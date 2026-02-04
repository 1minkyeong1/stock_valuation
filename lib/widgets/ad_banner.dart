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

  @override
  void initState() {
    super.initState();

    final ad = BannerAd(
      adUnitId: AdService.I.bannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner, // ✅ 320x50 (표준)
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
          if (!mounted) return;
          setState(() => _loaded = false);
        },
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
    // ✅ 로드 전/실패 시에도 "하단 배너 자리"만 (원하면 0으로도 가능)
    final height = AdSize.banner.height.toDouble(); // 50

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: Center(
          child: _loaded && _ad != null
              ? AdWidget(ad: _ad!)
              : const SizedBox.shrink(), // 자리만 잡고 비워둠
        ),
      ),
    );
  }
}
