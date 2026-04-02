import '../models/valuation_result.dart';
import '../models/valuation_rating.dart';
import 'package:flutter/material.dart';
import '../copy/valuation_copy.dart';


enum ValuationErrorCode {
  invalidRequiredReturn,
  invalidPrice,
  invalidBps,
}

class ValuationException implements Exception {
  final ValuationErrorCode code;

  const ValuationException(this.code);

  @override
  String toString() => 'ValuationException($code)';
}

class ValuationInput {
  final double price, eps, bps, dps, rPct;
  const ValuationInput({
    required this.price,
    required this.eps,
    required this.bps,
    required this.dps,
    required this.rPct,
  });
}

class ValuationService {
  static ValuationResult evaluate(ValuationInput x) {
    if (x.rPct <= 0) throw const ValuationException(ValuationErrorCode.invalidRequiredReturn);
    if (x.price <= 0) throw const ValuationException(ValuationErrorCode.invalidPrice);
    if (x.bps <= 0) throw const ValuationException(ValuationErrorCode.invalidBps);
    //  EPS 0 이하도 허용 (throw 제거)
    // if (x.eps <= 0) throw Exception("EPS가 0 이하이면 계산이 어렵습니다.");

    // roePct ROE(%) - (x.eps / x.bps) * 100.0
    // roeOverR , fairPrice 적정주가 - x.bps * (roePct / x.rPct)

    final roePct = (x.eps / x.bps) * 100.0;     //  음수면 음수 그대로
    final roeOverR = roePct / x.rPct;           //  음수면 음수 그대로
    final fairPrice = x.bps * roeOverR;         //  음수 가능

    // gapPct 현재가 대비 적정가 비중 (현재가 / 적정가) * 100
    // expectedReturnPct 기대수익률 ((적정가 - 현재가) / 현재가) * 100
    // dividendYieldPct 배당수익률 - (x.dps / x.price) * 100.0
    // per/ 전통적가치지표 - per : x.price / x.eps (EPS 0일 때 무한대 처리), 
    // pbr               - pbr : x.price / x.bps

    // fairPrice가 0이면 gapPct에서 0으로 나누기 발생 → 안전처리
    final gapPct = (fairPrice == 0) ? double.nan : (x.price / fairPrice) * 100.0;
    final expectedReturnPct = ((fairPrice - x.price) / x.price) * 100.0;
    final dividendYieldPct = (x.dps > 0) ? (x.dps / x.price) * 100.0 : 0.0;

    // EPS=0이면 PER 0으로 나누기 → 안전처리(표시는 UI에서 처리)
    final per = (x.eps == 0) ? double.infinity : (x.price / x.eps);

    final pbr = x.price / x.bps;

    return ValuationResult(
      roePct: roePct,
      roeOverR: roeOverR,
      fairPrice: fairPrice,
      gapPct: gapPct,
      expectedReturnPct: expectedReturnPct,
      dividendYieldPct: dividendYieldPct,
      per: per,
      pbr: pbr,
    );
  }

  // 평가 설명
  static ValuationRating interpret5(
    ValuationResult r,
    double userRPct, {
    required bool isKo,
  }) {
    ({Color bg, Color border, Color accent}) palette(RatingLevel level) {
      switch (level) {
        case RatingLevel.strongBuy:
          return (
            bg: Colors.red.withAlpha(16),
            border: Colors.red.withAlpha(70),
            accent: Colors.red.withAlpha(220),
          );
        case RatingLevel.buy:
          return (
            bg: Colors.green.withAlpha(14),
            border: Colors.green.withAlpha(70),
            accent: Colors.green.withAlpha(220),
          );
        case RatingLevel.neutral:
          return (
            bg: Colors.blueGrey.withAlpha(12),
            border: Colors.blueGrey.withAlpha(60),
            accent: Colors.blueGrey.withAlpha(200),
          );
        case RatingLevel.caution:
          return (
            bg: Colors.orange.withAlpha(16),
            border: Colors.orange.withAlpha(80),
            accent: Colors.orange.withAlpha(220),
          );
        case RatingLevel.avoid:
          return (
            bg: Colors.purple.withAlpha(14),
            border: Colors.purple.withAlpha(70),
            accent: Colors.purple.withAlpha(220),
          );
      }
    }


    // --------------------------
    // ✅ 5단계 최종 판정 룰(초보용)
    // - strongBuy: 매우 저평가 + ROE/r 아주 좋음 + 기대수익 충분
    // - buy: 저평가 + ROE/r 양호
    // - neutral: 애매/적정가 근처
    // - caution: 비싸거나 ROE/r이 기준 미달
    // - avoid: 매우 비싸거나 ROE/r이 많이 부족
    // --------------------------

    final isVeryCheap = r.gapPct <= 80;
    final isCheap = r.gapPct <= 90;
    final isExpensive = r.gapPct >= 110;
    final isVeryExpensive = r.gapPct >= 130;

    final isVeryStrong = r.roeOverR >= 1.5;
    final isStrong = r.roeOverR >= 1.2;
    final isWeak = r.roeOverR < 1.0;
    final isVeryWeak = r.roeOverR < 0.8;

    final isHighUpside = r.expectedReturnPct >= 30;
    final isUpside = r.expectedReturnPct >= 15;
    final isNegative = r.expectedReturnPct < 0;
    final isVeryNegative = r.expectedReturnPct < -10;

    late final RatingLevel level;

    if (isVeryCheap && isVeryStrong && (isHighUpside || isUpside)) {
      level = RatingLevel.strongBuy;
    } else if (isCheap && isStrong && !isNegative) {
      level = RatingLevel.buy;
    } else if (isVeryExpensive || isVeryWeak || isVeryNegative) {
      level = RatingLevel.avoid;
    } else if (isExpensive || isWeak) {
      level = RatingLevel.caution;
    } else {
      level = RatingLevel.neutral;
    }

    final copy = ValuationCopy.build(
      isKo: isKo,
      level: level,
      r: r,
      userRPct: userRPct,
    );

    final p = palette(level);

    return ValuationRating(
      level: level,
      title: copy.title,
      summary: copy.summary,
      bullets: copy.bullets,
      bg: p.bg,
      border: p.border,
      accent: p.accent,
    );
  }
}