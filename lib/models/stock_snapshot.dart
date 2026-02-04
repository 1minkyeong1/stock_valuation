class StockSnapshot {
  final String name;      // 종목명
  final String ticker;    // 종목코드/티커(예: 005930)
  final double price;     // 현재가
  final double bps;       // BPS
  final double eps;       // EPS
  final double dps;       // DPS (없으면 0)

  const StockSnapshot({
    required this.name,
    required this.ticker,
    required this.price,
    required this.bps,
    required this.eps,
    required this.dps,
  });
}
