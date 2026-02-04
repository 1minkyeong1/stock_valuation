import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../stock_repository.dart';
import 'fmp_client.dart';
import 'dart:async';

class UsFmpRepository implements StockRepository {
  final FmpClient _fmp;
  UsFmpRepository(this._fmp);

  // FMP 플랜 제한: income-statement limit <= 5
  static const int _maxLimit = 5;

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

  // static dynamic _firstRaw(Map<String, dynamic> m, List<String> keys) {
  //   for (final k in keys) {
  //     if (m.containsKey(k)) return m[k];
  //   }
  //   return null;
  // }

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

  static int _safeLimit(int n) => n.clamp(0, _maxLimit);

  static bool _isHttp402(Object e) => e.toString().contains('HTTP 402');
  static bool _isHttp429(Object e) => e.toString().contains('HTTP 429');

  // -------------------------
  // StockRepository
  // -------------------------
  @override
  Future<List<StockSearchItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final raw = await _fmp.searchSymbol(q);
    final items = <StockSearchItem>[];

    for (final e in raw) {
      final m = (e is Map<String, dynamic>) ? e : Map<String, dynamic>.from(e as Map);

      final code = (m['symbol'] ?? '').toString().trim().toUpperCase();
      if (code.isEmpty) continue;

      final name = (m['name'] ?? m['companyName'] ?? code).toString().trim();
      final market = _pickMarket(m);

      items.add(StockSearchItem(code: code, name: name, market: market));
      if (items.length >= 30) break;
    }

    // 검색 결과가 없는데 사용자가 티커처럼 입력한 경우 UX fallback
    if (items.isEmpty && _looksLikeUsTicker(q)) {
      final t = q.toUpperCase();
      items.add(StockSearchItem(code: t, name: t, market: 'US'));
    }

