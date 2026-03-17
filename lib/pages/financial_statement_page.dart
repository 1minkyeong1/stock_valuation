import 'dart:async';
import 'package:flutter/material.dart';

import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';
import 'package:stock_valuation_app/data/repository/stock_repository.dart';
import 'package:stock_valuation_app/utils/number_format.dart';
import 'package:stock_valuation_app/utils/search_alias.dart';

class FinancialStatementPage extends StatefulWidget {
  final RepoHub hub;
  final Market market;
  final StockSearchItem item;

  /// ResultPage에서 이미 받아온 fundamentals(즉시 표시용)
  final StockFundamentals? initialFundamentals;

  const FinancialStatementPage({
    super.key,
    required this.hub,
    required this.market,
    required this.item,
    this.initialFundamentals,
  });

  @override
  State<FinancialStatementPage> createState() => _FinancialStatementPageState();
}

class _FinancialStatementPageState extends State<FinancialStatementPage> {
  bool _loading = false;
  String? _error;

  StockFinancialDetails? _details;

  Timer? _slowHintTimer;
  bool _showSlowHint = false;


  @override
  void initState() {
    super.initState();

    if (widget.initialFundamentals != null) {
      _details = StockFinancialDetails(
        current: widget.initialFundamentals!,
      );
    }

    _reload();
  }

