import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  String get _unit => AdService.I.bannerUnitId;

  void _log(String msg) {
    // 릴리스에서도 찍히게 하고 싶으면 debugPrint 그대로 OK
    debugPrint('[ADS][BANNER] $msg');
  }

  @override
  void initState() {
    super.initState();

    final unit = _unit.trim();
    if (unit.isEmpty) {
      _log('unitId is EMPTY ❌ (AdService.I.bannerUnitId)');
      return;
    }

    _log('load... release=$kReleaseMode unit=$unit');

    final ad = BannerAd(
      adUnitId: unit,
      request: const AdRequest(),
      size: AdSize.banner, // 320x50
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _log('LOADED ✅ size=${(ad as BannerAd).size}');
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          _log('FAILED ❌ code=${error.code} domain=${error.domain} msg=${error.message}');
          ad.dispose();
          _ad = null;
          if (!mounted) return;
          setState(() => _loaded = false);
        },
        onAdImpression: (ad) => _log('IMPRESSION 👀'),
        onAdOpened: (ad) => _log('OPENED'),
        onAdClosed: (ad) => _log('CLOSED'),
      ),
    );

    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adSize = AdSize.banner;        // runtime
    final h = adSize.height.toDouble();  // 50.0
    final w = adSize.width.toDouble();   // 320.0

    return SafeArea(
      top: false,
      child: SizedBox(
        height: h,
        child: Center(
          child: _loaded && _ad != null
              ? SizedBox(
                  width: w,
                  height: h,
                  child: AdWidget(ad: _ad!),
                )
              : SizedBox(width: w, height: h), // 자리 유지(디버깅/UX)
        ),
      ),
    );
  }
}