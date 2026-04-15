import 'package:flutter/material.dart';
import 'package:stock_valuation_app/copy/result_copy.dart';
import 'package:stock_valuation_app/models/valuation_rating.dart';
import 'package:stock_valuation_app/models/valuation_result.dart';

class ResultExplanationCard extends StatelessWidget {
  final bool isKoLang;
  final double currentPrice;
  final double requiredReturnPct;
  final double? fibPositionPct;
  final String Function(num value) formatMoney;
  final ValuationResult result;
  final ValuationRating? rating;
  final Color accentColor;
  final Color infoColor;

  const ResultExplanationCard({
    super.key,
    required this.isKoLang,
    required this.currentPrice,
    required this.requiredReturnPct,
    required this.fibPositionPct,
    required this.formatMoney,
    required this.result,
    required this.rating,
    required this.accentColor,
    required this.infoColor,
  });

  @override
  Widget build(BuildContext context) {
    final bodyParagraphs = _buildBodyParagraphs(context);
    final summaryText = _buildSummaryText(context);

    return Card(
      elevation: 0,
      color: Colors.transparent,
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: infoColor.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: infoColor.withAlpha(55)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: infoColor.withAlpha(18),
                      shape: BoxShape.circle,
                      border: Border.all(color: infoColor.withAlpha(55)),
                    ),
                    child: Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: infoColor.withAlpha(220),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isKoLang
                          ? '이 기업은 지금 이런 상태예요'
                          : 'What this stock looks like now',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.black.withAlpha(20),
              ),
              const SizedBox(height: 12),

              ...bodyParagraphs.map((text) => _bulletParagraph(context, text)),

