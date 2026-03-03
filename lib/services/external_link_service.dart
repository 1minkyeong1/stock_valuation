import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

enum NaverWorldPage { total, discussion }

class ExternalLinkService {
  const ExternalLinkService();

  // 간단 캐시(같은 티커 반복 오픈 시 네트워크 절약)
  static final Map<String, _CacheEntry> _worldCodeCache = {};

  // 캐시 유효기간(원하면 줄이거나 늘리세요)
  static const Duration _cacheTtl = Duration(days: 7);

  Future<bool> openInExternalBrowser(String url) async {
    final uri = Uri.parse(url);

    if (Platform.isAndroid) {
      // 1) Chrome 우선
      final okChrome =
          await _tryAndroidBrowser(url, package: 'com.android.chrome');
      if (okChrome) return true;

      // 2) Samsung Internet
      final okSamsung =
          await _tryAndroidBrowser(url, package: 'com.sec.android.app.sbrowser');
      if (okSamsung) return true;

      // 3) fallback
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openNaverFinance({
    required String rawCodeOrTicker,
    NaverWorldPage worldPage = NaverWorldPage.total,
  }) async {
    final raw = rawCodeOrTicker.trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    // ✅ 국내 6자리
    if (digits.length == 6) {
      final url = 'https://finance.naver.com/item/main.naver?code=$digits';
      return openInExternalBrowser(url);
    }

    // ✅ 해외: "브라우저로 여러 번 던지기" 대신
    //    네이버 stock basic API로 실제 존재하는 코드를 먼저 찾고 1번만 오픈
    final resolvedCode = await _resolveNaverWorldCode(raw);
    if (resolvedCode != null) {
      final base = 'https://m.stock.naver.com/worldstock/stock/$resolvedCode';
      final url = (worldPage == NaverWorldPage.discussion)
          ? '$base/discussion'
          : '$base/total';
      return openInExternalBrowser(url);
    }

    // ✅ 못 찾으면(매핑 실패) 그래도 앱이 "아예 안 열리는" 상황은 피하려고
    //    해외토론 랭킹으로 fallback (원하면 다른 fallback으로 교체)
    return openInExternalBrowser(
      'https://m.stock.naver.com/worldstock/home/USA/discussion/ranking',
    );
  }

  /// 사용자가 입력한 티커를 네이버 worldstock "실제 코드(reutersCode)"로 해석
  /// - 예) AAPL -> AAPL.O (나스닥인 경우)
  /// - 예) KO   -> KO (NYSE는 suffix 없이도 등록된 경우가 많음)
  /// - 예) BRK-A/BRK.A -> BRKa, BRK-B/BRK.B -> BRKb
  Future<String?> _resolveNaverWorldCode(String rawTicker) async {
    final key = rawTicker.trim().toUpperCase();

    // 캐시
    final cached = _worldCodeCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.savedAt) <= _cacheTtl) {
      return cached.reutersCode;
    }

    final candidates = _buildWorldCodeCandidates(rawTicker);

    for (final code in candidates) {
      final basic = await _fetchNaverBasic(code);
      if (basic == null) continue;

      final reutersCode = basic['reutersCode'];
      final stockEndUrl = basic['stockEndUrl'] ?? basic['endUrl'];

      // 최소한의 유효성 체크
      if (reutersCode is String && stockEndUrl is String && stockEndUrl.isNotEmpty) {
        _worldCodeCache[key] = _CacheEntry(reutersCode: reutersCode);
        return reutersCode;
      }
    }

    return null;
  }

  /// 네이버에 실제로 존재할 법한 코드 후보 생성
  List<String> _buildWorldCodeCandidates(String rawTicker) {
    final t0 = rawTicker.trim().toUpperCase();
    final tDot = t0.replaceAll('-', '.'); // BRK-A -> BRK.A

    // 1) 클래스주 패턴: AAA.B -> AAAb (네이버는 BRKa/BRKb처럼 쓰는 케이스가 있음)
    final classLower = _toClassLowerCode(tDot); // ex) BRK.A -> BRKa

    // 2) 점 제거 버전 (일반적으로 네이버 worldstock code는 '.'를 그대로 쓰는 경우가 드뭅니다)
    final plain = tDot.replaceAll('.', '');

    // 3) 기본 후보 목록
    final list = <String>[
      if (classLower != null) classLower,

      // 나스닥은 .O가 필요한 경우가 많아서 우선순위를 조금 높임
      '$plain.O',

      // NYSE 등은 suffix 없이 plain이 등록된 경우가 많음 (KO 같은 케이스)
      plain,

      // 아래는 실제로 쓰이는 경우가 적지만, 혹시 몰라 후보로 남김
      '$plain.N',
      '$plain.A',
      '$plain.K',
    ];

    // 중복 제거 + 빈값 제거
    final seen = <String>{};
    final out = <String>[];
    for (final s in list) {
      final v = s.trim();
      if (v.isEmpty) continue;
      if (seen.add(v)) out.add(v);
    }
    return out;
  }

  String? _toClassLowerCode(String tDot) {
    final m = RegExp(r'^([A-Z0-9]+)\.([A-Z])$').firstMatch(tDot);
    if (m == null) return null;
    final base = m.group(1)!;
    final cls = m.group(2)!.toLowerCase();
    return '$base$cls';
  }

  Future<Map<String, dynamic>?> _fetchNaverBasic(String code) async {
    final uri = Uri.parse('https://api.stock.naver.com/stock/$code/basic');

    try {
      final res = await http
          .get(
            uri,
            headers: const {
              // 네이버 쪽에서 UA 없으면 막히는 케이스가 있어 브라우저 UA 흉내
              'User-Agent': 'Mozilla/5.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 2));

      if (res.statusCode != 200) return null;

      final body = utf8.decode(res.bodyBytes);
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _tryAndroidBrowser(String url, {required String package}) async {
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: url,
        package: package,
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _CacheEntry {
  _CacheEntry({required this.reutersCode}) : savedAt = DateTime.now();
  final String reutersCode;
  final DateTime savedAt;
}