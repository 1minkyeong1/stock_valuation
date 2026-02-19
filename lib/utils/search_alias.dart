import 'package:flutter/foundation.dart';

class AliasHit {
  final String code; // US=ticker, KR=6-digit code
  final String name; // display name (korean alias key)
  const AliasHit({required this.code, required this.name});
}

class SearchAlias {
  // 한글 포함 여부
  static bool hasHangul(String s) => RegExp(r'[ㄱ-ㅎㅏ-ㅣ가-힣]').hasMatch(s);

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
    '알파벳A': 'GOOGL',
    '알파벳C': 'GOOG',
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
    '버크셔': 'BRK-B',
    '브로드컴': 'AVGO',
    'AMD': 'AMD',
    '인텔': 'INTC',
    '쿠팡': 'CPNG',
    '팔란티어': 'PLTR',
    '마이크로스트래티지': 'MSTR',
    '아이온큐': 'IONQ',
    '마이크론테크놀로지':'MU',
    '시스코시스템즈': 'CSCO',
    '플란티어': 'PLTR',
    '램리서치': 'LRCX',
    '어플라이드': 'AMAT',
    '펩시코': 'PEP',
    'T모바일': 'TMUS',
    '페이스북': 'FB',
    '페이팔': 'PYPL',
    '머크': 'MRK',
    '스냅': 'SNAP',
    '알리바바': 'BABA',
    '팔로알토': 'PANW',
    '엑슨모빌': 'XOM',
    '샌디스크': 'SNDK',
    '쇼피파이': 'SHOP',
    '피앤지': 'PG',
    '피앤쥐': 'PG',
    '플록터앤드갬블': 'PG',
    '서비스나우': 'NOW',
    '코인베이스': 'COIN',
    '셰브론': 'CVX',
    '웨스턴디지털': 'WDC',
    '오라클': 'ORCL',
    '어플라이드머티어리얼즈': 'AMAT',
    '존슨앤존슨': 'JNJ',
    '아나로그디바이스': 'ADI',
    'JP모건체이스': 'JPM',
    '유나이티드헬스그룹': 'UNH',
    '비자': 'V',
    '카바나': 'CVNA',
    '앱러빈': 'APP',
    '인튜이트': 'INTU',
    '마스터카드': 'MA',
    '일라이릴리': 'LLY',
    '캐터필러': 'CAT',
    '골드만삭스': 'GS',
    '부킹홀딩스': 'BKNG',

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

    // partial (한글일 때만, 2글자 이상만)
    if (hasHangul(raw) && q.length >= 2) {
      for (final k in _usKeysByLen) {
        // ✅ 사용자가 짧게 입력해도 매칭되도록 k.contains(q)
        if (k.contains(q) || q.contains(k)) return _usExact[k];
      }
    }
    return null;
  }

  // -------------------------
  // 🇰🇷 KR (한글/별칭 → 종목코드)
  // -------------------------
  static const Map<String, String> krKoToCode = {
    '네이버': '035420',
    '엘지전자': '066570',
    '엘지': '003550',
    '엘지생활건강': '051900',
    '엘지이노텍': '011070',
    '엘지디스플레이': '034220',
    '엘에프': '093050',
    '에스케이': '034730',
    '에스케이하이닉스': '000660',
    '에스케이아이이테크놀로지': '361610',
    '에스케이케미칼': '285130',
    '에스케이바이오사이언스': '302440',
    '에스케이이노베이션': '096770',
    '에스케이이터닉스': '475150',
    '에이치제이중공업': '097230',
    '케이지모빌리티': '003620',
    '케이쥐모빌리티': '003620',
    '엔에이치투자증권': '005940',

  };

  static final Map<String, AliasHit> _krExact = {
    for (final e in krKoToCode.entries)
      norm(e.key): AliasHit(code: e.value, name: e.key),
  };

  static final List<String> _krKeysByLen = _krExact.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  static const int _minPartialLen = 2;

  static AliasHit? resolveKr(String query) {
    final raw = query.trim();
    final q = norm(raw);

    final exact = _krExact[q];
    if (exact != null) return exact;

    if (hasHangul(raw) && q.length >= _minPartialLen) {
      for (final k in _krKeysByLen) {
        // ✅ 입력이 prefix일 때 매칭 (아크 → 아크릴)
        if (k.startsWith(q) || k.contains(q)) return _krExact[k];
      }
    }
    return null;
  }

  // ✅ KR 코드 통일: 6자리 숫자 + "0007C0" 같은 5숫자+영숫자1
  static bool looksLikeKrCode(String s) {
    final t = s.trim().toUpperCase().replaceAll(' ', '');
    if (RegExp(r'^\d{4,6}$').hasMatch(t)) return true;       // 4~6자리 숫자
    if (RegExp(r'^\d{5}[A-Z0-9]$').hasMatch(t)) return true; // 0007C0
    return false;
  }

  static bool looksLikeUsTicker(String s) =>
      RegExp(r'^[A-Z]{1,6}([.\-][A-Z0-9]{1,3})?$')
          .hasMatch(s.trim().toUpperCase());

  static void debugLog(String msg) {
    if (kDebugMode) debugPrint('[Alias] $msg');
  }
}
