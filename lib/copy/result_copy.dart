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

  static String requiredReturnTooltip(BuildContext context) {
    return isKo(context)
        ? '요구수익률은 내가 투자할 때 원하는 기준 수익률입니다. 쉽게 말해 “나는 이 정도는 벌고 싶다” 하는 목표입니다.'
        : 'Required return is the return you want from your investment.';
  }

  static String roeTooltip(BuildContext context) {
    return isKo(context)
        ? 'ROE는 회사가 자기자본으로 얼마나 돈을 잘 버는지 보는 숫자입니다. 보통 높을수록 좋습니다.'
        : 'ROE shows how well a company earns money using its own capital.';
  }

  static String roeOverRTooltip(BuildContext context) {
    return isKo(context)
        ? 'ROE/r는 회사의 실력(ROE)이 나의 목표(r)를 얼마나 뛰어넘었는지 보여주는 값입니다. 1보다 크면 내 기준보다 돈을 더 잘 벌고 있다는 아주 좋은 신호입니다.'
        : 'ROE/r A score that checks if the company outperforms your goals. If it’s over 1.0, the company is earning more than what you’re asking for.';
  }

  static String perTooltip(BuildContext context) {
    return isKo(context)
        ? 'PER는 회사가 버는 돈에 비해 주가가 적당한지 보는 지표예요. 숫자가 낮을수록 번 돈에 비해 주가가 아직 저렴하네? 라고 볼 수 있습니다.'
        : 'PER compares price to earnings. Lower can mean the stock is cheaper relative to profit.';
  }

  static String pbrTooltip(BuildContext context) {
    return isKo(context)
        ? 'PBR은 회사가 가진 전체 재산(자산)과 주가를 비교해본 거예요. 1보다 낮으면 회사를 다 팔아도 주가보다 많은 돈이 남을 정도로 주가가 저평가되었다는 뜻입니다.'
        : 'PBR Compares the stock price to the company’s net assets. A lower number means you’re buying the company’s assets at a discounted price.';
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
        ? '  현황평가: ${gapPct.toStringAsFixed(1)}%  (100% 미만이면 저평가 쪽)'
        : '  Valuation status: ${gapPct.toStringAsFixed(1)}%  (Below 100% suggests undervaluation)';
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

  // static SellGuideCopy sellGuide(BuildContext context, double gap) {
  //   final ko = isKo(context);
  //   final over = gap >= 130;
  //   final under = gap <= 90;

  //   if (ko) {
  //     if (over) {
  //       return SellGuideCopy(
  //         title: "보유/매도 점검(참고) · 과열 주의",
  //         subtitle:
  //             "현재가가 적정가 대비 ${gap.toStringAsFixed(0)}% 높습니다. 내재가치보다 비싼 구간이니, 수익을 확정할지 아니면 기업의 초과 성장을 더 믿고 기다릴지 결정이 필요한 시점입니다.",
  //         icon: Icons.warning_amber,
  //         color: Colors.orange,
  //       );
  //     } else if (under) {
  //       return SellGuideCopy(
  //         title: "보유/매도 점검(참고) · 안전마진 유효",
  //         subtitle:
  //             "현재가가 적정가 대비 ${gap.toStringAsFixed(0)}% 낮아 안전마진이 충분합니다. 시세 흔들림에 불안해하기보다, 기업의 이익 성장세와 사업의 본질이 변하지 않았는지 확인하며 보유하세요.",
  //         icon: Icons.fact_check,
  //         color: Colors.blueGrey,
  //       );
  //     } else {
  //       return SellGuideCopy(
  //         title: "보유/매도 점검(참고) · 가치 부합",
  //         subtitle:
  //             "현재 주가가 기업의 내재가치에 근접했습니다. 이제부터는 가격의 싸고 비쌈을 따지기보다, 기업의 '해자(경쟁력)'나 '경영진의 태도' 등 질적인 변화를 더 세밀하게 관찰해야 합니다.",
  //         icon: Icons.checklist,
  //         color: Colors.indigo,
  //       );
  //     }
  //   }

  //   if (over) {
  //     return SellGuideCopy(
  //       title: "Hold/Sell check · Caution on overheating",
  //       subtitle:
  //           "The current price is ${gap.toStringAsFixed(0)}% above fair value. Since the stock is trading above intrinsic value, this is the point where you decide whether to lock in gains or keep holding based on stronger long-term growth expectations.",
  //       icon: Icons.warning_amber,
  //       color: Colors.orange,
  //     );
  //   } else if (under) {
  //     return SellGuideCopy(
  //       title: "Hold/Sell check · Margin of safety remains",
  //       subtitle:
  //           "The current price is ${gap.toStringAsFixed(0)}% below fair value, which suggests a sufficient margin of safety. Rather than reacting to price swings, keep holding while checking whether earnings growth and business fundamentals remain intact.",
  //       icon: Icons.fact_check,
  //       color: Colors.blueGrey,
  //     );
  //   } else {
  //     return SellGuideCopy(
  //       title: "Hold/Sell check · Near fair value",
  //       subtitle:
  //           "The current price is close to intrinsic value. From here, rather than focusing only on whether the stock is cheap or expensive, it is more important to monitor qualitative changes such as moat and management attitude.",
  //       icon: Icons.checklist,
  //       color: Colors.indigo,
  //     );
  //   }
  // }

  static String epsTooltip(BuildContext context) {
    return isKo(context)
        ? 'EPS (주당순이익). 이 회사가 1년 동안 주식 1주당 실제 얼마를 벌어다 줬는지 보여주는 알짜 수익 지표입니다.'
        : 'EPS means earnings per share. It shows how much profit the company earned for each share over the year.';
  }

  static String bpsTooltip(BuildContext context) {
    return isKo(context)
        ? 'BPS (주당순자산). 회사를 지금 당장 다 정리한다면 주식 1주당 떨어지는 몫이 얼마인지 보여주는 든든한 기초 체력 숫자입니다.'
        : 'BPS means book value per share. It shows the net asset value belonging to each share if the company were liquidated.';
  }

  static String dpsTooltip(BuildContext context) {
    return isKo(context)
        ? 'DPS (주당배당금). 회사가 주주님께 주식 1주당 직접 현금으로 쥐여주는 보너스 금액입니다.'
        : 'DPS means dividend per share. It shows the actual cash dividend amount paid out for each share.';
  }

  static String dividendYieldTooltip(BuildContext context) {
    return isKo(context)
        ? '배당수익률은 현재 주가 대비 배당금 비율입니다. 내가 투자한 돈 대비 배당금이 몇 %나 되는지 보여줍니다.'
        : 'Dividend yield shows the dividend amount relative to the current stock price.';
  }

  static String dividendYieldExplain(BuildContext context, double yieldPct) {
    if (isKo(context)) {
      if (yieldPct <= 0) {
        return '배당수익률은 ${yieldPct.toStringAsFixed(2)}%입니다. 현재 기준으로는 배당이 없거나, 배당 매력이 거의 없는 수준으로 볼 수 있습니다.';
      } else if (yieldPct < 1) {
        return '배당수익률은 ${yieldPct.toStringAsFixed(2)}%입니다. 배당이 아예 없는 것은 아니지만, 수익률보다는 회사의 성장에 더 집중해야 할 시기입니다.';
      } else if (yieldPct < 3) {
        return '배당수익률은 ${yieldPct.toStringAsFixed(2)}%입니다. 은행 이자 정도의 무난한 배당입니다. 보너스를 챙기며 길게 가져가기에 적당한 수준이에요.';
      } else if (yieldPct < 5) {
        return '배당수익률은 ${yieldPct.toStringAsFixed(2)}%입니다. 배당 매력이 꽤 쏠쏠합니다. 꼬박꼬박 들어오는 현금을 중시하는 투자자라면 아주 반가운 숫자네요.';
      } else {
        return '배당수익률은 ${yieldPct.toStringAsFixed(2)}%입니다. 수익률이 상당히 높습니다! 다만 주가가 너무 많이 빠져서 일시적으로 높아진 건 아닌지, 배당을 계속 줄 수 있는 회사인지 체크가 필요합니다.';
      }
    }

    if (yieldPct <= 0) {
      return 'Dividend yield is ${yieldPct.toStringAsFixed(2)}%. At the moment, dividend appeal looks minimal or absent.';
    } else if (yieldPct < 1) {
      return 'Dividend yield is ${yieldPct.toStringAsFixed(2)}%. There is some dividend, but the income appeal is still limited.';
    } else if (yieldPct < 3) {
      return 'Dividend yield is ${yieldPct.toStringAsFixed(2)}%. It is not especially high, but it can still be seen as reasonable.';
    } else if (yieldPct < 5) {
      return 'Dividend yield is ${yieldPct.toStringAsFixed(2)}%. This is relatively decent for investors who also look at income.';
    } else {
      return 'Dividend yield is ${yieldPct.toStringAsFixed(2)}%. It looks high, but unusually high yield can sometimes reflect a temporary price drop.';
    }
  }

  static String perLevelExplain(BuildContext context, double per) {
    if (isKo(context)) {
      if (!per.isFinite || per <= 0) {
        return '**PER은 해석에 주의가 필요한 값입니다.** 현재 회사가 적자 상태이거나 일시적인 손실로 인해 숫자가 왜곡되었을 수 있습니다.';
      } else if (per < 8) {
        return '**현재 PER은** 벌어들이는 이익에 비해 **주가가 매우 낮습니다. 가성비가 아주 뛰어난 상태**이며, 시장에서 저평가된 진주일 가능성이 높습니다.';
      } else if (per < 12) {
        return '**현재 PER은 무난한 수준**입니다. 아주 낮지는 않지만, 이익에 비해 주가가 비싼 편도 아니라서 부담 없이 접근할 수 있는 구간입니다.';
      } else if (per < 20) {
        return '**현재 PER은 보통 수준**입니다. 주가가 이익만큼 제값을 받고 있으며, 아주 싸지도 비싸지도 않은 균형 잡힌 구간으로 볼 수 있습니다.';
      } else if (per < 30) {
        return '**현재 PER은 다소 높은 편**입니다. 시장이 미래 성장을 기대하며 가격을 높게 쳐주고 있으니, 그만큼 실적이 잘 따라오는지 지켜봐야 합니다.';
      } else {
        return '**현재 PER은 높은 편이고,** 미래 기대감이 많이 반영되어 있습니다. **비싼 만큼 제값을 하는 성장주**인지 꼼꼼히 따져봐야 합니다.';
      }
    }

    if (!per.isFinite || per <= 0) {
      return '**PER needs caution in interpretation.** The company may be loss-making or affected by one-off earnings.';
    } else if (per < 8) {
      return '**PER looks low,** which can mean the stock is trading at a relatively low level compared with earnings.';
    } else if (per < 12) {
      return 'PER is at a **reasonable level**. While not extremely low, it is not expensive relative to earnings, making it a comfortable entry range.';
    } else if (per < 20) {
      return 'PER looks **fairly normal**. The price is well-aligned with earnings, sitting in a balanced range that is neither cheap nor expensive.';
    } else if (per < 30) {
      return 'PER is **somewhat high**. The market is pricing in future growth expectations, so it is important to see if earnings can keep up.';
    } else {
      return 'PER is **high**. Since high growth expectations are already reflected, check if its performance justifies the premium price.';
    }
  }

  static String pbrLevelExplain(BuildContext context, double pbr) {
    if (isKo(context)) {
      if (!pbr.isFinite || pbr <= 0) {
        return '**PBR 해석에 주의가 필요합니다.** 재무 구조가 특수한 상황일 수 있으니 자산 현황을 별도로 확인하는 것이 좋습니다.';
      } else if (pbr < 0.8) {
        return '**PBR은 낮은 편입니다.** 회사가 가진 재산보다 주가가 더 싸네요. **저평가된 진주**를 찾는 분들에게 흥미로운 숫자입니다.';
      } else if (pbr < 1.2) {
        return '**현재 PBR은 1배 안팎**입니다. 주가가 회사의 자산 가치와 비슷한 수준에서 정직하게 평가받고 있는 구간입니다.';
      } else if (pbr < 2.0) {
        return '**현재 PBR은** 아주 낮지는 않지만, **지나치게 높지도 않은 편**입니다. 자산 가치를 적절히 인정받으며 안정적인 흐름을 보이고 있습니다.';
      } else if (pbr < 3.0) {
        return '**현재 PBR은 다소 높은 편**입니다. 자산 대비 주가에 어느 정도 프리미엄이 붙어 있으며, 이는 회사의 실력이나 브랜드 가치 때문일 수 있습니다.';
      } else {
        return '**현재 PBR은 높은 편**입니다. 자산 대비 주가가 꽤 높게 평가받는 **인기 종목**이네요. 높은 기대만큼 수익성(ROE)도 계속 좋은지 확인하세요.';
      }
    }

    if (!pbr.isFinite || pbr <= 0) {
      return '**Caution needed for PBR.** The financial structure might be unique, so it is best to check the asset status separately.';
    } else if (pbr < 0.8) {
      return 'PBR is **low**. The price is cheaper than the company\'s net assets, making it an attractive "hidden gem" for value investors.';
    } else if (pbr < 1.2) {
      return 'PBR is **around 1x**. The price is fairly valued, sitting right near the company\'s actual book value.';
    } else if (pbr < 2.0) {
      return 'PBR is **not very low, but not excessive**. It shows a stable trend, with the asset value being reasonably recognized.';
    } else if (pbr < 3.0) {
      return 'PBR is **somewhat high**. The price carries a premium over assets, likely reflecting the company’s brand or operational strength.';
    } else {
      return 'PBR is **high**. This is a **popular stock** valued well above its assets. Ensure its profitability (ROE) remains strong to support this level.';
    }
  }

  static String roeActionExplain(
    BuildContext context, {
    required double roe,
    required double roeOverR,
    required double requiredReturnPct,
  }) {
    if (isKo(context)) {
      if (!roe.isFinite || !roeOverR.isFinite) {
        return 'ROE와 ROE/r는 해석에 주의가 필요한 값입니다.';
      }

      if (roeOverR >= 1.2) {
        return '즉, 요구수익률 ${requiredReturnPct.toStringAsFixed(1)}%를 기준으로 봐도 현재 회사의 돈 버는 힘은 비교적 괜찮은 편입니다. 이런 경우에는 현재 주가가 아주 비싸지 않다면 매수 관점이 조금 더 편해질 수 있습니다.';
      }

      if (roeOverR >= 1.0) {
        return '즉, 요구수익률 ${requiredReturnPct.toStringAsFixed(1)}%를 기준으로 보면 현재 수익성은 기준을 간신히 넘기거나 내 기준치에 딱 맞게 벌고 있습니다. 기본기는 갖췄으니, 앞으로 실력이 더 늘어나는지 지켜봅시다.';
      }

      if (roeOverR >= 0.8) {
        return '즉, 요구수익률 ${requiredReturnPct.toStringAsFixed(1)}%를 기준으로 보면 현재 수익성은 조금 아쉬운 편입니다. 가격이 싸게 보이더라도, 그 가격을 뒷받침할 만큼 회사가 충분히 잘 벌고 있는지는 한 번 더 확인하는 편이 좋습니다.';
      }

      return '즉, 요구수익률 ${requiredReturnPct.toStringAsFixed(1)}%를 기준으로 보면 현재 내 기대치에는 조금 못 미치는 실력이네요. 단순히 싸다는 이유만으로 사기엔 **회사의 버는 힘**이 조금 아쉽습니다. 왜 수익성이 낮은지 먼저 생각해보는 편이 좋습니다.';
    }

    if (!roe.isFinite || !roeOverR.isFinite) {
      return 'ROE and ROE/r need caution in interpretation.';
    }

    if (!roe.isFinite || !roeOverR.isFinite) {
      return 'ROE and ROE/r values require caution in interpretation.';
    }

    if (roeOverR >= 1.2) {
      return 'The company’s earning power is solid compared to your required return of ${requiredReturnPct.toStringAsFixed(1)}%. If the current price is reasonable, this could be a favorable entry point.';
    }

    if (roeOverR >= 1.0) {
      return 'Profitability is meeting your required return of ${requiredReturnPct.toStringAsFixed(1)}%. It has a decent foundation; now watch if its performance improves further.';
    }

    if (roeOverR >= 0.8) {
      return 'Profitability is slightly below your required return of ${requiredReturnPct.toStringAsFixed(1)}%. Even if the price looks attractive, double-check if the company is earning enough to justify its value.';
    }

    return 'The company’s earning power is currently below your required return of ${requiredReturnPct.toStringAsFixed(1)}%. Instead of buying just because it looks "cheap," it is wise to consider why its profitability is struggling.';
  }

  static String perPbrActionExplain(
    BuildContext context, {
    required double per,
    required double pbr,
  }) {
    if (isKo(context)) {
      final perHigh = per.isFinite && per >= 20;
      final pbrHigh = pbr.isFinite && pbr >= 2.0;

      if (perHigh && pbrHigh) {
        return '즉, 이미 시장에서 **인기 만점인 종목**입니다. 기대감이 큰 만큼 앞으로도 실적이 계속 잘 나와야 현재의 높은 가치를 증명할 수 있습니다. 기대에 못 미칠 경우 변동성이 커질 수 있으니 주의하세요.';
      }

      if (perHigh) {
        return '즉, 현재 벌어들이는 이익보다 **미래 성장에 대한 기대감**이 주가에 많이 반영되어 있습니다. 성장의 속도가 투자자들의 눈높이를 따라오는지 계속 확인하는 것이 중요합니다.';
      }

      if (pbrHigh) {
        return '즉, 회사가 가진 자산보다 **주가가 높게 평가**되고 있습니다. 브랜드 가치나 독보적인 기술력이 있는 회사인지, 그 프리미엄이 계속 유지될 만큼 돈을 잘 벌고 있는지 따져보아야 합니다.';
      }

      if (per < 10 && pbr < 1.0) {
        return '즉, 현재 숫자만 보면 시장에서 아직 **주목받지 못한 알짜 종목**일 가능성이 있습니다. 다만 단순히 싼 것이 아니라, 성장이 멈춰서 낮은 평가를 받는 "저평가의 함정"은 아닌지 함께 살펴보세요.';
      }

      return '즉, 현재 주가는 아주 비싸지도, 싸지도 않은 **합리적인 균형 구간**에 있습니다. 이제부터는 회사가 시장의 예상보다 얼마나 더 성장하느냐가 주가 상승의 핵심 열쇠가 될 것입니다.';
    }

    final perHigh = per.isFinite && per >= 20;
    final pbrHigh = pbr.isFinite && pbr >= 2.0;

    if (perHigh && pbrHigh) {
      return 'This is a **market favorite** with high expectations! Since it trades at a premium, the company must deliver strong results to sustain its value. Be mindful of potential volatility.';
    }

    if (perHigh) {
      return 'The stock price reflects **high expectations for future growth** rather than current profits. It’s crucial to see if the company’s actual performance can keep up with investor sentiment.';
    }

    if (pbrHigh) {
      return 'The stock is **valued high relative to its assets**. Check if the company has the brand power or tech edge to justify this premium, and if its profitability can be sustained.';
    }

    if (per < 10 && pbr < 1.0) {
      return 'This could be an **undervalued gem** that the market hasn’t fully noticed yet. However, make sure it’s not a "value trap" where growth has stalled before you step in.';
    }

    return 'The current valuation is in a **fair and balanced range**. From here, the key driver for the stock price will be how much the company grows beyond market expectations.';
  }
}