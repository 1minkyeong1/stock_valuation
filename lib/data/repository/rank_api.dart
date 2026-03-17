import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RankApiResponse<T> {
  final bool ok;
  final String? error;
  final String? message;
  final String? generatedAt;
  final List<T> items;
  final Map<String, dynamic> raw;

  RankApiResponse({
    required this.ok,
    required this.items,
    required this.raw,
    this.error,
    this.message,
    this.generatedAt,
  });

  static RankApiResponse<T> fromJson<T>(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final itemsJson = (j['items'] as List?) ?? const [];
    final parsed = <T>[];

    for (int i = 0; i < itemsJson.length; i++) {
      final row = itemsJson[i];
      if (row is! Map) continue;

      try {
        parsed.add(itemParser(row.cast<String, dynamic>()));
      } catch (e, st) {
        debugPrint('[RankApi] item parse failed index=$i error=$e');
        debugPrint('[RankApi] raw row=$row');
        debugPrint('$st');
      }
    }

    return RankApiResponse<T>(
      ok: j['ok'] == true,
      error: j['error']?.toString(),
      message: j['message']?.toString(),
      generatedAt: j['generatedAt']?.toString(),
      items: parsed,
      raw: j,
    );
  }

  bool get isNotReady => ok == false && error == 'RANKING_NOT_READY';
}

Future<RankApiResponse<T>> fetchRankingWithRetry<T>({
  required Uri url,
  required T Function(Map<String, dynamic>) itemParser,
  Map<String, String>? headers,
  Duration timeout = const Duration(seconds: 20),
  int retryOnceAfterSecondsIfNotReady = 3,
}) async {
  Future<RankApiResponse<T>> once() async {
    final res = await http
        .get(url, headers: {'accept': 'application/json', ...?headers})
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final obj = jsonDecode(res.body);

    if (obj is List) {
      final parsed = <T>[];

      for (int i = 0; i < obj.length; i++) {
        final row = obj[i];
        if (row is! Map) continue;

        try {
          parsed.add(itemParser(row.cast<String, dynamic>()));
        } catch (e, st) {
          debugPrint('[RankApi] list item parse failed index=$i error=$e');
          debugPrint('[RankApi] raw row=$row');
          debugPrint('$st');
        }
      }

      return RankApiResponse<T>(
        ok: true,
        items: parsed,
        raw: {'ok': true, 'items': obj},
        generatedAt: null,
      );
    }

    if (obj is! Map) {
      return RankApiResponse<T>(
        ok: false,
        error: 'BAD_RESPONSE',
        message: 'Response is not a JSON object',
        items: const [],
        raw: {'raw': obj},
        generatedAt: null,
      );
    }

    return RankApiResponse.fromJson<T>(
      obj.cast<String, dynamic>(),
      itemParser,
    );
  }

  final first = await once();

  if (first.isNotReady && retryOnceAfterSecondsIfNotReady > 0) {
    await Future.delayed(
      Duration(seconds: retryOnceAfterSecondsIfNotReady),
    );
    return await once();
  }

  return first;
}