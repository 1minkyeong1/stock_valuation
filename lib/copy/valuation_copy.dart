import '../models/valuation_rating.dart';
import '../models/valuation_result.dart';

class ValuationCopyData {
  final String title;
  final String summary;
  final List<String> bullets;

  const ValuationCopyData({
    required this.title,
    required this.summary,
    required this.bullets,
  });
}

class ValuationCopy {
  static ValuationCopyData build({
    required bool isKo,
    required RatingLevel level,
    required ValuationResult r,
    required double userRPct,
  }) {
    final bullets = <String>[];

    // 1) 가격
    if (r.gapPct <= 80) {
      bullets.add(
        isKo
            ? "✅ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (매우 저평가 구간)"
            : "✅ Price: ${r.gapPct.toStringAsFixed(0)}% of fair value (deeply undervalued zone)",
      );
    } else if (r.gapPct <= 90) {
      bullets.add(
        isKo
            ? "✅ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (저평가 구간)"
            : "✅ Price: ${r.gapPct.toStringAsFixed(0)}% of fair value (undervalued zone)",
      );
    } else if (r.gapPct < 110) {
      bullets.add(
        isKo
            ? "➖ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (적정가 근처)"
            : "➖ Price: ${r.gapPct.toStringAsFixed(0)}% of fair value (near fair value)",
      );
    } else if (r.gapPct < 130) {
      bullets.add(
        isKo
            ? "⚠ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (고평가 가능성)"
            : "⚠ Price: ${r.gapPct.toStringAsFixed(0)}% of fair value (possibly overvalued)",
      );
    } else {
      bullets.add(
        isKo
            ? "⛔ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (매우 고평가 가능성)"
            : "⛔ Price: ${r.gapPct.toStringAsFixed(0)}% of fair value (strongly overvalued)",
      );
    }

    // 2) 수익성
    if (r.roeOverR >= 1.5) {
      bullets.add(
        isKo
            ? "✅ 수익성: ROE가 목표수익률(r=${userRPct.toStringAsFixed(1)}%)보다 충분히 높음 (ROE/r=${r.roeOverR.toStringAsFixed(2)})"
            : "✅ Profitability: ROE is comfortably above the target return (r=${userRPct.toStringAsFixed(1)}%) (ROE/r=${r.roeOverR.toStringAsFixed(2)})",
      );
    } else if (r.roeOverR >= 1.2) {
      bullets.add(
        isKo
            ? "✅ 수익성: ROE가 목표수익률보다 높음 (ROE/r=${r.roeOverR.toStringAsFixed(2)})"
            : "✅ Profitability: ROE is above the target return (ROE/r=${r.roeOverR.toStringAsFixed(2)})",
      );
    } else if (r.roeOverR >= 1.0) {
      bullets.add(
        isKo
            ? "➖ 수익성: ROE가 목표수익률과 비슷함 (ROE/r=${r.roeOverR.toStringAsFixed(2)})"
            : "➖ Profitability: ROE is close to the target return (ROE/r=${r.roeOverR.toStringAsFixed(2)})",
      );
    } else if (r.roeOverR >= 0.8) {
      bullets.add(
        isKo
            ? "⚠ 수익성: ROE가 목표수익률보다 낮음 (ROE/r=${r.roeOverR.toStringAsFixed(2)})"
            : "⚠ Profitability: ROE is below the target return (ROE/r=${r.roeOverR.toStringAsFixed(2)})",
      );
    } else {
      bullets.add(
        isKo
            ? "⛔ 수익성: ROE가 목표수익률을 크게 못 미침 (ROE/r=${r.roeOverR.toStringAsFixed(2)})"
            : "⛔ Profitability: ROE falls well short of the target return (ROE/r=${r.roeOverR.toStringAsFixed(2)})",
      );
    }

    // 3) 기대수익률
    if (r.expectedReturnPct >= 30) {
      bullets.add(
        isKo
            ? "✅ 기대수익: 적정가까지 ${r.expectedReturnPct.toStringAsFixed(0)}% 여지"
            : "✅ Upside: ${r.expectedReturnPct.toStringAsFixed(0)}% upside to fair value",
      );
    } else if (r.expectedReturnPct >= 15) {
      bullets.add(
        isKo
            ? "✅ 기대수익: 적정가까지 ${r.expectedReturnPct.toStringAsFixed(0)}% 여지"
            : "✅ Upside: ${r.expectedReturnPct.toStringAsFixed(0)}% upside to fair value",
      );
    } else if (r.expectedReturnPct >= 0) {
      bullets.add(
        isKo
            ? "➖ 기대수익: 적정가까지 ${r.expectedReturnPct.toStringAsFixed(0)}% (여지 작음)"
            : "➖ Upside: ${r.expectedReturnPct.toStringAsFixed(0)}% to fair value (limited upside)",
      );
    } else if (r.expectedReturnPct >= -10) {
      bullets.add(
        isKo
            ? "⚠ 기대수익: 적정가 기준으로 ${r.expectedReturnPct.toStringAsFixed(0)}% (다소 비쌈)"
            : "⚠ Upside: ${r.expectedReturnPct.toStringAsFixed(0)}% versus fair value (somewhat expensive)",
      );
    } else {
      bullets.add(
        isKo
            ? "⛔ 기대수익: 적정가 기준으로 ${r.expectedReturnPct.toStringAsFixed(0)}% (비쌈)"
            : "⛔ Upside: ${r.expectedReturnPct.toStringAsFixed(0)}% versus fair value (expensive)",
      );
    }

    switch (level) {
      case RatingLevel.strongBuy:
        return ValuationCopyData(
          title: isKo ? "강력매수" : "Strong Buy",
          summary: isKo
              ? "가격이 충분히 싸고(저평가), ROE가 목표수익률을 크게 상회합니다."
              : "The stock looks attractively priced and ROE is well above the target return.",
          bullets: bullets,
        );
      case RatingLevel.buy:
        return ValuationCopyData(
          title: isKo ? "매수" : "Buy",
          summary: isKo
              ? "저평가 구간이며, ROE가 목표수익률보다 높습니다."
              : "The stock appears undervalued and ROE is above the target return.",
          bullets: bullets,
        );
      case RatingLevel.neutral:
        return ValuationCopyData(
          title: isKo ? "중립" : "Neutral",
          summary: isKo
              ? "적정가 근처이거나 판단이 애매한 구간입니다."
              : "The stock is near fair value or sits in an ambiguous range.",
          bullets: bullets,
        );
      case RatingLevel.caution:
        return ValuationCopyData(
          title: isKo ? "주의" : "Caution",
          summary: isKo
              ? "가격이 비싸거나 ROE가 목표수익률보다 낮습니다."
              : "The stock looks expensive or ROE is below the target return.",
          bullets: bullets,
        );
      case RatingLevel.avoid:
        return ValuationCopyData(
          title: isKo ? "피하기" : "Avoid",
          summary: isKo
              ? "매우 비싸거나(또는) ROE가 목표수익률을 크게 못 미칩니다."
              : "The stock looks very expensive or ROE falls well short of the target return.",
          bullets: bullets,
        );
    }
  }
}