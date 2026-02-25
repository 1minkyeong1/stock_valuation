import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLinkService {
  const ExternalLinkService();

  Future<bool> openInExternalBrowser(String url) async {
    final uri = Uri.parse(url);

    if (Platform.isAndroid) {
      // 1) Chrome 우선
      final okChrome = await _tryAndroidBrowser(url, package: 'com.android.chrome');
      if (okChrome) return true;

      // 2) Samsung Internet
      final okSamsung = await _tryAndroidBrowser(url, package: 'com.sec.android.app.sbrowser');
      if (okSamsung) return true;

      // 3) fallback
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> openNaverFinance({
    required String rawCodeOrTicker,
  }) async {
    final raw = rawCodeOrTicker.trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    // ✅ 국내 6자리
    if (digits.length == 6) {
      final url = 'https://finance.naver.com/item/main.naver?code=$digits';
      return openInExternalBrowser(url);
    }

    // ✅ 해외 티커 후보 URL 순차 시도
    final sym = normalizeWorldTicker(raw);

    final candidates = <String>[
      'https://m.stock.naver.com/worldstock/stock/$sym.O/total',
      'https://m.stock.naver.com/worldstock/stock/$sym.O/discussion',
      'https://m.stock.naver.com/worldstock/stock/$sym.K/total',
      'https://m.stock.naver.com/worldstock/stock/$sym.K/discussion',
      'https://m.stock.naver.com/worldstock/stock/$sym.N/total',
      'https://m.stock.naver.com/worldstock/stock/$sym.N/discussion',
      'https://m.stock.naver.com/worldstock/stock/$sym/total',
      'https://m.stock.naver.com/worldstock/stock/$sym/discussion',
      'https://m.stock.naver.com/worldstock/home/USA/discussion/ranking',
    ];

    for (final url in candidates) {
      final ok = await openInExternalBrowser(url);
      if (ok) return true;
    }
    return false;
  }

  String normalizeWorldTicker(String ticker) {
    final t = ticker.toUpperCase().trim();
    if (t == 'BRK.A') return 'BRKa';
    if (t == 'BRK.B') return 'BRKb';
    return t.replaceAll('.', '');
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