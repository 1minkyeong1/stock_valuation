enum Market { kr, us }

extension MarketX on Market {
  String get label => this == Market.kr ? "국내" : "미국";
  String get key => this == Market.kr ? "KR" : "US";
}