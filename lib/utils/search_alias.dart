import 'package:flutter/foundation.dart';

class AliasHit {
  final String code; // US=ticker, KR=6-digit code
  final String name; // display name (korean alias key)
  const AliasHit({required this.code, required this.name});
}

/// ✅ 같은 code(티커/종목코드)에 대해 여러 한글 이름을 묶어 반환
class AliasGroup {
  final String code;
  final List<String> names; // 중복 alias 묶음
  const AliasGroup({required this.code, required this.names});

  /// UI에서 대표 이름으로 쓸 때
  String get primaryName => names.isEmpty ? code : names.first;
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

  static String _cleanCode(String s) => s.trim().toUpperCase();

  // 티커 . , - 표기 정리
  static String _normUsTickerCode(String s) => s
    .trim()
    .toUpperCase()
    .replaceAll('.', '-');

  // 한글명 조회 함수
  static final Map<String, String> _usTickerToPrimaryKo = () {
    final out = <String, String>{};

    for (final e in usKoToTicker.entries) {
      final code = _normUsTickerCode(e.value);
      if (code.isEmpty) continue;
      out.putIfAbsent(code, () => e.key);
    }

    return out;
  }();

  static String? usPrimaryKoName(String ticker) {
    final code = _normUsTickerCode(ticker);
    if (code.isEmpty) return null;
    return _usTickerToPrimaryKo[code];
  }

 

