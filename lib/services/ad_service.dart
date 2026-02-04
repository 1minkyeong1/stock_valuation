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

  // ---------------------------
  // ✅ 테스트 광고 ID (AdMob 공식)
  // ---------------------------
  String get bannerUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    // ignore: todo
    // TODO: 여기에 본인 AdMob 배너 유닛ID로 교체
    return Platform.isAndroid
        ? 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx'
        : 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  }

  String get interstitialUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    // ignore: todo
    // TODO: 여기에 본인 AdMob 전면 유닛ID로 교체
    return Platform.isAndroid
        ? 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx'
        : 'ca-app-pub-xxxxxxxxxxxxxxxx/xxxxxxxxxx';
  }

  // ---------------------------
  // 로드 / 준비
  // ---------------------------
  void warmUp() {
    // 앱 시작 시 미리 1번 준비해두면 좋음
    _loadInterstitialIfNeeded();
  }

  void _loadInterstitialIfNeeded() {
    if (_interstitial != null) return;
    if (_loadingInterstitial) return;

    _loadingInterstitial = true;

    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial = null;
              // 다음 광고 미리 로드
              _loadInterstitialIfNeeded();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitial = null;
              _loadInterstitialIfNeeded();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitial = null;
          _loadingInterstitial = false;
        },
      ),
    );
  }

  // ---------------------------
  // ✅ “종목 상세 열기” 카운트 증가
  // ---------------------------
  void onOpenResult() {
    _openResultCount++;
    // 카운트가 올라갈수록 로드 확률 올리기
    _loadInterstitialIfNeeded();
  }

  bool _isEligibleNow() {
    // 3회마다만
    if (_openResultCount <= 0) return false;
    if (_openResultCount % everyN != 0) return false;

    // 쿨다운 체크
    final last = _lastShownAt;
    if (last == null) return true;

    final diff = DateTime.now().difference(last).inSeconds;
    return diff >= cooldownSeconds;
  }

  /// ✅ 네비게이션 직전/직후 “자연스러운 지점”에서 호출
  /// - 광고가 없거나 조건이 아니면 그냥 바로 리턴(사용자 흐름 안 막음)
  Future<void> maybeShowInterstitial() async {
    if (!_isEligibleNow()) return;

    // 준비된 광고가 없으면: 로드만 걸고 스킵
    if (_interstitial == null) {
      _loadInterstitialIfNeeded();
      return;
    }

    final ad = _interstitial;
    _interstitial = null; // show 중복 방지

    final completer = Completer<void>();

    ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        // 기록
        _lastShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialIfNeeded();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialIfNeeded();
        if (!completer.isCompleted) completer.complete();
      },
    );

    // show
    ad.show();
    await completer.future;
  }
}
