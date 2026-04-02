import 'package:flutter/material.dart';
import 'package:stock_valuation_app/models/market.dart';

class SellGuideCopy {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const SellGuideCopy({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class ResultCopy {
  static bool isKo(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ko';
  }

  static String pageTitle(BuildContext context, String name) {
    return isKo(context) ? '$name 평가' : '$name Valuation';
  }

  static String dataSourceText(BuildContext context, Market market) {
    if (market == Market.kr) {
      return isKo(context)
          ? '데이터 출처: 한국투자증권(KIS) 실시간 시세 + OpenDART 재무'
          : 'Source: Korea Investment & Securities (KIS) real-time quotes + OpenDART financials';
    }
    return isKo(context)
        ? '데이터 출처: FMP (Financial Modeling Prep)'
        : 'Source: FMP (Financial Modeling Prep)';
  }

  static String financialBasisText(BuildContext context, String value) {
    return isKo(context) ? '재무 기준: $value' : 'Financial basis: $value';
  }

  static String financialDateText(BuildContext context, String value) {
    return isKo(context) ? '재무 기준일: $value' : 'Financial date: $value';
  }

  static String priceDateText(BuildContext context, String value) {
    return isKo(context) ? '가격 기준일: $value' : 'Price date: $value';
  }

  static String missingBrief(BuildContext context) {
    return isKo(context)
        ? 'EPS/BPS 자동값이 비어 있습니다. (탭하면 보기 전환)'
        : 'EPS/BPS auto values are empty. Tap to toggle the view.';
  }

  static String missingTitle(BuildContext context, List<String> missing) {
    return isKo(context)
        ? '데이터 미제공/계산불가: ${missing.join(', ')}'
        : 'Unavailable / cannot calculate: ${missing.join(', ')}';
  }

  static String missingDetail(
    BuildContext context, {
    required Market market,
    required String? usedFinanceText,
    required bool dpsZero,
  }) {
    final ko = isKo(context);

    if (ko) {
      return (market == Market.kr)
          ? "현재 앱은 최신 사용가능 재무를 자동 선택해서 계산합니다.\n"
              "${usedFinanceText != null ? "현재 사용 기준: $usedFinanceText\n" : ""}"
              "최신 연간/분기 재무가 아직 공시되지 않았으면 직전 재무를 사용할 수 있어요.\n"
              "${dpsZero ? "※ DPS=0은 무배당이거나(정상), 배당 데이터 미제공일 수 있어요.\n" : ""}"
              "값을 직접 입력하면 즉시 재계산됩니다."
          : "해당 값은 공시/배당 반영 타이밍 또는 API 제공 범위에 따라 비어 있을 수 있어요.\n"
              "${dpsZero ? "※ DPS=0은 무배당(정상) 또는 데이터 미제공일 수 있어요.\n" : ""}"
              "값을 직접 입력하면 즉시 재계산됩니다.";
    }

    return (market == Market.kr)
        ? "The app automatically calculates using the latest available financial data.\n"
            "${usedFinanceText != null ? "Current basis: $usedFinanceText\n" : ""}"
            "If the latest annual or quarterly report has not been disclosed yet, the previous financial period may be used.\n"
            "${dpsZero ? "※ DPS=0 may indicate no dividend (normal) or unavailable dividend data.\n" : ""}"
            "If you enter values manually, the result is recalculated immediately."
        : "These values may be empty depending on disclosure timing, dividend updates, or the API coverage.\n"
            "${dpsZero ? "※ DPS=0 may indicate no dividend (normal) or unavailable data.\n" : ""}"
            "If you enter values manually, the result is recalculated immediately.";
  }

  static String retryAutoValuesLabel(BuildContext context) {
    return isKo(context) ? '값 자동 재시도(새로고침)' : 'Retry auto values';
  }

  static String inputsTitle(BuildContext context) {
    return isKo(context) ? '입력값' : 'Inputs';
  }

  static String resetLabel(BuildContext context) {
    return isKo(context) ? '초기화' : 'Reset';
  }

  static String priceUnavailableHint(BuildContext context) {
    return isKo(context)
        ? '현재가 데이터를 가져오지 못했습니다. 직접 입력해도 계산은 가능합니다.'
        : 'Current price data could not be loaded. You can still calculate by entering it manually.';
  }

  static String manualInputHint(BuildContext context) {
    return isKo(context) ? '직접 입력 가능' : 'Manual input allowed';
  }

  static String requiredReturnLabel(BuildContext context) {
    return isKo(context) ? '요구수익률 r(%)' : 'Required return r(%)';
  }

  static String requiredReturnHelp(BuildContext context) {
    return isKo(context)
        ? '(ROE/r로 적정 PBR 결정)'
        : '(Fair PBR is determined by ROE/r)';
  }

  static String resultTitleLabel(BuildContext context) {
    return isKo(context) ? '결과' : 'Result';
  }

  static String calcNeedMoreValues(BuildContext context) {
    return isKo(context)
        ? '아직 계산에 필요한 값이 부족해요. 입력값을 한 번 확인해 주세요.'
        : 'Some values required for calculation are still missing. Please check the inputs.';
  }

  static String fairPriceLabel(BuildContext context) {
    return isKo(context) ? '적정주가' : 'Fair price';
  }

  static String expectedReturnPctLabel(BuildContext context) {
    return isKo(context) ? '기대수익률(%)' : 'Expected return (%)';
  }

  static String expectedReturnHint(BuildContext context) {
    return isKo(context) ? '적정가까지 상승 여지' : 'Upside to fair price';
  }

  static String valuationStatusText(BuildContext context, double gapPct) {
    return isKo(context)
        ? '현황평가: ${gapPct.toStringAsFixed(1)}%  (100% 미만이면 저평가 쪽)'
        : 'Valuation status: ${gapPct.toStringAsFixed(1)}%  (Below 100% suggests undervaluation)';
  }

  static String detailHintText(BuildContext context) {
    return isKo(context)
        ? '※ 상단 눈 아이콘을 켜면 ROE, 배당수익률, PER/PBR 등 상세 지표를 볼 수 있어요.'
        : '※ Turn on the eye icon above to view detailed indicators such as ROE, dividend yield, PER, and PBR.';
  }

  static String valueSectionTitle(BuildContext context) {
    return isKo(context) ? '가치(Valuation)' : 'Value (Valuation)';
  }

  static String profitabilitySectionTitle(BuildContext context) {
    return isKo(context) ? '수익성(Profitability)' : 'Profitability';
  }

  static String dividendSectionTitle(BuildContext context) {
    return isKo(context) ? '배당(Dividend)' : 'Dividend';
  }

  static String multiplesSectionTitle(BuildContext context) {
    return isKo(context) ? '멀티플(Multiples)' : 'Multiples';
  }

  static String valuationStatusLabel(BuildContext context) {
    return isKo(context)
        ? '현황평가(현재/적정)'
        : 'Valuation status (current/fair)';
  }

  static String valuationStatusHelper(BuildContext context) {
    return isKo(context)
        ? '100% 미만이면 저평가 쪽'
        : 'Below 100% suggests undervaluation';
  }

  static String roeOverRHelper(BuildContext context) {
    return isKo(context)
        ? '1.0 이상이면 r 충족'
        : 'At or above 1.0 meets r';
  }

  static String dividendYieldLabel(BuildContext context) {
    return isKo(context) ? '배당수익률' : 'Dividend yield';
  }

  static String needCurrentAndFairPrice(BuildContext context) {
    return isKo(context)
        ? '현재가/적정가를 표시하려면 현재가와 적정가가 필요해요.'
        : 'Current price and fair price are both required to show this gauge.';
  }

  static String currentVsFairText(BuildContext context, double pct) {
    return isKo(context)
        ? '현재가 / 적정주가: ${pct.toStringAsFixed(1)}%'
        : 'Current / Fair price: ${pct.toStringAsFixed(1)}%';
  }

  static String fairAt100Label(BuildContext context) {
    return isKo(context) ? '100%(적정)' : '100% (fair)';
  }

  static String currentPriceText(
    BuildContext context,
    String formattedPrice,
  ) {
    return isKo(context)
        ? '현재가: $formattedPrice'
        : 'Current: $formattedPrice';
  }

  static String fairPriceText(
    BuildContext context,
    String formattedFairPrice,
  ) {
    return isKo(context)
        ? '적정가: $formattedFairPrice'
        : 'Fair: $formattedFairPrice';
  }

  static String checklistLabel(BuildContext context) {
    return isKo(context) ? '체크리스트 보기' : 'View checklist';
  }

  static String pdfExportTitle(BuildContext context) {
    return isKo(context) ? 'PDF 내보내기' : 'Export PDF';
  }

  static String pdfSaveResultTitle(BuildContext context) {
    return isKo(context) ? '평가 결과 PDF 저장' : 'Save valuation result PDF';
  }

  static String pdfSaveResultSubtitle(BuildContext context) {
    return isKo(context)
        ? '현재가, EPS/BPS/DPS, 적정주가, 기대수익률 등'
        : 'Current price, EPS/BPS/DPS, fair price, expected return, and more';
  }

  static String pdfSaveFullTitle(BuildContext context) {
    return isKo(context)
        ? '평가 결과 + 재무제표 함께 저장'
        : 'Save valuation result + financial statements';
  }

  static String pdfSaveFullSubtitle(BuildContext context) {
    return isKo(context)
        ? '평가 결과와 재무제표 요약을 한 파일로 저장'
        : 'Save the valuation result and financial statement summary in one file';
  }

  static String pdfCanceled(BuildContext context) {
    return isKo(context)
        ? 'PDF 저장이 취소되었습니다.'
        : 'PDF save was canceled.';
  }

  static String pdfStartedResult(BuildContext context) {
    return isKo(context)
        ? '평가 결과 PDF 저장/공유를 시작했습니다.'
        : 'Started saving/sharing the valuation result PDF.';
  }

  static String pdfStartedFull(BuildContext context) {
    return isKo(context)
        ? '평가 결과 + 재무제표 PDF 저장/공유를 시작했습니다.'
        : 'Started saving/sharing the valuation result + financial statements PDF.';
  }

  static String pdfFailed(BuildContext context, Object e) {
    return isKo(context) ? 'PDF 저장 실패: $e' : 'PDF save failed: $e';
  }

  static SellGuideCopy sellGuide(BuildContext context, double gap) {
    final ko = isKo(context);
    final over = gap >= 130;
    final under = gap <= 90;

    if (ko) {
      if (over) {
        return SellGuideCopy(
          title: "보유/매도 점검(참고) · 과열 주의",
          subtitle:
              "현재가가 적정가 대비 ${gap.toStringAsFixed(0)}% 높습니다. 내재가치보다 비싼 구간이니, 수익을 확정할지 아니면 기업의 초과 성장을 더 믿고 기다릴지 결정이 필요한 시점입니다.",
          icon: Icons.warning_amber,
          color: Colors.orange,
        );
      } else if (under) {
        return SellGuideCopy(
          title: "보유/매도 점검(참고) · 안전마진 유효",
          subtitle:
              "현재가가 적정가 대비 ${gap.toStringAsFixed(0)}% 낮아 안전마진이 충분합니다. 시세 흔들림에 불안해하기보다, 기업의 이익 성장세와 사업의 본질이 변하지 않았는지 확인하며 보유하세요.",
          icon: Icons.fact_check,
          color: Colors.blueGrey,
        );
      } else {
        return SellGuideCopy(
          title: "보유/매도 점검(참고) · 가치 부합",
          subtitle:
              "현재 주가가 기업의 내재가치에 근접했습니다. 이제부터는 가격의 싸고 비쌈을 따지기보다, 기업의 '해자(경쟁력)'나 '경영진의 태도' 등 질적인 변화를 더 세밀하게 관찰해야 합니다.",
          icon: Icons.checklist,
          color: Colors.indigo,
        );
      }
    }

    if (over) {
      return SellGuideCopy(
        title: "Hold/Sell check · Caution on overheating",
        subtitle:
            "The current price is ${gap.toStringAsFixed(0)}% above fair value. Since the stock is trading above intrinsic value, this is the point where you decide whether to lock in gains or keep holding based on stronger long-term growth expectations.",
        icon: Icons.warning_amber,
        color: Colors.orange,
      );
    } else if (under) {
      return SellGuideCopy(
        title: "Hold/Sell check · Margin of safety remains",
        subtitle:
            "The current price is ${gap.toStringAsFixed(0)}% below fair value, which suggests a sufficient margin of safety. Rather than reacting to price swings, keep holding while checking whether earnings growth and business fundamentals remain intact.",
        icon: Icons.fact_check,
        color: Colors.blueGrey,
      );
    } else {
      return SellGuideCopy(
        title: "Hold/Sell check · Near fair value",
        subtitle:
            "The current price is close to intrinsic value. From here, rather than focusing only on whether the stock is cheap or expensive, it is more important to monitor qualitative changes such as moat and management attitude.",
        icon: Icons.checklist,
        color: Colors.indigo,
      );
    }
  }
}