import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> with WidgetsBindingObserver {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;

  bool _loading = false;

  int _retryAttempt = 0;
  Timer? _retryTimer;

  // ✅ 너무 잦은 요청을 막는 쿨다운
  DateTime? _lastRequestAt;
  static const int _minRequestIntervalSec = 30;

  // ✅ 백그라운드에서는 로드/재시도 중지
  bool _isForeground = true;

  // 마지막으로 관측된 width (재시도 타이머에서 사용)
  double _lastWidth = 0;

  String get _unit => AdService.I.bannerUnitId;
  void _log(String msg) => debugPrint('[ADS][BANNER] $msg');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = (state == AppLifecycleState.resumed);

    if (!_isForeground) {
      // 백그라운드: 불필요한 요청/타이머 중지
      _retryTimer?.cancel();
      return;
    }

    // 포그라운드 복귀: 다음 build에서 다시 로드될 수 있게 준비
    if (_ad == null && _lastWidth > 0) {
      Future.microtask(() => _loadForWidth(_lastWidth));
    }
  }

  int _nextDelaySec(int attempt) {
    // ✅ 강한 백오프: 30s, 60s, 120s, 300s(상한 5분)
    if (attempt <= 1) return 30;
    if (attempt == 2) return 60;
    if (attempt == 3) return 120;
    return 300;
  }

  bool _cooldownOk() {
    final last = _lastRequestAt;
    if (last == null) return true;
    return DateTime.now().difference(last).inSeconds >= _minRequestIntervalSec;
  }

  Future<void> _loadForWidth(double width) async {
    _lastWidth = width;

    if (!_isForeground) return;

    final unit = _unit.trim();
    if (unit.isEmpty) {
      _log('unitId is EMPTY ❌ (AdService.I.bannerUnitId)');
      return;
    }

    // 이미 로드된 광고가 있거나 로딩 중이면 중복 로드 방지
    if (_ad != null || _loading) return;

    // 너무 자주 요청하지 않도록 최소 간격 보장
    if (!_cooldownOk()) {
      // 쿨다운 남은 시간만큼 한 번만 예약
      final remain = _minRequestIntervalSec -
          DateTime.now().difference(_lastRequestAt!).inSeconds;
      final sec = remain.clamp(1, _minRequestIntervalSec);
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: sec), () {
        if (!mounted) return;
        _loadForWidth(_lastWidth);
      });
      return;
    }

    _retryTimer?.cancel();
    _loading = true;
    _lastRequestAt = DateTime.now();

    // ✅ 화면폭 기반 적응형 배너 사이즈
    final anchoredSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width.truncate(),
    );

    if (!mounted) {
      _loading = false;
      return;
    }

    if (anchoredSize == null) {
      _log('AnchoredAdaptiveBanner size is null → skip');
      _loading = false;
      return;
    }

    _size = anchoredSize;

    _log('load... release=$kReleaseMode unit=$unit size=$anchoredSize');

    final ad = BannerAd(
      adUnitId: unit,
      request: const AdRequest(),
      size: anchoredSize,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _log('LOADED ✅ size=${(ad as BannerAd).size}');
          _retryAttempt = 0;
          _loading = false;
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          _log('FAILED ❌ code=${error.code} domain=${error.domain} msg=${error.message}');
          ad.dispose();

          _ad = null;
          _loaded = false;
          _loading = false;

          // ✅ 실패하면 더 느리게 재시도
          _retryAttempt = (_retryAttempt + 1).clamp(1, 10);
          final delaySec = _nextDelaySec(_retryAttempt);

          // ✅ "Too many recently failed requests"면, 최소 간격을 더 여유 있게
          // (SDK가 '몇 초 기다려라'라고 할 때 즉시 두드리면 또 막힘)
          final extraCooldown = (error.code == 1) ? 15 : 0;
          final totalDelay = (delaySec + extraCooldown).clamp(30, 300);

          _retryTimer?.cancel();
          _retryTimer = Timer(Duration(seconds: totalDelay), () {
            if (!mounted) return;
            _loadForWidth(_lastWidth);
          });

          if (!mounted) return;
          setState(() {});
        },
      ),
    );

    _ad = ad;
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width > 0) {
          _lastWidth = width;
        }

        // width가 유효해진 이후에 1회 로드 시도
        if (_isForeground && width > 0 && _ad == null && !_loading) {
          Future.microtask(() => _loadForWidth(width));
        }

        final h = (_loaded && _size != null) ? _size!.height.toDouble() : 0.0;
        final w = (_size != null) ? _size!.width.toDouble() : width;

        return SafeArea(
          top: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: h,
            child: Center(
              child: (_loaded && _ad != null && _size != null)
                  ? SizedBox(width: w, height: h, child: AdWidget(ad: _ad!))
                  : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
