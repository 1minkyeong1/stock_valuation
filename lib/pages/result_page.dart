import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';
import 'package:stock_valuation_app/data/repository/stock_repository.dart';

import 'package:stock_valuation_app/data/stores/favorites_store.dart';
import 'package:stock_valuation_app/data/stores/stock_input_store.dart';

import 'package:stock_valuation_app/models/valuation_result.dart';
import 'package:stock_valuation_app/models/valuation_rating.dart';
import 'package:stock_valuation_app/services/valuation_service.dart';

import 'package:stock_valuation_app/widgets/ad_banner.dart';
import 'package:stock_valuation_app/utils/number_format.dart';

import 'package:stock_valuation_app/widgets/sell_guide_sheet.dart';
import 'package:stock_valuation_app/widgets/inputs/labeled_number_field.dart';
import 'package:stock_valuation_app/widgets/inputs/metric_field_with_badge.dart';
import 'package:stock_valuation_app/services/external_link_service.dart';
import 'package:stock_valuation_app/utils/money_input_formatter.dart';
import 'package:stock_valuation_app/pages/financial_statement_page.dart';

class ResultPage extends StatefulWidget {
  final RepoHub hub;
  final StockSearchItem item;
  final Market market;

  const ResultPage({
    super.key,
    required this.hub,
    required this.item,
    required this.market,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  // 재무는 2025년만 사용(없으면 2024 fallback) - 안내 메시지에서 사용
  static const int _targetFinanceYear = 2025;

  StockFundamentals? _fundamentals;

  // 상태
  bool _loading = true;
  String? _error;

  String? _priceBasDt; // yyyymmdd
  int? _usedFinanceYear;

  // 즐겨찾기
  final _favStore = FavoritesStore();
  bool _isFav = false;

  // 입력값 저장
  final _inputStore = StockInputStore();
  Timer? _saveDebounce;

  // 외부 링크 서비스
  final _link = const ExternalLinkService();

  // 컨트롤러
  late final TextEditingController _priceCtrl;
  late final TextEditingController _epsCtrl;
  late final TextEditingController _bpsCtrl;
  late final TextEditingController _dpsCtrl;

  // r(%) 슬라이더
  double rPct = 9.0;

  // 초기값(Reset)
  double _initPrice = 0.0;
  StockFundamentals _initF = const StockFundamentals(eps: 0, bps: 0, dps: 0);
  double _initR = 9.0;

  // 고급보기 토글용 (true=고급/작은카드, false=초급/큰카드)
  bool _showAdvanced = true;

  String get _storeKey => "${widget.market.name}:${widget.item.code}";
  bool get _isUS => widget.market == Market.us;

  // 표시용(라벨)
  String get _priceUnitText => _isUS ? r'현재가($)' : '현재가(원)';

  // ✅ 결과/요약 표시용 포맷 (콤마/단위 일관성)
  String _fmtMoney(num v) => _isUS ? fmtUsd(v) : fmtWon(v);

  // 가격 포맷터
  late final TextInputFormatter _priceFormatterKr;
  late final TextInputFormatter _priceFormatterUs;

  // 로딩 단계 표시(디버깅/UX)
  String _stage = '';
  void _setStage(String s) {
    if (!mounted) return;
    setState(() => _stage = s);
    debugPrint('[ResultPage][STAGE] $s');
  }

  @override
  void initState() {
    super.initState();

    _priceCtrl = TextEditingController();
    _epsCtrl = TextEditingController();
    _bpsCtrl = TextEditingController();
    _dpsCtrl = TextEditingController();

    // ✅ 가격 포맷터 준비
    _priceFormatterKr = MoneyInputFormatter(allowDecimal: false);
    _priceFormatterUs = MoneyInputFormatter(allowDecimal: true, decimalDigits: 2);

    debugPrint('[ResultPage] initState item=${widget.item.code} market=${widget.market}');
    _loadFavState();
    _load();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _priceCtrl.dispose();
    _epsCtrl.dispose();
    _bpsCtrl.dispose();
    _dpsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavState() async {
    final v = await _favStore.isFavorite(widget.market, widget.item.code);
    if (!mounted) return;
    setState(() => _isFav = v);
  }

  Future<void> _toggleFavorite() async {
    if (_isFav) {
      await _favStore.remove(widget.market, widget.item.code);
    } else {
      await _favStore.add(widget.market, widget.item);
    }
    if (!mounted) return;
    setState(() => _isFav = !_isFav);
  }

  // -----------------
  // View Toggle (눈 아이콘 / rating 카드 탭 / 미싱카드 탭 공통)
  // -----------------
  void _toggleViewMode() {
    if (!mounted) return;
    setState(() => _showAdvanced = !_showAdvanced);
    debugPrint('[Toggle] showAdvanced=$_showAdvanced');
  }

  // ---------- 파싱 ----------
  double _parseDouble(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '');
    if (t == '-' || t.isEmpty) return 0.0;
    return double.tryParse(t) ?? 0.0;
  }

  void _applyToTextFields({required double price, required StockFundamentals f}) {
    final fd = _isUS ? 2 : 0;

    _priceCtrl.text = _isUS
        ? fmtUsdDecimal(price, fractionDigits: 2).replaceAll('\$', '')
        : fmtWonDecimal(price, fractionDigits: 0);

    _epsCtrl.text = _isUS
        ? fmtUsdDecimal(f.eps, fractionDigits: fd).replaceAll('\$', '')
        : fmtWonDecimal(f.eps, fractionDigits: fd);

    _bpsCtrl.text = _isUS
        ? fmtUsdDecimal(f.bps, fractionDigits: fd).replaceAll('\$', '')
        : fmtWonDecimal(f.bps, fractionDigits: fd);

    _dpsCtrl.text = _isUS
        ? fmtUsdDecimal(f.dps, fractionDigits: fd).replaceAll('\$', '')
        : fmtWonDecimal(f.dps, fractionDigits: fd);
  }

  // ---------- 저장 ----------
  void _scheduleSaveInputs() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () async {
      final inputs = StockInputs(
        eps: _parseDouble(_epsCtrl),
        bps: _parseDouble(_bpsCtrl),
        dps: _parseDouble(_dpsCtrl),
        rPct: rPct,
      );
      await _inputStore.save(_storeKey, inputs);
    });
  }

