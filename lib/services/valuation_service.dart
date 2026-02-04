import '../models/valuation_result.dart';
import '../models/valuation_rating.dart';


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
    if (x.rPct <= 0) throw Exception("r은 0보다 커야 합니다.");
    if (x.price <= 0) throw Exception("현재가가 0보다 커야 합니다.");
    if (x.bps <= 0) throw Exception("BPS가 0 이하이면 계산이 어렵습니다.");
    //  EPS 0 이하도 허용 (throw 제거)
    // if (x.eps <= 0) throw Exception("EPS가 0 이하이면 계산이 어렵습니다.");

    final roePct = (x.eps / x.bps) * 100.0;     //  음수면 음수 그대로
    final roeOverR = roePct / x.rPct;           //  음수면 음수 그대로
    final fairPrice = x.bps * roeOverR;         //  음수 가능

    // ✅ fairPrice가 0이면 gapPct에서 0으로 나누기 발생 → 안전처리
    final gapPct = (fairPrice == 0)
        ? double.nan
        : (x.price / fairPrice) * 100.0;

    final expectedReturnPct = ((fairPrice - x.price) / x.price) * 100.0;
    final dividendYieldPct = (x.dps > 0) ? (x.dps / x.price) * 100.0 : 0.0;

    // ✅ EPS=0이면 PER 0으로 나누기 → 안전처리(표시는 UI에서 처리)
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
  static ValuationRating interpret5(ValuationResult r, double userRPct) {
    final bullets = <String>[];

    // 1) 가격(현황평가: 현재가/적정가*100)
    if (r.gapPct <= 80) {
      bullets.add("✅ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (매우 저평가 구간)");
    } else if (r.gapPct <= 90) {
      bullets.add("✅ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (저평가 구간)");
    } else if (r.gapPct < 110) {
      bullets.add("➖ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (적정가 근처)");
    } else if (r.gapPct < 130) {
      bullets.add("⚠ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (고평가 가능성)");
    } else {
      bullets.add("⛔ 가격: 적정가 대비 ${r.gapPct.toStringAsFixed(0)}% (매우 고평가 가능성)");
    }

    // 2) 수익성(ROE/r)
    if (r.roeOverR >= 1.5) {
      bullets.add("✅ 수익성: ROE가 목표수익률(r=${userRPct.toStringAsFixed(1)}%)보다 충분히 높음 (ROE/r=${r.roeOverR.toStringAsFixed(2)})");
    } else if (r.roeOverR >= 1.2) {
      bullets.add("✅ 수익성: ROE가 목표수익률보다 높음 (ROE/r=${r.roeOverR.toStringAsFixed(2)})");
    } else if (r.roeOverR >= 1.0) {
      bullets.add("➖ 수익성: ROE가 목표수익률과 비슷함 (ROE/r=${r.roeOverR.toStringAsFixed(2)})");
    } else if (r.roeOverR >= 0.8) {
      bullets.add("⚠ 수익성: ROE가 목표수익률보다 낮음 (ROE/r=${r.roeOverR.toStringAsFixed(2)})");
    } else {
      bullets.add("⛔ 수익성: ROE가 목표수익률을 크게 못 미침 (ROE/r=${r.roeOverR.toStringAsFixed(2)})");
    }

    // 3) 기대수익률
    if (r.expectedReturnPct >= 30) {
      bullets.add("✅ 기대수익: 적정가까지 ${r.expectedReturnPct.toStringAsFixed(0)}% 여지");
    } else if (r.expectedReturnPct >= 15) {
      bullets.add("✅ 기대수익: 적정가까지 ${r.expectedReturnPct.toStringAsFixed(0)}% 여지");
    } else if (r.expectedReturnPct >= 0) {
      bullets.add("➖ 기대수익: 적정가까지 ${r.expectedReturnPct.toStringAsFixed(0)}% (여지 작음)");
    } else if (r.expectedReturnPct >= -10) {
      bullets.add("⚠ 기대수익: 적정가 기준으로 ${r.expectedReturnPct.toStringAsFixed(0)}% (다소 비쌈)");
    } else {
      bullets.add("⛔ 기대수익: 적정가 기준으로 ${r.expectedReturnPct.toStringAsFixed(0)}% (비쌈)");
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

    if (isVeryCheap && isVeryStrong && (isHighUpside || isUpside)) {
      return ValuationRating(
        level: RatingLevel.strongBuy,
        title: "강력매수",
        summary: "가격이 충분히 싸고(저평가), ROE가 목표수익률을 크게 상회합니다.",
        bullets: bullets,
      );
    }

    if (isCheap && isStrong && !isNegative) {
      return ValuationRating(
        level: RatingLevel.buy,
        title: "매수",
        summary: "저평가 구간이며, ROE가 목표수익률보다 높습니다.",
        bullets: bullets,
      );
    }

    if (isVeryExpensive || isVeryWeak || isVeryNegative) {
      return ValuationRating(
        level: RatingLevel.avoid,
        title: "피하기",
        summary: "매우 비싸거나(또는) ROE가 목표수익률을 크게 못 미칩니다.",
        bullets: bullets,
      );
    }

    if (isExpensive || isWeak) {
      return ValuationRating(
        level: RatingLevel.caution,
        title: "주의",
        summary: "가격이 비싸거나 ROE가 목표수익률보다 낮습니다.",
        bullets: bullets,
      );
    }

    return ValuationRating(
      level: RatingLevel.neutral,
      title: "중립",
      summary: "적정가 근처이거나 판단이 애매한 구간입니다.",
      bullets: bullets,
    );
  }
}