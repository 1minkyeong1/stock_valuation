import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'stock_repository.dart';
import '../api/fmp_client.dart';
import '../../utils/search_alias.dart';

class UsFmpRepository implements StockRepository {
  final FmpClient _fmp;
  UsFmpRepository(this._fmp);

  // (선택) 짧은 TTL 캐시로 429 완화
  static const Duration _cacheTtl = Duration(minutes: 3);
  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<StockFundamentals>> _inflight = {};

  // -------------------------
  // helpers
  // -------------------------
  static String _pickMarket(Map<String, dynamic> m) {
    final v = (m['exchangeShortName'] ??
            m['exchange'] ??
            m['stockExchange'] ??
            m['market'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    if (v.isEmpty) return 'US';
    if (v.contains('NASDAQ')) return 'NASDAQ';
    if (v.contains('NYSE')) return 'NYSE';
    return v;
  }

  static bool _looksLikeUsTicker(String q) {
    final t = q.trim().toUpperCase();
    if (t.isEmpty) return false;
    return RegExp(r'^[A-Z]{1,6}([.\-][A-Z0-9]{1,3})?$').hasMatch(t);
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static double _firstNumber(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null) return _asDouble(v);
    }
    return 0.0;
  }

  static int? _toYear(dynamic y) {
    final s = y?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return int.tryParse(s);
  }

  static String? _toBasDt(dynamic dateValue) {
    // "YYYY-MM-DD" -> "YYYYMMDD"
    final s = dateValue?.toString().trim();
    if (s == null || s.isEmpty) return null;

    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m != null) return '${m.group(1)}${m.group(2)}${m.group(3)}';

    final m2 = RegExp(r'^(\d{8})$').firstMatch(s);
    if (m2 != null) return s;

    return null;
  }

  static String? _quarterLabelFromBasDt(String? basDt, int? year) {
    if (basDt == null || basDt.length != 8 || year == null) return null;
    final mm = int.tryParse(basDt.substring(4, 6));
    if (mm == null) return null;
    final q = ((mm - 1) ~/ 3) + 1; // 1~4
    return '$year ${q}Q';
  }

  static bool _isHttp402(Object e) => e.toString().contains('HTTP 402');
  static bool _isHttp429(Object e) => e.toString().contains('HTTP 429');

  static bool _isLegacyMsg(Object e) =>
      e.toString().toLowerCase().contains('legacy endpoint') ||
      e.toString().toLowerCase().contains('no longer supported');

  // -------------------------
  // StockRepository
  // -------------------------
  @override
  Future<List<StockSearchItem>> search(String query) async {
    final raw = query.trim();
    if (raw.isEmpty) return [];

    // ✅ 한글(애플/테슬라/엔비디아 등) → 티커로 치환
    final hit = SearchAlias.resolveUs(raw);
    final q2 = hit?.code ?? raw;

    // ✅ Worker /fmp/search 호출
    final resp = await _fmp.search(q2);
    final itemsRaw = (resp['items'] is List) ? (resp['items'] as List) : const [];

    final items = <StockSearchItem>[];
    for (final e in itemsRaw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);

      final code = (m['symbol'] ?? '').toString().trim().toUpperCase();
      if (code.isEmpty) continue;

      final name = (m['name'] ?? m['companyName'] ?? code).toString().trim();
      final market = _pickMarket(m);

      items.add(StockSearchItem(code: code, name: name, market: market));
      if (items.length >= 30) break;
    }

    // ✅ alias로는 잡혔는데 FMP 검색이 비어있으면 UX fallback
    if (items.isEmpty && hit != null) {
      return [StockSearchItem(code: hit.code, name: hit.name, market: 'US')];
    }

    // ✅ 티커처럼 입력했는데 결과가 없으면 fallback
    if (items.isEmpty && SearchAlias.looksLikeUsTicker(raw)) {
      final t = raw.toUpperCase();
      return [StockSearchItem(code: t, name: t, market: 'US')];
    }