  void _onAnyInputChanged() {
    setState(() {}); // 즉시 재계산 UI 반영
    _scheduleSaveInputs();
  }

  Future<void> _resetToInitial() async {
    await _inputStore.remove(_storeKey);
    if (!mounted) return;
    setState(() {
      rPct = _initR;
      _applyToTextFields(price: _initPrice, f: _initF);
    });
  }

  Future<void> _retryAutoValues() async {
    await _inputStore.remove(_storeKey);
    if (!mounted) return;
    await _load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("값을 다시 불러왔습니다.")),
    );
  }

  // ---------- Load ----------
  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _stage = '';
    });

    final code = widget.item.code;

    double price = 0.0;
    StockFundamentals f = const StockFundamentals(eps: 0, bps: 0, dps: 0);

    String? nextPriceBasDt;
    int? nextUsedFinanceYear;

    try {
      // 1) 가격
      _setStage('가격 조회 시작');
      Future<void> loadPrice() async {
        try {
          final quote = await widget.hub
              .getPriceQuote(widget.market, code)
              .timeout(const Duration(seconds: 8), onTimeout: () {
            throw Exception('가격 조회 타임아웃(8s)');
          });

          price = quote.price;
          nextPriceBasDt = quote.basDt;
        } catch (e, st) {
          debugPrint('[ResultPage] price fail: $e\n$st');
          price = 0.0;
          nextPriceBasDt = null;
        }
      }

      // 2) 재무
      _setStage('재무(EPS/BPS/DPS) 조회 시작');
      Future<void> loadFunda() async {
        try {
          f = await widget.hub
              .getFundamentals(widget.market, code, targetYear: null)
              .timeout(const Duration(seconds: 12), onTimeout: () {
            throw Exception('재무 조회 타임아웃(12s)');
          });

          nextUsedFinanceYear = f.year;
        } catch (e, st) {
          debugPrint('[ResultPage] fundamentals fail: $e\n$st');
          f = const StockFundamentals(eps: 0, bps: 0, dps: 0);
          nextUsedFinanceYear = null;
        }
      }

      // 병렬
      await Future.wait([loadPrice(), loadFunda()]);

      // 3) 초기값 반영
      _setStage('초기값 반영');
      _initPrice = price;
      _initF = f;
      _initR = 9.0;
      rPct = _initR;

      _applyToTextFields(price: price, f: f);

      // 4) 저장값 복원
      _setStage('저장값 복원');
      final saved = await _inputStore.load(_storeKey).timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      final fd = _isUS ? 2 : 0;

      if (saved != null) {
        if (saved.eps != 0) {
          _epsCtrl.text = _isUS
              ? fmtUsdDecimal(saved.eps, fractionDigits: fd).replaceAll('\$', '')
              : fmtWonDecimal(saved.eps, fractionDigits: fd);
        }

        if (saved.bps != 0) {
          _bpsCtrl.text = _isUS
              ? fmtUsdDecimal(saved.bps, fractionDigits: fd).replaceAll('\$', '')
              : fmtWonDecimal(saved.bps, fractionDigits: fd);
        }

        // DPS=0은 무배당일 수 있어 기존정책 유지 (0이면 덮어쓰기 안 함)
        if (saved.dps != 0) {
          _dpsCtrl.text = _isUS
              ? fmtUsdDecimal(saved.dps, fractionDigits: fd).replaceAll('\$', '')
              : fmtWonDecimal(saved.dps, fractionDigits: fd);
        }

        rPct = saved.rPct;
      }

      if (!mounted) return;

      _setStage('완료');

      setState(() {
        _priceBasDt = nextPriceBasDt;
        _usedFinanceYear = nextUsedFinanceYear;
        _fundamentals = f;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('[ResultPage] load fail (outer): $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------- Naver ----------
  Future<void> _openNaverFinanceForCurrent() async {
    final ok = await _link.openNaverFinance(rawCodeOrTicker: widget.item.code);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버 페이지를 열 수 없습니다.')),
      );
      return;
    }

    if (mounted && _isUS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해외는 네이버 해외주식에서 티커로 검색해서 확인하세요.')),
      );
    }
  }

  // ---------- Header / Meta ----------
  String _fmtBasDt(String yyyymmdd) {
    final s = yyyymmdd.trim();
    if (s.length != 8) return s;
    return "${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}";
  }

  String? _metricLabel() {
    final f = _fundamentals ?? _initF;

    final pl = f.periodLabel?.trim();
    if (pl != null && pl.isNotEmpty && pl != 'TTM') {
      return '재무 기준: $pl';
    }

    final bd = f.basDt?.trim();
    if (bd != null && bd.isNotEmpty) {
      return '재무 기준일: ${_fmtBasDt(bd)}';
    }

    if (f.year != null) {
      return '재무 기준: ${f.year}년';
    }

    return null;
  }

  Widget _metricHint(String? s) {
    if (s == null || s.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        s,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }

  // ---------- Rating UI ----------
  IconData _ratingIcon(RatingLevel level) {
    switch (level) {
      case RatingLevel.strongBuy:
        return Icons.local_fire_department;
      case RatingLevel.buy:
        return Icons.trending_up;
      case RatingLevel.neutral:
        return Icons.remove_circle_outline;
      case RatingLevel.caution:
        return Icons.warning_amber;
      case RatingLevel.avoid:
        return Icons.block;
    }
  }

  Color _ratingColor(RatingLevel level) {
    switch (level) {
      case RatingLevel.strongBuy:
        return Colors.green;
      case RatingLevel.buy:
        return Colors.lightGreen;
      case RatingLevel.neutral:
        return Colors.blueGrey;
      case RatingLevel.caution:
        return Colors.orange;
      case RatingLevel.avoid:
        return Colors.red;
    }
  }

  Color get _accent => _isUS ? Colors.blue : Colors.green;
  Color get _cHeader => _isUS ? Colors.indigo : Colors.teal;
  Color get _cInput => _isUS ? Colors.blue : Colors.green;
  Color get _cResult => _isUS ? Colors.purple : Colors.deepPurple;
  Color get _cKpi => _isUS ? Colors.cyan : Colors.lightBlue;
  Color get _cInfo => _isUS ? Colors.orange : Colors.amber;

  BoxDecoration _cardDeco(Color c) => BoxDecoration(
        color: c.withAlpha(16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withAlpha(55)),
      );

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    debugPrint('[ResultPage] build loading=$_loading error=$_error');
    final name = widget.item.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("$name 평가"),
        backgroundColor: _accent.withAlpha(18),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.star : Icons.star_border,
              color: _isFav ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite, // ✅ 즐겨찾기
          ),
          IconButton(
            tooltip: _showAdvanced ? "고급보기 숨기기" : "고급보기 보기",
            icon: Icon(_showAdvanced ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleViewMode, // ✅ 눈 아이콘 = 토글
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _openNaverFinanceForCurrent,
              style: TextButton.styleFrom(foregroundColor: _accent),
              label: Text(widget.market == Market.kr ? 'N증권' : 'N해외검색'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_stage.isEmpty ? '로딩 중...' : _stage),
                ],
              ),
            )
          : (_error != null ? _errorView() : _bodyView()),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("불러오기 실패: $_error", style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text("다시 시도")),
        ],
      ),
    );
  }

  Widget _bodyView() {
    final name = widget.item.name;
    final code = widget.item.code;

    // 입력값
    final price = _parseDouble(_priceCtrl);
    final eps = _parseDouble(_epsCtrl);
    final bps = _parseDouble(_bpsCtrl);
    final dps = _parseDouble(_dpsCtrl);

    // 계산
    ValuationResult? result;
    String? calcError;

    try {
      result = ValuationService.evaluate(
        ValuationInput(
          price: price,
          eps: eps,
          bps: bps,
          dps: dps,
          rPct: rPct,
        ),
      );
    } catch (e) {
      calcError = e.toString();
    }

    // 5단계 요약
    ValuationRating? rating;
    if (calcError == null && result != null) {
      rating = ValuationService.interpret5(result, rPct);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _headerCard(name, code),
        const SizedBox(height: 8),

        // ✅ rating 카드 탭도 눈 아이콘과 동일 동작
        if (rating != null) ...[
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _toggleViewMode,
            child: _showAdvanced ? _ratingCardCompact(rating) : _ratingCardLarge(rating),
          ),
          const SizedBox(height: 8),
        ],

        // ✅ 미싱일 때만 카드 존재 + 탭=눈아이콘
        _missingDataHintCard(),
        const SizedBox(height: 8),

        _inputCard(),
        const SizedBox(height: 8),

        _resultCard(currentPrice: price, result: result, calcError: calcError),
        const SizedBox(height: 8),

        _sellGuideCard(result: result, calcError: calcError),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _headerCard(String name, String code) {
    final marketText = (widget.market == Market.kr) ? "KR" : "US";
    final f = _fundamentals ?? _initF;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: _cardDeco(_cHeader),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: _cHeader.withAlpha(170), width: 4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$name ($code) · $marketText",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  (widget.market == Market.kr)
                      ? "데이터 출처: 한국투자증권(KIS) 실시간 시세 + OpenDART 재무"
                      : "데이터 출처: FMP (Financial Modeling Prep)",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                if (f.basDt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "재무 기준일: ${_fmtBasDt(f.basDt!)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (_priceBasDt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "가격 기준일: ${_fmtBasDt(_priceBasDt!)}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _openFinancialStatementPage,
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text("재무제표 보기"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ 미싱일 때만 나오고, 탭하면 토글(눈 아이콘과 동일)
  Widget _missingDataHintCard() {
    final eps = _parseDouble(_epsCtrl);
    final bps = _parseDouble(_bpsCtrl);
    final dps = _parseDouble(_dpsCtrl);

    final missing = <String>[];
    if (eps == 0) missing.add("EPS");
    if (bps == 0) missing.add("BPS");

    if (missing.isEmpty) return const SizedBox.shrink();

    final usedYear = _usedFinanceYear ?? _targetFinanceYear;
    final fellBack = (_usedFinanceYear != null) && (_usedFinanceYear != _targetFinanceYear);
    final dpsZero = (dps == 0);

    // ✅ 고급(true)=간단, 초급(false)=자세히
    final showDetail = !_showAdvanced;

    final brief = "EPS/BPS 자동값이 비어 있습니다. (탭하면 보기 전환)";
    final detail = (widget.market == Market.kr)
        ? "현재 앱은 이번 계산에 $usedYear년 재무를 사용했습니다.\n"
            "$usedYear년 재무가 미공개/승인대기/갱신 전인 종목은 EPS/BPS가 0으로 표시될 수 있어요.\n"
            "${fellBack ? "※ $_targetFinanceYear 값이 부족해 $usedYear로 자동 전환했습니다.\n" : ""}"
            "${dpsZero ? "※ DPS=0은 무배당이거나(정상), 배당 데이터 미제공일 수 있어요.\n" : ""}"
            "값을 직접 입력하면 즉시 재계산됩니다."
        : "해당 값은 공시/배당 반영 타이밍 또는 API 제공 범위에 따라 비어 있을 수 있어요.\n"
            "${dpsZero ? "※ DPS=0은 무배당(정상) 또는 데이터 미제공일 수 있어요.\n" : ""}"
            "값을 직접 입력하면 즉시 재계산됩니다.";

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _toggleViewMode,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange.withAlpha(30),
                child: const Icon(Icons.info_outline, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "데이터 미제공/계산불가: ${missing.join(', ')}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Icon(
                          showDetail ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      showDetail ? detail : brief,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (showDetail) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _retryAutoValues,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("값 자동 재시도(새로고침)"),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard() {
    final priceFormatter = _isUS ? _priceFormatterUs : _priceFormatterKr;

    return Card(
      color: _cInput.withAlpha(14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _cInput.withAlpha(55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cInput.withAlpha(35)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text("입력값", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  TextButton(
                    onPressed: _resetToInitial,
                    style: TextButton.styleFrom(foregroundColor: _cInput),
                    child: const Text("초기화"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (_parseDouble(_priceCtrl) == 0.0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(60)),
                ),
                child: const Text(
                  "현재가 데이터를 가져오지 못했습니다. 직접 입력해도 계산은 가능합니다.",
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),

            const SizedBox(height: 10),

            // Price
            LabeledNumberField(
              label: _priceUnitText,
              controller: _priceCtrl,
              onChanged: (_) => _onAnyInputChanged(),
              inputFormatters: [priceFormatter],
              hintText: "직접 입력 가능",
            ),

            const SizedBox(height: 8),

            // EPS/BPS/DPS
            MetricFieldWithBadge(
              isUS: _isUS,
              label: "EPS",
              controller: _epsCtrl,
              onChanged: (_) => _onAnyInputChanged(),
            ),
            const SizedBox(height: 8),

            MetricFieldWithBadge(
              isUS: _isUS,
              label: "BPS",
              controller: _bpsCtrl,
              onChanged: (_) => _onAnyInputChanged(),
            ),
            const SizedBox(height: 8),

            MetricFieldWithBadge(
              isUS: _isUS,
              label: "DPS",
              controller: _dpsCtrl,
              onChanged: (_) => _onAnyInputChanged(),
            ),

            // ✅ 재무 기준 힌트는 1번만
            _metricHint(_metricLabel()),

            const SizedBox(height: 14),
            const Text("요구수익률 r(%)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("r = ${rPct.toStringAsFixed(1)}%"),
                const Text("(ROE/r로 적정 PBR 결정)", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _accent.withAlpha(200),
                inactiveTrackColor: _accent.withAlpha(60),
                thumbColor: _accent.withAlpha(220),
                overlayColor: _accent.withAlpha(30),
                valueIndicatorColor: _accent.withAlpha(220),
              ),
              child: Slider(
                value: rPct,
                min: 5,
                max: 20,
                divisions: 150,
                label: "${rPct.toStringAsFixed(1)}%",
                onChanged: (v) {
                  setState(() => rPct = v);
                  _scheduleSaveInputs();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 고급 작은카드
  Widget _ratingCardCompact(ValuationRating rating) {
    final a = rating.accent ?? _ratingColor(rating.level);
    final bg = rating.bg ?? a.withAlpha(6);
    final br = rating.border ?? a.withAlpha(60);

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: br),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: a.withAlpha(30),
              child: Icon(_ratingIcon(rating.level), color: a),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rating.title, style: TextStyle(fontWeight: FontWeight.bold, color: a)),
                  const SizedBox(height: 2),
                  Text(rating.summary, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 초급 큰카드
  Widget _ratingCardLarge(ValuationRating rating) {
    final a = rating.accent ?? _ratingColor(rating.level);
    final bg = rating.bg ?? a.withAlpha(14);
    final br = rating.border ?? a.withAlpha(60);

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: br),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: a.withAlpha(170), width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: a.withAlpha(30),
                    child: Icon(_ratingIcon(rating.level), color: a),
                  ),
                  const SizedBox(width: 10),
                  Text(rating.title, style: TextStyle(fontWeight: FontWeight.w800, color: a)),
                ],
              ),
              const SizedBox(height: 10),
              Text(rating.summary),
              const SizedBox(height: 10),
              ...rating.bullets.map(
                (b) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: a.withAlpha(10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: a.withAlpha(30)),
                  ),
                  child: Text(b),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard({
    required double currentPrice,
    required ValuationResult? result,
    required String? calcError,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: (calcError != null || result == null)
            ? Text(
                "계산 불가: ${calcError ?? "데이터가 부족합니다."}",
                style: const TextStyle(color: Colors.red),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("결과", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // 초보 모드
                  if (!_showAdvanced) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _kpiBox(
                            title: "적정주가",
                            value: _fmtMoney(result.fairPrice),
                            subtitle: "BPS × (ROE / r)",
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _kpiBox(
                            title: "기대수익률(%)",
                            value:
                                "${result.expectedReturnPct >= 0 ? '+' : ''}${result.expectedReturnPct.toStringAsFixed(1)}%",
                            valueColor: result.expectedReturnPct >= 0 ? Colors.green : Colors.red,
                            subtitle: "적정가까지 상승 여지",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _priceFairGauge(price: currentPrice, fairPrice: result.fairPrice),
                    const SizedBox(height: 10),
                    Text(
                      "현황평가: ${result.gapPct.toStringAsFixed(1)}%  (100% 미만이면 저평가 쪽)",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "※ 상단 눈 아이콘을 켜면 ROE, 배당수익률, PER/PBR 등 상세 지표를 볼 수 있어요.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],

                  // 고급 모드
                  if (_showAdvanced) ...[
                    _sectionCard("가치(Valuation)", [
                      _metricTile(
                        label: "적정주가",
                        value: _fmtMoney(result.fairPrice),
                        helper: "BPS × (ROE / r)",
                        icon: Icons.price_check,
                      ),
                      _metricTile(
                        label: "현황평가(현재/적정)",
                        value: "${result.gapPct.toStringAsFixed(1)}%",
                        helper: "100% 미만이면 저평가 쪽",
                        icon: Icons.bar_chart,
                      ),
                      _metricTile(
                        label: "기대수익률",
                        value:
                            "${result.expectedReturnPct >= 0 ? '+' : ''}${result.expectedReturnPct.toStringAsFixed(1)}%",
                        helper: "적정가까지 상승 여지",
                        icon: Icons.trending_up,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _sectionCard("수익성(Profitability)", [
                      _metricTile(
                        label: "ROE",
                        value: "${result.roePct.toStringAsFixed(2)}%",
                        helper: "EPS / BPS",
                        icon: Icons.flash_on,
                      ),
                      _metricTile(
                        label: "ROE / r",
                        value: result.roeOverR.toStringAsFixed(2),
                        helper: "1.0 이상이면 r 충족",
                        icon: Icons.functions,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _sectionCard("배당(Dividend)", [
                      _metricTile(
                        label: "배당수익률",
                        value: "${result.dividendYieldPct.toStringAsFixed(2)}%",
                        helper: "DPS / 현재가",
                        icon: Icons.savings,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _sectionCard("멀티플(Multiples)", [
                      _metricTile(label: "PER", value: result.per.toStringAsFixed(2), icon: Icons.calculate),
                      _metricTile(label: "PBR", value: result.pbr.toStringAsFixed(2), icon: Icons.assessment),
                    ]),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _kpiBox({
    required String title,
    required String value,
    Color? valueColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cKpi.withAlpha(12),
        border: Border.all(color: _cKpi.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _priceFairGauge({required double price, required double fairPrice}) {
    if (price <= 0 || fairPrice <= 0) {
      return const SizedBox.shrink();
    }

    final ratio = price / fairPrice;
    final pct = ratio * 100.0;

    final clamped = ratio.clamp(0.0, 2.0);
    final fill = clamped / 2.0;

    final isUndervalued = ratio <= 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cInfo.withAlpha(12),
        border: Border.all(color: _cInfo.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("현재가 / 적정주가: ${pct.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final fillW = w * fill;
              final fairX = w * 0.5;

              return SizedBox(
                height: 14,
                child: Stack(
                  children: [
                    Container(
                      width: w,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      width: fillW,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isUndervalued ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Positioned(
                      left: fairX - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("0%", style: TextStyle(fontSize: 12)),
              Text("100%(적정)", style: TextStyle(fontSize: 12)),
              Text("200%", style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("현재가: ${_fmtMoney(price)}", style: const TextStyle(fontSize: 12)),
              Text("적정가: ${_fmtMoney(fairPrice)}", style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      color: _cResult.withAlpha(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _cResult.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _cResult.withAlpha(180),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    String? helper,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(helper, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ==========================
  // Sell Guide
  // ==========================
  Widget _sellGuideCard({
    required ValuationResult? result,
    required String? calcError,
  }) {
    if (calcError != null || result == null) return const SizedBox.shrink();

    final gap = result.gapPct;
    final over = gap >= 130;
    final under = gap <= 90;

    String title;
    String subtitle;
    IconData icon;
    Color c;

    if (over) {
      title = "보유/매도 점검(참고) · 과열 주의";
      subtitle =
          "현재가가 적정가 대비 ${gap.toStringAsFixed(0)}% 높습니다. 내재가치보다 비싼 구간이니, 수익을 확정할지 아니면 기업의 초과 성장을 더 믿고 기다릴지 결정이 필요한 시점입니다.";
      icon = Icons.warning_amber;
      c = Colors.orange;
    } else if (under) {
      title = "보유/매도 점검(참고) · 안전마진 유효";
      subtitle =
          "현재가가 적정가 대비 ${gap.toStringAsFixed(0)}% 낮아 안전마진이 충분합니다. 시세 흔들림에 불안해하기보다, 기업의 이익 성장세와 사업의 본질이 변하지 않았는지 확인하며 보유하세요.";
      icon = Icons.fact_check;
      c = Colors.blueGrey;
    } else {
      title = "보유/매도 점검(참고) · 가치 부합";
      subtitle =
          "현재 주가가 기업의 내재가치에 근접했습니다. 이제부터는 가격의 싸고 비쌈을 따지기보다, 기업의 '해자(경쟁력)'나 '경영진의 태도' 등 질적인 변화를 더 세밀하게 관찰해야 합니다.";
      icon = Icons.checklist;
      c = Colors.indigo;
    }

    return Card(
      elevation: 0,
      color: c.withAlpha(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openSellGuideSheet(gapPct: gap),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: c.withAlpha(24),
                child: Icon(icon, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: c)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => _openSellGuideSheet(gapPct: gap),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text("체크리스트 보기"),
                      ),
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

  void _openSellGuideSheet({required double gapPct}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SellGuideSheet(
          gapPct: gapPct,
          onClose: () => Navigator.pop(ctx),
        );
      },
    );
  }

  // 재무제표 페이지 이동
  void _openFinancialStatementPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinancialStatementPage(
          hub: widget.hub,
          market: widget.market,
          item: widget.item,
          initialFundamentals: _fundamentals,
        ),
      ),
    );
  }
}