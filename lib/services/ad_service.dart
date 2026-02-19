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

  // ✅ retry/backoff
  int _retryAttempt = 0;
  Timer? _retryTimer;

  // ✅ eligible인데 광고 없으면, 로드되면 바로 show
  bool _pendingShow = false;

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
    if (_useTestAds) return Platform.isAndroid ? _androidBannerTest : _iosBannerTest;
    if (Platform.isAndroid) return _androidBannerProd;
    return _iosBannerTest;
  }

  String get interstitialUnitId {
    if (_useTestAds) return Platform.isAndroid ? _androidInterstitialTest : _iosInterstitialTest;
    if (Platform.isAndroid) return _androidInterstitialProd;
    return _iosInterstitialTest;
  }

  // 앱 시작 시 1회 호출 권장
  void warmUp() {
    _loadInterstitialIfNeeded();
  }

  void onOpenResult() {
    _openResultCount++;
    _loadInterstitialIfNeeded(); // 항상 예열
  }

  bool _isEligibleNow() {
    if (_openResultCount <= 0) return false;
    if (_openResultCount % everyN != 0) return false;

    final last = _lastShownAt;
    if (last == null) return true;

    final diff = DateTime.now().difference(last).inSeconds;
    return diff >= cooldownSeconds;
  }

  // ✅ 핵심: show 요청 시점에 없으면 pending 처리
  Future<void> maybeShowInterstitial() async {
    if (!_isEligibleNow()) return;

    final ad = _interstitial;
    if (ad == null) {
      debugPrint('[ADS] interstitial not ready → pendingShow');
      _pendingShow = true;
      _loadInterstitialIfNeeded(); // 즉시 로드 시도
      return;
    }

    await _showInterstitial(ad);
  }

  Future<void> _showInterstitial(InterstitialAd ad) async {
    _interstitial = null; // 한 번 show하면 재사용 불가

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
    if (_interstitial != null) return;
    if (_loadingInterstitial) return;

    _retryTimer?.cancel();
    _loadingInterstitial = true;

    debugPrint('[ADS] load interstitial... useTest=$_useTestAds unit=$interstitialUnitId');

    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
          _loadingInterstitial = false;
          _retryAttempt = 0;
          _interstitial = ad;

          debugPrint('[ADS] interstitial LOADED ✅');

          // ✅ pendingShow면, 로드되자마자 보여주기(단, 쿨다운 조건은 이미 통과했다고 가정)
          if (_pendingShow && _isEligibleNow()) {
            _pendingShow = false;
            final toShow = _interstitial;
            if (toShow != null) {
              await _showInterstitial(toShow);
            }
          }
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _loadingInterstitial = false;

          debugPrint('[ADS] interstitial FAILED_TO_LOAD ❌ $error (unit=$interstitialUnitId)');

          // ✅ 지수 백오프 재시도 (최대 60초)
          _retryAttempt = (_retryAttempt + 1).clamp(1, 10);
          final delaySec = (2 << (_retryAttempt - 1)).clamp(2, 60);
          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: delaySec), _loadInterstitialIfNeeded);

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