    return items;
  }

  // ✅ 가격은 무조건 Worker /fmp/price(정규화)에서만 가져온다.
  @override
  Future<double> getPrice(String code) async {
    final symbol = code.trim().toUpperCase();
    if (symbol.isEmpty) return 0.0;

    try {
      final r = await _fmp.priceNormalized(symbol);
      if (kDebugMode) debugPrint('[FMP] priceNormalized $symbol => $r');

      if (r['ok'] == true) {
        return _asDouble(r['price']);
      }
      return 0.0;
    } catch (e) {
      if (kDebugMode) debugPrint('[FMP] getPrice failed: $e');
      return 0.0;
    }
  }

  @override
  Future<PriceQuote> getPriceQuote(String code) async {
    final symbol = code.trim().toUpperCase();
    if (symbol.isEmpty) {
      return const PriceQuote(price: 0, basDt: null, listedShares: 0, marketCap: 0);
    }

    try {
      final r = await _fmp.priceNormalized(symbol);
      if (kDebugMode) debugPrint('[FMP] priceQuote $symbol => $r');

      if (r['ok'] == true) {
        final price = _asDouble(r['price']);
        final marketCap = _asDouble(r['marketCap']).round(); // int

        return PriceQuote(
          price: price,
          basDt: null,
          listedShares: 0,
          marketCap: marketCap,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FMP] getPriceQuote failed: $e');
    }

    return const PriceQuote(price: 0, basDt: null, listedShares: 0, marketCap: 0);
  }

  @override
  Future<StockFundamentals> getFundamentals(String code, {int? targetYear}) async {
    final symbol = code.trim().toUpperCase();
    final bool dbg = kDebugMode;

    if (symbol.isEmpty) {
      return const StockFundamentals(eps: 0, bps: 0, dps: 0);
    }

    // TTL 캐시
    final cacheKey = '$symbol:${targetYear ?? "latest"}';
    final now = DateTime.now();
    final ce = _cache[cacheKey];
    if (ce != null && now.difference(ce.at) <= _cacheTtl) {
      if (dbg) debugPrint('[FMP] fundamentals cache hit => $cacheKey');
      return ce.value;
    }

    // inflight 방지
    final inflight = _inflight[cacheKey];
    if (inflight != null) return inflight;

    final fut = _getFundamentalsImpl(symbol, targetYear: targetYear).then((v) {
      _cache[cacheKey] = _CacheEntry(v, DateTime.now());
      _inflight.remove(cacheKey);
      return v;
    }).catchError((e) {
      _inflight.remove(cacheKey);
      throw e;
    });

    _inflight[cacheKey] = fut;
    return fut;
  }

  List<Map<String, dynamic>> _unwrapList(dynamic v) {
    // 1) 응답이 곧바로 List
    if (v is List) {
      return v
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    // 2) { ok, items: [...] }
    if (v is Map && v['items'] is List) {
      final items = v['items'] as List;
      return items
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _unwrapOne(dynamic v) {
    // 1) Map 하나
    if (v is Map) {
      // 신규 형태인 경우 items[0]
      if (v['items'] is List && (v['items'] as List).isNotEmpty) {
        final first = (v['items'] as List).first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
      return Map<String, dynamic>.from(v);
    }

    // 2) List[0]
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }

    return null;
  }

  Future<StockFundamentals> _getFundamentalsImpl(String symbol, {int? targetYear}) async {
    final dbg = kDebugMode;
    if (dbg) debugPrint('[FMP] getFundamentals START symbol=$symbol targetYear=$targetYear');

    StockFundamentals fail(String reason) => StockFundamentals(
          eps: 0,
          bps: 0,
          dps: 0,
          periodLabel: 'TTM',
          epsLabel: reason,
          bpsLabel: reason,
          dpsLabel: reason,
          epsSource: reason,
          bpsSource: reason,
          dpsSource: reason,
        );

    try {
      double pickBpsFromWorker(Map<String, dynamic> br) {
            // flat: {bps: ...}
            final direct = _asDouble(br['bps']);
            if (direct != 0.0) return direct;

            // wrapped: {items:[{bps: ...}]}
            final items = br['items'];
            if (items is List && items.isNotEmpty && items.first is Map) {
              return _asDouble((items.first as Map)['bps']);
            }
            return 0.0;
          }

      // 병렬 호출
      final incomeF = _fmp.incomeStatement(symbol: symbol, limit: 12);
      final bsF = _fmp.balanceSheet(symbol: symbol, limit: 1);
      final profF = _fmp.profileOne(symbol);
      final divF = _fmp.dividends(symbol: symbol, limit: 20);

      final results = await Future.wait([incomeF, bsF, profF, divF]).timeout(const Duration(seconds: 10));

      final incomeList = _unwrapList(results[0]);
      final bsList = _unwrapList(results[1]);
      final prof = _unwrapOne(results[2]);
      final divs = _unwrapList(results[3]);

      if (dbg) {
        debugPrint('[FMP] income len=${incomeList.length} bs len=${bsList.length} div len=${divs.length}');
      }

      // 사용할 최신 row 선택
      Map<String, dynamic>? latestIncome;
      if (incomeList.isNotEmpty) {
        if (targetYear == null) {
          latestIncome = incomeList.first;
        } else {
          Map<String, dynamic>? picked;
          for (final r in incomeList) {
            final y = _toYear(r['calendarYear'] ?? r['fiscalYear'] ?? r['year']);
            if (y == targetYear) {
              picked = r;
              break;
            }
          }
          latestIncome = picked ?? incomeList.first;
        }
      }

      final year = _toYear(latestIncome?['calendarYear'] ?? latestIncome?['fiscalYear'] ?? latestIncome?['year']);

      final incomeBasDt = _toBasDt(
        latestIncome?['date'] ?? latestIncome?['acceptedDate'] ?? latestIncome?['filingDate'],
      );

      final periodLabel = _quarterLabelFromBasDt(incomeBasDt, year) ?? (year != null ? '$year' : 'TTM');

      // EPS(TTM) 근사: 4개 합
      double epsTtm = 0.0;
      List<Map<String, dynamic>> epsRows = incomeList;

      if (targetYear != null) {
        final filtered = incomeList.where((r) {
          final y = _toYear(r['calendarYear'] ?? r['fiscalYear'] ?? r['year']);
          return y == targetYear || y == targetYear - 1;
        }).toList();
        if (filtered.isNotEmpty) epsRows = filtered;
      }

      for (final r in epsRows.take(4)) {
        epsTtm += _firstNumber(r, ['eps', 'epsDiluted', 'epsdiluted']);
      }


     // ✅ BPS = equity / shares (안전 + equity2 반영)
      double assets = 0.0;
      double liab = 0.0;
      double equity = 0.0;

      if (bsList.isNotEmpty) {
        assets = _firstNumber(bsList.first, ['totalAssets']);
        liab   = _firstNumber(bsList.first, ['totalLiabilities']);

        equity = _firstNumber(bsList.first, [
          'totalStockholdersEquity',
          'totalEquity',
          'totalShareholdersEquity',
          'totalAssetsMinusTotalLiabilities', // (있으면 사용)
        ]);
      }

      final equity2 = (equity != 0.0)
          ? equity
          : ((assets != 0.0 || liab != 0.0) ? (assets - liab) : 0.0);

      // shares는 profile만 보지 말고, BS에도 있으면 먼저 사용
      double shares = 0.0;

      if (bsList.isNotEmpty) {
        shares = _firstNumber(bsList.first, [
          'commonStockSharesOutstanding',
          'sharesOutstanding',
          'shares',
        ]);
      }
      if (shares == 0.0 && prof != null) {
        shares = _firstNumber(prof, [
          'sharesOutstanding',
          'shares',
          'commonStockSharesOutstanding',
        ]);
      }

      if (shares == 0.0 && prof != null) {
        final mc = _firstNumber(prof, ['marketCap', 'mktCap']);
        final px = _firstNumber(prof, ['price']);
        if (mc != 0.0 && px != 0.0) {
          shares = mc / px;
        }
      }

      double bps = (equity2 != 0.0 && shares != 0.0) ? (equity2 / shares) : 0.0;

      String bpsSource = 'balance-sheet(equity2/shares)';
      String bpsLabel  = (equity != 0.0)
          ? 'BS (equity/shares)'
          : ((assets != 0.0 || liab != 0.0) ? 'BS (assets-liab)/shares' : 'BS (no equity)');

      if (bps == 0.0 || bps.isNaN) {
        try {
          final br = await _fmp.bpsNormalized(symbol);
          if (br['ok'] == true) {
            final bps2 = pickBpsFromWorker(br);

            if (bps2 > 0.0) {
              bps = bps2;
              final src = (br['source'] ?? 'unknown').toString();
              bpsSource = 'worker:/fmp/bps($src)';
              bpsLabel  = 'BPS fallback ($src)';
            } else {
              bpsLabel  = 'BPS 없음';
              bpsSource = 'worker:/fmp/bps(no_value)';
            }
          } else {
            final err = (br['error'] ?? 'unknown').toString();
            bpsLabel  = 'BPS 실패($err)';
            bpsSource = 'worker:/fmp/bps(fail)';
          }
        } catch (e) {
          if (dbg) debugPrint('[FMP] bps fallback error: $e');
          bpsLabel  = 'BPS 실패';
          bpsSource = 'worker:/fmp/bps(error)';
        }
      }

      // DPS 근사: 최근 8개 합
      double dps = 0.0;
      if (divs.isNotEmpty) {
        for (final d in divs.take(8)) {
          dps += _firstNumber(d, ['dividend', 'adjDividend', 'amount']);
        }
      }

      final epsSource = 'income-statement(sum4)';
      final dpsSource = 'dividends(sum8)';

      final epsLabel = (incomeBasDt != null) ? 'TTM (as of $incomeBasDt)' : 'TTM';
      final dpsLabel = 'Dividends (last 8)';

      return StockFundamentals(
        eps: epsTtm,
        bps: bps,
        dps: dps,
        year: year,
        basDt: incomeBasDt,
        periodLabel: periodLabel,
        epsLabel: epsLabel,
        bpsLabel: bpsLabel,
        dpsLabel: dpsLabel,
        epsSource: epsSource,
        bpsSource: bpsSource,
        dpsSource: dpsSource,
      );
    } on TimeoutException {
      if (dbg) debugPrint('[FMP] getFundamentals TIMEOUT');
      return fail('FMP 타임아웃(10s)');
    } catch (e, st) {
      if (_isLegacyMsg(e)) {
        if (dbg) {
          debugPrint('[FMP] LEGACY: $e');
          debugPrint('$st');
        }
        return fail('FMP 레거시 차단');
      }
      if (_isHttp402(e)) {
        if (dbg) {
          debugPrint('[FMP] 402: $e');
          debugPrint('$st');
        }
        return fail('FMP 402(플랜 제한)');
      }
      if (_isHttp429(e)) {
        if (dbg) {
          debugPrint('[FMP] 429: $e');
          debugPrint('$st');
        }
        return fail('FMP 429(한도초과): 잠시 후 재시도');
      }
      if (dbg) {
        debugPrint('[FMP] ERROR: $e');
        debugPrint('$st');
      }
      return fail('FMP 오류: ${e.toString()}');
    } finally {
      if (dbg) debugPrint('[FMP] getFundamentals END symbol=$symbol');
    }
  }
}

class _CacheEntry {
  final StockFundamentals value;
  final DateTime at;
  _CacheEntry(this.value, this.at);
}
