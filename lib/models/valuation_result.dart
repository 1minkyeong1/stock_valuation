class ValuationResult {
  final double roePct;               // ROE       = 주주가 맡긴 자본을 얼마나 효율적으로 활용 해 수익을 냈는가?
  final double roeOverR;             // ROE / r   = 내가 바라는 최소한의 수익률(배)
  final double fairPrice;            // 적정주가    = 현재 기업의 적정한 주의 가격
  final double gapPct;               // 현황평가    = 현재 주가의 평가 (100% 미만이면 저평가)
  final double expectedReturnPct;    // 기대수익률  = 적정가까지의 상승 여지
  final double dividendYieldPct;     // 배당수익률  = 1주당 배당금이 주가 대비 얼마나 되는지를 나타내는 비율
  final double per;                  // PER       = 현금회수하려면 몇 년정도 걸리는가?
  final double pbr;                  // PBR       = 회사 자산보다 몇 배나 비싸게 거래되고 있는가?

  const ValuationResult({
    required this.roePct,
    required this.roeOverR,
    required this.fairPrice,
    required this.gapPct,
    required this.expectedReturnPct,
    required this.dividendYieldPct,
    required this.per,
    required this.pbr,
  });
}
