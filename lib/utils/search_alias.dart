import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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
    'AT&T': 'T',
    'AT앤T': 'T',
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
    '퍼시픽가스&일렉트릭': 'PCG',
    '퍼시픽가스앤일렉트릭': 'PCG',
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
    '퍼블릭서비스': 'PEG',
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
    '매치그룹': 'MTCH',
    '매스코': 'MAS',
    '알트리아그룹': 'MO',
    '다비타': 'DVA',
    '맥코믹앤컴퍼니': 'MKC',
    '로우스컴퍼니': 'LOW',
    '맥도날드': 'MCD',
    '커민스': 'CMI',
    '메리어트인터내셔널': 'MAR',
    '쿠퍼컴퍼니스': 'COO',
    '다나허': 'DHR',
    '크라운캐슬': 'CCI',
    '애브비': 'ABBV',
    '아이언마운틴': 'IRM',
    '데이포스': 'DAY',
    '엑셀에너지': 'XEL',
    '베리스크애널리틱스': 'VRSK',
    '싱크로니파이낸셜': 'SYF',
    '솔벤텀': 'SOLV',
    '유니버셜헬스스비스': 'UHS',
    '유나이티드에어라인스홀딩스': 'UAL',
    '티로웨프라이스그룹': 'TROW',
    '트래블러스컴퍼니스': 'TRV',
    '트루이스트파이낸셜': 'TFC',
    '폭스코퍼레이션A': 'FOXA',
    '피프스서드뱅코프': 'FITB',
    '사이먼프로퍼티그룹': 'SPG',
    '스테이트스트리트': 'STT',
    '퍼스트솔라': 'FSLR',
    '유나이티드파셀서비스': 'UPS',
    'W.R.버클리': 'WRB',
    '타겟': 'TGT',
    '모자이크': 'MOS',
    '익스팬드에너지': 'EXE',
    'PPG인더스트리스': 'PPG',
    '모간스탠리': 'MS',
    'HCA헬스케어': 'HCA',
    '로얄캐리비안크루즈': 'RCL',
    'SBA커뮤니케이션스': 'SBAC',
    '텍스트론': 'TXT',
    '윌리스타워스왓슨': 'WTW',
    '스카이웍스솔루션스': 'SWKS',
    '넷앱': 'NTAP',
    '스냅-온': 'SNA',
    '유나이티드렌탈스': 'URI',
    '윌리엄소노마': 'WSM',
    '도미노피자': 'DPZ',
    '울타뷰티': 'ULTA',
    '유니온퍼시픽': 'UNP',
    '페덱스': 'FDX',
    '스틸다이내믹스': 'STLD',
    '트랙터서플라이': 'TSCO',
    '시스코': 'SYY',
    '오토존': 'AZO',
    '베랄토': 'VLTO',
    '노스롭그루만': 'NOC',
    'WEC에너지그룹': 'WEC',
    '아레스매니지먼트': 'ARES',
    '메트라이프': 'MET',
    '달러트리': 'DLTR',
    '오티스월드와이드': 'OTIS',
    '필립모리스': 'PM',
    '파이서브': 'FISV',
    '메드트로닉': 'MDT',
    '엠코그룹': 'EME',
    '나스닥': 'NDAQ',
    '퍼스트에너지': 'FE',
    '랄프로렌': 'RL',
    '메틀러톨레도': 'MTD',
    '퍼블릭스토리지': 'PSA',
    '인터랙티브브로커스': 'IBKR',
    

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
    // 🇰🇷 KR (종목코드 -> 영어명)
    // -------------------------
  static const Map<String, String> krCodeToEnglishName = {
    'F70100': 'Hantu Global Negseuteuweibeu 1 Class A', // 한투글로벌넥스트웨이브1(A)
    'F70101': 'Milrano Real Estate', // 밀라노부동산
    'F70102': 'Luxembourg Koeo Office ( Derivative ) Class A', // 룩셈부르크코어오피스(파생형)(A)
    'F70103': 'Luxembourg Koeo Office ( Derivative ) Class C-I', // 룩셈부르크코어오피스(파생형)(C-I)
    'F70900': 'Daishin High Yield IPO Alpasecurities 2 Ho A', // 대신하이일드공모주알파증권2호 A
    'F71201': 'Kiumhieorojeu Europe Office Real Estate 1 Ho A', // 키움히어로즈유럽오피스부동산1호 A
    'F71202': 'Kiumhieorojeu Europe Office Real Estate 1 Ho C-I', // 키움히어로즈유럽오피스부동산1호 C-I
    'F71203': 'Kiumhieorojeu Europe Office Real Estate 2 Ho A', // 키움히어로즈유럽오피스부동산2호 A
    'F71204': 'Kiumhieorojeu Europe Office Real Estate 2 Ho C-I', // 키움히어로즈유럽오피스부동산2호 C-I
    'F71205': 'Kiumhieorojeu Europe Office Real Estate 3 Ho A', // 키움히어로즈유럽오피스부동산3호 A
    'F71206': 'Kiumhieorojeu Europe Office Real Estate 3 Ho C-I', // 키움히어로즈유럽오피스부동산3호 C-I
    'F71207': 'Kiumhieorojeu Europe Office Real Estate 4 Ho A', // 키움히어로즈유럽오피스부동산4호 A
    'F71208': 'Kiumhieorojeu Europe Office Real Estate 4 Ho C-I', // 키움히어로즈유럽오피스부동산4호 C-I
    'F73400': 'Koreiteu High Yield IPO Target Maturity 3 Ho A', // 코레이트하이일드공모주만기형3호 A
    'F74201': 'Hana Alternative Nasa Real Estate 1 Ho', // 하나대체나사부동산1호
    'F74202': 'Hana Alternative US Real Estate 1 Ho C-I', // 하나대체미국부동산1호 C-I
    'F74401': 'Maebseu US 11 Ho', // 맵스미국11호
    'F74601': 'KCGI Vietnam Securities Investment Trust', // KCGI베트남증권투자신탁
    'F74701': 'Ijiseukoeo Real Estate 126 Ho A', // 이지스코어부동산126호 A
    'F74702': 'Ijiseukoeo Real Estate 126 Ho C-I', // 이지스코어부동산126호 C-i
    'F75601': 'Yugyeonggongmo Real Estate 3 Ho Class A', // 유경공모부동산3호ClassA
    'F75602': 'Yugyeonggongmo Real Estate 3 Ho Class C-I', // 유경공모부동산3호ClassC-I
    'F75701': 'Hyundai Yupeoseuteu Real Estate 30 Ho ( Derivative ) A', // 현대유퍼스트부동산30호[파생형] A
    'F75702': 'Hyundai Yupeoseuteu Real Estate 30 Ho ( Derivative ) C-I', // 현대유퍼스트부동산30호[파생형] C-i
    'F76201': 'Italy Logistics 1 Ho Class A', // 이탈리아물류1호 종류A
    'F77200': 'Korea Value Raipeu V Paweo 1 Class A', // 한국밸류라이프V파워1(A)
    '000020': 'Donghwa Pharmaceutical', // 동화약품
    '000040': 'KR Moteoseu', // KR모터스
    '000050': 'Gyeongbang', // 경방
    '000070': 'Samyang Holdings', // 삼양홀딩스
    '000080': 'Haiteujinro', // 하이트진로
    '000087': 'Haiteujinro 2nd Pref B', // 하이트진로2우B
    '0000D0': 'TIGER NVI DI A US Cae Covered Call Baelreonseu ( Synthetic', // TIGER 엔비디아미국채커버드콜밸런스(합성
    '0000H0': 'KODEX India Nifty Mid Cap 100', // KODEX 인도Nifty미드캡100
    '0000J0': 'PLUS Hanwha Geurubju', // PLUS 한화그룹주
    '0000Y0': 'HK 26-12 Corporate Bond (AA- Isang ) Active', // HK 26-12 회사채(AA-이상)액티브
    '0000Z0': 'RISE Bio Top 10 Active', // RISE 바이오TOP10액티브
    '000100': 'Yuhan', // 유한양행
    '000105': 'Yuhan Pref', // 유한양행우
    '000120': 'CJ Korea Logistics', // CJ대한통운
    '000140': 'Haiteujinro Holdings', // 하이트진로홀딩스
    '000145': 'Haiteujinro Holdings Pref', // 하이트진로홀딩스우
    '000150': 'Doosan', // 두산
    '000155': 'Doosan Pref', // 두산우
    '000157': 'Doosan 2nd Pref B', // 두산2우B
    '000180': 'Seongcanggieob Holdings', // 성창기업지주
    '0001P0': 'Maiti Biosimilar &CDMO Active', // 마이티 바이오시밀러&CDMO액티브
    '0001S0': 'TIGER 26-04 Corporate Bond (A+ Isang ) Active', // TIGER 26-04 회사채(A+이상)액티브
    '000210': 'DL', // DL
    '000215': 'DL Pref', // DL우
    '000220': 'Yuyu Pharmaceutical', // 유유제약
    '000225': 'Yuyu Pharmaceutical 1st Pref', // 유유제약1우
    '000227': 'Yuyu Pharmaceutical 2nd Pref B', // 유유제약2우B
    '000230': 'Ildong Holdings', // 일동홀딩스
    '000240': 'Korea Aenkeompeoni', // 한국앤컴퍼니
    '000270': 'Kia', // 기아
    '0002C0': 'Asset Plus India Ildeunggieob Focus 20 Active', // 에셋플러스 인도일등기업포커스20액티브
    '000300': 'DH Otonegseu', // DH오토넥스
    '000320': 'Noru Holdings', // 노루홀딩스
    '000325': 'Noru Holdings Pref', // 노루홀딩스우
    '000370': 'Hanwha Non-Life Insurance', // 한화손해보험
    '000390': 'Samhwapeinteu', // 삼화페인트
    '000400': 'Lotte Non-Life Insurance', // 롯데손해보험
    '000430': 'Daeweongangeob', // 대원강업
    '000480': 'CR Holdings', // CR홀딩스
    '000490': 'Daedong', // 대동
    '0004G0': '1Q US Dividend Top 30', // 1Q 미국배당TOP30
    '000500': 'Gaonjeonseon', // 가온전선
    '000520': 'Samil Pharmaceutical', // 삼일제약
    '000540': 'Heunggug Fire', // 흥국화재
    '000545': 'Heunggug Fire Pref', // 흥국화재우
    '000590': 'CS Holdings', // CS홀딩스
    '0005A0': 'KODEX US S&P500 Daily Covered Call OTM', // KODEX 미국S&P500데일리커버드콜OTM
    '0005C0': 'RISE US S&P500 Enhwanocul ( Synthetic H)', // RISE 미국S&P500엔화노출(합성 H)
    '0005D0': 'SOL All-Solid-State Battery & Silrikoneumgeugjae', // SOL 전고체배터리&실리콘음극재
    '0005G0': 'ITF K- AI Semiconductor Core Tech', // ITF K-AI반도체코어테크
    '000640': 'Dongassosio Holdings', // 동아쏘시오홀딩스
    '000650': 'Ceonilgosog', // 천일고속
    '000660': 'SK hynix', // SK하이닉스
    '000670': 'Yeongpung', // 영풍
    '000680': 'LS Neteuweogseu', // LS네트웍스
    '000700': 'Yusu Holdings', // 유수홀딩스
    '000720': 'Hyundai Engineering & Construction', // 현대건설
    '000725': 'Hyundai Engineering & Construction Pref', // 현대건설우
    '000760': 'Ihwa Industries', // 이화산업
    '0007F0': 'KODEX 27-12 Corporate Bond (AA- Isang ) Active', // KODEX 27-12 회사채(AA-이상)액티브
    '0007G0': 'PLUS Global Nuclear Power Value Cein', // PLUS 글로벌원자력밸류체인
    '0007N0': 'AIem Asset 200', // 아이엠에셋 200
    '000810': 'Samsung Fire & Marine Insurance', // 삼성화재
    '000815': 'Samsung Fire Pref', // 삼성화재우
    '000850': 'Hwaceongigong', // 화천기공
    '000860': 'Gangnamjebiseuko', // 강남제비스코
    '000880': 'Hanwha', // 한화
    '00088K': 'Hanwha 3rd Pref B', // 한화3우B
    '000890': 'Bohaeyangjo', // 보해양조
    '0008E0': 'ACE US Jungsim Small & Mid Cap Manufacturing', // ACE 미국중심중소형제조업
    '0008S0': 'TIGER US Dividend Dow Jones Target Daily Keobeodeu', // TIGER 미국배당다우존스타겟데일리커버드
    '0008T0': 'SOL Hwajangpum Top 3 Plus', // SOL 화장품TOP3플러스
    '000910': 'Yunion', // 유니온
    '000950': 'Jeonbang', // 전방
    '000970': 'Korea Juceolgwan', // 한국주철관
    '000990': 'DB Haiteg', // DB하이텍
    '001020': 'Peipeo Korea', // 페이퍼코리아
    '001040': 'CJ', // CJ
    '001045': 'CJ Pref', // CJ우
    '00104K': 'CJ 4th Pref (Convertible)', // CJ4우(전환)
    '001060': 'JW Pharmaceutical', // JW중외제약
    '001065': 'JW Jungoe Pharmaceutical Pref', // JW중외제약우
    '001067': 'JW Jungoe Pharmaceutical 2nd Pref B', // JW중외제약2우B
    '001070': 'Korea Bangjig', // 대한방직
    '001080': 'Manhojegang', // 만호제강
    '0010E0': 'ACE FTSE WGBI Korea', // ACE FTSE WGBI Korea
    '001120': 'LX International', // LX인터내셔널
    '001130': 'Korea Jebun', // 대한제분
    '001200': 'Eugene Investment & Securities', // 유진투자증권
    '001210': 'Kumho Electric', // 금호전기
    '001230': 'Dongkuk Holdings', // 동국홀딩스
    '001250': 'GS Global', // GS글로벌
    '001260': 'Namgwangtogeon', // 남광토건
    '001270': 'Bugugsecurities', // 부국증권
    '001275': 'Bugugsecurities Pref', // 부국증권우
    '001290': 'Sangsanginsecurities', // 상상인증권
    '001340': 'PKC', // PKC
    '001360': 'Samsung Pharmaceutical', // 삼성제약
    '001380': 'SG Global', // SG글로벌
    '001390': 'KG Chemical', // KG케미칼
    '0013P0': 'RISE US Bank Top 10', // RISE 미국은행TOP10
    '0013R0': 'RISE Tesla US Cae Target Covered Call Mixed ( Synthetic )', // RISE 테슬라미국채타겟커버드콜혼합(합성)
    '001420': 'Taeweonmulsan', // 태원물산
    '001430': 'Seabeseutil Holdings', // 세아베스틸지주
    '001440': 'Korea Jeonseon', // 대한전선
    '001450': 'Hyundai Marine', // 현대해상
    '001460': 'BYC', // BYC
    '001465': 'BYC Pref', // BYC우
    '001470': 'Sambutogeon', // 삼부토건
    '001500': 'Hyundai Motor Securities', // 현대차증권
    '001510': 'SK Securities', // SK증권
    '001515': 'SK Securities Pref', // SK증권우
    '001520': 'Dongyang', // 동양
    '001525': 'Dongyang Pref', // 동양우
    '001527': 'Dongyang 2nd Pref B', // 동양2우B
    '001530': 'DI Dongil', // DI동일
    '001550': 'Jobi', // 조비
    '001560': 'Jeilyeonma', // 제일연마
    '001570': 'Geumyang', // 금양
    '0015B0': 'Koact US Nasdaq Growth Companies Active', // KoAct 미국나스닥성장기업액티브
    '0015E0': 'KIWOOM NVI DI A US 30 Nyeon Treasury Bond Mixed Active (H', // KIWOOM 엔비디아미국30년국채혼합액티브(H
    '0015F0': 'KIWOOM Palantir US 30 Nyeon Treasury Bond Mixed Active (H', // KIWOOM 팔란티어미국30년국채혼합액티브(H
    '0015K0': 'TIGER US Sobiteurendeu Active', // TIGER 미국소비트렌드액티브
    '001620': 'Keibiai Dongkuk Sileob', // 케이비아이동국실업
    '001630': 'Chong Kun Dang Holdings', // 종근당홀딩스
    '001680': 'Daesang', // 대상
    '001685': 'Daesang Pref', // 대상우
    '0016X0': 'SOL Short/Mid-Term Corporate Bond (A- Isang ) Active', // SOL 중단기회사채(A-이상)액티브
    '001720': 'Sinyeongsecurities', // 신영증권
    '001740': 'SK Neteuweogseu', // SK네트웍스
    '001750': 'Hanyangsecurities', // 한양증권
    '001755': 'Hanyangsecurities Pref', // 한양증권우
    '001770': 'SHD', // SHD
    '001780': 'Alruko', // 알루코
    '001790': 'Korea Jedang', // 대한제당
    '001795': 'Korea Jedang Pref', // 대한제당우
    '0017Y0': '1Q Jonghab Bond (AA- Isang ) Active', // 1Q 종합채권(AA-이상)액티브
    '001800': 'Orion Holdings', // 오리온홀딩스
    '001820': 'Samhwakondenseo', // 삼화콘덴서
    '0018C0': 'PLUS High Dividend Juwikeulri Fixed Covered Call', // PLUS 고배당주위클리고정커버드콜
    '0018Z0': 'RISE US Quantum Computing', // RISE 미국양자컴퓨팅
    '001940': 'KISCO Holdings', // KISCO홀딩스
    '0019K0': 'TIME US Nasdaq 100 Bond Mixed 50 Active', // TIME 미국나스닥100채권혼합50액티브
    '002020': 'Kolon', // 코오롱
    '002025': 'Kolon Pref', // 코오롱우
    '002030': 'Asea', // 아세아
    '002070': 'Bibian', // 비비안
    '0020H0': 'Koact Global Quantum Computing Active', // KoAct 글로벌양자컴퓨팅액티브
    '002100': 'Gyeongnong', // 경농
    '002140': 'Goryeo Industries', // 고려산업
    '002150': 'Dohwaenjinieoring', // 도화엔지니어링
    '002170': 'Samyang Tongsang', // 삼양통상
    '0021C0': 'ACE Long-Term Jasanbaebun Active', // ACE 장기자산배분액티브
    '0021D0': 'ACE TDF 2030 Active', // ACE TDF2030액티브
    '0021E0': 'ACE TDF 2050 Active', // ACE TDF2050액티브
    '002200': 'Korea Export Pojang', // 한국수출포장
    '002210': 'Dongseong Pharmaceutical', // 동성제약
    '002220': 'Hanilceolgang', // 한일철강
    '002240': 'Goryeojegang', // 고려제강
    '0022T0': 'SOL International Gold Covered Call Active', // SOL 국제금커버드콜액티브
    '002310': 'Asea Paper', // 아세아제지
    '002320': 'Hanjin', // 한진
    '002350': 'Negsentaieo', // 넥센타이어
    '002355': 'Negsentaieo 1st Pref B', // 넥센타이어1우B
    '002360': 'SH Energy Chemical', // SH에너지화학
    '002380': 'KCC', // KCC
    '002390': 'Handog', // 한독
    '0023A0': 'SOL US Quantum Computing Top 10', // SOL 미국양자컴퓨팅TOP10
    '0023B0': 'PLUS US Quantum Computing Top 10', // PLUS 미국양자컴퓨팅TOP10
    '002410': 'Beomyanggeonyeong', // 범양건영
    '002420': 'Segi Corporation', // 세기상사
    '002450': 'Samigaggi', // 삼익악기
    '002460': 'HS Hwaseong', // HS화성
    '0025N0': 'TIGER TDF 2045', // TIGER TDF2045
    '002600': 'Joheung', // 조흥
    '002620': 'Jeilpama Holdings', // 제일파마홀딩스
    '002630': 'Orienteu Bio', // 오리엔트바이오
    '002690': 'Dongiljegang', // 동일제강
    '0026E0': 'KODEX US S&P500 Beopeo 3 Weol Active', // KODEX 미국S&P500버퍼3월액티브
    '0026S0': '1Q US S&P500', // 1Q 미국S&P500
    '002700': 'Sinil Electronics', // 신일전자
    '002710': 'TCC Seutil', // TCC스틸
    '002720': 'Gug Pharmaceutical Pum', // 국제약품
    '002760': 'Borag', // 보락
    '002780': 'Jinheunggieob', // 진흥기업
    '002785': 'Jinheunggieob Pref B', // 진흥기업우B
    '002787': 'Jinheunggieob 2nd Pref B', // 진흥기업2우B
    '002790': 'Amorepeosipig Holdings', // 아모레퍼시픽홀딩스
    '002795': 'Amorepeosipig Holdings Pref', // 아모레퍼시픽홀딩스우
    '00279K': 'Amorepeosipig Holdings 3rd Pref C', // 아모레퍼시픽홀딩스3우C
    '002810': 'Samyeongmuyeog', // 삼영무역
    '002820': 'SUN&L', // SUN&L
    '002840': 'Miweon Corporation', // 미원상사
    '002870': 'Sinpung', // 신풍
    '002880': 'Daeyueiteg', // 대유에이텍
    '0028X0': 'KODEX US Financial Tech Active', // KODEX 미국금융테크액티브
    '002900': 'TYM', // TYM
    '002920': 'Yuseonggieob', // 유성기업
    '002960': 'Korea Swelseogyu', // 한국쉘석유
    '002990': 'Kumho Engineering & Construction', // 금호건설
    '002995': 'Kumho Engineering & Construction Pref', // 금호건설우
    '003000': 'Bugwang Pharmaceutical', // 부광약품
    '003010': 'Hyein', // 혜인
    '003030': 'Seajegang Holdings', // 세아제강지주
    '003060': 'Eipeurojen Biologics', // 에이프로젠바이오로직스
    '003070': 'Kolon Global', // 코오롱글로벌
    '003075': 'Kolon Global Pref', // 코오롱글로벌우
    '003080': 'SB Seongbo', // SB성보
    '003090': 'Daeung', // 대웅
    '0030R0': 'Daishin Value REITs', // 대신밸류리츠
    '003120': 'Ilseongaieseu', // 일성아이에스
    '003160': 'Diai', // 디아이
    '003200': 'Ilsinbangjig', // 일신방직
    '003220': 'Daeweon Pharmaceutical', // 대원제약
    '003230': 'Samyang Foods', // 삼양식품
    '003240': 'Taegwang Industries', // 태광산업
    '003280': 'Heungahaeun', // 흥아해운
    '003300': 'Hanil Holdings', // 한일홀딩스
    '003350': 'Korea Hwajangpumjejo', // 한국화장품제조
    '003460': 'Yuhwasecurities', // 유화증권
    '003465': 'Yuhwasecurities Pref', // 유화증권우
    '003470': 'Yuanta Securities', // 유안타증권
    '003475': 'Yuanta Securities Pref', // 유안타증권우
    '003480': 'Hanjin Heavy Industries Holdings', // 한진중공업홀딩스
    '003490': 'Korean Air', // 대한항공
    '003495': 'Korea AIr Pref', // 대한항공우
    '003520': 'Yeongjin Pharmaceutical', // 영진약품
    '003530': 'Hanwha Investment & Securities', // 한화투자증권
    '003535': 'Hanwha Investment & Securities Pref', // 한화투자증권우
    '003540': 'Daishin Securities', // 대신증권
    '003545': 'Daishin Securities Pref', // 대신증권우
    '003547': 'Daishin Securities 2nd Pref B', // 대신증권2우B
    '003550': 'LG', // LG
    '003555': 'LG Pref', // LG우
    '003570': 'SNT Dainaemigseu', // SNT다이내믹스
    '003580': 'HLB Global', // HLB글로벌
    '0035T0': 'PLUS Global Humanoid Robotics Active', // PLUS 글로벌휴머노이드로봇액티브
    '003610': 'Bangrim', // 방림
    '003620': 'KG Mobility', // KG모빌리티
    '003650': 'Micangseogyu', // 미창석유
    '003670': 'POSCO Pyuceoem', // 포스코퓨처엠
    '003680': 'Hanseonggieob', // 한성기업
    '003690': 'Koreanri', // 코리안리
    '0036D0': 'TIME US Dividend Dow Jones Active', // TIME 미국배당다우존스액티브
    '0036R0': 'RISE US Humanoid Robotics', // RISE 미국휴머노이드로봇
    '0036Z0': 'RISE US Ceonyeongaseu Value Cein', // RISE 미국천연가스밸류체인
    '003720': 'Samyeong', // 삼영
    '003780': 'Jinyang Industries', // 진양산업
    '003830': 'Korea Hwaseom', // 대한화섬
    '003850': 'Boryeong', // 보령
    '0038A0': 'KODEX US Humanoid Robotics', // KODEX 미국휴머노이드로봇
    '003920': 'Namyang Dairy', // 남양유업
    '003925': 'Namyang Dairy Pref', // 남양유업우
    '003960': 'Sajo Daelim', // 사조대림
    '004000': 'Lotte Jeongmil Chemical', // 롯데정밀화학
    '004020': 'Hyundai Steel', // 현대제철
    '004060': 'SG Segyemulsan', // SG세계물산
    '004080': 'Sinheung', // 신흥
    '004090': 'Korea Seogyu', // 한국석유
    '0040S0': 'HANARO Global Pijikeol AI Active', // HANARO 글로벌피지컬AI액티브
    '0040X0': 'SOL Palantir US Cae Covered Call Mixed', // SOL 팔란티어미국채커버드콜혼합
    '0040Y0': 'SOL Palantir Covered Call OTM Bond Mixed', // SOL 팔란티어커버드콜OTM채권혼합
    '004100': 'Taeyanggeumsog', // 태양금속
    '004105': 'Taeyanggeumsog Pref', // 태양금속우
    '004140': 'Dongbang', // 동방
    '004150': 'Hansol Holdings', // 한솔홀딩스
    '004170': 'Shinsegae', // 신세계
    '0041D0': 'KODEX US AI Software Top 10', // KODEX 미국AI소프트웨어TOP10
    '0041E0': 'KODEX US S&P500 Active', // KODEX 미국S&P500액티브
    '004250': 'NPC', // NPC
    '004255': 'NPC Pref', // NPC우
    '004270': 'Namseong', // 남성
    '004310': 'Hyundai Pharmaceutical', // 현대약품
    '004360': 'Sebang', // 세방
    '004365': 'Sebang Pref', // 세방우
    '004370': 'Nongshim', // 농심
    '004380': 'Samig T HK', // 삼익THK
    '0043B0': 'TIGER Money Market Active', // TIGER 머니마켓액티브
    '0043Y0': 'TIME China AI Tech Active', // TIME 차이나AI테크액티브
    '004410': 'Seoul Foods', // 서울식품
    '004415': 'Seoul Foods Pref', // 서울식품우
    '004430': 'Songweon Industries', // 송원산업
    '004440': 'Samil CNS', // 삼일씨엔에스
    '004450': 'Samhwawanggwan', // 삼화왕관
    '004490': 'Sebangjeonji', // 세방전지
    '004540': 'Ggaeggeushannara', // 깨끗한나라
    '004545': 'Ggaeggeushannara Pref', // 깨끗한나라우
    '004560': 'Hyundai Biaenjiseutil', // 현대비앤지스틸
    '004690': 'Samceonri', // 삼천리
    '0046A0': 'TIGER US Co Short-Term (3 Gaeweoliha ) Treasury Bond', // TIGER 미국초단기(3개월이하)국채
    '0046Y0': 'ACE US Dividend Quality', // ACE 미국배당퀄리티
    '004700': 'Jogwangpihyeog', // 조광피혁
    '004710': 'Hansol Technics', // 한솔테크닉스
    '004720': 'Pamjensaieonseu', // 팜젠사이언스
    '004770': 'Sseoni Electronics', // 써니전자
    '0047A0': 'TIGER China Tech Top 10', // TIGER 차이나테크TOP10
    '0047N0': 'PLUS China AI Tech Top 10', // PLUS 차이나AI테크TOP10
    '0047P0': 'RISE Tesla Fixed Tech 100', // RISE 테슬라고정테크100
    '0047R0': 'RISE Palantir Fixed Tech 100', // RISE 팔란티어고정테크100
    '004800': 'Hyosung', // 효성
    '004830': 'Deogseong', // 덕성
    '004835': 'Deogseong Pref', // 덕성우
    '004840': 'DRB Dongil', // DRB동일
    '004870': 'Tiwei Holdings', // 티웨이홀딩스
    '004890': 'Dongil Industries', // 동일산업
    '0048J0': 'KODEX US Money Market Active', // KODEX 미국머니마켓액티브
    '0048K0': 'KODEX China Humanoid Robotics', // KODEX 차이나휴머노이드로봇
    '004910': 'Jogwangpeinteu', // 조광페인트
    '004920': 'Ssiai Tech', // 씨아이테크
    '004960': 'Hansingongyeong', // 한신공영
    '004970': 'Sinragyoyeog', // 신라교역
    '004980': 'Seongsinyanghoe', // 성신양회
    '004985': 'Seongsinyanghoe Pref', // 성신양회우
    '004990': 'Lotte Holdings', // 롯데지주
    '00499K': 'Lotte Holdings Pref', // 롯데지주우
    '0049K0': 'ACE US Dividend Quality Bond Mixed 50', // ACE 미국배당퀄리티채권혼합50
    '0049M0': 'ACE US Dividend Quality + Covered Call Active', // ACE 미국배당퀄리티+커버드콜액티브
    '005010': 'Hyuseutil', // 휴스틸
    '005030': 'Busanjugong', // 부산주공
    '005070': 'Koseumosinsojae', // 코스모신소재
    '005090': 'SGC Energy', // SGC에너지
    '0050E0': 'PLUS US AI Eijeonteu', // PLUS 미국AI에이전트
    '005110': 'Hancang', // 한창
    '005180': 'Binggrae', // 빙그레
    '0051A0': 'Koact Broadcom Value Cein Active', // KoAct 브로드컴밸류체인액티브
    '0051G0': 'SOL US Nuclear SMR', // SOL 미국원자력SMR
    '005250': 'GC Holdings', // 녹십자홀딩스
    '005257': 'GC Holdings 2nd Pref', // 녹십자홀딩스2우
    '0052D0': 'TIGER Korea Dividend Dow Jones', // TIGER 코리아배당다우존스
    '0052S0': '1Q US S&P500 US Cae Mixed 50 Active', // 1Q 미국S&P500미국채혼합50액티브
    '0052T0': '1Q Short/Mid-Term Corporate Bond (A- Isang ) Active', // 1Q 중단기회사채(A-이상)액티브
    '005300': 'Lotte Cilseong', // 롯데칠성
    '005305': 'Lotte Cilseong Pref', // 롯데칠성우
    '005320': 'Ontaideu', // 온타이드
    '005360': 'Monami', // 모나미
    '005380': 'Hyundai Motor', // 현대차
    '005385': 'Hyundai Motor Pref', // 현대차우
    '005387': 'Hyundai Motor 2nd Pref B', // 현대차2우B
    '005389': 'Hyundai Motor 3rd Pref B', // 현대차3우B
    '0053L0': 'TIGER China Humanoid Robotics', // TIGER 차이나휴머노이드로봇
    '0053M0': 'Deojei Small & Mid Cap Focus Active', // 더제이 중소형포커스액티브
    '005420': 'Koseumo Chemical', // 코스모화학
    '005430': 'Korea Gonghang', // 한국공항
    '005440': 'Hyundai GF Holdings', // 현대지에프홀딩스
    '005490': 'POSCO Holdings', // POSCO홀딩스
    '005500': 'Samjin Pharmaceutical', // 삼진제약
    '005610': 'SPC Samlip', // SPC삼립
    '005680': 'Samyeong Electronics', // 삼영전자
    '005690': 'Pamisel', // 파미셀
    '005720': 'Negsen', // 넥센
    '005725': 'Negsen Pref', // 넥센우
    '005740': 'Keuraunhaetae Holdings', // 크라운해태홀딩스
    '005745': 'Keuraunhaetae Holdings Pref', // 크라운해태홀딩스우
    '005750': 'Daelim Baseu', // 대림바스
    '0057H0': 'PLUS US S&P500 US Cae Mixed 50 Active', // PLUS 미국S&P500미국채혼합50액티브
    '005800': 'Sinyeongwakoru', // 신영와코루
    '005810': 'Pungsan Holdings', // 풍산홀딩스
    '005820': 'Weonrim', // 원림
    '005830': 'DB Non-Life Insurance', // DB손해보험
    '005850': 'Eseuel', // 에스엘
    '005870': 'Hyunideu', // 휴니드
    '005880': 'Korea Haeun', // 대한해운
    '005930': 'Samsung Electronics', // 삼성전자
    '005935': 'Samsung Electronics Pref', // 삼성전자우
    '005940': 'NH Investment & Securities', // NH투자증권
    '005945': 'NH Investment & Securities Pref', // NH투자증권우
    '005950': 'Isu Chemical', // 이수화학
    '005960': 'Dongbu Engineering & Construction', // 동부건설
    '005965': 'Dongbu Engineering & Construction Pref', // 동부건설우
    '006040': 'Dongweon Industries', // 동원산업
    '006060': 'Hwaseungindeo', // 화승인더
    '006090': 'Sajooyang', // 사조오양
    '0060H0': 'TIGER Total World Stock Active', // TIGER 토탈월드스탁액티브
    '006110': 'Samaalminyum', // 삼아알미늄
    '006120': 'SK Diseukeobeori', // SK디스커버리
    '006125': 'SK Diseukeobeori Pref', // SK디스커버리우
    '0061Z0': 'RISE Short-Term Teugsu Bank Cae Active', // RISE 단기특수은행채액티브
    '006200': 'Korea Electronics Holdings', // 한국전자홀딩스
    '006220': 'Jeju Bank', // 제주은행
    '006260': 'LS', // LS
    '006280': 'GC', // 녹십자
    '006340': 'Daeweonjeonseon', // 대원전선
    '006345': 'Daeweonjeonseon Pref', // 대원전선우
    '006360': 'GS Engineering & Construction', // GS건설
    '006370': 'Daegubaeghwajeom', // 대구백화점
    '006380': 'Kapeuro', // 카프로
    '006400': 'Samsung SDI', // 삼성SDI
    '006405': 'Samsung S DI Pref', // 삼성SDI우
    '006490': 'Inseukobi', // 인스코비
    '0064K0': 'KODEX Geum Active', // KODEX 금액티브
    '006570': 'Daelim Tongsang', // 대림통상
    '0065G0': 'KODEX China Tech Top 10', // KODEX 차이나테크TOP10
    '006650': 'Korea Yuhwa', // 대한유화
    '006660': 'Samsung Gongjo', // 삼성공조
    '0066W0': 'SOL International Gold', // SOL 국제금
    '006740': 'Beulru Industries Gaebal', // 블루산업개발
    '0067V0': 'TIGER China Global Rideoseu Top 3 +', // TIGER 차이나글로벌리더스TOP3+
    '0067Y0': 'TIGER China AI Software', // TIGER 차이나AI소프트웨어
    '006800': 'Mirae Asset Securities', // 미래에셋증권
    '006805': 'Mirae Asset Securities Pref', // 미래에셋증권우
    '00680K': 'Mirae Asset Securities 2nd Pref B', // 미래에셋증권2우B
    '006840': 'AK Holdings', // AK홀딩스
    '006880': 'Sinsong Holdings', // 신송홀딩스
    '006890': 'Taegyeongkemikeol', // 태경케미컬
    '0068M0': 'KODEX US S&P500 Beopeo 6 Weol Active', // KODEX 미국S&P500버퍼6월액티브
    '006980': 'USeong', // 우성
    '0069M0': '1Q US Nasdaq 100', // 1Q 미국나스닥100
    '007070': 'GS Riteil', // GS리테일
    '007110': 'Ilsinseogjae', // 일신석재
    '007120': 'Miraeaiaenji', // 미래아이앤지
    '007160': 'Sajo Industries', // 사조산업
    '007210': 'Byeogsan', // 벽산
    '007280': 'Korea Teuggang', // 한국특강
    '0072R0': 'TIGER KRX Physical Gold', // TIGER KRX금현물
    '007310': 'Ottogi', // 오뚜기
    '007340': 'DN Otomotibeu', // DN오토모티브
    '0073X0': 'FOCUS Alibaba US Cae Covered Call Mixed', // FOCUS 알리바바미국채커버드콜혼합
    '007460': 'Eipeurojen', // 에이프로젠
    '0074K0': 'Koact K Export Core Companies Top 30 Active', // KoAct K수출핵심기업TOP30액티브
    '007540': 'Saempyo', // 샘표
    '007570': 'Ilyang Pharmaceutical', // 일양약품
    '007575': 'Ilyang Pharmaceutical Pref', // 일양약품우
    '007590': 'Dongbangageuro', // 동방아그로
    '007610': 'Seondo Electric', // 선도전기
    '007660': 'Isupetasiseu', // 이수페타시스
    '007690': 'Gugdo Chemical', // 국도화학
    '007700': 'F&F Holdings', // F&F홀딩스
    '007810': 'Korea Sseokiteu', // 코리아써키트
    '007815': 'Korea Sseo Pref', // 코리아써우
    '00781K': 'Korea Sseokiteu 2nd Pref B', // 코리아써키트2우B
    '007860': 'Seoyeon', // 서연
    '0078V0': 'PLUS US Robotaxi', // PLUS 미국로보택시
    '007980': 'TP', // TP
    '0079X0': 'ACE BYD Value Cein Active', // ACE BYD밸류체인액티브
    '008040': 'Sajodongaweon', // 사조동아원
    '008060': 'Daedeog', // 대덕
    '00806K': 'Daedeog 1st Pref', // 대덕1우
    '0080G0': 'KODEX Defense Top 10', // KODEX 방산TOP10
    '0080X0': 'SOL US S&P500 US Cae Mixed 50', // SOL 미국S&P500미국채혼합50
    '0080Y0': 'SOL Joseon Top 3 Plus Rebeoriji', // SOL 조선TOP3플러스레버리지
    '008110': 'Daedong Electronics', // 대동전자
    '008250': 'Igeon Industries', // 이건산업
    '008260': 'NI Seutil', // NI스틸
    '0082F0': 'HANARO Europe Defense', // HANARO 유럽방산
    '0082V0': 'KODEX TDF 2060 Active', // KODEX TDF2060액티브
    '008350': 'Namseonalminyum', // 남선알미늄
    '008355': 'Namseonalmi Pref', // 남선알미우
    '0083S0': '1Q US Medical AI', // 1Q 미국메디컬AI
    '008420': 'Munbaeceolgang', // 문배철강
    '008490': 'Seoheung', // 서흥
    '0084D0': 'KIWOOM US Tech 100 Monthly Target Heji Active', // KIWOOM 미국테크100월간목표헤지액티브
    '0084E0': 'KIWOOM US Large Cap 500 Monthly Target Heji Active', // KIWOOM 미국대형주500월간목표헤지액티브
    '008500': 'Iljeongsileob', // 일정실업
    '0085N0': 'ACE US 10 Nyeon Treasury Bond Active (H)', // ACE 미국10년국채액티브(H)
    '0085P0': 'ACE US 10 Nyeon Treasury Bond Active', // ACE 미국10년국채액티브
    '008600': 'Wilbiseu', // 윌비스
    '0086B0': 'TIGER REITs Real Estate Infrastructure Top 10 Active', // TIGER 리츠부동산인프라TOP10액티브
    '0086C0': 'TIGER REITs Real Estate Infrastructure 10 Bond Mixed Active', // TIGER 리츠부동산인프라10채권혼합액티브
    '008700': 'Anam Electronics', // 아남전자
    '008730': 'Yulcon Chemical', // 율촌화학
    '008770': 'Hotel Shilla', // 호텔신라
    '008775': 'Hotel Shilla Pref', // 호텔신라우
    '0087F0': 'ACE China AI Big Tech Top 2 + Active', // ACE 차이나AI빅테크TOP2+액티브
    '008870': 'Geumbi', // 금비
    '0088N0': 'WON K- Global Sugeubsangwi', // WON K-글로벌수급상위
    '008930': 'Hanmisaieonseu', // 한미사이언스
    '008970': 'KB I Dongyangceolgwan', // KBI동양철관
    '0089B0': 'PLUS US Nasdaq 100 US Cae Mixed 50', // PLUS 미국나스닥100미국채혼합50
    '0089C0': 'KODEX US S&P500 Byeondongseonghwagdaesi Covered Call', // KODEX 미국S&P500변동성확대시커버드콜
    '0089D0': 'KODEX Financial High Dividend Top 10', // KODEX 금융고배당TOP10
    '009070': 'KCTC', // KCTC
    '0090B0': 'PLUS K Defense Sobujang', // PLUS K방산소부장
    '009140': 'Gyeongin Electronics', // 경인전자
    '009150': 'Samsung Electro-Mechanics', // 삼성전기
    '009155': 'Samsung Electric Pref', // 삼성전기우
    '009160': 'SIMPAC', // SIMPAC
    '009180': 'Hansol Logistics', // 한솔로지스틱스
    '009190': 'Daeyanggeumsog', // 대양금속
    '0091C0': 'KODEX US 10 Nyeon Treasury Bond Active (H)', // KODEX 미국10년국채액티브(H)
    '0091M0': 'HANARO 27-06 Corporate Bond (AA- Isang ) Active', // HANARO 27-06 회사채(AA-이상)액티브
    '0091P0': 'TIGER Korea Nuclear Power', // TIGER 코리아원자력
    '009200': 'Murimpeipeo', // 무림페이퍼
    '009240': 'Hansaem', // 한샘
    '009270': 'Sinweon', // 신원
    '009290': 'Gwangdong Pharmaceutical', // 광동제약
    '0092B0': 'SOL Korea Nuclear SMR', // SOL 한국원자력SMR
    '0092C0': 'SOL 27-12 Corporate Bond (AA- Isang ) Active', // SOL 27-12 회사채(AA-이상)액티브
    '009310': 'Camenjinieoring', // 참엔지니어링
    '009320': 'Ajin Electronics Bupum', // 아진전자부품
    '0093A0': 'RISE AI Semiconductor Top 10', // RISE AI반도체TOP10
    '0093B0': 'RISE NVI DI A Fixed Tech 100', // RISE 엔비디아고정테크100
    '0093D0': 'Koact Palantir Value Cein Active', // KoAct 팔란티어밸류체인액티브
    '009410': 'Taeyeong Engineering & Construction', // 태영건설
    '009415': 'Taeyeong Engineering & Construction Pref', // 태영건설우
    '009420': 'Hanol Bio Pama', // 한올바이오파마
    '009440': 'KC Geurin Holdings', // KC그린홀딩스
    '009450': 'Gyeongdongnabien', // 경동나비엔
    '009460': 'Hancang Paper', // 한창제지
    '009470': 'Samhwa Electric', // 삼화전기
    '0094K0': 'TIGER 28-04 Corporate Bond (A+ Isang ) Active', // TIGER 28-04 회사채(A+이상)액티브
    '0094L0': 'RISE China Tech Top 10 Wikeulri Target Covered Call', // RISE 차이나테크TOP10위클리타겟커버드콜
    '0094M0': 'RISE Korea Value Eobwikeulri Fixed Covered Call', // RISE 코리아밸류업위클리고정커버드콜
    '0094X0': '1Q Syaomi Value Cein Active', // 1Q 샤오미밸류체인액티브
    '009540': 'HD Korea Joseonhaeyang', // HD한국조선해양
    '009580': 'Murim P&P', // 무림P&P
    '009680': 'Motonig', // 모토닉
    '009770': 'Samjeongpeolpeu', // 삼정펄프
    '0097L0': 'KIWOOM Korea High Dividend & US AI Tech', // KIWOOM 한국고배당&미국AI테크
    '009810': 'Peulreigeuraem', // 플레이그램
    '009830': 'Hanwha Solrusyeon', // 한화솔루션
    '009835': 'Hanwha Solrusyeon Pref', // 한화솔루션우
    '0098F0': 'KODEX Nuclear SMR', // KODEX 원자력SMR
    '0098N0': 'PLUS Jasajumaeib High Dividend Ju', // PLUS 자사주매입고배당주
    '0098Z0': 'FOCUS 200', // FOCUS 200
    '009900': 'Myeongsin Industries', // 명신산업
    '009970': 'Yeongweonmuyeog Holdings', // 영원무역홀딩스
    '0099L0': 'ACE Blue-Chip Corporate Bond (AA- Isang ) Active', // ACE 우량회사채(AA-이상)액티브
    '010040': 'Korea Naehwa', // 한국내화
    '010060': 'OCI Holdings', // OCI홀딩스
    '0100K0': 'KODEX Defense Top 10 Rebeoriji', // KODEX 방산TOP10레버리지
    '010100': 'Korea Mubeunegseu', // 한국무브넥스
    '010120': 'LS ELECTRIC', // LS ELECTRIC
    '010130': 'Korea Zinc', // 고려아연
    '010140': 'Samsung Heavy Industries', // 삼성중공업
    '0101N0': 'RISE AI Jeonryeoginpeura', // RISE AI전력인프라
    '0102A0': 'TIGER US AI Software TOP4Plus', // TIGER 미국AI소프트웨어TOP4Plus
    '0102X0': 'ACE Europe Defense Top 10', // ACE 유럽방산TOP10
    '0103T0': '1Q K Sobeorin AI', // 1Q K소버린AI
    '010400': 'Ujinaieneseu', // 우진아이엔에스
    '0104G0': 'PLUS K Defense Rebeoriji', // PLUS K방산레버리지
    '0104H0': 'Koact US Nasdaq Bond Mixed 50 Active', // KoAct 미국나스닥채권혼합50액티브
    '0104N0': 'TIGER 200 Target Wikeulri Covered Call', // TIGER 200타겟위클리커버드콜
    '0104P0': 'TIGER Korea Dividend Dow Jones Wikeulri Covered Call', // TIGER 코리아배당다우존스위클리커버드콜
    '010580': 'Eseuembegsel', // 에스엠벡셀
    '0105D0': 'SOL Korea AI Software', // SOL 한국AI소프트웨어
    '0105E0': 'SOL Korea High Dividend', // SOL 코리아고배당
    '010640': 'Jinyangpolri', // 진양폴리
    '010660': 'Hwaceongigye', // 화천기계
    '010690': 'Hwasin', // 화신
    '0106J0': 'Daishin KOSPI200 Indegseu X Keulraeseu', // 대신 KOSPI200인덱스 X클래스
    '010770': 'Pyeonghwa Holdings', // 평화홀딩스
    '010780': 'AIeseudongseo', // 아이에스동서
    '0107F0': 'KIWOOM US High Dividend & AI Tech', // KIWOOM 미국고배당&AI테크
    '010820': 'Peoseuteg', // 퍼스텍
    '010950': 'S-Oil', // S-Oil
    '010955': 'S-Oil Pref', // S-Oil우
    '010960': 'Samhogaebal', // 삼호개발
    '011000': 'Jinweonsaengmyeonggwahag', // 진원생명과학
    '011070': 'LG Innotek', // LG이노텍
    '011090': 'Enegseu', // 에넥스
    '011150': 'CJ Ssipudeu', // CJ씨푸드
    '011155': 'CJ Ssipudeu 1st Pref', // CJ씨푸드1우
    '011170': 'Lotte Chemical', // 롯데케미칼
    '0111J0': 'HANARO Securities High Dividend Top 3 Plus', // HANARO 증권고배당TOP3플러스
    '0111P0': '1Q US Nasdaq 100 US Cae Mixed 50 Active', // 1Q 미국나스닥100미국채혼합50액티브
    '011200': 'HMM', // HMM
    '011210': 'Hyundai Wia', // 현대위아
    '011230': 'Samhwa Electronics', // 삼화전자
    '011280': 'Taerimpojang', // 태림포장
    '0112X0': 'Maiti 200TR', // 마이티 200TR
    '011300': 'Seonganmeotirieolseu', // 성안머티리얼스
    '011330': 'Yunikem', // 유니켐
    '011390': 'Busan Industries', // 부산산업
    '0113D0': 'TIME Global Tabpig Active', // TIME 글로벌탑픽액티브
    '0113G0': 'Koact US Bio Helseukeeo Active', // KoAct 미국바이오헬스케어액티브
    '0113P0': 'HK Money Market Active', // HK 머니마켓액티브
    '011420': 'Gaelreogsiaeseuem', // 갤럭시아에스엠
    '0114X0': 'RISE Global Geim Tech Top 3 Plus', // RISE 글로벌게임테크TOP3Plus
    '011500': 'Hannonghwaseong', // 한농화성
    '0115C0': 'RISE US High Dividend Dow Jones Top 10', // RISE 미국고배당다우존스TOP10
    '0115D0': 'KODEX Joseon Top 10', // KODEX 조선TOP10
    '0115E0': 'KODEX Korea Sobeorin AI', // KODEX 코리아소버린AI
    '011690': 'Waitusolrusyeon', // 와이투솔루션
    '011700': 'Hansingigye', // 한신기계
    '011760': 'Hyundai Kopeoreisyeon', // 현대코퍼레이션
    '011780': 'Kumho Seogyu Chemical', // 금호석유화학
    '011785': 'Kumho Seogyu Chemical Pref', // 금호석유화학우
    '011790': 'SK C', // SKC
    '0117L0': 'KODEX 26-12 Financial Cae (AA- Isang ) Active', // KODEX 26-12 금융채(AA-이상)액티브
    '0117V0': 'TIGER Korea AI Jeonryeoggigi Top 3 Plus', // TIGER 코리아AI전력기기TOP3플러스
    '011810': 'STX', // STX
    '0118S0': 'SOL US Negseuteu Tech Top 10 Active', // SOL 미국넥스트테크TOP10액티브
    '0118Z0': 'ACE US AI Tech Haegsim Industries Active', // ACE 미국AI테크핵심산업액티브
    '011930': 'Sinseongienji', // 신성이엔지
    '0119H0': 'KODEX 28-12 Corporate Bond (AA- Isang ) Active', // KODEX 28-12 회사채(AA-이상)액티브
    '012030': 'DB', // DB
    '0120G0': 'Samyang Bio Pam', // 삼양바이오팜
    '0120J0': 'BNK Kakao Geurub Focus', // BNK 카카오그룹포커스
    '0120X0': 'Eugene Caempieon Short/Mid-Term Keuredis X Keulraeseu', // 유진 챔피언중단기크레딧 X클래스
    '012160': 'Yeongheung', // 영흥
    '012170': 'Asendio', // 아센디오
    '012200': 'Gyeyang Electric', // 계양전기
    '012205': 'Gyeyang Electric Pref', // 계양전기우
    '012280': 'Yeonghwageumsog', // 영화금속
    '0122W0': 'RISE 26-11 Corporate Bond (AA- Isang ) Active', // RISE 26-11 회사채(AA-이상)액티브
    '012320': 'Gyeongdonginbeseuteu', // 경동인베스트
    '012330': 'Hyundai Mobis', // 현대모비스
    '0123G0': 'TIGER US AI Jeonryeog SMR', // TIGER 미국AI전력SMR
    '0123S0': 'HANARO 26-12 Bank Cae (AA+ Isang ) Active', // HANARO 26-12 은행채(AA+이상)액티브
    '012450': 'Hanwha Eeoroseupeiseu', // 한화에어로스페이스
    '012510': 'Deojonbijeuon', // 더존비즈온
    '012610': 'Gyeonginyanghaeng', // 경인양행
    '012630': 'HDC', // HDC
    '012690': 'Monarinvestment', // 모나리자
    '0126Z0': 'Samsung Episeu Holdings', // 삼성에피스홀딩스
    '012750': 'Eseuweon', // 에스원
    '0127M0': 'ACE US Daehyeong Value Ju Active', // ACE 미국대형가치주액티브
    '0127P0': 'ACE US Daehyeong Growth Ju Active', // ACE 미국대형성장주액티브
    '0127R0': 'RISE US AI Keulraudeuinpeura', // RISE 미국AI클라우드인프라
    '0127T0': 'KIWOOM US S&P500 & Dividend Dow Jones Bijungjeonhwan', // KIWOOM 미국S&P500&배당다우존스비중전환
    '0127V0': 'KIWOOM US S&P500 Top 10 & Dividend Daubijungjeon', // KIWOOM 미국S&P500 TOP10&배당다우비중전
    '012800': 'Daecang', // 대창
    '0128D0': 'PLUS China Hangseng Tech Wikeulri Target Covered Call', // PLUS 차이나항셍테크위클리타겟커버드콜
    '013000': 'Seu Global', // 세우글로벌
    '0131A0': 'SOL China Sobiteurendeu', // SOL 차이나소비트렌드
    '0131V0': '1Q US Uju AIr Tech', // 1Q 미국우주항공테크
    '0131W0': '1Q Short-Term Teugsu Bank Cae Active', // 1Q 단기특수은행채액티브
    '0132D0': 'Koact Global K Keolceo Value Cein Active', // KoAct 글로벌K컬처밸류체인액티브
    '0132H0': 'KODEX US Nuclear SMR', // KODEX 미국원자력SMR
    '0132K0': 'PLUS Tesla Wikeulri Covered Call Bond Mixed', // PLUS 테슬라위클리커버드콜채권혼합
    '013360': 'Ilseong Engineering & Construction', // 일성건설
    '0133E0': 'TIGER China Securities', // TIGER 차이나증권
    '013520': 'Hwaseungkopeoreisyeon', // 화승코퍼레이션
    '013570': 'Diwai', // 디와이
    '013580': 'Gyeryong Engineering & Construction', // 계룡건설
    '0135Y0': 'ITF Junggijonghab Bond (AA- Isang ) Active', // ITF 중기종합채권(AA-이상)액티브
    '013700': 'Ggamyuiaenssi', // 까뮤이앤씨
    '0137V0': 'KIWOOM US S&P500 Momenteom', // KIWOOM 미국S&P500모멘텀
    '0137W0': 'KIWOOM US S&P500 &GOLD', // KIWOOM 미국S&P500&GOLD
    '013870': 'Jiembi Korea', // 지엠비코리아
    '013890': 'Jinuseu', // 지누스
    '0138D0': 'RISE Donghaggaemi', // RISE 동학개미
    '0138T0': 'RISE US S&P500 Daily Fixed Covered Call', // RISE 미국S&P500데일리고정커버드콜
    '0138Y0': 'PLUS Geum Bond Mixed', // PLUS 금채권혼합
    '0139F0': 'TIGER 12 Weoljadongyeonjang Financial Cae (AA- Isang ) Active', // TIGER 12월자동연장금융채(AA-이상)액티브
    '0139P0': 'ACE High Dividend Ju', // ACE 고배당주
    '014130': 'Hanigseupeureseu', // 한익스프레스
    '014160': 'Daeyeongpojang', // 대영포장
    '0141S0': 'SOL Joseonginvestmentjae', // SOL 조선기자재
    '0141T0': 'SOL Junggijonghab Bond (AA- Isang ) Active', // SOL 중기종합채권(AA-이상)액티브
    '014280': 'Geumganggongeob', // 금강공업
    '014285': 'Geumganggongeob Pref', // 금강공업우
    '0142D0': 'TIGER US AI Deiteosenteo TOP4Plus', // TIGER 미국AI데이터센터TOP4Plus
    '014440': 'Yeongbo Chemical', // 영보화학
    '0144L0': 'KODEX US Growth Covered Call Active', // KODEX 미국성장커버드콜액티브
    '0144M0': 'KODEX US Deuron UAM Top 10', // KODEX 미국드론UAM TOP10
    '014530': 'Geugdongyuhwa', // 극동유화
    '014580': 'Taegyeongbikei', // 태경비케이
    '014680': 'Hansol Chemical', // 한솔케미칼
    '014710': 'Sajossipudeu', // 사조씨푸드
    '014790': 'HL D&I', // HL D&I
    '014820': 'Dongweonsiseutemjeu', // 동원시스템즈
    '014825': 'Dongweonsiseutemjeu Pref', // 동원시스템즈우
    '014830': 'Yunideu', // 유니드
    '0148J0': 'TIGER Korea Humanoid Robotics Industries', // TIGER 코리아휴머노이드로봇산업
    '014910': 'Seongmun Electronics', // 성문전자
    '014915': 'Seongmun Electronics Pref', // 성문전자우
    '014990': 'Indiepeu', // 인디에프
    '015020': 'Iseutako', // 이스타코
    '0150K0': 'Koact Susojeonryeog ESS Inpeura Active', // KoAct 수소전력ESS인프라액티브
    '0151P0': 'RISE Korea Jeonryag Industries Active', // RISE 코리아전략산업액티브
    '0151S0': 'KODEX US AI Semiconductor Top 3 Plus', // KODEX 미국AI반도체TOP3플러스
    '015230': 'Daecangdanjo', // 대창단조
    '015260': 'Eienpi', // 에이엔피
    '0152E0': 'SOL Dividend Seonghyangtabpig Active', // SOL 배당성향탑픽액티브
    '015360': 'INVENI', // INVENI
    '0153K0': 'KODEX Jujuhwanweon High Dividend Ju', // KODEX 주주환원고배당주
    '0153P0': 'ACE REITs Real Estate Infrastructure Active', // ACE 리츠부동산인프라액티브
    '0153X0': 'PLUS US High Dividend Ju Active', // PLUS 미국고배당주액티브
    '0154F0': 'WON Codaehyeong IB& Financial Group', // WON 초대형IB&금융지주
    '0154H0': 'Koact China Bio Helseukeeo Active', // KoAct 차이나바이오헬스케어액티브
    '015590': 'DKME', // DKME
    '0155M0': 'ACE US SMR Nuclear Power Top 10', // ACE 미국SMR원자력TOP10
    '0155N0': 'HANARO K Hyumeonoideutema Top 10', // HANARO K휴머노이드테마TOP10
    '015760': 'Korea Jeonryeog', // 한국전력
    '015860': 'Iljin Holdings', // 일진홀딩스
    '015890': 'Taegyeong Industries', // 태경산업
    '016090': 'Daehyeon', // 대현
    '0162L0': 'KODEX China AI Semiconductor Top 10', // KODEX 차이나AI반도체TOP10
    '0162M0': 'KODEX Financial Cae 1~2 Nyeon (AA- Isang ) PLUS Active', // KODEX 금융채1~2년(AA-이상)PLUS액티브
    '0162Y0': 'TIME Koseudag Active', // TIME 코스닥액티브
    '0162Z0': 'RISE Samsung Electronics SK hynix Bond Mixed 50', // RISE 삼성전자SK하이닉스채권혼합50
    '016360': 'Samsung Securities', // 삼성증권
    '016380': 'KG Seutil', // KG스틸
    '0163Y0': 'Koact Koseudag Active', // KoAct 코스닥액티브
    '016450': 'Hanseyeseu 24 Holdings', // 한세예스24홀딩스
    '0164G0': 'RISE China AI Semiconductor TOP4Plus', // RISE 차이나AI반도체TOP4Plus
    '016580': 'Hwanin Pharmaceutical', // 환인제약
    '016590': 'Sindaeyang Paper', // 신대양제지
    '016610': 'DB Securities', // DB증권
    '0166N0': 'PLUS Koseudag 150 Active', // PLUS 코스닥150액티브
    '0166S0': 'PLUS K Manufacturing Core Companies Active', // PLUS K제조업핵심기업액티브
    '016710': 'Daeseong Holdings', // 대성홀딩스
    '016740': 'Duol', // 두올
    '0167A0': 'SOL AI Semiconductor Top 2 Plus', // SOL AI반도체TOP2플러스
    '0167B0': 'SOL 200 Target Wikeulri Covered Call', // SOL 200타겟위클리커버드콜
    '0167Z0': 'KODEX US Uju AIr', // KODEX 미국우주항공
    '016800': 'Peosiseu', // 퍼시스
    '016880': 'Ungjin', // 웅진
    '0168K0': 'TIGER Gisulijeon Bio Active', // TIGER 기술이전바이오액티브
    '017040': 'Gwangmyeong Electric', // 광명전기
    '017180': 'Myeongmun Pharmaceutical', // 명문제약
    '017370': 'USinsiseutem', // 우신시스템
    '017390': 'Seoulgaseu', // 서울가스
    '017550': 'Susansebotigseu', // 수산세보틱스
    '017670': 'SK Telecom', // SK텔레콤
    '017800': 'Hyundai Elribeiteo', // 현대엘리베이터
    '017810': 'Pulmuweon', // 풀무원
    '017860': 'DS Danseog', // DS단석
    '017900': 'Gwang Electronics', // 광전자
    '017940': 'E1', // E1
    '017960': 'Korea Kabon', // 한국카본
    '018250': 'Aegyeong Industries', // 애경산업
    '018260': 'Samsung SDS', // 삼성에스디에스
    '018470': 'Joilalminyum', // 조일알미늄
    '018500': 'Dongweongeumsog', // 동원금속
    '018670': 'SK Gaseu', // SK가스
    '018880': 'Hanonsiseutem', // 한온시스템
    '019170': 'Sinpung Pharmaceutical', // 신풍제약
    '019175': 'Sinpung Pharmaceutical Pref', // 신풍제약우
    '019180': 'Tieicien', // 티에이치엔
    '019490': 'Egsikyueohaiteuron', // 엑시큐어하이트론
    '019680': 'Daegyo', // 대교
    '019685': 'Daegyo Pref B', // 대교우B
    '020000': 'Hanseom', // 한섬
    '020120': 'Kidariseutyudio', // 키다리스튜디오
    '020150': 'Lotte Energy Meotirieoljeu', // 롯데에너지머티리얼즈
    '020560': 'Asiana AIr', // 아시아나항공
    '020760': 'Iljindiseupeul', // 일진디스플
    '021050': 'Seoweon', // 서원
    '021240': 'Kowei', // 코웨이
    '021820': 'Seweonjeonggong', // 세원정공
    '022100': 'POSCO DX', // 포스코DX
    '023000': 'Samweongangjae', // 삼원강재
    '023150': 'MH Etanol', // MH에탄올
    '023350': 'Korea Jonghabgisul', // 한국종합기술
    '023450': 'Dongnam Synthetic', // 동남합성
    '023530': 'Lotte Syoping', // 롯데쇼핑
    '023590': 'Daugisul', // 다우기술
    '023800': 'Injikeonteurolseu', // 인지컨트롤스
    '023810': 'Inpaeg', // 인팩
    '023960': 'Esseussienjinieoring', // 에쓰씨엔지니어링
    '024070': 'WISCOM', // WISCOM
    '024090': 'Dissiem', // 디씨엠
    '024110': 'Gieob Bank', // 기업은행
    '024720': 'Kolma Holdings', // 콜마홀딩스
    '024890': 'Daeweonhwaseong', // 대원화성
    '024900': 'Diwaideogyang', // 디와이덕양
    '025000': 'KPX Chemical', // KPX케미칼
    '025530': 'SJM Holdings', // SJM홀딩스
    '025540': 'Korea Danja', // 한국단자
    '025560': 'Mirae Industries', // 미래산업
    '025620': 'Ca AI Helseukeeo', // 차AI헬스케어
    '025750': 'Hansolhomdeko', // 한솔홈데코
    '025820': 'Igu Industries', // 이구산업
    '025860': 'Namhae Chemical', // 남해화학
    '025890': 'Korea Jugang', // 한국주강
    '026890': 'Seutiginbeseuteumeonteu', // 스틱인베스트먼트
    '026940': 'Bugugceolgang', // 부국철강
    '026960': 'Dongseo', // 동서
    '027410': 'BGF', // BGF
    '027740': 'Manikeo', // 마니커
    '027970': 'Korea Paper', // 한국제지
    '028050': 'Samsung E&A', // 삼성E&A
    '028100': 'Dongajijil', // 동아지질
    '028260': 'Samsung C&T', // 삼성물산
    '02826K': 'Samsung C&T Pref B', // 삼성물산우B
    '028670': 'Paenosyeon', // 팬오션
    '029460': 'Keissi', // 케이씨
    '029530': 'Sindiariko', // 신도리코
    '029780': 'Samsung Card', // 삼성카드
    '030000': 'Jeilgihoeg', // 제일기획
    '030190': 'NICE Pyeonggajeongbo', // NICE평가정보
    '030200': 'KT', // KT
    '030210': 'Daol Investment & Securities', // 다올투자증권
    '030610': 'Gyobosecurities', // 교보증권
    '030720': 'Dongweonsusan', // 동원수산
    '031210': 'Seoulbojeung Insurance', // 서울보증보험
    '031430': 'Shinsegae Inteonaesyeonal', // 신세계인터내셔날
    '031440': 'Shinsegae Pudeu', // 신세계푸드
    '031820': 'AItisenssitieseu', // 아이티센씨티에스
    '032350': 'Lotte Gwangwanggaebal', // 롯데관광개발
    '032560': 'Hwanggeumeseuti', // 황금에스티
    '032640': 'LG Yu Plus', // LG유플러스
    '032830': 'Samsung Life Insurance', // 삼성생명
    '033240': 'Jahwa Electronics', // 자화전자
    '033250': 'Cesiseu', // 체시스
    '033270': 'Yunaitideu Pharmaceutical', // 유나이티드제약
    '033530': 'SJG Sejong', // SJG세종
    '033780': 'KT &G', // KT&G
    '033920': 'Muhag', // 무학
    '034020': 'Doosan Enerbility', // 두산에너빌리티
    '034120': 'SBS', // SBS
    '034220': 'LG Display', // LG디스플레이
    '034230': 'Paradaiseu', // 파라다이스
    '034310': 'NICE', // NICE
    '034590': 'Inceondosigaseu', // 인천도시가스
    '034730': 'SK', // SK
    '03473K': 'SK Pref', // SK우
    '034830': 'Korea Tojisintag', // 한국토지신탁
    '035000': 'HS Aedeu', // HS애드
    '035150': 'Baegsan', // 백산
    '035250': 'Gangweonraendeu', // 강원랜드
    '035420': 'NAVER', // NAVER
    '035510': 'Shinsegae I&C', // 신세계 I&C
    '035720': 'Kakao', // 카카오
    '036420': 'Kontenteurijungang', // 콘텐트리중앙
    '036460': 'Korea Gaseugongsa', // 한국가스공사
    '036530': 'SNT Holdings', // SNT홀딩스
    '036570': 'Enssisopeuteu', // 엔씨소프트
    '036580': 'Pamseuko', // 팜스코
    '037270': 'YG PLUS', // YG PLUS
    '037560': 'LG Helrobijeon', // LG헬로비전
    '037710': 'Gwangju Shinsegae', // 광주신세계
    '039130': 'Hana Tueo', // 하나투어
    '039490': 'Kiumsecurities', // 키움증권
    '039570': 'HDC Raebseu', // HDC랩스
    '041650': 'Sangsinbeureikeu', // 상신브레이크
    '042660': 'Hanwha Osyeon', // 한화오션
    '042700': 'Hanmi Semiconductor', // 한미반도체
    '044380': 'Juyeon Tech', // 주연테크
    '044450': 'KSS Haeun', // KSS해운
    '044820': 'Koseumaegseubitiai', // 코스맥스비티아이
    '047040': 'Daeu Engineering & Construction', // 대우건설
    '047050': 'POSCO International', // 포스코인터내셔널
    '047400': 'Yunionmeotirieol', // 유니온머티리얼
    '047810': 'Korea AIr Uju', // 한국항공우주
    '049800': 'Ujinpeulraim', // 우진플라임
    '051600': 'Hanjeon KPS', // 한전KPS
    '051630': 'Jinyang Chemical', // 진양화학
    '051900': 'LG H&H', // LG생활건강
    '051905': 'LG Saenghwalgeongang Pref', // LG생활건강우
    '051910': 'LG Chem', // LG화학
    '051915': 'LG Chemical Pref', // LG화학우
    '052690': 'Han Electric Sul', // 한전기술
    '053210': 'Seukairaipeu', // 스카이라이프
    '053690': 'Hanmi Global', // 한미글로벌
    '055490': 'Teipaegseu', // 테이팩스
    '055550': 'Shinhan Financial Group', // 신한지주
    '057050': 'Hyundai Homsyoping', // 현대홈쇼핑
    '058430': 'POSCO Seutilrion', // 포스코스틸리온
    '058650': 'Sea Holdings', // 세아홀딩스
    '058730': 'Daseuko', // 다스코
    '058850': 'KT Cs', // KTcs
    '058860': 'KT Is', // KTis
    '060980': 'HL Holdings', // HL홀딩스
    '062040': 'Sanil Electric', // 산일전기
    '063160': 'Chong Kun Dang Bio', // 종근당바이오
    '064350': 'Hyundai Rotem', // 현대로템
    '064400': 'LG CNS', // LG씨엔에스
    '064960': 'SNT Motibeu', // SNT모티브
    '066570': 'LG Electronics', // LG전자
    '066575': 'LG Electronics Pref', // LG전자우
    '066970': 'Elaenepeu', // 엘앤에프
    '067830': 'Seibeujon I&C', // 세이브존I&C
    '068270': 'Celltrion', // 셀트리온
    '068290': 'Samsung Culpansa', // 삼성출판사
    '069260': 'T KG Hyukemseu', // TKG휴켐스
    '069460': 'Daehoeiel', // 대호에이엘
    '069500': 'KODEX 200', // KODEX 200
    '069620': 'Daeung Pharmaceutical', // 대웅제약
    '069640': 'Hanseemkei', // 한세엠케이
    '069660': 'KIWOOM 200', // KIWOOM 200
    '069730': 'DSR Jegang', // DSR제강
    '069960': 'Hyundai Baeghwajeom', // 현대백화점
    '070960': 'Monayongpyeong', // 모나용평
    '071050': 'Korea Financial Group', // 한국금융지주
    '071055': 'Korea Financial Group Pref', // 한국금융지주우
    '071090': 'Haiseutil', // 하이스틸
    '071320': 'Jiyeognanbanggongsa', // 지역난방공사
    '071840': 'Lotte Haimateu', // 롯데하이마트
    '071950': 'Koaseu', // 코아스
    '071970': 'HD Hyundai Marinenjin', // HD현대마린엔진
    '072130': 'Yuenjel', // 유엔젤
    '072710': 'Nongshim Holdings', // 농심홀딩스
    '073240': 'Kumho Taieo', // 금호타이어
    '074610': 'Ien Plus', // 이엔플러스
    '075180': 'Saeronotomotibeu', // 새론오토모티브
    '075580': 'Sejin Heavy Industries', // 세진중공업
    '077500': 'Yunikweseuteu', // 유니퀘스트
    '077970': 'STX Enjin', // STX엔진
    '078000': 'Telkoweeo', // 텔코웨어
    '078520': 'Eibeulssienssi', // 에이블씨엔씨
    '078930': 'GS', // GS
    '078935': 'GS Pref', // GS우
    '079160': 'CJ CGV', // CJ CGV
    '079430': 'Hyundai Ribateu', // 현대리바트
    '079550': 'LIG Negseuweon', // LIG넥스원
    '079900': 'Jeonjin Engineering & Construction Robos', // 전진건설로봇
    '079980': 'Hyubiseu', // 휴비스
    '081000': 'Iljindaia', // 일진다이아
    '081660': 'Miseuto Holdings', // 미스토홀딩스
    '082640': 'Dongyangsaengmyeong', // 동양생명
    '082740': 'Hanwha Enjin', // 한화엔진
    '083420': 'Geurin Chemical', // 그린케미칼
    '084010': 'Korea Jegang', // 대한제강
    '084670': 'Dongyanggosog', // 동양고속
    '084680': 'Iweoldeu', // 이월드
    '084690': 'Daesang Holdings', // 대상홀딩스
    '084695': 'Daesang Holdings Pref', // 대상홀딩스우
    '084870': 'TBH Global', // TBH글로벌
    '085310': 'Enkei', // 엔케이
    '085620': 'Mirae Asset Saengmyeong', // 미래에셋생명
    '086280': 'Hyundai Geulrobiseu', // 현대글로비스
    '086790': 'Hana Financial Group', // 하나금융지주
    '088260': 'I REITs Kokeureb', // 이리츠코크렙
    '088350': 'Hanwha Saengmyeong', // 한화생명
    '088790': 'Jindia', // 진도
    '088980': 'Maegkweoriinpeura', // 맥쿼리인프라
    '089470': 'HDC Hyundai EP', // HDC현대EP
    '089590': 'Jeju AIr', // 제주항공
    '089860': 'Lotte Rental', // 롯데렌탈
    '090080': 'Pyeonghwa Industries', // 평화산업
    '090350': 'Norupeinteu', // 노루페인트
    '090355': 'Norupeinteu Pref', // 노루페인트우
    '090370': 'Metaraebseu', // 메타랩스
    '090430': 'Amorepeosipig', // 아모레퍼시픽
    '090435': 'Amorepeosipig Pref', // 아모레퍼시픽우
    '090460': 'Bieici', // 비에이치
    '091160': 'KODEX Semiconductor', // KODEX 반도체
    '091170': 'KODEX Bank', // KODEX 은행
    '091180': 'KODEX Motor', // KODEX 자동차
    '091220': 'TIGER Bank', // TIGER 은행
    '091230': 'TIGER Semiconductor', // TIGER 반도체
    '091810': 'Tiwei AIr', // 티웨이항공
    '092200': 'Diaissi', // 디아이씨
    '092220': 'KEC', // KEC
    '092230': 'KPX Holdings', // KPX홀딩스
    '092440': 'Gisinjeonggi', // 기신정기
    '092780': 'DYP', // DYP
    '092790': 'Negseutil', // 넥스틸
    '093050': 'LF', // LF
    '093240': 'Hyeongjielriteu', // 형지엘리트
    '093370': 'Huseong', // 후성
    '094280': 'Hyosung ITX', // 효성ITX
    '094800': 'Maebseurieolti', // 맵스리얼티
    '095570': 'AJ Neteuweogseu', // AJ네트웍스
    '095720': 'Ungjinssingkeubig', // 웅진씽크빅
    '096760': 'JW Holdings', // JW홀딩스
    '096770': 'SK Innovation', // SK이노베이션
    '096775': 'SK Innovation Pref', // SK이노베이션우
    '097230': 'HJ Shipbuilding & Construction', // HJ중공업
    '097520': 'Emssinegseu', // 엠씨넥스
    '097950': 'CJ Jeiljedang', // CJ제일제당
    '097955': 'CJ Jeiljedang Pref', // CJ제일제당 우
    '099140': 'KODEX China H', // KODEX 차이나H
    '100090': 'SK Osyeonpeulraenteu', // SK오션플랜트
    '100220': 'Bisanggyoyug', // 비상교육
    '100250': 'Jinyang Holdings', // 진양홀딩스
    '100840': 'SNT Energy', // SNT에너지
    '100910': 'KIWOOM KRX 100', // KIWOOM KRX100
    '101140': 'In Bio Jen', // 인바이오젠
    '101280': 'KODEX Japan TOPIX100', // KODEX 일본TOPIX100
    '101530': 'Haetaejegwa Foods', // 해태제과식품
    '102110': 'TIGER 200', // TIGER 200
    '102260': 'Dongseongkemikeol', // 동성케미컬
    '102460': 'Iyeon Pharmaceutical', // 이연제약
    '102780': 'KODEX Samsung Geurub', // KODEX 삼성그룹
    '102960': 'KODEX Gigyejangbi', // KODEX 기계장비
    '102970': 'KODEX Securities', // KODEX 증권
    '103140': 'Pungsan', // 풍산
    '103590': 'Iljin Electric', // 일진전기
    '104520': 'KIWOOM Beulrucib', // KIWOOM 블루칩
    '104530': 'KIWOOM High Dividend', // KIWOOM 고배당
    '104700': 'Korea Ceolgang', // 한국철강
    '105010': 'TIGER Ratin 35', // TIGER 라틴35
    '105190': 'ACE 200', // ACE 200
    '105560': 'KB Financial Group', // KB금융
    '105630': 'Hansesileob', // 한세실업
    '105780': 'RISE 5 Daegeurubju', // RISE 5대그룹주
    '105840': 'Ujin', // 우진
    '107590': 'Miweon Holdings', // 미원홀딩스
    '108320': 'LX Semikon', // LX세미콘
    '108450': 'ACE Samsung Geurubsegteogajung', // ACE 삼성그룹섹터가중
    '108590': 'TREX 200', // TREX 200
    '108670': 'LX Hausiseu', // LX하우시스
    '108675': 'LX Hausiseu Pref', // LX하우시스우
    '109070': 'Juseongkopeoreisyeon', // 주성코퍼레이션
    '111110': 'Hojeonsileob', // 호전실업
    '111380': 'Dongingiyeon', // 동인기연
    '111770': 'Yeongweonmuyeog', // 영원무역
    '112610': 'Ssieseuwindeu', // 씨에스윈드
    '114090': 'GKL', // GKL
    '114100': 'RISE Guggocae 3 Nyeon', // RISE 국고채3년
    '114260': 'KODEX Guggocae 3 Nyeon', // KODEX 국고채3년
    '114460': 'ACE Guggocae 3 Nyeon', // ACE 국고채3년
    '114470': 'KIWOOM Guggocae 3 Nyeon', // KIWOOM 국고채3년
    '114800': 'KODEX Inbeoseu', // KODEX 인버스
    '114820': 'TIGER Treasury Bond 3 Nyeon', // TIGER 국채3년
    '117460': 'KODEX Energy Chemical', // KODEX 에너지화학
    '117580': 'Daeseong Energy', // 대성에너지
    '117680': 'KODEX Ceolgang', // KODEX 철강
    '117690': 'TIGER China Hangseng 30', // TIGER 차이나항셍30
    '117700': 'KODEX Engineering & Construction', // KODEX 건설
    '118000': 'Metakeeo', // 메타케어
    '119650': 'KC Koteurel', // KC코트렐
    '120030': 'Joseonseonjae', // 조선선재
    '120110': 'Kolon Indeo', // 코오롱인더
    '120115': 'Kolon Indeo Pref', // 코오롱인더우
    '122090': 'PLUS Koseupi 50', // PLUS 코스피50
    '122260': 'KIWOOM Tongancae 1 Nyeon', // KIWOOM 통안채1년
    '122630': 'KODEX Rebeoriji', // KODEX 레버리지
    '122900': 'AImakes Korea', // 아이마켓코리아
    '123310': 'TIGER Inbeoseu', // TIGER 인버스
    '123320': 'TIGER Rebeoriji', // TIGER 레버리지
    '123690': 'Korea Hwajangpum', // 한국화장품
    '123700': 'SJM', // SJM
    '123890': 'Korea Jasansintag', // 한국자산신탁
    '126560': 'Hyundai Pyuceones', // 현대퓨처넷
    '126720': 'Susanindeoseuteuri', // 수산인더스트리
    '128820': 'Daeseong Industries', // 대성산업
    '128940': 'Hanmi Pharmaceutical', // 한미약품
    '129260': 'Inteojiseu', // 인터지스
    '130660': 'Hanjeon Industries', // 한전산업
    '130680': 'TIGER Weonyuseonmul Enhanced (H)', // TIGER 원유선물Enhanced(H)
    '130730': 'KIWOOM Short-Term Jageum', // KIWOOM 단기자금
    '131890': 'ACE Samsung Geurubdongilgajung', // ACE 삼성그룹동일가중
    '132030': 'KODEX Goldeuseonmul (H)', // KODEX 골드선물(H)
    '133690': 'TIGER US Nasdaq 100', // TIGER 미국나스닥100
    '133820': 'Hwainbeseutil', // 화인베스틸
    '134380': 'Miweon Chemical', // 미원화학
    '134790': 'Sidijeu', // 시디즈
    '136340': 'RISE Junggi Blue-Chip Corporate Bond', // RISE 중기우량회사채
    '136490': 'Seonjin', // 선진
    '137310': 'Eseudi Bio Senseo', // 에스디바이오센서
    '137610': 'TIGER Nongsanmulseonmul Enhanced (H)', // TIGER 농산물선물Enhanced(H)
    '138040': 'Me REITs Financial Group', // 메리츠금융지주
    '138230': 'KIWOOM US Dalreoseonmul', // KIWOOM 미국달러선물
    '138490': 'Kolon ENP', // 코오롱ENP
    '138520': 'TIGER Samsung Geurub', // TIGER 삼성그룹
    '138530': 'TIGER LG Geurub Plus', // TIGER LG그룹플러스
    '138540': 'TIGER Hyundai Motor Geurub Plus', // TIGER 현대차그룹플러스
    '138910': 'KODEX Guriseonmul (H)', // KODEX 구리선물(H)
    '138920': 'KODEX Kongseonmul (H)', // KODEX 콩선물(H)
    '138930': 'BNK Financial Group', // BNK금융지주
    '139130': 'Im Financial Group', // iM금융지주
    '139220': 'TIGER 200 Engineering & Construction', // TIGER 200 건설
    '139230': 'TIGER 200 Heavy Industries', // TIGER 200 중공업
    '139240': 'TIGER 200 Ceolgangsojae', // TIGER 200 철강소재
    '139250': 'TIGER 200 Energy Chemical', // TIGER 200 에너지화학
    '139260': 'TIGER 200 IT', // TIGER 200 IT
    '139270': 'TIGER 200 Financial', // TIGER 200 금융
    '139280': 'TIGER Gyeonggibangeo', // TIGER 경기방어
    '139290': 'TIGER 200 Gyeonggisobinvestmente', // TIGER 200 경기소비재
    '139320': 'TIGER Geumeunseonmul (H)', // TIGER 금은선물(H)
    '139480': 'Imateu', // 이마트
    '139660': 'KIWOOM US Dalreoseonmulinbeoseu', // KIWOOM 미국달러선물인버스
    '139990': 'Ajuseutil', // 아주스틸
    '140570': 'RISE Export Ju', // RISE 수출주
    '140580': 'RISE Blue-Chip Eobjongdaepyoju', // RISE 우량업종대표주
    '140700': 'KODEX Insurance', // KODEX 보험
    '140710': 'KODEX Unsong', // KODEX 운송
    '140910': 'Ei REITs', // 에이리츠
    '140950': 'Paweo Koseupi 100', // 파워 코스피100
    '143210': 'Haenjeukopeoreisyeon', // 핸즈코퍼레이션
    '143850': 'TIGER US S&P500 Seonmul (H)', // TIGER 미국S&P500선물(H)
    '143860': 'TIGER Helseukeeo', // TIGER 헬스케어
    '144600': 'KODEX Eunseonmul (H)', // KODEX 은선물(H)
    '145210': 'Dainamigdinvestmentin', // 다이나믹디자인
    '145270': 'Keitab REITs', // 케이탑리츠
    '145670': 'ACE Inbeoseu', // ACE 인버스
    '145720': 'Dentium', // 덴티움
    '145850': 'TREX Peondeomental 200', // TREX 펀더멘탈 200
    '145990': 'Samyang Sa', // 삼양사
    '145995': 'Samyang Sa Pref', // 삼양사우
    '147970': 'TIGER Momenteom', // TIGER 모멘텀
    '148020': 'RISE 200', // RISE 200
    '148070': 'KIWOOM Guggocae 10 Nyeon', // KIWOOM 국고채10년
    '150460': 'TIGER China Sobitema', // TIGER 중국소비테마
    '152100': 'PLUS 200', // PLUS 200
    '152380': 'KODEX Treasury Bond Seonmul 10 Nyeon', // KODEX 국채선물10년
    '152500': 'ACE Rebeoriji', // ACE 레버리지
    '152550': 'Korea ANKOR Yujeon', // 한국ANKOR유전
    '152870': 'Paweo 200', // 파워 200
    '153130': 'KODEX Short-Term Bond', // KODEX 단기채권
    '153270': 'KIWOOM Koseupi 100', // KIWOOM 코스피100
    '155660': 'DSR', // DSR
    '156080': 'KODEX MSCI Korea', // KODEX MSCI Korea
    '157450': 'TIGER Short-Term Tongancae', // TIGER 단기통안채
    '157490': 'TIGER Software', // TIGER 소프트웨어
    '157500': 'TIGER Securities', // TIGER 증권
    '159800': 'Maiti Koseupi 100', // 마이티 코스피100
    '160580': 'TIGER Gurisilmul', // TIGER 구리실물
    '161000': 'Aegyeong Chemical', // 애경케미칼
    '161390': 'Korea Taieoaen Tech Nolroji', // 한국타이어앤테크놀로지
    '161510': 'PLUS High Dividend Ju', // PLUS 고배당주
    '161890': 'Korea Kolma', // 한국콜마
    '163560': 'Dongilgomubelteu', // 동일고무벨트
    '166400': 'TIGER 200 Covered Call OTM', // TIGER 200커버드콜OTM
    '167860': 'KIWOOM Guggocae 10 Nyeonrebeoriji', // KIWOOM 국고채10년레버리지
    '168580': 'ACE China Bonto CSI300', // ACE 중국본토CSI300
    '169950': 'KODEX China A50', // KODEX 차이나A50
    '170900': 'Dongaeseuti', // 동아에스티
    '174350': 'TIGER Roubol', // TIGER 로우볼
    '174360': 'RISE China Bonto Large Cap CSI100', // RISE 중국본토대형주CSI100
    '175330': 'JB Financial Group', // JB금융지주
    '176950': 'KODEX Treasury Bond Seonmul 10 Nyeoninbeoseu', // KODEX 국채선물10년인버스
    '178920': 'PI Ceomdansojae', // PI첨단소재
    '180640': 'Hanjin Kal', // 한진칼
    '18064K': 'Hanjin Kal Pref', // 한진칼우
    '181480': 'ACE US Real Estate REITs ( Synthetic H)', // ACE 미국부동산리츠(합성 H)
    '181710': 'NH N', // NHN
    '182480': 'TIGER US MSCI REITs ( Synthetic H)', // TIGER 미국MSCI리츠(합성 H)
    '182490': 'TIGER Short-Term Seonjin High Yield ( Synthetic H)', // TIGER 단기선진하이일드(합성 H)
    '183190': 'Aseasimenteu', // 아세아시멘트
    '183700': 'RISE Bond Mixed', // RISE 채권혼합
    '183710': 'RISE Jusig Mixed', // RISE 주식혼합
    '185680': 'KODEX US S&P Bio ( Synthetic )', // KODEX 미국S&P바이오(합성)
    '185750': 'Chong Kun Dang', // 종근당
    '189400': 'PLUS Global MSCI ( Synthetic H)', // PLUS 글로벌MSCI(합성 H)
    '190620': 'ACE Short-Term Tongancae', // ACE 단기통안채
    '192080': 'Deobeulyugeimjeu', // 더블유게임즈
    '192090': 'TIGER China CSI300', // TIGER 차이나CSI300
    '192400': 'Kuku Holdings', // 쿠쿠홀딩스
    '192650': 'Deurimteg', // 드림텍
    '192720': 'Paweo High Dividend Jeobyeondongseong', // 파워 고배당저변동성
    '192820': 'Koseumaegseu', // 코스맥스
    '194370': 'Jeieseukopeoreisyeon', // 제이에스코퍼레이션
    '195870': 'Haeseongdieseu', // 해성디에스
    '195920': 'TIGER Japan TOPIX ( Synthetic H)', // TIGER 일본TOPIX(합성 H)
    '195930': 'TIGER Yuroseutagseu 50 ( Synthetic H)', // TIGER 유로스탁스50(합성 H)
    '195970': 'PLUS Seonjingug MSCI ( Synthetic H)', // PLUS 선진국MSCI(합성 H)
    '195980': 'PLUS Sinheunggug MSCI ( Synthetic H)', // PLUS 신흥국MSCI(합성 H)
    '196030': 'ACE Japan TOPIX Rebeoriji (H)', // ACE 일본TOPIX레버리지(H)
    '196230': 'RISE Short-Term Tongancae', // RISE 단기통안채
    '200030': 'KODEX US S&P500 Industries Jae ( Synthetic )', // KODEX 미국S&P500산업재(합성)
    '200250': 'KIWOOM India Nifty 50 ( Synthetic )', // KIWOOM 인도Nifty50(합성)
    '200880': 'Seoyeonihwa', // 서연이화
    '203780': 'TIGER US Nasdaq Bio', // TIGER 미국나스닥바이오
    '204210': 'Seutaeseuem REITs', // 스타에스엠리츠
    '204320': 'HL Mando', // HL만도
    '204450': 'KODEX China H Rebeoriji (H)', // KODEX 차이나H레버리지(H)
    '204480': 'TIGER China CSI300 Rebeoriji ( Synthetic )', // TIGER 차이나CSI300레버리지(합성)
    '205720': 'ACE Japan TOPIX Inbeoseu ( Synthetic H)', // ACE 일본TOPIX인버스(합성 H)
    '207940': 'Samsung Biologics', // 삼성바이오로직스
    '210540': 'Diwaipaweo', // 디와이파워
    '210780': 'TIGER Koseupi High Dividend', // TIGER 코스피고배당
    '210980': 'SK Diaendi', // SK디앤디
    '211560': 'TIGER Dividend Growth', // TIGER 배당성장
    '211900': 'KODEX Korea Dividend Growth', // KODEX 코리아배당성장
    '213500': 'Hansol Paper', // 한솔제지
    '213610': 'KODEX Samsung Geurub Value', // KODEX 삼성그룹밸류
    '213630': 'PLUS US Dow Jones High Dividend Ju ( Synthetic H)', // PLUS 미국다우존스고배당주(합성 H)
    '214320': 'Inosyeon', // 이노션
    '214330': 'Kumho Eiciti', // 금호에이치티
    '214390': 'Gyeongbo Pharmaceutical', // 경보제약
    '214420': 'Tonimori', // 토니모리
    '214980': 'KODEX Short-Term Bond PLUS', // KODEX 단기채권PLUS
    '215620': 'HK S&P Korea Roubol', // HK S&P코리아로우볼
    '217590': 'Tiemssi', // 티엠씨
    '217770': 'TIGER Weonyuseonmulinbeoseu (H)', // TIGER 원유선물인버스(H)
    '217780': 'TIGER China CSI300 Inbeoseu ( Synthetic )', // TIGER 차이나CSI300인버스(합성)
    '218420': 'KODEX US S&P500 Energy ( Synthetic )', // KODEX 미국S&P500에너지(합성)
    '219390': 'RISE US S&P Weonyusaengsangieob ( Synthetic H)', // RISE 미국S&P원유생산기업(합성 H)
    '219480': 'KODEX US S&P500 Seonmul (H)', // KODEX 미국S&P500선물(H)
    '219900': 'ACE China Bonto CSI300 Rebeoriji ( Synthetic )', // ACE 중국본토CSI300레버리지(합성)
    '220130': 'SOL China Gangsogieob CSI500 ( Synthetic H)', // SOL 차이나강소기업CSI500(합성 H)
    '223190': 'KODEX 200 Value Jeobyeondong', // KODEX 200가치저변동
    '225030': 'TIGER US S&P500 Seonmulinbeoseu (H)', // TIGER 미국S&P500선물인버스(H)
    '225040': 'TIGER US S&P500 Rebeoriji ( Synthetic H)', // TIGER 미국S&P500레버리지(합성 H)
    '225050': 'TIGER Yuroseutagseurebeoriji ( Synthetic H)', // TIGER 유로스탁스레버리지(합성 H)
    '225060': 'TIGER Imeojingmakes MSCI Rebeoriji ( Synthetic H)', // TIGER 이머징마켓MSCI레버리지(합성 H)
    '225130': 'ACE Goldeuseonmul Rebeoriji ( Synthetic H)', // ACE 골드선물 레버리지(합성 H)
    '225800': 'KIWOOM US Dalreoseonmulrebeoriji', // KIWOOM 미국달러선물레버리지
    '226320': 'Isceuhanbul', // 잇츠한불
    '226380': 'ACE Fn Growth Sobijudoju', // ACE Fn성장소비주도주
    '226490': 'KODEX Koseupi', // KODEX 코스피
    '226980': 'KODEX 200 Small & Mid Cap', // KODEX 200 중소형
    '227540': 'TIGER 200 Helseukeeo', // TIGER 200 헬스케어
    '227550': 'TIGER 200 Industries Jae', // TIGER 200 산업재
    '227560': 'TIGER 200 Saenghwalsobinvestmente', // TIGER 200 생활소비재
    '227570': 'TIGER Blue-Chip Value', // TIGER 우량가치
    '227830': 'PLUS Koseupi', // PLUS 코스피
    '227840': 'Hyundai Kopeoreisyeon Holdings', // 현대코퍼레이션홀딩스
    '228790': 'TIGER Hwajangpum', // TIGER 화장품
    '228800': 'TIGER Yeohaengrejeo', // TIGER 여행레저
    '228810': 'TIGER Midieokeontenceu', // TIGER 미디어컨텐츠
    '228820': 'TIGER K Top 30', // TIGER KTOP30
    '229200': 'KODEX Koseudag 150', // KODEX 코스닥150
    '229640': 'LS Eko Energy', // LS에코에너지
    '229720': 'KODEX K Top 30', // KODEX KTOP30
    '230480': 'KIWOOM US Dalreoseonmulinbeoseu 2X', // KIWOOM 미국달러선물인버스2X
    '232080': 'TIGER Koseudag 150', // TIGER 코스닥150
    '233160': 'TIGER Koseudag 150 Rebeoriji', // TIGER 코스닥150 레버리지
    '233740': 'KODEX Koseudag 150 Rebeoriji', // KODEX 코스닥150레버리지
    '234080': 'JW Saengmyeonggwahag', // JW생명과학
    '234310': 'RISE V&S Selregteu Value', // RISE V&S셀렉트밸류
    '236350': 'TIGER India Nipeuti 50 Rebeoriji ( Synthetic )', // TIGER 인도니프티50레버리지(합성)
    '237350': 'KODEX Koseupi 100', // KODEX 코스피100
    '237370': 'KODEX Korea Dividend Growth Bond Mixed', // KODEX 코리아배당성장채권혼합
    '237440': 'TIGER Gyeonggibangeo Bond Mixed', // TIGER 경기방어채권혼합
    '238670': 'PLUS Seumateubeta Quality Bond Mixed', // PLUS 스마트베타Quality채권혼합
    '238720': 'ACE Japan Nikkei225 (H)', // ACE 일본Nikkei225(H)
    '239660': 'PLUS Blue-Chip Corporate Bond 50', // PLUS 우량회사채50
    '241180': 'TIGER Japan Nikei 225', // TIGER 일본니케이225
    '241390': 'RISE V&S Selregteu Value Bond Mixed', // RISE V&S셀렉트밸류채권혼합
    '241560': 'Doosan Babkaes', // 두산밥캣
    '241590': 'Hwaseungenteopeuraijeu', // 화승엔터프라이즈
    '243880': 'TIGER 200IT Rebeoriji', // TIGER 200IT레버리지
    '243890': 'TIGER 200 Energy Chemical Rebeoriji', // TIGER 200에너지화학레버리지
    '244580': 'KODEX Bio', // KODEX 바이오
    '244620': 'KODEX Momenteom Plus', // KODEX 모멘텀Plus
    '244660': 'KODEX Quality Plus', // KODEX 퀄리티Plus
    '244670': 'KODEX Value Plus', // KODEX 밸류Plus
    '244920': 'Ei Plus Asset', // 에이플러스에셋
    '245340': 'TIGER US Dow Jones 30', // TIGER 미국다우존스30
    '245350': 'TIGER Yuroseutagseu Dividend 30', // TIGER 유로스탁스배당30
    '245360': 'TIGER China HSCEI', // TIGER 차이나HSCEI
    '245710': 'ACE Vietnam VN30 ( Synthetic )', // ACE 베트남VN30(합성)
    '248070': 'Solruem', // 솔루엠
    '248170': 'Saempyo Foods', // 샘표식품
    '248270': 'TIGER S&P Global Helseukeeo ( Synthetic )', // TIGER S&P글로벌헬스케어(합성)
    '249420': 'Ildong Pharmaceutical', // 일동제약
    '250730': 'RISE China HSCEI (H)', // RISE 차이나HSCEI(H)
    '250780': 'TIGER Koseudag 150 Seonmulinbeoseu', // TIGER 코스닥150선물인버스
    '251270': 'Netmarble', // 넷마블
    '251340': 'KODEX Koseudag 150 Seonmulinbeoseu', // KODEX 코스닥150선물인버스
    '251350': 'KODEX MSCI Seonjingug', // KODEX MSCI선진국
    '251590': 'PLUS High Dividend Jeobyeondong 50', // PLUS 고배당저변동50
    '251600': 'PLUS High Dividend Ju Bond Mixed', // PLUS 고배당주채권혼합
    '252000': 'TIGER 200 Dongilgajung', // TIGER 200동일가중
    '252400': 'RISE 200 Seonmulrebeoriji', // RISE 200선물레버리지
    '252410': 'RISE 200 Seonmulinbeoseu', // RISE 200선물인버스
    '252420': 'RISE 200 Seonmulinbeoseu 2X', // RISE 200선물인버스2X
    '252650': 'KODEX 200 Dongilgajung', // KODEX 200동일가중
    '252670': 'KODEX 200 Seonmulinbeoseu 2X', // KODEX 200선물인버스2X
    '252710': 'TIGER 200 Seonmulinbeoseu 2X', // TIGER 200선물인버스2X
    '253150': 'PLUS 200 Seonmulrebeoriji', // PLUS 200선물레버리지
    '253160': 'PLUS 200 Seonmulinbeoseu 2X', // PLUS 200선물인버스2X
    '253230': 'KIWOOM 200 Seonmulinbeoseu 2X', // KIWOOM 200선물인버스2X
    '253240': 'KIWOOM 200 Seonmulinbeoseu', // KIWOOM 200선물인버스
    '253250': 'KIWOOM 200 Seonmulrebeoriji', // KIWOOM 200선물레버리지
    '253280': 'RISE Helseukeeo', // RISE 헬스케어
    '253290': 'RISE Helseukeeo Bond Mixed', // RISE 헬스케어채권혼합
    '256440': 'ACE MSCI India Nesia ( Synthetic )', // ACE MSCI인도네시아(합성)
    '256450': 'PLUS Simceoncainegseuteu ( Synthetic )', // PLUS 심천차이넥스트(합성)
    '256750': 'KODEX China Simceon Chinext ( Synthetic )', // KODEX 차이나심천ChiNext(합성)
    '259960': 'Keuraepeuton', // 크래프톤
    '261060': 'TIGER Koseudag 150IT', // TIGER 코스닥150IT
    '261070': 'TIGER Koseudag 150 Bio Tech', // TIGER 코스닥150바이오테크
    '261110': 'TIGER US Dalreoseonmulrebeoriji', // TIGER 미국달러선물레버리지
    '261120': 'TIGER US Dalreoseonmulinbeoseu 2X', // TIGER 미국달러선물인버스2X
    '261140': 'TIGER USeonju', // TIGER 우선주
    '261220': 'KODEX WTI Weonyuseonmul (H)', // KODEX WTI원유선물(H)
    '261240': 'KODEX US Dalreoseonmul', // KODEX 미국달러선물
    '261250': 'KODEX US Dalreoseonmulrebeoriji', // KODEX 미국달러선물레버리지
    '261260': 'KODEX US Dalreoseonmulinbeoseu 2X', // KODEX 미국달러선물인버스2X
    '261270': 'KODEX US Dalreoseonmulinbeoseu', // KODEX 미국달러선물인버스
    '261920': 'ACE MSCI Pilripin ( Synthetic )', // ACE MSCI필리핀(합성)
    '264900': 'Keuraunjegwa', // 크라운제과
    '26490K': 'Keuraunjegwa Pref', // 크라운제과우
    '265690': 'ACE Reosia MSCI ( Synthetic )', // ACE 러시아MSCI(합성)
    '266160': 'RISE High Dividend', // RISE 고배당
    '266360': 'KODEX K Kontenceu', // KODEX K콘텐츠
    '266370': 'KODEX IT', // KODEX IT
    '266390': 'KODEX Gyeonggisobinvestmente', // KODEX 경기소비재
    '266410': 'KODEX Pilsusobinvestmente', // KODEX 필수소비재
    '266420': 'KODEX Helseukeeo', // KODEX 헬스케어
    '266550': 'PLUS Junghyeongjujeobyeondong 50', // PLUS 중형주저변동50
    '267250': 'HD Hyundai', // HD현대
    '267260': 'HD Hyundai Ilregteurig', // HD현대일렉트릭
    '267270': 'HD Engineering & Construction Gigye', // HD건설기계
    '267290': 'Gyeongdongdosigaseu', // 경동도시가스
    '267440': 'RISE US Long-Term Treasury Bond Seonmul (H)', // RISE 미국장기국채선물(H)
    '267450': 'RISE US Long-Term Treasury Bond Seonmulinbeoseu (H)', // RISE 미국장기국채선물인버스(H)
    '267490': 'RISE US Long-Term Treasury Bond Seonmulrebeoriji ( Synthetic H)', // RISE 미국장기국채선물레버리지(합성 H)
    '267770': 'TIGER 200 Seonmulrebeoriji', // TIGER 200선물레버리지
    '267850': 'Asiana IDT', // 아시아나IDT
    '268280': 'Miweoneseussi', // 미원에스씨
    '269370': 'TIGER S&P Global Inpeura ( Synthetic )', // TIGER S&P글로벌인프라(합성)
    '269420': 'KODEX S&P Global Inpeura ( Synthetic )', // KODEX S&P글로벌인프라(합성)
    '269530': 'PLUS S&P Global Inpeura', // PLUS S&P글로벌인프라
    '269540': 'PLUS US S&P500 (H)', // PLUS 미국S&P500(H)
    '270800': 'RISE KQ High Dividend', // RISE KQ고배당
    '270810': 'RISE Koseudag 150', // RISE 코스닥150
    '271050': 'KODEX WTI Weonyuseonmulinbeoseu (H)', // KODEX WTI원유선물인버스(H)
    '271060': 'KODEX 3 Daenongsanmulseonmul (H)', // KODEX 3대농산물선물(H)
    '271560': 'Orion', // 오리온
    '271940': 'Iljinhaisolruseu', // 일진하이솔루스
    '271980': 'Jeil Pharmaceutical', // 제일약품
    '272210': 'Hanwha Siseutem', // 한화시스템
    '272450': 'Jineeo', // 진에어
    '272550': 'Samyang Paekijing', // 삼양패키징
    '272560': 'RISE Short-Term Guggongcae Active', // RISE 단기국공채액티브
    '272570': 'RISE Jung Long-Term Guggongcae Active', // RISE 중장기국공채액티브
    '272580': 'TIGER Short-Term Bond Active', // TIGER 단기채권액티브
    '272910': 'ACE Jung Long-Term Guggongcae Active', // ACE 중장기국공채액티브
    '273130': 'KODEX Jonghab Bond (AA- Isang ) Active', // KODEX 종합채권(AA-이상)액티브
    '273140': 'KODEX Short-Term Byeondonggeumribu Bond Active', // KODEX 단기변동금리부채권액티브
    '275280': 'KODEX Momenteomju', // KODEX 모멘텀주
    '275290': 'KODEX Value Ju', // KODEX 가치주
    '275300': 'KODEX Blue-Chip Ju', // KODEX 우량주
    '275750': 'RISE Koseudag 150 Seonmulinbeoseu', // RISE 코스닥150선물인버스
    '275980': 'TIGER Global 4 Ca Industries Hyeogsingisul ( Synthetic H)', // TIGER 글로벌4차산업혁신기술(합성 H)
    '276000': 'TIGER Global Jaweonsaengsangieob ( Synthetic H)', // TIGER 글로벌자원생산기업(합성 H)
    '276650': 'RISE Global Tech Nolroji ( Synthetic H)', // RISE 글로벌테크놀로지(합성 H)
    '276970': 'KODEX US S&P500 Dividend Gwijog Covered Call ( Synthetic H', // KODEX 미국S&P500배당귀족커버드콜(합성 H
    '276990': 'KODEX Global Robos ( Synthetic )', // KODEX 글로벌로봇(합성)
    '277540': 'ACE Asia TOP50', // ACE 아시아TOP50
    '277630': 'TIGER Koseupi', // TIGER 코스피
    '277640': 'TIGER Koseupi Large Cap', // TIGER 코스피대형주
    '277650': 'TIGER Koseupijunghyeongju', // TIGER 코스피중형주
    '278240': 'RISE Koseudag 150 Seonmulrebeoriji', // RISE 코스닥150선물레버리지
    '278470': 'Eipial', // 에이피알
    '278530': 'KODEX 200TR', // KODEX 200TR
    '278540': 'KODEX MSCI Korea TR', // KODEX MSCI Korea TR
    '278620': 'PLUS Short-Term Bond Active', // PLUS 단기채권액티브
    '279530': 'KODEX High Dividend Ju', // KODEX 고배당주
    '279540': 'KODEX Coesobyeondongseong', // KODEX 최소변동성
    '279570': 'Keibaengkeu', // 케이뱅크
    '280320': 'ACE US IT Inteones ( Synthetic H)', // ACE 미국IT인터넷(합성 H)
    '280360': 'Lotte Welpudeu', // 롯데웰푸드
    '280920': 'PLUS Judoeobjong', // PLUS 주도업종
    '280930': 'KODEX US Reosel 2000 (H)', // KODEX 미국러셀2000(H)
    '280940': 'KODEX Goldeuseonmulinbeoseu (H)', // KODEX 골드선물인버스(H)
    '281820': 'Keissiteg', // 케이씨텍
    '281990': 'RISE Small & Mid Cap High Dividend', // RISE 중소형고배당
    '282000': 'RISE Guggocae 3 Nyeonseonmulinbeoseu', // RISE 국고채3년선물인버스
    '282330': 'BGF Riteil', // BGF리테일
    '283580': 'KODEX China CSI300', // KODEX 차이나CSI300
    '284430': 'KODEX 200 US Cae Mixed', // KODEX 200미국채혼합
    '284740': 'Kukuhomsiseu', // 쿠쿠홈시스
    '284980': 'RISE 200 Financial', // RISE 200금융
    '285130': 'SK Chemicals', // SK케미칼
    '28513K': 'SK Chemical Pref', // SK케미칼우
    '285690': 'FOCUS ESG Rideoseu', // FOCUS ESG리더스
    '286940': 'Lotte Inobeiteu', // 롯데이노베이트
    '287180': 'PLUS US Nasdaq Tech', // PLUS 미국나스닥테크
    '289040': 'KODEX MSCI KOREA ESG Yunibeoseol', // KODEX MSCI KOREA ESG유니버설
    '289250': 'TIGER MSCI KOREA ESG Yunibeoseol', // TIGER MSCI KOREA ESG유니버설
    '289260': 'TIGER MSCI KOREA ESG Rideoseu', // TIGER MSCI KOREA ESG리더스
    '289480': 'TIGER 200 Covered Call', // TIGER 200커버드콜
    '289670': 'PLUS Treasury Bond Seonmul 10 Nyeon', // PLUS 국채선물10년
    '290080': 'RISE 200 High Dividend Covered Call ATM', // RISE 200고배당커버드콜ATM
    '290130': 'RISE ESG Sahoecaegimtuja', // RISE ESG사회책임투자
    '291130': 'ACE MSCI Megsiko ( Synthetic )', // ACE MSCI멕시코(합성)
    '291620': 'KIWOOM Koseudag 150 Seonmulinbeoseu', // KIWOOM 코스닥150선물인버스
    '291630': 'KIWOOM Koseudag 150 Seonmulrebeoriji', // KIWOOM 코스닥150선물레버리지
    '291680': 'RISE China H Seonmulinbeoseu (H)', // RISE 차이나H선물인버스(H)
    '291890': 'KODEX MSCI EM Seonmul (H)', // KODEX MSCI EM선물(H)
    '292050': 'RISE KRX 300', // RISE KRX300
    '292150': 'TIGER Korea Top 10', // TIGER 코리아TOP10
    '292160': 'TIGER KRX 300', // TIGER KRX300
    '292190': 'KODEX KRX 300', // KODEX KRX300
    '292500': 'SOL KRX 300', // SOL KRX300
    '292560': 'TIGER Japan Enseonmul', // TIGER 일본엔선물
    '292770': 'KODEX Treasury Bond Seonmul 3 Nyeoninbeoseu', // KODEX 국채선물3년인버스
    '293180': 'HANARO 200', // HANARO 200
    '293480': 'Hana Pharmaceutical', // 하나제약
    '293940': 'Shinhan Alpa REITs', // 신한알파리츠
    '294400': 'KIWOOM 200TR', // KIWOOM 200TR
    '294870': 'HDC Hyundai Industries Gaebal', // HDC현대산업개발
    '295000': 'RISE Treasury Bond Seonmul 10 Nyeon', // RISE 국채선물10년
    '295020': 'RISE Treasury Bond Seonmul 10 Nyeoninbeoseu', // RISE 국채선물10년인버스
    '295040': 'SOL 200TR', // SOL 200TR
    '298000': 'Hyosung Chemical', // 효성화학
    '298020': 'Hyosung Tiaenssi', // 효성티앤씨
    '298040': 'Hyosung Heavy Industries', // 효성중공업
    '298050': 'HS Hyosung Ceomdansojae', // HS효성첨단소재
    '298340': 'PLUS Treasury Bond Seonmul 3 Nyeon', // PLUS 국채선물3년
    '298690': 'Eeobusan', // 에어부산
    '298770': 'KODEX Korea Daeman IT Peurimieo', // KODEX 한국대만IT프리미어
    '300610': 'TIGER K Geim', // TIGER K게임
    '300640': 'RISE Geimtema', // RISE 게임테마
    '300720': 'Hanilsimenteu', // 한일시멘트
    '300950': 'KODEX Geim Industries', // KODEX 게임산업
    '301400': 'PLUS Koseudag 150', // PLUS 코스닥150
    '301410': 'PLUS Koseudag 150 Seonmulinbeoseu', // PLUS 코스닥150선물인버스
    '302190': 'TIGER Jung Long-Term Treasury Bond', // TIGER 중장기국채
    '302440': 'SK Bioscience', // SK바이오사이언스
    '302450': 'RISE Koseupi', // RISE 코스피
    '304660': 'KODEX US 30 Nyeon Treasury Bond Ulteuraseonmul (H)', // KODEX 미국30년국채울트라선물(H)
    '304670': 'KODEX US 30 Nyeon Treasury Bond Ulteuraseonmulinbeoseu (H)', // KODEX 미국30년국채울트라선물인버스(H)
    '304760': 'HANARO KRX 300', // HANARO KRX300
    '304770': 'HANARO Koseudag 150', // HANARO 코스닥150
    '304780': 'HANARO 200 Seonmulrebeoriji', // HANARO 200선물레버리지
    '304940': 'KODEX US Nasdaq 100 Seonmul (H)', // KODEX 미국나스닥100선물(H)
    '305050': 'ACE Koseupi', // ACE 코스피
    '305080': 'TIGER US Cae 10 Nyeonseonmul', // TIGER 미국채10년선물
    '305540': 'TIGER 2 Cajeonjitema', // TIGER 2차전지테마
    '305720': 'KODEX 2 Cajeonji Industries', // KODEX 2차전지산업
    '306200': 'Seajegang', // 세아제강
    '306520': 'HANARO 200 Seonmulinbeoseu', // HANARO 200선물인버스
    '306530': 'HANARO Koseudag 150 Seonmulrebeoriji', // HANARO 코스닥150선물레버리지
    '306950': 'KODEX KRX 300 Rebeoriji', // KODEX KRX300레버리지
    '307510': 'TIGER Medical Gigi', // TIGER 의료기기
    '307520': 'TIGER Holdings', // TIGER 지주회사
    '307950': 'Hyundai Otoebeo', // 현대오토에버
    '308170': 'Ssitial Mobility', // 씨티알모빌리티
    '308620': 'KODEX US 10 Nyeon Treasury Bond Seonmul', // KODEX 미국10년국채선물
    '309230': 'ACE US Widemoat Dongilgajung', // ACE 미국WideMoat동일가중
    '310080': 'RISE China MSCI China (H)', // RISE 중국MSCI China(H)
    '310960': 'TIGER 200TR', // TIGER 200TR
    '310970': 'TIGER MSCI Korea TR', // TIGER MSCI Korea TR
    '314250': 'KODEX US Big Tech 10 (H)', // KODEX 미국빅테크10(H)
    '314700': 'HANARO Nongeobyungboghab Industries', // HANARO 농업융복합산업
    '315270': 'TIGER 200 Keomyunikeisyeonseobiseu', // TIGER 200커뮤니케이션서비스
    '315930': 'KODEX Top5PlusTR', // KODEX Top5PlusTR
    '315960': 'RISE Daehyeong High Dividend 10TR', // RISE 대형고배당10TR
    '316140': 'Woori Financial Group', // 우리금융지주
    '316300': 'ACE Singgaporeu REITs', // ACE 싱가포르리츠
    '316670': 'KIWOOM Koseudag 150', // KIWOOM 코스닥150
    '317400': 'Jaieseuaendi', // 자이에스앤디
    '317450': 'Myeongin Pharmaceutical', // 명인제약
    '319640': 'TIGER Goldeuseonmul (H)', // TIGER 골드선물(H)
    '321410': 'KODEX Meolti Asset Haiinkeom (H)', // KODEX 멀티에셋하이인컴(H)
    '322000': 'HD Hyundai Energy Solrusyeon', // HD현대에너지솔루션
    '322400': 'HANARO E Keomeoseu', // HANARO e커머스
    '322410': 'HANARO K High Dividend', // HANARO K고배당
    '323410': 'Kakao Baengkeu', // 카카오뱅크
    '325010': 'KODEX Growth Ju', // KODEX 성장주
    '325020': 'KODEX Dividend Value', // KODEX 배당가치
    '326030': 'SK Bio Pam', // SK바이오팜
    '326230': 'RISE Naesuju Plus', // RISE 내수주플러스
    '326240': 'RISE IT Plus', // RISE IT플러스
    '328370': 'PLUS Koseupi TR', // PLUS 코스피TR
    '329180': 'HD Hyundai Heavy Industries', // HD현대중공업
    '329200': 'TIGER REITs Real Estate Infrastructure', // TIGER 리츠부동산인프라
    '329650': 'KODEX TRF3070', // KODEX TRF3070
    '329660': 'KODEX TRF5050', // KODEX TRF5050
    '329670': 'KODEX TRF7030', // KODEX TRF7030
    '329750': 'TIGER US Dalreo Short-Term Bond Active', // TIGER 미국달러단기채권액티브
    '330590': 'Lotte REITs', // 롯데리츠
    '332500': 'ACE 200TR', // ACE 200TR
    '332610': 'PLUS US Short-Term Corporate Bond (AAA~A)', // PLUS 미국단기회사채(AAA~A)
    '332620': 'PLUS US Long-Term Blue-Chip Corporate Bond', // PLUS 미국장기우량회사채
    '332930': 'HANARO 200TR', // HANARO 200TR
    '332940': 'HANARO MSCI Korea TR', // HANARO MSCI Korea TR
    '334690': 'RISE Palradyumseonmul (H)', // RISE 팔라듐선물(H)
    '334700': 'RISE Palradyumseonmulinbeoseu (H)', // RISE 팔라듐선물인버스(H)
    '334890': 'Ijiseu Value Plus REITs', // 이지스밸류플러스리츠
    '336160': 'RISE Financial Cae Active', // RISE 금융채액티브
    '336260': 'Doosan Pyueolsel', // 두산퓨얼셀
    '33626K': 'Doosan Pyueolsel 1st Pref', // 두산퓨얼셀1우
    '33626L': 'Doosan Pyueolsel 2nd Pref B', // 두산퓨얼셀2우B
    '336370': 'Solruseuceomdansojae', // 솔루스첨단소재
    '33637K': 'Solruseuceomdansojae 1st Pref', // 솔루스첨단소재1우
    '33637L': 'Solruseuceomdansojae 2nd Pref B', // 솔루스첨단소재2우B
    '337120': 'KODEX Meoltipaegteo', // KODEX 멀티팩터
    '337140': 'KODEX Koseupi Large Cap', // KODEX 코스피대형주
    '337150': 'KODEX 200exTOP', // KODEX 200exTOP
    '337160': 'KODEX 200ESG', // KODEX 200ESG
    '338100': 'NH Peuraim REITs', // NH프라임리츠
    '339770': 'Gyoconepeuaenbi', // 교촌에프앤비
    '341850': 'TIGER REITs Real Estate Infrastructure Bond', // TIGER 리츠부동산인프라채권
    '344820': 'KCC Geulraseu', // KCC글라스
    '348950': 'Jeial Global REITs', // 제이알글로벌리츠
    '350520': 'Ijiseurejideonseu REITs', // 이지스레지던스리츠
    '352540': 'KODEX Japan Real Estate REITs (H)', // KODEX 일본부동산리츠(H)
    '352560': 'KODEX US Real Estate REITs (H)', // KODEX 미국부동산리츠(H)
    '352820': 'Haibeu', // 하이브
    '353200': 'Daedeog Electronics', // 대덕전자
    '35320K': 'Daedeog Electronics 1st Pref', // 대덕전자1우
    '354240': 'RISE US Fixed Dividend USeonsecurities', // RISE 미국고정배당우선증권
    '354350': 'HANARO Global Reogsyeori S&P ( Synthetic )', // HANARO 글로벌럭셔리S&P(합성)
    '354500': 'ACE Koseudag 150', // ACE 코스닥150
    '356540': 'ACE Jonghab Bond (AA- Isang ) Active', // ACE 종합채권(AA-이상)액티브
    '357120': 'Koramkoraipeuinpeura REITs', // 코람코라이프인프라리츠
    '357250': 'Mirae Asset Maebseu REITs', // 미래에셋맵스리츠
    '357430': 'Maseuteonpeurimieo REITs', // 마스턴프리미어리츠
    '357870': 'TIGER CD Geumrituja KIS ( Synthetic )', // TIGER CD금리투자KIS(합성)
    '359210': 'KODEX Koseupi TR', // KODEX 코스피TR
    '360140': 'KODEX 200 Rongkoseudag 150 Syosseonmul', // KODEX 200롱코스닥150숏선물
    '360150': 'KODEX Koseudag 150 Rongkoseupi 200 Syosseonmul', // KODEX 코스닥150롱코스피200숏선물
    '360200': 'ACE US S&P500', // ACE 미국S&P500
    '360750': 'TIGER US S&P500', // TIGER 미국S&P500
    '361580': 'RISE 200TR', // RISE 200TR
    '361610': 'SK IE Technology', // SK아이이테크놀로지
    '363280': 'Tiwai Holdings', // 티와이홀딩스
    '36328K': 'Tiwai Holdings Pref', // 티와이홀딩스우
    '363510': 'SOL KIS Short-Term Tongancae', // SOL KIS단기통안채
    '363570': 'KODEX Long-Term Jonghab Bond (AA- Isang ) Active', // KODEX 장기종합채권(AA-이상)액티브
    '363580': 'KODEX 200IT TR', // KODEX 200IT TR
    '364690': 'KODEX Hyeogsingisultema Active', // KODEX 혁신기술테마액티브
    '364960': 'TIGER BBIG', // TIGER BBIG
    '364970': 'TIGER Bio Top 10', // TIGER 바이오TOP10
    '364980': 'TIGER 2 Cajeonji Top 10', // TIGER 2차전지TOP10
    '364990': 'TIGER Geim Top 10', // TIGER 게임TOP10
    '365000': 'TIGER Inteones Top 10', // TIGER 인터넷TOP10
    '365040': 'TIGER AI Korea Geuroseu Active', // TIGER AI코리아그로스액티브
    '365550': 'ESR Kendalseukweeo REITs', // ESR켄달스퀘어리츠
    '365780': 'ACE Guggocae 10 Nyeon', // ACE 국고채10년
    '367380': 'ACE US Nasdaq 100', // ACE 미국나스닥100
    '367740': 'HANARO Fn5G Industries', // HANARO Fn5G산업
    '367760': 'RISE Neteuweokeuinpeura', // RISE 네트워크인프라
    '367770': 'RISE Susogyeongjetema', // RISE 수소경제테마
    '368190': 'HANARO Fn K- Nyudildijiteol Plus', // HANARO Fn K-뉴딜디지털플러스
    '368590': 'RISE US Nasdaq 100', // RISE 미국나스닥100
    '368680': 'KODEX K- Nyudildijiteol Plus', // KODEX K-뉴딜디지털플러스
    '371150': 'RISE China Hangseng Tech', // RISE 차이나항셍테크
    '371160': 'TIGER China Hangseng Tech', // TIGER 차이나항셍테크
    '371450': 'TIGER Global Keulraudeukeompyuting INDXX', // TIGER 글로벌클라우드컴퓨팅INDXX
    '371460': 'TIGER China Electric Ca SOL ACTIVE', // TIGER 차이나전기차SOLACTIVE
    '371470': 'TIGER China Bio Tech SOL ACTIVE', // TIGER 차이나바이오테크SOLACTIVE
    '371870': 'ACE China Hangseng Tech', // ACE 차이나항셍테크
    '372330': 'KODEX China Hangseng Tech', // KODEX 차이나항셍테크
    '372910': 'Hankeomraipeukeeo', // 한컴라이프케어
    '373220': 'LG Energy Solution', // LG에너지솔루션
    '373490': 'KODEX Korea Hyeogsin Growth Active', // KODEX 코리아혁신성장액티브
    '373790': 'KIWOOM US Bangeo Dividend Growth Nasdaq', // KIWOOM 미국방어배당성장나스닥
    '375270': 'RISE Global Deiteosenteo REITs ( Synthetic )', // RISE 글로벌데이터센터리츠(합성)
    '375500': 'DL Iaenssi', // DL이앤씨
    '37550K': 'DL Iaenssi Pref', // DL이앤씨우
    '37550L': 'DL Iaenssi 2 U ( Jeonhwan )', // DL이앤씨2우(전환)
    '375760': 'HANARO Tansohyoyulgeurinnyudil', // HANARO 탄소효율그린뉴딜
    '375770': 'KODEX Tansohyoyulgeurinnyudil', // KODEX 탄소효율그린뉴딜
    '376410': 'TIGER Tansohyoyulgeurinnyudil', // TIGER 탄소효율그린뉴딜
    '377190': 'Diaendipeulraespom REITs', // 디앤디플랫폼리츠
    '377300': 'Kakao Pei', // 카카오페이
    '377740': 'Bio Noteu', // 바이오노트
    '377990': 'TIGER Fn Sinjaesaeng Energy', // TIGER Fn신재생에너지
    '378850': 'Hwaseungalaenei', // 화승알앤에이
    '379780': 'RISE US S&P500', // RISE 미국S&P500
    '379790': 'RISE Yuroseutagseu 50 (H)', // RISE 유로스탁스50(H)
    '379800': 'KODEX US S&P500', // KODEX 미국S&P500
    '379810': 'KODEX US Nasdaq 100', // KODEX 미국나스닥100
    '380340': 'ACE Korea AI Tech Haegsim Industries', // ACE 코리아AI테크핵심산업
    '381170': 'TIGER US Tech Top 10 INDXX', // TIGER 미국테크TOP10 INDXX
    '381180': 'TIGER US Pilradelpia Semiconductor Nasdaq', // TIGER 미국필라델피아반도체나스닥
    '381560': 'HANARO Fn Electric & Susoca', // HANARO Fn전기&수소차
    '381570': 'HANARO Fn Cinhwangyeong Energy', // HANARO Fn친환경에너지
    '381970': 'Keika', // 케이카
    '383220': 'F&F', // F&F
    '383800': 'LX Holdings', // LX홀딩스
    '38380K': 'LX Holdings 1st Pref', // LX홀딩스1우
    '385510': 'KODEX Sinjaesaeng Energy Active', // KODEX 신재생에너지액티브
    '385520': 'KODEX Jayuljuhaeng Active', // KODEX 자율주행액티브
    '385540': 'RISE Jonghab Bond (A- Isang ) Active', // RISE 종합채권(A-이상)액티브
    '385550': 'RISE Short-Term Bond Alpa Active', // RISE 단기채권알파액티브
    '385560': 'RISE KIS Guggocae 30 Nyeon Enhanced', // RISE KIS국고채30년Enhanced
    '385590': 'ACE ESG Active', // ACE ESG액티브
    '385600': 'ACE 2 Cajeonji & Cinhwangyeongca Active', // ACE 2차전지&친환경차액티브
    '385710': 'TIME K Innovation Active', // TIME K이노베이션액티브
    '385720': 'TIME Koseupi Active', // TIME 코스피액티브
    '387270': 'TIGER Global Innovation Active', // TIGER 글로벌이노베이션액티브
    '387280': 'TIGER Pyuceo Mobility Active', // TIGER 퓨처모빌리티액티브
    '388280': 'RISE K Enteo & Yeohaengrejeo', // RISE K엔터&여행레저
    '388420': 'RISE Bimemori Semiconductor Active', // RISE 비메모리반도체액티브
    '390390': 'KODEX US Semiconductor', // KODEX 미국반도체
    '390400': 'KODEX US Seumateu Mobility S&P', // KODEX 미국스마트모빌리티S&P
    '391600': 'ACE US Cinhwangyeonggeurintema', // ACE 미국친환경그린테마
    '391670': 'HK Beseuteuilrebeun Active', // HK 베스트일레븐액티브
    '394350': 'KIWOOM Global Pyuceo Mobility', // KIWOOM 글로벌퓨처모빌리티
    '394660': 'TIGER Global Jayuljuhaeng & Electric Ca SOL ACTIVE', // TIGER 글로벌자율주행&전기차SOLACTIVE
    '394670': 'TIGER Global Rityum &2 Cajeonji SOL ACTIVE ( Synthetic )', // TIGER 글로벌리튬&2차전지SOLACTIVE(합성)
    '395150': 'KODEX Webtun & Deurama', // KODEX 웹툰&드라마
    '395160': 'KODEX AI Semiconductor', // KODEX AI반도체
    '395170': 'KODEX Top10 Dongilgajung', // KODEX Top10동일가중
    '395270': 'HANARO Fn K- Semiconductor', // HANARO Fn K-반도체
    '395280': 'HANARO Fn K- Geim', // HANARO Fn K-게임
    '395290': 'HANARO Fn K-POP& Midieo', // HANARO Fn K-POP&미디어
    '395400': 'SK REITs', // SK리츠
    '395750': 'PLUS ESG Value Ju Active', // PLUS ESG가치주액티브
    '395760': 'PLUS ESG Growth Ju Active', // PLUS ESG성장주액티브
    '396500': 'TIGER Semiconductor Top 10', // TIGER 반도체TOP10
    '396510': 'TIGER China Keulrin Energy SOL ACTIVE', // TIGER 차이나클린에너지SOLACTIVE
    '396520': 'TIGER China Semiconductor FACTSET', // TIGER 차이나반도체FACTSET
    '396690': 'Mirae Asset Global REITs', // 미래에셋글로벌리츠
    '397420': 'RISE Treasury Bond Seonmul 5 Nyeoncujong', // RISE 국채선물5년추종
    '399110': 'SOL US S&P500 ESG', // SOL 미국S&P500ESG
    '399580': 'RISE Global Keulrin Energy', // RISE 글로벌클린에너지
    '400570': 'KODEX Europe Tansobaeculgweonseonmul ICE (H)', // KODEX 유럽탄소배출권선물ICE(H)
    '400580': 'SOL Europe Tansobaeculgweonseonmul S&P (H)', // SOL 유럽탄소배출권선물S&P(H)
    '400590': 'SOL Global Tansobaeculgweonseonmul ICE ( Synthetic )', // SOL 글로벌탄소배출권선물ICE(합성)
    '400760': 'NH Olweon REITs', // NH올원리츠
    '400970': 'TIGER Fn Metabeoseu', // TIGER Fn메타버스
    '401170': 'RISE Metabeoseu', // RISE 메타버스
    '401470': 'KODEX Metabeoseu Active', // KODEX 메타버스액티브
    '401590': 'HANARO Global Tansobaeculgweonseonmul ICE ( Synthetic )', // HANARO 글로벌탄소배출권선물ICE(합성)
    '402340': 'SK Seukweeo', // SK스퀘어
    '402460': 'HANARO Fn K- Metabeoseu MZ', // HANARO Fn K-메타버스MZ
    '402970': 'ACE US Dividend Dow Jones', // ACE 미국배당다우존스
    '403550': 'Ssoka', // 쏘카
    '403790': 'Maidaseu Koseupi Active', // 마이다스 코스피액티브
    '404120': 'TIME K Sinjaesaeng Energy Active', // TIME K신재생에너지액티브
    '404260': 'KODEX Gihubyeonhwasolrusyeon', // KODEX 기후변화솔루션
    '404540': 'TIGER KRX Gihubyeonhwasolrusyeon', // TIGER KRX기후변화솔루션
    '404650': 'SOL KRX Gihubyeonhwasolrusyeon', // SOL KRX기후변화솔루션
    '404990': 'Shinhan Seobutiendi REITs', // 신한서부티엔디리츠
    '407300': 'HANARO Fn Golpeutema', // HANARO Fn골프테마
    '407310': 'HANARO 200 Top 10', // HANARO 200 TOP10
    '407820': 'Asset Plus Korea Peulraespom Active', // 에셋플러스 코리아플랫폼액티브
    '407830': 'Asset Plus Global Peulraespom Active', // 에셋플러스 글로벌플랫폼액티브
    '409810': 'KODEX US Nasdaq 100 Seonmulinbeoseu (H)', // KODEX 미국나스닥100선물인버스(H)
    '409820': 'KODEX US Nasdaq 100 Rebeoriji ( Synthetic H)', // KODEX 미국나스닥100레버리지(합성 H)
    '410870': 'TIME K Keolceo Active', // TIME K컬처액티브
    '411060': 'ACE KRX Physical Gold', // ACE KRX금현물
    '411420': 'KODEX US Nasdaq AI Tech Active', // KODEX 미국나스닥AI테크액티브
    '411540': 'SOL 200 Top10', // SOL 200 Top10
    '411860': 'KIWOOM Dogil DAX', // KIWOOM 독일DAX
    '412560': 'TIGER BBIG Rebeoriji', // TIGER BBIG레버리지
    '412570': 'TIGER 2 Cajeonji Top 10 Rebeoriji', // TIGER 2차전지TOP10레버리지
    '412770': 'TIGER Global AI Peulraespom Active', // TIGER 글로벌AI플랫폼액티브
    '413220': 'SOL China Taeyanggwang CSI ( Synthetic )', // SOL 차이나태양광CSI(합성)
    '413930': 'WON AI ESG Active', // WON AI ESG액티브
    '414270': 'ACE Global Jayuljuhaeng Active', // ACE 글로벌자율주행액티브
    '414780': 'TIGER China Gwacangpan STAR50 ( Synthetic )', // TIGER 차이나과창판STAR50(합성)
    '415340': 'KODEX China Gwacangpan STAR50 ( Synthetic )', // KODEX 차이나과창판STAR50(합성)
    '415640': 'KB Balhaeinpeura', // KB발해인프라
    '415760': 'SOL China Yugseong Industries Active ( Synthetic )', // SOL 차이나육성산업액티브(합성)
    '415920': 'PLUS Global Hyitoryu & Jeonryagjaweonsaengsangieob', // PLUS 글로벌희토류&전략자원생산기업
    '416090': 'ACE China Gwacangpan STAR50', // ACE 중국과창판STAR50
    '417310': 'Koramkodeoweon REITs', // 코람코더원리츠
    '417450': 'RISE Global Susogyeongje', // RISE 글로벌수소경제
    '417630': 'TIGER KE DI Hyeogsingieob ESG30', // TIGER KEDI혁신기업ESG30
    '418660': 'TIGER US Nasdaq 100 Rebeoriji ( Synthetic )', // TIGER 미국나스닥100레버리지(합성)
    '418670': 'TIGER Global AI Saibeoboan', // TIGER 글로벌AI사이버보안
    '419420': 'KODEX US Keulrin Energy Nasdaq', // KODEX 미국클린에너지나스닥
    '419430': 'KODEX China 2 Cajeonji MSCI ( Synthetic )', // KODEX 차이나2차전지MSCI(합성)
    '419650': 'PLUS Global Suso & Casedaeyeonryojeonji', // PLUS 글로벌수소&차세대연료전지
    '419890': 'KIWOOM Short-Term Bond ESG Active', // KIWOOM 단기채권ESG액티브
    '421320': 'PLUS Uju AIr &UAM', // PLUS 우주항공&UAM
    '422260': 'VITA MZ Sobi Active', // VITA MZ소비액티브
    '422420': 'RISE 2 Cajeonji Active', // RISE 2차전지액티브
    '423160': 'KODEX KOFR Geumri Active ( Synthetic )', // KODEX KOFR금리액티브(합성)
    '423170': 'SOL Global AI Semiconductor Tabpig Active', // SOL 글로벌AI반도체탑픽액티브
    '423920': 'TIGER US Pilradelpia Semiconductor Rebeoriji ( Synthetic', // TIGER 미국필라델피아반도체레버리지(합성
    '424460': 'HANARO Global Weoteo MSCI ( Synthetic )', // HANARO 글로벌워터MSCI(합성)
    '426020': 'TIME US S&P500 Active', // TIME 미국S&P500액티브
    '426030': 'TIME US Nasdaq 100 Active', // TIME 미국나스닥100액티브
    '426150': 'WON Korea Mingugguggocae Active', // WON 대한민국국고채액티브
    '426330': 'KIWOOM US ETF Industries STOXX', // KIWOOM 미국ETF산업STOXX
    '427120': 'RISE AI Peulraespom', // RISE AI플랫폼
    '428510': 'KODEX China AI Tech Active', // KODEX 차이나AI테크액티브
    '428560': 'KODEX US ETF Industries Top10 Indxx', // KODEX 미국ETF산업Top10 Indxx
    '429000': 'TIGER US S&P500 Dividend Gwijog', // TIGER 미국S&P500배당귀족
    '429010': 'TIGER US Nasdaq Negseuteu 100', // TIGER 미국나스닥넥스트100
    '429740': 'PLUS K REITs', // PLUS K리츠
    '429760': 'PLUS US S&P500', // PLUS 미국S&P500
    '429980': 'SOL Korea Hyeong Global Electric Ca &2 Cajeonji Active', // SOL 한국형글로벌전기차&2차전지액티브
    '430500': 'KIWOOM Mulgacae KIS', // KIWOOM 물가채KIS
    '432320': 'KB Seuta REITs', // KB스타리츠
    '432600': 'RISE Treasury Bond Seonmul 3 Nyeon', // RISE 국채선물3년
    '432840': 'HANARO US S&P500', // HANARO 미국S&P500
    '433220': 'Asset Plus Global Daejangjangi Active', // 에셋플러스 글로벌대장장이액티브
    '433250': 'UNICORN R&D Active', // UNICORN R&D 액티브
    '433330': 'SOL US S&P500', // SOL 미국S&P500
    '433500': 'ACE Nuclear Power Top 10', // ACE 원자력TOP10
    '433880': 'PLUS TDF 2060 Active', // PLUS TDF2060액티브
    '433970': 'KODEX TDF 2030 Active', // KODEX TDF2030액티브
    '433980': 'KODEX TDF 2040 Active', // KODEX TDF2040액티브
    '434060': 'KODEX TDF 2050 Active', // KODEX TDF2050액티브
    '434730': 'HANARO Nuclear Power Iselect', // HANARO 원자력iSelect
    '434960': 'D AI SHIN343 K200', // DAISHIN343 K200
    '435040': 'ACE Global Beuraendeu Top 10', // ACE 글로벌브랜드TOP10
    '435420': 'TIGER US Nasdaq 100 Bond Mixed Fn', // TIGER 미국나스닥100채권혼합Fn
    '435530': 'KIWOOM TDF 2030 Active', // KIWOOM TDF2030액티브
    '435540': 'KIWOOM TDF 2040 Active', // KIWOOM TDF2040액티브
    '435550': 'KIWOOM TDF 2050 Active', // KIWOOM TDF2050액티브
    '436140': 'SOL Jonghab Bond (AA- Isang ) Active', // SOL 종합채권(AA-이상)액티브
    '437070': 'KODEX Asiadalreo Bond ESG Plus Active', // KODEX 아시아달러채권ESG플러스액티브
    '437080': 'KODEX US Jonghab Bond ESG Active (H)', // KODEX 미국종합채권ESG액티브(H)
    '437350': 'RISE US Short-Term Tujadeunggeub Corporate Bond Active', // RISE 미국단기투자등급회사채액티브
    '437370': 'RISE Global Nongeobgyeongje', // RISE 글로벌농업경제
    '438080': 'ACE US S&P500 US Cae Mixed 50 Active', // ACE 미국S&P500미국채혼합50액티브
    '438100': 'ACE US Nasdaq 100 US Cae Mixed 50 Active', // ACE 미국나스닥100미국채혼합50액티브
    '438320': 'TIGER China Hangseng Tech Rebeoriji ( Synthetic H)', // TIGER 차이나항셍테크레버리지(합성 H)
    '438330': 'TIGER Blue-Chip Corporate Bond Active', // TIGER 우량회사채액티브
    '438560': 'SOL Guggocae 3 Nyeon', // SOL 국고채3년
    '438570': 'SOL Guggocae 10 Nyeon', // SOL 국고채10년
    '438740': 'Maidaseu Small & Mid Cap Active', // 마이다스 중소형액티브
    '438900': 'HANARO Fn K- Pudeu', // HANARO Fn K-푸드
    '439260': 'Korea Joseon', // 대한조선
    '439860': 'KODEX ESG Jonghab Bond (A- Isang ) Active', // KODEX ESG종합채권(A-이상)액티브
    '439870': 'KODEX Guggocae 30 Nyeon Active', // KODEX 국고채30년액티브
    '440340': 'TIGER Global Meolti Asset TIF Active', // TIGER 글로벌멀티에셋TIF액티브
    '440640': 'ACE Short-Term Bond Alpa Active', // ACE 단기채권알파액티브
    '440650': 'ACE US Dalreo Short-Term Bond Active', // ACE 미국달러단기채권액티브
    '440910': 'WON US Uju AIr Defense', // WON 미국우주항공방산
    '441330': 'KIWOOM China A50 Keonegteu MSCI', // KIWOOM 차이나A50커넥트MSCI
    '441540': 'HANARO Fn Joseonhaeun', // HANARO Fn조선해운
    '441640': 'KODEX US Dividend Covered Call Active', // KODEX 미국배당커버드콜액티브
    '441680': 'TIGER US Nasdaq 100 Covered Call ( Synthetic )', // TIGER 미국나스닥100커버드콜(합성)
    '441800': 'TIME Korea Plus Dividend Active', // TIME Korea플러스배당액티브
    '442090': 'Asset Plus Korea Daejangjangi Active', // 에셋플러스 코리아대장장이액티브
    '442260': 'Maiti Dainamigkweonteu Active', // 마이티 다이나믹퀀트액티브
    '442320': 'RISE Global Nuclear Power', // RISE 글로벌원자력
    '442550': 'RISE TDF 2030 Active', // RISE TDF2030액티브
    '442560': 'RISE TDF 2040 Active', // RISE TDF2040액티브
    '442570': 'RISE TDF 2050 Active', // RISE TDF2050액티브
    '442580': 'PLUS Global HBM Semiconductor', // PLUS 글로벌HBM반도체
    '443060': 'HD Hyundai Marinsolrusyeon', // HD현대마린솔루션
    '444200': 'SOL Korea Mega Tech Active', // SOL 코리아메가테크액티브
    '444490': 'WON US S&P500', // WON 미국S&P500
    '445150': 'KODEX Cinhwangyeongjoseonhaeun Active', // KODEX 친환경조선해운액티브
    '445290': 'KODEX Robos Active', // KODEX 로봇액티브
    '445690': 'BNK Juju Value Active', // BNK 주주가치액티브
    '445910': 'TIGER MKF Dividend Gwijog', // TIGER MKF배당귀족
    '446070': 'Yunideubiti Plus', // 유니드비티플러스
    '446690': 'KODEX Asia AI Semiconductor Exchina Active', // KODEX 아시아AI반도체exChina액티브
    '446700': 'RISE Battery Risaikeulring', // RISE 배터리 리사이클링
    '446720': 'SOL US Dividend Dow Jones', // SOL 미국배당다우존스
    '446770': 'ACE Global Semiconductor TOP4 Plus', // ACE 글로벌반도체TOP4 Plus
    '447430': 'ACE Jujuhwanweon Value Ju Active', // ACE 주주환원가치주액티브
    '447620': 'SOL US TOP5 Bond Mixed 50', // SOL 미국TOP5채권혼합50
    '447660': 'PLUS Aepeul Bond Mixed', // PLUS 애플채권혼합
    '447770': 'TIGER Tesla Bond Mixed Fn', // TIGER 테슬라채권혼합Fn
    '448100': 'WON 200', // WON 200
    '448290': 'TIGER US S&P500 (H)', // TIGER 미국S&P500(H)
    '448300': 'TIGER US Nasdaq 100 (H)', // TIGER 미국나스닥100(H)
    '448330': 'KODEX Samsung Electronics Bond Mixed', // KODEX 삼성전자채권혼합
    '448490': 'HANARO 32-10 Guggocae Active', // HANARO 32-10 국고채액티브
    '448540': 'ACE NVI DI A Bond Mixed', // ACE 엔비디아채권혼합
    '448570': 'FOCUS AI Korea Active', // FOCUS AI코리아액티브
    '448630': 'RISE Samsung Geurub Top3 Bond Mixed', // RISE 삼성그룹Top3채권혼합
    '448730': 'Samsung FN REITs', // 삼성FN리츠
    '449170': 'TIGER KOFR Geumri Active ( Synthetic )', // TIGER KOFR금리액티브(합성)
    '449180': 'KODEX US S&P500 (H)', // KODEX 미국S&P500(H)
    '449190': 'KODEX US Nasdaq 100 (H)', // KODEX 미국나스닥100(H)
    '449450': 'PLUS K Defense', // PLUS K방산
    '449580': 'RISE Tesla Aepeulamajon Bond Mixed', // RISE 테슬라애플아마존채권혼합
    '449680': 'TIGER Hanjung Electric Ca ( Synthetic )', // TIGER 한중전기차(합성)
    '449690': 'TIGER Hanjung Semiconductor ( Synthetic )', // TIGER 한중반도체(합성)
    '449770': 'KIWOOM US S&P500', // KIWOOM 미국S&P500
    '449780': 'KIWOOM US S&P500 (H)', // KIWOOM 미국S&P500(H)
    '450080': 'Ekopeuromeoti', // 에코프로머티
    '450180': 'KODEX Hanjung Electric Ca ( Synthetic )', // KODEX 한중전기차(합성)
    '450190': 'KODEX Hanjung Semiconductor ( Synthetic )', // KODEX 한중반도체(합성)
    '450910': 'SOL Koseudag 150', // SOL 코스닥150
    '451000': 'PLUS Jonghab Bond (AA- Isang ) Active', // PLUS 종합채권(AA-이상)액티브
    '451060': '1Q 200 Active', // 1Q 200액티브
    '451150': 'Asset Plus Global Yeongeiji Active', // 에셋플러스 글로벌영에이지액티브
    '451530': 'TIGER Guggocae 30 Nyeonseuteurib Active', // TIGER 국고채30년스트립액티브
    '451540': 'TIGER Jonghab Bond (AA- Isang ) Active', // TIGER 종합채권(AA-이상)액티브
    '451600': 'PLUS Guggocae 30 Nyeon Active', // PLUS 국고채30년액티브
    '451670': 'RISE Treasury Bond 30 Nyeonrebeoriji ( Synthetic )', // RISE 국채30년레버리지(합성)
    '451800': 'Hanwha REITs', // 한화리츠
    '452250': 'ACE US 30 Nyeon Treasury Bond Seonmulrebeoriji ( Synthetic H)', // ACE 미국30년국채선물레버리지(합성 H)
    '452260': 'Hanwha Gaelreoria', // 한화갤러리아
    '45226K': 'Hanwha Gaelreoria Pref', // 한화갤러리아우
    '452360': 'SOL US Dividend Dow Jones (H)', // SOL 미국배당다우존스(H)
    '452440': 'VITA Value Alpa Active', // VITA 밸류알파액티브
    '453010': 'PLUS KOFR Geumri', // PLUS KOFR금리
    '453060': 'HANARO KOFR Geumri Active ( Synthetic )', // HANARO KOFR금리액티브(합성)
    '453080': 'KIWOOM US Nasdaq 100 (H)', // KIWOOM 미국나스닥100(H)
    '453330': 'RISE US S&P500 (H)', // RISE 미국S&P500(H)
    '453340': 'Hyundai Geurinpudeu', // 현대그린푸드
    '453630': 'KODEX US S&P500 Pilsusobinvestmente', // KODEX 미국S&P500필수소비재
    '453640': 'KODEX US S&P500 Helseukeeo', // KODEX 미국S&P500헬스케어
    '453650': 'KODEX US S&P500 Financial', // KODEX 미국S&P500금융
    '453660': 'KODEX US S&P500 Gyeonggisobinvestmente', // KODEX 미국S&P500경기소비재
    '453810': 'KODEX India Nifty 50', // KODEX 인도Nifty50
    '453820': 'KODEX India Nifty 50 Rebeoriji ( Synthetic )', // KODEX 인도Nifty50레버리지(합성)
    '453850': 'ACE US 30 Nyeon Treasury Bond Active (H)', // ACE 미국30년국채액티브(H)
    '453870': 'TIGER India Nipeuti 50', // TIGER 인도니프티50
    '453950': 'TIGER TSMC Paundeuri Value Cein', // TIGER TSMC파운드리밸류체인
    '454180': 'KIWOOM China Naesusobi TOP CSI', // KIWOOM 차이나내수소비TOP CSI
    '454320': 'HANARO CAPEX Seolbituja Iselect', // HANARO CAPEX설비투자iSelect
    '454780': 'KIWOOM Jonghab Bond (AA- Isang ) Active', // KIWOOM 종합채권(AA-이상)액티브
    '454910': 'Doosan Robotigseu', // 두산로보틱스
    '455030': 'KODEX US Dalreo SOFR Geumri Active ( Synthetic )', // KODEX 미국달러SOFR금리액티브(합성)
    '455660': 'ACE US High Yield Active (H)', // ACE 미국하이일드액티브(H)
    '455850': 'SOL AI Semiconductor Sobujang', // SOL AI반도체소부장
    '455860': 'SOL 2 Cajeonjisobujang Fn', // SOL 2차전지소부장Fn
    '455890': 'RISE Money Market Active', // RISE 머니마켓액티브
    '455960': 'RISE US Dalreo SOFR Geumri Active ( Synthetic )', // RISE 미국달러SOFR금리액티브(합성)
    '456040': 'OCI', // OCI
    '456200': 'PLUS US Dalreo SOFR Geumri Active ( Synthetic )', // PLUS 미국달러SOFR금리액티브(합성)
    '456250': 'KODEX Europe Myeongpum Top 10 STOXX', // KODEX 유럽명품TOP10 STOXX
    '456600': 'TIME Global AI Ingongjineung Active', // TIME 글로벌AI인공지능액티브
    '456610': 'TIGER US Dalreo SOFR Geumri Active ( Synthetic )', // TIGER 미국달러SOFR금리액티브(합성)
    '456680': 'TIGER China Electric Carebeoriji ( Synthetic )', // TIGER 차이나전기차레버리지(합성)
    '456880': 'ACE US Dalreo SOFR Geumri ( Synthetic )', // ACE 미국달러SOFR금리(합성)
    '457190': 'Isuseupesyeoltikemikeol', // 이수스페셜티케미컬
    '457480': 'ACE Tesla Value Cein Active', // ACE 테슬라밸류체인액티브
    '457690': 'KODEX 33-06 Guggocae Active', // KODEX 33-06 국고채액티브
    '457700': 'KODEX 53-09 Guggocae Active', // KODEX 53-09 국고채액티브
    '457930': 'BNK Miraejeonryaggisul Active', // BNK 미래전략기술액티브
    '457990': 'PLUS Taeyanggwang &ESS', // PLUS 태양광&ESS
    '458030': 'WON Guggongcae Money Market Active', // WON 국공채머니마켓액티브
    '458210': 'KIWOOM CD Geumri Active ( Synthetic )', // KIWOOM CD금리액티브(합성)
    '458250': 'TIGER US 30 Nyeon Treasury Bond Seuteurib Active ( Synthetic H)', // TIGER 미국30년국채스트립액티브(합성 H)
    '458260': 'TIGER US Tujadeunggeub Corporate Bond Active (H)', // TIGER 미국투자등급회사채액티브(H)
    '458730': 'TIGER US Dividend Dow Jones', // TIGER 미국배당다우존스
    '458750': 'TIGER US Dividend Dow Jones Target Covered Call 1 Ho', // TIGER 미국배당다우존스타겟커버드콜1호
    '458760': 'TIGER US Dividend Dow Jones Target Covered Call 2 Ho', // TIGER 미국배당다우존스타겟커버드콜2호
    '459560': 'KODEX Tesla Value Cein Factset', // KODEX 테슬라밸류체인FactSet
    '459580': 'KODEX CD Geumri Active ( Synthetic )', // KODEX CD금리액티브(합성)
    '459750': 'RISE Global Jusigbunsan Active', // RISE 글로벌주식분산액티브
    '459790': 'KIWOOM US Growth Companies 30 Active', // KIWOOM 미국성장기업30액티브
    '460270': 'KIWOOM US Dalreo SOFR Geumri Active ( Synthetic )', // KIWOOM 미국달러SOFR금리액티브(합성)
    '460280': 'KIWOOM Fn Yu Electronics Hyeogsingisul', // KIWOOM Fn유전자혁신기술
    '460660': 'RISE US S&P Dividend King', // RISE 미국S&P배당킹
    '460850': 'Dongkuk Ssiem', // 동국씨엠
    '460860': 'Dongkuk Jegang', // 동국제강
    '460960': 'ACE Global Inkeom Top 10', // ACE 글로벌인컴TOP10
    '461270': 'ACE 26-06 Corporate Bond (AA- Isang ) Active', // ACE 26-06 회사채(AA-이상)액티브
    '461340': 'HANARO Global Saengseonghyeong AI Active', // HANARO 글로벌생성형AI액티브
    '461450': 'KODEX Koseudag Global', // KODEX 코스닥글로벌
    '461460': 'PLUS Guggocae 10 Nyeon Active', // PLUS 국고채10년액티브
    '461490': 'RISE Global Jasanbaebun Active', // RISE 글로벌자산배분액티브
    '461500': 'HANARO Jonghab Bond (AA- Isang ) Active', // HANARO 종합채권(AA-이상)액티브
    '461580': 'TIGER Koseudag Global', // TIGER 코스닥글로벌
    '461600': 'SOL US 30 Nyeon Treasury Bond Active (H)', // SOL 미국30년국채액티브(H)
    '461900': 'PLUS US Tech Top 10', // PLUS 미국테크TOP10
    '461910': 'PLUS US Tech Top 10 Rebeoriji ( Synthetic )', // PLUS 미국테크TOP10레버리지(합성)
    '461950': 'KODEX 2 Cajeonjihaegsimsojae 10', // KODEX 2차전지핵심소재10
    '462010': 'TIGER 2 Cajeonjisojae Fn', // TIGER 2차전지소재Fn
    '462330': 'KODEX 2 Cajeonji Industries Rebeoriji', // KODEX 2차전지산업레버리지
    '462340': 'Asset Plus Global Dainamigsinieo Active', // 에셋플러스 글로벌다이나믹시니어액티브
    '462520': 'Joseonnaehwa', // 조선내화
    '462870': 'Sipeuteueob', // 시프트업
    '462900': 'Koact Bio Helseukeeo Active', // KoAct 바이오헬스케어액티브
    '463050': 'TIME K Bio Active', // TIME K바이오액티브
    '463250': 'TIGER K Defense & Uju', // TIGER K방산&우주
    '463290': '1Q Short-Term Financial Cae Active', // 1Q 단기금융채액티브
    '463300': 'RISE China Bonto CSI300', // RISE 중국본토CSI300
    '463640': 'KODEX US S&P500 Yutilriti', // KODEX 미국S&P500유틸리티
    '463680': 'KODEX US S&P500 Tech Nolroji', // KODEX 미국S&P500테크놀로지
    '463690': 'KODEX US S&P500 Keomyunikeisyeon', // KODEX 미국S&P500커뮤니케이션
    '464240': 'KIWOOM 26-09 Corporate Bond (AA- Isang ) Active', // KIWOOM 26-09회사채(AA-이상)액티브
    '464310': 'TIGER Global AI & Robotigseu INDXX', // TIGER 글로벌AI&로보틱스 INDXX
    '464470': 'PLUS US Cae 30 Nyeon Active', // PLUS 미국채30년액티브
    '464600': 'SOL Motor Sobujang Fn', // SOL 자동차소부장Fn
    '464610': 'SOL Medical Gigisobujang Fn', // SOL 의료기기소부장Fn
    '464920': 'PLUS Japan Semiconductor Sobujang', // PLUS 일본반도체소부장
    '464930': 'TIGER Global Hyeogsinbeulrucib Top 10', // TIGER 글로벌혁신블루칩TOP10
    '465330': 'RISE 2 Cajeonji Top 10', // RISE 2차전지TOP10
    '465350': 'RISE 2 Cajeonji Top 10 Inbeoseu ( Synthetic )', // RISE 2차전지TOP10인버스(합성)
    '465580': 'ACE US Big Tech TOP7 Plus', // ACE 미국빅테크TOP7 Plus
    '465610': 'ACE US Big Tech TOP7 Plus Rebeoriji ( Synthetic )', // ACE 미국빅테크TOP7 Plus레버리지(합성)
    '465620': 'ACE US Big Tech TOP7 Plus Inbeoseu ( Synthetic )', // ACE 미국빅테크TOP7 Plus인버스(합성)
    '465660': 'TIGER Japan Semiconductor FACTSET', // TIGER 일본반도체FACTSET
    '465670': 'TIGER US Kaesikau 100', // TIGER 미국캐시카우100
    '465770': 'STX Geurinrojiseu', // STX그린로지스
    '465780': 'Maiti 26-09 Teugsucae (AAA) Active', // 마이티 26-09 특수채(AAA)액티브
    '466810': 'BNK 2 Cajeonjiyanggeugjae', // BNK 2차전지양극재
    '466920': 'SOL Joseon Top 3 Plus', // SOL 조선TOP3플러스
    '466930': 'SOL Motor Top 3 Plus', // SOL 자동차TOP3플러스
    '466940': 'TIGER Bank High Dividend Plus Top 10', // TIGER 은행고배당플러스TOP10
    '466950': 'TIGER Global AI Active', // TIGER 글로벌AI액티브
    '468370': 'KODEX Ishares US Inpeulreisyeon Treasury Bond Active', // KODEX iShares미국인플레이션국채액티브
    '468380': 'KODEX Ishares US High Yield Active', // KODEX iShares미국하이일드액티브
    '468630': 'KODEX Ishares US Tujadeunggeub Corporate Bond Active', // KODEX iShares미국투자등급회사채액티브
    '469050': 'RISE US Semiconductor NYSE (H)', // RISE 미국반도체NYSE(H)
    '469060': 'RISE US Semiconductor NYSE', // RISE 미국반도체NYSE
    '469070': 'RISE AI & Robos', // RISE AI&로봇
    '469150': 'ACE AI Semiconductor Top 3 +', // ACE AI반도체TOP3+
    '469160': 'ACE Japan Semiconductor', // ACE 일본반도체
    '469170': 'ACE POSCO Geurub Focus', // ACE 포스코그룹포커스
    '469530': 'RISE US Dalreoseonmulinbeoseu', // RISE 미국달러선물인버스
    '469790': 'KIWOOM K- Tech Top 10', // KIWOOM K-테크TOP10
    '469830': 'SOL Co Short-Term Bond Active', // SOL 초단기채권액티브
    '470310': 'UNICORN Saengseonghyeong AI Gangsogieob Active', // UNICORN 생성형AI강소기업액티브
    '471040': 'Koact Global AI & Robos Active', // KoAct 글로벌AI&로봇액티브
    '471230': 'KODEX Guggocae 10 Nyeon Active', // KODEX 국고채10년액티브
    '471460': 'KIWOOM Guggocae 30 Nyeon Active', // KIWOOM 국고채30년액티브
    '471760': 'TIGER AI Semiconductor Haegsimgongjeong', // TIGER AI반도체핵심공정
    '471780': 'TIGER Korea Tech Active', // TIGER 코리아테크액티브
    '471990': 'KODEX AI Semiconductor Haegsimjangbi', // KODEX AI반도체핵심장비
    '472150': 'TIGER Dividend Covered Call Active', // TIGER 배당커버드콜액티브
    '472160': 'TIGER US Tech Top 10 INDXX (H)', // TIGER 미국테크TOP10 INDXX(H)
    '472170': 'TIGER US Tech Top 10 Bond Mixed', // TIGER 미국테크TOP10채권혼합
    '472720': 'TRUSTON Juju Value Active', // TRUSTON 주주가치액티브
    '472830': 'RISE US 30 Nyeon Treasury Bond Covered Call ( Synthetic )', // RISE 미국30년국채커버드콜(합성)
    '472840': 'ITF 200', // ITF 200
    '472870': 'RISE US 30 Nyeon Treasury Bond Enhwanocul ( Synthetic H)', // RISE 미국30년국채엔화노출(합성 H)
    '472920': 'HK Jonghab Bond (AA- Isang ) Active', // HK 종합채권(AA-이상)액티브
    '473290': 'KODEX 26-12 Corporate Bond (AA- Isang ) Active', // KODEX 26-12 회사채(AA-이상)액티브
    '473330': 'SOL US 30 Nyeon Treasury Bond Covered Call ( Synthetic )', // SOL 미국30년국채커버드콜(합성)
    '473440': 'ACE 11 Weolmanginvestmentdongyeonjang Corporate Bond AA- Isang Active', // ACE 11월만기자동연장회사채AA-이상액티브
    '473460': 'KODEX US Seohaggaemi', // KODEX 미국서학개미
    '473490': 'KIWOOM Global AI Semiconductor', // KIWOOM 글로벌AI반도체
    '473590': 'ACE US Jusigbeseuteuselreo', // ACE 미국주식베스트셀러
    '473640': 'HANARO Global Geumcaegulgieob', // HANARO 글로벌금채굴기업
    '474220': 'TIGER US Tech Top 10 Target Covered Call', // TIGER 미국테크TOP10타겟커버드콜
    '474390': 'SOL Guggocae 30 Nyeon Active', // SOL 국고채30년액티브
    '474590': 'WON Semiconductor Value Cein Active', // WON 반도체밸류체인액티브
    '474800': 'KIWOOM US Weonyu Energy Gieob', // KIWOOM 미국원유에너지기업
    '474920': 'Asset Plus China Ildeunggieob Focus 10 Active', // 에셋플러스 차이나일등기업포커스10액티브
    '475050': 'ACE KPOP Focus', // ACE KPOP포커스
    '475070': 'Koact Global Cinhwangyeongjeonryeoginpeura Active', // KoAct 글로벌친환경전력인프라액티브
    '475080': 'KODEX Tesla Covered Call Bond Mixed Active', // KODEX 테슬라커버드콜채권혼합액티브
    '475150': 'SK eternix', // SK이터닉스
    '475260': 'ACE 2 Weolmanginvestmentdongyeonjang Corporate Bond AA- Isang Active', // ACE 2월만기자동연장회사채AA-이상액티브
    '475270': 'ACE 5 Weolmanginvestmentdongyeonjang Corporate Bond AA- Isang Active', // ACE 5월만기자동연장회사채AA-이상액티브
    '475280': 'ACE 8 Weolmanginvestmentdongyeonjang Corporate Bond AA- Isang Active', // ACE 8월만기자동연장회사채AA-이상액티브
    '475300': 'SOL Semiconductor Jeongongjeong', // SOL 반도체전공정
    '475310': 'SOL Semiconductor Hugongjeong', // SOL 반도체후공정
    '475350': 'RISE Beokeusyeopoteupolrio Top 10', // RISE 버크셔포트폴리오TOP10
    '475380': 'RISE Global Rieoltiinkeom', // RISE 글로벌리얼티인컴
    '475560': 'Deobon Korea', // 더본코리아
    '475630': 'TIGER CD1 Nyeongeumri Active ( Synthetic )', // TIGER CD1년금리액티브(합성)
    '475720': 'RISE 200 Wikeulri Covered Call', // RISE 200위클리커버드콜
    '476000': 'UNICORN Poseuteu IPO Active', // UNICORN 포스트IPO액티브
    '476030': 'SOL US Nasdaq 100', // SOL 미국나스닥100
    '476070': 'KODEX Global Bimanciryoje Top 2 Plus', // KODEX 글로벌비만치료제TOP2 Plus
    '476260': 'HANARO Semiconductor Haegsimgongjeongjudoju', // HANARO 반도체핵심공정주도주
    '476310': 'RISE Global Biman Industries Top 2 +', // RISE 글로벌비만산업TOP2+
    '476450': 'KIWOOM Money Market Active', // KIWOOM 머니마켓액티브
    '476550': 'TIGER US 30 Nyeon Treasury Bond Covered Call Active (H)', // TIGER 미국30년국채커버드콜액티브(H)
    '476690': 'TIGER Global Bimanciryoje Top 2 Plus', // TIGER 글로벌비만치료제TOP2Plus
    '476750': 'ACE US 30 Nyeon Treasury Bond Enhwanocul Active (H)', // ACE 미국30년국채엔화노출액티브(H)
    '476760': 'ACE US 30 Nyeon Treasury Bond Active', // ACE 미국30년국채액티브
    '476800': 'KODEX Korea Real Estate REITs Inpeura', // KODEX 한국부동산리츠인프라
    '476850': 'Koact Dividend Growth Active', // KoAct 배당성장액티브
    '477050': 'PLUS Money Market Active', // PLUS 머니마켓액티브
    '477080': 'RISE CD Geumri Active ( Synthetic )', // RISE CD금리액티브(합성)
    '477490': 'Asset Plus Global Ildeunggieob Focus 10 Active', // 에셋플러스 글로벌일등기업포커스10액티브
    '477730': 'KODEX India Tatageurub', // KODEX 인도타타그룹
    '478150': 'TIME Global Uju Tech & Defense Active', // TIME 글로벌우주테크&방산액티브
    '479080': '1Q Money Market Active', // 1Q 머니마켓액티브
    '479520': 'RISE KOFR Geumri Active ( Synthetic )', // RISE KOFR금리액티브(합성)
    '479620': 'SOL US AI Semiconductor Cibmeikeo', // SOL 미국AI반도체칩메이커
    '479730': 'TIGER India Bilrieonkeonsyumeo', // TIGER 인도빌리언컨슈머
    '479850': 'HANARO K- Byuti', // HANARO K-뷰티
    '480020': 'ACE US Big Tech 7+ Daily Target Covered Call ( Synthetic', // ACE 미국빅테크7+데일리타겟커버드콜(합성
    '480030': 'ACE US 500 Daily Target Covered Call ( Synthetic )', // ACE 미국500데일리타겟커버드콜(합성)
    '480040': 'ACE US Semiconductor Daily Target Covered Call ( Synthetic )', // ACE 미국반도체데일리타겟커버드콜(합성)
    '480260': 'TIGER 27-04 Corporate Bond (A+ Isang ) Active', // TIGER 27-04회사채(A+이상)액티브
    '480310': 'TIGER Global Ondibaiseu AI', // TIGER 글로벌온디바이스AI
    '480370': 'Ssikeisolrusyeon', // 씨케이솔루션
    '480460': 'WON Korea Real Estate Top 3 Plus', // WON 한국부동산TOP3플러스
    '481050': 'KODEX CD1 Nyeongeumri Plus Active ( Synthetic )', // KODEX CD1년금리플러스액티브(합성)
    '481060': 'KODEX US 30 Nyeon Treasury Bond Target Covered Call ( Synthetic H)', // KODEX 미국30년국채타겟커버드콜(합성 H)
    '481180': 'SOL US AI Software', // SOL 미국AI소프트웨어
    '481190': 'SOL US Tech Top 10', // SOL 미국테크TOP10
    '481340': 'RISE US 30 Nyeon Treasury Bond Active', // RISE 미국30년국채액티브
    '481430': 'RISE Guggocae 10 Nyeon Active', // RISE 국고채10년액티브
    '481850': 'Shinhan Global Active REITs', // 신한글로벌액티브리츠
    '482030': 'Koact Semiconductor &2 Cajeonjihaegsimsojae Active', // KoAct 반도체&2차전지핵심소재액티브
    '482730': 'TIGER US S&P500 Target Daily Covered Call', // TIGER 미국S&P500타겟데일리커버드콜
    '483020': 'KIWOOM Medical AI', // KIWOOM 의료AI
    '483030': 'KIWOOM US Beulrogbeoseuteo Bio Tech Yi Pharmaceutical +', // KIWOOM 미국블록버스터바이오테크의약품+
    '483240': 'TIGER US Nasdaq 100ETF Seonmul', // TIGER 미국나스닥100ETF선물
    '483280': 'KODEX US AI Tech Top 10 Target Covered Call', // KODEX 미국AI테크TOP10타겟커버드콜
    '483290': 'KODEX US Dividend Dow Jones Target Covered Call', // KODEX 미국배당다우존스타겟커버드콜
    '483320': 'ACE NVI DI A Value Cein Active', // ACE 엔비디아밸류체인액티브
    '483330': 'ACE Maikeurosopeuteu Value Cein Active', // ACE 마이크로소프트밸류체인액티브
    '483340': 'ACE Gugeul Value Cein Active', // ACE 구글밸류체인액티브
    '483420': 'ACE Aepeul Value Cein Active', // ACE 애플밸류체인액티브
    '483570': 'KCGI US S&P500 Top 10', // KCGI 미국S&P500 TOP10
    '483650': 'Dalba Global', // 달바글로벌
    '484790': 'KODEX US 30 Nyeon Treasury Bond Active (H)', // KODEX 미국30년국채액티브(H)
    '484870': 'Emaenssisolrusyeon', // 엠앤씨솔루션
    '484880': 'SOL Financial Group Plus High Dividend', // SOL 금융지주플러스고배당
    '484890': 'SOL Money Market Active', // SOL 머니마켓액티브
    '485540': 'KODEX US AI Tech Top 10', // KODEX 미국AI테크TOP10
    '485690': 'RISE US AI Value Cein Top 3 Plus', // RISE 미국AI밸류체인TOP3Plus
    '485810': 'TIME Global Bio Active', // TIME 글로벌바이오액티브
    '486240': 'D AI SHIN343 AI Semiconductor & Inpeura Active', // DAISHIN343 AI반도체&인프라액티브
    '486290': 'TIGER US Nasdaq 100 Target Daily Covered Call', // TIGER 미국나스닥100타겟데일리커버드콜
    '486450': 'SOL US AI Jeonryeoginpeura', // SOL 미국AI전력인프라
    '486830': 'HANARO Money Market Active', // HANARO 머니마켓액티브
    '487130': 'Koact AI Inpeura Active', // KoAct AI인프라액티브
    '487230': 'KODEX US AI Jeonryeoghaegsiminpeura', // KODEX 미국AI전력핵심인프라
    '487240': 'KODEX AI Jeonryeoghaegsimseolbi', // KODEX AI전력핵심설비
    '487340': 'ACE Money Market Active', // ACE 머니마켓액티브
    '487570': 'HS Hyosung', // HS효성
    '487750': 'BNK Ondibaiseu AI', // BNK 온디바이스AI
    '487910': 'ACE India Keonsyumeopaweo Active', // ACE 인도컨슈머파워액티브
    '487920': 'ACE India Sinvestmentngdaepyo BIG5 Geurub Active', // ACE 인도시장대표BIG5그룹액티브
    '487950': 'KODEX Daeman Tech High Dividend Dow Jones', // KODEX 대만테크고배당다우존스
    '488080': 'TIGER Semiconductor Top 10 Rebeoriji', // TIGER 반도체TOP10레버리지
    '488200': 'KIWOOM K-2 Cajeonjibugmigonggeubmang', // KIWOOM K-2차전지북미공급망
    '488210': 'KIWOOM K- Semiconductor Bugmigonggeubmang', // KIWOOM K-반도체북미공급망
    '488290': 'Maidaseu Japan Tech Active', // 마이다스 일본테크액티브
    '488480': 'RISE Japan Segteo TOP4Plus', // RISE 일본섹터TOP4Plus
    '488500': 'TIGER US S&P500 Dongilgajung', // TIGER 미국S&P500동일가중
    '488720': 'WON Jonghab Bond (AA- Isang ) Active', // WON 종합채권(AA-이상)액티브
    '488770': 'KODEX Money Market Active', // KODEX 머니마켓액티브
    '488980': 'SOL 26-12 Corporate Bond (AA- Isang ) Active', // SOL 26-12 회사채(AA-이상)액티브
    '489000': 'PLUS Japan Enhwaco Short-Term Treasury Bond ( Synthetic )', // PLUS 일본엔화초단기국채(합성)
    '489010': 'PLUS Global AI Inpeura', // PLUS 글로벌AI인프라
    '489030': 'PLUS High Dividend Juwikeulri Covered Call', // PLUS 고배당주위클리커버드콜
    '489250': 'KODEX US Dividend Dow Jones', // KODEX 미국배당다우존스
    '489290': 'WON US Bilrieoneeo', // WON 미국빌리어네어
    '489790': 'Hanwha Bijeon', // 한화비전
    '489860': 'KIWOOM Global Jeonryeog GRID Inpeura', // KIWOOM 글로벌전력GRID인프라
    '490090': 'TIGER US AI Big Tech 10', // TIGER 미국AI빅테크10
    '490330': 'Koact US Cimae & Noejilhwanciryoje Active', // KoAct 미국치매&뇌질환치료제액티브
    '490480': 'SOL K Defense', // SOL K방산
    '490490': 'SOL US Dividend US Cae Mixed 50', // SOL 미국배당미국채혼합50
    '490590': 'RISE US AI Value Cein Daily Fixed Covered Call', // RISE 미국AI밸류체인데일리고정커버드콜
    '490600': 'RISE US Dividend 100 Daily Fixed Covered Call', // RISE 미국배당100데일리고정커버드콜
    '491010': 'TIGER Global AI Jeonryeoginpeura Active', // TIGER 글로벌AI전력인프라액티브
    '491090': 'KODEX US Tech Top 3 Plus', // KODEX 미국테크TOP3플러스
    '491220': 'PLUS 200TR', // PLUS 200TR
    '491230': 'PLUS Guggongcae Money Market Active', // PLUS 국공채머니마켓액티브
    '491510': 'Paweo K- Juju Value Active', // 파워 K-주주가치액티브
    '491610': '1Q CD Geumri Active ( Synthetic )', // 1Q CD금리액티브(합성)
    '491620': 'RISE US Tech 100 Daily Fixed Covered Call', // RISE 미국테크100데일리고정커버드콜
    '491630': 'RISE US Semiconductor Inbeoseu ( Synthetic H)', // RISE 미국반도체인버스(합성 H)
    '491700': 'HK 200', // HK 200
    '491820': 'HANARO Jeonryeogseolbituja', // HANARO 전력설비투자
    '491830': 'TIGER US AI Semiconductor Paebriseu', // TIGER 미국AI반도체팹리스
    '492500': '1Q Hyundai Motor Geurub Bond (A+ Isang ) & Guggotongan', // 1Q 현대차그룹채권(A+이상)&국고통안
    '493420': 'SOL US Dividend Dow Jones 2 Ho', // SOL 미국배당다우존스2호
    '493810': 'TIGER US AI Big Tech 10 Target Daily Covered Call', // TIGER 미국AI빅테크10타겟데일리커버드콜
    '494180': 'TIME Global Sobiteurendeu Active', // TIME 글로벌소비트렌드액티브
    '494210': 'SOL US 500 Target Daily Covered Call Active', // SOL 미국500타겟데일리커버드콜액티브
    '494220': 'UNICORN SK hynix Value Cein Active', // UNICORN SK하이닉스밸류체인액티브
    '494300': 'KODEX US Nasdaq 100 Daily Covered Call OTM', // KODEX 미국나스닥100데일리커버드콜OTM
    '494310': 'KODEX Semiconductor Rebeoriji', // KODEX 반도체레버리지
    '494330': 'ACE Raipeujasanjuju Value Active', // ACE 라이프자산주주가치액티브
    '494340': 'ACE Global AI Majcumhyeong Semiconductor', // ACE 글로벌AI맞춤형반도체
    '494410': 'PLUS US S&P500 Growth Ju', // PLUS 미국S&P500성장주
    '494420': 'PLUS US Dividend Jeungga Growth Ju Daily Covered Call', // PLUS 미국배당증가성장주데일리커버드콜
    '494670': 'TIGER Joseon Top 10', // TIGER 조선TOP10
    '494840': 'TIGER US Defense Top 10', // TIGER 미국방산TOP10
    '494890': 'KODEX 200 Active', // KODEX 200액티브
    '495040': 'PLUS Korea Value Eob', // PLUS 코리아밸류업
    '495050': 'RISE Korea Value Eob', // RISE 코리아밸류업
    '495060': 'TIME Korea Value Eob Active', // TIME 코리아밸류업액티브
    '495230': 'Koact Korea Value Eob Active', // KoAct 코리아밸류업액티브
    '495330': '1Q Korea Value Eob', // 1Q 코리아밸류업
    '495550': 'SOL Korea Value Eob TR', // SOL 코리아밸류업TR
    '495710': 'BNK 26-06 Teugsucae (AAA Isang ) Active', // BNK 26-06 특수채(AAA이상)액티브
    '495750': 'HANARO Korea Value Eob', // HANARO 코리아밸류업
    '495850': 'KODEX Korea Value Eob', // KODEX 코리아밸류업
    '495940': 'RISE US AI Tech Active', // RISE 미국AI테크액티브
    '496020': 'WON Jeondancae Plus Active', // WON 전단채플러스액티브
    '496080': 'TIGER Korea Value Eob', // TIGER 코리아밸류업
    '496090': 'KIWOOM Korea Value Eob', // KIWOOM 코리아밸류업
    '496120': 'ACE Korea Value Eob', // ACE 코리아밸류업
    '496130': 'TRUSTON Korea Value Eob Active', // TRUSTON 코리아밸류업액티브
    '496770': 'PLUS Global Defense', // PLUS 글로벌방산
    '497510': 'ACE Global Bigpama', // ACE 글로벌빅파마
    '497520': 'ACE Ilrairilri Value Cein', // ACE 일라이릴리밸류체인
    '497570': 'TIGER US Pilradelpia AI Semiconductor Nasdaq', // TIGER 미국필라델피아AI반도체나스닥
    '497780': 'Koact US Ceonyeongaseuinpeura Active', // KoAct 미국천연가스인프라액티브
    '497880': 'SOL CD Geumri & Money Market Active', // SOL CD금리&머니마켓액티브
    '498050': 'HANARO Bio Korea Active', // HANARO 바이오코리아액티브
    '498180': 'Paweo Jonghab Bond (AA- Isang ) Active', // 파워 종합채권(AA-이상)액티브
    '498270': 'KIWOOM US Quantum Computing', // KIWOOM 미국양자컴퓨팅
    '498400': 'KODEX 200 Target Wikeulri Covered Call', // KODEX 200타겟위클리커버드콜
    '498410': 'KODEX Financial High Dividend Top 10 Target Wikeulri Covered Call', // KODEX 금융고배당TOP10타겟위클리커버드콜
    '498610': 'RISE India Dijiteol Growth', // RISE 인도디지털성장
    '498860': 'RISE Korea Financial High Dividend', // RISE 코리아금융고배당
    '499150': 'SOL US S&P500 Enhwanocul (H)', // SOL 미국S&P500엔화노출(H)
    '499660': 'TIGER CD Geumri Plus Active ( Synthetic )', // TIGER CD금리플러스액티브(합성)
    '499790': 'GS Piaenel', // GS피앤엘
    '950210': 'Peureseutiji Bio Pama', // 프레스티지바이오파마
    'J00362': 'KG Mobility 122WR', // KG모빌리티 122WR
    'J01133': 'Yunikem 41WR', // 유니켐 41WR
    'J01800': 'Yuniseun 15WR', // 유니슨 15WR
    'J05011': 'Kaemsiseu 22R', // 캠시스 22R
    'J06697': 'Elaenepeu 7WR', // 엘앤에프 7WR
    'J06717': 'Oteg 13WR', // 오텍 13WR
    'J10996': 'Aebtokeurom 6WR', // 앱토크롬 6WR
    'J14321': 'Haenjeukopeoreisyeon 2WR', // 핸즈코퍼레이션 2WR
    'J19955': 'Reijeoobteg 15R', // 레이저옵텍 15R
    'J29012': 'DH Otorideu 9WR', // DH오토리드 9WR
    'Q50006': 'Shinhan Inbeoseu Koseupi 200 Seonmul ETN', // 신한 인버스 코스피 200 선물 ETN
    'Q50007': 'Shinhan Inbeoseu 2X Koseupi 200 Seonmul ETN', // 신한 인버스 2X 코스피 200 선물 ETN
    'Q50008': 'Shinhan S&P Rebeoriji Yuro Seonmul ETN (H)', // 신한 S&P 레버리지 유로 선물 ETN(H)
    'Q50009': 'Shinhan 2X 26-05 Gongsacae (AAA) ETN', // 신한 2X 26-05 공사채(AAA) ETN
    'Q50010': 'Shinhan Geum Seonmul ETN', // 신한 금 선물 ETN
    'Q50003': 'Shinhan Rebeoriji US Dalreo Seonmul ETN', // 신한 레버리지 미국달러 선물 ETN
    'Q50002': 'Shinhan Rebeoriji Dow Jones Jisu Seonmul ETN (H)', // 신한 레버리지 다우존스지수 선물 ETN(H)
    'Q50005': 'Shinhan Rebeoriji S&P500 Seonmul ETN', // 신한 레버리지 S&P500 선물 ETN
    'Q50004': 'Shinhan Rebeoriji Guri Seonmul ETN', // 신한 레버리지 구리 선물 ETN
    'Q51001': 'Daishin Ceonyeongaseu Seonmul ETN (H)', // 대신 천연가스 선물 ETN(H)
    'Q51002': 'Daishin Inbeoseu 2X Koseudag 150 Seonmul ETN', // 대신 인버스 2X 코스닥 150 선물 ETN
    'Q51004': 'Daishin Inbeoseu Ceonyeongaseu Seonmul ETN (H) B', // 대신 인버스 천연가스 선물 ETN(H) B
    'Q52003': 'Mirae Asset Koseupi 200 Seonmul ETN', // 미래에셋 코스피200 선물 ETN
    'Q52004': 'Mirae Asset Inbeoseu Koseudag 150 Seonmul ETN', // 미래에셋 인버스 코스닥150 선물 ETN
    'Q52005': 'Mirae Asset Inbeoseu 2X Weonyuseonmul Mixed ETN (H)', // 미래에셋 인버스 2X 원유선물혼합 ETN(H)
    'Q52006': 'Mirae Asset 2X US Caeulteura 30 Nyeon Seonmul ETN', // 미래에셋 2X 미국채울트라30년 선물 ETN
    'Q52007': 'Mirae Asset US AI Top 3 ETN', // 미래에셋 미국 AI TOP3 ETN
    'Q52008': 'Mirae Asset US Tech & Semiconductor Top 3 ETN', // 미래에셋 미국 테크&반도체 TOP3 ETN
    'Q52009': 'Mirae Asset Ceonyeongaseu Seonmul ETN B', // 미래에셋 천연가스 선물 ETN B
    'Q52000': 'Mirae Asset Rebeoriji Weonyuseonmul Mixed ETN (H)', // 미래에셋 레버리지 원유선물혼합 ETN(H)
    'Q53008': 'Samsung Geum Seonmul ETN (H)', // 삼성 금 선물 ETN(H)
    'Q53009': 'Samsung Inbeoseu Eun Seonmul ETN (H)', // 삼성 인버스 은 선물 ETN(H)
    'Q53010': 'Samsung Rebeoriji Koseupi 200 Seonmul ETN', // 삼성 레버리지 코스피200 선물 ETN
    'Q53011': 'Samsung Rebeoriji Ceonyeongaseu Seonmul ETN C', // 삼성 레버리지 천연가스 선물 ETN C
    'Q53012': 'Samsung Nasdaq 100 TR ETN', // 삼성 나스닥 100 TR ETN
    'Q53013': 'Samsung S&P500 VIX S/T Seonmul ETN B', // 삼성 S&P500 VIX S/T 선물 ETN B
    'Q53014': 'Samsung Iselect Rebeoriji Joseon Top 10 TR ETN', // 삼성 iSelect 레버리지 조선 TOP10 TR ETN
    'Q53006': 'Samsung KRX Physical Gold ETN', // 삼성 KRX 금현물 ETN
    'Q53003': 'Samsung Rebeoriji WTI Weonyu Seonmul ETN', // 삼성 레버리지 WTI원유 선물 ETN
    'Q53005': 'Samsung Rebeoriji Geum Seonmul ETN (H)', // 삼성 레버리지 금 선물 ETN(H)
    'Q55006': 'N2 Rebeoriji Geum Seonmul ETN (H)', // N2 레버리지 금 선물 ETN(H)
    'Q55007': 'N2 Inbeoseu Rebeoriji Guri Seonmul ETN (H)', // N2 인버스 레버리지 구리 선물 ETN(H)
    'Q55008': 'N2 KIS CD Geumrituja ETN', // N2 KIS CD금리투자 ETN
    'Q55009': 'N2 Bangwi Industries Top5 ETN', // N2 방위산업 Top5 ETN
    'Q55010': 'N2 Inbeoseu 2X Ceonyeongaseu Seonmul ETN', // N2 인버스 2X 천연가스 선물 ETN
    'Q55004': 'N2 US IT TOP5 ETN (H)', // N2 미국 IT TOP5 ETN(H)
    'Q57004': 'Hantu FTSE 100 ETN', // 한투 FTSE100 ETN
    'Q57005': 'Hantu S&P500 Seonmul ETN', // 한투 S&P500 선물 ETN
    'Q57006': 'Hantu Inbeoseu 2X Geum Seonmul ETN', // 한투 인버스 2X 금 선물 ETN
    'Q57007': 'Hantu Inbeoseu 2X Peulraetineom Seonmul ETN', // 한투 인버스 2X 플래티넘 선물 ETN
    'Q57008': 'Hantu Rebeoriji Koseudag 150 Seonmul ETN', // 한투 레버리지 코스닥150선물 ETN
    'Q57009': 'Hantu KIS CD Geumrituja ETN', // 한투 KIS CD금리투자 ETN
    'Q57010': 'Hantu Japan Jonghab Corporation TOP5 ETN', // 한투 일본종합상사TOP5 ETN
    'Q57011': 'Hantu 3X Rebeoriji Treasury Bond 30 Nyeon ETN', // 한투 3X레버리지국채30년 ETN
    'Q57001': 'Hantu Koseupi Yangmaedo 5% OTM ETN', // 한투 코스피 양매도 5% OTM ETN
    'Q57002': 'Hantu Koseupi Yangmaedo 3% OTM ETN', // 한투 코스피 양매도 3% OTM ETN
    'Q58001': 'KB Rebeoriji S&P 500 Seonmul ETN (H)', // KB 레버리지 S&P 500 선물 ETN(H)
    'Q58002': 'KB Ceonyeongaseu Seonmul ETN (H)', // KB 천연가스 선물 ETN(H)
    'Q58003': 'KB Rebeoriji Guri Seonmul ETN (H)', // KB 레버리지 구리 선물 ETN(H)
    'Q58004': 'KB Inbeoseu 2X KOSPI 200 Seonmul ETN', // KB 인버스 2X KOSPI 200 선물 ETN
    'Q58005': 'KB China Gwacangpan STAR 50 ETN', // KB 차이나 과창판 STAR 50 ETN
    'Q58006': 'KB Rebeoriji US Cae 10 Nyeon ETN', // KB 레버리지 미국채 10년 ETN
    'Q58007': 'KB Rebeoriji 2 Cajeonji TOP 10 TR ETN', // KB 레버리지 2차전지 TOP 10 TR ETN
    'Q58008': 'KB Inbeoseu Eun Seonmul ETN', // KB 인버스 은 선물 ETN
    'Q61000': 'Me REITs Inpeulreisyeon Treasury Bond ETN', // 메리츠 인플레이션 국채 ETN
    'Q61001': 'Me REITs Rebeoriji Geum Seonmul ETN (H)', // 메리츠 레버리지 금 선물 ETN(H)
    'Q61002': 'Me REITs Inbeoseu Treasury Bond 10 Nyeon ETN', // 메리츠 인버스 국채10년 ETN
    'Q61003': 'Me REITs S&P Europe Tansobaeculgweon Seonmul ETN (H)', // 메리츠 S&P 유럽탄소배출권 선물 ETN(H)
    'Q61004': 'Me REITs Inbeoseu 2X US Cae 30 Nyeon ETN (H)', // 메리츠 인버스 2X 미국채30년 ETN(H)
    'Q61005': 'Me REITs Inbeoseu Treasury Bond 5 Nyeon ETN', // 메리츠 인버스 국채5년 ETN
    'Q61006': 'Me REITs Inbeoseu 3X Treasury Bond 10 Nyeon ETN', // 메리츠 인버스 3X 국채10년 ETN
    'Q61007': 'Me REITs KAP Inbeoseu 2X Japan Enhwa ETN', // 메리츠 KAP 인버스 2X 일본 엔화 ETN
    'Q61008': 'Me REITs Megsiko Pesohwa ETN', // 메리츠 멕시코 페소화 ETN
    'Q61009': 'Me REITs Japan Treasury Bond 10 Nyeon ETN', // 메리츠 일본 국채 10년 ETN
    'Q61010': 'Me REITs Rebeoriji Eun Seonmul ETN (H)', // 메리츠 레버리지 은 선물 ETN(H)
    'Q70001': 'Hana Rebeoriji Ogsusu Seonmul ETN (H)', // 하나 레버리지 옥수수 선물 ETN(H)
    'Q70002': 'Hana Solactive US Tech Top 10 ETN (H)', // 하나 Solactive US Tech Top 10 ETN(H)
    'Q70003': 'Hana S&P Inbeoseu 2X WTI Weonyu Seonmul ETN B', // 하나 S&P 인버스 2X WTI원유 선물 ETN B
    'Q76000': 'Kium Inbeoseu US Dalreoseonmul ETN', // 키움 인버스 미국달러선물 ETN
    'Q76001': 'Kium 2 Cajeonji Industries ETN', // 키움 2차전지산업 ETN
    'Q76002': 'Kium Rebeoriji REITs Real Estate Infrastructure ETN', // 키움 레버리지 리츠부동산인프라 ETN
    '900140': 'Elbeuiemssi Holdings', // 엘브이엠씨홀딩스
    '900110': 'Iseuteuasia Holdings', // 이스트아시아홀딩스
    '900270': 'Heongsyeonggeurub', // 헝셩그룹
    '900260': 'Roseuwel', // 로스웰
    '900290': 'GRT', // GRT
    '900300': 'Oganigtikoseumetig', // 오가닉티코스메틱
    '900310': 'Keolreorei', // 컬러레이
    '900340': 'Wingibpudeu', // 윙입푸드
    '0001A0': 'Deogyangeneojen', // 덕양에너젠
    '000250': 'Samceondang Pharmaceutical', // 삼천당제약
    '000440': 'Jungangeneobiseu', // 중앙에너비스
    '0004V0': 'Enbialmosyeon', // 엔비알모션
    '0004Y0': 'Dibi Financial Je 14 Hoseupaeg', // 디비금융제14호스팩
    '0007C0': 'Akeuril', // 아크릴
    '0008Z0': 'Eseuensiseu', // 에스엔시스
    '0009K0': 'Eimdeu Bio', // 에임드바이오
    '001000': 'Sinraseomyu', // 신라섬유
    '0010V0': 'Jeipiaihelseukeeo', // 제이피아이헬스케어
    '0011A0': 'Aegseubiseu', // 액스비스
    '0013V0': 'Samjin Foods', // 삼진식품
    '001540': 'Angug Pharmaceutical', // 안국약품
    '0015G0': 'Geuringwanghag', // 그린광학
    '0015N0': 'Aromatika', // 아로마티카
    '0015S0': 'Peseukaro', // 페스카로
    '001810': 'Murim SP', // 무림SP
    '001840': 'Ihwagongyeong', // 이화공영
    '002230': 'Pieseuteg', // 피에스텍
    '002290': 'Samilgieobgongsa', // 삼일기업공사
    '002680': 'Hantab', // 한탑
    '002800': 'Sinsin Pharmaceutical', // 신신제약
    '003100': 'Seongwang', // 선광
    '003310': 'Daeju Industries', // 대주산업
    '003380': 'Harim Holdings', // 하림지주
    '0037T0': 'KB Je 32 Hoseupaeg', // KB제32호스팩
    '003800': 'Eiseucimdae', // 에이스침대
    '0041B0': 'Gyobo 18 Hoseupaeg', // 교보18호스팩
    '0041J0': 'Eleseuseupaeg 1 Ho', // 엘에스스팩1호
    '0041L0': 'Hana 35 Hoseupaeg', // 하나35호스팩
    '0044K0': 'Samsung Seupaeg 10 Ho', // 삼성스팩10호
    '004590': 'Korea Gagu', // 한국가구
    '004650': 'Canghaeetanol', // 창해에탄올
    '004780': 'Daeryugjegwan', // 대륙제관
    '005160': 'Dongkuk Industries', // 동국산업
    '005290': 'Dongjinssemikem', // 동진쎄미켐
    '0054V0': 'Eneiciseupaeg 32 Ho', // 엔에이치스팩32호
    '005670': 'Pudeuwel', // 푸드웰
    '005710': 'Daeweon Industries', // 대원산업
    '005860': 'Hanilsaryo', // 한일사료
    '005990': 'Maeil Holdings', // 매일홀딩스
    '006050': 'Gugyeongjiaenem', // 국영지앤엠
    '006140': 'Pijei Electronics', // 피제이전자
    '006620': 'Donggu Bio Pharmaceutical', // 동구바이오제약
    '006730': 'Seobu T&D', // 서부T&D
    '0068Y0': 'Bienkeije 3 Hoseupaeg', // 비엔케이제3호스팩
    '006910': 'Boseongpaweoteg', // 보성파워텍
    '006920': 'Mohenjeu', // 모헨즈
    '0071M0': 'Samsung Seupaeg 11 Ho', // 삼성스팩11호
    '0072Z0': 'KB Je 33 Hoseupaeg', // KB제33호스팩
    '007330': 'Pureunjeocug Bank', // 푸른저축은행
    '007370': 'Jinyang Pharmaceutical', // 진양제약
    '007390': 'Neiceosel', // 네이처셀
    '007530': 'Waiem', // 와이엠
    '007680': 'Daeweon', // 대원
    '007720': 'Sonoseukweeo', // 소노스퀘어
    '007770': 'Hanil Chemical', // 한일화학
    '007820': 'Eseuemkoeo', // 에스엠코어
    '008290': 'Weonpungmulsan', // 원풍물산
    '0082N0': 'Kanapeuterapyutigseu', // 카나프테라퓨틱스
    '008370': 'Weonpung', // 원풍
    '008470': 'Buseuta', // 부스타
    '008830': 'Daedonggieo', // 대동기어
    '0088D0': 'Me REITs Je 1 Hoseupaeg', // 메리츠제1호스팩
    '0088M0': 'Mejyu', // 메쥬
    '0091W0': 'Sinyeongseupaeg 11 Ho', // 신영스팩11호
    '009300': 'Sama Pharmaceutical', // 삼아제약
    '0093G0': 'Mirae Asset Bijeonseupaeg 8 Ho', // 미래에셋비전스팩8호
    '009520': 'POSCO Emteg', // 포스코엠텍
    '009620': 'Sambo Industries', // 삼보산업
    '0096B0': 'Samsung Seupaeg 12 Ho', // 삼성스팩12호
    '0096D0': 'Mirae Asset Bijeonseupaeg 9 Ho', // 미래에셋비전스팩9호
    '009730': 'Irem', // 이렘
    '009780': 'Emeseussi', // 엠에스씨
    '0097F0': 'Mirae Asset Bijeonseupaeg 10 Ho', // 미래에셋비전스팩10호
    '0098T0': 'Gyobo 19 Hoseupaeg', // 교보19호스팩
    '0099W0': 'Mirae Asset Bijeonseupaeg 11 Ho', // 미래에셋비전스팩11호
    '0099X0': 'IBKS Je 25 Hoseupaeg', // IBKS제25호스팩
    '010170': 'Korea Gwangtongsin', // 대한광통신
    '0101C0': 'Hana 36 Hoseupaeg', // 하나36호스팩
    '010240': 'Heunggug', // 흥국
    '010280': 'AItisenenteg', // 아이티센엔텍
    '010470': 'Orikom', // 오리콤
    '0105P0': 'Eugene Seupaeg 12 Ho', // 유진스팩12호
    '011040': 'Gyeongdong Pharmaceutical', // 경동제약
    '011080': 'Hyeongji I&C', // 형지I&C
    '011320': 'Yunikeu', // 유니크
    '011370': 'Seohan', // 서한
    '011560': 'Seboemissi', // 세보엠이씨
    '0115H0': 'Samsung Seupaeg 13 Ho', // 삼성스팩13호
    '012210': 'Sammigeumsog', // 삼미금속
    '012340': 'Nyuinteg', // 뉴인텍
    '012620': 'Weonilteuggang', // 원일특강
    '012700': 'Rideukopeu', // 리드코프
    '012790': 'Sinil Pharmaceutical', // 신일제약
    '012860': 'Mobeiseu Electronics', // 모베이스전자
    '013030': 'Hairog Korea', // 하이록코리아
    '0130H0': 'Eneiciseupaeg 33 Ho', // 엔에이치스팩33호
    '013120': 'Dongweongaebal', // 동원개발
    '013310': 'Ajin Industries', // 아진산업
    '013720': 'THE CUBE&', // THE CUBE&
    '013810': 'Seupeko', // 스페코
    '013990': 'Agabangkeompeoni', // 아가방컴퍼니
    '014100': 'Mediangseu', // 메디앙스
    '014190': 'Weonigkyubeu', // 원익큐브
    '014470': 'Bubang', // 부방
    '014570': 'Goryeo Pharmaceutical', // 고려제약
    '014620': 'Seonggwangbendeu', // 성광벤드
    '014940': 'Orientaljeonggong', // 오리엔탈정공
    '014950': 'Samig Pharmaceutical', // 삼익제약
    '014970': 'Samryungmulsan', // 삼륭물산
    '015710': 'Kokom', // 코콤
    '015750': 'Seonguhaiteg', // 성우하이텍
    '016100': 'Rideoseukoseumetig', // 리더스코스메틱
    '016250': 'SGC E&C', // SGC E&C
    '016600': 'Kyu Capital', // 큐캐피탈
    '016670': 'Dimoa', // 디모아
    '016790': 'Hyundai Saryo', // 현대사료
    '016920': 'Kaseu', // 카스
    '017000': 'Sinweonjonghabgaebal', // 신원종합개발
    '017250': 'Inteoem', // 인터엠
    '017480': 'Samhyeonceolgang', // 삼현철강
    '017510': 'Semyeong Electric', // 세명전기
    '017650': 'Daelim Paper', // 대림제지
    '017890': 'Korea Alkol', // 한국알콜
    '018000': 'Yuniseun', // 유니슨
    '018120': 'Jinrobalhyo', // 진로발효
    '018290': 'Beuiti', // 브이티
    '018310': 'Sammogeseupom', // 삼목에스폼
    '018620': 'Ujinbiaenji', // 우진비앤지
    '018680': 'Seoul Pharmaceutical', // 서울제약
    '018700': 'Bareunson', // 바른손
    '019010': 'Benyuji', // 베뉴지
    '019210': 'Waiji - Weon', // 와이지-원
    '019540': 'Ilji Tech', // 일지테크
    '019550': 'SBI Inbeseuteumeonteu', // SBI인베스트먼트
    '019570': 'Peulrutoseu', // 플루토스
    '019660': 'Geulrobon', // 글로본
    '019770': 'Seoyeontabmetal', // 서연탑메탈
    '019990': 'Eneotokeu', // 에너토크
    '020180': 'Daishin Jeongbotongsin', // 대신정보통신
    '020400': 'Daedonggeumsog', // 대동금속
    '020710': 'Sigong Tech', // 시공테크
    '021040': 'Daehoteugsugang', // 대호특수강
    '021045': 'Daehoteugsugang Pref', // 대호특수강우
    '021080': 'Eitineominbeseuteu', // 에이티넘인베스트
    '021320': 'KCC Engineering & Construction', // KCC건설
    '021650': 'Korea Kyubig', // 한국큐빅
    '021880': 'Meiseun Capital', // 메이슨캐피탈
    '022220': 'Tikeijiaegang', // 티케이지애강
    '023160': 'Taegwang', // 태광
    '023410': 'Eugene Gieob', // 유진기업
    '023440': 'Jeiseuko Holdings', // 제이스코홀딩스
    '023600': 'Sambopanji', // 삼보판지
    '023760': 'Korea Capital', // 한국캐피탈
    '023770': 'Peulreiwideu', // 플레이위드
    '023790': 'Dongilseutilreogseu', // 동일스틸럭스
    '023900': 'Punggugjujeong', // 풍국주정
    '023910': 'Korea Pharmaceutical', // 대한약품
    '024060': 'Heungguseogyu', // 흥구석유
    '024120': 'KB Otosiseu', // KB오토시스
    '024740': 'Hanildanjo', // 한일단조
    '024800': 'Yuseongtieneseu', // 유성티엔에스
    '024830': 'Seweonmulsan', // 세원물산
    '024840': 'KB I Metal', // KBI메탈
    '024850': 'HLB Innovation', // HLB이노베이션
    '024880': 'Keipiepeu', // 케이피에프
    '024910': 'Gyeongcang Industries', // 경창산업
    '024940': 'PN Pungnyeon', // PN풍년
    '024950': 'Samceonrinvestmentjeongeo', // 삼천리자전거
    '025320': 'Sinopegseu', // 시노펙스
    '025440': 'DH Otoweeo', // DH오토웨어
    '025550': 'Korea Seonjae', // 한국선재
    '025770': 'Korea Jeongbotongsin', // 한국정보통신
    '025870': 'Sinraeseuji', // 신라에스지
    '025880': 'Keissipideu', // 케이씨피드
    '025900': 'Donghwagieob', // 동화기업
    '025950': 'Dongsin Engineering & Construction', // 동신건설
    '025980': 'Ananti', // 아난티
    '026040': 'Jeieseutina', // 제이에스티나
    '026150': 'Teugsu Engineering & Construction', // 특수건설
    '026910': 'Gwangjinsileob', // 광진실업
    '027040': 'Seoul Electronics Tongsin', // 서울전자통신
    '027050': 'Korea Na', // 코리아나
    '027360': 'Aju IB Tuja', // 아주IB투자
    '027580': 'Sangbo', // 상보
    '027710': 'Pamseutori', // 팜스토리
    '027830': 'Daeseongcangtu', // 대성창투
    '028080': 'Hyumaegseu Holdings', // 휴맥스홀딩스
    '028300': 'HLB', // HLB
    '029480': 'Gwangmu', // 광무
    '030350': 'Deuraegonpeulrai', // 드래곤플라이
    '030520': 'Hangeulgwakeompyuteo', // 한글과컴퓨터
    '030530': 'Weonig Holdings', // 원익홀딩스
    '030960': 'Yangjisa', // 양지사
    '031310': 'AIjeubijeon', // 아이즈비전
    '031330': 'Eseueiemti', // 에스에이엠티
    '031510': 'Oseutem', // 오스템
    '031860': 'Dieiciegseukeompeoni', // 디에이치엑스컴퍼니
    '031980': 'Pieseukei Holdings', // 피에스케이홀딩스
    '032080': 'Ajeuteg WB', // 아즈텍WB
    '032190': 'Daudeita', // 다우데이타
    '032280': 'Samil', // 삼일
    '032300': 'Korea Pama', // 한국파마
    '032500': 'Keiemdeobeulyu', // 케이엠더블유
    '032540': 'TJ Midieo', // TJ미디어
    '032580': 'Pidelrigseu', // 피델릭스
    '032620': 'Yubikeeo', // 유비케어
    '032680': 'Sopeuteusen', // 소프트센
    '032685': 'Sopeuteusen Pref', // 소프트센우
    '032750': 'Samjin', // 삼진
    '032790': 'Emjensolrusyeon', // 엠젠솔루션
    '032800': 'Pantajio', // 판타지오
    '032820': 'Woori Gisul', // 우리기술
    '032850': 'Biteukeompyuteo', // 비트컴퓨터
    '032860': 'Deorami', // 더라미
    '032940': 'Weonig', // 원익
    '032960': 'Dongilgiyeon', // 동일기연
    '032980': 'Baion', // 바이온
    '033050': 'Jeiemai', // 제이엠아이
    '033100': 'Jeryong Electric', // 제룡전기
    '033130': 'Dijiteuljoseon', // 디지틀조선
    '033160': 'Emkei Electronics', // 엠케이전자
    '033170': 'Sigeunetigseu', // 시그네틱스
    '033200': 'Moateg', // 모아텍
    '033230': 'Inseongjeongbo', // 인성정보
    '033290': 'Rojen', // 로젠
    '033310': 'Emtuen', // 엠투엔
    '033320': 'Jeissihyeonsiseutem', // 제이씨현시스템
    '033340': 'Joheunsaramdeul', // 좋은사람들
    '033500': 'Dongseonghwainteg', // 동성화인텍
    '033540': 'Parateg', // 파라텍
    '033560': 'Beulrukom', // 블루콤
    '033640': 'Nepaeseu', // 네패스
    '033790': 'Pino', // 피노
    '033830': 'Tibissi', // 티비씨
    '034810': 'Haeseong Industries', // 해성산업
    '03481K': 'Haeseong Industries 1st Pref', // 해성산업1우
    '034940': 'Joa Pharmaceutical', // 조아제약
    '034950': 'Korea Gieobpyeongga', // 한국기업평가
    '035080': 'Geuraedieonteu', // 그래디언트
    '035200': 'Peureompaseuteu', // 프럼파스트
    '035290': 'Goldeuaeneseu', // 골드앤에스
    '035460': 'Gisantelrekom', // 기산텔레콤
    '035600': 'KG Inisiseu', // KG이니시스
    '035610': 'Solbon', // 솔본
    '035620': 'Bareunsoniaenei', // 바른손이앤에이
    '035760': 'CJ ENM', // CJ ENM
    '035810': 'Iji Holdings', // 이지홀딩스
    '035890': 'Seohyi Engineering & Construction', // 서희건설
    '035900': 'JYP Ent.', // JYP Ent.
    '036000': 'Yerimdang', // 예림당
    '036010': 'Abiko Electronics', // 아비코전자
    '036030': 'Keitialpa', // 케이티알파
    '036090': 'Wijiteu', // 위지트
    '036120': 'Seoulpyeonggajeongbo', // 서울평가정보
    '036170': 'Eiciemnegseu', // 에이치엠넥스
    '036190': 'Geumhwapieseusi', // 금화피에스시
    '036200': 'Yunisem', // 유니셈
    '036220': 'Osanghelseukeeo', // 오상헬스케어
    '036480': 'Daeseongmisaengmul', // 대성미생물
    '036540': 'SFA Semiconductor', // SFA반도체
    '036560': 'KZ Jeongmil', // KZ정밀
    '036620': 'Gamseongkopeoreisyeon', // 감성코퍼레이션
    '036630': 'Sejongtelrekom', // 세종텔레콤
    '036640': 'HRS', // HRS
    '036670': 'Samyang Keissiai', // 삼양케이씨아이
    '036690': 'Komaegseu', // 코맥스
    '036710': 'Simteg Holdings', // 심텍홀딩스
    '036800': 'Naiseujeongbotongsin', // 나이스정보통신
    '036810': 'Epeueseuti', // 에프에스티
    '036830': 'Solbeurein Holdings', // 솔브레인홀딩스
    '036890': 'Jinseongtiissi', // 진성티이씨
    '036930': 'Juseongenjinieoring', // 주성엔지니어링
    '037030': 'Paweones', // 파워넷
    '037070': 'Paseko', // 파세코
    '037230': 'Korea Paegkiji', // 한국팩키지
    '037330': 'Injidiseupeulre', // 인지디스플레
    '037350': 'Seongdoienji', // 성도이엔지
    '037370': 'EG', // EG
    '037400': 'Woori Enteopeuraijeu', // 우리엔터프라이즈
    '037440': 'Hyirim', // 희림
    '037460': 'Samji Electronics', // 삼지전자
    '037760': 'Sseniteu', // 쎄니트
    '037950': 'Elkeomteg', // 엘컴텍
    '038010': 'Jeil Tech Noseu', // 제일테크노스
    '038060': 'Rumenseu', // 루멘스
    '038070': 'Seorin Bio', // 서린바이오
    '038110': 'Ekopeulraseutig', // 에코플라스틱
    '038290': 'Makeurojen', // 마크로젠
    '038390': 'Redeukaebtueo', // 레드캡투어
    '038460': 'Bio Seumateu', // 바이오스마트
    '038500': 'Sampyosimenteu', // 삼표시멘트
    '038530': 'Kei Bio', // 케이바이오
    '038540': 'Sangsangin', // 상상인
    '038620': 'Wijeukopeu', // 위즈코프
    '038680': 'Eseunes', // 에스넷
    '038870': 'Eko Bio', // 에코바이오
    '038880': 'AIei', // 아이에이
    '038950': 'Paindijiteol', // 파인디지털
    '039010': 'Hyundai Eiciti', // 현대에이치티
    '039020': 'Igeon Holdings', // 이건홀딩스
    '039030': 'Io Technics', // 이오테크닉스
    '039200': 'Oseukoteg', // 오스코텍
    '039240': 'Gyeongnamseutil', // 경남스틸
    '039290': 'Inpobaengkeu', // 인포뱅크
    '039310': 'Sejung', // 세중
    '039340': 'Korea Gyeongje TV', // 한국경제TV
    '039420': 'Keielnes', // 케이엘넷
    '039440': 'Eseutiai', // 에스티아이
    '039560': 'Dasanneteuweogseu', // 다산네트웍스
    '039610': 'Hwaseongbaelbeu', // 화성밸브
    '039740': 'Korea Jeongbogonghag', // 한국정보공학
    '039830': 'Orora', // 오로라
    '039840': 'Dio', // 디오
    '039860': 'Nanoenteg', // 나노엔텍
    '039980': 'Polrariseu AI', // 폴라리스AI
    '040160': 'Nuripeulregseu', // 누리플렉스
    '040300': 'YTN', // YTN
    '040350': 'Keureoeseuji', // 크레오에스지
    '040420': 'Jeongsangjeieleseu', // 정상제이엘에스
    '040610': 'SG&G', // SG&G
    '040910': 'AIssidi', // 아이씨디
    '041020': 'Polrariseu Office', // 폴라리스오피스
    '041190': 'Woori Gisultuja', // 우리기술투자
    '041440': 'Hyundai Ebeodaim', // 현대에버다임
    '041460': 'Korea Electronics Injeung', // 한국전자인증
    '041510': 'Eseuem', // 에스엠
    '041520': 'Ielssi', // 이엘씨
    '041590': 'Peulraeseukeu', // 플래스크
    '041830': 'Inbadi', // 인바디
    '041910': 'Polrariseu AI Pama', // 폴라리스AI파마
    '041920': 'Mediana', // 메디아나
    '041930': 'Dongahwaseong', // 동아화성
    '041960': 'Komipam', // 코미팜
    '042000': 'Kape 24', // 카페24
    '042040': 'Keipiem Tech', // 케이피엠테크
    '042110': 'Eseussidi', // 에스씨디
    '042370': 'Biceuro Tech', // 비츠로테크
    '042420': 'Neowijeu Holdings', // 네오위즈홀딩스
    '042500': 'Ringneteu', // 링네트
    '042510': 'Raonsikyueo', // 라온시큐어
    '042520': 'Hanseu Bio Medeu', // 한스바이오메드
    '042600': 'Saeronigseu', // 새로닉스
    '042940': 'Sangji Engineering & Construction', // 상지건설
    '043090': 'Deo Tech Nolroji', // 더테크놀로지
    '043100': 'Alpa AI', // 알파AI
    '043150': 'Bateg', // 바텍
    '043200': 'Paru', // 파루
    '043220': 'Tieseunegseujen', // 티에스넥스젠
    '043260': 'Seongho Electronics', // 성호전자
    '043340': 'Essen Tech', // 에쎈테크
    '043360': 'Dijiai', // 디지아이
    '043370': 'Pieiciei', // 피에이치에이
    '043590': 'Welkibseuhaiteg', // 웰킵스하이텍
    '043610': 'KT Jinimyujig', // KT지니뮤직
    '043650': 'Gugsundang', // 국순당
    '043710': 'Seoulrigeo', // 서울리거
    '043910': 'Jayeongwahwangyeong', // 자연과환경
    '044180': 'KD', // KD
    '044340': 'Winigseu', // 위닉스
    '044480': 'Bilrieonseu', // 빌리언스
    '044490': 'Taeung', // 태웅
    '044780': 'Eicikei', // 에이치케이
    '044960': 'Igeulbes', // 이글벳
    '044990': 'Eicieneseuhaiteg', // 에이치엔에스하이텍
    '045060': 'Ogong', // 오공
    '045100': 'Hanyangienji', // 한양이엔지
    '045300': 'Seongu Tech Ron', // 성우테크론
    '045340': 'Totalsopeuteu', // 토탈소프트
    '045390': 'Daeatiai', // 대아티아이
    '045510': 'Jeongweonensiseu', // 정원엔시스
    '045520': 'Keurinaensaieonseu', // 크린앤사이언스
    '045660': 'Eiteg', // 에이텍
    '045970': 'Koasia', // 코아시아
    '046070': 'Kodako', // 코다코
    '046120': 'Oreubiteg', // 오르비텍
    '046210': 'HLB Panajin', // HLB파나진
    '046310': 'Baeggeum T&A', // 백금T&A
    '046390': 'Samhwaneteuweogseu', // 삼화네트웍스
    '046440': 'KG Mobilrieonseu', // KG모빌리언스
    '046890': 'Seoul Semiconductor', // 서울반도체
    '046940': 'Uweongaebal', // 우원개발
    '046970': 'Woori Ro', // 우리로
    '047080': 'Hanbicsopeuteu', // 한빛소프트
    '047310': 'Paweorojigseu', // 파워로직스
    '047560': 'Iseuteusopeuteu', // 이스트소프트
    '047770': 'Kodejeukeombain', // 코데즈컴바인
    '047820': 'Corogbaemmidieo', // 초록뱀미디어
    '047920': 'HLB Pharmaceutical', // HLB제약
    '048410': 'Hyundai Bio', // 현대바이오
    '048430': 'Yura Tech', // 유라테크
    '048470': 'Daedongseutil', // 대동스틸
    '048530': 'Inteuron Bio', // 인트론바이오
    '048550': 'SM C&C', // SM C&C
    '048770': 'TPC', // TPC
    '048830': 'Enpikei', // 엔피케이
    '048870': 'Sineoji Innovation', // 시너지이노베이션
    '048910': 'Daeweonmidieo', // 대원미디어
    '049070': 'Intabseu', // 인탑스
    '049080': 'Gigarein', // 기가레인
    '049120': 'Paindiaenssi', // 파인디앤씨
    '049180': 'Selrumedeu', // 셀루메드
    '049430': 'Komeron', // 코메론
    '049470': 'Biteupeulraenis', // 비트플래닛
    '049480': 'Opeunbeiseu', // 오픈베이스
    '049520': 'Yuaiel', // 유아이엘
    '049550': 'Ingkeu Tech', // 잉크테크
    '049630': 'Jaeyeongsolruteg', // 재영솔루텍
    '049720': 'Goryeosinyongjeongbo', // 고려신용정보
    '049830': 'Seungil', // 승일
    '049950': 'Miraekeompeoni', // 미래컴퍼니
    '049960': 'Ssel Bio Teg', // 쎌바이오텍
    '050090': 'Bikei Holdings', // 비케이홀딩스
    '050110': 'Kaemsiseu', // 캠시스
    '050120': 'ES Kyubeu', // ES큐브
    '050760': 'Eseupolriteg', // 에스폴리텍
    '050860': 'Aseateg', // 아세아텍
    '050890': 'Ssolrideu', // 쏠리드
    '050960': 'Susanaiaenti', // 수산아이앤티
    '051160': 'Jieosopeuteu', // 지어소프트
    '051360': 'Tobiseu', // 토비스
    '051370': 'Inteopeulregseu', // 인터플렉스
    '051380': 'Pissidiregteu', // 피씨디렉트
    '051390': 'YW', // YW
    '051490': 'Naraemaendi', // 나라엠앤디
    '051500': 'CJ Peuresiwei', // CJ프레시웨이
    '051780': 'Kyuro Holdings', // 큐로홀딩스
    '051980': 'Jungangceomdansojae', // 중앙첨단소재
    '052020': 'Eseutikyubeu', // 에스티큐브
    '052220': 'Imbc', // iMBC
    '052260': 'Hyundai Bio Raendeu', // 현대바이오랜드
    '052300': 'Osyeonindeobeulyu', // 오션인더블유
    '052330': 'Koteg', // 코텍
    '052400': 'Konaai', // 코나아이
    '052420': 'Oseongceomdansojae', // 오성첨단소재
    '052460': 'AIkeuraepeuteu', // 아이크래프트
    '052600': 'Hanneteu', // 한네트
    '052710': 'Amoteg', // 아모텍
    '052770': 'AItogsi', // 아이톡시
    '052790': 'Aegtojeusopeuteu', // 액토즈소프트
    '052860': 'AIaenssi', // 아이앤씨
    '052900': 'KX Haiteg', // KX하이텍
    '053030': 'Bainegseu', // 바이넥스
    '053050': 'Jieseui', // 지에스이
    '053060': 'Sedong', // 세동
    '053080': 'Keiensol', // 케이엔솔
    '053160': 'Peuriemseu', // 프리엠스
    '053260': 'Geumgangceolgang', // 금강철강
    '053270': 'Guyeong Tech', // 구영테크
    '053280': 'Yeseu 24', // 예스24
    '053290': 'NE Neungryul', // NE능률
    '053300': 'Korea Jeongboinjeung', // 한국정보인증
    '053350': 'Initeg', // 이니텍
    '053450': 'Sekonigseu', // 세코닉스
    '053580': 'Webkesi', // 웹케시
    '053610': 'Peuroteg', // 프로텍
    '053620': 'Taeyang', // 태양
    '053700': 'Sambomoteoseu', // 삼보모터스
    '053800': 'Anraeb', // 안랩
    '053950': 'Gyeongnam Pharmaceutical', // 경남제약
    '053980': 'Osangjaiel', // 오상자이엘
    '054040': 'Korea Keompyuteo', // 한국컴퓨터
    '054050': 'Nongu Bio', // 농우바이오
    '054090': 'Samjinelaendi', // 삼진엘앤디
    '054180': 'Medikogseu', // 메디콕스
    '054210': 'Iraenteg', // 이랜텍
    '054220': 'Biceurosiseu', // 비츠로시스
    '054300': 'Paenseutaenteopeuraijeu', // 팬스타엔터프라이즈
    '054410': 'Keipitiyu', // 케이피티유
    '054450': 'Telrecibseu', // 텔레칩스
    '054540': 'Samyeongemteg', // 삼영엠텍
    '054620': 'APS', // APS
    '054670': 'Korea Nyupam', // 대한뉴팜
    '054780': 'Kiiseuteu', // 키이스트
    '054800': 'AIdiseu Holdings', // 아이디스홀딩스
    '054920': 'Hankeomwideu', // 한컴위드
    '054930': 'Yusin', // 유신
    '054940': 'Egsaienssi', // 엑사이엔씨
    '054950': 'Jeibeuiem', // 제이브이엠
    '056080': 'Eugene Robos', // 유진로봇
    '056090': 'Sijimedeuteg', // 시지메드텍
    '056190': 'Eseuepeuei', // 에스에프에이
    '056360': 'Kowibeo', // 코위버
    '056700': 'Sinhwainteoteg', // 신화인터텍
    '056730': 'CNT85', // CNT85
    '057030': 'YBM Nes', // YBM넷
    '057540': 'Omnisiseutem', // 옴니시스템
    '057680': 'Tisaieontipig', // 티사이언티픽
    '058110': 'Megaissieseu', // 멕아이씨에스
    '058400': 'KNN', // KNN
    '058450': 'Hanjueialti', // 한주에이알티
    '058470': 'Rinogongeob', // 리노공업
    '058610': 'Eseupiji', // 에스피지
    '058630': 'Emgeim', // 엠게임
    '058820': 'CMG Pharmaceutical', // CMG제약
    '058970': 'Emro', // 엠로
    '059090': 'Miko', // 미코
    '059100': 'AIkeomponeonteu', // 아이컴포넌트
    '059120': 'Ajinegseuteg', // 아진엑스텍
    '059210': 'Meta Bio Medeu', // 메타바이오메드
    '059270': 'Haeseongeeorobotigseu', // 해성에어로보틱스
    '060150': 'Inseonienti', // 인선이엔티
    '060230': 'Jeikeisinaebseu', // 제이케이시냅스
    '060240': 'Seutakoringkeu', // 스타코링크
    '060250': 'NH N KCP', // NHN KCP
    '060260': 'Nyuboteg', // 뉴보텍
    '060280': 'Kyuregso', // 큐렉소
    '060310': '3S', // 3S
    '060370': 'LS Marinsolrusyeon', // LS마린솔루션
    '060380': 'Dongyangeseuteg', // 동양에스텍
    '060480': 'Gugilsindiang', // 국일신동
    '060540': 'Eseueiti', // 에스에이티
    '060560': 'HC Homsenta', // HC홈센타
    '060570': 'Deurimeoseukeompeoni', // 드림어스컴퍼니
    '060590': 'Ssitissi Bio', // 씨티씨바이오
    '060720': 'KH Bateg', // KH바텍
    '060850': 'Yeongrimweonsopeuteuraeb', // 영림원소프트랩
    '060900': 'Eijeonteu AI', // 에이전트AI
    '061040': 'Alepeuteg', // 알에프텍
    '061090': 'Sena Tech Nolroji', // 세나테크놀로지
    '061250': 'Hwail Pharmaceutical', // 화일약품
    '061970': 'LB Semikon', // LB세미콘
    '062970': 'Korea Ceomdansojae', // 한국첨단소재
    '063080': 'Keomtuseu Holdings', // 컴투스홀딩스
    '063170': 'Seoulogsyeon', // 서울옥션
    '063440': 'SM Life Design', // SM Life Design
    '063570': 'NICE Inpeura', // NICE인프라
    '063760': 'Ielpi', // 이엘피
    '064090': 'Inkeuredeobeulbeojeu', // 인크레더블버즈
    '064240': 'Homkaeseuteu', // 홈캐스트
    '064260': 'Danal', // 다날
    '064290': 'Integ Plus', // 인텍플러스
    '064480': 'Beurijiteg', // 브리지텍
    '064520': 'Tech El', // 테크엘
    '064550': 'Bio Nia', // 바이오니아
    '064760': 'Tissikei', // 티씨케이
    '064800': 'Poniringkeu', // 포니링크
    '064820': 'Keipeu', // 케이프
    '064850': 'Epeuaengaideu', // 에프앤가이드
    '065060': 'Jienko', // 지엔코
    '065130': 'Tabenjinieoring', // 탑엔지니어링
    '065150': 'Daesan F&B', // 대산F&B
    '065170': 'Bielpamteg', // 비엘팜텍
    '065350': 'Sinseongdelta Tech', // 신성델타테크
    '065370': 'Wiseaiteg', // 위세아이텍
    '065420': 'Eseuairisoseu', // 에스아이리소스
    '065440': 'Iruon', // 이루온
    '065450': 'Bigteg', // 빅텍
    '065500': 'Orienteujeonggong', // 오리엔트정공
    '065510': 'Hyubiceu', // 휴비츠
    '065530': 'Waieobeul', // 와이어블
    '065570': 'Samyeongienssi', // 삼영이엔씨
    '065650': 'Haipeokopeoreisyeon', // 하이퍼코퍼레이션
    '065660': 'Anteurojen', // 안트로젠
    '065680': 'Ujuilregteuro', // 우주일렉트로
    '065690': 'Pakeoseu', // 파커스
    '065710': 'Seoho Electric', // 서호전기
    '065770': 'CS', // CS
    '065950': 'Welkeuron', // 웰크론
    '066130': 'Haceu', // 하츠
    '066310': 'Kyueseuai', // 큐에스아이
    '066360': 'Ceriburo', // 체리부로
    '066410': 'Beokisseutyudio', // 버킷스튜디오
    '066430': 'AIrobotigseu', // 아이로보틱스
    '066590': 'USu AMS', // 우수AMS
    '066620': 'Gugbodinvestmentin', // 국보디자인
    '066670': 'Ditissi', // 디티씨
    '066700': 'Terajenitegseu', // 테라젠이텍스
    '066790': 'Ssissieseu', // 씨씨에스
    '066900': 'Dieipi', // 디에이피
    '066910': 'Sonogong', // 손오공
    '066980': 'Hanseongkeurinteg', // 한성크린텍
    '067000': 'Joisiti', // 조이시티
    '067010': 'Issieseu', // 이씨에스
    '067080': 'Daehwa Pharmaceutical', // 대화제약
    '067160': 'SOOP', // SOOP
    '067170': 'Oteg', // 오텍
    '067280': 'Meoltikaempeoseu', // 멀티캠퍼스
    '067290': 'JW Sinyag', // JW신약
    '067310': 'Hana Maikeuron', // 하나마이크론
    '067370': 'Seon Bio', // 선바이오
    '067390': 'Aseuteu', // 아스트
    '067570': 'Enbeuieici Korea', // 엔브이에이치코리아
    '067630': 'HLB Saengmyeonggwahag', // HLB생명과학
    '067730': 'Rojisiseu', // 로지시스
    '067770': 'Sejintieseu', // 세진티에스
    '067900': 'Waienteg', // 와이엔텍
    '067920': 'Igeulru', // 이글루
    '067990': 'Doicimoteoseu', // 도이치모터스
    '068050': 'Paenenteoteinmeonteu', // 팬엔터테인먼트
    '068100': 'Keiwedeo', // 케이웨더
    '068240': 'Daweonsiseu', // 다원시스
    '068330': 'Ilsin Bio', // 일신바이오
    '068760': 'Celltrion Pharmaceutical', // 셀트리온제약
    '068790': 'DMS', // DMS
    '068930': 'Dijiteoldaeseong', // 디지털대성
    '068940': 'Selpi Global', // 셀피글로벌
    '069080': 'Webjen', // 웹젠
    '069140': 'Nuripeulraen', // 누리플랜
    '069330': 'Yuaidi', // 유아이디
    '069410': 'Entelseu', // 엔텔스
    '069510': 'Eseuteg', // 에스텍
    '069540': 'Bicgwa Electronics', // 빛과전자
    '069920': 'Egsiongeurub', // 엑시온그룹
    '070300': 'Egseukyueo', // 엑스큐어
    '070590': 'Hansolintikyubeu', // 한솔인티큐브
    '071200': 'Inpiniteuhelseukeeo', // 인피니트헬스케어
    '071280': 'Rocesiseutemjeu', // 로체시스템즈
    '071670': 'Ei Tech Solrusyeon', // 에이테크솔루션
    '071850': 'Kaeseuteg Korea', // 캐스텍코리아
    '072020': 'Jungangbaegsin', // 중앙백신
    '072470': 'Woori Industries Holdings', // 우리산업홀딩스
    '072770': 'Memreibiti', // 멤레이비티
    '072870': 'Megaseuteodi', // 메가스터디
    '072950': 'Bicsaem Electronics', // 빛샘전자
    '072990': 'Eicisiti', // 에이치시티
    '073010': 'Keieseupi', // 케이에스피
    '073110': 'Elemeseu', // 엘엠에스
    '073190': 'Dyuobaeg', // 듀오백
    '073490': 'Inowaieoriseu', // 이노와이어리스
    '073540': 'Epeualteg', // 에프알텍
    '073560': 'Woori Sonepeuaenji', // 우리손에프앤지
    '073570': 'Rityumpoeoseu', // 리튬포어스
    '073640': 'Terasaieonseu', // 테라사이언스
    '074430': 'Aminorojigseu', // 아미노로직스
    '074600': 'Weonig Qnc', // 원익QnC
    '075130': 'Peulraentines', // 플랜티넷
    '075970': 'Dongkuk Alaeneseu', // 동국알앤에스
    '076080': 'Welkeuronhanteg', // 웰크론한텍
    '076610': 'Haeseongobtigseu', // 해성옵틱스
    '077360': 'Deogsanhaimetal', // 덕산하이메탈
    '078020': 'LS Securities', // LS증권
    '078070': 'Yubikweoseu Holdings', // 유비쿼스홀딩스
    '078130': 'Gugil Paper', // 국일제지
    '078140': 'Daebongeleseu', // 대봉엘에스
    '078150': 'HB Tech Nolreoji', // HB테크놀러지
    '078160': 'Mediposeuteu', // 메디포스트
    '078340': 'Keomtuseu', // 컴투스
    '078350': 'Hanyangdijiteg', // 한양디지텍
    '078590': 'Hyurimeiteg', // 휴림에이텍
    '078600': 'Daeju Electronics Jaeryo', // 대주전자재료
    '078860': 'Seuteijiweonenteo', // 스테이지원엔터
    '078890': 'Gaongeurub', // 가온그룹
    '079000': 'Watoseu Korea', // 와토스코리아
    '079170': 'Hancang Industries', // 한창산업
    '079190': 'Keseupion', // 케스피온
    '079370': 'Jeuseu', // 제우스
    '079650': 'Seosan', // 서산
    '079810': 'Diienti', // 디이엔티
    '079940': 'Gabia', // 가비아
    '079950': 'Inbenia', // 인베니아
    '079960': 'Dongyangienpi', // 동양이엔피
    '079970': 'Tubisopeuteu', // 투비소프트
    '080010': 'Isangneteuweogseu', // 이상네트웍스
    '080160': 'Modutueo', // 모두투어
    '080220': 'Jeju Semiconductor', // 제주반도체
    '080420': 'Modainocib', // 모다이노칩
    '080470': 'Seongcangototeg', // 성창오토텍
    '080520': 'Oditeg', // 오디텍
    '080530': 'Kodi', // 코디
    '080580': 'Okinseu Electronics', // 오킨스전자
    '080720': 'Korea Yunion Pharmaceutical', // 한국유니온제약
    '081150': 'Tipeulraegseu', // 티플랙스
    '081180': 'Ssekeu', // 쎄크
    '081580': 'Seongu Electronics', // 성우전자
    '082210': 'Obteuronteg', // 옵트론텍
    '082270': 'Jembaegseu', // 젬백스
    '082660': 'Koseunain', // 코스나인
    '082800': 'Bibojon Pharmaceutical', // 비보존 제약
    '082850': 'Woori Bio', // 우리바이오
    '082920': 'Biceurosel', // 비츠로셀
    '083310': 'Elotibekyum', // 엘오티베큠
    '083450': 'GS T', // GST
    '083470': 'Iemaenai', // 이엠앤아이
    '083500': 'Epeueneseu Tech', // 에프엔에스테크
    '083550': 'Keiem', // 케이엠
    '083640': 'Inkon', // 인콘
    '083650': 'Bieiciai', // 비에이치아이
    '083660': 'CSA Koseumig', // CSA 코스믹
    '083790': 'CG Inbaiceu', // CG인바이츠
    '083930': 'Abako', // 아바코
    '084110': 'Hyuonseu Global', // 휴온스글로벌
    '084180': 'Suseongwebtun', // 수성웹툰
    '084370': 'Eugene Tech', // 유진테크
    '084440': 'Yubion', // 유비온
    '084650': 'Raebjinomigseu', // 랩지노믹스
    '084730': 'Tingkeuweeo', // 팅크웨어
    '084850': 'AItiem Semiconductor', // 아이티엠반도체
    '084990': 'Helrigseumiseu', // 헬릭스미스
    '085660': 'Ca Bio Teg', // 차바이오텍
    '085670': 'Nyupeuregseu', // 뉴프렉스
    '085810': 'Altikaeseuteu', // 알티캐스트
    '085910': 'Neotiseu', // 네오티스
    '086040': 'Bio Togseuteg', // 바이오톡스텍
    '086060': 'Jin Bio Teg', // 진바이오텍
    '086390': 'Yuniteseuteu', // 유니테스트
    '086450': 'Dongkuk Pharmaceutical', // 동국제약
    '086520': 'Ekopeuro', // 에코프로
    '086670': 'Biemti', // 비엠티
    '086710': 'Seonjinbyutisaieonseu', // 선진뷰티사이언스
    '086820': 'Bio Solrusyeon', // 바이오솔루션
    '086890': 'Isuaebjiseu', // 이수앱지스
    '086900': 'Meditogseu', // 메디톡스
    '086960': 'MDS Tech', // MDS테크
    '086980': 'Syobagseu', // 쇼박스
    '087010': 'Pebteuron', // 펩트론
    '087260': 'Mobaileopeulraieonseu', // 모바일어플라이언스
    '087600': 'Pigsel Plus', // 픽셀플러스
    '088130': 'Dongaelteg', // 동아엘텍
    '088280': 'Ssonigseu', // 쏘닉스
    '088290': 'Iweonkeompoteg', // 이원컴포텍
    '088340': 'Yurakeul', // 유라클
    '088390': 'Inogseu', // 이녹스
    '088800': 'Eiseu Tech', // 에이스테크
    '088910': 'Dongupamtuteibeul', // 동우팜투테이블
    '089010': 'Kemteuronigseu', // 켐트로닉스
    '089030': 'Tech Wing', // 테크윙
    '089140': 'Negseuteonaenrol Korea', // 넥스턴앤롤코리아
    '089150': 'Keissiti', // 케이씨티
    '089230': 'THE E&M', // THE E&M
    '089600': 'KT Naseumidieo', // KT나스미디어
    '089790': 'Jeiti', // 제이티
    '089850': 'Yubibelrogseu', // 유비벨록스
    '089890': 'Koseseu', // 코세스
    '089970': 'Beuiem', // 브이엠
    '089980': 'Sangapeuron Tech', // 상아프론테크
    '090150': 'AIwin', // 아이윈
    '090360': 'Roboseuta', // 로보스타
    '090410': 'Deogsinipissi', // 덕신이피씨
    '090470': 'Jeiseuteg', // 제이스텍
    '090710': 'Hyurimrobos', // 휴림로봇
    '090850': 'Hyundai Ijiwel', // 현대이지웰
    '091120': 'Iemteg', // 이엠텍
    '091340': 'S&K Polriteg', // S&K폴리텍
    '091440': 'Hanulsojaegwahag', // 한울소재과학
    '091580': 'Sangsinidipi', // 상신이디피
    '091590': 'Namhwatogeon', // 남화토건
    '091700': 'Pateuron', // 파트론
    '091970': 'Nanokaemteg', // 나노캠텍
    '092040': 'Amikojen', // 아미코젠
    '092070': 'Dienepeu', // 디엔에프
    '092130': 'Ikeuredeobeul', // 이크레더블
    '092190': 'Seoul Bio Siseu', // 서울바이오시스
    '092300': 'Hyeonu Industries', // 현우산업
    '092460': 'Hanra IMS', // 한라IMS
    '092600': 'Aenssiaen', // 앤씨앤
    '092730': 'Neopam', // 네오팜
    '092870': 'Egsikon', // 엑시콘
    '093190': 'Bigsolron', // 빅솔론
    '093320': 'Keiaienegseu', // 케이아이엔엑스
    '093380': 'Punggang', // 풍강
    '093520': 'Maekeoseu', // 매커스
    '093640': 'Keialem', // 케이알엠
    '093920': 'Seoweoninteg', // 서원인텍
    '094170': 'Dongunanateg', // 동운아나텍
    '094360': 'Cibseuaenmidieo', // 칩스앤미디어
    '094480': 'Gaelreogsiameoniteuri', // 갤럭시아머니트리
    '094820': 'Iljinpaweo', // 일진파워
    '094840': 'Syupeurimaeicikyu', // 슈프리마에이치큐
    '094850': 'Camjoheunyeohaeng', // 참좋은여행
    '094860': 'Neorijin', // 네오리진
    '094940': 'Pureungisul', // 푸른기술
    '094970': 'Jeiemti', // 제이엠티
    '095190': 'Iem Korea', // 이엠코리아
    '095270': 'Weibeuilregteuro', // 웨이브일렉트로
    '095340': 'ISC', // ISC
    '095500': 'Miraenanoteg', // 미래나노텍
    '095610': 'Teseu', // 테스
    '095660': 'Neowijeu', // 네오위즈
    '095700': 'Jenegsin', // 제넥신
    '095910': 'Eseu Energy', // 에스에너지
    '096240': 'Keurebeoseu', // 크레버스
    '096250': 'Waijeuneos', // 와이즈넛
    '096350': 'Daecangsolrusyeon', // 대창솔루션
    '096530': 'Ssijen', // 씨젠
    '096610': 'Alepeusemi', // 알에프세미
    '096630': 'Eseukoneg', // 에스코넥
    '096690': 'Eiruteu', // 에이루트
    '096870': 'Elditi', // 엘디티
    '097780': 'Ekobolteu', // 에코볼트
    '097800': 'Winpaeg', // 윈팩
    '097870': 'Hyosung Oaenbi', // 효성오앤비
    '098070': 'Hanteg', // 한텍
    '098120': 'Maikeurokeontegsol', // 마이크로컨텍솔
    '098460': 'Goyeong', // 고영
    '098660': 'Eseutio', // 에스티오
    '099190': 'AIsenseu', // 아이센스
    '099220': 'SDN', // SDN
    '099320': 'Sseteuregai', // 쎄트렉아이
    '099390': 'Beureinjeukeompeoni', // 브레인즈컴퍼니
    '099410': 'Dongbangseongi', // 동방선기
    '099430': 'Bio Plus', // 바이오플러스
    '099440': 'Seumaeg', // 스맥
    '099520': 'DGI', // DGI
    '099750': 'Ijikeeoteg', // 이지케어텍
    '100030': 'Injisopeuteu', // 인지소프트
    '100120': 'Byuweogseu', // 뷰웍스
    '100130': 'Dongkuk S&C', // 동국S&C
    '100590': 'Meokyuri', // 머큐리
    '100660': 'Seoamgigyegongeob', // 서암기계공업
    '100700': 'Seunmedikal', // 세운메디칼
    '100790': 'Mirae Asset Benceotuja', // 미래에셋벤처투자
    '101000': 'KS Indeoseuteuri', // KS인더스트리
    '101160': 'Weoldegseu', // 월덱스
    '101170': 'Urimpitieseu', // 우림피티에스
    '101240': 'Ssikyubeu', // 씨큐브
    '101330': 'Mobeiseu', // 모베이스
    '101360': 'Ekoaendeurim', // 에코앤드림
    '101390': 'AIem', // 아이엠
    '101400': 'Ensiteuron', // 엔시트론
    '101490': 'Eseuaeneseuteg', // 에스앤에스텍
    '101670': 'Haideurorityum', // 하이드로리튬
    '101680': 'Korea Jeongmilgigye', // 한국정밀기계
    '101730': 'Wimeideumaegseu', // 위메이드맥스
    '101930': 'Inhwajeonggong', // 인화정공
    '101970': 'Uyangeicissi', // 우양에이치씨
    '102120': 'Eobobeu Semiconductor', // 어보브반도체
    '102370': 'Keiogsyeon', // 케이옥션
    '102710': 'Ienepeu Tech Nolroji', // 이엔에프테크놀로지
    '102940': 'Kolon Saengmyeonggwahag', // 코오롱생명과학
    '103230': 'Eseuaendeobeulryu', // 에스앤더블류
    '103840': 'Uyang', // 우양
    '104040': 'Daeseongpainteg', // 대성파인텍
    '104200': 'NH N Beogseu', // NHN벅스
    '104460': 'Diwaipienepeu', // 디와이피엔에프
    '104480': 'Tikei Chemical', // 티케이케미칼
    '104540': 'Korenteg', // 코렌텍
    '104620': 'Norangpungseon', // 노랑풍선
    '104830': 'Weonigmeoteurieoljeu', // 원익머트리얼즈
    '105330': 'Keiendeobeulyu', // 케이엔더블유
    '105550': 'Esjipaundeuri', // 엣지파운드리
    '105740': 'Dikeirag', // 디케이락
    '105760': 'Poseubaengkeu', // 포스뱅크
    '106080': 'Keiiemteg', // 케이이엠텍
    '106190': 'Haitegpam', // 하이텍팜
    '106240': 'Pain Technics', // 파인테크닉스
    '106520': 'Nobeulemaenbi', // 노블엠앤비
    '107600': 'Saebiskem', // 새빗켐
    '107640': 'Hanjungensieseu', // 한중엔시에스
    '108230': 'Tobteg', // 톱텍
    '108380': 'Daeyang Electric Gongeob', // 대양전기공업
    '108490': 'Robotijeu', // 로보티즈
    '108860': 'Selbaseu AI', // 셀바스AI
    '109080': 'Obtisiseu', // 옵티시스
    '109610': 'Eseuwai', // 에스와이
    '109670': 'Ssissaiteu', // 씨싸이트
    '109740': 'Dieseukei', // 디에스케이
    '109820': 'Jinmaeteurigseu', // 진매트릭스
    '109860': 'Dongilgeumsog', // 동일금속
    '109960': 'Aebtokeurom', // 앱토크롬
    '110020': 'Jeonjin Bio Pam', // 전진바이오팜
    '110790': 'Keuriseuepeuaenssi', // 크리스에프앤씨
    '110990': 'Diaiti', // 디아이티
    '111710': 'Namhwa Industries', // 남화산업
    '112040': 'Wimeideu', // 위메이드
    '112290': 'Waissikem', // 와이씨켐
    '113810': 'Dijenseu', // 디젠스
    '114190': 'Gangweon Energy', // 강원에너지
    '114450': 'Geurinsaengmyeonggwahag', // 그린생명과학
    '114630': 'Polrariseuuno', // 폴라리스우노
    '114810': 'Hansolaiweonseu', // 한솔아이원스
    '114840': 'AIpaemilrieseussi', // 아이패밀리에스씨
    '115160': 'Hyumaegseu', // 휴맥스
    '115180': 'Kyurieonteu', // 큐리언트
    '115310': 'Inpobain', // 인포바인
    '115440': 'Woori Nes', // 우리넷
    '115450': 'HLB Terapyutigseu', // HLB테라퓨틱스
    '115480': 'Ssiyumedikal', // 씨유메디칼
    '115500': 'Keissieseu', // 케이씨에스
    '115530': 'Ssien Plus', // 씨엔플러스
    '115570': 'Seutapeulregseu', // 스타플렉스
    '115610': 'Imijiseu', // 이미지스
    '117670': 'Alpacibseu', // 알파칩스
    '117730': 'Tirobotigseu', // 티로보틱스
    '118990': 'Moteuregseu', // 모트렉스
    '119500': 'Pometal', // 포메탈
    '119610': 'Inteorojo', // 인터로조
    '119830': 'AIteg', // 아이텍
    '119850': 'Jienssi Energy', // 지엔씨에너지
    '120240': 'Daejeonghwageum', // 대정화금
    '121440': 'Golpeujon Holdings', // 골프존홀딩스
    '121600': 'Nanosinsojae', // 나노신소재
    '121800': 'Bidenteu', // 비덴트
    '121850': 'Koijeu', // 코이즈
    '121890': 'Eseudisiseutem', // 에스디시스템
    '122310': 'Jenorei', // 제노레이
    '122350': 'Samgi', // 삼기
    '122450': 'KX', // KX
    '122640': 'Yeseuti', // 예스티
    '122690': 'Seojinotomotibeu', // 서진오토모티브
    '122870': 'Waijienteoteinmeonteu', // 와이지엔터테인먼트
    '122990': 'Waisol', // 와이솔
    '123010': 'Alentiegseu', // 알엔티엑스
    '123040': 'Emeseuototeg', // 엠에스오토텍
    '123330': 'Jenig', // 제닉
    '123410': 'Korea Epeuti', // 코리아에프티
    '123420': 'Wimeideupeulrei', // 위메이드플레이
    '123570': 'Iemnes', // 이엠넷
    '123750': 'Alton', // 알톤
    '123840': 'Nyuon', // 뉴온
    '123860': 'Anapaeseu', // 아나패스
    '124500': 'AItisen Global', // 아이티센글로벌
    '124560': 'Taeungrojigseu', // 태웅로직스
    '125020': 'Tissimeotirieoljeu', // 티씨머티리얼즈
    '125210': 'Amogeurinteg', // 아모그린텍
    '125490': 'Hanrakaeseuteu', // 한라캐스트
    '126340': 'Binateg', // 비나텍
    '126600': 'BGF Ekomeotirieoljeu', // BGF에코머티리얼즈
    '126640': 'Hwasinjeonggong', // 화신정공
    '126700': 'Haibijyeonsiseutem', // 하이비젼시스템
    '126730': 'Kocib', // 코칩
    '126880': 'Jeienkei Global', // 제이엔케이글로벌
    '127120': 'Jeieseuringkeu', // 제이에스링크
    '127710': 'Asiagyeongje', // 아시아경제
    '127980': 'Hwainsseokiteu', // 화인써키트
    '128540': 'Ekokaeb', // 에코캡
    '128660': 'Pijeimetal', // 피제이메탈
    '129890': 'Aebko', // 앱코
    '129920': 'Daeseonghaiteg', // 대성하이텍
    '130500': 'GH Sinsojae', // GH신소재
    '130580': 'Naiseudiaenbi', // 나이스디앤비
    '130740': 'Tipissi Global', // 티피씨글로벌
    '131030': 'Obtuseu Pharmaceutical', // 옵투스제약
    '131090': 'Sikyubeu', // 시큐브
    '131100': 'Tienenteoteinmeonteu', // 티엔엔터테인먼트
    '131180': 'Dilri', // 딜리
    '131220': 'Korea Gwahag', // 대한과학
    '131290': 'Tieseui', // 티에스이
    '131370': 'Alseopoteu', // 알서포트
    '131400': 'Ibeuiceomdansojae', // 이브이첨단소재
    '131760': 'Painteg', // 파인텍
    '131970': 'Doosan Teseuna', // 두산테스나
    '133750': 'Megaemdi', // 메가엠디
    '134060': 'Ipyucyeo', // 이퓨쳐
    '134580': 'Tabkomidieo', // 탑코미디어
    '136150': 'Weoniltienai', // 원일티엔아이
    '136410': 'Asemseu', // 아셈스
    '136480': 'Harim', // 하림
    '136540': 'Winseu Tech Nes', // 윈스테크넷
    '137080': 'Naraenanoteg', // 나래나노텍
    '137400': 'Pienti', // 피엔티
    '137940': 'Negseuteuai', // 넥스트아이
    '137950': 'Jeissi Chemical', // 제이씨케미칼
    '138070': 'Sinjineseuem', // 신진에스엠
    '138080': 'Oisolrusyeon', // 오이솔루션
    '138360': 'Aenrobotigseu', // 앤로보틱스
    '138610': 'Naibeg', // 나이벡
    '139050': 'BF Raebseu', // BF랩스
    '139670': 'Kinemaseuteo', // 키네마스터
    '140070': 'Seo Plus Global', // 서플러스글로벌
    '140410': 'Mejion', // 메지온
    '140430': 'Katiseu', // 카티스
    '140520': 'Daecangseutil', // 대창스틸
    '140670': 'Aleseuotomeisyeon', // 알에스오토메이션
    '140860': 'Pakeusiseutemseu', // 파크시스템스
    '141000': 'Biateuron', // 비아트론
    '141080': 'Rigakem Bio', // 리가켐바이오
    '142210': 'Yuniteuronteg', // 유니트론텍
    '142280': 'GC Emeseu', // 녹십자엠에스
    '142760': 'Moaraipeu Plus', // 모아라이프플러스
    '143160': 'AIdiseu', // 아이디스
    '143240': 'Saramin', // 사람인
    '143540': 'Yeongudieseupi', // 영우디에스피
    '144510': 'Jissisel', // 지씨셀
    '144960': 'Nyupaweopeurajeuma', // 뉴파워프라즈마
    '145020': 'Hyujel', // 휴젤
    '145170': 'Nobeuraendeu', // 노브랜드
    '146060': 'Yulcon', // 율촌
    '146320': 'Bissienssi', // 비씨엔씨
    '147760': 'Piemti', // 피엠티
    '147830': 'Jeryong Industries', // 제룡산업
    '148150': 'Segyeonghai Tech', // 세경하이테크
    '148250': 'Alentu Tech Nolroji', // 알엔투테크놀로지
    '148780': 'Bikyu AI', // 비큐AI
    '148930': 'Eiciwaitissi', // 에이치와이티씨
    '149950': 'Abateg', // 아바텍
    '149980': 'Haironig', // 하이로닉
    '150900': 'Pasu', // 파수
    '151860': 'KG Ekosolrusyeon', // KG에코솔루션
    '153460': 'Neibeul', // 네이블
    '153490': 'Woori Iaenel', // 우리이앤엘
    '153710': 'Obtipam', // 옵티팜
    '154030': 'Asiajongmyo', // 아시아종묘
    '154040': 'Dasansolrueta', // 다산솔루에타
    '155650': 'Waiemssi', // 와이엠씨
    '156100': 'Elaenkei Bio', // 엘앤케이바이오
    '158430': 'Aton', // 아톤
    '159010': 'Aseupeulro', // 아스플로
    '159580': 'Jerotusebeun', // 제로투세븐
    '159910': 'Ekogeulro Pref', // 에코글로우
    '160190': 'Haijenalaenem', // 하이젠알앤엠
    '160550': 'NEW', // NEW
    '160980': 'Ssaimaegseu', // 싸이맥스
    '161580': 'Pilobtigseu', // 필옵틱스
    '162300': 'Sinseutil', // 신스틸
    '163280': 'Eeorein', // 에어레인
    '163730': 'Pinggeo', // 핑거
    '166090': 'Hana Meotirieoljeu', // 하나머티리얼즈
    '166480': 'Koaseutemkemon', // 코아스템켐온
    '168330': 'Naecyureolendoteg', // 내츄럴엔도텍
    '168360': 'Pemteuron', // 펨트론
    '169330': 'Embeurein', // 엠브레인
    '170030': 'Hyundai Gongeob', // 현대공업
    '170790': 'Paioringkeu', // 파이오링크
    '170920': 'Eltissi', // 엘티씨
    '171010': 'Raem Tech Nolreoji', // 램테크놀러지
    '171090': 'Seonigsiseutem', // 선익시스템
    '171120': 'Raionkemteg', // 라이온켐텍
    '172670': 'Eielti', // 에이엘티
    '173130': 'Opaseunes', // 오파스넷
    '173940': 'Epeuenssienteo', // 에프엔씨엔터
    '174900': 'Aebkeulron', // 앱클론
    '175140': 'Hyumeon Tech Nolroji', // 휴먼테크놀로지
    '175250': 'AIkyueo', // 아이큐어
    '176750': 'Dyukem Bio', // 듀켐바이오
    '177350': 'Besel', // 베셀
    '177830': 'Pabeonain', // 파버나인
    '177900': 'Sseurieirojigseu', // 쓰리에이로직스
    '178320': 'Seojinsiseutem', // 서진시스템
    '178780': 'Ilweoljiemel', // 일월지엠엘
    '179290': 'Emaiteg', // 엠아이텍
    '179530': 'Aedeu Bio Teg', // 애드바이오텍
    '179900': 'Yutiai', // 유티아이
    '180400': 'DXVX', // DXVX
    '182360': 'Kyubeuenteo', // 큐브엔터
    '182400': 'Enkeijen Bio Teg Korea', // 엔케이젠바이오텍코리아
    '183300': 'Komiko', // 코미코
    '183490': 'Enjikemsaengmyeonggwahag', // 엔지켐생명과학
    '184230': 'SGA Solrusyeonjeu', // SGA솔루션즈
    '185490': 'AIjin', // 아이진
    '186230': 'Geurin Plus', // 그린플러스
    '187220': 'Ditiaenssi', // 디티앤씨
    '187270': 'Sinhwakonteg', // 신화콘텍
    '187420': 'HLB Jenegseu', // HLB제넥스
    '187660': 'Peniteurium Bio', // 페니트리움바이오
    '187790': 'Nano', // 나노
    '187870': 'Dibaiseu', // 디바이스
    '188040': 'Bio Poteu', // 바이오포트
    '188260': 'Senijen', // 세니젠
    '189300': 'Intelrian Tech', // 인텔리안테크
    '189330': 'Ssiiraeb', // 씨이랩
    '189690': 'Posieseu', // 포시에스
    '189860': 'Seo Electric Jeon', // 서전기전
    '189980': 'Heunggugepeuenbi', // 흥국에프엔비
    '190510': 'Namuga', // 나무가
    '190650': 'Korea Asset Investment & Securities', // 코리아에셋투자증권
    '191410': 'Yugilssienesseu', // 육일씨엔에쓰
    '191420': 'Tegosaieonseu', // 테고사이언스
    '192250': 'Keisain', // 케이사인
    '192390': 'Winhaiteg', // 윈하이텍
    '192410': 'Oneulienem', // 오늘이엔엠
    '192440': 'Syupigen Korea', // 슈피겐코리아
    '193250': 'Ringkeudeu', // 링크드
    '194480': 'Debeusiseuteojeu', // 데브시스터즈
    '194700': 'Nobaregseu', // 노바렉스
    '195500': 'Manikeoepeuaenji', // 마니커에프앤지
    '195940': 'HK Inoen', // HK이노엔
    '195990': 'Eibipeuro Bio', // 에이비프로바이오
    '196170': 'Alteojen', // 알테오젠
    '196300': 'HLB Peb', // HLB펩
    '196450': 'Koasiassiem', // 코아시아씨엠
    '196490': 'Diei Tech Nolroji', // 디에이테크놀로지
    '196700': 'Webseu', // 웹스
    '197140': 'Dijikaeb', // 디지캡
    '198080': 'Kaepeu', // 캐프
    '198440': 'Gangdongssiaenel', // 강동씨앤엘
    '198940': 'Hanjuraiteumetal', // 한주라이트메탈
    '199430': 'Keienalsiseutem', // 케이엔알시스템
    '199480': 'Baengkeuweeo Global', // 뱅크웨어글로벌
    '199550': 'Reijeoobteg', // 레이저옵텍
    '199730': 'Bio Inpeura', // 바이오인프라
    '199800': 'Tuljen', // 툴젠
    '199820': 'Jeililregteurig', // 제일일렉트릭
    '200130': 'Kolmabiaeneici', // 콜마비앤에이치
    '200230': 'Telkon RF Pharmaceutical', // 텔콘RF제약
    '200350': 'Atiseuteuseutyudio', // 아티스트스튜디오
    '200470': 'Eipaegteu', // 에이팩트
    '200670': 'Hyumedigseu', // 휴메딕스
    '200710': 'Eidi Tech Nolroji', // 에이디테크놀로지
    '200780': 'Bissiweoldeu Pharmaceutical', // 비씨월드제약
    '201490': 'Mituon', // 미투온
    '203400': 'Eibion', // 에이비온
    '203450': 'Yunion Bio Meteurigseu', // 유니온바이오메트릭스
    '203650': 'Deurimsikyuriti', // 드림시큐리티
    '203690': 'Akeusolrusyeonseu', // 아크솔루션스
    '204020': 'Geuriti', // 그리티
    '204270': 'Jeiaentissi', // 제이앤티씨
    '204610': 'Tisseuri', // 티쓰리
    '204620': 'Global Tegseupeuri', // 글로벌텍스프리
    '204840': 'Jielpamteg', // 지엘팜텍
    '205100': 'Egsem', // 엑셈
    '205470': 'Hyumasiseu', // 휴마시스
    '205500': 'Negsseosseu', // 넥써쓰
    '206400': 'Benotiaenal', // 베노티앤알
    '206560': 'Degseuteo', // 덱스터
    '206640': 'Baditegmedeu', // 바디텍메드
    '206650': 'Yu Biologics', // 유바이오로직스
    '207760': 'Miseuteobeulru', // 미스터블루
    '208140': 'Jeongdaun', // 정다운
    '208350': 'Jiranjigyosikyuriti', // 지란지교시큐리티
    '208370': 'Selbaseuhelseukeeo', // 셀바스헬스케어
    '208640': 'Sseomeiji', // 썸에이지
    '208710': 'Poton', // 포톤
    '208860': 'Dasandiemssi', // 다산디엠씨
    '209640': 'Waijeiringkeu', // 와이제이링크
    '210120': 'Kaenbeoseuen', // 캔버스엔
    '211050': 'Inka Financial Seobiseu', // 인카금융서비스
    '211270': 'AP Wiseong', // AP위성
    '212560': 'Neooto', // 네오오토
    '212710': 'AIeseutii', // 아이에스티이
    '213420': 'Deogsanneorugseu', // 덕산네오룩스
    '214150': 'Keulraesiseu', // 클래시스
    '214180': 'Hegto Innovation', // 헥토이노베이션
    '214260': 'Rapaseu', // 라파스
    '214270': 'FSN', // FSN
    '214370': 'Keeojen', // 케어젠
    '214430': 'AIsseurisiseutem', // 아이쓰리시스템
    '214450': 'Pamariseoci', // 파마리서치
    '214610': 'Rolringseuton', // 롤링스톤
    '214680': 'Dialteg', // 디알텍
    '215000': 'Golpeujon', // 골프존
    '215090': 'Soldipenseu', // 솔디펜스
    '215100': 'Roborobo', // 로보로보
    '215200': 'Megaseuteodigyoyug', // 메가스터디교육
    '215360': 'Woori Industries', // 우리산업
    '215380': 'Ujeong Bio', // 우정바이오
    '215480': 'Tobagseu Korea', // 토박스코리아
    '215600': 'Sinrajen', // 신라젠
    '215790': 'Inoinseuteurumeonteu', // 이노인스트루먼트
    '216050': 'Inkeuroseu', // 인크로스
    '216080': 'Jetema', // 제테마
    '217190': 'Jeneosem', // 제너셈
    '217270': 'Nebtyun', // 넵튠
    '217330': 'Ssaitojen', // 싸이토젠
    '217480': 'Eseudisaengmyeonggonghag', // 에스디생명공학
    '217500': 'Reosel', // 러셀
    '217620': 'Seonsyainpudeu', // 선샤인푸드
    '217730': 'Gangseutem Bio Teg', // 강스템바이오텍
    '217820': 'Weonigpiaeni', // 원익피앤이
    '218150': 'Miraesaengmyeongjaweon', // 미래생명자원
    '218410': 'RFHIC', // RFHIC
    '219130': 'Taigeoilreg', // 타이거일렉
    '219420': 'Ringkeujenisiseu', // 링크제니시스
    '219550': 'Diwaidi', // 디와이디
    '219750': 'Korea Bitibi', // 한국비티비
    '220100': 'Pyucyeokem', // 퓨쳐켐
    '220180': 'Haendisopeuteu', // 핸디소프트
    '220260': 'Kemteuroseu', // 켐트로스
    '221800': 'Yutu Bio', // 유투바이오
    '221840': 'Haijeu AIr', // 하이즈항공
    '221980': 'Keidikem', // 케이디켐
    '222040': 'Koseumaegseuenbiti', // 코스맥스엔비티
    '222080': 'Ssiaieseu', // 씨아이에스
    '222110': 'Paenjen', // 팬젠
    '222160': 'NPX', // NPX
    '222420': 'Ssenoteg', // 쎄노텍
    '222800': 'Simteg', // 심텍
    '222980': 'Korea Maegneolti', // 한국맥널티
    '223250': 'Deurimssiaieseu', // 드림씨아이에스
    '223310': 'Satosi Holdings', // 사토시홀딩스
    '224060': 'Deokodi', // 더코디
    '224110': 'Eiteg Mobility', // 에이텍모빌리티
    '225190': 'LK Samyang', // LK삼양
    '225220': 'Jenolrusyeon', // 제놀루션
    '225430': 'Keiem Pharmaceutical', // 케이엠제약
    '225530': 'HC Bogwang Industries', // HC보광산업
    '225570': 'Negseungeimjeu', // 넥슨게임즈
    '225590': 'Paesyeonpeulraespom', // 패션플랫폼
    '226330': 'Sinteka Bio', // 신테카바이오
    '226340': 'Bonneu', // 본느
    '226400': 'Oseuteonig', // 오스테오닉
    '226590': 'Emdibaiseu', // 엠디바이스
    '226950': 'Olrigseu', // 올릭스
    '227100': 'Peurobeuis', // 프로브잇
    '227610': 'Audinpyucyeoseu', // 아우딘퓨쳐스
    '227950': 'Entuteg', // 엔투텍
    '228340': 'Dongyangpail', // 동양파일
    '228670': 'Rei', // 레이
    '228760': 'Jinomigteuri', // 지노믹트리
    '228850': 'Reieonseu', // 레이언스
    '229000': 'Jenkyurigseu', // 젠큐릭스
    '230240': 'Eciepeual', // 에치에프알
    '230360': 'Ekomaketing', // 에코마케팅
    '230980': 'Biyu Tech Nolreoji', // 비유테크놀러지
    '232140': 'Waissi', // 와이씨
    '232680': 'Raonrobotigseu', // 라온로보틱스
    '232830': 'AItisenpieneseu', // 아이티센피엔에스
    '234030': 'Ssainigsolrusyeon', // 싸이닉솔루션
    '234100': 'Polrariseuseweon', // 폴라리스세원
    '234300': 'Eseuteuraepig', // 에스트래픽
    '234340': 'Hegtopainaensyeol', // 헥토파이낸셜
    '234690': 'GC Welbing', // 녹십자웰빙
    '234920': 'Jaigeul', // 자이글
    '235980': 'Medeupaegto', // 메드팩토
    '236200': 'Syupeurima', // 슈프리마
    '236810': 'Enbiti', // 엔비티
    '237690': 'Eseutipam', // 에스티팜
    '237750': 'Piaenssi Tech', // 피앤씨테크
    '237820': 'Peulreidi', // 플레이디
    '237880': 'Keulrio', // 클리오
    '238090': 'Aendiposeu', // 앤디포스
    '238120': 'Eolraindeu', // 얼라인드
    '238200': 'Bipido', // 비피도
    '238490': 'Himseu', // 힘스
    '239340': 'Iseuteueideu', // 이스트에이드
    '239610': 'Eicielsaieonseu', // 에이치엘사이언스
    '239890': 'Pieneici Tech', // 피엔에이치테크
    '240550': 'Dongbang Medical', // 동방메디컬
    '240600': 'Eugene Tech Nolroji', // 유진테크놀로지
    '240810': 'Weonig IPS', // 원익IPS
    '241520': 'DSC Inbeseuteumeonteu', // DSC인베스트먼트
    '241690': 'Yuni Tech No', // 유니테크노
    '241710': 'Koseumeka Korea', // 코스메카코리아
    '241770': 'Mekaro', // 메카로
    '241790': 'Tiiemssi CNS', // 티이엠씨씨엔에스
    '241820': 'Pissiel', // 피씨엘
    '241840': 'Eiseutori', // 에이스토리
    '242040': 'Namugisul', // 나무기술
    '243070': 'Hyuonseu', // 휴온스
    '243840': 'Sinheungeseuissi', // 신흥에스이씨
    '244460': 'Olripaeseu', // 올리패스
    '245620': 'EDGC', // EDGC
    '246250': 'Eseueleseu Bio', // 에스엘에스바이오
    '246690': 'TS Inbeseuteumeonteu', // TS인베스트먼트
    '246710': 'Tiaenal Bio Paeb', // 티앤알바이오팹
    '246720': 'Aseuta', // 아스타
    '246960': 'SCL Saieonseu', // SCL사이언스
    '247540': 'Ekopeurobiem', // 에코프로비엠
    '247660': 'Nanossiemeseu', // 나노씨엠에스
    '250000': 'Boratial', // 보라티알
    '250060': 'Mobis', // 모비스
    '250930': 'Yeseon Tech', // 예선테크
    '251120': 'Bio Epeudienssi', // 바이오에프디엔씨
    '251370': 'Waiemti', // 와이엠티
    '251630': 'Beuiweonteg', // 브이원텍
    '251970': 'Peomteg Korea', // 펌텍코리아
    '252500': 'Sehwapiaenssi', // 세화피앤씨
    '252990': 'Saem CNS', // 샘씨엔에스
    '253450': 'Seutyudiodeuraegon', // 스튜디오드래곤
    '253590': 'Neosem', // 네오셈
    '253840': 'Sujenteg', // 수젠텍
    '254120': 'Jabiseu', // 자비스
    '254490': 'Mirae Semiconductor', // 미래반도체
    '255220': 'SG', // SG
    '255440': 'Yaseu', // 야스
    '256150': 'Handogkeurinteg', // 한독크린텍
    '256630': 'Pointeuenjinieoring', // 포인트엔지니어링
    '256840': 'Korea Bienssi', // 한국비엔씨
    '256940': 'Kibseupama', // 킵스파마
    '257370': 'Pientiemeseu', // 피엔티엠에스
    '257720': 'Silrikontu', // 실리콘투
    '258610': 'Keilreom', // 케일럼
    '258790': 'Sopeuteukaempeu', // 소프트캠프
    '258830': 'Sejongmedikal', // 세종메디칼
    '259630': 'Em Plus', // 엠플러스
    '260660': 'Alriko Pharmaceutical', // 알리코제약
    '260930': 'Ssitikei', // 씨티케이
    '260970': 'Eseuaendi', // 에스앤디
    '261200': 'Dentiseu', // 덴티스
    '261520': 'Ijiseu', // 이지스
    '261780': 'Cabaegsinyeonguso', // 차백신연구소
    '262260': 'Eipeuro', // 에이프로
    '262840': 'AIkweseuteu', // 아이퀘스트
    '263020': 'Dikeiaendi', // 디케이앤디
    '263050': 'Yutilregseu', // 유틸렉스
    '263600': 'Deogu Electronics', // 덕우전자
    '263690': 'Dialjem', // 디알젬
    '263700': 'Keeoraebseu', // 케어랩스
    '263720': 'Diaenssimidieo', // 디앤씨미디어
    '263750': 'Peoleobiseu', // 펄어비스
    '263770': 'Yueseuti', // 유에스티
    '263800': 'Deitasolrusyeon', // 데이타솔루션
    '263810': 'Sangsin Electronics', // 상신전자
    '263860': 'Jinieonseu', // 지니언스
    '263920': 'Hyuemaenssi', // 휴엠앤씨
    '264450': 'Yubikweoseu', // 유비쿼스
    '264660': 'Ssiaenjihai Tech', // 씨앤지하이테크
    '264850': 'Iraensiseu', // 이랜시스
    '265520': 'AP Siseutem', // AP시스템
    '265560': 'Yeonghwa Tech', // 영화테크
    '265740': 'Enepeussi', // 엔에프씨
    '267320': 'Nain Tech', // 나인테크
    '267790': 'Baereol', // 배럴
    '267980': 'Maeilyueob', // 매일유업
    '269620': 'Siseuweog', // 시스웍
    '270520': 'Aebteun', // 앱튼
    '270660': 'Ebeuribos', // 에브리봇
    '270870': 'Nyuteuri', // 뉴트리
    '271830': 'Paemteg', // 팸텍
    '272110': 'Keienjei', // 케이엔제이
    '272290': 'Inogseuceomdansojae', // 이녹스첨단소재
    '273060': 'Waijeubeojeu', // 와이즈버즈
    '273640': 'Waiemteg', // 와이엠텍
    '274090': 'Kenkoaeeoroseupeiseu', // 켄코아에어로스페이스
    '274400': 'Inosimyulreisyeon', // 이노시뮬레이션
    '275630': 'Eseueseual', // 에스에스알
    '276040': 'Seukoneg', // 스코넥
    '276730': 'Hanulaenjeju', // 한울앤제주
    '277070': 'Rindeumeonasia', // 린드먼아시아
    '277410': 'Insanga', // 인산가
    '277810': 'Reinbourobotigseu', // 레인보우로보틱스
    '277880': 'Tieseuai', // 티에스아이
    '278280': 'Ceonbo', // 천보
    '278650': 'HLB Bio Seuteb', // HLB바이오스텝
    '279600': 'Midieojen', // 미디어젠
    '281740': 'Reikeumeotirieoljeu', // 레이크머티리얼즈
    '282720': 'Geumyanggeurinpaweo', // 금양그린파워
    '282880': 'Kowin Tech', // 코윈테크
    '284620': 'Kainoseumedeu', // 카이노스메드
    '285490': 'Nobateg', // 노바텍
    '285800': 'Jinyeong', // 진영
    '286750': 'Nanosilrikanceomdansojae', // 나노실리칸첨단소재
    '287840': 'Intusel', // 인투셀
    '288330': 'Parataegsiseu Korea', // 파라택시스코리아
    '288620': 'Eseupyueolsel', // 에스퓨얼셀
    '288980': 'Moadeita', // 모아데이타
    '289010': 'AIseukeurimedyu', // 아이스크림에듀
    '289080': 'SV Inbeseuteumeonteu', // SV인베스트먼트
    '289220': 'Jaieonteuseuteb', // 자이언트스텝
    '289930': 'Weibiseu', // 웨이비스
    '290090': 'Teuwim', // 트윔
    '290120': 'DH Otorideu', // DH오토리드
    '290270': 'Hyunesion', // 휴네시온
    '290520': 'Sindiagiyeon', // 신도기연
    '290550': 'Dikeiti', // 디케이티
    '290560': 'Parataegsiseuideorium', // 파라택시스이더리움
    '290650': 'Elaenssi Bio', // 엘앤씨바이오
    '290660': 'Neopegteu', // 네오펙트
    '290670': 'Daebomageunetig', // 대보마그네틱
    '290690': 'Sorugseu', // 소룩스
    '290720': 'Pudeunamu', // 푸드나무
    '290740': 'Aegteuro', // 액트로
    '291230': 'Enpi', // 엔피
    '291650': 'Abtameosaieonseu', // 압타머사이언스
    '291810': 'Pintel', // 핀텔
    '293490': 'Kakao Geimjeu', // 카카오게임즈
    '293580': 'Nau IB', // 나우IB
    '293780': 'Abta Bio', // 압타바이오
    '294090': 'Iopeulro Pref', // 이오플로우
    '294140': 'Remon', // 레몬
    '294570': 'Kukon', // 쿠콘
    '294630': 'Seonam', // 서남
    '295310': 'Eicibeuiem', // 에이치브이엠
    '296640': 'Inorulseu', // 이노룰스
    '297090': 'Ssieseubeeoring', // 씨에스베어링
    '297570': 'Alroiseu', // 알로이스
    '297890': 'HB Solrusyeon', // HB솔루션
    '298060': 'Eseussiemsaengmyeonggwahag', // 에스씨엠생명과학
    '298380': 'Eibiel Bio', // 에이비엘바이오
    '298540': 'Deoneicyeo Holdings', // 더네이쳐홀딩스
    '298830': 'Syueosopeuteu Tech', // 슈어소프트테크
    '299030': 'Hana Gisul', // 하나기술
    '299170': 'Deobeulyueseuai', // 더블유에스아이
    '299660': 'Selrideu', // 셀리드
    '299900': 'Wijiwigseutyudio', // 위지윅스튜디오
    '300080': 'Peulrito', // 플리토
    '300120': 'Raonpipeul', // 라온피플
    '301300': 'Baibeukeompeoni', // 바이브컴퍼니
    '302430': 'Inometeuri', // 이노메트리
    '302550': 'Rimedeu', // 리메드
    '303030': 'Jinitigseu', // 지니틱스
    '303360': 'Peurotia', // 프로티아
    '303530': 'Inodeb', // 이노뎁
    '303810': 'Dongkuk Saengmyeonggwahag', // 동국생명과학
    '304100': 'Solteurugseu', // 솔트룩스
    '304360': 'Eseu Bio Medigseu', // 에스바이오메딕스
    '304840': 'Pipeul Bio', // 피플바이오
    '305090': 'Maikeurodijital', // 마이크로디지탈
    '306040': 'Eseujeigeurub', // 에스제이그룹
    '306620': 'Jiaieseu', // 지아이에스
    '307180': 'AIel', // 아이엘
    '307280': 'Weon Bio Jen', // 원바이오젠
    '307750': 'Gugjeon Pharmaceutical', // 국전약품
    '307870': 'Bituen', // 비투엔
    '307930': 'Keompeonikei', // 컴퍼니케이
    '308080': 'Baijensel', // 바이젠셀
    '308100': 'Hyeongji Global', // 형지글로벌
    '308430': 'Selbion', // 셀비온
    '309710': 'AItikem', // 아이티켐
    '309930': 'Joiweogseuaenko', // 조이웍스앤코
    '309960': 'LB Inbeseuteumeonteu', // LB인베스트먼트
    '310200': 'Aeni Plus', // 애니플러스
    '310210': 'Boronoi', // 보로노이
    '310870': 'Diwaissi', // 디와이씨
    '311320': 'Jioelrimeonteu', // 지오엘리먼트
    '311390': 'Neokeurema', // 네오크레마
    '311690': 'CJ Bioscience', // CJ 바이오사이언스
    '312610': 'Eiepeudeobeulryu', // 에이에프더블류
    '313760': 'Kaeri', // 캐리
    '314130': 'Jinomaenkeompeoni', // 지놈앤컴퍼니
    '314140': 'Alpi Bio', // 알피바이오
    '314930': 'Bio Dain', // 바이오다인
    '315640': 'Dibnoideu', // 딥노이드
    '317120': 'Ranigseu', // 라닉스
    '317240': 'TS Teurilrion', // TS트릴리온
    '317330': 'Deogsantekopia', // 덕산테코피아
    '317530': 'Kaerisopeuteu', // 캐리소프트
    '317690': 'Kweontamaeteurigseu', // 퀀타매트릭스
    '317770': 'Egseuperigseu', // 엑스페릭스
    '317830': 'Eseupisiseutemseu', // 에스피시스템스
    '317850': 'Daemo', // 대모
    '317870': 'En Bio Nia', // 엔바이오니아
    '318000': 'KB G', // KBG
    '318010': 'Pamseubil', // 팜스빌
    '318020': 'Pointeumobail', // 포인트모바일
    '318060': 'Geuraepi', // 그래피
    '318160': 'Sel Bio Hyumeonteg', // 셀바이오휴먼텍
    '318410': 'Bibissi', // 비비씨
    '319400': 'Hyundai Mubegseu', // 현대무벡스
    '319660': 'Pieseukei', // 피에스케이
    '320000': 'Hanul Semiconductor', // 한울반도체
    '321260': 'Peuroiceon', // 프로이천
    '321370': 'Senseobyu', // 센서뷰
    '321550': 'Tium Bio', // 티움바이오
    '321820': 'Atiseuteukeompeoni', // 아티스트컴퍼니
    '322180': 'LS Tirayuteg', // LS티라유텍
    '322310': 'Oroseu Tech Nolroji', // 오로스테크놀로지
    '322510': 'Jeielkei', // 제이엘케이
    '322780': 'Kopeoseu Korea', // 코퍼스코리아
    '323280': 'Taeseong', // 태성
    '323350': 'Daweonnegseubyu', // 다원넥스뷰
    '323990': 'Bagsel Bio', // 박셀바이오
    '327260': 'RF Meoteurieoljeu', // RF머트리얼즈
    '328130': 'Runis', // 루닛
    '328380': 'Solteuweeo', // 솔트웨어
    '330350': 'Wideoseu Pharmaceutical', // 위더스제약
    '330730': 'Seutonbeurisjibenceoseu', // 스톤브릿지벤처스
    '330860': 'Nepaeseuakeu', // 네패스아크
    '331380': 'Focus Eiai', // 포커스에이아이
    '331520': 'Baelropeu', // 밸로프
    '331740': 'Autokeuribteu', // 아우토크립트
    '331920': 'Selremigseu', // 셀레믹스
    '332290': 'Nubo', // 누보
    '332370': 'AIdipi', // 아이디피
    '332570': 'PS Ilregteuronigseu', // PS일렉트로닉스
    '333050': 'Mokoemsiseu', // 모코엠시스
    '333430': 'Ilseung', // 일승
    '333620': 'Ensiseu', // 엔시스
    '334970': 'Peureseutiji Biologics', // 프레스티지바이오로직스
    '335810': 'Peurisijyeon Bio', // 프리시젼바이오
    '335870': 'Wingseupus', // 윙스풋
    '336060': 'Weibeoseu', // 웨이버스
    '336570': 'Weonteg', // 원텍
    '336680': 'Tabreontotalsolrusyeon', // 탑런토탈솔루션
    '337930': 'Jegsimigseu', // 젝시믹스
    '338220': 'Byuno', // 뷰노
    '338840': 'Wai Biologics', // 와이바이오로직스
    '339950': 'AIbigimyeong', // 아이비김영
    '340360': 'Daboringkeu', // 다보링크
    '340440': 'Serim B&G', // 세림B&G
    '340450': 'Jissijinom', // 지씨지놈
    '340570': 'Tiaenel', // 티앤엘
    '340810': 'Siseon AI', // 시선AI
    '340930': 'Yuileneo Tech', // 유일에너테크
    '342870': 'Oa', // 오아
    '344860': 'Inojin', // 이노진
    '347000': 'Senko', // 센코
    '347700': 'Seupieo', // 스피어
    '347740': 'Pienkeipibuimsangyeongusenta', // 피엔케이피부임상연구센타
    '347770': 'Pimseu', // 핌스
    '347850': 'Diaendipamateg', // 디앤디파마텍
    '347860': 'Alcera', // 알체라
    '347890': 'Emtuai', // 엠투아이
    '348030': 'Mobirigseu', // 모비릭스
    '348080': 'Kyuratiseu', // 큐라티스
    '348150': 'Go Bio Raeb', // 고바이오랩
    '348210': 'Negseutin', // 넥스틴
    '348340': 'Nyuromeka', // 뉴로메카
    '348350': 'Wideuteg', // 위드텍
    '348370': 'Enkem', // 엔켐
    '351320': 'Negsadainaemigseu', // 넥사다이내믹스
    '351330': 'Isagenjinieoring', // 이삭엔지니어링
    '351870': 'Caikeomyunikeisyeon', // 차이커뮤니케이션
    '352090': 'Seutom Tech', // 스톰테크
    '352480': 'Ssiaenssi International', // 씨앤씨인터내셔널
    '352700': 'Ssiaentuseu', // 씨앤투스
    '352770': 'Selreseuteura', // 셀레스트라
    '352910': 'Obigo', // 오비고
    '352940': 'In Bio', // 인바이오
    '353190': 'Hyureom', // 휴럼
    '353590': 'Otoaen', // 오토앤
    '353810': 'Iji Bio', // 이지바이오
    '354200': 'Enjen Bio', // 엔젠바이오
    '354320': 'Almeg', // 알멕
    '355150': 'Koseutegsiseu', // 코스텍시스
    '355390': 'Keuraudeuweogseu', // 크라우드웍스
    '355690': 'Eiteom', // 에이텀
    '356680': 'Egseugeiteu', // 엑스게이트
    '356860': 'Tielbi', // 티엘비
    '356890': 'Ssaibeoweon', // 싸이버원
    '357230': 'Eicipio', // 에이치피오
    '357550': 'Seoggyeongeiti', // 석경에이티
    '357580': 'Amosenseu', // 아모센스
    '357780': 'Solbeurein', // 솔브레인
    '357880': 'SK AI', // SKAI
    '358570': 'Jiai Innovation', // 지아이이노베이션
    '359090': 'Ssienalriseoci', // 씨엔알리서치
    '360070': 'Tabmeotirieol', // 탑머티리얼
    '360350': 'Kosem', // 코셈
    '361390': 'Jenoko', // 제노코
    '361570': 'Albideobeulyu', // 알비더블유
    '361670': 'Samyeongeseuaenssi', // 삼영에스앤씨
    '362320': 'Ceongdam Global', // 청담글로벌
    '362990': 'Deuriminsaiteu', // 드림인사이트
    '363250': 'Jinsiseutem', // 진시스템
    '363260': 'Mobideijeu', // 모비데이즈
    '364950': 'Eiai Korea', // 에이아이코리아
    '365270': 'Kyurakeul', // 큐라클
    '365330': 'Eseuwaiseutilteg', // 에스와이스틸텍
    '365340': 'Seongilhaiteg', // 성일하이텍
    '365590': 'Haidib', // 하이딥
    '365900': 'Beuissi', // 브이씨
    '366030': 'Gongguumeon', // 공구우먼
    '367000': 'Peulraetieo', // 플래티어
    '368600': 'AIssieici', // 아이씨에이치
    '368770': 'Paibeopeuro', // 파이버프로
    '368970': 'Oeseupi', // 오에스피
    '369370': 'Beul REITs Weienteoteinmeonteu', // 블리츠웨이엔터테인먼트
    '370090': 'Pyureontieo', // 퓨런티어
    '371950': 'Pungweonjeongmil', // 풍원정밀
    '372170': 'Yunseongepeuaenssi', // 윤성에프앤씨
    '372320': 'Kyurosel', // 큐로셀
    '372800': 'AItiaijeu', // 아이티아이즈
    '373110': 'Egselserapyutigseu', // 엑셀세라퓨틱스
    '373160': 'Deiweonkeompeoni', // 데이원컴퍼니
    '373170': 'Emaikyubeusolrusyeon', // 엠아이큐브솔루션
    '373200': 'Egseu Plus', // 엑스플러스
    '376180': 'Pikogeuraem', // 피코그램
    '376270': 'HEM Pama', // HEM파마
    '376290': 'Ssiyu Tech', // 씨유테크
    '376300': 'Dieoyu', // 디어유
    '376900': 'Rokishelseukeeo', // 로킷헬스케어
    '376930': 'Noeul', // 노을
    '376980': 'Weontideuraeb', // 원티드랩
    '377030': 'Biteumaegseu', // 비트맥스
    '377220': 'Peurom Bio', // 프롬바이오
    '377330': 'Ijiteuronigseu', // 이지트로닉스
    '377450': 'Ripain', // 리파인
    '377460': 'Winiaeideu', // 위니아에이드
    '377480': 'Maeum AI', // 마음AI
    '378340': 'Pil Energy', // 필에너지
    '378800': 'Syaperon', // 샤페론
    '380540': 'Obtikoeo', // 옵티코어
    '380550': 'Nyuropis', // 뉴로핏
    '381620': 'Jenigseurobotigseu', // 제닉스로보틱스
    '382150': 'Onkokeuroseu', // 온코크로스
    '382480': 'Jiaiteg', // 지아이텍
    '382800': 'Jiaenbieseu Eko', // 지앤비에스 에코
    '382840': 'Weonjun', // 원준
    '382900': 'Beomhanpyueolsel', // 범한퓨얼셀
    '383310': 'Ekopeuroeicien', // 에코프로에이치엔
    '383930': 'Ditiaenssialo', // 디티앤씨알오
    '384470': 'Koeorainsopeuteu', // 코어라인소프트
    '387570': 'Painmedigseu', // 파인메딕스
    '388050': 'Jitupaweo', // 지투파워
    '388210': 'Ssiemtiegseu', // 씨엠티엑스
    '388610': 'GF Ssisaengmyeonggwahag', // 지에프씨생명과학
    '388720': 'Yuilrobotigseu', // 유일로보틱스
    '388790': 'Raikom', // 라이콤
    '388870': 'Paroseuai Bio', // 파로스아이바이오
    '389020': 'Jaram Tech Nolroji', // 자람테크놀로지
    '389030': 'Jinineoseu', // 지니너스
    '389140': 'Pobaipo', // 포바이포
    '389260': 'Daemyeong Energy', // 대명에너지
    '389470': 'Inbentijiraeb', // 인벤티지랩
    '389500': 'Eseubibi Tech', // 에스비비테크
    '389650': 'Negseuteu Bio Medical', // 넥스트바이오메디컬
    '389680': 'Yudiemteg', // 유디엠텍
    '391710': 'Konigotomeisyeon', // 코닉오토메이션
    '393210': 'Tomatosiseutem', // 토마토시스템
    '393890': 'Deobeulyussipi', // 더블유씨피
    '393970': 'Daejinceomdansojae', // 대진첨단소재
    '394280': 'Opeunesji Tech Nolroji', // 오픈엣지테크놀로지
    '394800': 'Sseuribilrieon', // 쓰리빌리언
    '396270': 'Negseuteucib', // 넥스트칩
    '396300': 'Seamekanigseu', // 세아메카닉스
    '396470': 'Weoteu', // 워트
    '397030': 'Eipeuril Bio', // 에이프릴바이오
    '397810': 'Aedeuporeoseu', // 애드포러스
    '398120': 'Eseujihelseukeeo', // 에스지헬스케어
    '399720': 'Gaoncibseu', // 가온칩스
    '402030': 'Konan Tech Nolroji', // 코난테크놀로지
    '402490': 'Geurinrisoseu', // 그린리소스
    '403490': 'Udeumjipam', // 우듬지팜
    '403850': 'Deopingkeupongkeompeoni', // 더핑크퐁컴퍼니
    '403870': 'HPSP', // HPSP
    '405000': 'Peulrajeumaeb', // 플라즈맵
    '405100': 'Kyualti', // 큐알티
    '405920': 'Naraselra', // 나라셀라
    '406820': 'Byutiseukin', // 뷰티스킨
    '407400': 'Ggumbi', // 꿈비
    '408470': 'Hanpaeseu', // 한패스
    '408900': 'Seutyudiomireu', // 스튜디오미르
    '408920': 'Messeisang', // 메쎄이상
    '411080': 'Saenjeuraeb', // 샌즈랩
    '412350': 'Reijeossel', // 레이저쎌
    '412540': 'Jeilemaeneseu', // 제일엠앤에스
    '413390': 'Emoti', // 엠오티
    '413630': 'Ssipisiseutem', // 씨피시스템
    '413640': 'Biaimaeteurigseu', // 비아이매트릭스
    '415380': 'Seutyudiosamig', // 스튜디오삼익
    '416180': 'Sinseongeseuti', // 신성에스티
    '417010': 'Nanotim', // 나노팀
    '417180': 'Pinggeoseutori', // 핑거스토리
    '417200': 'LS Meoteurieoljeu', // LS머트리얼즈
    '417500': 'Jeiai Tech', // 제이아이테크
    '417790': 'Teuruen', // 트루엔
    '417840': 'Jeoseutem', // 저스템
    '417860': 'Obeujen', // 오브젠
    '417970': 'Modelsolrusyeon', // 모델솔루션
    '418250': 'Sikyureteo', // 시큐레터
    '418420': 'Raonteg', // 라온텍
    '418470': 'KT Milriyiseojae', // KT밀리의서재
    '418550': 'Jeio', // 제이오
    '418620': 'E8', // E8
    '419050': 'Samgi Energy Solrusyeonjeu', // 삼기에너지솔루션즈
    '419080': 'Enjes', // 엔젯
    '419120': 'Sandol', // 산돌
    '419530': 'SAMG Enteo', // SAMG엔터
    '419540': 'Biseutoseu', // 비스토스
    '420570': 'Jeitukei Bio', // 제이투케이바이오
    '420770': 'Gigabiseu', // 기가비스
    '424760': 'Belrokeu', // 벨로크
    '424870': 'Imyunonsia', // 이뮨온시아
    '424960': 'Seumateureideosiseutem', // 스마트레이더시스템
    '424980': 'Maikeurotunano', // 마이크로투나노
    '425040': 'Tiiemssi', // 티이엠씨
    '425420': 'Tiepeui', // 티에프이
    '429270': 'Sijiteuronigseu', // 시지트로닉스
    '430690': 'Hanssag', // 한싹
    '431190': 'Keisseuriai', // 케이쓰리아이
    '432430': 'Wairaeb', // 와이랩
    '432470': 'Keieneseu', // 케이엔에스
    '432720': 'Kweolritaseu Semiconductor', // 퀄리타스반도체
    '432980': 'Emepeussi', // 엠에프씨
    '434480': 'Moniteoraeb', // 모니터랩
    '435570': 'Ereukoseu', // 에르코스
    '437730': 'Samhyeon', // 삼현
    '438700': 'Beonegteu', // 버넥트
    '439090': 'Manyeogongjang', // 마녀공장
    '439580': 'Beulruemteg', // 블루엠텍
    '440110': 'Padu', // 파두
    '440290': 'HB Inbeseuteumeonteu', // HB인베스트먼트
    '440320': 'Opeunnol', // 오픈놀
    '441270': 'Painemteg', // 파인엠텍
    '443250': 'Rebyukopeoreisyeon', // 레뷰코퍼레이션
    '443670': 'Eseupisopeuteu', // 에스피소프트
    '444530': 'Simpeulraespom', // 심플랫폼
    '444920': 'Yuanta Je 11 Hoseupaeg', // 유안타제11호스팩
    '445090': 'Eijigraendeu', // 에이직랜드
    '445180': 'Pyuris', // 퓨릿
    '445680': 'Kyuriogseu Bio Siseutemjeu', // 큐리옥스바이오시스템즈
    '446540': 'Megateoci', // 메가터치
    '446840': 'Jiseun', // 지슨
    '448280': 'Ekoai', // 에코아이
    '448710': 'Koceu Tech Nolroji', // 코츠테크놀로지
    '448900': 'Korea Piaiem', // 한국피아이엠
    '450330': 'Haseu', // 하스
    '450520': 'Inseuweibeu', // 인스웨이브
    '450950': 'Aseuterasiseu', // 아스테라시스
    '451220': 'AIemti', // 아이엠티
    '451250': 'Bbia', // 삐아
    '451700': 'Eneiciseupaeg 29 Ho', // 엔에이치스팩29호
    '451760': 'Keonteg', // 컨텍
    '452160': 'Jeienbi', // 제이엔비
    '452190': 'Hanbicreijeo', // 한빛레이저
    '452200': 'Min Tech', // 민테크
    '452280': 'Hanseonenjinieoring', // 한선엔지니어링
    '452300': 'Kaebseutonpateuneoseu', // 캡스톤파트너스
    '452400': 'Inigseu', // 이닉스
    '452430': 'Sapien Semiconductor', // 사피엔반도체
    '452450': 'Piaii', // 피아이이
    '452670': 'Sangsanginje 4 Hoseupaeg', // 상상인제4호스팩
    '452980': 'Shinhan Je 11 Hoseupaeg', // 신한제11호스팩
    '453450': 'Geurideuwijeu', // 그리드위즈
    '453860': 'Eieseuteg', // 에이에스텍
    '455180': 'Keijiei', // 케이지에이
    '455310': 'Hanwha Plus Je 4 Hoseupaeg', // 한화플러스제4호스팩
    '455900': 'Enjelrobotigseu', // 엔젤로보틱스
    '456010': 'AIssitikei', // 아이씨티케이
    '456070': 'Iensel', // 이엔셀
    '456160': 'Jituji Bio', // 지투지바이오
    '457370': 'Hankem', // 한켐
    '457550': 'Ujinenteg', // 우진엔텍
    '457600': 'Begteu', // 벡트
    '457630': 'Daishin Baelreonseuje 16 Hoseupaeg', // 대신밸런스제16호스팩
    '458350': 'Eseutim', // 에스팀
    '458610': 'Korea Je 12 Hoseupaeg', // 한국제12호스팩
    '458650': 'Seong Pref', // 성우
    '458870': 'Ssieoseu Tech Nolroji', // 씨어스테크놀로지
    '459100': 'Wiceu', // 위츠
    '459510': 'Naurobotigseu', // 나우로보틱스
    '459550': 'Alteu', // 알트
    '460470': 'AIbim Tech Nolroji', // 아이빔테크놀로지
    '460870': 'Eseuemssiji', // 에스엠씨지
    '460930': 'Hyundai Himseu', // 현대힘스
    '460940': 'Piaeneseurobotigseu', // 피앤에스로보틱스
    '461030': 'AIembidiegseu', // 아이엠비디엑스
    '461300': 'AIseukeurimmidieo', // 아이스크림미디어
    '462020': 'Eiciemssije 6 Hoseupaeg', // 에이치엠씨제6호스팩
    '462310': 'Nyukijeuon', // 뉴키즈온
    '462350': 'Inoseupeiseu', // 이노스페이스
    '462510': 'Ramediteg', // 라메디텍
    '462860': 'Deojeun', // 더즌
    '462980': 'AIjines', // 아이지넷
    '463020': 'Nyuen AI', // 뉴엔AI
    '463480': 'Motibeuringkeu', // 모티브링크
    '464080': 'Eseuoeseuraeb', // 에스오에스랩
    '464280': 'Tidieseupam', // 티디에스팜
    '464440': 'Korea Je 13 Hoseupaeg', // 한국제13호스팩
    '464490': 'Kweodeumediseun', // 쿼드메디슨
    '464500': 'AIeondibaiseu', // 아이언디바이스
    '464580': 'Dot Mil', // 닷밀
    '464680': 'KB Je 27 Hoseupaeg', // KB제27호스팩
    '465320': 'Gyobo 15 Hoseupaeg', // 교보15호스팩
    '465480': 'Inseupieon', // 인스피언
    '466100': 'Keulrobos', // 클로봇
    '466410': 'Sainaebsopeuteu', // 사이냅소프트
    '466690': 'Kiumhieoroje 1 Hoseupaeg', // 키움히어로제1호스팩
    '466910': 'Eneiciseupaeg 30 Ho', // 엔에이치스팩30호
    '467930': 'IBKS Je 23 Hoseupaeg', // IBKS제23호스팩
    '468530': 'Peurotina', // 프로티나
    '468760': 'Eugene Seupaeg 10 Ho', // 유진스팩10호
    '469480': 'IBKS Je 24 Hoseupaeg', // IBKS제24호스팩
    '469610': 'Ino Tech', // 이노테크
    '469750': 'AIbijyeonweogseu', // 아이비젼웍스
    '469880': 'Hana 30 Hoseupaeg', // 하나30호스팩
    '469900': 'Hana 31 Hoseupaeg', // 하나31호스팩
    '471050': 'Daishin Baelreonseuje 17 Hoseupaeg', // 대신밸런스제17호스팩
    '471820': 'Selromaegseusaieonseu', // 셀로맥스사이언스
    '472220': 'Sinyeongseupaeg 10 Ho', // 신영스팩10호
    '472230': 'Eseukeisecuritiesje 11 Hoseupaeg', // 에스케이증권제11호스팩
    '472850': 'Pondeugeurub', // 폰드그룹
    '473000': 'Eseukeisecuritiesje 12 Hoseupaeg', // 에스케이증권제12호스팩
    '473050': 'Yuanta Je 15 Hoseupaeg', // 유안타제15호스팩
    '473370': 'Bienkeije 2 Hoseupaeg', // 비엔케이제2호스팩
    '473950': 'Eseukeisecuritiesje 13 Hoseupaeg', // 에스케이증권제13호스팩
    '473980': 'Nomeoseu', // 노머스
    '474170': 'Rumireu', // 루미르
    '474490': 'Yuanta Je 16 Hoseupaeg', // 유안타제16호스팩
    '474610': 'RF Siseutemjeu', // RF시스템즈
    '474650': 'Ringkeusolrusyeon', // 링크솔루션
    '474660': 'Shinhan Je 12 Hoseupaeg', // 신한제12호스팩
    '474930': 'Shinhan Je 13 Hoseupaeg', // 신한제13호스팩
    '475230': 'Enalbi', // 엔알비
    '475240': 'Hana 32 Hoseupaeg', // 하나32호스팩
    '475250': 'Hana 33 Hoseupaeg', // 하나33호스팩
    '475400': 'Ssimeseu', // 씨메스
    '475430': 'Kiseuteuron', // 키스트론
    '475460': 'Miteubagseu', // 미트박스
    '475580': 'Eireogseu', // 에이럭스
    '475660': 'Eseukem', // 에스켐
    '475830': 'Oreumterapyutig', // 오름테라퓨틱
    '475960': 'Tomokyubeu', // 토모큐브
    '476040': 'Oganoideusaieonseu', // 오가노이드사이언스
    '476060': 'Onkonigterapyutigseu', // 온코닉테라퓨틱스
    '476080': 'M83', // M83
    '476830': 'Aljinomigseu', // 알지노믹스
    '477340': 'Eiciemssije 7 Hoseupaeg', // 에이치엠씨제7호스팩
    '477380': 'Mirae Asset Bijeonseupaeg 4 Ho', // 미래에셋비전스팩4호
    '477470': 'Mirae Asset Bijeonseupaeg 5 Ho', // 미래에셋비전스팩5호
    '477760': 'DB Financial Seupaeg 12 Ho', // DB금융스팩12호
    '478110': 'Ibeseuteuseupaeg 6 Ho', // 이베스트스팩6호
    '478340': 'Naraseupeiseu Tech Nolroji', // 나라스페이스테크놀로지
    '478390': 'KB Je 29 Hoseupaeg', // KB제29호스팩
    '478440': 'Mirae Asset Bijeonseupaeg 6 Ho', // 미래에셋비전스팩6호
    '478560': 'Beulraegyakeuaiaenssi', // 블랙야크아이앤씨
    '479880': 'Korea Je 15 Hoseupaeg', // 한국제15호스팩
    '479960': 'Wineoseu', // 위너스
    '481070': 'Eiyubeuraenjeu', // 에이유브랜즈
    '481890': 'Eneiciseupaeg 31 Ho', // 엔에이치스팩31호
    '482520': 'Gyobo 16 Hoseupaeg', // 교보16호스팩
    '482630': 'Samyang Enssikem', // 삼양엔씨켐
    '482680': 'Mirae Asset Bijeonseupaeg 7 Ho', // 미래에셋비전스팩7호
    '482690': 'Daishin Baelreonseuje 19 Hoseupaeg', // 대신밸런스제19호스팩
    '484120': 'Douinsiseu', // 도우인시스
    '484130': 'Hana 34 Hoseupaeg', // 하나34호스팩
    '484590': 'Samyang Keomteg', // 삼양컴텍
    '484810': 'Tiegseualrobotigseu', // 티엑스알로보틱스
    '486630': 'KB Je 30 Hoseupaeg', // KB제30호스팩
    '486990': 'Nota', // 노타
    '487360': 'Shinhan Je 14 Hoseupaeg', // 신한제14호스팩
    '487720': 'Kiumje 10 Hoseupaeg', // 키움제10호스팩
    '487830': 'Shinhan Je 15 Hoseupaeg', // 신한제15호스팩
    '488060': 'Eugene Seupaeg 11 Ho', // 유진스팩11호
    '488280': 'Eseutudeobeulyu', // 에스투더블유
    '488900': 'Biceuronegseuteg', // 비츠로넥스텍
    '489210': 'Gyobo 17 Hoseupaeg', // 교보17호스팩
    '489460': 'Bio Bijyu', // 바이오비쥬
    '489480': 'Kiumje 11 Hoseupaeg', // 키움제11호스팩
    '489500': 'Elkeikem', // 엘케이켐
    '489730': 'Dibi Financial Je 13 Hoseupaeg', // 디비금융제13호스팩
    '490470': 'Semipaibeu', // 세미파이브
    '491000': 'Ribeuseumedeu', // 리브스메드
    '492220': 'KB Je 31 Hoseupaeg', // KB제31호스팩
    '493280': 'AIem Biologics', // 아이엠바이오로직스
    '493330': 'GF AI', // 지에프아이
    '493790': 'Yuanta Je 17 Hoseupaeg', // 유안타제17호스팩
    '494120': 'Kyuriosiseu', // 큐리오시스
    '496070': 'Shinhan Je 16 Hoseupaeg', // 신한제16호스팩
    '498390': 'Hanwha Plus Je 5 Hoseupaeg', // 한화플러스제5호스팩
    '950190': 'Goseuteuseutyudio', // 고스트스튜디오
    '950170': 'JTC', // JTC
    '950250': 'Terabyu', // 테라뷰
    '950130': 'Egseseu Bio', // 엑세스바이오
    '950140': 'Inggeuludeuraeb', // 잉글우드랩
    '950160': 'Kolon Tisyujin', // 코오롱티슈진
    '950220': 'Neoimyunteg', // 네오이뮨텍
    '950200': 'Somajen', // 소마젠
    '900120': 'Ssiegseuai', // 씨엑스아이
    '900250': 'Keuriseutalsinsojae', // 크리스탈신소재
    '900070': 'Global Eseuem', // 글로벌에스엠
    '900100': 'Aemeorisji', // 애머릿지
  };


    static String? krEnglishName(String code) {
      final c = code.trim();
      if (c.isEmpty) return null;
      return krCodeToEnglishName[c];
    }

    static String displayKrName({
      required String code,
      required String koName,
      required Locale locale,
    }) {
      if (locale.languageCode == 'en') {
        return krEnglishName(code) ?? koName;
      }
      return koName;
    }

    static String? displayKrOriginalName({
      required String code,
      required String koName,
      required Locale locale,
    }) {
      if (locale.languageCode != 'en') return null;

      final en = krEnglishName(code);
      if (en == null || en.trim().isEmpty || en == koName) return null;
      return koName;
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