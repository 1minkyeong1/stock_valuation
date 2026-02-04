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

   // ✅  지표별 기준 라벨/기준일/출처
  final String? epsLabel;   // 예: "TTM (as of 2025-09-30)" 또는 "2025 3Q"
  final String? bpsLabel;   // 예: "BS 2025-09-30"
  final String? dpsLabel;   // 예: "Dividends (last 8) up to 2025-12-15"

  final String? epsSource;  // 예: "key-metrics-ttm" / "income-statement(sum4Q)"
  final String? bpsSource;  // 예: "key-metrics-ttm" / "balance-sheet(equity/shares)"
  final String? dpsSource;  // 예: "key-metrics-ttm" / "stable/dividends(sum)"

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
