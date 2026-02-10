import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService I = AdService._();

  /// ✅ 3회마다 전면광고
  int everyN = 3;

  /// ✅ 전면광고 쿨다운(초)
  int cooldownSeconds = 120;

  int _openResultCount = 0;
  DateTime? _lastShownAt;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  /// ✅ 릴리즈에서도 테스트광고 강제:
  /// flutter run --release --dart-define=TEST_ADS=true
  static const bool _forceTestAds =
      bool.fromEnvironment('TEST_ADS', defaultValue: false);

  bool get _useTestAds => _forceTestAds || !kReleaseMode;

  // ------------------------------------------------------------
  // ✅ 본인 광고 단위 ID(ANDROID)만 여기에 넣으세요 (ca-app-pub-xxx/yyy)
  // ------------------------------------------------------------
  static const String _androidBannerProd = 'ca-app-pub-4855768071671191/9260415794';
  static const String _androidInterstitialProd = 'ca-app-pub-4855768071671191/7923293139';

  // ------------------------------------------------------------
  // ✅ AdMob 공식 테스트 광고 단위 ID
  // ------------------------------------------------------------
  static const String _androidBannerTest = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosInterstitialTest = 'ca-app-pub-3940256099942544/4411468910';

  String get bannerUnitId {
    if (_useTestAds) {
      return Platform.isAndroid ? _androidBannerTest : _iosBannerTest;
    }
    if (Platform.isAndroid) return _androidBannerProd;

    // iOS 아직 없으면 일단 테스트ID로 둬도 OK (iOS 빌드할 때 교체)
    return _iosBannerTest;
  }

  String get interstitialUnitId {
    if (_useTestAds) {
      return Platform.isAndroid ? _androidInterstitialTest : _iosInterstitialTest;
    }
    if (Platform.isAndroid) return _androidInterstitialProd;
    return _iosInterstitialTest;
  }

  // ---------------------------
  // 로드 / 준비
  // ---------------------------
  void warmUp() {
    _loadInterstitialIfNeeded();
  }

  void _loadInterstitialIfNeeded() {
    if (_interstitial != null) return;
    if (_loadingInterstitial) return;

    _loadingInterstitial = true;

    debugPrint('[ADS] load interstitial... useTest=$_useTestAds unit=$interstitialUnitId');

    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
          debugPrint('[ADS] interstitial LOADED ✅');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              _lastShownAt = DateTime.now();
              debugPrint('[ADS] interstitial SHOWED ✅');
            },
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[ADS] interstitial DISMISSED');
              ad.dispose();
              _interstitial = null;
              _loadInterstitialIfNeeded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[ADS] interstitial FAILED_TO_SHOW ❌ $error');
              ad.dispose();
              _interstitial = null;
              _loadInterstitialIfNeeded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _loadingInterstitial = false;
          debugPrint('[ADS] interstitial FAILED_TO_LOAD ❌ $error (unit=$interstitialUnitId)');
        },
      ),
    );
  }

  // ---------------------------
  // ✅ “종목 상세 열기” 카운트 증가
  // ---------------------------
  void onOpenResult() {
    _openResultCount++;
    _loadInterstitialIfNeeded();
  }

  bool _isEligibleNow() {
    if (_openResultCount <= 0) return false;
    if (_openResultCount % everyN != 0) return false;

    final last = _lastShownAt;
    if (last == null) return true;

    final diff = DateTime.now().difference(last).inSeconds;
    return diff >= cooldownSeconds;
  }

  Future<void> maybeShowInterstitial() async {
    if (!_isEligibleNow()) return;

    final ad = _interstitial;

    if (ad == null) {
      debugPrint('[ADS] not ready yet → skip show');
      _loadInterstitialIfNeeded();
      return;
    }

    _interstitial = null;

    final completer = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastShownAt = DateTime.now();
        debugPrint('[ADS] interstitial SHOWED ✅');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[ADS] interstitial DISMISSED');
        ad.dispose();
        _loadInterstitialIfNeeded();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[ADS] interstitial FAILED_TO_SHOW ❌ $error');
        ad.dispose();
        _loadInterstitialIfNeeded();
        if (!completer.isCompleted) completer.complete();
      },
    );

    ad.show();
    await completer.future;
  }
}
