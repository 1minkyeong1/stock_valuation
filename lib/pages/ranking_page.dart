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

  String _krRankQuery = '';
  String _usRankQuery = '';

  int _krReqSeq = 0;
  int _usReqSeq = 0;

  // US표시용 이름 helper
  String _usDisplayName(UsRankItem it) {
    return SearchAlias.usPrimaryKoName(it.tickerFmp) ?? it.name;
  }

  String _usDisplaySubtitle(UsRankItem it) {
    final ko = SearchAlias.usPrimaryKoName(it.tickerFmp);
    if (ko == null) return it.tickerDisplay;
    return '${it.tickerDisplay} · ${it.name}';
  }

  Uri _krRankUri() {
    return Uri.parse('$kWorkerBaseUrl/rankings/kr').replace(
      queryParameters: {
        'loss': '0',
        'limit': '200',
        'market': _krBoard,
      },
    );
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

  Uri _krQuoteUri(String code6) =>
      Uri.parse('$kWorkerBaseUrl/kr/price?code=$code6');

  Uri _usRankUri() => Uri.parse(
        '$kWorkerBaseUrl/rankings/us?group=$_usGroup&loss=0&limit=200',
      );

  Uri _usQuoteUri(String tickerFmp) =>
      Uri.parse('$kWorkerBaseUrl/fmp/quote?symbol=$tickerFmp');

  @override
  void initState() {
    super.initState();
    AdService.I.warmUp();
    _tab = TabController(length: 2, vsync: this);

    _krRankSearchCtrl.text = _krRankQuery;
    _usRankSearchCtrl.text = _usRankQuery;

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
          _krNotReadyMsg = r.message ?? '랭킹 생성중입니다... 잠시만요!';
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
          _krNotReadyMsg = 'KR 랭킹 생성중입니다... 잠시 후 다시 시도해주세요.';
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
          _usError = r.message ?? '랭킹 생성중입니다... 잠시만요!';
          _usItems = [];
          _usFetchedAt = generatedAtLocal;
          _usLoading = false;
        });
        return;
      }

      if (!r.ok) {
        final generatedAtLocal = _parseServerTime(r.generatedAt);

        setState(() {
          _usError = 'US 랭킹 오류: ${r.error ?? "UNKNOWN"}';
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

  // 추가 helper

  List<KrRankItem> get _krVisibleItems {
    final q = _krRankQuery.trim().toLowerCase();
    if (q.isEmpty) return _krItems;

    return _krItems.where((it) {
      return it.name.toLowerCase().contains(q) ||
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

  int _krOriginalRank(KrRankItem item) {
    final idx = _krItems.indexWhere((x) => x.code == item.code);
    return idx >= 0 ? idx + 1 : 0;
  }

  int _usOriginalRank(UsRankItem item) {
    final idx = _usItems.indexWhere((x) => x.tickerFmp == item.tickerFmp);
    return idx >= 0 ? idx + 1 : 0;
  }

  //

  Color _diffColor(ColorScheme cs, double diff) {
    if (diff > 0) return Colors.red;
    if (diff < 0) return Colors.blue;
    return cs.onSurfaceVariant;
  }

  IconData? _diffIcon(double diff) {
    if (diff > 0) return Icons.arrow_drop_up;
    if (diff < 0) return Icons.arrow_drop_down;
    return null;
  }

  String _signed(String s, double v) => v > 0 ? '+$s' : s;

  Widget _trailingKr(KrRankItem it) {
    final cs = Theme.of(context).colorScheme;

    final q = _krQuotes[it.code];
    final price = q?.price ?? it.price?.toDouble();

    final change = q?.change ?? it.change?.toDouble();
    final changePct = q?.changePct ?? it.changePct?.toDouble();

    if (price == null) return const SizedBox.shrink();

    final hasDiff = (change != null) && (changePct != null);
    final diff = change ?? 0.0;
    final color = _diffColor(cs, diff);
    final icon = _diffIcon(diff);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          fmtWon(price),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        if (hasDiff)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: color),
              Text(
                '${_signed(fmtWon(diff), diff)} (${changePct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          Text(
            '전일대비 -',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _trailingUs(UsRankItem it) {
    final cs = Theme.of(context).colorScheme;

    final q = _usQuotes[it.tickerFmp];
    final price = q?.price ?? it.price?.toDouble();

    final change = q?.change ?? it.change?.toDouble();
    final changePct = q?.changePct ?? it.changePct?.toDouble();

    if (price == null) return const SizedBox.shrink();

    final hasDiff = (change != null) && (changePct != null);
    final diff = change ?? 0.0;
    final color = _diffColor(cs, diff);
    final icon = _diffIcon(diff);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        if (hasDiff)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: color),
              Text(
                '${diff > 0 ? '+' : ''}\$${diff.toStringAsFixed(2)} (${changePct.toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          Text(
            'chg -',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
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
                const SizedBox(width: 10),
                trailing,
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
                  ' ${_fmtUpdated(fetchedAt)} (기대수익률 기준)',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$count개',
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
            '현재가는 화면 진입 후 다시 반영될 수 있어요.',
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
        _metaRow(fetchedAt: _krFetchedAt, count: 0),
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
                    child: Text(_krNotReadyMsg ?? '랭킹 생성중입니다... 잠시만요!'),
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
            '요청 URL: ${_krRankUri()}',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBarBottom() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(96),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'KR'),
              Tab(text: 'US'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
        'KR 랭킹 생성중입니다... 잠시만 기다려주세요.',
        fetchedAt: _krFetchedAt,
      );
    }

    if (_krError != null) {
      return _buildPreparingView(
        'KR 랭킹 생성중입니다... 잠시 후 다시 시도해주세요.',
        fetchedAt: _krFetchedAt,
      );
    }

    if (!_krLoading && _krItems.isEmpty && !_krNotReady && _krError == null) {
      return _buildPreparingView(
        'KR 랭킹을 준비중입니다...',
        fetchedAt: _krFetchedAt,
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
          ),
          _buildEmptySearchResult('KR 랭킹 내 검색 결과가 없습니다.'),
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
          );
        }

        final it = visible[i - 1];
        final rank = _krOriginalRank(it);

        return _rankCardTile(
          rank: rank,
          title: it.name,
          subtitle: '${it.code} · ${it.market}',
          trailing: _trailingKr(it),
          onTap: () => _openResultKr(it),
          companyMark: _companyMark(
            title: it.name,
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
        'US 랭킹 생성중입니다... 잠시만 기다려주세요.',
        fetchedAt: _usFetchedAt,
      );
    }

    if (_usError != null) {
      return _buildPreparingView(
        'US 랭킹 생성중입니다... 잠시 후 다시 시도해주세요.',
        fetchedAt: _usFetchedAt,
      );
    }

    if (!_usLoading && _usItems.isEmpty && _usError == null) {
      return _buildPreparingView(
        'US 랭킹을 준비중입니다...',
        fetchedAt: _usFetchedAt,
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
          ),
          _buildEmptySearchResult('US 랭킹 내 검색 결과가 없습니다.'),
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
          );
        }

        final it = visible[i - 1];
        final rank = _usOriginalRank(it);

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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "저평가 기업",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
          ),
          bottom: _buildAppBarBottom(),
          actions: [
            IconButton(
              tooltip: '검색',
              icon: const Icon(Icons.search),
              onPressed: _openSearch,
            ),
            IconButton(
              tooltip: '새로고침',
              icon: const Icon(Icons.refresh),
              onPressed: _refreshCurrent,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildPinnedRankSearchBox(),
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
    final hint = isKr ? '종목명 · 코드 검색' : '기업명 · 티커 검색';

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
                          tooltip: '지우기',
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
  Widget _buildPreparingView(String message, {DateTime? fetchedAt}) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _metaRow(fetchedAt: fetchedAt, count: 0),
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