  @override
  void dispose() {
    _slowHintTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    _slowHintTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _showSlowHint = false;
    });

    _slowHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _showSlowHint = true;
        });
      }
    });

    try {
      final details = await widget.hub.getFinancialDetails(
        widget.market,
        widget.item.code,
        targetYear: null,
      );

      _slowHintTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _details = details;
        _loading = false;
        _showSlowHint = false;
      });
    } catch (e) {
      _slowHintTimer?.cancel();

      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _showSlowHint = false;
      });
    }
  }

  bool get _isKR => widget.market == Market.kr;

  bool get _isUS => widget.market == Market.us;

  String get _displayName {
    if (!_isUS) return widget.item.name;

    final ko = SearchAlias.usPrimaryKoName(widget.item.code);
    return ko ?? widget.item.name;
  }

  String? get _originalUsName {
    if (!_isUS) return null;

    final ko = SearchAlias.usPrimaryKoName(widget.item.code);
    final en = widget.item.name.trim();

    if (ko == null || en.isEmpty || ko == en) return null;
    return en;
  }

  bool get _isLand => MediaQuery.of(context).orientation == Orientation.landscape;

  String _fmtBasDt(String yyyymmdd) {
    final s = yyyymmdd.trim();
    if (s.length != 8) return s;
    return "${s.substring(0, 4)}-${s.substring(4, 6)}-${s.substring(6, 8)}";
  }

  String _fmtMoney(num? v) {
    if (v == null) return '-';
    return _isKR ? fmtWon(v) : fmtUsd(v);
  }

  String _metaLine(StockFundamentals f) {
    final parts = <String>[];

    final pl = f.periodLabel?.trim();
    if (pl != null && pl.isNotEmpty) parts.add(pl);

    final bd = f.basDt?.trim();
    if (bd != null && bd.isNotEmpty) parts.add("기준일 ${_fmtBasDt(bd)}");

    return parts.join(" · ");
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName;
    final code = widget.item.code;

    final pad = EdgeInsets.all(_isLand ? 12 : 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$name 재무제표",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: "새로고침",
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // SafeArea + minimum padding으로 좌/우 “잘림(노치/라운드)” 방지
      body: SafeArea(
        minimum: pad,
        child: _error != null
            ? _errorView()
            : _body(name: name, code: code),
      ),
    );
  }

  Widget _errorView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("불러오기 실패: $_error", style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _reload,
          child: const Text("다시 시도"),
        ),
      ],
    );
  }

  Widget _body({required String name, required String code}) {
    final details = _details;
    final f = details?.current ?? widget.initialFundamentals;

    if (f == null) {
      return _loading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Center(child: CircularProgressIndicator()),
                if (_showSlowHint) ...[
                  const SizedBox(height: 14),
                  const Text(
                    "재무제표 계산 중...",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            )
          : const Center(child: Text("데이터가 없습니다."));
    }

    final hasAny = details?.revenue != null ||
        details?.opIncome != null ||
        details?.netIncome != null ||
        details?.equity != null ||
        details?.liabilities != null;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (_loading && _showSlowHint) ...[
          _loadingHintCard(),
          const SizedBox(height: 12),
        ],

        _headerCard(name: name, code: code, f: f),
        const SizedBox(height: 12),

        if (!hasAny) _emptyHintCard() else _fsSummaryCard(details!),
        const SizedBox(height: 12),

        if (details != null) ...[
          _buffettAssistCard(details),
          const SizedBox(height: 12),
          _trendCard(details),
          const SizedBox(height: 12),
          _stabilityCard(details),
          const SizedBox(height: 12),
        ],

        _noteCard(),
      ],
    );
  }

  // 로딩 안내카드
  Widget _loadingHintCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.withAlpha(18),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "재무제표 계산 중...",
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 헤더 카드
  Widget _headerCard({
    required String name,
    required String code,
    required StockFundamentals f,
  }) {
    final meta = _metaLine(f);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$name ($code)",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_originalUsName != null) ...[
                    const TextSpan(text: " · "),
                    TextSpan(
                      text: _originalUsName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              widget.market == Market.kr
                  ? "출처: OpenDART 재무 + KIS 시세"
                  : "출처: FMP(제공 범위에 따라 값이 비어 있을 수 있음)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                meta,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyHintCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          "재무 원본 금액(매출/영업이익/순이익/자본총계/부채총계)을 가져오지 못했습니다.\n"
          "공시 반영 전이거나(승인/갱신 대기), 항목명이 달라 파싱이 실패했을 수 있어요.\n\n"
          "우측 상단 새로고침을 눌러 다시 시도해보세요.",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _fsSummaryCard(StockFinancialDetails d) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("재무 요약(원본)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _row("매출", _fmtMoney(d.revenue), helper: "손익계산서"),
            _row("영업이익", _fmtMoney(d.opIncome), helper: "손익계산서"),
            _row("순이익", _fmtMoney(d.netIncome), helper: "EPS 계산 근거"),
            _row("자본총계", _fmtMoney(d.equity), helper: "BPS 계산 근거"),
            _row("부채총계", _fmtMoney(d.liabilities), helper: "재무상태표"),
          ],
        ),
      ),
    );
  }

  // Widget _epsBpsDpsCard(StockFundamentals f) {
  //   String fmtMetric(num v) =>
  //       _isKR ? fmtWonDecimal(v, fractionDigits: 0) : fmtUsdDecimal(v, fractionDigits: 2);

  //   return Card(
  //     elevation: 0,
  //     child: Padding(
  //       padding: const EdgeInsets.all(14),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text("현재 계산에 사용된 값", style: TextStyle(fontWeight: FontWeight.bold)),
  //           const SizedBox(height: 10),
  //           _row("EPS", fmtMetric(f.eps)),
  //           _row("BPS", fmtMetric(f.bps)),
  //           _row("DPS", fmtMetric(f.dps)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String _fmtMetricValue(num? v) {
    if (v == null) return '-';
    return _isKR
        ? fmtWonDecimal(v, fractionDigits: 0)
        : fmtUsdDecimal(v, fractionDigits: 2);
  }

  String _fmtPercent(double? v, {int digits = 1}) {
    if (v == null) return '-';
    return '${v.toStringAsFixed(digits)}%';
  }

  Widget _miniMetricCard({
    required String title,
    required String value,
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sub != null && sub.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _subSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _historyWrap(
    List<YearMetric> items,
    String Function(num? v) formatter,
  ) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          "-",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        return Container(
          constraints: const BoxConstraints(minWidth: 108),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${e.year}년",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatter(e.value),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 버핏식 보조 지표 카드
  Widget _buffettAssistCard(StockFinancialDetails d) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("버핏식 보조 지표", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    title: "3년 평균 EPS",
                    value: _fmtMetricValue(d.epsAvg3y),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniMetricCard(
                    title: "5년 평균 ROE",
                    value: _fmtPercent(d.roeAvg5y),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 장기 추이 카드
  Widget _trendCard(StockFinancialDetails d) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("장기 추이", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 13),

            _subSectionTitle("연도별 EPS"),
            _historyWrap(d.epsHistory, _fmtMetricValue),

            const SizedBox(height: 16),

            _subSectionTitle("연도별 ROE"),
            _historyWrap(d.roeHistory, (v) => _fmtPercent(v is num ? v.toDouble() : null)),
          ],
        ),
      ),
    );
  }

  // 안정성 카드
  Widget _stabilityCard(StockFinancialDetails d) {
    String lossText() {
      if (d.lossYears.isEmpty) return '없음';
      return d.lossYears.map((e) => '$e년').join(', ');
    }

    String dividendText() {
      if (d.hasDividend == null) return '-';
      return d.hasDividend! ? '있음' : '없음';
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("안정성", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    title: "적자 여부",
                    value: lossText(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniMetricCard(
                    title: "부채비율",
                    value: _fmtPercent(d.debtRatio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _miniMetricCard(
              title: "최근 배당",
              value: dividendText(),
            ),
          ],
        ),
      ),
    );
  }

  // 노트 카드
  Widget _noteCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.withAlpha(18),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          "※ 안내\n"
          "- EPS/BPS/DPS는 적정가 계산에 직접 사용된 값입니다.\n"
          "- 장기 지표는 종목의 질을 길게 보기 위한 참고 정보입니다.\n"
          "- 공시 반영 시점이나 데이터 제공 범위에 따라 일부 값은 비어 있을 수 있습니다.",
          style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.45),
        ),
      ),
    );
  }

  // 가로에서 숫자/통화 문자열이 길어도 “오른쪽 끝”이 안 잘리도록
  Widget _row(String label, String value, {String? helper}) {
    final mq = MediaQuery.of(context);
    final ts = mq.textScaler.scale(1.0).clamp(1.0, 2.0);
    final bool vertical = ts >= 1.35;

    final labelStyle = TextStyle(color: Colors.grey[700], fontSize: 12);
    final helperStyle = TextStyle(color: Colors.grey[600], fontSize: 11);
    final valueStyle = const TextStyle(fontWeight: FontWeight.w700);

    Widget valueWidget() {
      // '-' 같은 짧은 값은 그냥
      final v = value.trim();
      if (v.isEmpty || v == '-') {
        return Text(value, style: valueStyle, textAlign: TextAlign.right);
      }

      // ✅ 핵심: 잘림(...) 대신 “영역 안에 들어오도록” 자동 축소
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.right,
          style: valueStyle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (helper != null) ...[
                  const SizedBox(height: 2),
                  Text(helper, style: helperStyle),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    // 세로형에서는 값이 충분히 크도록 전체폭 활용
                    width: double.infinity,
                    child: valueWidget(),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: labelStyle),
                      if (helper != null) ...[
                        const SizedBox(height: 2),
                        Text(helper, style: helperStyle),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 가로형: 오른쪽 값은 남는 공간에서 scaleDown
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: valueWidget(),
                  ),
                ),
              ],
            ),
    );
  }
}