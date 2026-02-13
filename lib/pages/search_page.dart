import 'dart:async';
import 'package:flutter/material.dart';

import 'package:stock_valuation_app/data/repository/stock_repository.dart';
import 'package:stock_valuation_app/data/stores/favorites_store.dart';
import 'package:stock_valuation_app/data/stores/recent_store.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';

import 'package:stock_valuation_app/pages/result_page.dart';
import 'package:stock_valuation_app/services/ad_service.dart';
import 'package:stock_valuation_app/widgets/ad_banner.dart';
import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/utils/search_alias.dart';
import 'about_page.dart';

class SearchPage extends StatefulWidget {
 final RepoHub hub;
  const SearchPage({super.key, required this.hub});

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

 @override
  void initState() {
    super.initState();

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

    // ✅ 조합이 끝날 때까지 기다렸다가 자동검색 실행
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

        // ✅ 조합이 끝났거나(또는 너무 오래 조합이면) 검색 실행
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

  // =========================
  // ✅ 검색: 돋보기/엔터로 즉시 검색
  // =========================
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

    // ✅ 자동검색이면 mySeq 유지, 수동검색이면 새 seq 발급
    final int seq = mySeq ?? (++_searchSeq);

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // ✅ 탭에 맞게 쿼리 변환(US: 한글->티커, KR: 한글->코드)
      final mapped = _mapQueryByTab(_tab, q);

      debugPrint('[Search] tab=$_tab q="$q" mapped="$mapped"');

      // ✅ (추가) US 탭에서 "국내로 보이는" 입력인데 US alias 변환이 안 된 경우 → 안내만
      if (_tab == Market.us) {
        final usHit = SearchAlias.resolveUs(q);
        final bool looksKr = _looksLikeKrQuery(q) || SearchAlias.looksLikeKrCode(q);

        // US로 매핑이 안 됐고, KR처럼 보이면: 자동전환 X, 안내만
        if (usHit == null && looksKr) {
          if (!mounted) return;
          if (seq != _searchSeq) return;

          setState(() {
            _loading = false;
            _results = [];
            _error = "국내 종목으로 보입니다. ‘국내’ 탭에서 검색해 주세요.";
          });
          FocusScope.of(context).requestFocus(_searchFocus);
          return;
        }
      }

      // ✅ KR 탭에서 미국 티커 형태는 차단(자동 전환 X)
      if (_tab == Market.kr &&
          _looksLikeUsTicker(mapped) &&
          !SearchAlias.looksLikeKrCode(mapped)) {
        if (!mounted) return;
        if (seq != _searchSeq) return;

        setState(() {
          _loading = false;
          _results = [];
          _error = "국내 탭에서는 미국 티커 검색을 지원하지 않습니다. ‘미국’ 탭에서 검색해 주세요.";
        });
        FocusScope.of(context).requestFocus(_searchFocus);
        return;
      }

      // ✅ 검색은 딱 1번만
      final r = await widget.hub.search(_tab, mapped);

      if (!mounted) return;
      if (seq != _searchSeq) return;            // 최신 요청 아니면 폐기
      if (_controller.text.trim() != q) return; // 입력이 바뀌면 폐기

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
      // ✅ (중요) 한글/별칭 → 코드 치환 제거
      // final hit = SearchAlias.resolveKr(raw);
      // if (hit != null) return hit.code;

      // 1) 숫자 4~6자리면 6자리로 패딩
      final digits = raw.replaceAll(' ', '');
      if (RegExp(r'^\d{4,6}$').hasMatch(digits)) {
        return digits.padLeft(6, '0');
      }

      // 2) 0007C0 같은 영숫자 6자리면 대문자
      final up = raw.replaceAll(' ', '').toUpperCase();
      if (RegExp(r'^[0-9A-Z]{6}$').hasMatch(up)) return up;

      // 3) 그 외(한글/부분검색)는 그대로
      return raw;
    }

    // tab == Market.us
    final hit = SearchAlias.resolveUs(raw);
    if (hit != null) return hit.code;

