// lib/pages/ranking_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import '../data/stores/repo_hub.dart';
import '../models/market.dart';
import '../pages/result_page.dart';
import '../pages/search_page.dart';
import '../data/repository/stock_repository.dart';

import '../models/ranking_models.dart';
import '../utils/number_format.dart';
import '../data/repository/rank_api.dart';
import '../data/stores/recent_store.dart';
import '../utils/search_alias.dart';
import '../services/ad_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/services.dart';

const String kWorkerBaseUrl = String.fromEnvironment(
  'WORKER_BASE_URL',
  defaultValue: 'https://stock-proxy.k17mnk.workers.dev',
);

class RankingPage extends StatefulWidget {
  final RepoHub hub;
  const RankingPage({super.key, required this.hub});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with TickerProviderStateMixin {
  late final TabController _tab;
  final _recentStore = RecentStore();

  // 번역
  AppLocalizations get t => AppLocalizations.of(context)!;

  bool get _isKo => Localizations.localeOf(context).languageCode == 'ko';

  // KR
  bool _krLoading = true;
  String? _krError;
  bool _krNotReady = false;
  String? _krNotReadyMsg;

  List<KrRankItem> _krItems = [];
  DateTime? _krFetchedAt;
  final Map<String, QuoteLite> _krQuotes = {};

  String _krBoard = 'KOSPI'; // KOSPI | KOSDAQ

  // US
  bool _usLoading = false;
  String? _usError;
  List<UsRankItem> _usItems = [];
  DateTime? _usFetchedAt;
  final Map<String, QuoteLite> _usQuotes = {};

  String _usGroup = 'SP500'; // SP500 | NASDAQ100

  // 랭킹 검색
  final TextEditingController _krRankSearchCtrl = TextEditingController();
  final TextEditingController _usRankSearchCtrl = TextEditingController();

  late final TextEditingController _krRCtrl;
  late final TextEditingController _usRCtrl;

  static const double _krBaseRPct = 15.0;
  static const double _usBaseRPct = 10.0;

  double _krRPct = _krBaseRPct;
  double _usRPct = _usBaseRPct;

  String _krRankQuery = '';
  String _usRankQuery = '';

  int _krReqSeq = 0;
  int _usReqSeq = 0;

  // US표시용 이름 helper
  String _usDisplayName(UsRankItem it) {
    if (_isKo) {
      return SearchAlias.usPrimaryKoName(it.tickerFmp) ?? it.name;
    }
    return it.name;
  }

  String _usDisplaySubtitle(UsRankItem it) {
    if (_isKo) {
      final ko = SearchAlias.usPrimaryKoName(it.tickerFmp);
      if (ko == null) return it.tickerDisplay;
      return '${it.tickerDisplay} · ${it.name}';
    }
    return it.tickerDisplay;
  }

  // 한글 (영어매핑)
  String _displayRankingName({
    required String code,
    required String koName,
  }) {
    final locale = Localizations.localeOf(context);

    return SearchAlias.displayKrName(
      code: code,
      koName: koName,
      locale: locale,
    );
  }

  String? _displayRankingOriginalName({
    required String code,
    required String koName,
  }) {
    final en = SearchAlias.krEnglishName(code)?.trim();
    if (en == null || en.isEmpty || en == koName.trim()) return null;
    return en;
  }

  // 랭킹숫자 반응형 사이즈
  double _uiScale(BuildContext context, {double max = 1.35}) {
    final ts = MediaQuery.of(context).textScaler.scale(1.0);
    return ts.clamp(1.0, max).toDouble();
  }

  double _responsiveSize(
    BuildContext context, {
    required double base,
    required double max,
    double step = 10,
  }) {
    final ts = _uiScale(context);
    return (base + (ts - 1.0) * step).clamp(base, max).toDouble();
  }

  Uri _krRankUri() {
    return Uri.parse('$kWorkerBaseUrl/rankings/kr').replace(
      queryParameters: {
        'loss': '0',
        'limit': '200',
        'market': _krBoard,
        'rPct': _krBaseRPct.toStringAsFixed(1),
      },
    );
  }

  Uri _krQuoteUri(String code6) =>
      Uri.parse('$kWorkerBaseUrl/kr/price?code=$code6');

  Uri _usRankUri() {
    return Uri.parse('$kWorkerBaseUrl/rankings/us').replace(
      queryParameters: {
        'group': _usGroup,
        'loss': '0',
        'limit': '200',
        'rPct': _usBaseRPct.toStringAsFixed(1),
      },
    );
  }

  Uri _usQuoteUri(String tickerFmp) =>
      Uri.parse('$kWorkerBaseUrl/fmp/quote?symbol=$tickerFmp');

  @override
  void initState() {
    super.initState();
    AdService.I.warmUp();
    _tab = TabController(length: 2, vsync: this);

    _krRankSearchCtrl.text = _krRankQuery;
    _usRankSearchCtrl.text = _usRankQuery;

    _krRCtrl = TextEditingController(text: _krRPct.toStringAsFixed(1));
    _usRCtrl = TextEditingController(text: _usRPct.toStringAsFixed(1));

    _tab.addListener(() {
      if (_tab.indexIsChanging) return;

      setState(() {});

      if (_tab.index == 1 && _usItems.isEmpty && !_usLoading) {
        setState(() {
          _usLoading = true;
          _usError = null;
        });
        _loadUs();
      }
    });

    _loadKr();
  }

  @override
  void dispose() {
    _krRankSearchCtrl.dispose();
    _usRankSearchCtrl.dispose();
    _krRCtrl.dispose();
    _usRCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  // 랭킹빌드 시간
  DateTime? _parseServerTime(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      final dt = DateTime.parse(iso);
      // 서버 시간이 UTC 기준이라고 보고 한국시간(KST)으로 고정 변환
      final utc = dt.isUtc ? dt : dt.toUtc();
      return utc.add(const Duration(hours: 9));
    } catch (_) {
      return null;
    }
  }

  String _fmtUpdated(DateTime? dt) {
    if (dt == null) return '-';

    String two(int n) => n.toString().padLeft(2, '0');

    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)} KST';
  }

  String _rankingBasisText(bool isKr) {
    final r = isKr ? _krRPct : _usRPct;
    if (_isKo) {
      return '요구수익률 ${r.toStringAsFixed(1)}% 기준';
    }
    return 'Based on required return ${r.toStringAsFixed(1)}%';
  }

  String _rankingUpdatedText(DateTime? fetchedAt, bool isKr) {
    final updated = _fmtUpdated(fetchedAt);
    return '$updated (${_rankingBasisText(isKr)})';
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(hub: widget.hub)),
    );
  }

  Future<void> _openResultKr(KrRankItem it) async {
    final item = StockSearchItem(
      code: it.code,
      name: it.name,
      market: it.market,
      logoUrl: it.logoUrl,
    );

    unawaited(
      _recentStore.add(Market.kr, item).catchError((e, st) {
        debugPrint('[Ranking][KR] recent save failed: $e');
      }),
    );

    if (!mounted) return;

    AdService.I.onOpenResult();

    if (AdService.I.adsEnabled &&
        AdService.I.isInterstitialEligibleNow &&
        AdService.I.hasReadyInterstitial) {
      try {
        await AdService.I.maybeShowInterstitial();
      } catch (e, st) {
        debugPrint('[Ranking][KR] ad error: $e');
        debugPrint('$st');
      }
    }

    if (!mounted) return;

    final nav = Navigator.of(context);
    await nav.push(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          hub: widget.hub,
          item: item,
          market: Market.kr,
          useRankingSnapshot: true,
          rankingPrice: _krQuotes[it.code]?.price ?? it.price?.toDouble(),
          rankingEps: it.eps?.toDouble(),
          rankingBps: it.bps?.toDouble(),
          rankingDps: it.dps?.toDouble(),
          rankingRPct: _krRPct,
        ),
      ),
    );
  }

  Future<void> _openResultUs(UsRankItem it) async {
    final item = StockSearchItem(
      code: it.tickerFmp,
      name: it.name,
      market: 'US',
      logoUrl: it.logoUrl,
    );

    unawaited(
      _recentStore.add(Market.us, item).catchError((e, st) {
        debugPrint('[Ranking][US] recent save failed: $e');
      }),
    );

    if (!mounted) return;

    AdService.I.onOpenResult();

    if (AdService.I.adsEnabled &&
        AdService.I.isInterstitialEligibleNow &&
        AdService.I.hasReadyInterstitial) {
      try {
        await AdService.I.maybeShowInterstitial();
      } catch (e, st) {
        debugPrint('[Ranking][US] ad error: $e');
        debugPrint('$st');
      }
    }

    if (!mounted) return;

    final nav = Navigator.of(context);
    await nav.push(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          hub: widget.hub,
          item: item,
          market: Market.us,
          useRankingSnapshot: true,
          rankingPrice: _usQuotes[it.tickerFmp]?.price ?? it.price?.toDouble(),
          rankingEps: it.eps?.toDouble(),
          rankingBps: it.bps?.toDouble(),
          rankingDps: it.dps?.toDouble(),
          rankingRPct: _usRPct,
        ),
      ),
    );
  }

  Future<void> _loadKr() async {
    final reqSeq = ++_krReqSeq;

    setState(() {
      _krLoading = true;
      _krError = null;
      _krNotReady = false;
      _krNotReadyMsg = null;
    });

    try {
      debugPrint('KR request url = ${_krRankUri()}');

      final r = await fetchRankingWithRetry<KrRankItem>(
        url: _krRankUri(),
        itemParser: (j) => KrRankItem.fromJson(j),
        timeout: const Duration(seconds: 20),
        retryOnceAfterSecondsIfNotReady: 3,
      );

      if (!mounted || reqSeq != _krReqSeq) return;

      if (r.isNotReady) {
        final generatedAtLocal = _parseServerTime(r.generatedAt);

        setState(() {
          _krNotReady = true;
          _krNotReadyMsg = r.message ?? t.rankingStillGeneratingWait;
          _krItems = [];
          _krFetchedAt = generatedAtLocal;
          _krLoading = false;
        });
        return;
      }

      if (!r.ok) {
        final generatedAtLocal = _parseServerTime(r.generatedAt);

        setState(() {
          _krError = 'KR 랭킹 오류: ${r.error ?? "UNKNOWN"}';
          _krItems = [];
          _krFetchedAt = generatedAtLocal;
          _krLoading = false;
        });
        return;
      }

      final parsed = r.items.where((x) => x.code.length == 6).toList();
      final generatedAtLocal = _parseServerTime(r.generatedAt);
      debugPrint('KR board=$_krBoard count=${parsed.length}');

      setState(() {
        _krItems = parsed;
        _krFetchedAt = generatedAtLocal;
        _krLoading = false;
      });

      _prefetchKrQuotes(maxN: parsed.length);
    } catch (e, st) {
      debugPrint('[Ranking][KR] load failed: $e');
      debugPrint('$st');

      if (!mounted || reqSeq != _krReqSeq) return;
      setState(() {
        _krLoading = false;

        // 기존 데이터가 없을 때만 안내 문구
        if (_krItems.isEmpty) {
          _krNotReady = true;
          _krNotReadyMsg = t.krRankingGeneratingRetry;
        }
      });
    }
  }

  Future<void> _loadUs() async {
    final reqSeq = ++_usReqSeq;

    setState(() {
      _usLoading = true;
      _usError = null;
    });

    try {
      final r = await fetchRankingWithRetry<UsRankItem>(
        url: _usRankUri(),
        itemParser: (j) => UsRankItem.fromJson(j),
        timeout: const Duration(seconds: 25),
        retryOnceAfterSecondsIfNotReady: 3,
      );

      if (!mounted || reqSeq != _usReqSeq) return;

      if (r.isNotReady) {
        final generatedAtLocal = _parseServerTime(r.generatedAt);

        setState(() {
          _usError = t.usRankingError(r.error ?? 'UNKNOWN');
          _usItems = [];
          _usFetchedAt = generatedAtLocal;
          _usLoading = false;
        });
        return;
      }

      if (!r.ok) {
        final generatedAtLocal = _parseServerTime(r.generatedAt);

        setState(() {
          _usError = t.usRankingError(r.error ?? 'UNKNOWN');
          _usItems = [];
          _usFetchedAt = generatedAtLocal;
          _usLoading = false;
        });
        return;
      }

      final parsed = r.items.where((x) => x.tickerFmp.isNotEmpty).toList();
      final generatedAtLocal = _parseServerTime(r.generatedAt);

      setState(() {
        _usItems = parsed;
        _usFetchedAt = generatedAtLocal;
        _usLoading = false;
      });

      _prefetchUsQuotes(maxN: parsed.length);
    } catch (e, st) {
      debugPrint('[Ranking][US] load failed: $e');
      debugPrint('$st');

      if (!mounted || reqSeq != _usReqSeq) return;
      setState(() {
        _usLoading = false;

        if (_usItems.isEmpty) {
          _usError = null;
        }
      });
    }
  }

  Future<void> _prefetchKrQuotes({int maxN = 12}) async {
    final n = (_krItems.length < maxN) ? _krItems.length : maxN;
    if (n <= 0) return;

    const batchSize = 6;

    for (int start = 0; start < n; start += batchSize) {
      final end = (start + batchSize < n) ? start + batchSize : n;
      final batch = _krItems.sublist(start, end);

      final futures = batch.map((it) async {
        final code = it.code;
        if (_krQuotes.containsKey(code)) return MapEntry<String, QuoteLite?>(code, null);

        try {
          final res = await http
              .get(_krQuoteUri(code), headers: {'accept': 'application/json'})
              .timeout(const Duration(seconds: 10));

          if (res.statusCode < 200 || res.statusCode >= 300) {
            return MapEntry<String, QuoteLite?>(code, null);
          }

          final obj = jsonDecode(res.body);
          if (obj is Map && obj['ok'] == true) {
            final q = QuoteLite.fromKrPrice(obj.cast<String, dynamic>());
            return MapEntry<String, QuoteLite?>(code, q);
          }
        } catch (_) {}

        return MapEntry<String, QuoteLite?>(code, null);
      }).toList();

      final results = await Future.wait(futures);

      if (!mounted) return;

      bool changed = false;
      for (final entry in results) {
        if (entry.value != null) {
          _krQuotes[entry.key] = entry.value!;
          changed = true;
        }
      }

      if (changed && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _prefetchUsQuotes({int maxN = 12}) async {
    final n = (_usItems.length < maxN) ? _usItems.length : maxN;
    if (n <= 0) return;

    const batchSize = 6;

    for (int start = 0; start < n; start += batchSize) {
      final end = (start + batchSize < n) ? start + batchSize : n;
      final batch = _usItems.sublist(start, end);

      final futures = batch.map((it) async {
        final tf = it.tickerFmp;
        if (_usQuotes.containsKey(tf)) return MapEntry<String, QuoteLite?>(tf, null);

        try {
          final res = await http
              .get(_usQuoteUri(tf), headers: {'accept': 'application/json'})
              .timeout(const Duration(seconds: 12));

          if (res.statusCode < 200 || res.statusCode >= 300) {
            return MapEntry<String, QuoteLite?>(tf, null);
          }

          final obj = jsonDecode(res.body);
          final q = QuoteLite.fromFmpQuoteArray(obj);
          return MapEntry<String, QuoteLite?>(tf, q);
        } catch (_) {}

        return MapEntry<String, QuoteLite?>(tf, null);
      }).toList();

      final results = await Future.wait(futures);

      if (!mounted) return;

      bool changed = false;
      for (final entry in results) {
        if (entry.value != null) {
          _usQuotes[entry.key] = entry.value!;
          changed = true;
        }
      }

      if (changed && mounted) {
        setState(() {});
      }
    }
  }

  // 계산 헬퍼
  void _setRankingRPct(
    double value, {
    required bool isKr,
    bool updateText = true,
  }) {
    final next = value.clamp(5.0, 20.0).toDouble();

    setState(() {
      if (isKr) {
        _krRPct = next;
        if (updateText) {
          _krRCtrl.text = next.toStringAsFixed(1);
        }
      } else {
        _usRPct = next;
        if (updateText) {
          _usRCtrl.text = next.toStringAsFixed(1);
        }
      }
    });
  }

  void _applyRankingRPctFromText(
    String raw, {
    required bool isKr,
    bool updateText = true,
  }) {
    final cleaned = raw.trim().replaceAll(',', '');
    final v = double.tryParse(cleaned);

    if (v == null) {
      if (updateText) {
        if (isKr) {
          _krRCtrl.text = _krRPct.toStringAsFixed(1);
        } else {
          _usRCtrl.text = _usRPct.toStringAsFixed(1);
        }
      }
      return;
    }

    _setRankingRPct(v, isKr: isKr, updateText: updateText);
  }

  // 적정가로부터 기대수익률 재계산
  double? _expectedFromFairPrice({
    required double? price,
    required double? fairPrice,
  }) {
    if (price == null || fairPrice == null) return null;
    if (price <= 0 || fairPrice <= 0) return null;

    final v = ((fairPrice - price) / price) * 100;
    if (!v.isFinite) return null;
    return v;
  }

  double? _scaledFairPrice({
    required double? baseFairPrice,
    required double baseRPct,
    required double currentRPct,
  }) {
    if (baseFairPrice == null) return null;
    if (baseFairPrice <= 0 || baseRPct <= 0 || currentRPct <= 0) return null;

    final v = baseFairPrice * (baseRPct / currentRPct);
    if (!v.isFinite || v <= 0) return null;
    return v;
  }

  double? _krLivePrice(KrRankItem it) =>
      _krQuotes[it.code]?.price ?? it.price?.toDouble();

  double? _usLivePrice(UsRankItem it) =>
      _usQuotes[it.tickerFmp]?.price ?? it.price?.toDouble();


  // 추가 helper

  List<KrRankItem> get _krVisibleItems {
    final q = _krRankQuery.trim().toLowerCase();
    if (q.isEmpty) return _krItems;

    return _krItems.where((it) {
      final displayName = _displayRankingName(
        code: it.code,
        koName: it.name,
      ).toLowerCase();

      final originalName = (_displayRankingOriginalName(
            code: it.code,
            koName: it.name,
          ) ??
          '')
          .toLowerCase();

      return displayName.contains(q) ||
          originalName.contains(q) ||
          it.name.toLowerCase().contains(q) ||
          it.code.toLowerCase().contains(q) ||
          it.market.toLowerCase().contains(q);
    }).toList();
  }

  List<UsRankItem> get _usVisibleItems {
    final q = _usRankQuery.trim().toLowerCase();
    if (q.isEmpty) return _usItems;

    return _usItems.where((it) {
      final koName = SearchAlias.usPrimaryKoName(it.tickerFmp) ?? '';

      return it.name.toLowerCase().contains(q) ||
          it.tickerDisplay.toLowerCase().contains(q) ||
          it.tickerFmp.toLowerCase().contains(q) ||
          koName.toLowerCase().contains(q);
    }).toList();
  }  

  Widget _trailingKr(KrRankItem it) {
    final price = _krLivePrice(it);
    final fairPrice = _scaledFairPrice(
      baseFairPrice: it.fairPrice?.toDouble(),
      baseRPct: _krBaseRPct,
      currentRPct: _krRPct,
    );
    final expected = _expectedFromFairPrice(
      price: price,
      fairPrice: fairPrice,
    );

    final expectedColor = expected == null
        ? Colors.grey
        : (expected >= 0 ? Colors.red : Colors.blue);

    final expectedText = expected == null
        ? '-'
        : '${expected >= 0 ? '+' : ''}${expected.toStringAsFixed(1)}%';

    final priceText = price == null
        ? '-'
        : fmtWonDecimal(price, fractionDigits: 0);

    final fairText = fairPrice == null
        ? '-'
        : fmtWonDecimal(fairPrice, fractionDigits: 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            expectedText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: expectedColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _priceTag(
          label: _isKo ? '현재가' : 'Price',
          value: priceText,
          color: Colors.blueGrey,
        ),
        const SizedBox(height: 4),
        _priceTag(
          label: _isKo ? '적정가' : 'Fair',
          value: fairText,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _trailingUs(UsRankItem it) {
    final price = _usLivePrice(it);
    final fairPrice = _scaledFairPrice(
      baseFairPrice: it.fairPrice?.toDouble(),
      baseRPct: _usBaseRPct,
      currentRPct: _usRPct,
    );
    final expected = _expectedFromFairPrice(
      price: price,
      fairPrice: fairPrice,
    );

    final expectedColor = expected == null
        ? Colors.grey
        : (expected >= 0 ? Colors.red : Colors.blue);

    final expectedText = expected == null
        ? '-'
        : '${expected >= 0 ? '+' : ''}${expected.toStringAsFixed(1)}%';

    final priceText = price == null
        ? '-'
        : fmtUsdDecimal(price, fractionDigits: 2);

    final fairText = fairPrice == null
        ? '-'
        : fmtUsdDecimal(fairPrice, fractionDigits: 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            expectedText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: expectedColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _priceTag(
          label: _isKo ? '현재가' : 'Price',
          value: priceText,
          color: Colors.blueGrey,
        ),
        const SizedBox(height: 4),
        _priceTag(
          label: _isKo ? '적정가' : 'Fair',
          value: fairText,
          color: Colors.blue,
        ),
      ],
    );
  }

  Color _op(Color c, double opacity) => c.withAlpha((opacity * 255).round());

  Widget _segCard({
    required List<String> labels,
    required int selectedIndex,
    required void Function(int idx) onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;

    Widget segItem(int i) {
      final selected = i == selectedIndex;

      return Expanded(
        child: InkWell(
          onTap: () => onTap(i),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: selected ? _op(cs.primary, 0.10) : cs.surface,
            child: Text(
              labels[i],
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final row = <Widget>[];
    for (int i = 0; i < labels.length; i++) {
      row.add(segItem(i));
      if (i != labels.length - 1) {
        row.add(Container(width: 1, height: 26, color: _op(divider, 0.8)));
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: cs.surface,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _op(divider, 0.9)),
          ),
          child: Row(children: row),
        ),
      ),
    );
  }

  Widget _segKrBoardCard() {
    final selectedIndex = (_krBoard == 'KOSPI') ? 0 : 1;

    return _segCard(
      labels: const ['KOSPI', 'KOSDAQ'],
      selectedIndex: selectedIndex,
      onTap: (idx) async {
        final next = (idx == 0) ? 'KOSPI' : 'KOSDAQ';
        if (next == _krBoard) return;

        setState(() {
          _krBoard = next;
          _krItems = [];
          _krQuotes.clear();
          _krFetchedAt = null;
          _krLoading = true;
          _krError = null;
          _krNotReady = false;
          _krNotReadyMsg = null;
        });

        await _loadKr();
      },
    );
  }

  Widget _segUsGroupCard() {
    final selectedIndex = (_usGroup == 'SP500') ? 0 : 1;

    return _segCard(
      labels: const ['S&P 500', 'NASDAQ 100'],
      selectedIndex: selectedIndex,
      onTap: (idx) async {
        final next = (idx == 0) ? 'SP500' : 'NASDAQ100';
        if (next == _usGroup) return;

        setState(() {
          _usGroup = next;
          _usItems = [];
          _usQuotes.clear();
          _usFetchedAt = null;
          _usLoading = true;
          _usError = null;
        });

        await _loadUs();
      },
    );
  }

  Future<void> _refreshCurrent() async {
    if (_tab.index == 0) {
      await _loadKr();
    } else {
      await _loadUs();
    }
  }

  Widget _rankCardTile({
    required int rank,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
    Widget? companyMark,
  }) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    final badgeSize = _responsiveSize(context, base: 38, max: 48, step: 12);
    final badgeRadius = _responsiveSize(context, base: 14, max: 18, step: 4);


    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: divider.withAlpha((0.7 * 255).round()),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(badgeRadius),
                    color: cs.primary.withAlpha((0.10 * 255).round()),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$rank',
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (companyMark != null) ...[
                  companyMark,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 160,
                  child: trailing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaRow({
    required DateTime? fetchedAt,
    required int count,
    required bool isKr,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _rankingUpdatedText(fetchedAt, isKr),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                t.rankingItemCount(count),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            t.rankingPriceMayUpdate,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _krNotReadyView() {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _metaRow(fetchedAt: _krFetchedAt, count: 0, isKr: true),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(_krNotReadyMsg ?? t.rankingStillGeneratingWait),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '${t.requestUrlLabel}: ${_krRankUri()}',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBarBottom() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tab,
            tabs: [
              Tab(text: t.tabKr),
              Tab(text: t.tabUs),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: AnimatedBuilder(
              animation: _tab,
              builder: (context, _) {
                final isKr = _tab.index == 0;
                return isKr ? _segKrBoardCard() : _segUsGroupCard();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKrBody() {
    final visible = _krVisibleItems;

    if (_krLoading) {
      return _buildPreparingView(
        t.krRankingGeneratingWait,
        fetchedAt: _krFetchedAt,
        isKr: true,
      );
    }

    if (_krError != null) {
      return _buildPreparingView(
        t.krRankingGeneratingRetry,
        fetchedAt: _krFetchedAt,
        isKr: true,
      );
    }

    if (!_krLoading && _krItems.isEmpty && !_krNotReady && _krError == null) {
      return _buildPreparingView(
        t.krRankingPreparing,
        fetchedAt: _krFetchedAt,
        isKr: true,
      );
    }

    if (_krNotReady) {
      return _krNotReadyView();
    }

    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _metaRow(
            fetchedAt: _krFetchedAt,
            count: 0,
            isKr: true,
          ),
          _buildEmptySearchResult(t.krRankingSearchEmpty),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: visible.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _metaRow(
            fetchedAt: _krFetchedAt,
            count: visible.length,
            isKr: true,
          );
        }

        final it = visible[i - 1];
        final rank = i;

        final displayName = _displayRankingName(
          code: it.code,
          koName: it.name,
        );

        final originalName = _displayRankingOriginalName(
          code: it.code,
          koName: it.name,
        );

        final subtitle = originalName != null && originalName.isNotEmpty
            ? '$originalName · ${it.code} · ${it.market}'
            : '${it.code} · ${it.market}';

        return _rankCardTile(
          rank: rank,
          title: displayName,
          subtitle: subtitle,
          trailing: _trailingKr(it),
          onTap: () => _openResultKr(it),
          companyMark: _companyMark(
            title: displayName,
            logoUrl: it.logoUrl,
            isUs: false,
          ),
        );
      },
    );
  }

  Widget _buildUsBody() {
    final visible = _usVisibleItems;

    if (_usLoading) {
      return _buildPreparingView(
        t.usRankingGeneratingWait,
        fetchedAt: _usFetchedAt,
        isKr: false,
      );
    }

    if (_usError != null) {
      return _buildPreparingView(
        t.usRankingGeneratingRetry,
        fetchedAt: _usFetchedAt,
        isKr: false,
      );
    }

    if (!_usLoading && _usItems.isEmpty && _usError == null) {
      return _buildPreparingView(
        t.usRankingPreparing,
        fetchedAt: _usFetchedAt,
        isKr: false,
      );
    }

    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _metaRow(
            fetchedAt: _usFetchedAt,
            count: 0,
            isKr: false,
          ),
          _buildEmptySearchResult(t.usRankingSearchEmpty),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: visible.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _metaRow(
            fetchedAt: _usFetchedAt,
            count: visible.length,
            isKr: false,
          );
        }

        final it = visible[i - 1];
        final rank = i;

        return _rankCardTile(
          rank: rank,
          title: _usDisplayName(it),
          subtitle: _usDisplaySubtitle(it),
          trailing: _trailingUs(it),
          onTap: () => _openResultUs(it),
          companyMark: _companyMark(
            title: _usDisplayName(it),
            logoUrl: it.logoUrl,
            isUs: true,
          ),
        );
      },
    );
  }

  // 로고 이미지 위젯
  Widget _companyMark({
    required String title,
    required String? logoUrl,
    required bool isUs,
    double size = 36,
  }) {
    final base = isUs ? Colors.indigo : Colors.teal;
    final text = title.trim().isEmpty ? '?' : title.trim().characters.first;

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: base.withAlpha(20),
          borderRadius: BorderRadius.circular(size / 2),
          border: Border.all(color: base.withAlpha(70)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textScaler: const TextScaler.linear(1.0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: base.withAlpha(230),
              fontWeight: FontWeight.w900,
              fontSize: size * 0.32,
            ),
          ),
        ),
      );
    }

    final url = logoUrl?.trim();
    if (url == null || url.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => fallback(),
        errorWidget: (context, _, _) => fallback(),
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        titleSpacing: 18,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            t.rankingPageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
        ),
        bottom: _buildAppBarBottom(),
        actions: [
          IconButton(
            tooltip: t.search,
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
          IconButton(
            tooltip: t.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrent,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            _buildPinnedRankSearchBox(),
            _requiredReturnRankingCard(),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  RefreshIndicator(
                    onRefresh: _loadKr,
                    child: _buildKrBody(),
                  ),
                  RefreshIndicator(
                    onRefresh: _loadUs,
                    child: _buildUsBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 고정 검색창
  Widget _buildPinnedRankSearchBox() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isKr = _tab.index == 0;

    final ctrl = isKr ? _krRankSearchCtrl : _usRankSearchCtrl;
    final hint = isKr ? t.krRankSearchHint : t.usRankSearchHint;

    final ts = _uiScale(context);
    final fieldMinHeight = (40 + (ts - 1.0) * 14).clamp(40.0, 54.0);
    final fontSize = (13.5 + (ts - 1.0) * 1.5).clamp(13.5, 15.5);
    final hintFontSize = (12.5 + (ts - 1.0) * 1.2).clamp(12.5, 14.0);

    return Material(
      color: theme.appBarTheme.backgroundColor ?? cs.surface,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? cs.surface,
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: ctrl,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;

            return Container(
              constraints: BoxConstraints(minHeight: fieldMinHeight),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: TextField(
                controller: ctrl,
                textAlignVertical: TextAlignVertical.center,
                maxLines: 1,
                minLines: 1,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (v) {
                  setState(() {
                    if (isKr) {
                      _krRankQuery = v.trim();
                    } else {
                      _usRankQuery = v.trim();
                    }
                  });
                },
                decoration: InputDecoration(
                  isDense: false,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: hintFontSize,
                    color: cs.onSurfaceVariant,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: (9 + (ts - 1.0) * 3).clamp(9.0, 13.0),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: (18 + (ts - 1.0) * 2).clamp(18.0, 20.0),
                    color: cs.onSurfaceVariant,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 34,
                    minHeight: fieldMinHeight,
                  ),
                  suffixIcon: hasText
                      ? IconButton(
                          tooltip: t.clear,
                          splashRadius: 16,
                          onPressed: () {
                            ctrl.clear();
                            setState(() {
                              if (isKr) {
                                _krRankQuery = '';
                              } else {
                                _usRankQuery = '';
                              }
                            });
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 17,
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : null,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 34,
                    minHeight: fieldMinHeight,
                  ),
                ),
              ),
            );
                      },
        ),
      ),
    );
  }

  Widget _requiredReturnRankingCard() {
    final isKr = _tab.index == 0;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ctrl = isKr ? _krRCtrl : _usRCtrl;
    final r = isKr ? _krRPct : _usRPct;
    final accent = isKr ? Colors.green : Colors.blue;

    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 2.0)
        .toDouble();

    final inputWidth = (78.0 + (textScale - 1.0) * 36.0).clamp(78.0, 120.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withAlpha(238),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant.withAlpha(110)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isKo ? '요구수익률' : 'Required return',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: inputWidth,
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,1}$'),
                          ),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          suffixText: '%',
                          hintText: isKr ? '15.0' : '10.0',
                          filled: true,
                          fillColor: Colors.white.withAlpha(190),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: cs.outlineVariant.withAlpha(120),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: accent.withAlpha(110),
                              width: 1.0,
                            ),
                          ),
                        ),
                        onSubmitted: (v) {
                          _applyRankingRPctFromText(v, isKr: isKr);
                        },
                        onEditingComplete: () {
                          _applyRankingRPctFromText(ctrl.text, isKr: isKr);
                          FocusScope.of(context).unfocus();
                        },
                        onTapOutside: (_) {
                          _applyRankingRPctFromText(ctrl.text, isKr: isKr);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _isKo
                      ? '이 값에 따라 기대수익률과 적정주가가 다시 계산됩니다.'
                      : 'Expected return and fair price are recalculated with this value.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent.withAlpha(185),
                    inactiveTrackColor: cs.outlineVariant.withAlpha(85),
                    thumbColor: accent.withAlpha(205),
                    overlayColor: accent.withAlpha(14),
                    trackHeight: 2.4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: r,
                    min: 5,
                    max: 20,
                    divisions: 150,
                    label: "${r.toStringAsFixed(1)}%",
                    onChanged: (v) => _setRankingRPct(v, isKr: isKr),
                    onChangeEnd: (v) => _setRankingRPct(v, isKr: isKr),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 2, right: 2, top: 0),
                  child: Row(
                    children: [
                      Text(
                        "5%",
                        style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        "20%",
                        style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 오른쪽 금액 위젯
  Widget _priceTag({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$label ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: color.withAlpha(220),
                ),
              ),
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 랭킹 내 검색결과없음 카드
  Widget _buildEmptySearchResult(String message) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search_off, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 랭킹불러올 때 빈 공간 “랭킹 준비중” 문구로 덮기 위젯
  Widget _buildPreparingView(String message, {DateTime? fetchedAt, required bool isKr,}) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _metaRow(fetchedAt: fetchedAt, count: 0, isKr: isKr),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}