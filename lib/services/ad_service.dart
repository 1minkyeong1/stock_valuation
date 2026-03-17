import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService._();
  static final AdService I = AdService._();

  /// 광고 전체 ON/OFF
  bool adsEnabled = true;

  /// 3회마다 전면광고
  int everyN = 3;

  /// 전면광고 쿨다운(초)
  int cooldownSeconds = 120;

  int _openResultCount = 0;
  DateTime? _lastShownAt;

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  int _retryAttempt = 0;
  Timer? _retryTimer;

  static const bool _forceTestAds =
      bool.fromEnvironment('TEST_ADS', defaultValue: false);

  bool get _useTestAds => _forceTestAds || !kReleaseMode;

  bool get isInterstitialEligibleNow => _isEligibleNow();
  bool get hasReadyInterstitial => _interstitial != null;

  // ------------------------------------------------------------
  // ✅ 본인 광고 단위 ID(ANDROID)만 여기에 넣으세요 (ca-app-pub-xxx/yyy)
  // ------------------------------------------------------------
  static const String _androidBannerProd = 'ca-app-pub-4855768071671191/9260415794';
  static const String _androidInterstitialProd = 'ca-app-pub-4855768071671191/7923293139';

  static const String _iosBannerProd = 'ca-app-pub-4855768071671191/7031859195';
  static const String _iosInterstitialProd = 'ca-app-pub-4855768071671191/8837094563';

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
    return _iosBannerProd;
  }

  String get interstitialUnitId {
    if (_useTestAds) {
      return Platform.isAndroid
          ? _androidInterstitialTest
          : _iosInterstitialTest;
    }
    if (Platform.isAndroid) return _androidInterstitialProd;
    return _iosInterstitialProd;
  }

  /// 앱 시작 시 1회 호출 권장
  void warmUp() {
    if (!adsEnabled) return;
    _loadInterstitialIfNeeded();
  }

  void onOpenResult() {
    _openResultCount++;
    if (!adsEnabled) return;
    _loadInterstitialIfNeeded();
  }

  bool _isEligibleNow() {
    if (!adsEnabled) return false;
    if (_openResultCount <= 0) return false;
    if (_openResultCount % everyN != 0) return false;

    final last = _lastShownAt;
    if (last == null) return true;

    final diff = DateTime.now().difference(last).inSeconds;
    return diff >= cooldownSeconds;
  }

  /// 준비된 광고가 있을 때만 표시
  Future<void> maybeShowInterstitial() async {
    if (!adsEnabled) return;
    if (!_isEligibleNow()) return;

    final ad = _interstitial;
    if (ad == null) {
      debugPrint('[ADS] interstitial not ready → skip');
      _loadInterstitialIfNeeded();
      return;
    }

    await _showInterstitial(ad);
  }

  Future<void> _showInterstitial(InterstitialAd ad) async {
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

  void _loadInterstitialIfNeeded() {
    if (!adsEnabled) return;
    if (_interstitial != null) return;
    if (_loadingInterstitial) return;

    _retryTimer?.cancel();
    _loadingInterstitial = true;

    debugPrint(
      '[ADS] load interstitial... useTest=$_useTestAds unit=$interstitialUnitId',
    );

    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          _retryAttempt = 0;
          _interstitial = ad;
          debugPrint('[ADS] interstitial LOADED ✅');
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _loadingInterstitial = false;

          debugPrint(
            '[ADS] interstitial FAILED_TO_LOAD ❌ $error (unit=$interstitialUnitId)',
          );

          _retryAttempt = (_retryAttempt + 1).clamp(1, 10);
          final delaySec = (2 << (_retryAttempt - 1)).clamp(2, 60);

          _retryTimer?.cancel();
          _retryTimer = Timer(
            Duration(seconds: delaySec),
            _loadInterstitialIfNeeded,
          );

          debugPrint('[ADS] retry in ${delaySec}s (attempt=$_retryAttempt)');
        },
      ),
    );
  }

  void dispose() {
    _retryTimer?.cancel();
    _interstitial?.dispose();
    _interstitial = null;
  }
}