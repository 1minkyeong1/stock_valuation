import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

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

import 'package:stock_valuation_app/widgets/inputs/labeled_number_field.dart';
import 'package:stock_valuation_app/widgets/inputs/metric_field_with_badge.dart';
import 'package:stock_valuation_app/services/external_link_service.dart';
import 'package:stock_valuation_app/utils/money_input_formatter.dart';
import 'package:stock_valuation_app/pages/financial_statement_page.dart';
import 'package:stock_valuation_app/pages/search_page.dart';
import 'package:stock_valuation_app/utils/search_alias.dart';
import 'package:stock_valuation_app/services/result_pdf_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_valuation_app/l10n/app_localizations.dart';
import 'package:stock_valuation_app/copy/result_copy.dart';
import 'package:stock_valuation_app/widgets/result/price_fib_chart_card.dart';
import 'package:stock_valuation_app/widgets/result/result_explanation_card.dart';
import 'package:stock_valuation_app/widgets/common/mini_help_tip.dart';

class ResultPage extends StatefulWidget {
  final RepoHub hub;
  final StockSearchItem item;
  final Market market;

  // 랭킹에서 넘어온 스냅샷 값
  final bool useRankingSnapshot;
  final double? rankingPrice;
  final double? rankingEps;
  final double? rankingBps;
  final double? rankingDps;
  final double? rankingRPct;
  final double? initialRequiredReturnPct;

  const ResultPage({
    super.key,
    required this.hub,
    required this.item,
    required this.market,
    this.useRankingSnapshot = false,
    this.rankingPrice,
    this.rankingEps,
    this.rankingBps,
    this.rankingDps,
    this.rankingRPct,
    this.initialRequiredReturnPct,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {

  // 피보나치 모델과 차트 변수
  StockFundamentals? _fundamentals;
  PriceFibChartData? _priceFibChart;
  
  // 피보나치 바텀시트로 보여주기
   int _priceFibMonths = 36;
   bool _priceFibLoading = false;


  AppLocalizations get t => AppLocalizations.of(context)!;
  bool get isKoLang => ResultCopy.isKo(context);

  // 상태
  bool _loading = true;
  String? _error;

  String? _priceBasDt; // yyyymmdd

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
  late final TextEditingController _rPctCtrl;

  // r(%) 슬라이더
  double rPct = 5.0; // 9.0 -> 5.0

  // 초기값(Reset)
  double _initPrice = 0.0;
  StockFundamentals _initF = const StockFundamentals(eps: 0, bps: 0, dps: 0);
  double _initR = 5.0; // 9.0 -> 5.0

  // 헤더카드, 평가문구 토글용
  bool _showAdvanced = true;
  bool _headerExpanded = true;
  bool _explanationExpanded = false;

  static const _kResultViewMode = 'result_view_mode_v1';
  static const _kHeaderExpanded = 'result_header_expanded_v1';

  String get _storeKey => "${widget.market.name}:${widget.item.code}";
  bool get _isUS => widget.market == Market.us;

  // 표시용(라벨)
  String get _priceUnitText {
    if (_isUS) {
      return isKoLang ? r'현재가($)' : r'Current price ($)';
    }
    return isKoLang ? '현재가(원)' : 'Current price (KRW)';
  }

  // 결과/요약 표시용 포맷 (콤마/단위 일관성)
  String _fmtMoney(num v) {
    return _isUS
        ? fmtUsdDecimal(v, fractionDigits: 2)
        : fmtWonDecimal(v, fractionDigits: 0);
  }

  // 가격 포맷터
  late final TextInputFormatter _priceFormatterKr;
  late final TextInputFormatter _priceFormatterUs;

  // pdf
  final _pdfService = ResultPdfService();

  // 로딩 단계 표시(디버깅/UX)
  String _stage = '';
  void _setStage(String s) {
    if (!mounted) return;
    setState(() => _stage = s);
    debugPrint('[ResultPage][STAGE] $s');
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          hub: widget.hub,
          initialRequiredReturnPct: rPct,
        ),
      ),
    );
  }

  // 에러 영어 변환
  String _valuationErrorText(Object e) {
    if (e is ValuationException) {
      switch (e.code) {
        case ValuationErrorCode.invalidRequiredReturn:
          return t.valuationErrorInvalidRequiredReturn;
        case ValuationErrorCode.invalidPrice:
          return t.valuationErrorInvalidPrice;
        case ValuationErrorCode.invalidBps:
          return t.valuationErrorInvalidBps;
      }
    }

    final raw = e.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }
  
  // 미국티커 한글표시용
  String get _displayName {
    final locale = Localizations.localeOf(context);

    if (_isUS) {
      if (locale.languageCode == 'ko') {
        final ko = SearchAlias.usPrimaryKoName(widget.item.code);
        return ko ?? widget.item.name;
      }
      return widget.item.name;
    }

    return SearchAlias.displayKrName(
      code: widget.item.code,
      koName: widget.item.name,
      locale: locale,
    );
  }

  // 한글은 그대로 사용
  String? get _originalDisplayName {
    final locale = Localizations.localeOf(context);

    if (_isUS) {
      if (locale.languageCode != 'ko') return null;

      final ko = SearchAlias.usPrimaryKoName(widget.item.code);
      final en = widget.item.name.trim();
      if (ko == null || en.isEmpty || ko == en) return null;
      return en;
    }

    return SearchAlias.displayKrOriginalName(
      code: widget.item.code,
      koName: widget.item.name,
      locale: locale,
    );
  }

  // 국내 서브타이틀 영어매핑 보이기
  String? get _headerSubtitleName {
    if (_isUS) {
      final original = _originalDisplayName?.trim();
      if (original == null || original.isEmpty) return null;
      return original;
    }

    final enName = SearchAlias.krEnglishName(widget.item.code)?.trim();

    if (enName == null || enName.isEmpty || enName == widget.item.name.trim()) {
      return null;
    }

    return enName;
  }

  // 기업 업종 표시
  String? get _industryText {
    final hasIndustry = widget.item.industry?.trim().isNotEmpty ?? false;
    final hasSector = widget.item.sector?.trim().isNotEmpty ?? false;
    if (!hasIndustry && !hasSector) return null;

    final locale = Localizations.localeOf(context);

    if (_isUS) {
      final out = SearchAlias.displayUsIndustry(
        industryEn: widget.item.industry,
        sectorEn: widget.item.sector,
        locale: locale,
      ).trim();

      return out.isEmpty ? null : out;
    }

    final out = SearchAlias.displayKrIndustry(
      koIndustry: widget.item.industry,
      locale: locale,
    ).trim();

    return out.isEmpty ? null : out;
  }

  String? _resultPdfMetaText() {
    final lines = <String>[];

    final metric = _metricLabel();
    if (metric != null && metric.trim().isNotEmpty) {
      lines.add(metric);
    }

    final industry = _industryText;
    if (industry != null && industry.trim().isNotEmpty) {
      lines.add(isKoLang ? '업종: $industry' : 'Industry: $industry');
    }

    return lines.isEmpty ? null : lines.join('\n');
  }

  // 기업 아이콘
  String _headerMarkText() {
    final name = _displayName.trim();

    if (_isUS) {
      final ko = SearchAlias.usPrimaryKoName(widget.item.code);
      if (ko != null && ko.isNotEmpty) {
        return ko.substring(0, 1);
      }

      final code = widget.item.code
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (code.length >= 2) return code.substring(0, 2);
      if (code.isNotEmpty) return code;
      return 'U';
    }

    if (name.isNotEmpty) return name.substring(0, 1);
    return 'K';
  }

  // 로고 반응형 사이즈 조절
  double _responsiveHeaderMarkSize(
    BuildContext context, {
    double base = 40,
    double max = 52,
  }) {
    final ts = MediaQuery.of(context).textScaler.scale(1.0).clamp(1.0, 1.35);
    return (base + (ts - 1.0) * 10).clamp(base, max).toDouble();
  }

