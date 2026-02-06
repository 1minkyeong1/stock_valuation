import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'pages/search_page.dart';
import 'data/repo_hub.dart';
import 'services/ad_service.dart';

// ✅ KR(KIS) Repo 추가
import 'data/kis_kr_stock_repository.dart';

// ✅ US(FMP) 그대로 유지
import 'data/us/fmp_client.dart';
import 'data/us/us_fmp_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initAds();

  // ✅ Worker URL만 있으면 됨 (KIS/FMP/OpenDART 키는 Worker에만 존재)
  final hub = _buildRepoHub(workerBaseUrl: _workerBaseUrl());

  runApp(StockValuationApp(hub: hub));
}

Future<void> _initAds() async {
  await MobileAds.instance.initialize();
  AdService.I.warmUp();
}

String _workerBaseUrl() {
  // 로컬 테스트 (wrangler dev)
  if (kDebugMode) return 'https://stock-proxy.k17mnk.workers.dev';
  // if (kDebugMode) return 'http://192.168.0.69:8787';
  // 실배포 Worker 도메인
   return 'https://stock-proxy.k17mnk.workers.dev';
}

RepoHub _buildRepoHub({required String workerBaseUrl}) {
  // ✅ KR repo:  KIS 전용 Repo
  final krRepo = KisKrStockRepository(
    workerBaseUrl: workerBaseUrl,
    debugLog: kDebugMode,
  );

  // ✅ US repo: 기존 FMP Repo 그대로 유지
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

class StockValuationApp extends StatelessWidget {
  final RepoHub hub;
  const StockValuationApp({super.key, required this.hub});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Valuation',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6BFF)),
        appBarTheme: const AppBarTheme(centerTitle: false),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9E2FF)),
          ),
        ),
      ),
      home: SearchPage(hub: hub),
    );
  }
}
