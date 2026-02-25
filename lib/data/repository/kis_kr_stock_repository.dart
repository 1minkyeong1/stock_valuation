import 'dart:convert' show jsonDecode, utf8;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'stock_repository.dart';
import '../api/dart_proxy_client.dart';
import '../../utils/search_alias.dart';

/// KIS(실시간 가격) + OpenDART(재무/배당)를 Worker를 통해 호출하는 Repository
class KisKrStockRepository implements StockRepository {
  final String workerBaseUrl;
  final http.Client _client;
  final bool debugLog;

  KisKrStockRepository({
    required this.workerBaseUrl,
    http.Client? client,
    this.debugLog = true,
  }) : _client = client ?? http.Client();

  // =========================
  // 로그 유틸
  // =========================
  void _log(String msg) {
    if (debugLog) debugPrint('[KIS] $msg');
  }

  void _logDart(String msg) {
    if (debugLog) debugPrint('[KIS][DART] $msg');
  }

  // =========================
  // Worker GET 공통
  // =========================
  Future<http.Response> _workerGet(
    String path,
    Map<String, String> params, {
    String? tag,
  }) async {
    final base = workerBaseUrl.endsWith('/')
        ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
        : workerBaseUrl;

    final p = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$p').replace(queryParameters: params);

    _log('[WORKER GET] ${tag ?? p} -> $uri');

    return _client.get(uri).timeout(
      const Duration(seconds: 18),
      onTimeout: () => throw Exception('WORKER timeout(18s): ${tag ?? p}'),
    );
  }