  // 헤더 기업마크
  Widget _headerCompanyMark({double size = 40}) {
    final logoUrl = widget.item.logoUrl?.trim();
    final base = _isUS ? Colors.indigo : Colors.teal;
    final text = _headerMarkText();

    debugPrint('[headerCompanyMark] code=${widget.item.code}, name=${widget.item.name}, logoUrl=[$logoUrl]');

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
      debugPrint('[headerCompanyMark] EMPTY logoUrl -> fallback, code=${widget.item.code}');
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
          debugPrint('[headerCompanyMark] load failed, url=[$url], error=$error');
          return fallback();
        },
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: const Duration(milliseconds: 80),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _priceCtrl = TextEditingController();
    _epsCtrl = TextEditingController();
    _bpsCtrl = TextEditingController();
    _dpsCtrl = TextEditingController();
    _rPctCtrl = TextEditingController(text: rPct.toStringAsFixed(1));

    _priceFormatterKr = MoneyInputFormatter(allowDecimal: false);
    _priceFormatterUs = MoneyInputFormatter(
      allowDecimal: true,
      decimalDigits: 2,
    );

    debugPrint(
      '[ResultPage] initState item=${widget.item.code} market=${widget.market}',
    );

    _loadViewMode();
    _loadFavState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _priceCtrl.dispose();
    _epsCtrl.dispose();
    _bpsCtrl.dispose();
    _dpsCtrl.dispose();
    _rPctCtrl.dispose();
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

  // 헤더카드, 평가문구 클릭 시 기억 저장
  Future<void> _loadViewMode() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getBool(_kResultViewMode);
    final savedHeaderExpanded = sp.getBool(_kHeaderExpanded);

