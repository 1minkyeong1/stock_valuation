import 'package:flutter/foundation.dart';

class AliasHit {
  final String code; // US=ticker, KR=6-digit code
  final String name; // display name (korean alias key)
  const AliasHit({required this.code, required this.name});
}

class SearchAlias {
  // 한글 포함 여부
  static bool hasHangul(String s) => RegExp(r'[가-힣]').hasMatch(s);

  /// 공백/기호 제거 + 소문자
  static String norm(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[()\-_.,·]'), '');

  // -------------------------
  // 🇺🇸 US (한글/별칭 → 티커)
  // -------------------------
  static const Map<String, String> usKoToTicker = {
    '애플': 'AAPL',
    '마이크로소프트': 'MSFT',
    '테슬라': 'TSLA',
    '엔비디아': 'NVDA',
    '구글': 'GOOGL',
    '알파벳': 'GOOGL',
    '아마존': 'AMZN',
    '메타': 'META',
    '넷플릭스': 'NFLX',
    '코카콜라': 'KO',
    '코스트코': 'COST',
    '스타벅스': 'SBUX',
    '나이키': 'NKE',
    '월마트': 'WMT',
    '디즈니': 'DIS',
    '보잉': 'BA',
    'JP모건': 'JPM',
    // FMP에서 BRK.B/BRK-B 둘 다 보일 수 있음.
    // Worker가 "."를 못 받으면 여기 값을 'BRK-B'로 바꾸세요.
    '버크셔': 'BRK.B',
    '브로드컴': 'AVGO',
    'AMD': 'AMD',
    '인텔': 'INTC',
    '쿠팡': 'CPNG',
  };

  static final Map<String, AliasHit> _usExact = {
    for (final e in usKoToTicker.entries)
      norm(e.key): AliasHit(code: e.value, name: e.key),
  };

  // 부분매칭은 “한글 입력일 때만” (영문은 오탐 방지)
  static final List<String> _usKeysByLen = _usExact.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static AliasHit? resolveUs(String query) {
    final raw = query.trim();
    final q = norm(raw);

    // exact
    final exact = _usExact[q];
    if (exact != null) return exact;

    // partial (한글일 때만)
    if (hasHangul(raw)) {
      for (final k in _usKeysByLen) {
        if (q.contains(k)) return _usExact[k];
      }
    }
    return null;
  }

  // -------------------------
  // 🇰🇷 KR (한글/별칭 → 종목코드)
  // -------------------------
  static const Map<String, String> krKoToCode = {
    '네이버': '035420',
    '카카오': '035720',
    '삼성전자': '005930',
    'sk하이닉스': '000660',
    '현대차': '005380',
    '기아': '000270',
    'LG에너지솔루션': '373220',
    '셀트리온': '068270',
    '삼성바이오로직스': '207940',
    '포스코홀딩스': '005490',
  };

  static final Map<String, AliasHit> _krExact = {
    for (final e in krKoToCode.entries)
      norm(e.key): AliasHit(code: e.value, name: e.key),
  };

  static final List<String> _krKeysByLen = _krExact.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static AliasHit? resolveKr(String query) {
    final raw = query.trim();
    final q = norm(raw);

    final exact = _krExact[q];
    if (exact != null) return exact;

    if (hasHangul(raw)) {
      for (final k in _krKeysByLen) {
        if (q.contains(k)) return _krExact[k];
      }
    }
    return null;
  }

  // KR 종목코드(6자리)인지
  static bool looksLikeKrCode(String s) =>
      RegExp(r'^\d{6}$').hasMatch(s.trim());

  // US 티커인지(대략)
  static bool looksLikeUsTicker(String s) => RegExp(
          r'^[A-Z]{1,6}([.\-][A-Z0-9]{1,3})?$')
      .hasMatch(s.trim().toUpperCase());

  static void debugLog(String msg) {
    if (kDebugMode) debugPrint('[Alias] $msg');
  }
}
