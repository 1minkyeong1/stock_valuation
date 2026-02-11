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

class SearchPage extends StatefulWidget {
 final RepoHub hub;
  const SearchPage({super.key, required this.hub});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

 // ✅ 국내 종목 영문 alias (최소 세트)
  static const Set<String> _krAliases = {
    'naver',
    'samsung',
    'samsung electronics',
    'kakao',
    'lg',
    'hyundai',
    'hynix',
    'sk hynix',
  };

  static const Map<String, String> _krAliasToCode = {
    'naver': '035420',
    'samsung': '005930',
    'samsung electronics': '005930',
    'kakao': '035720',
    'lg': '066570',        // LG전자 기준
    'hyundai': '005380',   // 현대차 기준
    'hynix': '000660',
    'sk hynix': '000660',
  };

  String _normalizeKrQuery(String q) {
    final t = q.trim().toLowerCase();
    final code = _krAliasToCode[t];
    return code ?? q.trim();
  }

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

  // =========================
  // ✅ 자동검색: 디바운스
  // =========================
  void _onChanged(String v) {
    final q = v.trim();

    _debounce?.cancel();

   if (q.isEmpty) {
      _searchSeq++; // 이전 검색 무효화
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }

   // 현재 시점의 시퀀스를 캡처하여 타이머에 전달
    _searchSeq++; 
    final int mySeq = _searchSeq;

    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runSearch(keyword: q, mySeq: mySeq);
    });
  }

    bool _looksLikeKrQuery(String q) {
      final s = q.trim();
      if (s.isEmpty) return false;

      // 1) 한글 → 국내
      if (RegExp(r'[가-힣]').hasMatch(s)) return true;

      // 2) 숫자 4~6자리 → 국내 코드
      if (RegExp(r'^\d{4,6}$').hasMatch(s.replaceAll(' ', ''))) return true;

      // 3) 영문 alias → 국내
      final t = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      return _krAliases.contains(t);
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

    // ✅ 탭 분리: US 탭에서 KR 입력 차단, KR 탭에서 US 티커 차단
    if (_tab == Market.us && _looksLikeKrQuery(q)) {
      // ✅ 자동으로 국내로 전환해서 검색
      setState(() => _tab = Market.kr);

      // 탭별 즐겨찾기/최근 다시 로드(선택: UX 좋아짐)
      await _loadFav();
      await _loadRecents();

      // IMPORTANT: seq 갱신(탭 전환이므로 새 요청으로 취급)
      final int nextSeq = ++_searchSeq;

      // KR로 검색 재호출
      await _runSearch(keyword: q, mySeq: nextSeq);
      return;
    }

    if (_tab == Market.kr && _looksLikeUsTicker(q) && !_looksLikeKrQuery(q)) {
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

    try {
      // 디버깅
      debugPrint('[Search] tab=$_tab q="$q"');

      final q2 = (_tab == Market.kr) ? _normalizeKrQuery(q) : q;
      final r = await widget.hub.search(_tab, q2);

      if (!mounted) return;
      if (seq != _searchSeq) return;            // 최신 요청 아니면 폐기
      if (_controller.text.trim() != q) return; // 사용자가 입력을 바꾼 경우만 폐기

      setState(() {
        _results = r;
        _loading = false;
      });

      // ✅ 검색 후에도 키보드 유지(원하면)
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: SegmentedButton<Market>(
                segments: const [
                  ButtonSegment(value: Market.kr, label: Text("국내")),
                  ButtonSegment(value: Market.us, label: Text("미국")),
                ],
                selected: {_tab},
                onSelectionChanged: (s) async {
                  final next = s.first;

                  //  탭 변경
                  setState(() => _tab = next);

                  //  탭별 최근/즐겨찾기 다시 불러오기
                  await _loadFav();
                  await _loadRecents();

                  //  탭 변경 시 현재 검색어가 있으면 다시 검색
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
            color: c.withAlpha(30),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c),
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
          border: Border.all(color: Colors.grey.shade300),
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
              children: const [
                Text("평가 보기", style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16),
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.corporate_fare, color: Colors.black54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("${s.code} · ${s.market}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 검색창: 큰 버튼 제거 + 돋보기(수동검색) + 자동검색(onChanged)
  Widget _searchBox() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
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
                  hintText: _tab == Market.kr
                      ? "국내 종목명 또는 코드 입력 (예: 삼성전자 / 005930)"
                      : "미국 티커 입력 (예: AAPL / TSLA)",
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasText)
                        IconButton(
                          tooltip: "지우기",
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close),
                        ),
                      IconButton(
                        tooltip: "검색",
                        onPressed: hasText ? _runSearch : null,
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _runSearch(),
              );
            },
          ),
          const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "자동검색이 되며, 필요하면 오른쪽 돋보기로 즉시 검색할 수 있어요.",
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      appBar: AppBar(title: const Text("종목 검색")),
      bottomNavigationBar: const AdBanner(),
      body: SafeArea(
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Icon(icon, color: Colors.black54),
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
}