    if (!mounted) return;
    setState(() {
      _showAdvanced = saved ?? true; // 저장값 없으면 기본은 고급보기
      _headerExpanded = savedHeaderExpanded ?? true; // 저장값 없으면 기본은 펼침
    });
  }
  
  // 평가문구 토글 상태 저장
  Future<void> _saveViewMode() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kResultViewMode, _showAdvanced);
  }

  // 헤더카드 토글 상태 저장
  Future<void> _saveHeaderExpanded() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kHeaderExpanded, _headerExpanded);
  }

  // -----------------
  // View Toggle (rating 카드 탭 / 미싱카드 탭 공통)
  // -----------------
  void _toggleViewMode() {
    if (!mounted) return;
    setState(() => _showAdvanced = !_showAdvanced);
    unawaited(_saveViewMode()); // 바꾼 상태 저장
    debugPrint('[Toggle] showAdvanced=$_showAdvanced');
  }

  void _toggleHeaderExpanded() {
    if (!mounted) return;
    setState(() => _headerExpanded = !_headerExpanded);
    unawaited(_saveHeaderExpanded());
  }

  // ---------- 파싱 ----------
  double _parseDouble(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '');
    if (t == '-' || t.isEmpty) return 0.0;
    return double.tryParse(t) ?? 0.0;
  }

  void _setRPct(double value, {bool updateText = true}) {
    final next = value.clamp(5.0, 20.0).toDouble();

    setState(() {
      rPct = next;
      if (updateText) {
        _rPctCtrl.text = next.toStringAsFixed(1);
      }
    });

    _scheduleSaveInputs();
  }

  void _applyRPctFromText(String raw, {bool updateText = true}) {
    final cleaned = raw.trim().replaceAll(',', '');
    final v = double.tryParse(cleaned);

    if (v == null) {
      if (updateText) {
        _rPctCtrl.text = rPct.toStringAsFixed(1);
      }
      return;
    }

    _setRPct(v, updateText: updateText);
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
      _rPctCtrl.text = _initR.toStringAsFixed(1);
      _applyToTextFields(price: _initPrice, f: _initF);
    });
  }

  Future<void> _retryAutoValues() async {
    await _inputStore.remove(_storeKey);
    if (!mounted) return;
    await _load();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.reloadedValues)),
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

    PriceFibChartData? nextPriceFibChart;

    try {
      // 1) 가격
      _setStage(t.loadingPriceStart);
      Future<void> loadPrice() async {
        try {
          final quote = await widget.hub
              .getPriceQuote(widget.market, code)
              .timeout(const Duration(seconds: 8), onTimeout: () {
            throw Exception(t.loadingPriceTimeout);
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
      _setStage(t.loadingFundamentalsStart);
      Future<void> loadFunda() async {
        try {
          f = await widget.hub
              .getFundamentals(widget.market, code, targetYear: null)
              .timeout(const Duration(seconds: 12), onTimeout: () {
            throw Exception(t.loadingFundamentalsTimeout);
          });
        } catch (e, st) {
          debugPrint('[ResultPage] fundamentals fail: $e\n$st');
          f = const StockFundamentals(eps: 0, bps: 0, dps: 0);
        }
      }

      // 피보나치 지표
      Future<void> loadPriceFibChart() async {
        try {
          nextPriceFibChart = await widget.hub
              .getPriceFibChart(widget.market, code, months: _priceFibMonths)
              .timeout(const Duration(seconds: 12), onTimeout: () {
            throw Exception('price fib chart timeout');
          });
        } catch (e, st) {
          debugPrint('[ResultPage] price fib chart fail: $e\n$st');
          nextPriceFibChart = null;
        }
      }

      // 병렬
      await Future.wait([
        loadPrice(),
        loadFunda(),
        loadPriceFibChart(),
      ]);

      // 3) 초기값 반영
      _setStage(t.loadingApplyInitial);

      // ✅ 랭킹에서 들어온 경우: 랭킹 계산값을 우선 적용
      if (widget.useRankingSnapshot) {
        final rp = widget.rankingPrice;
        final re = widget.rankingEps;
        final rb = widget.rankingBps;
        final rd = widget.rankingDps;

        if (rp != null && rp > 0) {
          price = rp;
        }

        f = StockFundamentals(
          eps: re ?? f.eps,
          bps: rb ?? f.bps,
          dps: rd ?? f.dps,
          year: f.year,
          basDt: f.basDt,
          periodLabel: f.periodLabel,
          fsDiv: f.fsDiv,
          reprtCode: f.reprtCode,
          fsSource: f.fsSource,
          epsSource: f.epsSource,
          bpsSource: f.bpsSource,
          dpsSource: f.dpsSource,
          epsLabel: f.epsLabel,
          bpsLabel: f.bpsLabel,
          dpsLabel: f.dpsLabel,
        );
      }

      _initPrice = price;
      _initF = f;

      // ✅ 기본 5.0이 아니라, 랭킹에서 들어왔으면 랭킹 r 사용
      final initialRPct = (widget.initialRequiredReturnPct ?? 10.0).clamp(5.0, 20.0).toDouble();

      _initR = widget.useRankingSnapshot
          ? (widget.rankingRPct ?? initialRPct)
          : initialRPct;

      rPct = _initR;
      _rPctCtrl.text = rPct.toStringAsFixed(1);

      _applyToTextFields(price: price, f: f);

      // 4) 저장값 복원
      // ✅ 랭킹에서 들어왔으면 저장값 복원 건너뜀
      if (!widget.useRankingSnapshot) {
        _setStage(t.loadingRestoreSaved);
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

          if (saved.dps != 0) {
            _dpsCtrl.text = _isUS
                ? fmtUsdDecimal(saved.dps, fractionDigits: fd).replaceAll('\$', '')
                : fmtWonDecimal(saved.dps, fractionDigits: fd);
          }

          // 요구수익률의 입력창 숫자와 실제 rPct 값이 항상 같이 맞춰짐
          if (widget.initialRequiredReturnPct == null) {
            rPct = saved.rPct;
            _rPctCtrl.text = rPct.toStringAsFixed(1);
          }
        }
        
      } else {
        _setStage(t.loadingApplyRankingSnapshot);
      }

      if (!mounted) return;

      _setStage(t.loadingDone);

      setState(() {
        _priceBasDt = nextPriceBasDt;
        _fundamentals = f;
        _priceFibChart = nextPriceFibChart;
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

  // 피보나치 차트 불러오는 함수
  Future<void> _reloadPriceFibChartOnly(int months) async {
    if (!mounted) return;

    setState(() {
      _priceFibLoading = true;
    });

    try {
      final chart = await widget.hub
          .getPriceFibChart(widget.market, widget.item.code, months: months)
          .timeout(const Duration(seconds: 12), onTimeout: () {
        throw Exception('price fib chart timeout');
      });

      if (!mounted) return;
      setState(() {
        _priceFibMonths = months;
        _priceFibChart = chart;
        _priceFibLoading = false;
      });
    } catch (e, st) {
      debugPrint('[ResultPage] reload price fib chart fail: $e\n$st');
      if (!mounted) return;

      setState(() {
        _priceFibLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKoLang
                ? '피보나치 차트를 다시 불러오지 못했습니다.'
                : 'Failed to reload Fibonacci chart.',
          ),
        ),
      );
    }
  }

  // ---------- Naver ----------
  Future<void> _openNaverFinanceForCurrent() async {
    final ok = await _link.openNaverFinance(rawCodeOrTicker: widget.item.code);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.naverOpenFailed)),
      );
      return;
    }

    if (mounted && _isUS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.naverUsHint)),
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
      return ResultCopy.financialBasisText(context, pl);
    }

    final bd = f.basDt?.trim();
    if (bd != null && bd.isNotEmpty) {
      return ResultCopy.financialDateText(context, _fmtBasDt(bd));
    }

    if (f.year != null) {
      return ResultCopy.financialBasisText(context, '${f.year}');
    }

    return null;
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
    final name = _displayName;

    return Scaffold(
      appBar: AppBar(
        title: Text(ResultCopy.pageTitle(context, name)),
        backgroundColor: _accent.withAlpha(18),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: t.search,
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            tooltip: t.favorite,
            icon: Icon(
              _isFav ? Icons.star : Icons.star_border,
              color: _isFav ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
            visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),

          Tooltip(
            message: t.openNaverKr,
            child: TextButton(
              onPressed: _openNaverFinanceForCurrent,
              style: TextButton.styleFrom(
                foregroundColor: _accent.withAlpha(220),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
              ),
              child: Text(
                t.openNaverKr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: t.moreMenu,
            icon: const Icon(Icons.more_vert),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onSelected: (value) async {
              switch (value) {
                case 'pdf':
                  await _showPdfSaveSheet();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    const SizedBox(width: 10),
                    Text(t.savePdf),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
      body: SafeArea(
        top: false,
        child: _loading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(_stage.isEmpty ? t.loading : _stage),
                  ],
                ),
              )
            : (_error != null ? _errorView() : _bodyView()),
      ),
    );
  }

  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKoLang ? "불러오기 실패: $_error" : "Load failed: $_error",
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            child: Text(t.retry),
          ),
        ],
      ),
    );
  }

  Widget _bodyView() {
    final name = _displayName;
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
      calcError = _valuationErrorText(e);
    }

    // 5단계 요약
    ValuationRating? rating;
    if (calcError == null && result != null) {
      rating = ValuationService.interpret5(
        result,
        rPct,
        isKo: isKoLang,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _headerCard(name, code),
        const SizedBox(height: 8),

          _requiredReturnHeaderCard(),
          const SizedBox(height: 8),

          if (rating != null) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _toggleViewMode,
              child: _showAdvanced
                  ? _ratingCardCompact(rating)
                  : _ratingCardLarge(rating),
            ),
            const SizedBox(height: 8),
          ],

          _missingDataHintCard(),
          const SizedBox(height: 8),

          KeyedSubtree(
            key: const ValueKey('input_card'),
            child: _inputCard(),
          ),
          const SizedBox(height: 2),

          if (calcError == null && result != null) ...[
            _topQuickSummaryCard(
              r: result,
              rating: rating,
             // fib: _priceFibChart,
            ),
            const SizedBox(height: 8),

            _priceFairGauge(
              price: price,
              fairPrice: result.fairPrice,
            ),
            const SizedBox(height: 5),

            Text(
              ResultCopy.valuationStatusText(context, result.gapPct),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 11),
          ],

          _resultCard(currentPrice: price, result: result, calcError: calcError),
          const SizedBox(height: 8),

          // 피보나치 차트
          // if (_priceFibChart != null) ...[
          //   PriceFibChartCard(
          //     data: _priceFibChart!,
          //     isKoLang: isKoLang,
          //     isUS: _isUS,
          //     months: _priceFibMonths,
          //     loading: _priceFibLoading,
          //     formatMoney: (v) => _fmtMoney(v),
          //     onTapGuide: () => _showFibGuideSheet(_priceFibChart!),
          //     onSelectMonths: _reloadPriceFibChartOnly,
          //   ),
          //   const SizedBox(height: 8),
          // ],

          if (calcError == null && result != null) ...[
            _explanationSection(
              price: price,
              result: result,
              rating: rating,
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),
      ],
    );
  }

  // 기업설명 결과
  String _explanationHeadline(ValuationResult result, ValuationRating? rating) {
    final expected = result.expectedReturnPct;
    final expectedText =
        '${expected >= 0 ? '+' : ''}${expected.toStringAsFixed(1)}%';
    final gapText = result.gapPct.toStringAsFixed(1);

    if (isKoLang) {
      switch (rating?.level) {
        case RatingLevel.strongBuy:
          return '계산된 가치 대비 상당히 저평가된 상태입니다. $expectedText 수준의 높은 기대수익률을 목표로 공격적인 검토가 가능한 구간입니다.';
        case RatingLevel.buy:
          return '현재 주가는 적정가보다 낮게 형성되어 있습니다. expectedText 정도의 상승 여력이 있어, 긍정적인 관점으로 지켜볼 만한 시점입니다.';
        case RatingLevel.caution:
          return '주가는 싸 보일 수 있지만 수익성 지표가 다소 불안정합니다. 가격만 보고 진입하기보다 실적 회복 여부를 먼저 확인하는 것이 안전합니다.';
        case RatingLevel.avoid:
          return '가치 대비 가격 부담이 크거나 수익성이 약해진 상태입니다. 지금은 적극적인 매수보다 보수적인 관점에서 흐름을 관망하는 것이 현명합니다.';
        case RatingLevel.neutral:
        default:
          return '현재 주가는 적정가($gapText%) 부근에서 균형을 이루고 있습니다. 큰 왜곡이 없는 상태이므로, 향후 실적 변화에 따라 방향성을 결정할 것으로 보입니다.';
      }
    }

    switch (rating?.level) {
      case RatingLevel.strongBuy:
        return 'Highly undervalued with a strong expected return of $expectedText This is a prime range for aggressive consideration.';
      case RatingLevel.buy:
        return 'Trading below its fair value with an upside of $expectedText It presents a solid opportunity for a positive outlook.';
      case RatingLevel.caution:
        return 'Price may seem cheap, but profitability shows weakness Confirming an earnings recovery is safer than buying on price alone.';
      case RatingLevel.avoid:
        return 'The stock is overvalued or profitability is declining A conservative approach is recommended over aggressive entry right now.';
      case RatingLevel.neutral:
      default:
        return 'Price is balanced near its fair value ($gapText%). With no significant gap, the next move will likely depend on future earnings.';
    }
  }

  Widget _explanationMiniChip({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(190),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _cInfo.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExplanationExpanded() {
    if (!mounted) return;
    setState(() => _explanationExpanded = !_explanationExpanded);
  }

  // 기업결과설명카드
  Widget _collapsedExplanationCard({
    required ValuationResult result,
    required ValuationRating? rating,
  }) {
    final expectedText =
        '${result.expectedReturnPct >= 0 ? '+' : ''}${result.expectedReturnPct.toStringAsFixed(1)}%';

    final fibText = _priceFibChart == null
        ? null
        : '${_priceFibChart!.positionPct.toStringAsFixed(1)}%';

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _cInfo.withAlpha(60)),
      ),
      child: InkWell(
        onTap: _toggleExplanationExpanded,
        child: Container(
          decoration: BoxDecoration(
            color: _cInfo.withAlpha(10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _cInfo.withAlpha(25),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: _cInfo.withAlpha(220),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isKoLang
                            ? '이 기업은 지금 이런 상태예요'
                            : 'What this stock looks like now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more, color: Colors.grey[700]),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _explanationHeadline(result, rating),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _explanationMiniChip(
                      label: isKoLang ? '기대수익률' : 'Expected',
                      value: expectedText,
                      valueColor: result.expectedReturnPct >= 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    _explanationMiniChip(
                      label: isKoLang ? '적정주가' : 'Fair price',
                      value: _fmtMoney(result.fairPrice),
                    ),
                    // if (fibText != null)
                    //   _explanationMiniChip(
                    //     label: isKoLang ? '피보나치 위치' : 'Fib position',
                    //     value: fibText,
                    //     valueColor: _accent.withAlpha(220),
                    //   ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isKoLang ? '눌러서 자세히 보기' : 'Tap to expand',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _explanationSection({
    required double price,
    required ValuationResult result,
    required ValuationRating? rating,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _explanationExpanded
          ? Column(
              key: const ValueKey('expanded_explanation'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _toggleExplanationExpanded,
                    child: ResultExplanationCard(
                      isKoLang: isKoLang,
                      currentPrice: price,
                      requiredReturnPct: rPct,
                      fibPositionPct: _priceFibChart?.positionPct,
                      formatMoney: _fmtMoney,
                      result: result,
                      rating: rating,
                      accentColor: _accent,
                      infoColor: _cInfo,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _toggleExplanationExpanded,
                    icon: const Icon(Icons.expand_less),
                    label: Text(isKoLang ? '간단히 보기' : 'Show less'),
                  ),
                ),
              ],
            )
          : _collapsedExplanationCard(
              result: result,
              rating: rating,
            ),
    );
  }

  // 헤더 카드
  Widget _headerCard(String name, String code) {
    final marketText = (widget.market == Market.kr) ? "KR" : "US";
    final f = _fundamentals ?? _initF;

    final subtitleName = _headerSubtitleName;
    final industryText = _industryText;

    final subtitleMeta = industryText != null
        ? '$code · $industryText'
        : '$code · $marketText';

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _toggleHeaderExpanded,
        child: Container(
          decoration: _cardDeco(_cHeader),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: _cHeader.withAlpha(170), width: 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headerCompanyMark(
                          size: _responsiveHeaderMarkSize(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (subtitleName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitleName,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitleMeta,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitleMeta,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _headerExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey[700],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _openFinancialStatementPage,
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: Text(t.viewFinancialStatements),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),

                    if (_headerExpanded) ...[
                      const SizedBox(height: 8),
                      Text(
                        ResultCopy.dataSourceText(context, widget.market),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (f.basDt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ResultCopy.financialDateText(
                            context,
                            _fmtBasDt(f.basDt!),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      if (_priceBasDt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ResultCopy.priceDateText(
                            context,
                            _fmtBasDt(_priceBasDt!),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 요구수익률 카드함수
  Widget _requiredReturnHeaderCard() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 2.0)
        .toDouble();

    final inputWidth = (76.0 + (textScale - 1.0) * 28.0).clamp(76.0, 110.0);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface.withAlpha(235),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withAlpha(85)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            ResultCopy.requiredReturnLabel(context),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        MiniHelpTip(
                          message: ResultCopy.requiredReturnTooltip(context),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: inputWidth,
                    child: TextField(
                      controller: _rPctCtrl,
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
                            color: cs.outlineVariant.withAlpha(110),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(
                            color: _accent.withAlpha(120),
                            width: 1.0,
                          ),
                        ),
                      ),
                      onSubmitted: (v) => _applyRPctFromText(v),
                      onEditingComplete: () {
                        _applyRPctFromText(_rPctCtrl.text);
                        FocusScope.of(context).unfocus();
                      },
                      onTapOutside: (_) {
                        _applyRPctFromText(_rPctCtrl.text);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                ResultCopy.requiredReturnHelp(context),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accent.withAlpha(190),
                  inactiveTrackColor: _accent.withAlpha(50),
                  thumbColor: _accent.withAlpha(215),
                  overlayColor: _accent.withAlpha(18),
                  valueIndicatorColor: _accent.withAlpha(215),
                  trackHeight: 2.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 10,
                  ),
                ),
                child: Slider(
                  value: rPct,
                  min: 5,
                  max: 20,
                  divisions: 150,
                  label: "${rPct.toStringAsFixed(1)}%",
                  onChanged: (v) => _setRPct(v),
                ),
              ),
              Row(
                children: [
                  Text(
                    "5%",
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    "20%",
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
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

    final f = _fundamentals ?? _initF;
    final usedPeriod = f.periodLabel?.trim();
    final usedFinanceText = (usedPeriod != null && usedPeriod.isNotEmpty)
        ? usedPeriod
        : (f.year != null ? '${f.year}' : null);

    final dpsZero = (dps == 0);

    //  고급(true)=간단, 초급(false)=자세히
    final showDetail = !_showAdvanced;

    final brief = ResultCopy.missingBrief(context);
    final detail = ResultCopy.missingDetail(
      context,
      market: widget.market,
      usedFinanceText: usedFinanceText,
      dpsZero: dpsZero,
    );

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
                            ResultCopy.missingTitle(context, missing),
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
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            side: const BorderSide(width: 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.refresh, size: 14),
                          label: Text(
                            ResultCopy.retryAutoValuesLabel(context),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  // 텍스트박스 카드
  Widget _inputCard() {
    final priceFormatter = _isUS ? _priceFormatterUs : _priceFormatterKr;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface.withAlpha(235),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ResultCopy.inputsTitle(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetToInitial,
                    style: TextButton.styleFrom(
                      foregroundColor: _cInput.withAlpha(210),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      ResultCopy.resetLabel(context),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Container(
                width: double.infinity,
                height: 1,
                color: cs.outlineVariant.withAlpha(70),
              ),

              const SizedBox(height: 10),

              if (_parseDouble(_priceCtrl) == 0.0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withAlpha(45)),
                  ),
                  child: Text(
                    ResultCopy.priceUnavailableHint(context),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              LabeledNumberField(
                key: const ValueKey('price_field'),
                label: _priceUnitText,
                controller: _priceCtrl,
                onChanged: (_) => _onAnyInputChanged(),
                inputFormatters: [priceFormatter],
                hintText: ResultCopy.manualInputHint(context),
              ),

              const SizedBox(height: 6),

              MetricFieldWithBadge(
                key: const ValueKey('eps_field'),
                isUS: _isUS,
                label: "EPS",
                helpMessage: ResultCopy.epsTooltip(context),
                controller: _epsCtrl,
                onChanged: (_) => _onAnyInputChanged(),
              ),

              const SizedBox(height: 6),

              MetricFieldWithBadge(
                key: const ValueKey('bps_field'),
                isUS: _isUS,
                label: "BPS",
                helpMessage: ResultCopy.bpsTooltip(context),
                controller: _bpsCtrl,
                onChanged: (_) => _onAnyInputChanged(),
              ),

              const SizedBox(height: 6),

              MetricFieldWithBadge(
                key: const ValueKey('dps_field'),
                isUS: _isUS,
                label: "DPS",
                helpMessage: ResultCopy.dpsTooltip(context),
                controller: _dpsCtrl,
                onChanged: (_) => _onAnyInputChanged(),
              ),

              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Text(
                  _metricLabel() ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 매수평가 작은카드 
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
                  Text(
                    rating.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: a,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rating.summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  // 매수평가 큰카드
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
                  Expanded(
                    child: Text(
                      rating.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: a,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_up,
                    color: Colors.grey[700],
                  ),
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

  // 상단 요약카드
  Widget _topQuickSummaryCard({
    required ValuationResult r,
    required ValuationRating? rating,
    PriceFibChartData? fib,
  }) {
    final judgmentColor =
        rating?.accent ?? _ratingColor(rating?.level ?? RatingLevel.neutral);
    final currentPriceText = _fmtMoney(_parseDouble(_priceCtrl));    

    // final fibText = fib == null ? '-' : '${fib.positionPct.toStringAsFixed(1)}%';
    // final fibSub = _fibZoneShort(fib);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _cResult.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cResult.withAlpha(45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _topSummaryMetricBox(
                        title: isKoLang ? '현재가' : 'Current price',
                        value: currentPriceText,
                        subtitle: isKoLang ? '현재 가격' : 'Latest price',
                        valueColor: Colors.blueGrey,
                      ),
                    ),
                    // 피보나치용
                    //  Expanded(
                    //    child: _topSummaryMetricBox(
                    //      title: isKoLang
                    //          ? '${(_priceFibMonths / 12).round()}년 위치'
                    //          : '${(_priceFibMonths / 12).round()}Y position',
                    //      value: fibText,
                    //      subtitle: fibSub,
                    //      valueColor: _accent.withAlpha(220),
                    //    ),
                    //  ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _topSummaryMetricBox(
                         title: ResultCopy.fairPriceLabel(context),
                         value: _fmtMoney(r.fairPrice),
                         subtitle: "BPS × (ROE / r)",
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _topSummaryMetricBox(
                        title: ResultCopy.expectedReturnPctLabel(context),
                        value:
                            "${r.expectedReturnPct >= 0 ? '+' : ''}${r.expectedReturnPct.toStringAsFixed(1)}%",
                        valueColor:
                            r.expectedReturnPct >= 0 ? Colors.green : Colors.red,
                        subtitle: ResultCopy.expectedReturnHint(context),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _topSummaryMetricBox(
                        title: isKoLang ? '매수판단' : 'Judgement',
                        value: rating?.title ?? (isKoLang ? '중립' : 'Neutral'),
                        valueColor: judgmentColor,
                        subtitle: isKoLang ? '현재 평가' : 'Current view',
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

  // 피보나치 헬퍼
  String _fibZoneShort(PriceFibChartData? fib) {
    if (fib == null) return isKoLang ? '차트 없음' : 'No chart';

    final p = fib.positionPct;
    if (p >= 80) return isKoLang ? '상단 20%' : 'Top 20%';
    if (p >= 60) return isKoLang ? '상단 구간' : 'Upper zone';
    if (p >= 40) return isKoLang ? '중간 구간' : 'Middle zone';
    if (p >= 20) return isKoLang ? '하단 구간' : 'Lower zone';
    return isKoLang ? '하단 20%' : 'Bottom 20%';
  }

  Widget _topSummaryMetricBox({
    required String title,
    required String value,
    String? subtitle,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(185),
        border: Border.all(color: _cKpi.withAlpha(35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 10.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 결과카드
  Widget _resultCard({
    required double currentPrice,
    required ValuationResult? result,
    required String? calcError,
  }) {
    if (calcError != null || result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            ResultCopy.calcNeedMoreValues(context),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final r = result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKoLang ? '상세 결과' : 'Detailed results',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            _sectionCard(ResultCopy.valueSectionTitle(context), [
              _metricTile(
                label: ResultCopy.fairPriceLabel(context),
                value: _fmtMoney(r.fairPrice),
                helper: "BPS × (ROE / r)",
                icon: Icons.price_check,
              ),
              _metricTile(
                label: ResultCopy.valuationStatusLabel(context),
                value: "${r.gapPct.toStringAsFixed(1)}%",
                helper: ResultCopy.valuationStatusHelper(context),
                icon: Icons.bar_chart,
              ),
              _metricTile(
                label: ResultCopy.expectedReturnPctLabel(context),
                value: "${r.expectedReturnPct >= 0 ? '+' : ''}${r.expectedReturnPct.toStringAsFixed(1)}%",
                helper: ResultCopy.expectedReturnHint(context),
                icon: Icons.trending_up,
              ),
            ]),
            const SizedBox(height: 8),
            _sectionCard(ResultCopy.profitabilitySectionTitle(context), [
              _metricTile(
                label: "ROE",
                value: "${r.roePct.toStringAsFixed(2)}%",
                helper: "EPS / BPS",
                helpMessage: ResultCopy.roeTooltip(context),
                icon: Icons.flash_on,
              ),
              _metricTile(
                label: "ROE / r",
                value: r.roeOverR.toStringAsFixed(2),
                helper: ResultCopy.roeOverRHelper(context),
                helpMessage: ResultCopy.roeOverRTooltip(context),
                icon: Icons.functions,
              ),
            ]),
            const SizedBox(height: 8),
            _sectionCard(ResultCopy.dividendSectionTitle(context), [
              _metricTile(
                label: ResultCopy.dividendYieldLabel(context),
                value: "${r.dividendYieldPct.toStringAsFixed(2)}%",
                helper: isKoLang ? "DPS / 현재가" : "DPS / current price",
                helpMessage: ResultCopy.dividendYieldTooltip(context),
                icon: Icons.savings,
              ),
            ]),
            const SizedBox(height: 8),
            _sectionCard(ResultCopy.multiplesSectionTitle(context), [
              _metricTile(
                label: "PER",
                value: r.per.toStringAsFixed(2),
                helpMessage: ResultCopy.perTooltip(context),
                icon: Icons.calculate,
              ),
              _metricTile(
                label: "PBR",
                value: r.pbr.toStringAsFixed(2),
                helpMessage: ResultCopy.pbrTooltip(context),
                icon: Icons.assessment,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // 현재/적정가 바 표시
  Widget _priceFairGauge({required double price, required double fairPrice}) {
    if (price <= 0 || fairPrice <= 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _cInfo.withAlpha(12),
          border: Border.all(color: _cInfo.withAlpha(60)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          ResultCopy.needCurrentAndFairPrice(context),
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    final mq = MediaQuery.of(context);
    final ts = mq.textScaler.scale(1.0).clamp(1.0, 2.0).toDouble();

    Widget clampScale(Widget child, {double max = 1.25}) {
      final cur = mq.textScaler.scale(1.0);
      if (cur <= max) return child;
      return MediaQuery(
        data: mq.copyWith(textScaler: TextScaler.linear(max)),
        child: child,
      );
    }

    final ratio = price / fairPrice;
    final pct = ratio * 100.0;

    final clamped = ratio.clamp(0.0, 2.0).toDouble();
    final fill = clamped / 2.0;

    final isUndervalued = ratio <= 1.0;
    final verticalInfo = ts >= 1.3;

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
          Text(
           ResultCopy.currentVsFairText(context, pct),
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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

          // 0 / 100 / 200: 좌/중/우 정렬 고정
          clampScale(
            Row(
              children: [
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("0%", style: TextStyle(fontSize: 12)),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(ResultCopy.fairAt100Label(context), style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text("200%", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            max: 1.25,
          ),

          const SizedBox(height: 6),

          // 현재가/적정가: 좌/우 정렬 + 길면 축소
          clampScale(
  Row(
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isKoLang
                  ? '현재가: ${_fmtMoney(price)}'
                  : 'Current: ${_fmtMoney(price)}',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              ResultCopy.fairPriceText(context, _fmtMoney(fairPrice)),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ),
    ],
  ),
  max: verticalInfo ? 1.35 : 1.25,
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
    String? helpMessage,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (helpMessage != null) ...[
                      const SizedBox(width: 6),
                      MiniHelpTip(message: helpMessage),
                    ],
                  ],
                ),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // 피보나치 안내박스를 바텀시트로 여는 함수 추가
  void _showFibGuideSheet(PriceFibChartData data) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: PriceFibGuideCard(
              data: data,
              isKoLang: isKoLang,
              isUS: _isUS,
            ),
          ),
        );
      },
    );
  }

  // pdf
  Future<void> _showPdfSaveSheet() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(120),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ResultCopy.pdfExportTitle(context),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_displayName} (${widget.item.code})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _pdfSheetTile(
                  icon: Icons.assessment_outlined,
                  title: ResultCopy.pdfSaveResultTitle(context),
                  subtitle: ResultCopy.pdfSaveResultSubtitle(context),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _saveResultPdf();
                  },
                ),
                _pdfSheetTile(
                  icon: Icons.picture_as_pdf_outlined,
                  title: ResultCopy.pdfSaveFullTitle(context),
                  subtitle: ResultCopy.pdfSaveFullSubtitle(context),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _saveFullPdf();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pdfSheetTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withAlpha(55)),
              color: _accent.withAlpha(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _accent.withAlpha(18),
                    child: Icon(icon, color: _accent.withAlpha(220)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
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
          ),
        ),
      ),
    );
  }

  String? _buildPdfMetaText({StockFinancialDetails? details}) {
    final f = _fundamentals ?? _initF;
    final lines = <String>[];

    final industry = _industryText;
    if (industry != null && industry.trim().isNotEmpty) {
      lines.add(isKoLang ? '업종: $industry' : 'Industry: $industry');
    }

    final metricHint = _metricLabel();
    if (metricHint != null && metricHint.trim().isNotEmpty) {
      lines.add(metricHint);
    }

    if (_priceBasDt != null) {
      lines.add(ResultCopy.priceDateText(context, _fmtBasDt(_priceBasDt!)));
    }

    if (_isUS && details != null) {
      final currency = _reportedCurrencyOf(details);
      if (currency.isNotEmpty) {
        lines.add(isKoLang ? '보고 통화: $currency' : 'Reporting currency: $currency');
      }
    }

    if (f.fsSource != null && f.fsSource!.trim().isNotEmpty) {
      lines.add(t.financialSourceLabel(f.fsSource!));
    }

    return lines.isEmpty ? null : lines.join('\n');
  }

  String _pdfMetricText(double v) {
    return _isUS
        ? fmtUsdDecimal(v, fractionDigits: 2)
        : fmtWonDecimal(v, fractionDigits: 0);
  }

  String _pdfFsText(num? v) {
    if (v == null) return '-';
    return _fmtMoney(v);
  }

  String _reportedCurrencyOf(StockFinancialDetails d) {
    final code = (d.reportedCurrency ?? '').trim().toUpperCase();
    return code.isEmpty ? 'USD' : code;
  }

  String _fmtRawPdfMoney(num? v, {required String currencyCode}) {
    if (v == null) return '-';

    final text = NumberFormat('#,##0', 'en_US').format(v);
    final code = currencyCode.trim().toUpperCase();

    switch (code) {
      case 'USD':
        return '\$$text';
      case 'KRW':
        return '₩$text';
      case 'CNY':
      case 'RMB':
        return 'RMB $text';
      case 'JPY':
        return '¥$text';
      case 'EUR':
        return 'EUR $text';
      default:
        return '$code $text';
    }
  }

  String _pdfMoneyWithUsdRef(num? raw, StockFinancialDetails? d) {
    if (raw == null) return '-';

    if (!_isUS || d == null) {
      return _pdfFsText(raw);
    }

    final currency = _reportedCurrencyOf(d);
    final rawText = _fmtRawPdfMoney(raw, currencyCode: currency);
    final rate = d.fxRateToUsd;

    if (currency == 'USD' || rate == null || rate <= 0) {
      return rawText;
    }

    final usd = raw.toDouble() * rate;
    final usdText = _fmtRawPdfMoney(usd, currencyCode: 'USD');

    return '$rawText\n${isKoLang ? 'USD 환산 참고값: $usdText' : 'USD reference value: $usdText'}';
  }

  Future<void> _saveResultPdf() async {
    try {
      final price = _parseDouble(_priceCtrl);
      final eps = _parseDouble(_epsCtrl);
      final bps = _parseDouble(_bpsCtrl);
      final dps = _parseDouble(_dpsCtrl);

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
        calcError = _valuationErrorText(e);
      }

      ValuationRating? rating;
      if (calcError == null && result != null) {
        rating = ValuationService.interpret5(
          result,
          rPct,
          isKo: isKoLang,
        );
      }

      final explanationParagraphs =
          (result != null && calcError == null)
              ? _buildPdfExplanationParagraphs(
                  result: result,
                  rating: rating,
                )
              : null;

      final labels = ResultPdfLabels(
        inputSectionTitle: t.resultPdfInputSectionTitle,
        resultSectionTitle: t.resultPdfResultSectionTitle,
        ratingSummarySectionTitle: t.resultPdfRatingSummarySectionTitle,
        financialSummarySectionTitle: t.resultPdfFinancialSummarySectionTitle,
        noteSectionTitle: t.resultPdfNoteSectionTitle,
        explanationSectionTitle: isKoLang
            ? '이 기업은 지금 이런 상태예요'
            : 'What this stock looks like now',

        currentPriceLabel: t.resultPdfCurrentPriceLabel,
        epsLabel: t.resultPdfEpsLabel,
        bpsLabel: t.resultPdfBpsLabel,
        dpsLabel: t.resultPdfDpsLabel,
        requiredReturnLabel: t.resultPdfRequiredReturnLabel,

        fairPriceLabel: t.resultPdfFairPriceLabel,
        expectedReturnLabel: t.resultPdfExpectedReturnLabel,
        valuationStatusLabel: t.resultPdfValuationStatusLabel,
        roeLabel: t.resultPdfRoeLabel,
        dividendYieldLabel: t.resultPdfDividendYieldLabel,
        perLabel: t.resultPdfPerLabel,
        pbrLabel: t.resultPdfPbrLabel,

        ratingLabel: t.resultPdfRatingLabel,
        financialBasisLabel: t.resultPdfFinancialBasisLabel,
        revenueLabel: t.resultPdfRevenueLabel,
        opIncomeLabel: t.resultPdfOpIncomeLabel,
        netIncomeLabel: t.resultPdfNetIncomeLabel,
        equityLabel: t.resultPdfEquityLabel,
        liabilitiesLabel: t.resultPdfLiabilitiesLabel,
        financialSourceLabel: t.resultPdfFinancialSourceLabel,

        calcUnavailablePrefix: t.resultPdfCalcUnavailablePrefix,
        disclaimerText: t.resultPdfDisclaimerText,
        shareTextSuffix: t.resultPdfShareTextSuffix,
        platformNotSupportedText: t.resultPdfPlatformNotSupportedText,
        fontLoadErrorText: t.resultPdfFontLoadErrorText,
      );

      final data = ResultPdfData(
        name: _displayName,
        originalName: _originalDisplayName,
        code: widget.item.code,
        marketText: widget.market == Market.kr ? 'KR' : 'US',
        sourceText: widget.market == Market.kr
            ? (isKoLang
                ? '출처: OpenDART 재무 + KIS 시세'
                : 'Source: OpenDART financials + KIS quotes')
            : (isKoLang
                ? '출처: FMP(제공 범위에 따라 값이 비어 있을 수 있음)'
                : 'Source: FMP (some values may be empty depending on coverage)'),
        metaText: _buildPdfMetaText(details: null),
        includeEvaluation: true,
        includeFinancials: false,
        currentPriceText: _fmtMoney(price),
        epsText: _pdfMetricText(eps),
        bpsText: _pdfMetricText(bps),
        dpsText: _pdfMetricText(dps),
        rPctText: '${rPct.toStringAsFixed(1)}%',
        fairPriceText: result != null ? _fmtMoney(result.fairPrice) : null,
        expectedReturnText: result != null
            ? '${result.expectedReturnPct >= 0 ? '+' : ''}${result.expectedReturnPct.toStringAsFixed(1)}%'
            : null,
        gapText: result != null ? '${result.gapPct.toStringAsFixed(1)}%' : null,
        roeText: result != null ? '${result.roePct.toStringAsFixed(2)}%' : null,
        dividendYieldText: result != null
            ? '${result.dividendYieldPct.toStringAsFixed(2)}%'
            : null,
        perText: result != null ? result.per.toStringAsFixed(2) : null,
        pbrText: result != null ? result.pbr.toStringAsFixed(2) : null,
        ratingTitle: rating?.title,
        ratingSummary: rating?.summary,
        calcError: calcError,
        explanationParagraphs: explanationParagraphs,
        financialPeriodText: null,
        revenueText: null,
        opIncomeText: null,
        netIncomeText: null,
        equityText: null,
        liabilitiesText: null,
        fsSourceText: null,
        labels: labels,
      );

      final savedPath = await _pdfService.savePdf(data);

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ResultCopy.pdfCanceled(context))),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ResultCopy.pdfStartedResult(context))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ResultCopy.pdfFailed(context, e))),
      );
    }
  }

  Future<void> _saveFullPdf() async {
    try {
      final details = await widget.hub.getFinancialDetails(
        widget.market,
        widget.item.code,
        targetYear: null,
      );

      final price = _parseDouble(_priceCtrl);
      final eps = _parseDouble(_epsCtrl);
      final bps = _parseDouble(_bpsCtrl);
      final dps = _parseDouble(_dpsCtrl);

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
        calcError = _valuationErrorText(e);
      }

      ValuationRating? rating;
      if (calcError == null && result != null) {
        rating = ValuationService.interpret5(
          result,
          rPct,
          isKo: isKoLang,
        );
      }

      final explanationParagraphs =
          (result != null && calcError == null)
              ? _buildPdfExplanationParagraphs(
                  result: result,
                  rating: rating,
                )
              : null;

      final f = details.current;

      String financialPeriodText = '-';
      if ((f.periodLabel ?? '').trim().isNotEmpty) {
        financialPeriodText = f.periodLabel!.trim();
      } else if ((f.basDt ?? '').trim().isNotEmpty) {
        financialPeriodText = _fmtBasDt(f.basDt!);
      } else if (f.year != null) {
        financialPeriodText = '${f.year}';
      }

      final labels = ResultPdfLabels(
        inputSectionTitle: t.resultPdfInputSectionTitle,
        resultSectionTitle: t.resultPdfResultSectionTitle,
        ratingSummarySectionTitle: t.resultPdfRatingSummarySectionTitle,
        financialSummarySectionTitle: t.resultPdfFinancialSummarySectionTitle,
        noteSectionTitle: t.resultPdfNoteSectionTitle,
        explanationSectionTitle: isKoLang
            ? '이 기업은 지금 이런 상태예요'
            : 'What this stock looks like now',

        currentPriceLabel: t.resultPdfCurrentPriceLabel,
        epsLabel: t.resultPdfEpsLabel,
        bpsLabel: t.resultPdfBpsLabel,
        dpsLabel: t.resultPdfDpsLabel,
        requiredReturnLabel: t.resultPdfRequiredReturnLabel,

        fairPriceLabel: t.resultPdfFairPriceLabel,
        expectedReturnLabel: t.resultPdfExpectedReturnLabel,
        valuationStatusLabel: t.resultPdfValuationStatusLabel,
        roeLabel: t.resultPdfRoeLabel,
        dividendYieldLabel: t.resultPdfDividendYieldLabel,
        perLabel: t.resultPdfPerLabel,
        pbrLabel: t.resultPdfPbrLabel,

        ratingLabel: t.resultPdfRatingLabel,
        financialBasisLabel: t.resultPdfFinancialBasisLabel,
        revenueLabel: t.resultPdfRevenueLabel,
        opIncomeLabel: t.resultPdfOpIncomeLabel,
        netIncomeLabel: t.resultPdfNetIncomeLabel,
        equityLabel: t.resultPdfEquityLabel,
        liabilitiesLabel: t.resultPdfLiabilitiesLabel,
        financialSourceLabel: t.resultPdfFinancialSourceLabel,

        calcUnavailablePrefix: t.resultPdfCalcUnavailablePrefix,
        disclaimerText: t.resultPdfDisclaimerText,
        shareTextSuffix: t.resultPdfShareTextSuffix,
        platformNotSupportedText: t.resultPdfPlatformNotSupportedText,
        fontLoadErrorText: t.resultPdfFontLoadErrorText,
      );

      final data = ResultPdfData(
        name: _displayName,
        originalName: _originalDisplayName,
        code: widget.item.code,
        marketText: widget.market == Market.kr ? 'KR' : 'US',
        sourceText: widget.market == Market.kr
            ? (isKoLang
                ? '출처: OpenDART 재무 + KIS 시세'
                : 'Source: OpenDART financials + KIS quotes')
            : (isKoLang
                ? '출처: FMP(제공 범위에 따라 값이 비어 있을 수 있음)'
                : 'Source: FMP (some values may be empty depending on coverage)'),
        metaText: _buildPdfMetaText(details: details),
        includeEvaluation: true,
        includeFinancials: true,
        currentPriceText: _fmtMoney(price),
        epsText: _pdfMetricText(eps),
        bpsText: _pdfMetricText(bps),
        dpsText: _pdfMetricText(dps),
        rPctText: '${rPct.toStringAsFixed(1)}%',
        fairPriceText: result != null ? _fmtMoney(result.fairPrice) : null,
        expectedReturnText: result != null
            ? '${result.expectedReturnPct >= 0 ? '+' : ''}${result.expectedReturnPct.toStringAsFixed(1)}%'
            : null,
        gapText: result != null ? '${result.gapPct.toStringAsFixed(1)}%' : null,
        roeText: result != null ? '${result.roePct.toStringAsFixed(2)}%' : null,
        dividendYieldText: result != null
            ? '${result.dividendYieldPct.toStringAsFixed(2)}%'
            : null,
        perText: result != null ? result.per.toStringAsFixed(2) : null,
        pbrText: result != null ? result.pbr.toStringAsFixed(2) : null,
        ratingTitle: rating?.title,
        ratingSummary: rating?.summary,
        calcError: calcError,
        explanationParagraphs: explanationParagraphs,
        financialPeriodText: financialPeriodText,
        revenueText: _pdfMoneyWithUsdRef(details.revenue ?? f.revenue, details),
        opIncomeText: _pdfMoneyWithUsdRef(details.opIncome ?? f.opIncome, details),
        netIncomeText: _pdfMoneyWithUsdRef(details.netIncome ?? f.netIncome, details),
        equityText: _pdfMoneyWithUsdRef(details.equity ?? f.equity, details),
        liabilitiesText: _pdfMoneyWithUsdRef(details.liabilities ?? f.liabilities, details),
        fsSourceText: (f.fsSource ?? '').trim().isEmpty ? '-' : f.fsSource,
        labels: labels,
      );

      final savedPath = await _pdfService.savePdf(data);

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ResultCopy.pdfCanceled(context))),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ResultCopy.pdfStartedFull(context))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ResultCopy.pdfFailed(context, e))),
      );
    }
  }

  // PDF용 설명문
  List<String> _buildPdfExplanationParagraphs({
    required ValuationResult result,
    required ValuationRating? rating,
  }) {
    final parts = <String>[];

    final priceText = _fmtMoney(_parseDouble(_priceCtrl));
    final fairPriceText = _fmtMoney(result.fairPrice);
    final expected = result.expectedReturnPct;
    final expectedText =
        '${expected >= 0 ? '+' : ''}${expected.toStringAsFixed(1)}%';
    final roeText = '${result.roePct.toStringAsFixed(2)}%';
    final roeOverRText = result.roeOverR.toStringAsFixed(2);
    final perText = result.per.toStringAsFixed(2);
    final pbrText = result.pbr.toStringAsFixed(2);

    final fib = _priceFibChart?.positionPct;
    final fibText = fib == null ? null : '${fib.toStringAsFixed(1)}%';

    // 1) 전체 분위기
    if (isKoLang) {
      switch (rating?.level) {
        case RatingLevel.strongBuy:
          parts.add(
            '지금 숫자만 놓고 보면 이 종목은 전반적으로 좋아 보이는 편입니다. 가격은 비교적 싸게 잡히고 있고, 회사의 돈 버는 힘도 괜찮아서 매수 관점에서 긍정적으로 볼 수 있습니다.',
          );
          break;
        case RatingLevel.buy:
          parts.add(
            '지금 숫자만 놓고 보면 이 종목은 다소 싸게 보이는 편입니다. 전체적으로는 괜찮지만, 앞으로도 실적 흐름이 계속 유지되는지는 같이 보는 것이 좋습니다.',
          );
          break;
        case RatingLevel.caution:
          parts.add(
            '지금 주가는 싸게 보일 수는 있지만, 회사의 수익성은 조금 더 조심해서 볼 필요가 있습니다. 가격만 보고 바로 강하게 들어가기보다는 한 번 더 확인하는 편이 좋습니다.',
          );
          break;
        case RatingLevel.avoid:
          parts.add(
            '지금 숫자 기준으로는 가격이 높게 평가되었거나 수익성이 약한 편입니다. 지금은 적극적으로 보기보다는 보수적으로 판단하는 편이 더 맞습니다.',
          );
          break;
        case RatingLevel.neutral:
        default:
          parts.add(
            '지금 이 종목은 아주 싸다고 보기도, 아주 비싸다고 보기도 애매한 상태입니다. 그래서 숫자를 하나씩 천천히 읽어보는 것이 중요합니다.',
          );
          break;
      }
    } else {
      switch (rating?.level) {
        case RatingLevel.strongBuy:
          parts.add(
            'Based on the current numbers, this stock looks attractive overall.',
          );
          break;
        case RatingLevel.buy:
          parts.add(
            'Based on the current numbers, this stock looks somewhat undervalued overall.',
          );
          break;
        case RatingLevel.caution:
          parts.add(
            'The stock may look cheap, but profitability needs a more careful look.',
          );
          break;
        case RatingLevel.avoid:
          parts.add(
            'On the current numbers, valuation may be expensive or profitability may be weak.',
          );
          break;
        case RatingLevel.neutral:
        default:
          parts.add(
            'This stock is in a middle zone right now.',
          );
          break;
      }
    }

    // 2) 기대수익률 / 적정주가
    if (expected >= 20) {
      parts.add(
        isKoLang
            ? '기대수익률은 $expectedText입니다. 현재 주가는 $priceText, 계산된 적정주가는 $fairPriceText입니다. 기대수익률이 플러스이고 폭도 큰 편이라, 계산상으로는 현재 주가보다 적정주가가 더 높게 잡히는 상태라고 볼 수 있습니다.'
            : 'Expected return is $expectedText. The current price is $priceText and the estimated fair price is $fairPriceText. On this calculation, fair value is meaningfully above the current price.',
      );
    } else if (expected >= 0) {
      parts.add(
        isKoLang
            ? '기대수익률은 $expectedText입니다. 현재 주가는 $priceText, 계산된 적정주가는 $fairPriceText입니다. 계산상으로는 아직 상승 여지가 남아 있는 편이지만, 아주 큰 차이라고 보기는 어려울 수 있습니다.'
            : 'Expected return is $expectedText. The current price is $priceText and the estimated fair price is $fairPriceText. There is still upside on this calculation, but the gap may not be very large.',
      );
    } else {
      parts.add(
        isKoLang
            ? '기대수익률은 $expectedText입니다. 현재 주가는 $priceText, 계산된 적정주가는 $fairPriceText입니다. 기대수익률이 마이너스라는 뜻은, 계산상 현재 주가가 적정주가보다 더 높게 거래되고 있을 가능성이 있다는 뜻입니다.'
            : 'Expected return is $expectedText. The current price is $priceText and the estimated fair price is $fairPriceText. A negative expected return suggests the stock may be trading above calculated fair value.',
      );
    }

    // 3) 요구수익률 / ROE / ROE-r
    final roeAction = ResultCopy.roeActionExplain(
      context,
      roe: result.roePct,
      roeOverR: result.roeOverR,
      requiredReturnPct: rPct,
    );

    parts.add(
      isKoLang
          ? '요구수익률은 투자할 때 내가 원하는 기준 수익률이고, 지금은 ${rPct.toStringAsFixed(1)}%입니다. ROE는 $roeText이고, ROE/r는 $roeOverRText입니다. $roeAction'
          : 'Required return is ${rPct.toStringAsFixed(1)}%. ROE is $roeText and ROE/r is $roeOverRText. $roeAction',
    );

    // 4) PER / PBR
    final perExplain = ResultCopy.perLevelExplain(context, result.per);
    final pbrExplain = ResultCopy.pbrLevelExplain(context, result.pbr);
    final perPbrAction = ResultCopy.perPbrActionExplain(
      context,
      per: result.per,
      pbr: result.pbr,
    );

    parts.add(
      isKoLang
          ? 'PER는 $perText이고, PBR은 $pbrText입니다. $perExplain $pbrExplain $perPbrAction'
          : 'PER is $perText and PBR is $pbrText. $perExplain $pbrExplain $perPbrAction',
    );

    // 5) 배당
    parts.add(
      ResultCopy.dividendYieldExplain(context, result.dividendYieldPct),
    );

    // 6) 피보나치
    // if (fib != null) {
    //   String fibExplain;

    //   if (fib >= 80) {
    //     fibExplain = isKoLang
    //         ? '피보나치 위치는 $fibText입니다. 최근 몇 년 흐름 중 높은 구간에 가까운 상태입니다. 여기서는 더 치고 올라갈 힘이 충분한지, 아니면 잠시 쉬어갈 자리인지를 함께 판단하는 것이 좋습니다.'
    //         : 'Fibonacci position is $fibText. The stock is near the upper end of its recent range, so it is worth judging whether it still has momentum or may need a pause.';
    //   } else if (fib >= 60) {
    //     fibExplain = isKoLang
    //         ? '피보나치 위치는 $fibText입니다. 중간 구간을 넘어선 자리지만, 61.8% 안착 전까지는 본격 상단 구간으로 단정하지 않는 편이 좋습니다. 소액 접근 또는 눌림 확인이 더 자연스러운 구간입니다.'
    //         : 'Fibonacci position is $fibText. It is above the middle zone, but before holding above 61.8%, it may be better not to treat it as a full upper-zone breakout.';
    //   } else if (fib >= 40) {
    //     fibExplain = isKoLang
    //         ? '피보나치 위치는 $fibText입니다. 전체 흐름의 중간 지점에 가까운 균형 구간입니다. 방향성이 완전히 정해지지 않은 상태이므로, 다른 수익성 지표와 함께 보는 편이 좋습니다.'
    //         : 'Fibonacci position is $fibText. It is in a balanced middle zone, so it is better to read it together with profitability and valuation signals.';
    //   } else if (fib >= 20) {
    //     fibExplain = isKoLang
    //         ? '피보나치 위치는 $fibText입니다. 비교적 낮은 구간에 있어 가격 부담은 덜한 편입니다. 다만 단순히 싸 보인다는 이유만으로 보기보다, 실적과 반등 흐름이 같이 살아나는지 확인하는 편이 좋습니다.'
    //         : 'Fibonacci position is $fibText. The stock is in a relatively lower zone, but it is still better to confirm improving earnings and price action rather than buying on price alone.';
    //   } else {
    //     fibExplain = isKoLang
    //         ? '피보나치 위치는 $fibText입니다. 최근 몇 년 흐름 중 바닥권에 가까운 상태입니다. 가격은 저렴해 보일 수 있지만, 정말 기회인지 아니면 힘이 약해서 밀린 것인지 구분해서 볼 필요가 있습니다.'
    //         : 'Fibonacci position is $fibText. It is near the bottom of its recent range, so it is important to distinguish a real opportunity from a weak trend.';
    //   }

    //   parts.add(fibExplain);
    // }

    // 7) 마지막 정리
    if (isKoLang) {
      if (rating?.level == RatingLevel.strongBuy ||
          rating?.level == RatingLevel.buy) {
        parts.add(
          '정리하면 지금 이 종목은 가격과 수익성 흐름을 함께 봤을 때 종합적으로 안정감과 수익성을 고루 갖춘 상태입니다. 서두르지 않고 차분히 비중을 늘려가는 전략이 유효해 보입니다.',
        );
      } else if (rating?.level == RatingLevel.caution) {
        parts.add(
          '정리하면 지금 이 종목은 숫자상 싸게 보여서 가격 매력은 있지만 아직은 조심스러운 신호가 섞여 있습니다. 확실한 반등 근거가 나타날 때까지 보수적인 관점을 유지하는 것이 안전합니다.',
        );
      } else if (rating?.level == RatingLevel.avoid) {
        parts.add(
          '정리하면 지금 이 종목은 지금은 지키는 투자가 중요한 시점입니다. 신규 매수보다는 현재 보유한 비중이 적절한지 냉정하게 점검해 보는 것이 좋습니다.',
        );
      } else {
        parts.add(
          '정리하면 지금 이 종목은 당장 강하게 움직이기보다는 관심종목으로 두고 숫자 변화를 더 지켜보는 편이 좋습니다.',
        );
      }
    } else {
      if (rating?.level == RatingLevel.strongBuy ||
          rating?.level == RatingLevel.buy) {
        parts.add(
          'Overall, this looks suitable for gradual buying.',
        );
      } else if (rating?.level == RatingLevel.caution) {
        parts.add(
          'Overall, this may look cheap, but it is better to stay cautious for now.',
        );
      } else if (rating?.level == RatingLevel.avoid) {
        parts.add(
          'Overall, this is better reviewed carefully rather than bought more aggressively.',
        );
      } else {
        parts.add(
          'Overall, this is better watched for now while following future changes in the numbers.',
        );
      }
    }

    return parts;
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