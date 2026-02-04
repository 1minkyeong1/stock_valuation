import '../models/market.dart';
import 'stock_repository.dart';

class RepoHub {
  final StockRepository kr;
  final StockRepository us;

  RepoHub({required this.kr, required this.us});

  StockRepository _repo(Market m) => (m == Market.kr) ? kr : us;

  Future<List<StockSearchItem>> search(Market market, String q) {
    return _repo(market).search(q);
  }

  Future<double> getPrice(Market market, String codeOrSymbol) {
    return _repo(market).getPrice(codeOrSymbol);
  }

  Future<StockFundamentals> getFundamentals(
    Market m,
    String codeOrSymbol, {
    int? targetYear,
  }) {
    return _repo(m).getFundamentals(codeOrSymbol, targetYear: targetYear);
  }

    Future<PriceQuote> getPriceQuote(Market market, String codeOrSymbol) {
    return _repo(market).getPriceQuote(codeOrSymbol);
  }
}
