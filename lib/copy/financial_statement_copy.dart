import 'package:flutter/material.dart';
import 'package:stock_valuation_app/models/market.dart';

class FinancialStatementCopy {
  static bool isKo(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ko';
  }

  static String pageTitle(BuildContext context, String name) {
    return isKo(context) ? '$name 재무제표' : '$name Financial Statements';
  }

  static String pdfSaveTooltip(BuildContext context) {
    return isKo(context) ? 'PDF 저장' : 'Save PDF';
  }

  static String reloadTooltip(BuildContext context) {
    return isKo(context) ? '새로고침' : 'Refresh';
  }

  static String loadFailed(BuildContext context, String error) {
    return isKo(context) ? '불러오기 실패: $error' : 'Load failed: $error';
  }

  static String retry(BuildContext context) {
    return isKo(context) ? '다시 시도' : 'Retry';
  }

  static String loadingHint(BuildContext context) {
    return isKo(context)
        ? '재무제표 계산 중...'
        : 'Calculating financial statements...';
  }

  static String noData(BuildContext context) {
    return isKo(context) ? '데이터가 없습니다.' : 'No data available.';
  }

  static String sourceText(BuildContext context, Market market) {
    if (market == Market.kr) {
      return isKo(context)
          ? '출처: OpenDART 재무 + KIS 시세'
          : 'Source: OpenDART financials + KIS quotes';
    }
    return isKo(context)
        ? '출처: FMP(제공 범위에 따라 값이 비어 있을 수 있음)'
        : 'Source: FMP (some values may be empty depending on coverage)';
  }

  static String metaDate(BuildContext context, String date) {
    return isKo(context) ? '기준일 $date' : 'Date $date';
  }

  static String emptyHint(BuildContext context) {
    return isKo(context)
        ? "재무 원본 금액(매출/영업이익/순이익/자본총계/부채총계)을 가져오지 못했습니다.\n"
            "공시 반영 전이거나(승인/갱신 대기), 항목명이 달라 파싱이 실패했을 수 있어요.\n\n"
            "우측 상단 새로고침을 눌러 다시 시도해보세요."
        : "Failed to load the raw financial amounts "
            "(revenue / operating income / net income / equity / liabilities).\n"
            "The filing may not be reflected yet, or parsing may have failed because the item names differ.\n\n"
            "Please tap refresh in the top-right corner and try again.";
  }

  static String fsSummaryTitle(BuildContext context) {
    return isKo(context) ? '재무 요약(원본)' : 'Financial Summary (Raw)';
  }

  static String revenue(BuildContext context) {
    return isKo(context) ? '매출' : 'Revenue';
  }

  static String opIncome(BuildContext context) {
    return isKo(context) ? '영업이익' : 'Operating income';
  }

  static String netIncome(BuildContext context) {
    return isKo(context) ? '순이익' : 'Net income';
  }

  static String equity(BuildContext context) {
    return isKo(context) ? '자본총계' : 'Total equity';
  }

  static String liabilities(BuildContext context) {
    return isKo(context) ? '부채총계' : 'Total liabilities';
  }

  static String incomeStatement(BuildContext context) {
    return isKo(context) ? '손익계산서' : 'Income statement';
  }

  static String epsBasis(BuildContext context) {
    return isKo(context) ? 'EPS 계산 근거' : 'Basis for EPS';
  }

  static String bpsBasis(BuildContext context) {
    return isKo(context) ? 'BPS 계산 근거' : 'Basis for BPS';
  }

  static String balanceSheet(BuildContext context) {
    return isKo(context) ? '재무상태표' : 'Balance sheet';
  }

  static String buffettAssistTitle(BuildContext context) {
    return isKo(context) ? '버핏식 보조 지표' : 'Buffett-style Helper Metrics';
  }

  static String avg3yEps(BuildContext context) {
    return isKo(context) ? '3년 평균 EPS' : '3Y average EPS';
  }

  static String avg5yRoe(BuildContext context) {
    return isKo(context) ? '5년 평균 ROE' : '5Y average ROE';
  }

  static String trendTitle(BuildContext context) {
    return isKo(context) ? '장기 추이' : 'Long-term Trend';
  }

  static String yearlyEps(BuildContext context) {
    return isKo(context) ? '연도별 EPS' : 'EPS by year';
  }

  static String yearlyRoe(BuildContext context) {
    return isKo(context) ? '연도별 ROE' : 'ROE by year';
  }

  static String yearLabel(BuildContext context, int year) {
    return isKo(context) ? '${year}년' : '$year';
  }

  static String stabilityTitle(BuildContext context) {
    return isKo(context) ? '안정성' : 'Stability';
  }

  static String lossYearsTitle(BuildContext context) {
    return isKo(context) ? '적자 여부' : 'Loss years';
  }

  static String debtRatioTitle(BuildContext context) {
    return isKo(context) ? '부채비율' : 'Debt ratio';
  }

  static String recentDividendTitle(BuildContext context) {
    return isKo(context) ? '최근 배당' : 'Recent dividend';
  }

  static String none(BuildContext context) {
    return isKo(context) ? '없음' : 'None';
  }

  static String yes(BuildContext context) {
    return isKo(context) ? '있음' : 'Yes';
  }

  static String no(BuildContext context) {
    return isKo(context) ? '없음' : 'No';
  }

  static String noteText(BuildContext context) {
    return isKo(context)
        ? "※ 안내\n"
            "- EPS/BPS/DPS는 적정가 계산에 직접 사용된 값입니다.\n"
            "- 장기 지표는 종목의 질을 길게 보기 위한 참고 정보입니다.\n"
            "- 공시 반영 시점이나 데이터 제공 범위에 따라 일부 값은 비어 있을 수 있습니다."
        : "※ Notes\n"
            "- EPS/BPS/DPS are the values directly used in the fair value calculation.\n"
            "- Long-term metrics are reference indicators for assessing business quality over time.\n"
            "- Some values may be empty depending on filing timing or data coverage.";
  }

  static String fsSourceLabel(BuildContext context, String source) {
    return isKo(context) ? '재무 출처: $source' : 'Financial source: $source';
  }

  static String pdfNoData(BuildContext context) {
    return isKo(context) ? '재무 데이터가 없습니다.' : 'No financial data available.';
  }

  static String pdfCanceled(BuildContext context) {
    return isKo(context) ? 'PDF 저장이 취소되었습니다.' : 'PDF save was canceled.';
  }

  static String pdfStarted(BuildContext context) {
    return isKo(context)
        ? '재무제표 PDF 저장/공유를 시작했습니다.'
        : 'Started saving/sharing the financial statement PDF.';
  }

  static String pdfFailed(BuildContext context, Object e) {
    return isKo(context) ? 'PDF 저장 실패: $e' : 'PDF save failed: $e';
  }

  static String pdfSourceText(BuildContext context, Market market) {
    if (market == Market.kr) {
      return isKo(context)
          ? '출처: OpenDART 재무 + KIS 시세'
          : 'Source: OpenDART financials + KIS quotes';
    }
    return isKo(context)
        ? '출처: FMP 재무 데이터'
        : 'Source: FMP financial data';
  }
}