import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:stock_valuation_app/data/repository/stock_repository.dart';
import 'package:stock_valuation_app/data/stores/favorites_store.dart';
import 'package:stock_valuation_app/data/stores/recent_store.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';

import 'package:stock_valuation_app/pages/result_page.dart';
import 'package:stock_valuation_app/services/ad_service.dart';
import 'package:stock_valuation_app/widgets/ad_banner.dart';
import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/utils/search_alias.dart';
import 'package:stock_valuation_app/pages/ranking_page.dart';
import 'about_page.dart';

import 'package:stock_valuation_app/services/app_backup_service.dart';
import 'package:stock_valuation_app/services/app_backup_file_service.dart';
import 'package:stock_valuation_app/l10n/app_localizations.dart';
import 'package:stock_valuation_app/copy/result_copy.dart';
import 'package:stock_valuation_app/pages/favorite_ranking_page.dart';


class SearchPage extends StatefulWidget {
 final RepoHub hub;
  final double? initialRequiredReturnPct;

  const SearchPage({
    super.key,
    required this.hub,
    this.initialRequiredReturnPct,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final _controller = TextEditingController();
  final _searchFocus = FocusNode(); //  포커스 유지용
  Market _tab = Market.kr;
  Timer? _debounce;

  bool _loading = false;
  String? _error;
  List<StockSearchItem> _results = [];
  int _searchSeq = 0;  // 검색 요청 순서를 관리하는 키

  final _favStore = FavoritesStore();
  List<StockSearchItem> _favorites = [];

  final _recentStore = RecentStore();
  List<StockSearchItem> _recents = [];

  final _backupService = AppBackupService();
  final _backupFileService = AppBackupFileService();

  double _searchRPct = 10.0;
  late final TextEditingController _rCtrl;

  // 번역
  AppLocalizations get t => AppLocalizations.of(context)!;
  bool get isKoLang => Localizations.localeOf(context).languageCode == 'ko';

  String _backupErrorText(Object e) {
    if (e is AppBackupException) {
      switch (e.code) {
        case AppBackupErrorCode.invalidFormat:
          return t.backupErrorInvalidFormat;
        case AppBackupErrorCode.wrongApp:
          return t.backupErrorWrongApp;
        case AppBackupErrorCode.unsupportedVersion:
          return t.backupErrorUnsupportedVersion;
      }
    }

    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }

 @override
  void initState() {
    super.initState();

    final initR = (widget.initialRequiredReturnPct ?? 10.0).clamp(5.0, 20.0);
    _searchRPct = initR.toDouble();
    _rCtrl = TextEditingController(text: _searchRPct.toStringAsFixed(1));

    // 첫 프레임 이후 로드(안전)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadFav();
      await _loadRecents();
    });

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _rCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // 데이터 로드 메서드들
  Future<void> _loadFav() async {
    final f = await _favStore.load(_tab);
    if (!mounted) return;
    setState(() => _favorites = f);
  }

  Future<void> _loadRecents() async {
    final r = await _recentStore.load(_tab);
    if (!mounted) return;
    setState(() => _recents = r);
  }

  bool _isComposing() {
    final c = _controller.value.composing;
    return c.isValid && !c.isCollapsed;
  }

  // 높이계산함수(잘림현상 사이즈조절)
  double _miniStripHeight(BuildContext context) {
    // 1.0(기본) ~ 2.0(최대 근처) 범위로 제한
    final double ts = (MediaQuery.maybeTextScalerOf(context)?.scale(1.0) ?? 1.0)
    .clamp(1.0, 2.0)
    .toDouble();

    // 기본 120에서, 글자 커질수록 최대 200까지 늘림
    final h = 120.0 + (ts - 1.0) * 80.0; // ts=2.0이면 200
    return h.clamp(120.0, 200.0);
  }

  // 요구수익률
  void _applySearchRPctFromText(String raw, {bool updateText = true}) {
    final cleaned = raw.trim().replaceAll(',', '');
    final v = double.tryParse(cleaned);

    if (v == null) {
      if (updateText) {
        _rCtrl.text = _searchRPct.toStringAsFixed(1);
      }
      return;
    }

    final next = v.clamp(5.0, 20.0).toDouble();

    setState(() {
      _searchRPct = next;
      if (updateText) {
        _rCtrl.text = next.toStringAsFixed(1);
      }
    });
  }

  // 랭킹페이지 열기
  Future<void> _openFavoriteRanking() async {
    _applySearchRPctFromText(_rCtrl.text);

    if (_favorites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('즐겨찾기 항목이 없습니다.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FavoriteRankingPage(
          hub: widget.hub,
          market: _tab,
          requiredReturnPct: _searchRPct,
        ),
      ),
    );

    await _loadFav();
  }

