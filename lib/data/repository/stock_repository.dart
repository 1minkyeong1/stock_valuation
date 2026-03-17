// 인터페이스 / 추상화

class StockSearchItem {
  final String code;
  final String name;
  final String market; // "KOSPI", "KOSDAQ", "US" 등 표시용
  final String? logoUrl;

  const StockSearchItem({
    required this.code,
    required this.name,
    required this.market,
    this.logoUrl,
  });
}

class StockFundamentals {
  final double eps;        // 기업이 1주당 얼마의 이익을 창출했나?
  final double bps;        // 회상 망했을 때 자산 다 팔고 한주 당 받을 수 있는 최소금액
  final double dps;        // 배당금

  final int? year;      // OpenDART/공공데이터에서 사용한 재무 기준 연도
  final String? basDt;    // 기준일(yyyymmdd) 
  final String? periodLabel;    // 표시용 라벨 - 예: "2025 3Q", "2024 FY"

  // 지표별 기준 라벨/기준일/출처
  final String? epsLabel;
  final String? bpsLabel;
  final String? dpsLabel;

  final String? epsSource;
  final String? bpsSource;
  final String? dpsSource;

  final String? fsDiv;       // "CFS" / "OFS"
  final String? reprtCode;   // "11014"(3Q) / "11011"(FY) 등
  final String? fsSource;    // 예: "OpenDART fnlttSinglAcntAll"


  const StockFundamentals({
    required this.eps,
    required this.bps,
    required this.dps,
    this.year,
    this.basDt,
    this.periodLabel,
    this.epsLabel,
    this.bpsLabel,
    this.dpsLabel,
    this.epsSource,
    this.bpsSource,
    this.dpsSource,
    this.fsDiv,
    this.reprtCode,
    this.fsSource,
  });
}

// ==========================================================
//  “재무제표 금액” (신뢰/디버그용) 분리
// ==========================================================
class YearMetric {
  final int year;
  final double value;

  const YearMetric({
    required this.year,
    required this.value,
  });
}

class StockFinancialDetails {
  final StockFundamentals current;

  // 현재 재무 원본 요약
  final num? revenue;        // 매출액
  final num? opIncome;       // 영업이익 (적자면 음수 가능)
  final num? netIncome;      // 당기순이익 (적자면 음수 가능)
  final num? equity;         // 자본총계
  final num? liabilities;    // 부채총계

  // 버핏식 보조 지표
  final double? epsAvg3y;
  final double? roeAvg5y;

  // 추이
  final List<YearMetric> epsHistory;
  final List<YearMetric> roeHistory;

  // 안정성
  final List<int> lossYears;   // 적자 연도
  final double? debtRatio;     // 부채비율(%)
  final bool? hasDividend;     // 최근 배당 여부

  const StockFinancialDetails({
    required this.current,
    this.revenue,
    this.opIncome,
    this.netIncome,
    this.equity,
    this.liabilities,
    this.epsAvg3y,
    this.roeAvg5y,
    this.epsHistory = const [],
    this.roeHistory = const [],
    this.lossYears = const [],
    this.debtRatio,
    this.hasDividend,
  });
}


class PriceQuote {
  final double price;
  final String? basDt; // "yyyymmdd" 또는 null
  final int listedShares;
  final int marketCap;

  const PriceQuote({
    required this.price,
    this.basDt,
    this.listedShares = 0,
    this.marketCap = 0,
  });
}


abstract class StockRepository {
  Future<List<StockSearchItem>> search(String query);

  Future<PriceQuote> getPriceQuote(String code);

  Future<double> getPrice(String code) async => (await getPriceQuote(code)).price;

  Future<StockFundamentals> getFundamentals(String code, {int? targetYear});

  Future<StockFinancialDetails> getFinancialDetails(String code, {int? targetYear});
}

