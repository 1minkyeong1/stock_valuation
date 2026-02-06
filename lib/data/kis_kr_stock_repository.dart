import 'dart:convert' show jsonDecode, utf8;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'stock_repository.dart';
import 'dart_proxy_client.dart';

/// KIS(실시간 가격) + OpenDART(재무/배당)를 "Worker"를 통해 호출하는 Repository
///
/// ✅ 핵심 수정 포인트
/// - 기존: /dart/fundamentals (Worker에 없음 → 404)
/// - 변경: Worker에 실제 존재하는 라우트만 사용
///   1) /dart/corp      : stock code -> corp_code
///   2) /dart/fnltt     : fnlttSinglAcntAll (재무제표)
///   3) /dart/alot      : alotMatter (배당)
///
/// 그리고 앱에서 EPS/BPS/DPS를 직접 조합합니다.
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
      const Duration(seconds: 12),
      onTimeout: () {
        throw Exception('WORKER timeout(12s): ${tag ?? p}');
      },
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
  // 안전 파서: 문자열(원/%, 콤마, 괄호음수 등) -> double
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

  // =========================
  // 1) 검색 (Worker: /kr/search)
  // =========================
  @override
  Future<List<StockSearchItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final res = await _workerGet(
      '/kr/search',
      {'q': q},
      tag: 'kr/search',
    );

    if (res.statusCode != 200) {
      _log('search fail HTTP ${res.statusCode} body=${res.body}');
      throw Exception('검색 실패: HTTP ${res.statusCode}: ${res.body}');
    }

    final root = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final list = (root['items'] is List) ? (root['items'] as List) : const [];

    return list
        .whereType<Map>()
        .map((m) {
          final mm = Map<String, dynamic>.from(m);
          return StockSearchItem(
            code: (mm['code'] ?? '').toString(),
            name: (mm['name'] ?? '').toString(),
            market: (mm['market'] ?? '').toString(),
          );
        })
        .where((x) => x.code.isNotEmpty && x.name.isNotEmpty)
        .toList();
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

  // 있으면 편하니 유지
  @override
  Future<double> getPrice(String code) async => (await getPriceQuote(code)).price;

  // =========================
  // 3) 재무 (Worker: /dart/corp + /dart/fnltt + /dart/alot)
  // =========================
  @override
  Future<StockFundamentals> getFundamentals(String code, {int? targetYear}) async {
    final c = _normalizeCode(code);
    if (c.isEmpty) throw Exception('code is empty');

    // ✅ DartProxyClient는 Worker의 /dart/* 라우트를 호출
    final dart = DartProxyClient(
      workerBaseUrl: workerBaseUrl,
      client: _client, // 같은 http client 재사용
      debugLog: debugLog,
    );

    // 1) corp_code 확보
    final corpCode = await dart.getCorpCodeByStockCode(c);
    if (corpCode == null || corpCode.isEmpty) {
      throw Exception('corp_code를 찾지 못했습니다: stock=$c');
    }
    _logDart('corp_code: stock=$c -> corp=$corpCode');

    // 2) EPS/BPS 계산을 위해 주식수(shares) 확보
    int shares = 0;
    try {
      final pq = await getPriceQuote(c);
      shares = pq.listedShares;

      // listedShares가 0인데 시총/가격은 있으면 역산
      if (shares <= 0 && pq.marketCap > 0 && pq.price > 0) {
        shares = (pq.marketCap / pq.price).round();
      }

      _logDart('shares: listedShares=${pq.listedShares} marketCap=${pq.marketCap} price=${pq.price} -> shares=$shares');
    } catch (e) {
      _logDart('getPriceQuote for shares failed: $e');
    }

    // 3) 어떤 연도/보고서로 조회할지 결정
    // - targetYear를 줬는데 DART에 없을 수 있으니, targetYear 포함해서 뒤로 2년까지 fallback
    final now = DateTime.now();

    // ✅ targetYear 없으면 "직전연도(FY)"부터 시작
    final baseYear = targetYear ?? (now.year - 1);

    // ✅ 최근 3개년 탐색
    final years = <int>[baseYear, baseYear - 1, baseYear - 2];

    // ✅ 우선순위(최신 보고서 쪽부터 시도)
    // 11011(FY) -> 11014(3Q) -> 11012(H1) -> 11013(1Q)  
    const reprtOrder = <String>['11011', '11014', '11012', '11013'];

    double eps = 0.0;
    double bps = 0.0;
    double dps = 0.0;

    int? usedYear;
    String? usedReprt;
    String? basDt;
    String? periodLabel;

    // 4) fnltt 가져오기 (CFS 우선, 없으면 OFS)
    List<Map<String, dynamic>>? fnlttRows;

    for (final y in years) {
      for (final reprt in reprtOrder) {
        // ✅ 요청하신 로그(어디 넣나?) → "실제 호출 직전"이 제일 의미있습니다.
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
          break;
        }

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
          break;
        }
      }
      if (fnlttRows != null) break;
    }

    // 5) fnlttRows에서 순이익/자본총계 뽑기
    if (fnlttRows != null && fnlttRows.isNotEmpty) {
      final profit = _pickNetProfitFromDart(fnlttRows);
      final equity = _pickEquityFromDart(fnlttRows);

      // 분기/반기/3Q는 누적값일 때가 많아서 연환산(이전 공공데이터 코드 로직 그대로)
      final annualizedProfit = _annualizeProfit(profit, usedReprt ?? '11011');

      if (shares > 0) {
        eps = (annualizedProfit != 0) ? (annualizedProfit / shares) : 0.0;
        bps = (equity != 0) ? (equity / shares) : 0.0;
      } else {
        // shares가 없으면 eps/bps 계산 불가 → 0 유지
        _logDart('shares=0 so eps/bps cannot be calculated');
      }

      final info = _reprtInfo(usedYear ?? (targetYear ?? now.year), usedReprt ?? '11011');
      basDt = info.basDt;
      periodLabel = info.label;

      _logDart('fnltt picked: year=$usedYear reprt=$usedReprt profit=$profit (annual=$annualizedProfit) equity=$equity shares=$shares -> eps=$eps bps=$bps');
    } else {
      _logDart('fnlttRows empty for corp=$corpCode stock=$c (years=$years)');
    }

    // 6) DPS(배당) 가져오기
    // - usedYear/usedReprt가 있으면 그 조합부터
    // - 없으면 FY(11011)로 먼저 시도
    final tryYear = usedYear ?? (targetYear ?? (now.year - 1));
    final tryReprt = usedReprt ?? '11011';

    dps = await _tryFetchDps(dart: dart, corpCode: corpCode, year: tryYear, reprtCode: tryReprt);

    // DPS가 0이면 보고서코드만 바꿔서 몇 번 더 시도(많이 현실적인 fallback)
    if (dps == 0.0) {
      for (final rc in reprtOrder) {
        if (rc == tryReprt) continue;
        dps = await _tryFetchDps(dart: dart, corpCode: corpCode, year: tryYear, reprtCode: rc);
        if (dps != 0.0) break;
      }
    }

    _logDart('final fundamentals: eps=$eps bps=$bps dps=$dps year=$usedYear basDt=$basDt label=$periodLabel');

    return StockFundamentals(
      eps: eps,
      bps: bps,
      dps: dps,
      year: usedYear ?? targetYear,
      basDt: basDt,
      periodLabel: periodLabel,
    );
  }

  // =========================
  // DART 파싱 유틸들
  // =========================

  // 보고서 정보(표시용)
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

  // 분기/반기/3Q 연환산
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

  // 당기순이익(손익계산서) 우선순위로 추출
  double _pickNetProfitFromDart(List<Map<String, dynamic>> rows) {
    // 손익계산서(IS/CIS)만 추리기
    final isRows = rows.where((m) {
      final sj = (m['sj_div'] ?? '').toString();
      return sj == 'IS' || sj == 'CIS';
    }).toList();

    if (isRows.isEmpty) return 0.0;

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
        final v = _toDouble(hit['thstrm_amount'] ?? hit['thstrm_add_amount']);
        if (v != 0.0) return v;
      }
    }

    // account_nm(한글명) 포함 검색
    const namePriority = <String>[
      '지배기업소유주지분당기순이익',
      '지배기업',
      '귀속',
      '당기순이익',
      '당기순이익(손실)',
      '분기순이익',
    ];

    for (final key in namePriority) {
      final hit = isRows.cast<Map<String, dynamic>>().firstWhere(
            (x) => (x['account_nm'] ?? '').toString().replaceAll(' ', '').contains(key),
            orElse: () => <String, dynamic>{},
          );
      if (hit.isNotEmpty) {
        final v = _toDouble(hit['thstrm_amount'] ?? hit['thstrm_add_amount']);
        if (v != 0.0) return v;
      }
    }

    return 0.0;
  }

  // 자본총계(재무상태표) 추출
  double _pickEquityFromDart(List<Map<String, dynamic>> rows) {
    // 정확히 "자본총계" 우선
    final exact = rows.firstWhere(
      (m) => (m['account_nm'] ?? '').toString() == '자본총계',
      orElse: () => <String, dynamic>{},
    );
    if (exact.isNotEmpty) {
      return _toDouble(exact['thstrm_amount'] ?? exact['thstrm_add_amount']);
    }

    // 포함 검색
    final contains1 = rows.firstWhere(
      (m) => (m['account_nm'] ?? '').toString().contains('자본총계'),
      orElse: () => <String, dynamic>{},
    );
    if (contains1.isNotEmpty) {
      return _toDouble(contains1['thstrm_amount'] ?? contains1['thstrm_add_amount']);
    }

    final contains2 = rows.firstWhere(
      (m) => (m['account_nm'] ?? '').toString().contains('총자본'),
      orElse: () => <String, dynamic>{},
    );
    if (contains2.isNotEmpty) {
      return _toDouble(contains2['thstrm_amount'] ?? contains2['thstrm_add_amount']);
    }

    return 0.0;
  }

  // DPS 시도(배당 테이블에서 "주당/현금/배당/보통주" 우선)
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

      _logDart('alot picked year=$year reprt=$reprtCode se=${picked['se']} stock=${picked['stock_knd']} -> dps=$v');
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

      // 1) "주당/현금/배당" 계정 우선
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

      // 2) 보통주 우선
      if (stock.contains('보통주')) score += 250;
      if (stock.contains('우선주')) score -= 100;

      // 3) 값이 있으면 가산
      if (v != 0.0) score += 400;

      // 4) (원) 표기 가산
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
