import 'dart:async';
import 'package:flutter/material.dart';

import 'package:stock_valuation_app/data/stores/favorites_store.dart';
import 'package:stock_valuation_app/data/stores/recent_store.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';
import 'package:stock_valuation_app/data/repository/stock_repository.dart';
import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/pages/result_page.dart';
import 'package:stock_valuation_app/services/ad_service.dart';
import 'package:stock_valuation_app/utils/search_alias.dart';
import 'package:stock_valuation_app/l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:stock_valuation_app/utils/number_format.dart';

class FavoriteRankingPage extends StatefulWidget {
  final RepoHub hub;
  final Market market;
  final double requiredReturnPct;

  const FavoriteRankingPage({
    super.key,
    required this.hub,
    required this.market,
    required this.requiredReturnPct,
  });

  @override
  State<FavoriteRankingPage> createState() => _FavoriteRankingPageState();
}

class _FavoriteRankingPageState extends State<FavoriteRankingPage> {
  final _favStore = FavoritesStore();
  final _recentStore = RecentStore();

  bool _loading = true;
  String? _error;
  List<FavoriteRankRow> _rows = [];

  AppLocalizations get t => AppLocalizations.of(context)!;
  bool get isKoLang => Localizations.localeOf(context).languageCode == 'ko';

  // 요구수익률
  late final TextEditingController _rCtrl;
  double _rPct = 10.0;
  List<_FavoriteSnapshotEntry> _snapshots = []; 

  // 컬러 헬퍼
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

  @override
  void initState() {
    super.initState();

    _rPct = widget.requiredReturnPct.clamp(5.0, 20.0).toDouble();
    _rCtrl = TextEditingController(text: _rPct.toStringAsFixed(1));

    _load();
  }

