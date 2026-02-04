import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OpenDART API 클라이언트
class OpenDartClient {
  final String apiKey;
  final http.Client _client;
  final bool debugLog;

  OpenDartClient({
    required this.apiKey,
    http.Client? client,
    this.debugLog = false,
  }) : _client = client ?? http.Client();

  void _log(String msg) {
    if (debugLog) debugPrint('[OpenDART] $msg');
  }

  static const _host = 'opendart.fss.or.kr';

  Uri _uri(String path, Map<String, String> qp) {
    final query = <String, String>{
      'crtfc_key': apiKey,
      ...qp,
    };
    return Uri.https(_host, path, query);
  }

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> qp) async {
    final uri = _uri(path, qp);
    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('OpenDART HTTP ${res.statusCode}: ${res.body}');
    }
    final root = jsonDecode(res.body) as Map<String, dynamic>;
    final status = (root['status'] ?? '').toString();
    final message = (root['message'] ?? '').toString();
    if (status.isNotEmpty && status != '000') {
      // 013 = 조회된 데이터가 없음 (일반적)
      _log('status=$status message=$message path=$path qp=$qp');
      throw _OpenDartStatusException(status, message);
    }
    return root;
  }

  /// corp_code 조회 (회사 고유번호)
  Future<String> getCorpCodeByStockCode(String stockCode6) async {
    // 회사개요: https://opendart.fss.or.kr/api/company.json
    // 단, 이 API는 corp_code를 직접 stock_code로 조회 가능
    final root = await _getJson('/api/company.json', {
      'stock_code': stockCode6,
    });
    final corp = (root['corp_code'] ?? '').toString().trim();
    return corp;
  }

  /// 단일회사 주요계정(재무제표): https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json
  Future<List<Map<String, dynamic>>> fnlttSinglAcntAll({
    required String corpCode,
    required int year,
    required String reprtCode, // 11013 1Q / 11012 반기 / 11014 3Q / 11011 사업보고서
    required String fsDiv,     // 'CFS' or 'OFS'
  }) async {
    try {
      final root = await _getJson('/api/fnlttSinglAcntAll.json', {
        'corp_code': corpCode,
        'bsns_year': year.toString(),
        'reprt_code': reprtCode,
        'fs_div': fsDiv,
      });

      final list = root['list'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on _OpenDartStatusException catch (e) {
      // 데이터 없음(013) 등을 빈 리스트로 처리
      if (e.status == '013') return [];
      rethrow;
    }
  }

  /// 배당: https://opendart.fss.or.kr/api/alotMatter.json
  Future<List<Map<String, dynamic>>> alotMatter({
    required String corpCode,
    required int year,
  }) async {
    try {
      final root = await _getJson('/api/alotMatter.json', {
        'corp_code': corpCode,
        'bsns_year': year.toString(),
      });
      final list = root['list'];
      if (list is! List) return [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } on _OpenDartStatusException catch (e) {
      if (e.status == '013') return [];
      rethrow;
    }
  }
}

class _OpenDartStatusException implements Exception {
  final String status;
  final String message;
  _OpenDartStatusException(this.status, this.message);
  @override
  String toString() => 'OpenDART status=$status message=$message';
}
