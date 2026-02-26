import 'package:flutter/material.dart';

import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';
import 'package:stock_valuation_app/data/repository/stock_repository.dart';
import 'package:stock_valuation_app/utils/number_format.dart';

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

  StockFundamentals? _f;

  @override
  void initState() {
    super.initState();
    _f = widget.initialFundamentals;

    if (_f == null) {
      _reload();
    }
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final f = await widget.hub.getFundamentals(
        widget.market,
        widget.item.code,
        targetYear: null,
      );

      if (!mounted) return;
      setState(() {
        _f = f;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _isKR => widget.market == Market.kr;

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

    if (f.year != null) parts.add("${f.year}년");
    if (f.fsDiv != null && f.fsDiv!.trim().isNotEmpty) parts.add("fsDiv ${f.fsDiv}");
    if (f.reprtCode != null && f.reprtCode!.trim().isNotEmpty) parts.add("reprt ${f.reprtCode}");

    return parts.join(" · ");
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.item.name;
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

      // ✅ SafeArea + minimum padding으로 좌/우 “잘림(노치/라운드)” 방지
      body: SafeArea(
        minimum: pad,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null ? _errorView() : _body(name: name, code: code)),
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
    final f = _f;

    if (f == null) {
      return const Center(child: Text("데이터가 없습니다."));
    }

    final hasAny = f.revenue != null ||
        f.opIncome != null ||
        f.netIncome != null ||
        f.equity != null;

    return ListView(
      padding: EdgeInsets.zero, // ✅ SafeArea(minimum)에서 패딩 담당
      children: [
        _headerCard(name: name, code: code, f: f),
        const SizedBox(height: 12),
        if (!hasAny) _emptyHintCard() else _fsSummaryCard(f),
        const SizedBox(height: 12),
        _epsBpsDpsCard(f),
        const SizedBox(height: 12),
        _noteCard(),
      ],
    );
  }

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
            Text(
              "$name ($code)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.market == Market.kr
                  ? "출처: OpenDART 재무 + KIS 시세(별도 화면)"
                  : "출처: FMP(제공 범위에 따라 값이 비어 있을 수 있음)",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 6),
              // ✅ 메타는 길어도 줄바꿈 허용
              Text(meta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            if (f.fsSource != null && f.fsSource!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              // ✅ 너무 길면 2줄까지만 + 말줄임
              Text(
                "fsSource: ${f.fsSource}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
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
          "재무 원본 금액(매출/영업이익/순이익/자본총계)을 가져오지 못했습니다.\n"
          "공시 반영 전이거나(승인/갱신 대기), 항목명이 달라 파싱이 실패했을 수 있어요.\n\n"
          "우측 상단 새로고침을 눌러 다시 시도해보세요.",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _fsSummaryCard(StockFundamentals f) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("재무 요약(원본)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _row("매출", _fmtMoney(f.revenue), helper: "손익계산서"),
            _row("영업이익", _fmtMoney(f.opIncome), helper: "손익계산서"),
            _row("순이익", _fmtMoney(f.netIncome), helper: "EPS 계산 근거"),
            _row("자본총계", _fmtMoney(f.equity), helper: "BPS 계산 근거"),
          ],
        ),
      ),
    );
  }

  Widget _epsBpsDpsCard(StockFundamentals f) {
    String fmtMetric(num v) =>
        _isKR ? fmtWonDecimal(v, fractionDigits: 0) : fmtUsdDecimal(v, fractionDigits: 2);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("지표(EPS/BPS/DPS)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _row("EPS", fmtMetric(f.eps)),
            _row("BPS", fmtMetric(f.bps)),
            _row("DPS", fmtMetric(f.dps)),
          ],
        ),
      ),
    );
  }

  Widget _noteCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.withAlpha(18),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          "※ 주의\n"
          "- 재무 원본 금액은 공시 반영 타이밍/파싱 규칙에 따라 비어 있을 수 있습니다.\n"
          "- EPS/BPS/DPS는 적정가 계산에 직접 사용되며, 원본 금액은 참고용입니다.",
          style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.45),
        ),
      ),
    );
  }

  // ✅ 가로에서 숫자/통화 문자열이 길어도 “오른쪽 끝”이 안 잘리도록:
  // - value 영역 maxWidth 제한 + 말줄임
  // - textAlign right
  Widget _row(String label, String value, {String? helper}) {
    final valueMaxW = _isLand ? 260.0 : 180.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
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
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: valueMaxW),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}