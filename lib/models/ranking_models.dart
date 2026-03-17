// lib/models/ranking_models.dart

double? _asDoubleNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = '$v'.trim();
  if (s.isEmpty) return null;

  final cleaned = s
      .replaceAll('%', '')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(',', '')
      .trim();

  return double.tryParse(cleaned);
}

num? _asNumNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  final s = '$v'.trim();
  if (s.isEmpty) return null;
  return num.tryParse(s);
}

class KrRankItem {
  final String code;
  final String name;
  final String market;

  final num? price;
  final num? change; 
  final num? changePct;
  final String? logoUrl; 

  final num? per;
  final num? pbr;
  final num? eps;
  final num? bps;
  final num? score;

  KrRankItem({
    required this.code,
    required this.name,
    required this.market,
    this.price,
    this.change,
    this.changePct,
    this.logoUrl,
    this.per,
    this.pbr,
    this.eps,
    this.bps,
    this.score,
  });

  factory KrRankItem.fromJson(Map<String, dynamic> j) {
    final rawCode =
        (j['code'] ?? j['symbol'] ?? j['ticker'] ?? '').toString().trim();

    final cleanedCode = rawCode.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final code = cleanedCode.padLeft(6, '0');

    final price = _asNumNullable(j['price']);
    final change = _asNumNullable(j['change']) ?? _asNumNullable(j['prdy_vrss']);
    final changePct =
        _asNumNullable(j['changePct']) ?? _asNumNullable(j['prdy_ctrt']);

    return KrRankItem(
      code: code,
      name: (j['name'] ?? j['nameKo'] ?? j['company'] ?? code).toString().trim(),
      market: (j['market'] ?? 'KRX').toString().trim(),
      price: price,
      change: change,
      changePct: changePct,
      logoUrl: (j['logoUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (j['logoUrl']).toString().trim(),
      per: _asNumNullable(j['per']),
      pbr: _asNumNullable(j['pbr']),
      eps: _asNumNullable(j['eps']),
      bps: _asNumNullable(j['bps']),
      score: _asNumNullable(j['score']),
    );
  }
}

class UsRankItem {
  final String tickerDisplay;
  final String tickerFmp;
  final String name;

  final num? price;
  final num? change;
  final num? changePct;
  final String? logoUrl;

  final num? eps;
  final num? bps;
  final num? dps;

  final num? per;
  final num? pbr;
  final num? divYieldPct;

  final num? fairPrice;
  final num? undervaluePct;

  UsRankItem({
    required this.tickerDisplay,
    required this.tickerFmp,
    required this.name,
    this.price,
    this.change,
    this.changePct,
    this.logoUrl,
    this.eps,
    this.bps,
    this.dps,
    this.per,
    this.pbr,
    this.divYieldPct,
    this.fairPrice,
    this.undervaluePct,
  });

  factory UsRankItem.fromJson(Map<String, dynamic> j) {
    final rawTf =
        (j['tickerFmp'] ?? j['symbol'] ?? j['ticker'] ?? '').toString().trim();
    final tfUp = rawTf.toUpperCase();

    final tickerFmp = tfUp.replaceAll('.', '-');
    final rawDisp = (j['ticker'] ?? j['symbol'] ?? '').toString().trim();
    final dispBase = rawDisp.isNotEmpty ? rawDisp.toUpperCase() : tickerFmp;
    final tickerDisplay = dispBase.replaceAll('-', '.');

    return UsRankItem(
      tickerDisplay: tickerDisplay,
      tickerFmp: tickerFmp,
      name: (j['name'] ?? j['company'] ?? j['companyName'] ?? tickerDisplay)
          .toString()
          .trim(),
      price: _asNumNullable(j['price']),
      change: _asNumNullable(j['change']),
      changePct: _asNumNullable(j['changePct']),
      logoUrl: (j['logoUrl'] ?? '').toString().trim().isEmpty
          ? null
          : (j['logoUrl']).toString().trim(),
      eps: _asNumNullable(j['eps']),
      bps: _asNumNullable(j['bps']),
      dps: _asNumNullable(j['dps']),
      per: _asNumNullable(j['per']),
      pbr: _asNumNullable(j['pbr']),
      divYieldPct: _asNumNullable(j['divYieldPct']),
      fairPrice: _asNumNullable(j['fairPrice']),
      undervaluePct: _asNumNullable(j['undervaluePct']),
    );
  }
}

class QuoteLite {
  final double price;
  final double change;
  final double changePct;

  QuoteLite({required this.price, required this.change, required this.changePct});

  /// ✅ KR 시세 응답 보강:
  /// - Worker가 change/changePct로 주면 그대로 사용
  /// - KIS 형태(prdy_vrss, prdy_ctrt)도 흡수
  /// - (가능하면) sign 코드(prdy_vrss_sign)가 있으면 하락/상승 부호 보정
  static QuoteLite fromKrPrice(Map<String, dynamic> m) {
    double toD(dynamic v) => _asDoubleNullable(v) ?? 0.0;

    final price = toD(m['price']);

    // change
    double ch = 0.0;
    if (m.containsKey('change')) {
      ch = toD(m['change']);
    } else {
      ch = toD(m['prdy_vrss']);
    }

    // changePct
    double cp = 0.0;
    if (m.containsKey('changePct')) {
      cp = toD(m['changePct']);
    } else {
      cp = toD(m['prdy_ctrt']);
    }

    // ✅ sign 보정(있을 때만)
    // KIS sign 코드가 내려오는 형태면(예: prdy_vrss_sign) 부호를 맞춰줌
    // (환경에 따라 코드 정의가 다를 수 있어, 다운 후보를 넓게 잡음)
    final sign = (m['prdy_vrss_sign'] ?? m['sign'] ?? '').toString().trim();
    if (sign.isNotEmpty) {
      final downCodes = {'4', '5'}; // 필요 시 Worker/KIS 문서에 맞춰 조정
      final upCodes = {'1', '2'};
      if (downCodes.contains(sign)) ch = -ch.abs();
      if (upCodes.contains(sign)) ch = ch.abs();
    }

    return QuoteLite(price: price, change: ch, changePct: cp);
  }

  /// ✅ FMP quote array: [{ price, change, changesPercentage }]
  static QuoteLite? fromFmpQuoteArray(dynamic obj) {
    if (obj is! List || obj.isEmpty) return null;
    final row = obj.first;
    if (row is! Map) return null;
    final m = row.cast<String, dynamic>();

    final price = _asDoubleNullable(m['price']) ?? 0.0;
    if (price <= 0) return null;

    final change = _asDoubleNullable(m['change']) ?? 0.0;
    final cp = _asDoubleNullable(m['changesPercentage']) ??
        _asDoubleNullable(m['changePct']) ??
        0.0;

    return QuoteLite(price: price, change: change, changePct: cp);
  }
}