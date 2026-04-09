// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '주식적정가계산기';

  @override
  String get tabKr => '국내';

  @override
  String get tabUs => '미국';

  @override
  String get searchHint => '종목 검색';

  @override
  String get recentSearches => '최근 검색';

  @override
  String get financialStatements => '재무제표';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get termsOfService => '이용약관';

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get ranking => '랭킹';

  @override
  String get undervalued => '저평가';

  @override
  String get fairValue => '적정가';

  @override
  String get currentPrice => '현재가';

  @override
  String get expectedReturn => '기대수익률';

  @override
  String get dividendYield => '배당수익률';

  @override
  String get roe => 'ROE';

  @override
  String get per => 'PER';

  @override
  String get pbr => 'PBR';

  @override
  String get veryUndervalued => '매우 저평가';

  @override
  String get undervaluedLabel => '저평가';

  @override
  String get nearFairValue => '적정 수준';

  @override
  String get expensive => '고평가';

  @override
  String get veryExpensive => '매우 고평가';

  @override
  String get aboutApp => '앱 정보';

  @override
  String get loading => '불러오는 중...';

  @override
  String get companyDescription =>
      '투기적인 매매가 아닌 원칙 있는 투자, 불확실한 미래 예측보다 확실한 재무 수치에 집중하는 보수적 투자자를 위한 앱입니다.';

  @override
  String get contact => '문의';

  @override
  String get emailInquiry => '이메일 문의';

  @override
  String get update => '업데이트';

  @override
  String get checkForUpdates => '스토어에서 업데이트 확인';

  @override
  String get installLatestVersion => '최신 버전 설치';

  @override
  String get misc => '기타';

  @override
  String get close => '닫기';

  @override
  String get invalidLink => '링크 형식이 올바르지 않습니다.';

  @override
  String get cannotOpenLink => '링크를 열 수 없습니다.';

  @override
  String get cannotOpenMailApp => '메일 앱을 열 수 없습니다.';

  @override
  String get privacyOpenWeb => '웹페이지로 열기';

  @override
  String get appInquirySubject => '[앱 문의]';

  @override
  String versionLabel(String version) {
    return '버전: $version';
  }

  @override
  String get rankingPageTitle => '저평가 기업';

  @override
  String get search => '검색';

  @override
  String get refresh => '새로고침';

  @override
  String get clear => '지우기';

  @override
  String get krRankSearchHint => '종목명 · 코드 검색';

  @override
  String get usRankSearchHint => '기업명 · 티커 검색';

  @override
  String rankingUpdatedMeta(String updated) {
    return '$updated (기대수익률 기준)';
  }

  @override
  String rankingItemCount(int count) {
    return '$count개';
  }

  @override
  String get rankingPriceMayUpdate => '현재가는 화면 진입 후 다시 반영될 수 있어요.';

  @override
  String get rankingStillGeneratingWait => '랭킹 생성중입니다... 잠시만요!';

  @override
  String get requestUrlLabel => '요청 URL';

  @override
  String get krRankingGeneratingWait => 'KR 랭킹 생성중입니다... 잠시만 기다려주세요.';

  @override
  String get krRankingGeneratingRetry => 'KR 랭킹 생성중입니다... 잠시 후 다시 시도해주세요.';

  @override
  String get krRankingPreparing => 'KR 랭킹을 준비중입니다...';

  @override
  String get krRankingSearchEmpty => 'KR 랭킹 내 검색 결과가 없습니다.';

  @override
  String get usRankingGeneratingWait => 'US 랭킹 생성중입니다... 잠시만 기다려주세요.';

  @override
  String get usRankingGeneratingRetry => 'US 랭킹 생성중입니다... 잠시 후 다시 시도해주세요.';

  @override
  String get usRankingPreparing => 'US 랭킹을 준비중입니다...';

  @override
  String get usRankingSearchEmpty => 'US 랭킹 내 검색 결과가 없습니다.';

  @override
  String get previousDayChangeNone => '전일대비 -';

  @override
  String get changeNone => '변동 -';

  @override
  String usRankingError(String error) {
    return 'US 랭킹 오류: $error';
  }

  @override
  String get searchPageCompactHintKr => '종목명/코드';

  @override
  String get searchPageCompactHintUs => '티커';

  @override
  String get searchPageHintKr => '국내 종목명 또는 코드 (예: 삼성전자 / 005930)';

  @override
  String get searchPageHintUs => '미국 티커 (예: AAPL / TSLA)';

  @override
  String get searchTabLooksKrGuide => '국내 종목으로 보입니다. ‘국내’ 탭에서 검색해 주세요.';

  @override
  String get searchErrorEmpty => '검색 결과가 없습니다.';

  @override
  String get searchButton => '검색';

  @override
  String get clearButton => '지우기';

  @override
  String get marketUs => 'US';

  @override
  String get marketUnknown => '-';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get searchPageTitle => '종목 검색';

  @override
  String get moreMenu => '더보기';

  @override
  String get backupExport => '백업 내보내기';

  @override
  String get backupImport => '백업 가져오기';

  @override
  String get exportBackupCanceled => '백업 내보내기가 취소되었습니다.';

  @override
  String exportBackupCreated(String path) {
    return '백업 파일을 만들었습니다.\n$path';
  }

  @override
  String exportBackupFailed(String error) {
    return '백업 내보내기 실패: $error';
  }

  @override
  String get importBackupCanceled => '백업 가져오기가 취소되었습니다.';

  @override
  String get importBackupTitle => '백업 가져오기';

  @override
  String get importBackupConfirm =>
      '현재 기기의 즐겨찾기, 최근검색, 입력값을 백업 파일 내용으로 바꿉니다.\n\n계속할까요?';

  @override
  String get importButton => '가져오기';

  @override
  String get importBackupSuccess => '백업 파일을 가져왔습니다.';

  @override
  String importBackupFailed(String error) {
    return '백업 가져오기 실패: $error';
  }

  @override
  String get recentDeleteTitle => '최근 검색 삭제';

  @override
  String recentDeleteConfirm(String name, String code) {
    return '$name($code) 를 최근 검색에서 삭제할까요?';
  }

  @override
  String get clearRecentTitle => '최근 검색 전체 삭제';

  @override
  String get clearRecentConfirm => '최근 검색 목록을 모두 삭제할까요?';

  @override
  String get favoritesDeleteTitle => '즐겨찾기 삭제';

  @override
  String favoritesDeleteConfirm(String name, String code) {
    return '$name($code) 를 즐겨찾기에서 삭제할까요?';
  }

  @override
  String get clearFavoritesTitle => '즐겨찾기 전체 삭제';

  @override
  String get clearFavoritesConfirm => '즐겨찾기 목록을 모두 삭제할까요?';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get deleteAll => '전체 삭제';

  @override
  String deletedItem(String name) {
    return '$name 삭제됨';
  }

  @override
  String get recentCleared => '최근 검색을 모두 삭제했습니다.';

  @override
  String get favoritesCleared => '즐겨찾기를 모두 삭제했습니다.';

  @override
  String get viewValuation => '평가보기';

  @override
  String get autoSearchHelp => '자동검색이 되며, 필요하면 오른쪽 돋보기로 즉시 검색할 수 있어요.';

  @override
  String get recentSearchesDeleteAllTooltip => '최근 검색 전체 삭제';

  @override
  String get favoritesDeleteAllTooltip => '즐겨찾기 전체 삭제';

  @override
  String get recentSearchesEmptyTitle => '최근 검색이 없어요';

  @override
  String get recentSearchesEmptyDesc => '위에서 종목명을 검색해보세요. 검색 기록이 여기에 쌓입니다.';

  @override
  String get favoritesEmptyTitle => '즐겨찾기가 비어 있어요';

  @override
  String get favoritesEmptyDesc => '종목 평가 화면에서 ⭐ 버튼을 누르면 여기에 모아볼 수 있어요.';

  @override
  String get emptySearchTitle => '검색 결과가 없어요';

  @override
  String get emptySearchDescKrTryUs => '국내에서 결과가 없으면 ‘미국’ 탭에서 티커로도 검색해보세요.';

  @override
  String get emptySearchDescKrCheck => '종목명/코드를 다시 확인해보세요.';

  @override
  String get emptySearchDescUsCheck => '티커를 다시 확인해보세요.';

  @override
  String detailPageOpenFailed(String error) {
    return '상세화면 이동 실패: $error';
  }

  @override
  String get favorite => '즐겨찾기';

  @override
  String get openNaverKr => 'N증권';

  @override
  String get retry => '다시 시도';

  @override
  String get loadingPriceStart => '가격 조회 시작';

  @override
  String get loadingPriceTimeout => '가격 조회 타임아웃(8s)';

  @override
  String get loadingFundamentalsStart => '재무(EPS/BPS/DPS) 조회 시작';

  @override
  String get loadingFundamentalsTimeout => '재무 조회 타임아웃(12s)';

  @override
  String get loadingApplyInitial => '초기값 반영';

  @override
  String get loadingRestoreSaved => '저장값 복원';

  @override
  String get loadingDone => '완료';

  @override
  String get reloadedValues => '값을 다시 불러왔습니다.';

  @override
  String get naverOpenFailed => '네이버 페이지를 열 수 없습니다.';

  @override
  String get naverUsHint => '해외는 네이버 해외주식에서 티커로 검색해서 확인하세요.';

  @override
  String get viewFinancialStatements => '재무제표 보기';

  @override
  String get savePdf => 'PDF 저장';

  @override
  String financialSourceLabel(String source) {
    return '재무 출처: $source';
  }

  @override
  String get valuationErrorInvalidRequiredReturn => '요구수익률 r은 0보다 커야 합니다.';

  @override
  String get valuationErrorInvalidPrice => '현재가는 0보다 커야 합니다.';

  @override
  String get valuationErrorInvalidBps => 'BPS가 0 이하이면 계산이 어렵습니다.';

  @override
  String get backupErrorInvalidFormat => '백업 형식이 올바르지 않습니다.';

  @override
  String get backupErrorWrongApp => '이 앱의 백업 파일이 아닙니다.';

  @override
  String get backupErrorUnsupportedVersion => '지원하지 않는 백업 버전입니다.';

  @override
  String get fsPdfDocumentTitleSuffix => '재무제표';

  @override
  String get fsPdfSummarySectionTitle => '재무제표 요약';

  @override
  String get fsPdfBuffettAssistSectionTitle => '버핏식 보조 지표';

  @override
  String get fsPdfTrendSectionTitle => '장기 추이';

  @override
  String get fsPdfStabilitySectionTitle => '안정성';

  @override
  String get fsPdfPeriodLabel => '기준';

  @override
  String get fsPdfRevenueLabel => '매출';

  @override
  String get fsPdfOpIncomeLabel => '영업이익';

  @override
  String get fsPdfNetIncomeLabel => '순이익';

  @override
  String get fsPdfEquityLabel => '자본';

  @override
  String get fsPdfLiabilitiesLabel => '부채';

  @override
  String get fsPdfFinancialSourceLabel => '재무 출처';

  @override
  String get fsPdfAvg3yEpsLabel => '3년 평균 EPS';

  @override
  String get fsPdfAvg5yRoeLabel => '5년 평균 ROE';

  @override
  String get fsPdfYearlyEpsLabel => '연도별 EPS';

  @override
  String get fsPdfYearlyRoeLabel => '연도별 ROE';

  @override
  String get fsPdfLossYearsLabel => '적자 여부';

  @override
  String get fsPdfDebtRatioLabel => '부채비율';

  @override
  String get fsPdfRecentDividendLabel => '최근 배당';

  @override
  String get fsPdfDisclaimerText => '본 문서는 투자 판단 참고용입니다.';

  @override
  String get fsPdfShareTextSuffix => '재무제표 PDF';

  @override
  String get fsPdfPlatformNotSupportedText => '이 플랫폼에서는 PDF 저장을 지원하지 않습니다.';

  @override
  String get fsPdfFontLoadErrorText =>
      'PDF 폰트를 불러오지 못했습니다.\nassets/fonts/NotoSansKR-Regular.ttf\nassets/fonts/NotoSansKR-Bold.ttf\n파일 확인 후 flutter clean 뒤 다시 실행하세요.';

  @override
  String get resultPdfInputSectionTitle => '입력값';

  @override
  String get resultPdfResultSectionTitle => '결과';

  @override
  String get resultPdfRatingSummarySectionTitle => '평가 요약';

  @override
  String get resultPdfFinancialSummarySectionTitle => '재무제표 요약';

  @override
  String get resultPdfNoteSectionTitle => '참고';

  @override
  String get resultPdfCurrentPriceLabel => '현재가';

  @override
  String get resultPdfEpsLabel => 'EPS';

  @override
  String get resultPdfBpsLabel => 'BPS';

  @override
  String get resultPdfDpsLabel => 'DPS';

  @override
  String get resultPdfRequiredReturnLabel => '요구수익률 r';

  @override
  String get resultPdfFairPriceLabel => '적정주가';

  @override
  String get resultPdfExpectedReturnLabel => '기대수익률';

  @override
  String get resultPdfValuationStatusLabel => '현황평가';

  @override
  String get resultPdfRoeLabel => 'ROE';

  @override
  String get resultPdfDividendYieldLabel => '배당수익률';

  @override
  String get resultPdfPerLabel => 'PER';

  @override
  String get resultPdfPbrLabel => 'PBR';

  @override
  String get resultPdfRatingLabel => '등급';

  @override
  String get resultPdfFinancialBasisLabel => '기준';

  @override
  String get resultPdfRevenueLabel => '매출';

  @override
  String get resultPdfOpIncomeLabel => '영업이익';

  @override
  String get resultPdfNetIncomeLabel => '순이익';

  @override
  String get resultPdfEquityLabel => '자본';

  @override
  String get resultPdfLiabilitiesLabel => '부채';

  @override
  String get resultPdfFinancialSourceLabel => '재무 출처';

  @override
  String get resultPdfCalcUnavailablePrefix => '계산 불가';

  @override
  String get resultPdfDisclaimerText => '본 문서는 투자 판단 참고용입니다.';

  @override
  String get resultPdfShareTextSuffix => 'PDF 보고서';

  @override
  String get resultPdfPlatformNotSupportedText => '이 플랫폼에서는 PDF 저장을 지원하지 않습니다.';

  @override
  String get resultPdfFontLoadErrorText =>
      'PDF 폰트를 불러오지 못했습니다.\n1) assets/fonts/NotoSansKR-Regular.ttf\n2) assets/fonts/NotoSansKR-Bold.ttf\n파일이 있는지 확인하고\n3) pubspec.yaml 에 assets 등록 후\n4) flutter clean 뒤 다시 실행하세요.';

  @override
  String get updateAvailableTitle => '업데이트가 있어요';

  @override
  String get updateAvailableMessage => '새 버전이 준비되었습니다. 지금 업데이트하시겠어요?';

  @override
  String get updateLater => '나중에';

  @override
  String get updateNow => '업데이트';

  @override
  String get updateAvailableBadge => '새 버전 있음';

  @override
  String get updateFromAbout => '업데이트';

  @override
  String get updateCheckInAboutHint => '앱정보에서 업데이트를 진행할 수 있어요.';

  @override
  String get updateAvailableMenuTitle => '업데이트 가능';

  @override
  String get updateAvailableMenuSubtitle => '새 버전이 있습니다. 눌러서 업데이트하세요.';

  @override
  String get loadingApplyRankingSnapshot => '랭킹 기준값 적용';
}