    return raw.toUpperCase();
  }

  // =========================
  // 상세 페이지 이동
  // =========================
  Future<void> _openResult(StockSearchItem s, {bool recordRecent = true}) async {
    debugPrint('[OpenResult] start ${s.code}');

    // 1) recent 저장은 실패해도 넘어가게
    if (recordRecent) {
      try {
        await _recentStore.add(_tab, s);
        await _loadRecents();
        debugPrint('[OpenResult] recent saved');
      } catch (e, st) {
        debugPrint('[OpenResult] recent error: $e\n$st');
      }
    }
    if (!mounted) return;

    // 2) 광고는 실패해도 넘어가게
    try {
      AdService.I.onOpenResult();
      await AdService.I.maybeShowInterstitial();
      debugPrint('[OpenResult] ad done');
    } catch (e, st) {
      debugPrint('[OpenResult] ad error: $e\n$st');
    }
    if (!mounted) return;

    // ✅ 3) push 직전에 Navigator를 다시 잡기 (중요)
    debugPrint('[OpenResult] before push');
    final nav = Navigator.of(context);

    try {
      await nav.push(
        MaterialPageRoute(
          builder: (_) => ResultPage(hub: widget.hub, item: s, market: _tab),
        ),
      );
      debugPrint('[OpenResult] after pop');
    } catch (e, st) {
      debugPrint('[OpenResult] push error: $e\n$st');
      if (!mounted) return;
      setState(() => _error = '상세화면 이동 실패: $e');
      return;
    }

    if (!mounted) return;

    // 4) 뒤로 왔을 때 초기화(원하면 유지/삭제 선택)
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
        title: const Text("최근 검색 삭제"),
        content: Text("${s.name}(${s.code}) 를 최근 검색에서 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제")),
        ],
      ),
    );

    if (ok == true) {
      await _recentStore.remove(_tab, s.code);
      await _loadRecents();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text("${s.name} 삭제됨")));
    }
  }

  Future<void> _confirmClearRecents() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("최근 검색 전체 삭제"),
        content: const Text("최근 검색 목록을 모두 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제")),
        ],
      ),
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _recentStore.clear(_tab);
      await _loadRecents();
      if (!context.mounted) return;

      messenger.showSnackBar(const SnackBar(content: Text("최근 검색을 모두 삭제했습니다.")));
    }
  }

  Future<void> _confirmDeleteFavorite(StockSearchItem s) async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("즐겨찾기 삭제"),
        content: Text("${s.name}(${s.code}) 를 즐겨찾기에서 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제")),
        ],
      ),
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _favStore.remove(_tab, s.code);
      await _loadFav();
      if (!context.mounted) return;

      messenger.showSnackBar(SnackBar(content: Text("${s.name} 삭제됨")));
    }
  }

  Future<void> _confirmClearFavorites() async {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("즐겨찾기 전체 삭제"),
        content: const Text("즐겨찾기 목록을 모두 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("삭제")),
        ],
      ),
    );

    if (!context.mounted) return;

    if (ok == true) {
      await _favStore.clear(_tab);
      await _loadFav();
      if (!context.mounted) return;

      messenger.showSnackBar(const SnackBar(content: Text("즐겨찾기를 모두 삭제했습니다.")));
    }
  }

  // =========================
  // UI 조각들
  // =========================
  Widget _marketTabs() {
    return _leftAccentCard(
      color: _accent2,
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<Market>(
              segments: const [
                ButtonSegment(value: Market.kr, label: Text("국내")),
                ButtonSegment(value: Market.us, label: Text("미국")),
              ],
              selected: {_tab},
              style: ButtonStyle(
                // 선택/비선택 배경
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _accent2.withAlpha(35);
                  return Colors.white.withAlpha(120);
                }),
                // 테두리
                side: WidgetStatePropertyAll(BorderSide(color: _accent2.withAlpha(80))),
                // 글자색
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return _accent2;
                  return Colors.black87;
                }),
                // 살짝 둥글게
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              onSelectionChanged: (s) async {
                final next = s.first;

                setState(() => _tab = next);
                await _loadFav();
                await _loadRecents();

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

                if (!mounted) return;
                FocusScope.of(context).requestFocus(_searchFocus);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _sectionHeader({
    required String title,
    VoidCallback? onClear,
    String? clearTooltip,
    Color? badgeColor,
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
                decoration: BoxDecoration(color: c.withAlpha(200), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (onClear != null)
          IconButton(
            tooltip: clearTooltip ?? "전체 삭제",
            onPressed: onClear,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }

  Widget _stockMiniCard(StockSearchItem s, {VoidCallback? onLongPress}) {
    return InkWell(
      onTap: () => _openResult(s, recordRecent: true),
      onLongPress: onLongPress,
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _accent.withAlpha(10),
          border: Border.all(color: _accent.withAlpha(55)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(s.code, style: TextStyle(color: Colors.grey[800])),
            Text(s.market, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            const Spacer(),
            Row(
              children: [
                const Text("평가 보기", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: _accent.withAlpha(220)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCardTile(StockSearchItem s) {
    return InkWell(
      onTap: () => _openResult(s, recordRecent: true),
      child: _leftAccentCard(
        color: _accent2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _accent2.withAlpha(20),
              child: Icon(Icons.corporate_fare, color: _accent2.withAlpha(220)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    "${s.code} · ${s.market}",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _accent2.withAlpha(220)),
          ],
        ),
      ),
    );
  }

  // ✅ 검색창: 큰 버튼 제거 + 돋보기(수동검색) + 자동검색(onChanged)
  Widget _searchBox() {
    return _leftAccentCard(
      color: _accent,
      child: Column(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, v, child) {
              final hasText = v.text.trim().isNotEmpty;

              return TextField(
                key: const ValueKey('searchField'),
                controller: _controller,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withAlpha(180),
                  hintText: _tab == Market.kr
                      ? "국내 종목명 또는 코드 (예: 삼성전자 / 005930)"
                      : "미국 티커 (예: AAPL / TSLA)",
                  prefixIcon: Icon(Icons.search, color: _accent.withAlpha(220)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasText)
                        IconButton(
                          tooltip: "지우기",
                          onPressed: _clearSearch,
                          icon: Icon(Icons.close, color: Colors.grey[700]),
                        ),
                      IconButton(
                        tooltip: "검색",
                        onPressed: hasText ? _runSearch : null,
                        icon: Icon(Icons.search, color: _accent.withAlpha(230)),
                      ),
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
          const SizedBox(height: 10),

          // ✅ 안내 배너 (살짝 화려한 톤)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _accent.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withAlpha(55)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: _accent.withAlpha(220)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "자동검색이 되며, 필요하면 오른쪽 돋보기로 즉시 검색할 수 있어요.",
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 검색 결과/히스토리 영역은 아래 Expanded에서만 바뀌게(검색창은 고정!)
  @override
  Widget build(BuildContext context) {
    final q = _controller.text.trim();
    final showHistory = q.isEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "종목 검색",
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: '앱 정보',
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              shadowColor: WidgetStatePropertyAll(Colors.transparent),
              surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
            ),
            icon: const Icon(Icons.error_outline), // ⭕ 테두리 + !
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
      body: SafeArea(
        child: Container(
          color: _accent.withAlpha(8), // ✅ 페이지 전체 배경 틴트
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _marketTabs(),
                const SizedBox(height: 10),
                _searchBox(),
                const SizedBox(height: 10),

                if (_loading) const LinearProgressIndicator(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),

                const SizedBox(height: 10),

                Expanded(
                  child: showHistory ? _historyList() : _resultList(),
                ),
              ],
            ),
          ),
        ),  
      ),
    );
  }

  Widget _historyList() {
    return ListView(
      children: [
        if (_recents.isNotEmpty) ...[
          _sectionHeader(
            title: "최근 검색",
            onClear: _confirmClearRecents,
            clearTooltip: "최근 검색 전체 삭제",
            badgeColor: Colors.orange,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
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
          const SizedBox(height: 14),
        ] else ...[
          _emptyHintCard(
            icon: Icons.history,
            title: "최근 검색이 없어요",
            desc: "위에서 종목명을 검색해보세요. 검색 기록이 여기에 쌓입니다.",
          ),
          const SizedBox(height: 12),
        ],

        if (_favorites.isNotEmpty) ...[
          _sectionHeader(
            title: "즐겨찾기",
            onClear: _confirmClearFavorites,
            clearTooltip: "즐겨찾기 전체 삭제",
            badgeColor: Colors.purple,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favorites.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _favorites[i];
                return _stockMiniCard(s, onLongPress: () => _confirmDeleteFavorite(s));
              },
            ),
          ),
        ] else ...[
          _emptyHintCard(
            icon: Icons.star_border,
            title: "즐겨찾기가 비어 있어요",
            desc: "종목 평가 화면에서 ⭐ 버튼을 누르면 여기에 모아볼 수 있어요.",
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _resultList() {
    return (_results.isEmpty && !_loading)
        ? _emptyHintCard(
            icon: Icons.search_off,
            title: "검색 결과가 없어요",
            desc: (_tab == Market.kr) ? "종목명/코드를 다시 확인해보세요." : "티커를 다시 확인해보세요.",
          )
        : ListView.separated(
            itemCount: _results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _resultCardTile(_results[i]),
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
