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

  // ✅ 재무제표 PDF용
  final num? revenue;
  final num? opIncome;
  final num? netIncome;
  final num? equity;
  final num? liabilities;


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
    this.revenue,
    this.opIncome,
    this.netIncome,
    this.equity,
    this.liabilities,
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

  final String? reportedCurrency;  // 통화
  final double? fxRateToUsd; // 1 reporting currency = ? USD

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
    this.reportedCurrency,
    this.fxRateToUsd,
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

class PriceChartPoint {
  final String ym;     // 예: 2023-04
  final String date;   // 예: 2023-04-28
  final double close;

  const PriceChartPoint({
    required this.ym,
    required this.date,
    required this.close,
  });

  factory PriceChartPoint.fromJson(Map<String, dynamic> json) {
    return PriceChartPoint(
      ym: (json['ym'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      close: (json['close'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FibLevel {
  final double ratio;   // 0.0, 0.236, 0.382 ...
  final double price;

  const FibLevel({
    required this.ratio,
    required this.price,
  });

  String get label {
    if (ratio == 0.0) return '0%';
    if (ratio == 1.0) return '100%';
    return '${(ratio * 100).toStringAsFixed(ratio == 0.5 ? 0 : 1)}%';
  }

  factory FibLevel.fromJson(Map<String, dynamic> json) {
    return FibLevel(
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


class PriceFibChartData {
  final String market;
  final String code;
  final int rangeMonths;

  final List<PriceChartPoint> points;
  final List<FibLevel> fibLevels;

  final double highestPrice;
  final String? highestDate;

  final double lowestPrice;
  final String? lowestDate;

  final double currentPrice;
  final String? currentDate;

  final double positionPct; // 0~100

  const PriceFibChartData({
    required this.market,
    required this.code,
    required this.rangeMonths,
    required this.points,
    required this.fibLevels,
    required this.highestPrice,
    required this.highestDate,
    required this.lowestPrice,
    required this.lowestDate,
    required this.currentPrice,
    required this.currentDate,
    required this.positionPct,
  });

  factory PriceFibChartData.fromJson(Map<String, dynamic> json) {
    final pointsJson = (json['points'] as List?) ?? const [];
    final fibJson = (json['fibLevels'] as List?) ?? const [];

    return PriceFibChartData(
      market: (json['market'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      rangeMonths: (json['rangeMonths'] as num?)?.toInt() ?? 36,
      points: pointsJson
          .map((e) => PriceChartPoint.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      fibLevels: fibJson
          .map((e) => FibLevel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      highestPrice: (json['highestPrice'] as num?)?.toDouble() ?? 0.0,
      highestDate: json['highestDate']?.toString(),
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ?? 0.0,
      lowestDate: json['lowestDate']?.toString(),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      currentDate: json['currentDate']?.toString(),
      positionPct: (json['positionPct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


abstract class StockRepository {
  Future<List<StockSearchItem>> search(String query);

  Future<PriceQuote> getPriceQuote(String code);

  Future<double> getPrice(String code) async => (await getPriceQuote(code)).price;

  Future<StockFundamentals> getFundamentals(String code, {int? targetYear});

  Future<StockFinancialDetails> getFinancialDetails(String code, {int? targetYear});

  Future<PriceFibChartData> getPriceFibChart(String code, {int months = 36});
}