              const SizedBox(height: 2),
              _summaryParagraph(context, summaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulletParagraph(BuildContext context, String text) {
    final base = TextStyle(
      fontSize: 13.4,
      height: 1.72,
      color: Colors.grey[850],
      fontWeight: FontWeight.w500,
    );

    final strong = TextStyle(
      fontSize: 13.4,
      height: 1.72,
      color: Colors.black.withAlpha(235),
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(180),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              textScaler: MediaQuery.textScalerOf(context),
              text: TextSpan(
                children: _buildBoldSpans(
                  text,
                  baseStyle: base,
                  strongStyle: strong,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryParagraph(BuildContext context, String text) {
    final base = TextStyle(
      fontSize: 13.4,
      height: 1.68,
      color: Colors.grey[900],
      fontWeight: FontWeight.w600,
    );

    final strong = TextStyle(
      fontSize: 13.4,
      height: 1.68,
      color: Colors.black.withAlpha(240),
      fontWeight: FontWeight.w800,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withAlpha(45)),
      ),
      child: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          children: _buildBoldSpans(
            text,
            baseStyle: base,
            strongStyle: strong,
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildBoldSpans(
    String text, {
    required TextStyle baseStyle,
    required TextStyle strongStyle,
  }) {
    final spans = <InlineSpan>[];
    final reg = RegExp(r'\*\*(.+?)\*\*');

    int start = 0;
    for (final m in reg.allMatches(text)) {
      if (m.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, m.start),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: m.group(1),
        style: strongStyle,
      ));

      start = m.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return spans;
  }

  String _withWon(String text) {
    final s = text.trim();

    if (!isKoLang) return text;
    if (s.isEmpty || s == '-') return text;

    // 달러 표시는 그대로 둠
    if (s.contains('\$')) return text;

    if (s.endsWith('원')) return text;
    return '$text원';
  }

  String _withBa(String text) {
    final s = text.trim();

    if (!isKoLang) return text;
    if (s.isEmpty || s == '-') return text;
    if (s.endsWith('배')) return text;

    return '$text배';
  }

  List<String> _buildBodyParagraphs(BuildContext context) {
    final parts = <String>[];

    final fairPriceText = _withWon(formatMoney(result.fairPrice));
    final priceText = _withWon(formatMoney(currentPrice));

    final expected = result.expectedReturnPct;
    final expectedText =
        '${expected >= 0 ? '+' : ''}${expected.toStringAsFixed(1)}%';

    //  final gapText = '${result.gapPct.toStringAsFixed(1)}%';
    final roeText = '${result.roePct.toStringAsFixed(2)}%';
    final roeOverRText = _withBa(result.roeOverR.toStringAsFixed(2));
    final perText = _withBa(result.per.toStringAsFixed(2));
    final pbrText = _withBa(result.pbr.toStringAsFixed(2));

  //  final fib = fibPositionPct;
   // final fibText = fib == null ? null : '${fib.toStringAsFixed(1)}%';

    // 1) 전체 분위기
    String overall;
    switch (rating?.level) {
      case RatingLevel.strongBuy:
        overall = isKoLang
            ? '지금 숫자만 놓고 보면 이 종목은 **전반적으로 좋아 보이는 편**입니다. 가격은 비교적 싸게 잡히고 있고, 회사의 돈 버는 힘도 괜찮아서 **매수 관점에서 긍정적으로 볼 수 있습니다.**'
            : 'Based on the current numbers, this stock looks attractive overall.';
        break;
      case RatingLevel.buy:
        overall = isKoLang
            ? '지금 숫자만 놓고 보면 이 종목은 **다소 싸게 보이는 편**입니다. 전체적으로는 괜찮지만, 앞으로도 실적 흐름이 계속 유지되는지는 같이 보는 것이 좋습니다.'
            : 'Based on the current numbers, this stock looks somewhat undervalued overall.';
        break;
      case RatingLevel.caution:
        overall = isKoLang
            ? '지금 주가는 **싸게 보일 수는 있지만**, 회사의 수익성은 조금 더 조심해서 볼 필요가 있습니다. 가격만 보고 바로 강하게 들어가기보다는 **한 번 더 확인하는 편이 좋습니다.**'
            : 'The stock may look cheap, but profitability needs a more careful look.';
        break;
      case RatingLevel.avoid:
        overall = isKoLang
            ? '지금 숫자 기준으로는 **가격이 높게 평가되었거나 수익성이 약한 편**입니다. 지금은 적극적으로 보기보다는 **보수적으로 판단하는 편이 더 맞습니다.**'
            : 'On the current numbers, valuation may be expensive or profitability may be weak.';
        break;
      case RatingLevel.neutral:
      default:
        overall = isKoLang
            ? '지금 이 종목은 **아주 싸다고 보기도, 아주 비싸다고 보기도 애매한 상태**입니다. 그래서 숫자를 하나씩 천천히 읽어보는 것이 중요합니다.'
            : 'This stock is in a middle zone right now.';
        break;
    }
    parts.add(overall);

    // 2) 기대수익률 중심 설명
    String expectedExplain;
    if (expected >= 20) {
      expectedExplain = isKoLang
          ? '**기대수익률**은 **$expectedText**입니다. 현재 주가는 **$priceText**, 계산된 **적정주가**는 **$fairPriceText**입니다. 기대수익률이 플러스이고 폭도 큰 편이라, 계산상으로는 **현재 주가보다 적정주가가 더 높게 잡히는 상태**라고 볼 수 있습니다.'
          : 'Expected return is $expectedText.';
    } else if (expected >= 0) {
      expectedExplain = isKoLang
          ? '**기대수익률**은 **$expectedText**입니다. 현재 주가는 **$priceText**, 계산된 **적정주가**는 **$fairPriceText**입니다. 계산상으로는 아직 **상승 여지가 남아 있는 편**이지만, 아주 큰 차이라고 보기는 어려울 수 있습니다.'
          : 'Expected return is $expectedText.';
    } else {
      expectedExplain = isKoLang
          ? '**기대수익률**은 **$expectedText**입니다. 현재 주가는 **$priceText**, 계산된 **적정주가**는 **$fairPriceText**입니다. 기대수익률이 마이너스라는 뜻은, 계산상 현재 주가가 적정주가보다 **더 높게 거래되고 있을 가능성**이 있다는 뜻입니다.'
          : 'Expected return is $expectedText.';
    }
    parts.add(expectedExplain);

    // 3) 요구수익률 / ROE / ROE-r 중심 설명
    final rrExplain = isKoLang
        ? '**요구수익률**은 투자할 때 **내가 원하는 기준 수익률**이고, 지금은 **${requiredReturnPct.toStringAsFixed(1)}%**입니다. '
          '**ROE**는 **$roeText**이고, **ROE/r**는 **$roeOverRText**입니다. '
        //  'ROE는 회사가 자기자본으로 얼마나 잘 돈을 버는지 보는 숫자이고, ROE/r는 그 돈 버는 힘이 내가 원하는 기준과 비교해 어느 정도인지 보여주는 값입니다. '
          '**${ResultCopy.roeActionExplain(
              context,
              roe: result.roePct,
              roeOverR: result.roeOverR,
              requiredReturnPct: requiredReturnPct,
            )}**'
        : 'Required return is **${requiredReturnPct.toStringAsFixed(1)}%**. '
          '**ROE** is **$roeText** and **ROE/r** is **$roeOverRText**. '
          '**${ResultCopy.roeActionExplain(
              context,
              roe: result.roePct,
              roeOverR: result.roeOverR,
              requiredReturnPct: requiredReturnPct,
            )}**';
    parts.add(rrExplain);

    // 4) PER / PBR
    parts.add(
      isKoLang
          ? '**PER**는 **$perText**이고, **PBR**은 **$pbrText**입니다. '
        //    'PER는 주가가 이익(EPS)에 비해 어느 정도 수준인지 보는 숫자이고, '
         //   'PBR은 주가가 자산가치(BPS)에 비해 어느 정도인지 보는 숫자입니다. '
            '${ResultCopy.perLevelExplain(context, result.per)} '
            '${ResultCopy.pbrLevelExplain(context, result.pbr)} '
            '**${ResultCopy.perPbrActionExplain(
              context,
              per: result.per,
              pbr: result.pbr,
            )}**'
          : '**PER** is **$perText** and **PBR** is **$pbrText**. '
            '${ResultCopy.perLevelExplain(context, result.per)} '
            '${ResultCopy.pbrLevelExplain(context, result.pbr)} '
            '**${ResultCopy.perPbrActionExplain(
              context,
              per: result.per,
              pbr: result.pbr,
            )}**',
    );

    // 5) 배당
    parts.add(
      isKoLang
          ? '**${ResultCopy.dividendYieldExplain(context, result.dividendYieldPct)}**'
          : ResultCopy.dividendYieldExplain(context, result.dividendYieldPct),
    );

    // 6) 피보나치 위치
    // if (fib != null) {
    //   String fibExplain;

    //   if (fib >= 80) {
    //     fibExplain = isKoLang
    //         ? '**피보나치 위치**는 **$fibText**입니다. 최근 몇 년간의 흐름 중 가장 높은 능선에 도달해 있네요. 여기서 더 치고 나갈 동력이 충분한지, 혹은 잠시 쉬어갈 자리인지 **호흡을 가다듬으며 판단할 때**입니다.'
    //         : 'Fibonacci position is **$fibText**. It’s near the peak of its recent range. Consider whether it has enough momentum to break higher or needs a breather.';
    //   } else if (fib >= 60) {
    //     fibExplain = isKoLang
    //         ? '**피보나치 위치**는 **$fibText**입니다. 주가에 서서히 탄력이 붙으며 상승 궤도에 올라탄 모습입니다. 특히 61.8% 선 위에서 잘 버텨준다면, **본격적인 상승세를 기대하며 적극적으로 지켜볼 만한 구간**입니다.'
    //         : 'Fibonacci position is **$fibText**. The stock is gaining momentum. If it holds above the 61.8% level, it could be a great setup for a trend continuation.';
    //   } else if (fib >= 40) {
    //     fibExplain = isKoLang
    //         ? '**피보나치 위치**는 **$fibText**입니다. 전체적인 흐름의 딱 중간 지점에 와 있네요. 방향성이 결정되지 않은 **균형 잡힌 상태**이므로, 다른 수익성 지표들과 함께 보며 다음 움직임을 예측해 보세요.'
    //         : 'Fibonacci position is **$fibText**. It’s at a balanced midpoint. Since the trend is neutral, use other fundamental metrics to decide your next move.';
    //   } else if (fib >= 20) {
    //     fibExplain = isKoLang
    //         ? '**피보나치 위치**는 **$fibText**입니다. 주가가 꽤 낮은 지대까지 내려와 있어 **가격 부담이 적은 구간**입니다. 바닥을 다지고 반등할 준비가 되었는지 실적과 함께 살피면 좋은 기회를 잡을 수 있습니다.'
    //         : 'Fibonacci position is **$fibText**. The price is in a comfortable low zone. Check if earnings support a rebound to catch a good entry point.';
    //   } else {
    //     fibExplain = isKoLang
    //         ? '**피보나치 위치**는 **$fibText**입니다. 최근 몇 년간의 흐름 중 가장 낮은 바닥권에 머물고 있습니다. 가격은 매우 저렴해 보이지만, **단순히 싸서 좋은 것인지 아니면 힘이 빠져서 밀린 것인지** 냉정하게 구분해 볼 필요가 있습니다.'
    //         : 'Fibonacci position is **$fibText**. It’s at the very bottom of its range. It’s important to distinguish if it’s a "bargain" or a "value trap" before stepping in.';
    //   }

    //   parts.add(fibExplain);
    // }

    return parts;
  }

  String _buildSummaryText(BuildContext context) {
    if (isKoLang) {
      if (rating?.level == RatingLevel.strongBuy ||
          rating?.level == RatingLevel.buy) {
        return '정리하면 지금 이 종목은 **가격과 수익성 흐름을 함께 봤을 때 종합적으로 안정감과 수익성을 고루 갖춘 상태입니다. 서두르지 않고 차분히 비중을 늘려가는 전략이 유효해 보입니다.**';
      } else if (rating?.level == RatingLevel.caution) {
        return '정리하면 지금 이 종목은 **숫자상 싸게 보여서 가격 매력은 있지만 아직은 조심스러운 신호가 섞여 있습니다. 확실한 반등 근거가 나타날 때까지 보수적인 관점을 유지하는 것이 안전합니다.**';
      } else if (rating?.level == RatingLevel.avoid) {
        return '정리하면 지금 이 종목은 **지금은 지키는 투자가 중요한 시점입니다. 신규 매수보다는 현재 보유한 비중이 적절한지 냉정하게 점검해 보는 것이 좋습니다.**';
      } else {
        return '정리하면 지금 이 종목은 **당장 강하게 움직이기보다는 관심종목으로 두고 숫자 변화를 더 지켜보는 편이 좋습니다.**';
      }
    }

    if (rating?.level == RatingLevel.strongBuy ||
        rating?.level == RatingLevel.buy) {
      return 'Overall, **this looks suitable for gradual buying.**';
    } else if (rating?.level == RatingLevel.caution) {
      return 'Overall, **this may look cheap, but it is better to stay cautious for now.**';
    } else if (rating?.level == RatingLevel.avoid) {
      return 'Overall, **this is better reviewed carefully rather than bought more aggressively.**';
    } else {
      return 'Overall, **this is better watched for now while following future changes in the numbers.**';
    }
  }
}