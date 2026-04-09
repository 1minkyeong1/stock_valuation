import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:stock_valuation_app/data/repository/stock_repository.dart';

class PriceFibChartCard extends StatelessWidget {
  final PriceFibChartData data;
  final bool isKoLang;
  final bool isUS;
  final int months;
  final bool loading;
  final String Function(num value) formatMoney;
  final VoidCallback onTapGuide;
  final ValueChanged<int> onSelectMonths;

  const PriceFibChartCard({
    super.key,
    required this.data,
    required this.isKoLang,
    required this.isUS,
    required this.months,
    required this.loading,
    required this.formatMoney,
    required this.onTapGuide,
    required this.onSelectMonths,
  });

  Color get _accent => isUS ? Colors.indigo : Colors.teal;

  @override
  Widget build(BuildContext context) {
    final position = data.positionPct.clamp(0.0, 100.0);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _accent.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withAlpha(45)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                          isKoLang
                              ? '피보나치 지표 (${_fibRangeLabel(months, isKoLang)})'
                              : 'Fibonacci indicators (${_fibRangeLabel(months, isKoLang)})',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onTapGuide,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.error_outline,
                            size: 18,
                            color: _accent.withAlpha(220),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  tooltip: isKoLang ? '기간 선택' : 'Select range',
                  onSelected: (value) {
                    if (value == months) return;
                    onSelectMonths(value);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 12, child: Text('1년')),
                    PopupMenuItem(value: 24, child: Text('2년')),
                    PopupMenuItem(value: 36, child: Text('3년')),
                    PopupMenuItem(value: 48, child: Text('4년')),
                    PopupMenuItem(value: 60, child: Text('5년')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withAlpha(14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _accent.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fibRangeLabel(months, isKoLang),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accent.withAlpha(230),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: _accent.withAlpha(230),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _accent.withAlpha(18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _accent.withAlpha(60)),
              ),
              child: Text(
                '${position.toStringAsFixed(1)}% · ${_fibZoneShort(position, isKoLang)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _accent.withAlpha(230),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _PriceFibLineChart(
                      data: data,
                      isUS: isUS,
                      formatMoney: formatMoney,
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PriceInfoBox(
                    title: isKoLang ? '최저가' : 'Low',
                    value: formatMoney(data.lowestPrice),
                    sub: data.lowestDate ?? '-',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriceInfoBox(
                    title: isKoLang ? '현재가' : 'Current',
                    value: formatMoney(data.currentPrice),
                    sub: data.currentDate ?? '-',
                    highlighted: true,
                    isUS: isUS,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PriceInfoBox(
                    title: isKoLang ? '최고가' : 'High',
                    value: formatMoney(data.highestPrice),
                    sub: data.highestDate ?? '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              isKoLang
                  ? '  느낌표 아이콘을 누르면 보는 방법을 확인할 수 있습니다.'
                  : '  Tap the info icon to see how to read this chart.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriceFibGuideCard extends StatelessWidget {
  final PriceFibChartData data;
  final bool isKoLang;
  final bool isUS;

  const PriceFibGuideCard({
    super.key,
    required this.data,
    required this.isKoLang,
    required this.isUS,
  });

  Color get _accent => isUS ? Colors.indigo : Colors.teal;

  @override
  Widget build(BuildContext context) {
    final p = data.positionPct.clamp(0.0, 100.0);
    final pullback = _fibPullbackFromHighPct(data);

    bool inRange(double from, double to) {
      if (to == 100) return p >= from && p <= to;
      return p >= from && p < to;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: _accent.withAlpha(220)),
              const SizedBox(width: 6),
              Text(
                isKoLang ? '피보나치 그래프 보는 방법' : 'How to read this chart',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKoLang
                ? '0%는 최근 기간 최저가, 100%는 최근 기간 최고가입니다. 최근 고점과 저점 사이의 상대적 위치를 나타냅니다. 과매수/과매도 구간을 파악하는 기술적 지표로 활용하며, 주요 지지선과 저항선을 가늠할 수 있습니다.'
                : '0% is the low of the selected range and 100% is the high. Represents the relative position between recent highs and lows. It serves as a technical indicator to identify overbought or oversold conditions and potential support/resistance levels.',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withAlpha(12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withAlpha(50)),
            ),
            child: Text(
              isKoLang
                  ? '현재 ${p.toStringAsFixed(1)}% · ${_fibZoneLabel(p, isKoLang)} / 고점 대비 약 ${pullback.toStringAsFixed(1)}% 조정'
                  : 'Now ${p.toStringAsFixed(1)}% · ${_fibZoneLabel(p, isKoLang)} / about ${pullback.toStringAsFixed(1)}% below the high',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accent.withAlpha(230),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // 0~20%
          _FibGuideRow(
            rangeText: '0~20%',
            title: isKoLang ? '바닥 다지기' : 'Bottoming out',
            desc: isKoLang
                ? '가격 매력은 높지만, 하락세가 멈추었는지 확인이 필요한 시점입니다.'
                : 'Price is attractive, but check if the decline has stopped first.',
            active: inRange(0, 20),
            isUS: isUS,
          ),
          // 20~40%
          _FibGuideRow(
            rangeText: '20~40%',
            title: isKoLang ? '안정적 매수권' : 'Stable buy zone',
            desc: isKoLang
                ? '낙폭을 회복하며 반등을 준비하는, 분할 매수하기에 편안한 구간입니다.'
                : 'A stable zone to begin building a position for a rebound.',
            active: inRange(20, 40),
            isUS: isUS,
          ),
          // 40~60%
          _FibGuideRow(
            rangeText: '40~60%',
            title: isKoLang ? '균형 잡힌 중립' : 'Balanced neutral',
            desc: isKoLang
                ? '상승과 하락의 힘이 팽팽합니다. 기업의 실제 가치를 함께 참고하세요.'
                : 'Forces are balanced. Consider checking fundamentals alongside the chart.',
            active: inRange(40, 60),
            isUS: isUS,
          ),
          // 60~80%
          _FibGuideRow(
            rangeText: '60~80%',
            title: isKoLang ? '상승 탄력 구간' : 'Upward momentum',
            desc: isKoLang
                ? '에너지가 붙고 있습니다. 61.8% 선을 지지하면 추가 상승이 기대됩니다.'
                : 'Momentum is building. It’s a good sign if it holds above 61.8%.',
            active: inRange(60, 80),
            isUS: isUS,
          ),
          // 80~100%
          _FibGuideRow(
            rangeText: '80~100%',
            title: isKoLang ? '고점 과열 주의' : 'High pressure zone',
            desc: isKoLang
                ? '최고점 부근에 도달했습니다. 서두르기보다 차분히 관망할 때입니다.'
                : 'Near the peak. Time to watch calmly rather than chasing price.',
            active: inRange(80, 100),
            isUS: isUS,
          ),
          const SizedBox(height: 3),
          Text(
            _fibZoneDesc(p, isKoLang),
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey[800],
              height: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withAlpha(40)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: Colors.orange.withAlpha(220),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKoLang ? '매수 실행 힌트' : 'Entry hint',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.withAlpha(230),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _fibActionHint(p, isKoLang),
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final bool highlighted;
  final bool isUS;

  const _PriceInfoBox({
    required this.title,
    required this.value,
    required this.sub,
    this.highlighted = false,
    this.isUS = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isUS ? Colors.indigo : Colors.teal;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlighted ? accent.withAlpha(14) : Colors.white.withAlpha(150),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? accent.withAlpha(70) : Colors.grey.withAlpha(50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: highlighted ? accent.withAlpha(220) : Colors.grey[700],
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: highlighted ? accent.withAlpha(230) : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _FibGuideRow extends StatelessWidget {
  final String rangeText;
  final String title;
  final String desc;
  final bool active;
  final bool isUS;

  const _FibGuideRow({
    required this.rangeText,
    required this.title,
    required this.desc,
    required this.active,
    required this.isUS,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isUS ? Colors.indigo : Colors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: active ? accent.withAlpha(14) : Colors.white.withAlpha(120),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? accent.withAlpha(80) : Colors.grey.withAlpha(40),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: active ? accent.withAlpha(20) : Colors.grey.withAlpha(18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              rangeText,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? accent.withAlpha(230) : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? accent.withAlpha(230) : Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[700],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceFibLineChart extends StatelessWidget {
  final PriceFibChartData data;
  final bool isUS;
  final String Function(num value) formatMoney;

  const _PriceFibLineChart({
    required this.data,
    required this.isUS,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    if (data.points.isEmpty) {
      return const Center(child: Text('-'));
    }

    final accent = isUS ? Colors.indigo : Colors.teal;
    const currentDot = Colors.orange;

    final spots = <FlSpot>[];
    for (int i = 0; i < data.points.length; i++) {
      spots.add(FlSpot(i.toDouble(), data.points[i].close));
    }

    final minY = data.lowestPrice * 0.96;
    final maxY = data.highestPrice * 1.04;
    final lastIndex = (data.points.length - 1).toDouble();

    List<HorizontalLine> fibLines() {
      return data.fibLevels.where((f) {
        return f.ratio == 0.382 ||
            f.ratio == 0.5 ||
            f.ratio == 0.618 ||
            f.ratio == 0.786;
      }).map((f) {
        final isMajor = f.ratio == 0.5 || f.ratio == 0.618;

        return HorizontalLine(
          y: f.price,
          strokeWidth: isMajor ? 1.4 : 1.0,
          dashArray: isMajor ? [4, 3] : [6, 4],
          color: isMajor
              ? accent.withAlpha(95)
              : Colors.blueGrey.withAlpha(90),
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: TextStyle(
              fontSize: 9,
              color: isMajor ? accent.withAlpha(230) : Colors.blueGrey[700],
              fontWeight: isMajor ? FontWeight.w700 : FontWeight.w500,
            ),
            labelResolver: (_) {
              if (f.ratio == 0.5) return '50%';
              return '${(f.ratio * 100).toStringAsFixed(1)}%';
            },
          ),
        );
      }).toList();
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withAlpha(45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withAlpha(55)),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 54,
              interval: (maxY - minY) / 4,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    formatMoney(value),
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= data.points.length) {
                  return const SizedBox.shrink();
                }

                final showIndex = {
                  0,
                  (data.points.length / 2).floor(),
                  data.points.length - 1,
                };

                if (!showIndex.contains(i)) {
                  return const SizedBox.shrink();
                }

                final ym = data.points[i].ym;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    ym.length >= 7 ? ym.substring(2) : ym,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: fibLines(),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.white.withAlpha(245),
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltipMargin: 10,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final i = spot.x.round();
                if (i < 0 || i >= data.points.length) return null;
                final p = data.points[i];

                return LineTooltipItem(
                  '${p.ym}\n${formatMoney(p.close)}',
                  const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.18,
            color: accent.withAlpha(230),
            barWidth: 2.8,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: accent.withAlpha(26),
            ),
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                return spot.x == lastIndex;
              },
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5.8,
                  color: currentDot,
                  strokeWidth: 2.2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _fibRangeLabel(int months, bool isKoLang) {
  switch (months) {
    case 12:
      return isKoLang ? '1년' : '1Y';
    case 24:
      return isKoLang ? '2년' : '2Y';
    case 36:
      return isKoLang ? '3년' : '3Y';
    case 48:
      return isKoLang ? '4년' : '4Y';
    case 60:
      return isKoLang ? '5년' : '5Y';
    default:
      return isKoLang ? '${(months / 12).round()}년' : '${(months / 12).round()}Y';
  }
}

String _fibZoneShort(double p, bool isKoLang) {
  if (p >= 80) return isKoLang ? '고점 주의 구간' : 'High Alert';
  if (p >= 60) return isKoLang ? '상승 탄력 구간' : 'Bullish Zone'; // 61.8%의 긍정적 의미 반영
  if (p >= 40) return isKoLang ? '중간 지점' : 'Middle Zone';
  if (p >= 20) return isKoLang ? '매수 검토권' : 'Buy Interest';
  return isKoLang ? '바닥 다지기' : 'Bottom Support';
}

String _fibZoneLabel(double p, bool isKoLang) {
  if (p < 20) return isKoLang ? '바닥 다지기' : 'Bottoming out';
  if (p < 40) return isKoLang ? '매력적인 저가권' : 'Attractive low';
  if (p < 60) return isKoLang ? '적정 가격대' : 'Fair value zone';
  if (p < 80) return isKoLang ? '상승 탄력 구간' : 'Upward momentum';
  return isKoLang ? '고점 부담 구간' : 'High pressure zone';
}

String _fibZoneDesc(double p, bool isKoLang) {
  if (p < 20) {
    return isKoLang
        ? '현재 바닥을 다지는 과정에 있습니다. 급하게 뛰어들기보다 하락이 완전히 멈춘 것을 확인한 뒤 움직여도 늦지 않습니다.'
        : 'The price is bottoming out. Instead of rushing in, wait for clear signs that the decline has fully stopped.';
  }
  if (p < 40) {
    return isKoLang
        ? '반등의 기틀을 마련한 안정적인 지점입니다. 본격적인 상승을 염두에 두고 비중을 조금씩 채워가기 좋은 시기입니다.'
        : 'A stable foundation for a rebound. It is a good time to gradually build your position for potential upside.';
  }
  if (p < 60) {
    return isKoLang
        ? '방향성을 탐색하는 균형 구간입니다. 지금은 차트의 움직임뿐만 아니라 기업의 실적 같은 기초 체력을 함께 점검할 때입니다.'
        : 'A balanced zone searching for direction. Check both the chart and the company\'s fundamental strength now.';
  }
  if (p < 80) {
    return isKoLang
        ? '상승 흐름이 견고해지는 구간입니다. 61.8% 선을 든든한 버팀목 삼아, 추세가 이어지는지 관찰하며 대응해 보세요.'
        : 'The upward trend is strengthening. Watch if the momentum continues, using the 61.8% level as a solid support.';
  }
  return isKoLang
      ? '상승의 정점에 가까워진 과열 구간입니다. 신규 진입은 잠시 미뤄두고, 조정이 왔을 때 더 좋은 가격을 노리는 것이 현명합니다.'
      : 'Near the peak of the rally. It is wiser to hold off on new entries and wait for a better price during a pullback.';
}

String _fibActionHint(double p, bool isKoLang) {
  if (p < 20) {
    return isKoLang
        ? '성급한 매수보다는 바닥을 확인하며 조금씩 모아가는 전략이 유효합니다.'
        : 'Instead of rushing, consider a strategy of collecting slowly as it bottoms.';
  }
  if (p < 40) {
    return isKoLang
        ? '본격적인 매수를 고려하기 가장 편안한 타이밍 중 하나입니다.'
        : 'One of the most comfortable times to consider a primary entry.';
  }
  if (p < 60) {
    return isKoLang
        ? '서두를 필요 없는 구간입니다. 비중을 조절하며 흐름을 관찰해 보세요.'
        : 'No need to rush. Observe the trend while managing your position size.';
  }
  if (p < 80) {
    return isKoLang
        ? '수익을 극대화할 수 있는 자리입니다. 61.8%를 지지선 삼아 대응해 보세요.'
        : 'A spot to maximize gains. Use 61.8% as a support level for your strategy.';
  }
  return isKoLang
      ? '조정이 올 때를 기다려 더 좋은 가격에 진입하는 것이 보수적이고 안전합니다.'
      : 'Waiting for a pullback to get a better price is a safer, more conservative approach.';
}

double _fibPullbackFromHighPct(PriceFibChartData data) {
  final v = 100.0 - data.positionPct;
  return v.clamp(0.0, 100.0);
}