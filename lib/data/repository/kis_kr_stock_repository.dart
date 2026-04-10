import 'dart:convert' show jsonDecode, utf8;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'stock_repository.dart';
//import '../api/dart_proxy_client.dart';
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

  double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();

    final s = v.toString().trim();
    if (s.isEmpty) return null;

    return double.tryParse(s);
  }

  List<YearMetric> _parseYearMetrics(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .map((e) {
          if (e is! Map) return null;

          final m = e.cast<String, dynamic>();
          final y = m['year'];
          final v = m['value'];

          final year = y is num ? y.toInt() : int.tryParse('$y');
          final value = v is num ? v.toDouble() : double.tryParse('$v');

          if (year == null || value == null) return null;
          return YearMetric(year: year, value: value);
        })
        .whereType<YearMetric>()
        .toList();
  }

  List<int> _parseIntList(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .map((e) => e is num ? e.toInt() : int.tryParse('$e'))
        .whereType<int>()
        .toList();
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

        final rawLogo = (mm['logoUrl'] ?? mm['logo'] ?? mm['image'] ?? '')
            .toString()
            .trim();

        final rawIndustry =
            (mm['industry'] ?? mm['sector'] ?? mm['bizType'] ?? mm['category'] ?? '')
                .toString()
                .trim();

        return StockSearchItem(
          code: code,
          name: name,
          market: market,
          logoUrl: rawLogo.isEmpty ? null : rawLogo,
          industry: rawIndustry.isEmpty ? null : rawIndustry,
        );
      })
      .where((x) => x.code.isNotEmpty && x.name.isNotEmpty)
      .toList();

    // Worker 결과가 비어도 alias가 있으면 1개라도 보여주기
    if (items.isEmpty && hit != null) {
      return [
        StockSearchItem(
          code: hit.code,
          name: hit.name,
          market: 'KRX',
          industry: null,
        ),
      ];
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
  Future<StockFundamentals> getFundamentals(String code, {int? targetYear}) async {
    final c = _normalizeCode(code);
    if (c.isEmpty) throw Exception('code is empty');

    final qs = <String, String>{
      'code': c,
      'reprt_code': '11011',
      'fs_div': 'CFS',
    };

    if (targetYear != null) {
      qs['bsns_year'] = '$targetYear';
    }

    final res = await _workerGet(
      '/kr/metrics-lite',
      qs,
      tag: 'kr/metrics-lite',
    );

    if (res.statusCode != 200) {
      throw Exception('KR metrics-lite HTTP ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception('KR metrics-lite failed: ${res.body}');
    }

    final fiscal = (map['fiscal'] as Map?)?.cast<String, dynamic>();

    final yearStr = fiscal?['bsns_year']?.toString();
    final reprtCode = fiscal?['reprt_code']?.toString();
    final fiscalBasDt = fiscal?['basDt']?.toString();
    final fsDivUsed =
        fiscal?['fs_div_used']?.toString() ?? map['fs_div_used']?.toString();

    final year = int.tryParse(yearStr ?? '');

    final labelSuffix = _reprtLabelFromCode(reprtCode);
    final periodLabel =
        (yearStr != null && labelSuffix.isNotEmpty) ? '$yearStr $labelSuffix' : null;

    final eps = _toDouble(map['eps']);
    final bps = _toDouble(map['bps']);
    final dps = _toDouble(map['dps']);

    _logDart(
      'KR metrics-lite parsed: '
      'eps=$eps bps=$bps dps=$dps year=$year reprt=$reprtCode fs=$fsDivUsed '
      'basDt=$fiscalBasDt label=$periodLabel',
    );

    return StockFundamentals(
      eps: eps,
      bps: bps,
      dps: dps,
      year: year,
      basDt: fiscalBasDt,
      periodLabel: periodLabel,
      reprtCode: reprtCode,
      fsDiv: fsDivUsed,
      fsSource: 'Worker /kr/metrics-lite',
      epsSource: 'Worker /kr/metrics-lite',
      bpsSource: 'Worker /kr/metrics-lite',
      dpsSource: 'Worker /kr/metrics-lite',
    );
  }

  @override
  Future<StockFinancialDetails> getFinancialDetails(String code, {int? targetYear}) async {
    final c = _normalizeCode(code);
    if (c.isEmpty) throw Exception('code is empty');

    final qs = <String, String>{
      'code': c,
      'reprt_code': '11011',
      'fs_div': 'CFS',
    };

    if (targetYear != null) {
      qs['bsns_year'] = '$targetYear';
    }

    final res = await _workerGet(
      '/kr/financial-details',
      qs,
      tag: 'kr/financial-details',
    );

    if (res.statusCode != 200) {
      throw Exception('KR financial-details HTTP ${res.statusCode}: ${res.body}');
    }

    final map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (map['ok'] != true) {
      throw Exception('KR financial-details failed: ${res.body}');
    }

    final currentMap =
        (map['current'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    final current = StockFundamentals(
      eps: _toDouble(currentMap['eps']),
      bps: _toDouble(currentMap['bps']),
      dps: _toDouble(currentMap['dps']),
      year: currentMap['year'] is num
          ? (currentMap['year'] as num).toInt()
          : int.tryParse('${currentMap['year'] ?? ''}'),
      basDt: currentMap['basDt']?.toString(),
      periodLabel: currentMap['periodLabel']?.toString(),

      epsLabel: currentMap['epsLabel']?.toString(),
      bpsLabel: currentMap['bpsLabel']?.toString(),
      dpsLabel: currentMap['dpsLabel']?.toString(),

      epsSource: currentMap['epsSource']?.toString(),
      bpsSource: currentMap['bpsSource']?.toString(),
      dpsSource: currentMap['dpsSource']?.toString(),
      fsDiv: currentMap['fsDiv']?.toString(),
      reprtCode: currentMap['reprtCode']?.toString(),
      fsSource: currentMap['fsSource']?.toString(),
    );

    final summary =
        (map['summary'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    final analysis =
        (map['analysis'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    num? asNumOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      final s = v.toString().trim();
      if (s.isEmpty) return null;
      return num.tryParse(s);
    }

    return StockFinancialDetails(
      current: current,
      revenue: asNumOrNull(summary['revenue']),
      opIncome: asNumOrNull(summary['opIncome']),
      netIncome: asNumOrNull(summary['netIncome']),
      equity: asNumOrNull(summary['equity']),
      liabilities: asNumOrNull(summary['liabilities']),

      epsAvg3y: _toNullableDouble(analysis['epsAvg3y']),
      roeAvg5y: _toNullableDouble(analysis['roeAvg5y']),
      epsHistory: _parseYearMetrics(analysis['epsHistory']),
      roeHistory: _parseYearMetrics(analysis['roeHistory']),
      lossYears: _parseIntList(analysis['lossYears']),
      debtRatio: _toNullableDouble(analysis['debtRatio']),
      hasDividend: analysis['hasDividend'] == null
          ? null
          : analysis['hasDividend'] == true,
    );
  }

  // =========================
  // DART 파싱/보조
  // =========================
  String _reprtLabelFromCode(String? code) {
    switch (code) {
      case '11011':
        return 'ANNUAL';
      case '11014':
        return 'Q3';
      case '11012':
        return 'HALF';
      case '11013':
        return 'Q1';
      default:
        return '';
    }
  }

  // 피보나치 그래프
  @override
  Future<PriceFibChartData> getPriceFibChart(
    String code, {
    int months = 36,
  }) async {
    final code6 = code.trim();
    if (code6.isEmpty) {
      throw Exception('Empty KR code');
    }

    final base = workerBaseUrl.endsWith('/')
        ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
        : workerBaseUrl;

    final uri = Uri.parse('$base/kr/price-fib').replace(
      queryParameters: {
        'code': code6,
        'months': '$months',
      },
    );

    if (debugLog) {
      debugPrint('[KIS-KR] GET $uri');
    }

    final res = await _client.get(uri).timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      throw Exception('KR price fib HTTP ${res.statusCode}: ${res.body}');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));

    if (body is! Map<String, dynamic>) {
      throw Exception('KR price fib bad response type');
    }

    if (body['ok'] != true) {
      throw Exception('KR price fib failed: ${(body['error'] ?? 'unknown').toString()}');
    }

    return PriceFibChartData.fromJson(body);
  }
}
 