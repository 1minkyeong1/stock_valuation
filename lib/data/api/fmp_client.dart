import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    final base = workerBaseUrl.endsWith('/')
        ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
        : workerBaseUrl;
    return Uri.parse('$base$path').replace(queryParameters: q);
  }

  List<dynamic>? _extractList(dynamic body) {
    if (body is List) return body;

    if (body is Map) {
      // ✅ Worker wrapper: { items: [...] }
      final items = body['items'];
      if (items is List) return items;

      // ✅ Some APIs: { data: [...] }
      final data = body['data'];
      if (data is List) return data;

      // ✅ Some FMP endpoints: { historical: [...] }
      final hist = body['historical'];
      if (hist is List) return hist;

      // ✅ Fallback: { results: [...] }
      final results = body['results'];
      if (results is List) return results;
    }
    return null;
  }

  Future<dynamic> _getJson(String path, Map<String, String> q) async {
    final uri = _u(path, q);
    if (debugLog && kDebugMode) debugPrint('[FMP] GET $uri');

    final res = await _http.get(uri).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('FMP HTTP ${res.statusCode}: ${res.body}');
    }
    return jsonDecode(res.body);
  }

  Future<List<Map<String, dynamic>>> _getListMap(
    String path,
    Map<String, String> q,
  ) async {
    final body = await _getJson(path, q);
    final list = _extractList(body);
    if (list == null) return const [];

    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>?> _getOne(
    String path,
    Map<String, String> q,
  ) async {
    final list = await _getListMap(path, q);
    if (list.isEmpty) return null;
    return list.first;
  }

  // =========================
  // Search (Worker /fmp/search returns Map)
  // =========================
  Future<Map<String, dynamic>> search(String query, {String? ex}) async {
    final q = <String, String>{'query': query};
    if (ex != null && ex.trim().isNotEmpty) q['ex'] = ex.trim();

    final body = await _getJson('/fmp/search', q);
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is List) return {'ok': true, 'items': body};
    return {'ok': false, 'items': const []};
  }

  // =========================
  // Normalized price
  // Worker: /fmp/price -> {ok,symbol,price,marketCap,exchange,currency,source,ts}
  // =========================
  Future<Map<String, dynamic>> priceNormalized(String symbol, {bool raw = false}) async {
    final body = await _getJson('/fmp/price', {
      'symbol': symbol,
      if (raw) 'raw': '1',
    });

    if (body is Map) return Map<String, dynamic>.from(body);
    return {'ok': false, 'symbol': symbol, 'error': 'BAD_RESPONSE_TYPE'};
  }

  // =========================
  // ✅ NEW: BPS normalized (Worker /fmp/bps)
  // {ok,symbol,bps,source,ts,error?}
  // =========================
  Future<Map<String, dynamic>> bpsNormalized(String symbol, {bool debug = false}) async {
    final body = await _getJson('/fmp/bps', {
      'symbol': symbol,
      if (debug) 'debug': '1',
    });
    if (body is Map) return Map<String, dynamic>.from(body);
    return {'ok': false, 'symbol': symbol, 'error': 'BAD_RESPONSE_TYPE'};
  }

  // =========================
  // Existing endpoints
  // =========================

  Future<List<Map<String, dynamic>>> incomeStatement({
    required String symbol,
    int limit = 12,
  }) {
    return _getListMap('/fmp/income-statement', {'symbol': symbol, 'limit': '$limit'});
  }

  Future<List<Map<String, dynamic>>> balanceSheet({
    required String symbol,
    int limit = 1,
  }) {
    return _getListMap('/fmp/balance-sheet-statement', {'symbol': symbol, 'limit': '$limit'});
  }

  Future<Map<String, dynamic>?> profileOne(String symbol) {
    return _getOne('/fmp/profile', {'symbol': symbol});
  }

  Future<List<Map<String, dynamic>>> dividends({
    required String symbol,
    int limit = 40,
  }) async {
    final list = await _getListMap('/fmp/dividends', {'symbol': symbol});
    return list.take(limit).toList();
  }

  void close() => _http.close();
}