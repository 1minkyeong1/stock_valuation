import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/market.dart';
import '../data/repo_hub.dart';
import '../data/stock_repository.dart';

import '../data/favorites_store.dart';
import '../data/stock_input_store.dart';

import '../models/valuation_result.dart';
import '../models/valuation_rating.dart';
import '../services/valuation_service.dart';

import '../widgets/ad_banner.dart';
import '../utils/finance_rules.dart';
import '../utils/number_format.dart';

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
  // 재무는 2025년만 사용(없으면 2024 fallback)
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

  // 고급보기 토글용
  bool _showAdvanced = true;

  String get _storeKey => "${widget.market.name}:${widget.item.code}";

  late final TextInputFormatter _priceFormatterKr;
  late final TextInputFormatter _priceFormatterUs;

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
// 디버깅    
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

  Widget _metricHint(String? s) {
    if (s == null || s.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        s,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }


  Future<void> _loadFavState() async {
    final v = await _favStore.isFavorite(widget.market, widget.item.code);
    if (!mounted) return;
    setState(() => _isFav = v);
  }

  String _stage = '';
    void _setStage(String s) {
      if (!mounted) return;
      setState(() => _stage = s);
      debugPrint('[ResultPage][STAGE] $s');
    }

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
      // =========================
      // 1) 가격 + 기준일(KR만)
      // =========================
      _setStage('가격 조회 시작');

      Future<void> loadPrice() async {
        try {
          final quote = await widget.hub
              .getPriceQuote(widget.market, code)
              .timeout(const Duration(seconds: 8), onTimeout: () {
            throw Exception('가격 조회 타임아웃(8s)');
          });

          price = quote.price;          // ✅ PriceQuote.price가 double이면 그대로
          nextPriceBasDt = quote.basDt; // ✅ KR이면 날짜, US면 null 가능
        } catch (e, st) {
          debugPrint('[ResultPage] price fail: $e\n$st');
          price = 0.0;
          nextPriceBasDt = null;
        }
      }

      // =========================
      // 2) EPS/BPS/DPS
      // =========================
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

      // ✅ 핵심: 두 개를 직렬로 하지 말고 병렬로
      await Future.wait([loadPrice(), loadFunda()]);

      // =========================
      // 3) 초기값 저장 + 텍스트필드 반영
      // =========================
      _setStage('초기값 반영');

      _initPrice = price;
      _initF = f;
      _initR = 9.0;
      rPct = _initR;

      _applyToTextFields(price: price, f: f);

      // =========================
      // 4) 저장값 복원(있으면 덮어쓰기)
      // =========================
      _setStage('저장값 복원');

      final saved = await _inputStore
          .load(_storeKey)
          .timeout(const Duration(seconds: 3), onTimeout: () {
        // 저장소가 느리면 UI를 막지 않도록
        return null;
      });

      final isUS = widget.market == Market.us;
      final fd = isUS ? 2 : 0;

      if (saved != null) {
        // ✅ 저장값이 "의미 있는 값"일 때만 덮어쓰기
        if (saved.eps != 0) {
         _epsCtrl.text = isUS
             ? fmtUsdDecimal(saved.eps, fractionDigits: fd).replaceAll('\$', '')
             : fmtWonDecimal(saved.eps, fractionDigits: fd);
        }

        if (saved.bps != 0) {
          _bpsCtrl.text = isUS
              ? fmtUsdDecimal(saved.bps, fractionDigits: fd).replaceAll('\$', '')
              : fmtWonDecimal(saved.bps, fractionDigits: fd);
        }

        // DPS는 0이 무배당일 수 있으니 기존 정책 유지(0이면 덮어쓰기 안 함)
        if (saved.dps != 0) {
          _dpsCtrl.text = isUS
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

  void _applyToTextFields({required double price, required StockFundamentals f}) {
    final isUS = widget.market == Market.us;
    final fd = isUS ? 2 : 0;

    _priceCtrl.text = isUS
        ? fmtUsdDecimal(price, fractionDigits: 2).replaceAll('\$', '')
        : fmtWonDecimal(price, fractionDigits: 0);

    _epsCtrl.text = isUS
        ? fmtUsdDecimal(f.eps, fractionDigits: fd).replaceAll('\$', '')
        : fmtWonDecimal(f.eps, fractionDigits: fd);

    _bpsCtrl.text = isUS
        ? fmtUsdDecimal(f.bps, fractionDigits: fd).replaceAll('\$', '')
        : fmtWonDecimal(f.bps, fractionDigits: fd);

    _dpsCtrl.text = isUS
        ? fmtUsdDecimal(f.dps, fractionDigits: fd).replaceAll('\$', '')
        : fmtWonDecimal(f.dps, fractionDigits: fd);
  }

  // ---------- 파싱 ----------
  double _parseDouble(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '');
    return double.tryParse(t) ?? 0.0;
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
    setState(() {});
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

  Future<void> _toggleFavorite() async {
    if (_isFav) {
      await _favStore.remove(widget.market, widget.item.code);
    } else {
      await _favStore.add(widget.market, widget.item);
    }
    if (!mounted) return;
    setState(() => _isFav = !_isFav);
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    //디버깅
    debugPrint('[ResultPage] build loading=$_loading error=$_error');
    final name = widget.item.name;

    return Scaffold(
      appBar: AppBar(
        title: Text("$name 평가"),
        actions: [
          IconButton(
            icon: Icon(_isFav ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            tooltip: _showAdvanced ? "고급보기 숨기기" : "고급보기 보기",
            icon: Icon(_showAdvanced ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
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

    // 입력값(텍스트필드 기반)
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

         if (rating != null) ...[
          _showAdvanced ? _ratingCardCompact(rating) : _ratingCardLarge(rating),
          const SizedBox(height: 8),
        ],

        _missingDataHintCard(),
        const SizedBox(height: 8),

        _inputCard(),
        const SizedBox(height: 8),

        _resultCard(currentPrice: price, result: result, calcError: calcError),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _headerCard(String name, String code) {
    final marketText = (widget.market == Market.kr) ? "KR" : "US";

    final f = _fundamentals ?? _initF;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$name ($code) · $marketText",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 6),
              Text(
                "가격 기준일: ${_fmtBasDt(_priceBasDt!)}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtBasDt(String yyyymmdd) {
    final s = yyyymmdd.trim();
    if (s.length != 8) return s;
    return "${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}";
  }

  String? _metricLabelFor(String metric) {
    // 1) fundamentals 우선
    final f = _fundamentals ?? _initF;

    // periodLabel이 있으면 그게 최우선 (예: "2025 Q3", "2025 FY", "TTM")
    final pl = f.periodLabel?.trim();
    if (pl != null && pl.isNotEmpty && pl != 'TTM') {
      return '기준: $pl';
    }

    // basDt가 있으면 날짜 기준 표시
    final bd = f.basDt?.trim();
    if (bd != null && bd.isNotEmpty) {
      return '기준일: ${_fmtBasDt(bd)}';
    }

    // year만 있으면 연도 기준 표시
    if (f.year != null) {
      return '기준: ${f.year}년';
    }

    // 그래도 없으면 (디버그 로그처럼 meta null) 표시 생략
    return null;
  }

  // --------------------------
  // ✅ 자동값 없음 / 적자 뱃지
  // - 0  : 자동값 없음
  // - <0 : 적자(EPS만)
  // --------------------------
 // 자동 값 없음 (0일 때만)
  Widget _autoMissingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(25),
        border: Border.all(color: Colors.orange.withAlpha(120)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "자동값 없음",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange),
      ),
    );
  }

  // EPS 적자 배지 (EPS < 0 일 때만)
  Widget _lossBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(25),
        border: Border.all(color: Colors.red.withAlpha(120)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        "적자(EPS<0)",
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red),
      ),
    );
  }

  // EPS/BPS/DPS 전용 “라벨+배지+텍스트필드” 위젯
  Widget _numFieldWithAutoBadge({
    required String label,
    required TextEditingController controller,
    required void Function(String) onChanged,
  }) {
    final v = controller.text.trim().replaceAll(',', '');
    final val = double.tryParse(v) ?? 0;

    final up = label.trim().toUpperCase();
    final isEps = up == "EPS";
    final isDps = up == "DPS";

    // ✅ 규칙
    final showLoss = isEps && FinanceRules.isLossEps(val); // EPS<0 = 적자

    // ✅ DPS는 0이 “무배당”일 수 있으므로 showMissing 처리 분리
    final showMissing = !isDps && FinanceRules.isMissing(val); // EPS/BPS만 0 => 자동값 없음
    final showDpsZero = isDps && (val == 0);                   // DPS=0 => 무배당/데이터없음

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            if (showLoss)
              _lossBadge()
            else if (showMissing)
              _autoMissingBadge()
            else if (showDpsZero)
              _dpsZeroBadge(), // ✅ 새 배지
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            // KR: 정수+콤마, US: 소수 허용
            widget.market == Market.us
                ? MoneyInputFormatter(allowDecimal: true, decimalDigits: 2)
                : MoneyInputFormatter(allowDecimal: false),
          ],
          decoration: const InputDecoration(
            hintText: "직접 입력 가능",
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ✅ 새 배지: DPS=0 전용(무배당/데이터없음)
  Widget _dpsZeroBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.withAlpha(80)),
      ),
      child: const Text(
        "무배당/데이터없음",
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blue),
      ),
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController controller,
    required void Function(String) onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: inputFormatters,
          decoration: const InputDecoration(
            hintText: "직접 입력 가능",
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _missingDataHintCard() {
    final eps = _parseDouble(_epsCtrl);
    final bps = _parseDouble(_bpsCtrl);
    final dps = _parseDouble(_dpsCtrl);

    final missing = <String>[];

    // ✅ EPS: 0만 “자동값 없음”. 음수는 적자(데이터 존재)
    if (eps == 0) missing.add("EPS");
    if (bps == 0) missing.add("BPS");
    //if (dps == 0) missing.add("DPS");

    if (missing.isEmpty) return const SizedBox.shrink();

    final usedYear = _usedFinanceYear ?? _targetFinanceYear;
    final fellBack = (_usedFinanceYear != null) && (_usedFinanceYear != _targetFinanceYear);
    final dpsZero = (dps == 0);

    return Card(
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
                  Text(
                    "데이터 미제공/계산불가: ${missing.join(', ')}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // ✅ 핵심: 2025 재무만 조회한다는 점을 명확히 안내
                  Text(
                     (widget.market == Market.kr)
                        ? "현재 앱은 이번 계산에 $usedYear년 재무를 사용했습니다.\n"
                          "$usedYear년 재무가 미공개/승인대기/갱신 전인 종목은 EPS/BPS가 0으로 표시될 수 있어요.\n"
                          "${fellBack ? "※ $_targetFinanceYear 값이 부족해 $usedYear로 자동 전환했습니다.\n" : ""}"
                          "${dpsZero ? "※ DPS=0은 무배당이거나(정상), 배당 데이터 미제공일 수 있어요.\n" : ""}"
                          "값을 직접 입력하면 즉시 재계산됩니다."
                        : "해당 값은 공시/배당 반영 타이밍 또는 API 제공 범위에 따라 비어 있을 수 있어요.\n"
                          "${dpsZero ? "※ DPS=0은 무배당(정상) 또는 데이터 미제공일 수 있어요.\n" : ""}"
                          "값을 직접 입력하면 즉시 재계산됩니다.",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 10),

                  // ✅ 자동 재시도 버튼
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _retryAutoValues,
                      icon: const Icon(Icons.refresh),
                      label: const Text("값 자동 재시도(새로고침)"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "입력값",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: _resetToInitial, child: const Text("초기화")),
              ],
            ),
            const SizedBox(height: 10),

              if (_parseDouble(_priceCtrl) == 0.0)    // -------------------변경
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "현재가 데이터를 가져오지 못했습니다. 직접 입력해도 계산은 가능합니다.",
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),

            _numField( label: _priceUnitText, controller: _priceCtrl, onChanged: (_) => _onAnyInputChanged(), inputFormatters: [widget.market == Market.us ? _priceFormatterUs : _priceFormatterKr,],),
            const SizedBox(height: 8),
            _numFieldWithAutoBadge(label: "EPS", controller: _epsCtrl, onChanged: (_) => _onAnyInputChanged()),
            _metricHint(_metricLabelFor('EPS')),
            const SizedBox(height: 8),
            _numFieldWithAutoBadge(label: "BPS", controller: _bpsCtrl, onChanged: (_) => _onAnyInputChanged()),
            _metricHint(_metricLabelFor('BPS')),
            const SizedBox(height: 8),
            _numFieldWithAutoBadge(label: "DPS", controller: _dpsCtrl, onChanged: (_) => _onAnyInputChanged()),
            _metricHint(_metricLabelFor('DPS')),

            const SizedBox(height: 14),
            const Text("요구수익률 r(%)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("r = ${rPct.toStringAsFixed(1)}%"),
                Text("(ROE/r로 적정 PBR 결정)", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Slider(
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
          ],
        ),
      ),
    );
  }

  // 아래 2개는 기존 프로젝트에 이미 있는 형태일 가능성이 높아서
  // "변수명 유지" 조건을 위해 최소 형태로만 제공합니다.
  // (원래 쓰던 UI가 있으면 그대로 붙여쓰셔도 됩니다.)

  Widget _ratingCardCompact(ValuationRating rating) {
    final c = _ratingColor(rating.level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: c.withAlpha(30),
              child: Icon(_ratingIcon(rating.level), color: c),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rating.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(rating.summary, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingCardLarge(ValuationRating rating) {
    final c = _ratingColor(rating.level);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: c.withAlpha(30),
                  child: Icon(_ratingIcon(rating.level), color: c),
                ),
                const SizedBox(width: 10),
                Text(rating.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Text(rating.summary),
            const SizedBox(height: 10),
            ...rating.bullets.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(b),
                )),
          ],
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

                  // ✅ 초보 모드(눈 아이콘 OFF 상태라고 보면 됨)
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

                  // ✅ 고급 모드(눈 아이콘 ON)
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

  // us 함수
bool get _isUS => widget.market == Market.us;

// 표시용(원하면 유지, UI 라벨에만 사용)
String get _priceUnitText  => _isUS ? r'현재가($)' : '현재가(원)';

// ✅ 결과/요약 표시용 포맷 (콤마/단위 일관성)
String _fmtMoney(num v) {
  if (_isUS) {
    return fmtUsd(v); // number_format.dart
  } else {
    return fmtWon(v); // number_format.dart
  }
}

  // 초보모드에서 사용
  Widget _kpiBox({
    required String title,
    required String value,
    Color? valueColor,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
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
              color: valueColor,
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

  // (하단) 초보 막대그래프 표시
  Widget _priceFairGauge({required double price, required double fairPrice}) {
    if (price <= 0 || fairPrice <= 0) {
      return const SizedBox.shrink();
    }

    final ratio = price / fairPrice; // 1.0 이면 적정가
    final pct = ratio * 100.0;

    // 바 길이(최대 200%까지만 표시)
    final clamped = ratio.clamp(0.0, 2.0);
    final fill = clamped / 2.0; // 0.0~1.0

    final isUndervalued = ratio <= 1.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "현재가 / 적정주가: ${pct.toStringAsFixed(1)}%",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // 게이지 바 (0% ~ 200%)
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final fillW = w * fill;

              // 100% 위치(적정가 위치)
              final fairX = w * 0.5;

              return SizedBox(
                height: 14,
                child: Stack(
                  children: [
                    // 배경
                    Container(
                      width: w,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    // 채움(현재가 위치)
                    Container(
                      width: fillW,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isUndervalued ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),

                    // 100% 마커(적정가)
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

          // 숫자 안내
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

  // (하단) 고급용 설명 UI
  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
}

class MoneyInputFormatter extends TextInputFormatter {
  final bool allowDecimal;
  final int decimalDigits;

  MoneyInputFormatter({
    required this.allowDecimal,
    this.decimalDigits = 2,
  });

  static String _withComma(String s) {
    // s는 정수 문자열(부호 없음)만 들어오는 형태로 처리
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;

    // 비어있으면 그대로
    if (raw.isEmpty) return newValue;

    // 콤마 제거
    var t = raw.replaceAll(',', '');

    // 숫자/소수점 외 제거
    if (allowDecimal) {
      t = t.replaceAll(RegExp(r'[^0-9.]'), '');
      // 점이 여러개면 첫 점만 남기기
      final firstDot = t.indexOf('.');
      if (firstDot != -1) {
        final before = t.substring(0, firstDot + 1);
        final after = t.substring(firstDot + 1).replaceAll('.', '');
        t = before + after;
      }
      // 소수 자릿수 제한
      if (firstDot != -1) {
        final parts = t.split('.');
        final intPart = parts[0];
        final decPart = (parts.length > 1) ? parts[1] : '';
        final trimmedDec = decPart.length > decimalDigits ? decPart.substring(0, decimalDigits) : decPart;
        t = '$intPart.$trimmedDec';
      }
    } else {
      t = t.replaceAll(RegExp(r'[^0-9]'), '');
    }

    if (t.isEmpty) return const TextEditingValue(text: '');

    // 정수/소수 분리 후 정수부 콤마
    String formatted;
    if (allowDecimal && t.contains('.')) {
      final parts = t.split('.');
      final intPart = parts[0].isEmpty ? '0' : parts[0];
      final decPart = parts.length > 1 ? parts[1] : '';
      formatted = '${_withComma(intPart)}.$decPart';
    } else {
      formatted = _withComma(t);
    }

    // 커서 위치: 끝으로 보내는 단순 방식(가장 안정적)
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
  
}


