import 'dart:convert' show jsonDecode, utf8;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// ✅ Worker(/dart/*)만 호출하는 OpenDART 프록시 클라이언트
/// - 키는 Worker에만 존재
/// - 앱에는 workerBaseUrl만 설정
class DartProxyClient {
  final String workerBaseUrl; // 예: http://192.168.0.69:8787
  final http.Client _client;
  final bool debugLog;

  DartProxyClient({
    required this.workerBaseUrl,
    http.Client? client,
    this.debugLog = false,
  }) : _client = client ?? http.Client();

  // void _log(String msg) {
  //   if (debugLog) debugPrint('[DartProxy] $msg');
  // }

  Uri _uri(String path, Map<String, String> qp) {
    final base = workerBaseUrl.endsWith('/')
        ? workerBaseUrl.substring(0, workerBaseUrl.length - 1)
        : workerBaseUrl;

    final u = Uri.parse('$base$path');

    // 기존 query + qp merge (qp가 우선)
    final merged = {...u.queryParameters, ...qp};
    return u.replace(queryParameters: merged);
  }

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> qp) async {
    // ✅ 캐시 버스트(항상 새 요청)
    final qp2 = {
      ...qp,
      'cb': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final uri = _uri(path, qp2);
    debugPrint('[DartProxy] GET $uri');

    final res = await _client.get(
      uri,
      headers: {
        'accept': 'application/json,text/plain,*/*',

        // ✅ 캐시 금지(클라/프록시 방어)
        'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    final bodyText = utf8.decode(res.bodyBytes);

    if (res.statusCode != 200) {
      debugPrint('[DartProxy] HTTP ${res.statusCode} body=$bodyText');
      throw Exception('Worker HTTP ${res.statusCode}: $bodyText');
    }

    final root = jsonDecode(bodyText);
    if (root is! Map<String, dynamic>) {
      throw Exception('Worker response is not a JSON object: $bodyText');
    }
    if (root['error'] != null) {
      throw Exception('Worker error: ${root['error']} ${root['message'] ?? ''}');
    }
    return root;
  }

  /// ✅ corp_code 조회 (Worker의 정적 corp_map.json 활용)
  /// /dart/corp?stock=005930 -> { stock, corp_code }
  Future<String?> getCorpCodeByStockCode(String stockCode6) async {
    debugPrint('corp lookup stock=$stockCode6');
    final root = await _getJson('/dart/corp', {'stock': stockCode6});
    final corp = (root['corp_code'] ?? '').toString().trim();
    debugPrint('corp lookup result stock=$stockCode6 corp="$corp"');
    return corp.isEmpty ? null : corp;
  }

  /// ✅ 공시 목록(정기보고서 찾는 용도)
  /// /dart/list?corp_code=...&bgn_de=...&end_de=...&page_no=1&page_count=100&sort=date&sort_mth=desc
  Future<List<Map<String, dynamic>>> list({
    required String corpCode,
    required String bgnDe,
    required String endDe,
    int pageNo = 1,
    int pageCount = 100,
    String sort = 'date',
    String sortMth = 'desc',
  }) async {
    final root = await _getJson('/dart/list', {
      'corp_code': corpCode,
      'bgn_de': bgnDe,
      'end_de': endDe,
      'page_no': '$pageNo',
      'page_count': '$pageCount',
      'sort': sort,
      'sort_mth': sortMth,
    });

    final raw = root['list'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// ✅ 단일회사 주요계정(재무제표)
  /// /dart/fnltt?corp_code=...&bsns_year=2025&reprt_code=11014&fs_div=CFS
  Future<List<Map<String, dynamic>>> fnlttSinglAcntAll({
    required String corpCode,
    required int year,
    required String reprtCode, // 11013/11012/11014/11011
    String fsDiv = 'CFS',
  }) async {
    debugPrint('fnltt call corp=$corpCode year=$year reprt=$reprtCode fs=$fsDiv');

    // ✅ corp_code 누락 방어 (지금 에러가 "corp_code 누락"이라서 유용)
    if (corpCode.trim().isEmpty) {
      throw Exception('fnlttSinglAcntAll: corpCode is empty');
    }

    final root = await _getJson('/dart/fnltt', {
      'corp_code': corpCode,
      'bsns_year': year.toString(),
      'reprt_code': reprtCode,
      'fs_div': fsDiv,
    });

    final raw = root['list'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// ✅ 배당
  /// /dart/alot?corp_code=...&bsns_year=2025&reprt_code=11014 (worker가 reprt_code optional로 받게 했으면 더 좋음)
  Future<List<Map<String, dynamic>>> alotMatter({
    required String corpCode,
    required int year,
    String reprtCode = '11011', // Worker 구현이 reprt_code 필수라면 기본값 필요
  }) async {
    final root = await _getJson('/dart/alot', {
      'corp_code': corpCode,
      'bsns_year': year.toString(),
      'reprt_code': reprtCode,
    });

    final raw = root['list'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  void close() => _client.close();
}