    return items;
  }

  @override
  Future<double> getPrice(String code) async {
    final symbol = code.trim().toUpperCase();
    if (symbol.isEmpty) return 0.0;

    try {
      final q = await _fmp.quoteOne(symbol);
      if (q == null) return 0.0;

      final price = _firstNumber(q, ['price', 'previousClose', 'open']);
      if (kDebugMode) debugPrint('[FMP] quote $symbol => $q');
      return price;
    } catch (e) {
      // 429/402 등에서도 ResultPage가 죽지 않게 0 반환
      if (kDebugMode) debugPrint('[FMP] getPrice failed: $e');
      return 0.0;
    }
  }

  @override
  Future<StockFundamentals> getFundamentals(String code, {int? targetYear}) async {
    final symbol = code.trim().toUpperCase();
    final bool dbg = kDebugMode;

    if (symbol.isEmpty) {
      return const StockFundamentals(eps: 0, bps: 0, dps: 0);
    }

    // (선택) TTL 캐시로 429 완화
    final cacheKey = '$symbol:${targetYear ?? "latest"}';
    final now = DateTime.now();
    final ce = _cache[cacheKey];
    if (ce != null && now.difference(ce.at) <= _cacheTtl) {
      if (dbg) debugPrint('[FMP] cache hit => $cacheKey');
      return ce.value;
    }

    // 동일 심볼 동시 호출 방지
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

  Future<StockFundamentals> _getFundamentalsImpl(String symbol, {int? targetYear}) async {
    final dbg = kDebugMode;
    if (dbg) debugPrint('[FMP] getFundamentals START symbol=$symbol');

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
      // ==========================================================
      // A) 병렬 호출 (총 소요시간 = 가장 느린 1개)
      // ==========================================================
      final kmF = _fmp.keyMetricsTtmOne(symbol);
      final incomeF = _fmp.incomeStatement(
        symbol: symbol,
        period: 'quarter',
        limit: _safeLimit((targetYear != null) ? _maxLimit : 4),
      );
      final bsF = _fmp.balanceSheetStatement(symbol: symbol, period: 'quarter', limit: 1);
      final divF = _fmp.dividendsCompany(symbol: symbol, limit: 40);

      final results = await Future.wait([kmF, incomeF, bsF, divF])
          .timeout(const Duration(seconds: 10));

      final km = results[0] as Map<String, dynamic>?;
      final incomeQ = results[1] as List<dynamic>;
      final bsQ = results[2] as List<Map<String, dynamic>>;
      final divs = results[3] as List<Map<String, dynamic>>;

      // profile은 shares가 없을 때만(조건부 1회)
      Map<String, dynamic>? prof;

      // ==========================================================
      // B) 디버깅(추가 호출 없이 받은 데이터로만)
      // ==========================================================
      if (dbg) {
        debugPrint('[FMP] incomeQ len=${incomeQ.length}  bsQ len=${bsQ.length}  divs len=${divs.length}');
        debugPrint('[FMP] km keys => ${km?.keys.toList()}');
        if (incomeQ.isNotEmpty) {
          final first = (incomeQ.first is Map<String, dynamic>)
              ? incomeQ.first as Map<String, dynamic>
              : Map<String, dynamic>.from(incomeQ.first as Map);
          debugPrint('[FMP] incomeQ first keys => ${first.keys.toList()}');
        }
        if (bsQ.isNotEmpty) debugPrint('[FMP] bsQ first keys => ${bsQ.first.keys.toList()}');
        if (divs.isNotEmpty) debugPrint('[FMP] div first keys => ${divs.first.keys.toList()}');
      }

      // ==========================================================
      // C) 메타(year/basDt/periodLabel)
      // ==========================================================
      Map<String, dynamic>? latestIncome;
      if (incomeQ.isNotEmpty) {
        latestIncome = (incomeQ.first is Map<String, dynamic>)
            ? incomeQ.first as Map<String, dynamic>
            : Map<String, dynamic>.from(incomeQ.first as Map);
      }

      final year = _toYear(
        latestIncome?['calendarYear'] ??
            latestIncome?['fiscalYear'] ??
            latestIncome?['year'],
      );

      final incomeBasDt = _toBasDt(
        latestIncome?['date'] ??
            latestIncome?['filingDate'] ??
            latestIncome?['acceptedDate'],
      );

      final qLabel = _quarterLabelFromBasDt(incomeBasDt, year);
      final periodLabel = qLabel ?? (year != null ? '$year' : 'TTM');

      String? bsBasDt;
      if (bsQ.isNotEmpty) {
        bsBasDt = _toBasDt(bsQ.first['date'] ?? bsQ.first['acceptedDate'] ?? bsQ.first['filingDate']);
      }

      String? divBasDt;
      if (divs.isNotEmpty) {
        divBasDt = _toBasDt(divs.first['date'] ?? divs.first['paymentDate'] ?? divs.first['recordDate']);
      }

      // ==========================================================
      // D) EPS/BPS/DPS 값 계산 (km 우선, 없으면 fallback)
      // ==========================================================
      final epsTtm = (km == null)
          ? 0.0
          : _firstNumber(km, ['netIncomePerShareTTM', 'epsTTM', 'eps', 'epsDilutedTTM', 'epsDiluted']);

      final bpsTtm = (km == null)
          ? 0.0
          : _firstNumber(km, ['bookValuePerShareTTM', 'bookValuePerShare', 'bvpsTTM', 'bvps']);

      final dpsTtm = (km == null)
          ? 0.0
          : _firstNumber(km, ['dividendPerShareTTM', 'dividendPerShare', 'dpsTTM', 'dps']);

      // EPS fallback: 최근 4분기 EPS 합(근사 TTM)
      double epsFallback = 0.0;
      if (epsTtm == 0.0 && incomeQ.isNotEmpty) {
        for (final e in incomeQ.take(4)) {
          final m = (e is Map<String, dynamic>) ? e : Map<String, dynamic>.from(e as Map);
          epsFallback += _firstNumber(m, ['eps', 'epsDiluted']);
        }
      }

      // BPS fallback: equity / shares
      double bpsFallback = 0.0;
      if (bpsTtm == 0.0) {
        final equity = (bsQ.isEmpty)
            ? 0.0
            : _firstNumber(bsQ.first, [
                'totalStockholdersEquity',
                'totalEquity',
                'totalShareholdersEquity',
                'totalAssetsMinusTotalLiabilities',
              ]);

        double shares = (bsQ.isEmpty)
            ? 0.0
            : _firstNumber(bsQ.first, [
                'commonStockSharesOutstanding',
                'commonSharesOutstanding',
                'sharesOutstanding',
              ]);

        // 2) income에서 shares fallback
        if (shares == 0.0 && incomeQ.isNotEmpty) {
          final m0 = (incomeQ.first is Map<String, dynamic>)
              ? incomeQ.first as Map<String, dynamic>
              : Map<String, dynamic>.from(incomeQ.first as Map);
          shares = _firstNumber(m0, ['weightedAverageShsOutDil', 'weightedAverageShsOut']);
        }

        // 3) profile 조건부 호출
        if (shares == 0.0) {
          try {
            prof = await _fmp.profileOne(symbol);
            if (prof != null) shares = _firstNumber(prof, ['sharesOutstanding']);
          } catch (_) {}
        }

        if (equity != 0.0 && shares != 0.0) {
          bpsFallback = equity / shares;
        }

        if (dbg) debugPrint('[FMP] BPS calc => equity=$equity shares=$shares bps=$bpsFallback');
      }

      // DPS fallback: 배당 리스트 합산(근사)
      double dpsFallback = 0.0;
      if (dpsTtm == 0.0 && divs.isNotEmpty) {
        for (final e in divs.take(8)) {
          dpsFallback += _firstNumber(e, ['dividend', 'adjDividend', 'amount']);
        }
      }

      final epsFinal = (epsTtm != 0.0) ? epsTtm : epsFallback;
      final bpsFinal = (bpsTtm != 0.0) ? bpsTtm : bpsFallback;
      final dpsFinal = (dpsTtm != 0.0) ? dpsTtm : dpsFallback;

      // ==========================================================
      // E) 표시용 source/label
      // ==========================================================
      final epsSource = (epsTtm != 0.0) ? 'key-metrics-ttm' : 'income-statement(sum4Q)';
      final bpsSource = (bpsTtm != 0.0) ? 'key-metrics-ttm' : 'balance-sheet(equity/shares)';
      final dpsSource = (dpsTtm != 0.0) ? 'key-metrics-ttm' : 'dividends(sum)';

      final epsLabel = (incomeBasDt != null)
          ? ((epsTtm != 0.0) ? 'TTM (as of $incomeBasDt)' : '$periodLabel (as of $incomeBasDt)')
          : ((epsTtm != 0.0) ? 'TTM' : periodLabel);

      final bpsLabel = (bsBasDt != null)
          ? ((bpsTtm != 0.0) ? 'TTM (as of $bsBasDt)' : 'BS as of $bsBasDt')
          : ((bpsTtm != 0.0) ? 'TTM' : 'BS');

      final dpsLabel = (divBasDt != null)
          ? ((dpsTtm != 0.0) ? 'TTM (as of $divBasDt)' : 'Dividends up to $divBasDt')
          : ((dpsTtm != 0.0) ? 'TTM' : 'Dividends');

      if (dbg) {
        debugPrint('[FMP] eps: ttm=$epsTtm fallback=$epsFallback final=$epsFinal');
        debugPrint('[FMP] bps: ttm=$bpsTtm fallback=$bpsFallback final=$bpsFinal');
        debugPrint('[FMP] dps: ttm=$dpsTtm fallback=$dpsFallback final=$dpsFinal');
        debugPrint('[FMP] meta => year=$year basDt=$incomeBasDt periodLabel=$periodLabel');
      }

      // ==========================================================
      // F) 반환
      // ==========================================================
      return StockFundamentals(
        eps: epsFinal,
        bps: bpsFinal,
        dps: dpsFinal,
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
      if (_isHttp402(e)) {
        if (dbg) { debugPrint('[FMP] 402: $e'); debugPrint('$st'); }
        return fail('FMP 402(플랜 제한): limit<=5 필요');
      }
      if (_isHttp429(e)) {
        if (dbg) { debugPrint('[FMP] 429: $e'); debugPrint('$st'); }
        return fail('FMP 429(한도초과): 잠시 후 재시도');
      }
      if (dbg) { debugPrint('[FMP] ERROR: $e'); debugPrint('$st'); }
      return fail('FMP 오류: ${e.toString()}');
    } finally {
      if (dbg) debugPrint('[FMP] getFundamentals END symbol=$symbol');
    }
  }

  @override
  Future<PriceQuote> getPriceQuote(String code) async {
    final p = await getPrice(code);
    return PriceQuote(
      price: p,
      basDt: null,     // US는 굳이 안 쓰면 null
      listedShares: 0,
      marketCap: 0,
    );
  }

}

class _CacheEntry {
  final StockFundamentals value;
  final DateTime at;
  _CacheEntry(this.value, this.at);
}