  // -------------------------
  // 🇺🇸 US (한글/별칭 → 티커)
  // -------------------------
  // ✅ 기존 매핑 그대로 유지 (절대 줄이지 않음)
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
    '버크셔B': 'BRK-B',
    '버크셔A': 'BRK-A',
    '브로드컴': 'AVGO',
    'AMD': 'AMD',
    '인텔': 'INTC',
    '쿠팡': 'CPNG',
    '팔란티어': 'PLTR',
    '마이크로스트래티지': 'MSTR',
    '아이온큐': 'IONQ',
    '마이크론': 'MU',
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
    '안텔로페엔터프라이즈': 'AEHL',
    '큐라넥스파마슈티컬스': 'CURX',
    '이오스에너지엔터프라이시스': 'EOSE',
    '랙스페이스': 'RXT',
    '누홀딩스': 'NU',
    '플러그파워': 'PLUG',
    '아메리칸에어라인스그룹': 'AAL',
    '티엔루이시앙': 'TIRX',
    '써클인터넷그룹': 'CRCL',
    '뉴스케일파워': 'SMR',
    '블루햇': 'BHAT',
    '소파이': 'SOFI',
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
    '비트마인이머전': 'BMNR',
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
    '로켓컴퍼니스': 'RKT',
    '쾨르마이닝': 'CDE',
    '텔라닥헬스': 'TDOC',
    '비트디지털': 'BTBT',
    '스텔란티스': 'STLA',
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
    '라이엇플랫폼즈': 'RIOT',
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
    'AES': 'AES',
    '아파치': 'APA',
    '캠벨수프': 'CPB',
    '호스트호텔앤리조트': 'HST',
    '브라운포맨B': 'BF-B',
    '브라운포맨A': 'BF-A',
    '인터퍼블릭그룹': 'IPG',
    '제너럴밀스': 'GIS',
    '젠디지털': 'GEN',
    '프랭클린리소시즈': 'BEN',
    '카맥스': 'KMX',
    '킴코리얼티': 'KIM',
    '호멜푸즈': 'HRL',
    '인비테이션홈즈': 'INVH',
    '폭스': 'FOX',
    '아치캐피털': 'ACGL',
    '베스트바이': 'BBY',
    '글로벌페이먼츠': 'GPN',
    'AIG': 'AIG',
    '브리스톨마이어스': 'BMY',
    '올스테이트': 'ALL',
    '볼코퍼레이션': 'BALL',
    '센터포인트에너지': 'CNP',
    '차터커뮤니케이션': 'CHTR',
    'AO스미스': 'AOS',
    '고대디': 'GDDY',
    'CF인더스트리스': 'CF',
    '베이커휴즈': 'BKR',
    '하트퍼드파이낸셜': 'HIG',
    '암코어': 'AMCR',
    '글로브라이프': 'GL',
    '인사이트': 'INCY',
    '제너럴모터스': 'GM',
    'GE헬스케어': 'GEHC',
    '보스턴프로퍼티스': 'BXP',
    '아폴로그로벌': 'APO',
    '브라운앤브라운': 'BRO',
    '얼라이언트에너지': 'LNT',
    '뉴욕멜론은행': 'BK',
    '킴벌리클라크': 'KMB',
    '에플락': 'AFL',
    'CDW': 'CDW',
    '헨리샤인': 'HSIC',
    '리전시센터': 'REG',
    '켈라노바': 'K',
    '캐리어글로벌': 'CARR',
    '아처대니얼스': 'ADM',
    '레이몬드제임스': 'RJF',
    '빌더스퍼스트소스': 'BLDR',
    '아메렌': 'AEE',
    '홀로직': 'HOLX',
    '아메리칸일렉트릭': 'AEP',
    '가트너': 'IT',
    '어슈어런트': 'AIZ',
    '헬스피크': 'DOC',
    '애질런트테크': 'A',
    '알레기온': 'ALLE',
    '캠든프로퍼티': 'CPT',
    'KKR': 'KKR',
    '길리어드': 'GILD',
    '블랙스톤': 'BX',
    '휴매나': 'HUM',
    '존슨컨트롤즈': 'JCI',
    '아카마이': 'AKAM',
    '아메리칸워터': 'AWK',
    '번지': 'BG',
    '애보트': 'ABT',
    '에이버리데니슨': 'AVY',
    '리얼티인컴': 'O',
    '3M': 'MMM',
    '퀄컴': 'QCOM',
    '브로드리지': 'BR',
    '리비티': 'RVTY',
    '아이큐비아': 'IQV',
    '바이오젠': 'BIIB',
    '아발론베이': 'AVB',
    '잭헨리': 'JKHY',
    '에어비앤비': 'ABNB',
    '벡튼디킨슨': 'BDX',
    '아모스에너지': 'ATO',
    '퀘스트다이아': 'DGX',
    '어도비': 'ADBE',
    'ADP': 'ADP',
    'ICE': 'ICE',
    'CBRE': 'CBRE',
    '제이콥스': 'J',
    '잉거솔랜드': 'IR',
    '암페놀': 'APH',
    '얼라인테크': 'ALGN',
    '아메리프라이즈': 'AMP',
    'IBM': 'IBM',
    '바이오테크네': 'TECH',
    '아메리칸익스프레스': 'AXP',
    '아이덱스': 'IEX',
    '레스메드': 'RMD',
    '에이온': 'AON',
    '아메리칸타워': 'AMT',
    '아리스타네트웍스': 'ANET',
    'CH로빈슨': 'CHRW',
    '가민': 'GRMN',
    '하니웰': 'HON',
    '앱티브': 'APTV',
    'ITW': 'ITW',
    'JB헌트': 'JBHT',
    '캐피털원': 'COF',
    '리퍼블릭서비스': 'RSG',
    '아메텍': 'AME',
    '아서갤러거': 'AJG',
    '제너럴다이내믹스': 'GD',
    'CBOE': 'CBOE',
    'RTX': 'RTX',
    '홈디포': 'HD',
    '자빌': 'JBL',
    '암젠': 'AMGN',
    '허쉬': 'HSY',
    '헌팅턴잉걸스': 'HII',
    'GE': 'GE',
    '오토데스크': 'ADSK',
    '리제네론': 'REGN',
    '허벨': 'HUBB',
    '키사이트': 'KEYS',
    '센코라': 'COR',
    '제네락': 'GNRC',
    '로크웰': 'ROK',
    '인슐렛': 'PODD',
    '하우멧': 'HWM',
    '케이던스': 'CDNS',
    '블랙록': 'BLK',
    '제뉴인파츠': 'GPC',
    '아이덱스래브': 'IDXX',
    '인튜이티브서지컬': 'ISRG',
    'GE베르노바': 'GEV',
    '콴타서비스': 'PWR',
    'KLA': 'KLAC',
    '액손엔터프라이즈': 'AXON',
    '엑셀론': 'EXC',
    '피디디홀딩스': 'PDD',
    'PDD홀딩스': 'PDD',
    '씨에스엑스': 'CSX',
    '패스널': 'FAST',
    '코카콜라유로퍼시픽파트너스': 'CCEP',
    '페이첵스': 'PAYX',
    '덱스컴': 'DXCM',
    '포티넷': 'FTNT',
    '몬스터베버리지': 'MNST',
    '페로비알': 'FER',
    '팩카': 'PCAR',
    '톰슨로이터': 'TRI',
    '엔엑스피반도체': 'NXPI',
    'NXP반도체': 'NXPI',
    '다이아몬드백에너지': 'FANG',
    '로스스토어스': 'ROST',
    '신타스': 'CTAS',
    '컨스텔레이션에너지': 'CEG',
    '도어대시': 'DASH',
    '일렉트로닉아츠': 'EA',
    '린데': 'LIN',
    '암홀딩스': 'ARM',
    '시놉시스': 'SNPS',
    '알나일람파마슈티컬스': 'ALNY',
    '데이터도그': 'DDOG',
    '에이에스엠엘': 'ASML',
    '메르카도리브레': 'MELI',
    '모놀리식파워시스템즈': 'MPWR',
    '코스타그룹': 'CSGP',
    '올드도미니언': 'ODFL',
    '로퍼테크놀로지스': 'ROP',
    '뉴스코프A': 'NWSA',
    '뉴스코프B': 'NWS',
    'LKQ': 'LKQ',
    '코테라에너지': 'CTRA',
    '에디슨인터내셔널': 'EIX',
    '데본에너지': 'DVN',
    '델타항공': 'DAL',
    '램웨스턴': 'LW',
    '푸르덴셜': 'PRU',
    'PPL': 'PPL',
    '나이사이스': 'NI',
    '도미니언에너지': 'D',
    'EQT': 'EQT',
    '이스트만케미컬': 'EMN',
    '레나': 'LEN',
    '에버소스에너지': 'ES',
    '라스베이거스샌즈': 'LVS',
    '에쿼티레지덴셜': 'EQR',
    '원오크': 'OKE',
    '풀티그룹': 'PHM',
    '엔페이즈에너지': 'ENPH',
    '엑셀릭시스': 'EXEL',
    '프린서펄파이낸셜': 'PFG',
    '데커스아웃도어': 'DECK',
    'PSEG': 'PEG',
    'EOG리소시즈': 'EOG',
    '에버지': 'EVRG',
    '이베이': 'EBAY',
    'DR호튼': 'DHI',
    '룰루레몬': 'LULU',
    '피나클웨스트': 'PNW',
    '페이컴소프트웨어': 'PAYC',
    '펜테어': 'PNR',
    '노던트러스트': 'NTRS',
    '뉴몬트': 'NEM',
    '페더럴리얼티': 'FRT',
    '필립스66': 'PSX',
    'PNC파이낸셜': 'PNC',
    '프로그레시브': 'PGR',
    '버터필드은행': 'NTB',
    '듀크에너지': 'DUK',
    '레이다스': 'LDOS',
    '에베레스트그룹': 'EG',
    'EPAM시스템즈': 'EPAM',
    '엔터지': 'ETR',
    '팩트셋': 'FDS',
    'DTE에너지': 'DTE',
    '엘레반스헬스': 'ELV',
    '크로거': 'KR',
    '익스피다이터스': 'EXPD',
    '마라톤패트롤리엄': 'MPC',
    '컨스텔레이션브랜즈': 'STZ',
    '코르테바': 'CTVA',
    'PTC': 'PTC',
    '달러제너럴': 'DG',
    '뉴코어': 'NUE',
    '풀코퍼레이션': 'POOL',
    '에드워즈라이프사이언스': 'EW',
    'CVS헬스': 'CVS',
    '다든레스토랑': 'DRI',
    '엑스트라스페이스스토리지': 'EXR',
    '에머슨일렉트릭': 'EMR',
    '이리인뎀니티': 'ERIE',
    '익스피디아': 'EXPE',
    '마켓액세스': 'MKTX',
    '프로로지스': 'PLD',
    'NRG에너지': 'NRG',
    '도버': 'DOV',
    '패키징코프': 'PKG',
    '에섹스프로퍼티': 'ESS',
    '랩코프': 'LH',
    '코페이': 'CPAY',
    '노퍽서던': 'NSC',
    '에퀴팩스': 'EFX',
    '아이텍스': 'ITX',
    '시티즌스파이낸셜그룹': 'CFG',
    '로우스': 'L',
    '신시내티파이낸셜': 'CINF',
    '코노코필립스': 'COP',
    '크로락스': 'CLX',
    '콘솔리데이티드에디슨': 'ED',
    'M&T뱅크': 'MTB',
    '시그나': 'CI',
    '콜게이트-팜올리브': 'CL',
    '처치&드와이트': 'CHD',
    '마쉬맥레넌': 'MMC',
    '마쉬': 'MRSH',
    '처브': 'CB',
    'CME그룹': 'CME',
    '레녹스이터내셔널': 'LII',
    '라이브네이션엔터테인먼트': 'LYV',
    'L3해리스테크놀러지': 'LHX',
    '록히드마틴': 'LMT',
    '마틴마리에타머터리얼스': 'MLM',
    'CMS에너지': 'CMS',
    '텍사스인스트루먼트': 'TXN',
    '버텍스파마슈티컬': 'VRTX',

  };

  /// normKey -> (code별 names 묶음)
  static final Map<String, Map<String, List<String>>> _usExactGroups = () {
    final out = <String, Map<String, List<String>>>{};

    // 1) 기존 1:1(풀네임)만으로 그룹 구성
    // - 같은 티커를 여러 한글 이름이 가리키면 names 리스트로 묶임
    for (final e in usKoToTicker.entries) {
      final display = e.key;
      final nk = norm(display);

      final code = _cleanCode(e.value);
      if (code.isEmpty) continue;

      final codeMap = out[nk] ??= <String, List<String>>{};
      final names = codeMap[code] ??= <String>[];
      if (!names.contains(display)) names.add(display);
    }

    return out;
  }();

  static final List<String> _usKeys = _usExactGroups.keys.toList();

  // -------------------------
  // 🇺🇸 US resolve (GROUPED)
  // -------------------------

  /// ✅ “중복 code를 names 리스트로 묶어서” 결과 반환
  /// - 같은 티커가 여러 한글 이름으로 등록돼도 1개로 묶입니다.
  static List<AliasGroup> resolveUsGroups(String query, {int limit = 20}) {
    final raw = query.trim();
    final q = norm(raw);
    if (q.isEmpty) return const [];

    final result = <String, List<String>>{}; // code -> names (insertion-ordered)
    void mergeCodeMap(Map<String, List<String>>? codeMap) {
      if (codeMap == null) return;
      for (final e in codeMap.entries) {
        if (result.length >= limit) return;
        final code = e.key;
        final names = result[code] ??= <String>[];
        for (final n in e.value) {
          if (!names.contains(n)) names.add(n);
        }
      }
    }

    // 1) exact
    mergeCodeMap(_usExactGroups[q]);

    // 2) partial (한글 + 2글자 이상)
    if (hasHangul(raw) && q.length >= 2 && result.length < limit) {
      final matches = <_ScoredKey>[];
      for (final k in _usKeys) {
        final score = _matchScore(k, q);
        if (score == null) continue;
        matches.add(_ScoredKey(k, score));
      }

      matches.sort((a, b) {
        final s = a.score.compareTo(b.score);
        if (s != 0) return s;
        final la = a.key.length;
        final lb = b.key.length;
        if (la != lb) return la.compareTo(lb);
        return a.key.compareTo(b.key);
      });

      for (final mk in matches) {
        if (result.length >= limit) break;
        mergeCodeMap(_usExactGroups[mk.key]);
      }
    }

    return result.entries
        .map((e) => AliasGroup(code: e.key, names: e.value))
        .toList();
  }

  /// ✅ 기존 호환: 1개만 필요할 때(대표 1개)
  static AliasHit? resolveUs(String query) {
    final groups = resolveUsGroups(query, limit: 1);
    if (groups.isEmpty) return null;
    final g = groups.first;
    return AliasHit(code: g.code, name: g.primaryName);
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

  static final Map<String, Map<String, List<String>>> _krExactGroups = () {
    final out = <String, Map<String, List<String>>>{};

    for (final e in krKoToCode.entries) {
      final display = e.key;
      final nk = norm(display);
      final code = e.value.trim();
      if (code.isEmpty) continue;

      final codeMap = out[nk] ??= <String, List<String>>{};
      final names = codeMap[code] ??= <String>[];
      if (!names.contains(display)) names.add(display);
    }

    return out;
  }();

  static final List<String> _krKeys = _krExactGroups.keys.toList();
  static const int _minPartialLen = 2;

  static List<AliasGroup> resolveKrGroups(String query, {int limit = 20}) {
    final raw = query.trim();
    final q = norm(raw);
    if (q.isEmpty) return const [];

    final result = <String, List<String>>{};
    void mergeCodeMap(Map<String, List<String>>? codeMap) {
      if (codeMap == null) return;
      for (final e in codeMap.entries) {
        if (result.length >= limit) return;
        final code = e.key;
        final names = result[code] ??= <String>[];
        for (final n in e.value) {
          if (!names.contains(n)) names.add(n);
        }
      }
    }

    // exact
    mergeCodeMap(_krExactGroups[q]);

    // partial
    if (hasHangul(raw) && q.length >= _minPartialLen && result.length < limit) {
      final matches = <_ScoredKey>[];
      for (final k in _krKeys) {
        final score = _matchScore(k, q);
        if (score == null) continue;
        matches.add(_ScoredKey(k, score));
      }

      matches.sort((a, b) {
        final s = a.score.compareTo(b.score);
        if (s != 0) return s;
        final la = a.key.length;
        final lb = b.key.length;
        if (la != lb) return la.compareTo(lb);
        return a.key.compareTo(b.key);
      });

      for (final mk in matches) {
        if (result.length >= limit) break;
        mergeCodeMap(_krExactGroups[mk.key]);
      }
    }

    return result.entries
        .map((e) => AliasGroup(code: e.key, names: e.value))
        .toList();
  }

  static AliasHit? resolveKr(String query) {
    final groups = resolveKrGroups(query, limit: 1);
    if (groups.isEmpty) return null;
    final g = groups.first;
    return AliasHit(code: g.code, name: g.primaryName);
  }

  // -------------------------
  // 공통 유틸
  // -------------------------
  static bool looksLikeKrCode(String s) {
    final t = s.trim().toUpperCase().replaceAll(' ', '');
    if (RegExp(r'^\d{4,6}$').hasMatch(t)) return true; // 4~6자리 숫자
    if (RegExp(r'^\d{5}[A-Z0-9]$').hasMatch(t)) return true; // 0007C0
    return false;
  }

  static bool looksLikeUsTicker(String s) =>
      RegExp(r'^[A-Z]{1,6}([.\-][A-Z0-9]{1,3})?$')
          .hasMatch(s.trim().toUpperCase());

  static void debugLog(String msg) {
    if (kDebugMode) debugPrint('[Alias] $msg');
  }

  static int? _matchScore(String key, String q) {
    if (key == q) return 0;
    if (key.startsWith(q)) return 1;
    if (key.contains(q)) return 2;
    if (q.contains(key)) return 3;
    return null;
  }
}

class _ScoredKey {
  final String key;
  final int score;
  _ScoredKey(this.key, this.score);
}