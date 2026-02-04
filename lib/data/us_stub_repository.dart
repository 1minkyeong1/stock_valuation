import 'stock_repository.dart';

class UsStubRepository implements StockRepository {
  String _guessExchange(String ticker) {
    final t = ticker.trim().toUpperCase();
    if (t.isEmpty) return "US";
    if (t.length <= 3) return "NYSE";
    return "NASDAQ";
  }

  @override
  Future<List<StockSearchItem>> search(String q) async {
    final t = q.trim().toUpperCase();
    if (t.isEmpty) return [];

    final ex = _guessExchange(t);

    return [
      StockSearchItem(code: t, name: t, market: ex),
    ];
  }

  @override
  Future<double> getPrice(String code) async => 0.0;

  @override
  Future<StockFundamentals> getFundamentals(String code, {int? targetYear}) async {
    return const StockFundamentals(
      eps: 0,
      bps: 0,
      dps: 0,
      year: null,
      basDt: null,
      periodLabel: "STUB",
    );
  }

  @override
  Future<PriceQuote> getPriceQuote(String code) async {
    // 스텁이니까 일단 0 반환
    return const PriceQuote(
      price: 0,
      basDt: null,
      listedShares: 0,
      marketCap: 0,
    );
  }
}