  @override
  void dispose() {
    _rCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final favs = await _favStore.load(widget.market);

      if (favs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _snapshots = [];
          _rows = [];
          _loading = false;
        });
        return;
      }
      // 삭제
      debugPrint('[FavoriteRanking] market=${widget.market} favs=${favs.map((e) => '${e.code}/${e.name}/${e.market}').toList()}');

      final entries = (await Future.wait(
        favs.map((item) async {
          final snap = await _fetchValuationSnapshot(item);
          if (snap == null) return null;
          return _FavoriteSnapshotEntry(item: item, snapshot: snap);
        }),
      ))
          .whereType<_FavoriteSnapshotEntry>()
          .toList();

      final rows = _buildRows(entries, requiredReturnPct: _rPct);

      if (!mounted) return;
      setState(() {
        _snapshots = entries;
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  // 즐겨찾기 랭킹페이지 내부 계산 로직
  List<FavoriteRankRow> _buildRows(
    List<_FavoriteSnapshotEntry> entries, {
    required double requiredReturnPct,
  }) {
    final rows = <FavoriteRankRow>[];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final snap = entry.snapshot;

      final fair = _fairPrice(
        eps: snap.eps,
        bps: snap.bps,
        rPct: requiredReturnPct,
      );

      final expected = _expectedReturnPct(
        price: snap.price,
        eps: snap.eps,
        bps: snap.bps,
        rPct: requiredReturnPct,
      );

      rows.add(
        FavoriteRankRow(
          item: entry.item,
          price: snap.price,
          eps: snap.eps,
          bps: snap.bps,
          dps: snap.dps,
          fairPrice: fair,
          expectedReturnPct: expected,
          isCalculable: expected != null,
          isLossMaking: snap.eps <= 0,
          originalOrder: i,
        ),
      );
    }

    rows.sort((a, b) {
      if (a.isCalculable != b.isCalculable) {
        return a.isCalculable ? -1 : 1;
      }

      if (a.isCalculable && b.isCalculable) {
        return b.expectedReturnPct!.compareTo(a.expectedReturnPct!);
      }

      return a.originalOrder.compareTo(b.originalOrder);
    });

    return rows;
  }

  void _setRequiredReturn(double next, {bool updateText = true}) {
    final clamped = next.clamp(5.0, 20.0).toDouble();
    final rows = _buildRows(_snapshots, requiredReturnPct: clamped);

    setState(() {
      _rPct = clamped;
      if (updateText) {
        _rCtrl.text = clamped.toStringAsFixed(1);
      }
      _rows = rows;
    });
  }

  void _applyRankingRPctFromText(String raw, {bool updateText = true}) {
    final cleaned = raw.trim().replaceAll(',', '');
    final v = double.tryParse(cleaned);

    if (v == null) {
      if (updateText) {
        _rCtrl.text = _rPct.toStringAsFixed(1);
      }
      return;
    }

    _setRequiredReturn(v, updateText: updateText);
  }

  Color get _accent => widget.market == Market.us ? Colors.blue : Colors.green;

  Widget _requiredReturnRankingCard({bool compact = false}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final titleStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      fontWeight: FontWeight.w800,
      color: cs.onSurface,
    );

    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 2.0)
        .toDouble();

    final inputWidth =
        ((compact ? 72.0 : 78.0) + (textScale - 1.0) * 36.0).clamp(72.0, 120.0);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface.withAlpha(238),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withAlpha(110)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 10 : 12,
            compact ? 7 : 8,
            compact ? 10 : 12,
            compact ? 4 : 5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isKoLang ? '요구수익률' : 'Required return',
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(
                    width: inputWidth,
                    child: TextField(
                      controller: _rCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
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
                        hintText: '10.0',
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
                            color: _accent.withAlpha(110),
                            width: 1.0,
                          ),
                        ),
                      ),
                      onSubmitted: (v) => _applyRankingRPctFromText(v),
                      onEditingComplete: () {
                        _applyRankingRPctFromText(_rCtrl.text);
                        FocusScope.of(context).unfocus();
                      },
                      onTapOutside: (_) {
                        _applyRankingRPctFromText(_rCtrl.text);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accent.withAlpha(185),
                  inactiveTrackColor: cs.outlineVariant.withAlpha(85),
                  thumbColor: _accent.withAlpha(205),
                  overlayColor: _accent.withAlpha(14),
                  trackHeight: compact ? 2.0 : 2.4,
                  thumbShape: RoundSliderThumbShape(
                    enabledThumbRadius: compact ? 6 : 7,
                  ),
                  overlayShape: RoundSliderOverlayShape(
                    overlayRadius: compact ? 10 : 12,
                  ),
                ),
                child: Slider(
                  value: _rPct,
                  min: 5,
                  max: 20,
                  divisions: 150,
                  label: "${_rPct.toStringAsFixed(1)}%",
                  onChanged: (v) {
                    _setRequiredReturn(v);
                  },
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
    );
  }

  // 프로젝트의 실제 데이터 로더
  Future<_ValuationSnapshot?> _fetchValuationSnapshot(
    StockSearchItem item,
  ) async {
    final code = item.code;

    double price = 0.0;
    StockFundamentals f = const StockFundamentals(
      eps: 0,
      bps: 0,
      dps: 0,
    );

    Future<void> loadPrice() async {
      try {
        final quote = await widget.hub
            .getPriceQuote(widget.market, code)
            .timeout(const Duration(seconds: 8));

        price = quote.price;
      } catch (e, st) {
        debugPrint('[FavoriteRanking] price fail: $code / $e');
        debugPrint('$st');
        price = 0.0;
      }
    }

    Future<void> loadFundamentals() async {
      try {
        f = await widget.hub
            .getFundamentals(widget.market, code, targetYear: null)
            .timeout(const Duration(seconds: 12));
      } catch (e, st) {
        debugPrint('[FavoriteRanking] fundamentals fail: $code / $e');
        debugPrint('$st');
        f = const StockFundamentals(
          eps: 0,
          bps: 0,
          dps: 0,
        );
      }
    }

    await Future.wait([
      loadPrice(),
      loadFundamentals(),
    ]);

    if (price <= 0) return null;
    if (f.bps <= 0) return null;
    //삭제
    if (item.code == '004910') {
      debugPrint(
        '[FavoriteRanking][004910] '
        'price=$price eps=${f.eps} bps=${f.bps} dps=${f.dps}',
      );
    }

    return _ValuationSnapshot(
      price: price,
      eps: f.eps,
      bps: f.bps,
      dps: f.dps,
    );
  }
  

  double? _fairPrice({
    required double? eps,
    required double? bps,
    required double rPct,
  }) {
    if (eps == null || bps == null) return null;
    if (bps <= 0 || rPct <= 0) return null;

    final roePct = (eps / bps) * 100;
    final roeOverR = roePct / rPct;
    final fair = bps * roeOverR;

    if (!fair.isFinite || fair <= 0) return null;
    return fair;
  }

  double? _expectedReturnPct({
    required double? price,
    required double? eps,
    required double? bps,
    required double rPct,
  }) {
    if (price == null || eps == null || bps == null) return null;
    if (price <= 0 || bps <= 0 || rPct <= 0) return null;

    final fair = _fairPrice(eps: eps, bps: bps, rPct: rPct);
    if (fair == null || fair == 0) return null;

    final v = ((fair - price) / price) * 100;
    if (!v.isFinite) return null;
    return v;
  }

  String _displayName(StockSearchItem s) {
    if (widget.market == Market.us) {
      if (isKoLang) {
        return SearchAlias.usPrimaryKoName(s.code) ?? s.name;
      }
      return s.name;
    }

    return SearchAlias.displayKrName(
      code: s.code,
      koName: s.name,
      locale: Localizations.localeOf(context),
    );
  }

  String? _displayOriginalName(StockSearchItem s) {
    if (widget.market == Market.us) {
      if (!isKoLang) return null;
      final ko = SearchAlias.usPrimaryKoName(s.code);
      final en = s.name.trim();
      if (ko == null || en.isEmpty || ko == en) return null;
      return en;
    }

    final en = SearchAlias.krEnglishName(s.code)?.trim();
    if (en == null || en.isEmpty || en == s.name.trim()) return null;
    return en;
  }

  Future<void> _openResult(StockSearchItem s) async {
    unawaited(_recentStore.add(widget.market, s));

    if (AdService.I.adsEnabled &&
        AdService.I.isInterstitialEligibleNow &&
        AdService.I.hasReadyInterstitial) {
      try {
        await AdService.I.maybeShowInterstitial();
      } catch (_) {}
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultPage(
          hub: widget.hub,
          item: s,
          market: widget.market,
          initialRequiredReturnPct: _rPct,
        ),
      ),
    );
  }

  Widget _companyMark(StockSearchItem s, {double size = 38}) {
    final isUs = widget.market == Market.us;
    final base = isUs ? Colors.indigo : Colors.teal;
    final logoUrl = s.logoUrl?.trim();

    Widget fallback() {
      final text = _displayName(s).trim().isEmpty ? '?' : _displayName(s).trim().characters.first;
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: base.withAlpha(20),
          shape: BoxShape.circle,
          border: Border.all(color: base.withAlpha(70)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: base.withAlpha(220),
          ),
        ),
      );
    }

    if (logoUrl == null || logoUrl.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback(),
        errorWidget: (_, __, ___) => fallback(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isKoLang ? '즐겨찾기 랭킹' : 'Favorite Ranking';
    final sub = isKoLang
        ? '요구수익률 ${_rPct.toStringAsFixed(1)}% 기준'
        : 'Based on required return ${_rPct.toStringAsFixed(1)}%';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _requiredReturnRankingCard(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isKoLang ? '불러오기 실패: $_error' : 'Load failed: $_error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else if (_rows.isEmpty)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isKoLang
                          ? '즐겨찾기 종목이 없거나 계산 가능한 데이터가 없습니다.'
                          : 'There are no favorite stocks or no calculable data.',
                    ),
                  ),
                )
              else
                ...List.generate(_rows.length, (i) {
                  final row = _rows[i];
                  final name = _displayName(row.item);
                  final original = _displayOriginalName(row.item);
                  final currentPriceText = widget.market == Market.us
                      ? fmtUsdDecimal(row.price, fractionDigits: 2)
                      : fmtWonDecimal(row.price, fractionDigits: 0);

                  final fairPriceText = row.fairPrice == null
                      ? '-'
                      : (widget.market == Market.us
                          ? fmtUsdDecimal(row.fairPrice!, fractionDigits: 2)
                          : fmtWonDecimal(row.fairPrice!, fractionDigits: 0));

                  final rankHeadline = row.isCalculable
                      ? '${row.expectedReturnPct! >= 0 ? '+' : ''}${row.expectedReturnPct!.toStringAsFixed(1)}%'
                      : (row.isLossMaking
                          ? (isKoLang ? '적자 · 계산 제외' : 'Loss · N/A')
                          : (isKoLang ? '계산 제외' : 'N/A'));

                  final rankColor = row.isCalculable
                      ? (row.expectedReturnPct! >= 0 ? Colors.red : Colors.blue)
                      : Colors.grey;        

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openResult(row.item),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _companyMark(row.item),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (original != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      original,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    row.item.code,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  rankHeadline,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: row.isCalculable ? 16 : 13,
                                    color: rankColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _priceTag(
                                  label: isKoLang ? '현재가' : 'Price',
                                  value: currentPriceText,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(height: 4),
                                _priceTag(
                                  label: isKoLang ? '적정가' : 'Fair',
                                  value: fairPriceText,
                                  color: row.isCalculable ? _accent : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoriteRankRow {
  final StockSearchItem item;
  final double price;
  final double eps;
  final double bps;
  final double dps;
  final double? expectedReturnPct;
  final double? fairPrice;
  final bool isCalculable;
  final bool isLossMaking;
  final int originalOrder;

  FavoriteRankRow({
    required this.item,
    required this.price,
    required this.eps,
    required this.bps,
    required this.dps,
    required this.expectedReturnPct,
    required this.fairPrice,
    required this.isCalculable,
    required this.isLossMaking,
    required this.originalOrder,
  });
}

class _ValuationSnapshot {
  final double price;
  final double eps;
  final double bps;
  final double dps;

  _ValuationSnapshot({
    required this.price,
    required this.eps,
    required this.bps,
    required this.dps,
  });
}

class _FavoriteSnapshotEntry {
  final StockSearchItem item;
  final _ValuationSnapshot snapshot;

  _FavoriteSnapshotEntry({
    required this.item,
    required this.snapshot,
  });
}