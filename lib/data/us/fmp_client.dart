import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:http/http.dart' as http;

class FmpClient {
  final String workerBaseUrl;
  final bool debugLog;
  final http.Client _http;

  FmpClient({
    required this.workerBaseUrl,
    this.debugLog = false,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  Uri _u(String path, Map<String, String> q) {
    // workerBaseUrl 끝에 / 있든 없든 안전하게
    final base = workerBaseUrl.endsWith('/')
        ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
        : workerBaseUrl;

    return Uri.parse('$base$path').replace(queryParameters: q);
  }

  Future<dynamic> _getJson(String path, Map<String, String> q) async {
    final uri = _u(path, q);
    if (debugLog && kDebugMode) debugPrint('[FMP-WORKER] GET $uri');

    // ✅ 여기서 타임아웃을 강제해야 "무한 대기"가 안 생깁니다.
    final res = await _http
        .get(uri)
        .timeout(const Duration(seconds: 6)); // 가격/재무 각각 6초 내 응답 유도

    if (res.statusCode != 200) {
      throw Exception('FMP-WORKER HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> _getList(String path, Map<String, String> q) async {
    final body = await _getJson(path, q);

    // 1) 이미 List면 그대로
    if (body is List) return body;

    // 2) Map 래퍼 처리
    if (body is Map) {
      // FMP에서 흔히 쓰는 래퍼 키들
      const candidates = [
        'data',
        'historical',
        'results',
        'items',
        'profile',
      ];

      for (final k in candidates) {
        final v = body[k];
        if (v is List) return v;
      }

      // 3) 래퍼가 없고 Map 한 덩어리만 오는 경우(드물지만 존재)
      // 이 경우 "리스트 1개짜리"로 만들어서 상위 로직이 계속 동작하게 함
      return [body];
    }

    return const [];
  }

Future<Map<String, dynamic>?> _getMapOne(String path, Map<String, String> q) async {
  final body = await _getJson(path, q);

  // 1) Map 한 덩어리면 그대로
  if (body is Map) {
    return Map<String, dynamic>.from(body);
  }

  // 2) List면 첫 요소를 Map으로
  if (body is List && body.isNotEmpty) {
    final first = body.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) return Map<String, dynamic>.from(first);
  }

  // 3) 나머지는 _getList로 한번 더 시도(래퍼형/혼합형 대응)
  final list = await _getList(path, q);
  if (list.isEmpty) return null;
  final first = list.first;
  if (first is Map<String, dynamic>) return first;
  if (first is Map) return Map<String, dynamic>.from(first);

  return null;
}

  // -------------------------
  // Worker: 검색
  // GET /fmp/search?query=...
  // -------------------------
  Future<List<dynamic>> searchSymbol(String query) {
    return _getList('/fmp/search', {'query': query});
  }

  // -------------------------
  // Worker: 현재가/시세
  // GET /fmp/quote?symbol=...
  // -------------------------
  Future<Map<String, dynamic>?> quoteOne(String symbol) {
    return _getMapOne('/fmp/quote', {'symbol': symbol});
  }

  // -------------------------
  // Worker: key-metrics-ttm
  // GET /fmp/key-metrics-ttm?symbol=...
  // -------------------------
  Future<Map<String, dynamic>?> keyMetricsTtmOne(String symbol) {
    return _getMapOne('/fmp/key-metrics-ttm', {'symbol': symbol});
  }

  // -------------------------
  // Worker: income-statement
  // GET /fmp/income-statement?symbol=...&period=...&limit=...
  // -------------------------
  Future<List<dynamic>> incomeStatement({
    required String symbol,
    required String period,
    required int limit,
  }) {
    return _getList('/fmp/income-statement', {
      'symbol': symbol,
      'period': period,
      'limit': limit.toString(),
    });
  }

  // -------------------------
  // Worker: balance-sheet-statement
  // GET /fmp/balance-sheet-statement?symbol=...&period=...&limit=...
  // -------------------------
  Future<List<Map<String, dynamic>>> balanceSheetStatement({
    required String symbol,
    required String period,
    int limit = 8,
  }) async {
    final list = await _getList('/fmp/balance-sheet-statement', {
      'symbol': symbol,
      'period': period,
      'limit': limit.toString(),
    });

    return list
        .map((e) => (e is Map<String, dynamic>) ? e : Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // -------------------------
  // Worker: profile
  // GET /fmp/profile?symbol=...
  // -------------------------
  Future<Map<String, dynamic>?> profileOne(String symbol) {
    return _getMapOne('/fmp/profile', {'symbol': symbol});
  }

  // -------------------------
  // Worker: dividends
  // GET /fmp/dividends?symbol=...
  // -------------------------
  Future<List<Map<String, dynamic>>> dividendsCompany({
    required String symbol,
    int limit = 40,
  }) async {
    final list = await _getList('/fmp/dividends', {'symbol': symbol});
    final mapped = list
        .map((e) => (e is Map<String, dynamic>) ? e : Map<String, dynamic>.from(e as Map))
        .toList();

    if (mapped.length <= limit) return mapped;
    return mapped.take(limit).toList();
  }

  void close() => _http.close();
}
