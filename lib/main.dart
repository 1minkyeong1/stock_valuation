import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
// import 'pages/ranking_page.dart';
import 'pages/search_page.dart';
import 'data/stores/repo_hub.dart';
import 'services/ad_service.dart';
import 'pages/update_check_gate.dart';

// KR(KIS) Repo
import 'data/repository/kis_kr_stock_repository.dart';

// US(FMP)
import 'data/api/fmp_client.dart';
import 'data/repository/us_fmp_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 모바일(Android/iOS)만 광고 사용
  AdService.I.adsEnabled = _isMobileAdPlatform;

  await _initAds();

  // Worker URL만 있으면 됨 (KIS/FMP/OpenDART 키는 Worker에만 존재)
  final hub = _buildRepoHub(workerBaseUrl: _workerBaseUrl());

  runApp(StockValuationApp(hub: hub));
}

Future<void> _initAds() async {
  if (!AdService.I.adsEnabled) return;

  await MobileAds.instance.initialize();
  AdService.I.warmUp();
}

String _workerBaseUrl() {
  if (kDebugMode) return 'https://stock-proxy.k17mnk.workers.dev';
  return 'https://stock-proxy.k17mnk.workers.dev';
}

RepoHub _buildRepoHub({required String workerBaseUrl}) {
  final krRepo = KisKrStockRepository(
    workerBaseUrl: workerBaseUrl,
    debugLog: kDebugMode,
  );

  final usClient = FmpClient(
    workerBaseUrl: workerBaseUrl,
    debugLog: kDebugMode,
  );
  final usRepo = UsFmpRepository(usClient);

  return RepoHub(
    kr: krRepo,
    us: usRepo,
  );
}

bool get _isMobileAdPlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

class StockValuationApp extends StatelessWidget {
  final RepoHub hub;
  const StockValuationApp({super.key, required this.hub});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 앱 제목도 번역
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      // 다국어 연결
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E2FF)),
          ),
        ),
      ),
      home: UpdateCheckGate(
         //child: RankingPage(hub: hub),
         child: SearchPage(hub: hub),
      ),
    );
  }
}