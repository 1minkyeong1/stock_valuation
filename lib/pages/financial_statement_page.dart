import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:stock_valuation_app/models/market.dart';
import 'package:stock_valuation_app/data/stores/repo_hub.dart';
import 'package:stock_valuation_app/data/repository/stock_repository.dart';
import 'package:stock_valuation_app/utils/number_format.dart';
import 'package:stock_valuation_app/utils/search_alias.dart';
import 'package:stock_valuation_app/services/financial_statement_pdf_service.dart';
import 'package:stock_valuation_app/copy/financial_statement_copy.dart';
import 'package:stock_valuation_app/l10n/app_localizations.dart';


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

  // 번역
  AppLocalizations get t => AppLocalizations.of(context)!;
  bool get isKoLang => FinancialStatementCopy.isKo(context);

  final _financialPdfService = FinancialStatementPdfService();

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

  // 업종 헬퍼
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

  String _industryMetaText(String industry) {
    return isKoLang ? '업종: $industry' : 'Industry: $industry';
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

  String _reportedCurrencyOf(StockFinancialDetails d) {
    final code = (d.reportedCurrency ?? '').trim().toUpperCase();
    return code.isEmpty ? 'USD' : code;
  }

  String _fmtRawStatementMoney(num? v, {required String currencyCode}) {
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

  String _reportedCurrencyText(String currencyCode) {
    return isKoLang
        ? '보고 통화: $currencyCode'
        : 'Reporting currency: $currencyCode';
  }

  String? _usdReferenceText(num? raw, StockFinancialDetails d) {
    if (!_isUS || raw == null) return null;

    final currency = _reportedCurrencyOf(d);
    final rate = d.fxRateToUsd;

    if (currency == 'USD' || rate == null || rate <= 0) return null;

    final usd = raw.toDouble() * rate;
    final usdText = _fmtRawStatementMoney(usd, currencyCode: 'USD');

    return isKoLang
        ? 'USD 환산 참고값: $usdText'
        : 'USD reference value: $usdText';
  }

  String _metaLine(StockFundamentals f) {
    final parts = <String>[];

    final pl = f.periodLabel?.trim();
    if (pl != null && pl.isNotEmpty) parts.add(pl);

    final bd = f.basDt?.trim();
    if (bd != null && bd.isNotEmpty) {
      parts.add(FinancialStatementCopy.metaDate(context, _fmtBasDt(bd)));
    }

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
          FinancialStatementCopy.pageTitle(context, name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: FinancialStatementCopy.pdfSaveTooltip(context),
            onPressed: _saveFinancialStatementPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: FinancialStatementCopy.reloadTooltip(context),
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      // SafeArea + minimum padding으로 좌/우 “잘림(노치/라운드)” 방지
      body: SafeArea(
        top: false,
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
        Text(
          FinancialStatementCopy.loadFailed(context, _error ?? '-'),
          style: const TextStyle(color: Colors.red),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _reload,
          child: Text(FinancialStatementCopy.retry(context)),
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
                  Text(
                    FinancialStatementCopy.loadingHint(context),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            )
          : Center(child: Text(FinancialStatementCopy.noData(context)));
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                FinancialStatementCopy.loadingHint(context),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
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
    final industry = _industryText;

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
                  if (_originalDisplayName != null) ...[
                    const TextSpan(text: " · "),
                    TextSpan(
                      text: _originalDisplayName!,
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
            if (industry != null && industry.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _industryMetaText(industry),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],

            const SizedBox(height: 8),
            Text(
              FinancialStatementCopy.sourceText(context, widget.market),
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
          FinancialStatementCopy.emptyHint(context),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _fsSummaryCard(StockFinancialDetails d) {
    final rawCurrency = _isUS ? _reportedCurrencyOf(d) : 'KRW';

    String rawMoney(num? v) {
      if (_isKR) return _fmtMoney(v);
      return _fmtRawStatementMoney(v, currencyCode: rawCurrency);
    }

    // String helperWithUsdRef(String base, num? raw) {
    //   final ref = _usdReferenceText(raw, d);
    //   if (ref == null) return base;
    //   return '$base\n$ref';
    // }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FinancialStatementCopy.fsSummaryTitle(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (_isUS)
              Text(
                _reportedCurrencyText(rawCurrency),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 10),
            _row(
              FinancialStatementCopy.revenue(context),
              rawMoney(d.revenue),
              helper: FinancialStatementCopy.incomeStatement(context),
              valueSub: _usdReferenceText(d.revenue, d),
            ),
            _row(
              FinancialStatementCopy.opIncome(context),
              rawMoney(d.opIncome),
              helper: FinancialStatementCopy.incomeStatement(context),
              valueSub: _usdReferenceText(d.opIncome, d),
            ),
            _row(
              FinancialStatementCopy.netIncome(context),
              rawMoney(d.netIncome),
              helper: FinancialStatementCopy.epsBasis(context),
              valueSub: _usdReferenceText(d.netIncome, d),
            ),
            _row(
              FinancialStatementCopy.equity(context),
              rawMoney(d.equity),
              helper: FinancialStatementCopy.bpsBasis(context),
              valueSub: _usdReferenceText(d.equity, d),
            ),
            _row(
              FinancialStatementCopy.liabilities(context),
              rawMoney(d.liabilities),
              helper: FinancialStatementCopy.balanceSheet(context),
              valueSub: _usdReferenceText(d.liabilities, d),
            ),
          ],
        ),
      ),
    );
  }

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
                FinancialStatementCopy.yearLabel(context, e.year),
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
            Text(FinancialStatementCopy.buffettAssistTitle(context), style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    title: FinancialStatementCopy.avg3yEps(context),
                    value: _fmtMetricValue(d.epsAvg3y),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniMetricCard(
                    title: FinancialStatementCopy.avg5yRoe(context),
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
            Text(FinancialStatementCopy.trendTitle(context), style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 13),

            _subSectionTitle(FinancialStatementCopy.yearlyEps(context)),
            _historyWrap(d.epsHistory, _fmtMetricValue),

            const SizedBox(height: 16),

            _subSectionTitle(FinancialStatementCopy.yearlyRoe(context)),
            _historyWrap(d.roeHistory, (v) => _fmtPercent(v is num ? v.toDouble() : null)),
          ],
        ),
      ),
    );
  }

  // 안정성 카드
  Widget _stabilityCard(StockFinancialDetails d) {
    String lossText() {
      if (d.lossYears.isEmpty) return FinancialStatementCopy.none(context);
      return d.lossYears.map((e) => FinancialStatementCopy.yearLabel(context, e)).join(', ');
    }

    String dividendText() {
      if (d.hasDividend == null) return '-';
      return d.hasDividend!
          ? FinancialStatementCopy.yes(context)
          : FinancialStatementCopy.no(context);
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(FinancialStatementCopy.stabilityTitle(context), style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _miniMetricCard(
                    title: FinancialStatementCopy.lossYearsTitle(context),
                    value: lossText(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _miniMetricCard(
                    title: FinancialStatementCopy.debtRatioTitle(context),
                    value: _fmtPercent(d.debtRatio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _miniMetricCard(
              title: FinancialStatementCopy.recentDividendTitle(context),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          FinancialStatementCopy.noteText(context),
          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.45),
        ),
      ),
    );
  }

  // 가로에서 숫자/통화 문자열이 길어도 “오른쪽 끝”이 안 잘리도록
  Widget _row(String label, String value, {String? helper, String? valueSub}) {
    final mq = MediaQuery.of(context);
    final ts = mq.textScaler.scale(1.0).clamp(1.0, 2.0);
    final bool vertical = ts >= 1.35;

    final labelStyle = TextStyle(color: Colors.grey[700], fontSize: 12);
    final helperStyle = TextStyle(color: Colors.grey[600], fontSize: 11);
    final valueStyle = const TextStyle(fontWeight: FontWeight.w700);
    final valueSubStyle = TextStyle(color: Colors.grey[600], fontSize: 11);

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
                  // 세로형
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        valueWidget(),
                        if (valueSub != null && valueSub.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            valueSub,
                            style: valueSubStyle,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ],
                    ),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        valueWidget(),
                        if (valueSub != null && valueSub.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            valueSub,
                            style: valueSubStyle,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _pdfFsText(num? v) {
    if (v == null) return '-';
    return _isKR ? fmtWon(v) : fmtUsd(v);
  }

  String _pdfSummaryMoneyWithUsdRef(num? raw, StockFinancialDetails? d) {
    if (raw == null) return '-';

    if (_isKR || d == null) {
      return _pdfFsText(raw);
    }

    final rawCurrency = _reportedCurrencyOf(d);
    final rawText = _fmtRawStatementMoney(raw, currencyCode: rawCurrency);
    final usdRef = _usdReferenceText(raw, d);

    if (usdRef == null || usdRef.trim().isEmpty) {
      return rawText;
    }

    return '$rawText\n$usdRef';
  }

  String? _financialPdfMetaText(
    StockFundamentals f,
    StockFinancialDetails? d,
  ) {
    final lines = <String>[];

    final industry = _industryText;
    if (industry != null && industry.trim().isNotEmpty) {
      lines.add(isKoLang ? '업종: $industry' : 'Industry: $industry');
    }

    final meta = _metaLine(f);
    if (meta.isNotEmpty) {
      lines.add(meta);
    }

    if (_isUS && d != null) {
      final currency = _reportedCurrencyOf(d);
      if (currency.isNotEmpty) {
        lines.add(_reportedCurrencyText(currency));
      }
    }

    final fsSource = f.fsSource?.trim();
    if (fsSource != null && fsSource.isNotEmpty) {
      lines.add(FinancialStatementCopy.fsSourceLabel(context, fsSource));
    }

    return lines.isEmpty ? null : lines.join('\n');
  }

  String _financialPeriodText(StockFundamentals f) {
    final pl = f.periodLabel?.trim();
    if (pl != null && pl.isNotEmpty) return pl;

    final bd = f.basDt?.trim();
    if (bd != null && bd.isNotEmpty) return _fmtBasDt(bd);

    if (f.year != null) return FinancialStatementCopy.yearLabel(context, f.year!);

    return '-';
  }

  Future<void> _saveFinancialStatementPdf() async {
    final f = _details?.current ?? widget.initialFundamentals;
    final d = _details;

    if (f == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FinancialStatementCopy.pdfNoData(context))),
      );
      return;
    }

    try {
      final labels = FinancialStatementPdfLabels(
        documentTitleSuffix: t.fsPdfDocumentTitleSuffix,
        summarySectionTitle: t.fsPdfSummarySectionTitle,
        buffettAssistSectionTitle: t.fsPdfBuffettAssistSectionTitle,
        trendSectionTitle: t.fsPdfTrendSectionTitle,
        stabilitySectionTitle: t.fsPdfStabilitySectionTitle,
        periodLabel: t.fsPdfPeriodLabel,
        revenueLabel: t.fsPdfRevenueLabel,
        opIncomeLabel: t.fsPdfOpIncomeLabel,
        netIncomeLabel: t.fsPdfNetIncomeLabel,
        equityLabel: t.fsPdfEquityLabel,
        liabilitiesLabel: t.fsPdfLiabilitiesLabel,
        financialSourceLabel: t.fsPdfFinancialSourceLabel,
        avg3yEpsLabel: t.fsPdfAvg3yEpsLabel,
        avg5yRoeLabel: t.fsPdfAvg5yRoeLabel,
        yearlyEpsLabel: t.fsPdfYearlyEpsLabel,
        yearlyRoeLabel: t.fsPdfYearlyRoeLabel,
        lossYearsLabel: t.fsPdfLossYearsLabel,
        debtRatioLabel: t.fsPdfDebtRatioLabel,
        recentDividendLabel: t.fsPdfRecentDividendLabel,
        disclaimerText: t.fsPdfDisclaimerText,
        shareTextSuffix: t.fsPdfShareTextSuffix,
        platformNotSupportedText: t.fsPdfPlatformNotSupportedText,
        fontLoadErrorText: t.fsPdfFontLoadErrorText,
      );

      final data = FinancialStatementPdfData(
        name: _displayName,
        originalName: _originalDisplayName,
        code: widget.item.code,
        marketText: _isKR ? 'KR' : 'US',
        sourceText: FinancialStatementCopy.pdfSourceText(context, widget.market),
        metaText: _financialPdfMetaText(f, d),
        periodText: _financialPeriodText(f),
        revenueText: _pdfSummaryMoneyWithUsdRef(d?.revenue ?? f.revenue, d),
        opIncomeText: _pdfSummaryMoneyWithUsdRef(d?.opIncome ?? f.opIncome, d),
        netIncomeText: _pdfSummaryMoneyWithUsdRef(d?.netIncome ?? f.netIncome, d),
        equityText: _pdfSummaryMoneyWithUsdRef(d?.equity ?? f.equity, d),
        liabilitiesText: _pdfSummaryMoneyWithUsdRef(d?.liabilities ?? f.liabilities, d),
        fsSourceText: (f.fsSource ?? '').trim().isEmpty ? '-' : f.fsSource!,

        epsAvg3yText: d == null ? '-' : _pdfMetricValue(d.epsAvg3y),
        roeAvg5yText: d == null ? '-' : _pdfPercent(d.roeAvg5y),

        epsHistoryLines: d == null
            ? const []
            : _yearMetricLines(d.epsHistory, _pdfMetricValue),
        roeHistoryLines: d == null
            ? const []
            : _yearMetricLines(
                d.roeHistory,
                (v) => _pdfPercent(v is num ? v.toDouble() : null),
              ),

        lossYearsText: d == null ? '-' : _lossYearsText(d),
        debtRatioText: d == null ? '-' : _pdfPercent(d.debtRatio),
        hasDividendText: d == null ? '-' : _hasDividendText(d),
        labels: labels,
      );

      final savedPath = await _financialPdfService.savePdf(data);

      if (!mounted) return;

      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FinancialStatementCopy.pdfCanceled(context))),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FinancialStatementCopy.pdfStarted(context))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(FinancialStatementCopy.pdfFailed(context, e))),
      );
    }
  }

  String _pdfMetricValue(num? v) {
    if (v == null) return '-';
    return _isKR
        ? fmtWonDecimal(v, fractionDigits: 0)
        : fmtUsdDecimal(v, fractionDigits: 2);
  }

  String _pdfPercent(double? v, {int digits = 1}) {
    if (v == null) return '-';
    return '${v.toStringAsFixed(digits)}%';
  }

  List<String> _yearMetricLines(
    List<YearMetric> items,
    String Function(num? v) formatter,
  ) {
    return items
        .map((e) => '${FinancialStatementCopy.yearLabel(context, e.year)}\n${formatter(e.value)}')
        .toList();
  }

  String _lossYearsText(StockFinancialDetails d) {
    if (d.lossYears.isEmpty) return FinancialStatementCopy.none(context);
    return d.lossYears.map((e) => FinancialStatementCopy.yearLabel(context, e)).join(', ');
  }

  String _hasDividendText(StockFinancialDetails d) {
    if (d.hasDividend == null) return '-';
    return d.hasDividend!
        ? FinancialStatementCopy.yes(context)
        : FinancialStatementCopy.no(context);
  }
}