  // "A005930" / "5930" / "005930" -> 6자리
  String _normalizeCode(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    if (s.length == 7 && (s[0] == 'A' || s[0] == 'a')) s = s.substring(1);
    s = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.isNotEmpty && s.length < 6) s = s.padLeft(6, '0');
    return s;
  }

  // -------------------------
  // 안전 파서: 문자열 -> double
  // -------------------------
  double _toDouble(dynamic v) {
    if (v == null) return 0.0;

    var s = v.toString().trim();
    if (s.isEmpty || s == '-') return 0.0;

    // (123) => -123
    if (s.startsWith('(') && s.endsWith(')')) {
      s = '-${s.substring(1, s.length - 1)}';
    }

    s = s
        .replaceAll(',', '')
        .replaceAll('원', '')
        .replaceAll('%', '')
        .replaceAll(RegExp(r'\s+'), '');

    // 숫자/부호/소수점만
    s = s.replaceAll(RegExp(r'[^0-9.\-]'), '');

    if (s.isEmpty || s == '-' || s == '.' || s == '-.') return 0.0;
    return double.tryParse(s) ?? 0.0;
  }

  // DART 숫자(원단위) 파서: num
  num _toNum(dynamic v) {
    final s0 = (v ?? '').toString().trim();
    if (s0.isEmpty || s0 == '-') return 0;
    var s = s0.replaceAll(',', '').trim();

    // (123) => -123
    if (s.startsWith('(') && s.endsWith(')')) {
      s = '-${s.substring(1, s.length - 1)}';
    }

    s = s.replaceAll(RegExp(r'[^0-9\-]'), '');
    return num.tryParse(s) ?? 0;
  }

  // =========================
  // 1) 검색 (Worker: /kr/search)
  // =========================
  @override
  Future<List<StockSearchItem>> search(String query) async {
    final raw = query.trim();
    if (raw.isEmpty) return [];

    // 한글 alias -> 코드로 치환 시도
    final hit = SearchAlias.resolveKr(raw);
    final q2 = hit?.code ?? raw;

    final res = await _workerGet(
      '/kr/search',
      {
        'q': q2, // Worker가 q/query 둘 다 받도록 해두셨다면 OK
        'limit': '30',
      },
      tag: 'kr/search',
    );

    if (res.statusCode != 200) {
      _log('search fail HTTP ${res.statusCode} body=${res.body}');
      throw Exception('검색 실패: HTTP ${res.statusCode}: ${res.body}');
    }

    final root = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (root['items'] is List) ? (root['items'] as List) : const [];

    final items = list
        .whereType<Map>()
        .map((m) {
          final mm = Map<String, dynamic>.from(m);
          final code = (mm['symbol'] ?? mm['code'] ?? '').toString().trim();
          final name = (mm['nameKo'] ?? mm['name'] ?? '').toString().trim();
          final market = (mm['exchangeShortName'] ?? mm['market'] ?? 'KRX')
              .toString()
              .trim();
          return StockSearchItem(code: code, name: name, market: market);
        })
        .where((x) => x.code.isNotEmpty && x.name.isNotEmpty)
        .toList();

    // Worker 결과가 비어도 alias가 있으면 1개라도 보여주기
    if (items.isEmpty && hit != null) {
      return [StockSearchItem(code: hit.code, name: hit.name, market: 'KRX')];
    }

    return items;
  }

  // =========================
  // 2) 가격 (Worker: /kr/price)
  // =========================
  @override
  Future<PriceQuote> getPriceQuote(String code) async {
    final c = _normalizeCode(code);
    if (c.isEmpty) throw Exception('code is empty');

    final res = await _workerGet(
      '/kr/price',
      {'code': c},
      tag: 'kr/price(KIS) code=$c',
    );

    if (res.statusCode != 200) {
      _log('price fail HTTP ${res.statusCode} body=${res.body}');
      throw Exception('KIS 가격 조회 실패: HTTP ${res.statusCode}: ${res.body}');
    }

    final root = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

    final price = (root['price'] as num?)?.toDouble() ??
        double.tryParse((root['price'] ?? '0').toString()) ??
        0.0;

    final basDtRaw = (root['basDt'] ?? '').toString().trim();
    final basDt = basDtRaw.isEmpty ? null : basDtRaw;

    if (price <= 0) {
      throw Exception('가격 데이터를 찾지 못했습니다: $c (KIS 실시간)');
    }

    return PriceQuote(
      price: price,
      basDt: basDt,
      listedShares: int.tryParse((root['listedShares'] ?? '0').toString()) ?? 0,
      marketCap: int.tryParse((root['marketCap'] ?? '0').toString()) ?? 0,
    );
  }

  @override
  Future<double> getPrice(String code) async => (await getPriceQuote(code)).price;

  // =========================
  // 3) 재무 (Worker: /dart/corp + /dart/fnltt + /dart/alot)
  // =========================
  @override
  Future<StockFundamentals> getFundamentals(String code,
      {int? targetYear}) async {
    final c = _normalizeCode(code);
    if (c.isEmpty) throw Exception('code is empty');

    final dart = DartProxyClient(
      workerBaseUrl: workerBaseUrl,
      client: _client,
      debugLog: debugLog,
    );

    // 1) corp_code
    final corpCode = await dart.getCorpCodeByStockCode(c);
    if (corpCode == null || corpCode.isEmpty) {
      throw Exception('corp_code를 찾지 못했습니다: stock=$c');
    }
    _logDart('corp_code: stock=$c -> corp=$corpCode');

    // 2) shares (EPS/BPS 계산용)
    int shares = 0;
    try {
      final pq = await getPriceQuote(c);
      shares = pq.listedShares;

      if (shares <= 0 && pq.marketCap > 0 && pq.price > 0) {
        shares = (pq.marketCap / pq.price).round();
      }

      _logDart(
          'shares: listedShares=${pq.listedShares} marketCap=${pq.marketCap} price=${pq.price} -> shares=$shares');
    } catch (e) {
      _logDart('getPriceQuote for shares failed: $e');
    }

    // 3) 후보 연도/보고서
    final now = DateTime.now();
    final baseYear = targetYear ?? (now.year - 1);
    final years = <int>[baseYear, baseYear - 1, baseYear - 2];

    // 3Q 우선 → 연간(FY) 폴백
    const reprtOrder = <String>['11014', '11011'];

    // 결과값
    double eps = 0.0;
    double bps = 0.0;
    double dps = 0.0;

    // 메타
    int? usedYear;
    String? usedReprt;
    String? usedFsDiv; // "CFS" / "OFS"
    String? basDt;
    String? periodLabel;

    // 원본 재무 금액(신뢰 표시용)
    num revenue = 0;
    num opIncome = 0;
    num netIncome = 0;
    num equity = 0;

    // 4) fnltt rows (CFS 우선, 없으면 OFS)
    List<Map<String, dynamic>>? fnlttRows;

    for (final y in years) {
      for (final reprt in reprtOrder) {
        // CFS
        debugPrint('fnltt call corp=$corpCode year=$y reprt=$reprt fs=CFS');
        final cfs = await dart.fnlttSinglAcntAll(
          corpCode: corpCode,
          year: y,
          reprtCode: reprt,
          fsDiv: 'CFS',
        );
        if (cfs.isNotEmpty) {
          fnlttRows = cfs;
          usedYear = y;
          usedReprt = reprt;
          usedFsDiv = 'CFS';
          break;
        }

        // OFS
        debugPrint('fnltt call corp=$corpCode year=$y reprt=$reprt fs=OFS');
        final ofs = await dart.fnlttSinglAcntAll(
          corpCode: corpCode,
          year: y,
          reprtCode: reprt,
          fsDiv: 'OFS',
        );
        if (ofs.isNotEmpty) {
          fnlttRows = ofs;
          usedYear = y;
          usedReprt = reprt;
          usedFsDiv = 'OFS';
          break;
        }
      }
      if (fnlttRows != null) break;
    }

    if (fnlttRows != null && fnlttRows.isNotEmpty) {
      // ✅ 원본 금액 추출
      netIncome = _pickNetIncomeFromDart(fnlttRows);
      equity = _pickEquityFromDart(fnlttRows);
      revenue = _pickRevenueFromDart(fnlttRows);
      opIncome = _pickOpIncomeFromDart(fnlttRows);

      // ✅ EPS/BPS 계산
      final annualizedNetIncome =
          _annualizeProfit(netIncome.toDouble(), usedReprt ?? '11011');

      if (shares > 0) {
        eps = (annualizedNetIncome != 0) ? (annualizedNetIncome / shares) : 0.0;
        bps = (equity != 0) ? (equity.toDouble() / shares) : 0.0;
      } else {
        _logDart('shares=0 so eps/bps cannot be calculated');
      }

      // 메타(기준일/라벨)
      if (usedYear != null && usedReprt != null) {
        final info = _reprtInfo(usedYear, usedReprt);
        basDt = info.basDt;
        periodLabel = info.label;
      }

      _logDart(
        'fnltt picked: year=$usedYear reprt=$usedReprt fs=$usedFsDiv '
        'revenue=$revenue opIncome=$opIncome netIncome=$netIncome equity=$equity shares=$shares '
        '-> eps=$eps bps=$bps basDt=$basDt label=$periodLabel',
      );
    } else {
      _logDart('fnlttRows empty for corp=$corpCode stock=$c (years=$years)');
    }

    // 5) DPS (배당)
    final tryYear = usedYear ?? baseYear;
    final tryReprt = usedReprt ?? '11011';

    dps = await _tryFetchDps(
      dart: dart,
      corpCode: corpCode,
      year: tryYear,
      reprtCode: tryReprt,
    );

    // DPS가 0이면 보고서코드만 바꿔서 추가 시도
    if (dps == 0.0) {
      for (final rc in reprtOrder) {
        if (rc == tryReprt) continue;
        dps = await _tryFetchDps(
          dart: dart,
          corpCode: corpCode,
          year: tryYear,
          reprtCode: rc,
        );
        if (dps != 0.0) break;
      }
    }

    _logDart(
      'final fundamentals: eps=$eps bps=$bps dps=$dps '
      'year=$usedYear reprt=$usedReprt fs=$usedFsDiv basDt=$basDt label=$periodLabel '
      'revenue=$revenue opIncome=$opIncome netIncome=$netIncome equity=$equity shares=$shares',
    );

    return StockFundamentals(
      eps: eps,
      bps: bps,
      dps: dps,
      year: usedYear ?? targetYear ?? baseYear,
      basDt: basDt,
      periodLabel: periodLabel,

      // ✅ 재무제표 원본 금액(사용자 신뢰용 표시)
      revenue: (revenue > 0) ? revenue : null,
      opIncome: (opIncome != 0) ? opIncome : null, // 적자(음수) 유지
      netIncome: (netIncome != 0) ? netIncome : null, // 적자(음수) 유지
      equity: (equity != 0) ? equity : null,

      // ✅ 어떤 조합으로 가져왔는지
      fsDiv: usedFsDiv,
      reprtCode: usedReprt,
      fsSource: 'OpenDART fnlttSinglAcntAll',
    );
  }

  // =========================
  // DART 파싱/보조
  // =========================

  _ReprtInfo _reprtInfo(int year, String reprtCode) {
    switch (reprtCode) {
      case '11013':
        return _ReprtInfo('$year 1Q', '${year}0331');
      case '11012':
        return _ReprtInfo('$year H1', '${year}0630');
      case '11014':
        return _ReprtInfo('$year 3Q', '${year}0930');
      case '11011':
      default:
        return _ReprtInfo('$year FY', '${year}1231');
    }
  }

  double _annualizeProfit(double profit, String reprtCode) {
    switch (reprtCode) {
      case '11013': // 1Q
        return profit * 4.0;
      case '11012': // H1
        return profit * 2.0;
      case '11014': // 3Q
        return profit * (4.0 / 3.0);
      case '11011':
      default:
        return profit;
    }
  }

  // ===== 당기순이익(원본 금액) =====
  num _pickNetIncomeFromDart(List<Map<String, dynamic>> rows) {
    final isRows = rows.where((m) {
      final sj = (m['sj_div'] ?? '').toString();
      return sj == 'IS' || sj == 'CIS';
    }).toList();

    if (isRows.isEmpty) return 0;

    // account_id 우선
    const idPriority = <String>[
      'ifrs-full_ProfitLossAttributableToOwnersOfParent',
      'ifrs-full_ProfitLoss',
      'dart_ProfitLoss',
    ];

    for (final id in idPriority) {
      final hit = isRows.cast<Map<String, dynamic>>().firstWhere(
            (x) => (x['account_id'] ?? '').toString() == id,
            orElse: () => <String, dynamic>{},
          );
      if (hit.isNotEmpty) {
        final v = _toNum(hit['thstrm_add_amount']);
        if (v != 0) return v;
        final v2 = _toNum(hit['thstrm_amount']);
        if (v2 != 0) return v2;
      }
    }

    // account_nm 포함 검색
    const namePriority = <String>[
      '지배기업소유주지분당기순이익',
      '당기순이익',
      '당기순이익(손실)',
    ];

    for (final key in namePriority) {
      final hit = isRows.cast<Map<String, dynamic>>().firstWhere(
            (x) => (x['account_nm'] ?? '')
                .toString()
                .replaceAll(' ', '')
                .contains(key),
            orElse: () => <String, dynamic>{},
          );
      if (hit.isNotEmpty) {
        final v = _toNum(hit['thstrm_add_amount']);
        if (v != 0) return v;
        final v2 = _toNum(hit['thstrm_amount']);
        if (v2 != 0) return v2;
      }
    }

    return 0;
  }

  // ===== 자본총계 =====
  num _pickEquityFromDart(List<Map<String, dynamic>> rows) {
    final exact = rows.firstWhere(
      (m) => (m['account_nm'] ?? '').toString() == '자본총계',
      orElse: () => <String, dynamic>{},
    );
    if (exact.isNotEmpty) {
      final v = _toNum(exact['thstrm_amount']);
      if (v != 0) return v;
      return _toNum(exact['thstrm_add_amount']);
    }

    for (final key in const ['자본총계', '총자본']) {
      final hit = rows.firstWhere(
        (m) => (m['account_nm'] ?? '').toString().contains(key),
        orElse: () => <String, dynamic>{},
      );
      if (hit.isNotEmpty) {
        final v = _toNum(hit['thstrm_amount']);
        if (v != 0) return v;
        return _toNum(hit['thstrm_add_amount']);
      }
    }
    return 0;
  }

  // ===== 매출액 =====
  num _pickRevenueFromDart(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      final nm = (r['account_nm'] ?? '').toString().trim(); 
      if (nm.contains('매출액') || nm.contains('영업수익')) {
        final add = _toNum(r['thstrm_add_amount']);
        final amt = _toNum(r['thstrm_amount']);
        final prevAdd = _toNum(r['frmtrm_add_amount']);
        final prevAmt = _toNum(r['frmtrm_amount']);
        return (add != 0) ? add : (amt != 0) ? amt : (prevAdd != 0) ? prevAdd : prevAmt;
      }
    }
    return 0;
  }

  // ===== 영업이익 =====
  num _pickOpIncomeFromDart(List<Map<String, dynamic>> rows) {
    for (final r in rows) {
      final nm = (r['account_nm'] ?? '').toString().trim(); 
      if (nm.contains('영업이익')) {
        final add = _toNum(r['thstrm_add_amount']);
        final amt = _toNum(r['thstrm_amount']);
        final prevAdd = _toNum(r['frmtrm_add_amount']);
        final prevAmt = _toNum(r['frmtrm_amount']);
        return (add != 0) ? add : (amt != 0) ? amt : (prevAdd != 0) ? prevAdd : prevAmt;
      }
    }
    return 0;
  }

  // =========================
  // DPS 시도 (배당)
  // =========================
  Future<double> _tryFetchDps({
    required DartProxyClient dart,
    required String corpCode,
    required int year,
    required String reprtCode,
  }) async {
    try {
      final list = await dart.alotMatter(
        corpCode: corpCode,
        year: year,
        reprtCode: reprtCode,
      );

      if (list.isEmpty) {
        _logDart('alot empty year=$year reprt=$reprtCode');
        return 0.0;
      }

      final picked = _pickBestDpsRow(list);
      if (picked == null) return 0.0;

      final v = _toDouble(picked['thstrm']);
      if (v == 0.0) return 0.0;

      _logDart(
          'alot picked year=$year reprt=$reprtCode se=${picked['se']} stock=${picked['stock_knd']} -> dps=$v');
      return v;
    } catch (e) {
      _logDart('alot fail year=$year reprt=$reprtCode: $e');
      return 0.0;
    }
  }

  Map<String, dynamic>? _pickBestDpsRow(List<Map<String, dynamic>> list) {
    Map<String, dynamic>? best;
    int bestScore = -999999;

    for (final m in list) {
      final se = (m['se'] ?? '').toString().replaceAll(' ', '');
      final stock = (m['stock_knd'] ?? '').toString().replaceAll(' ', '');
      final v = _toDouble(m['thstrm']);

      int score = 0;

      final hasJooDang = se.contains('주당');
      final hasCash = se.contains('현금');
      final hasDividend = se.contains('배당');
      final hasDividendAmt = se.contains('배당금') || se.contains('배당액');

      if (hasJooDang && hasCash && hasDividend) {
        score += 1000;
      } else if (hasJooDang && hasDividendAmt) {
        score += 850;
      } else if (hasJooDang && hasDividend) {
        score += 700;
      } else if (hasDividend || hasDividendAmt) {
        score += 300;
      }

      if (stock.contains('보통주')) score += 250;
      if (stock.contains('우선주')) score -= 100;

      if (v != 0.0) score += 400;
      if (se.contains('(원)')) score += 50;

      if (score > bestScore) {
        bestScore = score;
        best = m;
      }
    }
    return best;
  }
}

class _ReprtInfo {
  final String label;
  final String basDt; // YYYYMMDD
  const _ReprtInfo(this.label, this.basDt);
}