  Widget _requiredReturnSearchCard({bool compact = false}) {
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
                      ResultCopy.requiredReturnLabel(context),
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
                      onSubmitted: (v) => _applySearchRPctFromText(v),
                      onEditingComplete: () {
                        _applySearchRPctFromText(_rCtrl.text);
                        FocusScope.of(context).unfocus();
                      },
                      onTapOutside: (_) {
                        _applySearchRPctFromText(_rCtrl.text);
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
                  value: _searchRPct,
                  min: 5,
                  max: 20,
                  divisions: 150,
                  label: "${_searchRPct.toStringAsFixed(1)}%",
                  onChanged: (v) {
                    setState(() {
                      _searchRPct = v;
                      _rCtrl.text = v.toStringAsFixed(1);
                    });
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

  // =========================
  // ✅ 자동검색: 디바운스 (IME 조합 대응)
  // =========================
  void _onChanged(String v) {
    _debounce?.cancel();

    final q = v.trim();

    if (q.isEmpty) {
      _searchSeq++; // 이전 검색 무효화
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    _searchSeq++;
    final int mySeq = _searchSeq;

    // 조합이 끝날 때까지 기다렸다가 자동검색 실행
    void schedule(int waitMs, int attemptsLeft) {
      _debounce?.cancel();
      _debounce = Timer(Duration(milliseconds: waitMs), () {
        if (!mounted) return;
        if (mySeq != _searchSeq) return; // 더 최신 입력이 있으면 중단

        // 최신 텍스트로 검색(캡쳐된 q 말고 현재값 사용)
        final latest = _controller.text.trim();
        if (latest.isEmpty) return;

        // 아직 한글 조합 중이면 조금 더 기다림 (최대 몇 번만)
        if (_isComposing() && attemptsLeft > 0) {
          schedule(80, attemptsLeft - 1);
          return;
        }

        // 조합이 끝났거나(또는 너무 오래 조합이면) 검색 실행
        _runSearch(keyword: latest, mySeq: mySeq);
      });
    }

    // 180ms 디바운스 + 조합이면 120ms 간격으로 최대 8번 더 대기(약 1초)
    schedule(180, 8);
  }

  bool _looksLikeKrQuery(String q) {
    final s = q.trim();
    if (s.isEmpty) return false;

    // 1) 한글(자모 포함) → 국내로 간주
    if (RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(s)) return true;

    // 2) 숫자/영숫자 코드 → 국내로 간주
    final up = s.replaceAll(' ', '').toUpperCase();

    // 2-1) 숫자 4~6자리
    if (RegExp(r'^\d{4,6}$').hasMatch(up)) return true;

    // 2-2) 국내 단축코드(예: 0007C0) = 앞이 숫자인 6자리
    if (RegExp(r'^\d{5}[0-9A-Z]$').hasMatch(up)) return true;

    return false;
  }

  bool _looksLikeUsTicker(String q) {
    final t = q.trim().toUpperCase();
    return RegExp(r'^[A-Z]{1,6}([.\-][A-Z0-9]{1,3})?$').hasMatch(t);
  }

  // =============================
  // ✅ 검색: 돋보기/엔터로 즉시 검색
  // =============================
  Future<void> _runSearch({String? keyword, int? mySeq}) async {
    _debounce?.cancel();

    final q = (keyword ?? _controller.text).trim();

    // 공백이면 초기화
    if (q.isEmpty) {
      _searchSeq++;
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }

    // 자동검색이면 mySeq 유지, 수동검색이면 새 seq 발급
    final int seq = mySeq ?? (++_searchSeq);

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // US 한글 alias 다중 결과는 결과 리스트에 바로 표시
      if (_isLikelyUsAliasQuery(q)) {
        final aliasGroups = SearchAlias.resolveUsGroups(q, limit: 12);

        if (aliasGroups.length >= 2) {
          final resolved = await _resolveAliasGroupsToItems(
            aliasGroups,
            tab: Market.us,
            fallbackMarket: 'US',
          );

          if (!mounted) return;
          if (seq != _searchSeq) return;

          setState(() {
            _results = resolved;
            _loading = false;
            _error = null;
          });

          FocusScope.of(context).requestFocus(_searchFocus);
          return;
        }
      }

      //  KR 영어 alias 다중 결과도 바로 표시
      if (_tab == Market.kr) {
        final krAliasGroups = SearchAlias.resolveKrGroups(q, limit: 12);

        if (krAliasGroups.length >= 2) {
          final resolved = await _resolveAliasGroupsToItems(
            krAliasGroups,
            tab: Market.kr,
            fallbackMarket: 'KRX',
          );

          if (!mounted) return;
          if (seq != _searchSeq) return;

          setState(() {
            _results = resolved;
            _loading = false;
            _error = null;
          });

          FocusScope.of(context).requestFocus(_searchFocus);
          return;
        }
      }

      // 탭에 맞게 쿼리 변환(US: 한글->티커, KR: 한글->코드)
      final mapped = _mapQueryByTab(_tab, q);

      debugPrint('[Search] tab=$_tab q="$q" mapped="$mapped"');

      //  US 탭에서 "국내로 보이는" 입력인데 US alias 변환이 안 된 경우 → 안내만
      if (_tab == Market.us) {
        final bool hasUsAlias = SearchAlias.resolveUsGroups(q, limit: 1).isNotEmpty;
        final bool looksKr = _looksLikeKrQuery(q) || SearchAlias.looksLikeKrCode(q);

        if (!hasUsAlias && looksKr) {
          if (!mounted) return;
          if (seq != _searchSeq) return;

          setState(() {
            _loading = false;
            _results = [];
            _error = t.searchTabLooksKrGuide;
          });
          FocusScope.of(context).requestFocus(_searchFocus);
          return;
        }
      }

      // ✅ 검색은 딱 1번만
      final r = await widget.hub.search(_tab, mapped);
      final isManualKeyword = keyword != null;

      if (!mounted) return;
      if (seq != _searchSeq) return;            // 최신 요청 아니면 폐기
      //if (_controller.text.trim() != q) return; // 입력이 바뀌면 폐기
      if (!isManualKeyword && _controller.text.trim() != q) return;   // 키위드를 썼을 때만 체크

      setState(() {
        _results = r;
        _loading = false;
      });

      FocusScope.of(context).requestFocus(_searchFocus);
    } catch (e) {
      if (!mounted) return;
      if (seq != _searchSeq) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });

      FocusScope.of(context).requestFocus(_searchFocus);
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchSeq++;

    _controller.clear();
    setState(() {
      _results = [];
      _loading = false;
      _error = null;
    });

    FocusScope.of(context).requestFocus(_searchFocus);
  }

  String _mapQueryByTab(Market tab, String q) {
    final raw = q.trim();
    if (raw.isEmpty) return raw;

    if (tab == Market.kr) {
      final digits = raw.replaceAll(' ', '');
      if (RegExp(r'^\d{4,6}$').hasMatch(digits)) {
        return digits.padLeft(6, '0');
      }

      final up = raw.replaceAll(' ', '').toUpperCase();
      if (RegExp(r'^[0-9A-Z]{6}$').hasMatch(up)) return up;

      return raw;
    }

    // tab == Market.us
    final groups = SearchAlias.resolveUsGroups(raw, limit: 12);

    // ✅ 1개일 때만 바로 티커 치환
    if (groups.length == 1) {
      return groups.first.code;
    }

    // 여러 개면 원문 유지
    return raw.toUpperCase();
  }

  // US 거래소로 분류
  String _displayMarketText(StockSearchItem s) {
    final market = s.market.trim();
    if (market.isEmpty) return _isUsItem(s) ? t.marketUs : t.marketUnknown;
    return market;
  }

  // 업종 헬퍼
  String? _industryText(StockSearchItem s) {
    final hasIndustry = s.industry?.trim().isNotEmpty ?? false;
    final hasSector = s.sector?.trim().isNotEmpty ?? false;
    if (!hasIndustry && !hasSector) return null;

    final locale = Localizations.localeOf(context);

    if (_isUsItem(s)) {
      final out = SearchAlias.displayUsIndustry(
        industryEn: s.industry,
        sectorEn: s.sector,
        locale: locale,
      ).trim();

      return out.isEmpty ? null : out;
    }

    final out = SearchAlias.displayKrIndustry(
      koIndustry: s.industry,
      locale: locale,
    ).trim();

    return out.isEmpty ? null : out;
  }

  String _itemMetaText(StockSearchItem s) {
    final industry = _industryText(s);
    if (industry != null) {
      return '${s.code} · $industry';
    }
    return '${s.code} · ${_displayMarketText(s)}';
  }

  // 로고 반응형 사이즈
  double _responsiveMarkSize(
    BuildContext context, {
    double base = 36,
    double max = 48,
  }) {
    final ts = MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.35);
    return (base + (ts - 1.0) * 10).clamp(base, max).toDouble();
  }

  // =========================
  // 상세 페이지 이동
  // =========================
  Future<void> _openResult(StockSearchItem s, {bool recordRecent = true}) async {
    _applySearchRPctFromText(_rCtrl.text, updateText: true);
    debugPrint('[OpenResult] start ${s.code}');

    // 1) 최근검색 저장은 기다리지 않음
    if (recordRecent) {
      unawaited(
        _recentStore.add(_tab, s).catchError((e, st) {
          debugPrint('[OpenResult] recent error: $e');
          debugPrint('$st');
        }),
      );
    }

    if (!mounted) return;

    // 2) 광고 노출 기회 카운트 + 준비되어 있을 때만 표시
    AdService.I.onOpenResult();

    if (AdService.I.adsEnabled &&
        AdService.I.isInterstitialEligibleNow &&
        AdService.I.hasReadyInterstitial) {
      try {
        await AdService.I.maybeShowInterstitial();
        debugPrint('[OpenResult] ad done');
      } catch (e, st) {
        debugPrint('[OpenResult] ad error: $e');
        debugPrint('$st');
      }
    }

    if (!mounted) return;

    // 3) 결과 화면 이동
    final nav = Navigator.of(context);

    try {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            hub: widget.hub,
            item: s,
            market: _tab,
            initialRequiredReturnPct: _searchRPct,
          ),
        ),
      );
      debugPrint('[OpenResult] after pop');
    } catch (e, st) {
      debugPrint('[OpenResult] push error: $e\n$st');
      if (!mounted) return;
      setState(() => _error = t.detailPageOpenFailed('$e'));
      return;
    }

    if (!mounted) return;

    // 4) 뒤로 왔을 때 초기화
    _controller.clear();
    _debounce?.cancel();
    _searchSeq++;

    setState(() {
      _results = [];
      _loading = false;
      _error = null;
    });

    try {
      await _loadFav();
      await _loadRecents();
    } catch (_) {}

    if (mounted) {
      FocusScope.of(context).requestFocus(_searchFocus);
    }
  }

  // =========================
  // 삭제/전체삭제 다이얼로그들
  // =========================
  Future<void> _confirmDeleteRecent(StockSearchItem s) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.recentDeleteTitle),
        content: Text(t.recentDeleteConfirm(s.name, s.code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _recentStore.remove(_tab, s.code);
      await _loadRecents();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(t.deletedItem(s.name))));
    }
  }

  Future<void> _confirmClearRecents() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearRecentTitle),
        content: Text(t.clearRecentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _recentStore.clear(_tab);
      await _loadRecents();
      if (!context.mounted) return;

      messenger.showSnackBar( SnackBar(content: Text(t.recentCleared)));
    }
  }

  Future<void> _confirmDeleteFavorite(StockSearchItem s) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.favoritesDeleteTitle),
        content: Text(t.favoritesDeleteConfirm(s.name, s.code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _favStore.remove(_tab, s.code);
      await _loadFav();
      if (!context.mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(t.deletedItem(s.name))));
    }
  }

  Future<void> _confirmClearFavorites() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearFavoritesTitle),
        content: Text(t.clearFavoritesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _favStore.clear(_tab);
      await _loadFav();
      if (!context.mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(t.favoritesCleared)));
    }
  }

  // =========================
  // UI 조각들
  // =========================
  Future<void> _changeMarketTab(Market next) async {
    if (_tab == next) return;

    // 탭 변경 UI 반영
    if (!mounted) return;
    setState(() => _tab = next);

    // 탭에 맞는 데이터 로드
    await _loadFav();
    await _loadRecents();

    // 검색어 있으면 재검색, 없으면 결과 초기화
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      await _runSearch(keyword: q);
    } else {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
    }

    // 포커스 복귀
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_searchFocus);
  }

  Widget _marketTabs() {
    return _leftAccentCard(
      color: _accent2,
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<Market>(
              segments: [
                ButtonSegment(value: Market.kr, label: Text(t.tabKr)),
                ButtonSegment(value: Market.us, label: Text(t.tabUs)),
              ],
              selected: {_tab},
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _accent2.withAlpha(35);
                  return Colors.white.withAlpha(120);
                }),
                side: WidgetStatePropertyAll(BorderSide(color: _accent2.withAlpha(80))),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _accent2;
                  return Colors.black87;
                }),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              onSelectionChanged: (s) => _changeMarketTab(s.first),
            ),
          ),
        ],
      ),
    );
  }

  // 최근검색, 즐겨찾기 us 한글
  bool _isUsItem(StockSearchItem s) {
    final m = s.market.trim().toUpperCase();
    return _tab == Market.us || m == 'US';
  }

  String _displayItemName(StockSearchItem s) {
    final locale = Localizations.localeOf(context);

    if (_isUsItem(s)) {
      if (locale.languageCode == 'ko') {
        final ko = SearchAlias.usPrimaryKoName(s.code);
        return ko ?? s.name;
      }
      return s.name;
    }

    return SearchAlias.displayKrName(
      code: s.code,
      koName: s.name,
      locale: locale,
    );
  }

  String? _displayItemOriginalName(StockSearchItem s) {
    final locale = Localizations.localeOf(context);

    if (_isUsItem(s)) {
      if (locale.languageCode != 'ko') return null;

      final ko = SearchAlias.usPrimaryKoName(s.code);
      final en = s.name.trim();

      if (ko == null || en.isEmpty || ko == en) return null;
      return en;
    }

    final en = SearchAlias.krEnglishName(s.code)?.trim();
    if (en == null || en.isEmpty || en == s.name.trim()) return null;
    return en;
  }

  // alisa 결과에도 로고 넣기 함수
  Future<List<StockSearchItem>> _resolveAliasGroupsToItems(
    List<AliasGroup> groups, {
    required Market tab,
    required String fallbackMarket,
  }) async {
    final futures = groups.map((g) async {
      try {
        final found = await widget.hub.search(tab, g.code);

        for (final item in found) {
          if (item.code.trim().toUpperCase() == g.code.trim().toUpperCase()) {
            return item;
          }
        }

        if (found.isNotEmpty) {
          return found.first;
        }
      } catch (_) {
        // fallback below
      }

      return StockSearchItem(
        code: g.code,
        name: g.primaryName,
        market: fallbackMarket,
      );
    });

    return Future.wait(futures);
  }

  bool _isLikelyUsAliasQuery(String q) {
    return _tab == Market.us && SearchAlias.hasHangul(q.trim());
  }

  String _markTextForItem(StockSearchItem s) {
    final displayName = _displayItemName(s).trim();

    if (_isUsItem(s)) {
      final ko = SearchAlias.usPrimaryKoName(s.code);
      if (ko != null && ko.isNotEmpty) {
        return ko.substring(0, 1);
      }

      final code = s.code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (code.length >= 2) return code.substring(0, 2);
      if (code.isNotEmpty) return code;
      return 'U';
    }

    if (displayName.isNotEmpty) return displayName.substring(0, 1);
    return 'K';
  }

  Widget _companyMark(StockSearchItem s, {double size = 36}) {
    final isUs = _isUsItem(s);
    final base = isUs ? Colors.indigo : Colors.teal;
    final text = _markTextForItem(s);
    final logoUrl = s.logoUrl?.trim();

    debugPrint('[companyMark] code=${s.code}, name=${s.name}, logoUrl=[$logoUrl]');

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

    if (logoUrl == null || logoUrl.isEmpty) {
      debugPrint('[companyMark] EMPTY logoUrl -> fallback, code=${s.code}');
      return fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => fallback(),
        errorWidget: (context, url, error) {
          debugPrint('[companyMark] load failed, url=[$url], error=$error');
          return fallback();
        },
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
      ),
    );
  }

 
  Widget _sectionHeader({
    required String title,
    VoidCallback? onClear,
    String? clearTooltip,
    Color? badgeColor,
    Widget? extraAction,
  }) {
    final c = badgeColor ?? Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.withAlpha(24),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.withAlpha(200),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: c,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (extraAction != null) ...[
          extraAction,
          const SizedBox(width: 4),
        ],
        if (onClear != null)
          IconButton(
            tooltip: clearTooltip ?? t.deleteAll,
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }

  // 랭킹 버튼
  Widget _favoriteRankingActionButton() {
    const border = Color(0xFFCBD5E1);   // 연한 회색 테두리
    const text = Color(0xFF334155);     // 짙은 슬레이트 글자
    const bg = Color(0xFFF8FAFC);       // 아주 옅은 배경

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _openFavoriteRanking,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.leaderboard_rounded,
                size: 15,
                color: text,
              ),
              const SizedBox(width: 5),
              Text(
                isKoLang ? '랭킹' : 'Ranking',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: text,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 최근검색 카드
  Widget _stockMiniCard(StockSearchItem s, {VoidCallback? onLongPress}) {
    final mq = MediaQuery.of(context);
    final ts = mq.textScaler.scale(1.0).clamp(1.0, 2.0);
    final cardW = (180.0 + (ts - 1.0) * 70.0).clamp(180.0, 260.0);

    final displayName = _displayItemName(s);
    final originalName = _displayItemOriginalName(s);

    Widget clampScale(Widget child, {double max = 1.2}) {
      final cur = mq.textScaler.scale(1.0);
      if (cur <= max) return child;
      return MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(max)),
        child: child,
      );
    }

    return InkWell(
      onTap: () => _openResult(s, recordRecent: true),
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: cardW,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _accent.withAlpha(10),
          border: Border.all(color: _accent.withAlpha(55)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _companyMark(s, size: _responsiveMarkSize(context)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            if (originalName != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                originalName,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _itemMetaText(s),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            clampScale(
              Text(
                t.viewValuation,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _accent.withAlpha(220),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 즐겨찾기 목록형
  Widget _favoriteListTile(StockSearchItem s, {VoidCallback? onLongPress}) {
    final displayName = _displayItemName(s);
    final originalName = _displayItemOriginalName(s);

    return InkWell(
      onTap: () => _openResult(s, recordRecent: true),
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _accent.withAlpha(10),
          border: Border.all(color: _accent.withAlpha(55)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _companyMark(s, size: _responsiveMarkSize(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (originalName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      originalName,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _itemMetaText(s),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: _accent.withAlpha(220)),
          ],
        ),
      ),
    );
  }

  // 검색 목록 
  Widget _resultCardTile(StockSearchItem s) {
    final displayName = _displayItemName(s);
    final originalName = _displayItemOriginalName(s);

    return InkWell(
      onTap: () => _openResult(s, recordRecent: true),
      child: _leftAccentCard(
        color: _accent2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _companyMark(s, size: _responsiveMarkSize(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (originalName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      originalName,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    _itemMetaText(s),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: _accent2.withAlpha(220)),
          ],
        ),
      ),
    );
  }

  //  검색창
  Widget _searchBox({bool compact = false}) {
    final hint = compact
    ? (_tab == Market.kr ? t.searchPageCompactHintKr : t.searchPageCompactHintUs)
    : (_tab == Market.kr ? t.searchPageHintKr : t.searchPageHintUs);

    return _leftAccentCard(
      color: _accent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, v, child) {
              final hasText = v.text.trim().isNotEmpty;

              // 최소폭도 "항상 2칸(지우기 + 검색)" 기준으로 고정
              final btnSize = compact ? 38.0 : 44.0;
              final rightPad = compact ? 2.0 : 4.0;

              return TextField(
                key: const ValueKey('searchField'),
                controller: _controller,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: compact ? 10 : 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: compact ? 12 : 14,
                    color: Colors.grey[600],
                  ),

                  // ✅ 왼쪽 prefix 돋보기 제거
                  prefixIcon: null,
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),

                  suffixIconConstraints: BoxConstraints(
                    // 지우기 슬롯 1칸 + 검색 1칸 + 오른쪽 패딩
                    minWidth: btnSize * 2 + rightPad,
                    minHeight: compact ? 40 : 48,
                  ),

                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 지우기 "자리"는 항상 유지(없으면 투명 + 터치 막기)
                      SizedBox(
                        width: btnSize,
                        height: btnSize,
                        child: IgnorePointer(
                          ignoring: !hasText,
                          child: Opacity(
                            opacity: hasText ? 1.0 : 0.0,
                            child: IconButton(
                              tooltip: t.clearButton,
                              onPressed: _clearSearch,
                              icon: Icon(Icons.close, color: Colors.grey[700], size: compact ? 18 : 22),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(width: btnSize, height: btnSize),
                            ),
                          ),
                        ),
                      ),

                      // 검색(돋보기)은 항상 같은 자리(맨 오른쪽)
                      IconButton(
                        tooltip: t.searchButton,
                        onPressed: hasText ? _runSearch : null,
                        icon: Icon(Icons.search, color: _accent.withAlpha(235), size: compact ? 22 : 26),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tightFor(width: btnSize, height: btnSize),
                      ),

                      SizedBox(width: rightPad),
                    ],
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _accent.withAlpha(70)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _accent.withAlpha(60)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _accent.withAlpha(160), width: 1.5),
                  ),
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _runSearch(),
              );
            },
          ),

          // 세로모드에서만 배너 보여줌(가로모드는 공간 확보)
          if (!compact) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: _accent.withAlpha(180),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.autoSearchHelp,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim();
    final showHistory = q.isEmpty;
    final isLand = MediaQuery.of(context).orientation == Orientation.landscape;

    final pad = EdgeInsets.all(isLand ? 8 : 12);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLand ? 48 : null,
       title: Text(
          t.searchPageTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: t.rankingPageTitle,
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              shadowColor: WidgetStatePropertyAll(Colors.transparent),
              surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
            ),
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RankingPage(hub: widget.hub),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: t.moreMenu,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'backup_export':
                  await _exportBackupToFile();
                  break;
                case 'backup_import':
                  await _importBackupFromFile();
                  break;
                case 'about':
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'backup_export',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 10),
                    Text(t.backupExport),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'backup_import',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 10),
                    Text(t.backupImport),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 10),
                    Text(t.aboutApp),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        left: false,
        right: false,
        maintainBottomViewPadding: true,
        child: AdBanner(),
      ),
      body: SafeArea(
        child: Container(
          color: _accent.withAlpha(8),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: pad,
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _marketTabs(),
                      SizedBox(height: isLand ? 6 : 10),

                      _requiredReturnSearchCard(compact: isLand),
                      SizedBox(height: isLand ? 6 : 8),

                      _searchBox(compact: isLand),
                      SizedBox(height: isLand ? 6 : 10),

                      if (_loading) const LinearProgressIndicator(),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),

                      const SizedBox(height: 8),

                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, pad.bottom),
                sliver: showHistory ? _historySliver() : _resultSliver(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyList() {
    final stripH = _miniStripHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_recents.isNotEmpty) ...[
          _sectionHeader(
            title: t.recentSearches,
            onClear: _confirmClearRecents,
            clearTooltip: t.recentSearchesDeleteAllTooltip,
            badgeColor: Colors.orange,
          ),
          const SizedBox(height: 8),
          ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SizedBox(
              height: stripH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                itemCount: _recents.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _recents[i];
                  return _stockMiniCard(
                    s,
                    onLongPress: () => _confirmDeleteRecent(s),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
        ] else ...[
          _emptyHintCard(
            icon: Icons.history,
            title: t.recentSearchesEmptyTitle,
            desc: t.recentSearchesEmptyDesc,
          ),
          const SizedBox(height: 12),
        ],

        if (_favorites.isNotEmpty) ...[
          _sectionHeader(
            title: t.favorites,
            onClear: _confirmClearFavorites,
            clearTooltip: t.favoritesDeleteAllTooltip,
            badgeColor: Colors.purple,
            extraAction: _favoriteRankingActionButton(),
          ),
          const SizedBox(height: 8),
          ...List.generate(_favorites.length, (i) {
            final s = _favorites[i];
            return Padding(
              padding: EdgeInsets.only(
                bottom: i == _favorites.length - 1 ? 0 : 8,
              ),
              child: _favoriteListTile(
                s,
                onLongPress: () => _confirmDeleteFavorite(s),
              ),
            );
          }),
        ] else ...[
          _emptyHintCard(
            icon: Icons.star_border,
            title: t.favoritesEmptyTitle,
            desc: t.favoritesEmptyDesc,
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  SliverToBoxAdapter _historySliver() {
    return SliverToBoxAdapter(child: _historyList());
  }

  Widget _resultSliver() {
    final q = _controller.text.trim();
    final mapped = _mapQueryByTab(_tab, q);

    final looksTicker =
        _looksLikeUsTicker(mapped) && !SearchAlias.looksLikeKrCode(mapped);

    final emptyDesc = (_tab == Market.kr)
        ? (looksTicker ? t.emptySearchDescKrTryUs : t.emptySearchDescKrCheck)
        : t.emptySearchDescUsCheck;

    // 결과 없고 로딩도 아니면: 빈 안내 카드만 보여주기
    if (_results.isEmpty && !_loading) {
      return SliverToBoxAdapter(
        child: _emptyHintCard(
          icon: Icons.search_off,
          title: t.emptySearchTitle,
          desc: emptyDesc,
        ),
      );
    }

    // 결과 리스트 (separator 포함)
    final count = _results.length;
    final childCount = (count == 0) ? 0 : (count * 2 - 1);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          if (i.isOdd) return const SizedBox(height: 6);
          final idx = i ~/ 2;
          return _resultCardTile(_results[idx]);
        },
        childCount: childCount,
      ),
    );
  }

  Widget _emptyHintCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Card(
      elevation: 0,
      color: _tintBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _tintBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _accent.withAlpha(18),
              child: Icon(icon, color: _accent.withAlpha(230)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackupToFile() async {
    try {
      final jsonText = await _backupService.exportJson();

      final labels = AppBackupFileLabels.defaults(
        isKo: Localizations.localeOf(context).languageCode == 'ko',
      );

      final savedPath = await _backupFileService.saveBackupFile(
        jsonText,
        labels: labels,
      );

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.exportBackupCanceled)),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.exportBackupCreated(savedPath))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.exportBackupFailed('$e'))),
      );
    }
  }

  Future<void> _importBackupFromFile() async {
    try {
      final jsonText = await _backupFileService.pickBackupFileAndRead();

      if (jsonText == null || jsonText.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.importBackupCanceled)),
        );
        return;
      }

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.importBackupTitle),
          content: Text(t.importBackupConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.importButton),
            ),
          ],
        ),
      );

      if (ok != true) return;

      await _backupService.importJson(jsonText, overwrite: true);

      await _loadFav();
      await _loadRecents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.importBackupSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.importBackupFailed(_backupErrorText(e)))),
      );
    }
  }

  // =========================
  // 🎨 SearchPage UI Palette
  // =========================
  Color get _accent => _tab == Market.us ? Colors.blue : Colors.green;
  Color get _accent2 => _tab == Market.us ? Colors.indigo : Colors.teal;
  Color get _tintBg => _accent.withAlpha(12);
  Color get _tintBorder => _accent.withAlpha(55);

  BoxDecoration _softCardDeco({Color? color}) => BoxDecoration(
    color: (color ?? _accent).withAlpha(12),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: (color ?? _accent).withAlpha(55)),
  );

  // 공통 “왼쪽 포인트 라인 카드”
  Widget _leftAccentCard({
    required Widget child,
    Color? color,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    final c = color ?? _accent;
    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: _softCardDeco(color: c),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: c.withAlpha(170), width: 4)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
