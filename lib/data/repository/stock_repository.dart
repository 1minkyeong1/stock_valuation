// 인터페이스 / 추상화

class StockSearchItem {
  final String code;
  final String name;
  final String market; // "KOSPI", "KOSDAQ", "US" 등 표시용

  const StockSearchItem({
    required this.code,
    required this.name,
    required this.market,
  });
}

class StockFundamentals {
  final double eps;
  final double bps;
  final double dps;

  /// ✅ OpenDART/공공데이터에서 사용한 재무 기준 연도 (없으면 null)
  final int? year;

  /// ✅ 기준일(yyyymmdd) - 예: 20250930(3Q), 20250630(H1), 20251231(FY)
  final String? basDt;

  /// ✅ 표시용 라벨 - 예: "2025 3Q", "2024 FY"
  final String? periodLabel;

  // ✅ 지표별 기준 라벨/기준일/출처
  final String? epsLabel;
  final String? bpsLabel;
  final String? dpsLabel;

  final String? epsSource;
  final String? bpsSource;
  final String? dpsSource;

  // ==========================================================
  // ✅ 추가: “재무제표 금액” (신뢰/디버그용)
  // - 단위는 DART 응답(원 단위)이 기본이라 num?로 받는 게 안전
  // ==========================================================
  final num? revenue;    // 매출액
  final num? opIncome;   // 영업이익 (적자면 음수 가능)
  final num? netIncome;  // 당기순이익 (적자면 음수 가능)
  final num? equity;     // 자본총계

  // ✅ 추가: 어떤 조합으로 가져왔는지
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

    // ✅ 추가 필드
    this.revenue,
    this.opIncome,
    this.netIncome,
    this.equity,
    this.fsDiv,
    this.reprtCode,
    this.fsSource,
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

 /// 실시간 가격 + 기준일(표시용) + 주식수/시총(있으면)
  Future<PriceQuote> getPriceQuote(String code);

   Future<double> getPrice(String code) async => (await getPriceQuote(code)).price;

  /// ✅ targetYear가 null이면 repo가 "최신(분기/반기/연간 포함)"을 탐색
  Future<StockFundamentals> getFundamentals(String code, {int? targetYear});
}
