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
    '팔란티어테크놀로지스': 'PLTR',
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
    '아발론글로보케어': 'ALBT',
    '안텔로페엔터프라이즈홀딩스': 'AEHL',
    '큐라넥스파마슈티컬스': 'CURX',
    '이오스에너지엔터프라이시스': 'EOSE',
    '랙스페이스테크놀로지': 'RXT',
    '누홀딩스': 'NU',
    '플러그파워': 'PLUG',
    '아메리칸에어라인스그룹': 'AAL',
    '티엔루이시앙홀딩스': 'TIRX',
    '써클인터넷그룹': 'CRCL',
    '뉴스케일파워': 'SMR',
    '블루햇': 'BHAT',
    '소파이테크놀로지스': 'SOFI',
    '온다스': 'ONDS',
    '버터플라이네트워크': 'BFLY',
    '얼라이트': 'ALIT',
    '포드모터': 'F',
    '이롱파워홀딩': 'ELPW',
    '리게티컴퓨팅': 'RGTI',
    '오픈도어테크놀로지스': 'OPEN',
    '트레이드데스크': 'TTD',
    '뱅크오브아메리카': 'BAC',
    '유아이패스': 'PATH',
    '아파트먼트인베스트먼트&매니지먼트': 'AIV',
    '마라홀딩스': 'MARA',
    '거화ADR': 'QH',
    '블루아울캐피털': 'OWL',
    '노키아ADR': 'NOK',
    '사운드하운드AI': 'SOUN',
    '디웨이브퀀텀': 'QBTS',
    '조비에비에이션': 'JOBY',
    '비트마인이머전' : 'BMNR',
    '발레ADR': 'VALE',
    '빅베이AI홀딩스': 'BBAI',
    '어레이': 'ARRY',
    '이뮤니티바이오': 'IBRX',
    '아처': 'ACHR',
    '데니슨마인스': 'DNN',
    '니오ADR': 'NIO',
    '노보노디스크': 'NVO',
    '비욘드미트': 'BYND',
    '켄뷰': 'KVUE',
    '방쿠브라데스쿠': 'BBD',
    '고사머바이오': 'GOSS',
    'AT앤T': 'T',
    'AT&T': 'T',
    '스플래시베버리지그룹': 'SBEV',
    '맨카인드': 'MNKD',
    '트랜드오션': 'RIG',
    'XCF글로벌': 'SAFX',
    'AMC엔터테인먼트': 'AMC',
    '퀸스테라퓨틱스': 'QNCX',
    'C3AI': 'AI',
    '화이자': 'PFE',
    'B2골드': 'BTG',
    '레드와이어': 'RDW',
    'UWM홀딩스': 'UWMC',
    '힘스&허즈': 'HIMS',
    '슈퍼마이크로컴퓨터': 'SMCI',
    '컴퍼스': 'COMP',
    '비트팜즈': 'BITF',
    '코어위브': 'CRWV',
    '그랩홀딩스': 'CRAB',
    '세일즈포스': 'CRM',
    '아이렌': 'IREN',
    'HP': 'HPQ',
    '퍼스트머제스틱실버': 'AG',
    '아이치이': 'IQ',
    '스프롯피지컬실버': 'PSLV',
    '테라울프': 'WULF',
    '사이퍼마이닝': 'CIFR',
    '컴캐스트': 'CMCSA',
    'X3홀딩스': 'XTKG',
    '노바백스': 'NVAX',
    '버라이존': 'VZ',
    '리비안': 'RIVN',
    '카이로스파르마': 'KAPA',
    '로빈후드': 'HOOD',
    'X웰': 'XWEL',
    '이오밴스바이오테라퓨틱스': 'IOVA',
    '우버': 'UBER',
    '로켓컴퍼니스' : 'RKT',
    '쾨르마이닝': 'CDE',
    '텔라닥헬스': 'TDOC',
    '비트디지털': 'BTBT',
    '스텔란티스':'STLA',
    '버바이오테크놀로지': 'VIR',
    '나비타스세미컨덕터': 'NVTS',
    '제론': 'GERN',
    'CCC인텔리전트': 'CCC',
    '코스모스에너지': 'KOS',
    '이타우우니방쿠': 'ITUB',
    '헤클라마이닝': 'HL',
    '방코산탄데르': 'SAN',
    '넥스트에라에너지': 'NEE',
    '워너브로스디스커버리': 'WBD',
    '비치프로퍼티스': 'VICI',
    '노르웨이지안크루즈라인': 'NCLH',
    '데이터볼트AI': 'DVLT',
    '헌팅턴뱅크세어스': 'HBAN',
    '프리모브랜드': 'PRMB',
    '퍼시픽가스앤일렉트릭': 'PCG',
    '퍼시픽가스&일렉트릭': 'PCG',
    '인포시스': 'INFY',
    '크리스피크림': 'DNUT',
    '클린스파크': 'CLSK',
    'FSKKR캐피털': 'FSK',
    '웰스파고': 'WFC',
    '비아트리스': 'VTRS',
    '로켓랩': 'RKLB',
    '블록': 'XYZ',
    'SM에너지': 'SM',
    '뉴타닉스': 'NTNX',
    '스트래티지': 'MSTR',
    '프리포트맥모란': 'FCX',
    '페르미안리소시스': 'PR',
    '유니큐어': 'QURE',
    '코닝': 'GLW',
    '퀀텀컴퓨팅': 'QUBT',
    '핀터레스트': 'PINS',
    '페트로브라스': 'PBR',
    '인카넥스헬스케어': 'IXHL',
    '아메리칸비트코인': 'ABTC',
    '시저스엔터테인먼트': 'CZR',
    '오로라이노베이션': 'AUR',
    '암베브': 'ABEV',
    '리커젼파마슈티컬스': 'RXRX',
    '어비디티바이오사이언시스': 'RNAM',
    '줌커뮤니케이션스': 'ZM',
    '배이텍스에너지': 'BTE',
    '스노우플레이크': 'SNOW',
    '휴렛패커드엔터프라이즈': 'HPE',
    '바릭마이닝': 'B',
    '유니티소프트웨어': 'U',
    '리프트': 'LYFT',
    '퀀텀스케이프': 'QS',
    '세노버스에너지': 'CVE',
    '파라마운트스카이댄스': 'PSKY',
    '어플라이드디지털': 'APLD',
    '카니발': 'CCL',
    '릴라이언스글로벌그룹': 'EZRA',
    '큐리그닥터페퍼': 'KDP',
    '셀시어스홀딩스': 'CELH',
    '젯AI': 'JTAI',
    '세이버': 'SABR',
    '루멘테크놀로지스': 'LUMN',
    '선런': 'RUN',
    '씨티그룹': 'C',
    '인튜이티브머신스': 'LUNR',
    'T1에너지': 'YE',
    '펜엔터테인먼트': 'PENN',
    '클래리베이트': 'CLVT',
    '키코프': 'KEY',
    'TSMC타이완반도체제조': 'TSM',
    '헬스케어크아이앵글': 'HCTI',
    '델데크놀로지': 'DELL',
    '노르딕아메리칸탱커': 'NAT',
    '비즐라실버': 'VZLA',
    '클래스오버홀딩스': 'KIDZ',
    '콘아그라브랜즈': 'CAG',
    '와비파커': 'WRBY',
    '로이즈뱅킹': 'LYG',
    '제트블루에어웨이스': 'JBLU',
    '위프로': 'WIT',
    '사이닝데이스포츠': 'SGN',
    '리전스파이낸셜': 'RF',
    '코그니전트테크놀로지솔루션': 'CTSH',
    '보스턴사이언티픽': 'BSX',
    '라리마테라퓨틱스': 'LRMR',
    '바이탈팜스': 'VITL',
    '이노빅스': 'ENVX',
    '코인베이스글로벌': 'COIN',
    '라이엇플랫폼즈': ' RIOT',
    '드래프트킹즈홀딩스': 'DKNG',
    '바클레이즈': 'BCS',
    '제르다우': 'GGB',
    '엔데버실버': 'EXK',
    '프로퓨사': 'PFSA',
    '킨더모건': 'KMI',
    '마벨테크놀로지': 'MRVL',
    '지아드': 'JDZG',
    '크래프트하인즈': 'KHC',
    '뉴골드': 'NGD',
    '리비바파마슈티컬스': 'RVPH',
    '패러데이퓨처인텔리전트': 'FFAI',
    '푸보티비': 'FUBO',
    '허츠글로벌': 'HTZ',
    '치폴레멕시칸그릴': 'CMG',
    '굿알엑스': 'GDRX',
    '아르셀엑스': 'ACLX',
    'USA레어어스': 'USAR',
    '제타글로벌': 'ZETA',
    '토스트': 'TOST',
    '렐엑스': 'RELX',
    '옥시덴털페트롤리움': 'OXY',
    '클리블랜드클리프스': 'CLF',
    '코파트': 'CPRT',
    '하이퍼스케일데이터': 'GPUS',
    '사우스웨스트에어라인스': '',
    '오디티테크': 'ODD',
    '웨스턴유니온': 'WU',
    '리치테크로보틱스': 'RR',
    'US뱅코프': 'USB',
    '액센추어': 'ACN',
    '엑센추어': 'ACN',
    '블룸에너지': 'BE',
    '인티크레이티드미디어': 'IMTE',
    '차임파이낸셜': 'CHYM',
    '라이프스탠스': 'LFST',
    '몬덜리즈': 'MDLZ',
    '세이블오프쇼어': 'SOC',
    'SRX헬스솔루션스': 'SRXH',
    '브리스톨마이어스스큅': 'BMY',
    '아틀라시안': 'TEAM',
    '크레센트에너지': 'CRGY',
    '헤일리온': 'HLN',
    '리졸브AI': 'RZLV',
    '비스탄스네트웍스': 'VISN',
    '머크앤코': 'MRK',
    '에버퓨어': 'PSTG',
    '재너스핸더슨': 'JHG',
    '워크데이': 'WDAY',
    '할리버튼': 'HAL',
    '마이크로칩': 'MCHP',
    '찰스슈왑': 'SCHW',
    '오큐젠': 'OCGN',
    '오레일리': 'ORLY',
    '피그스': 'FIGS',
    '페이오니아': 'PAYO',
    '월트디즈니': 'DIS',
// 일단 미국 천주까지 등록
    
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
