// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stock Fair Value Calculator';

  @override
  String get tabKr => 'Korea';

  @override
  String get tabUs => 'US';

  @override
  String get searchHint => 'Search stocks';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get financialStatements => 'Financial statements';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get ranking => 'Ranking';

  @override
  String get undervalued => 'Undervalued';

  @override
  String get fairValue => 'Fair value';

  @override
  String get currentPrice => 'Current price';

  @override
  String get expectedReturn => 'Expected return';

  @override
  String get dividendYield => 'Dividend yield';

  @override
  String get roe => 'ROE';

  @override
  String get per => 'PER';

  @override
  String get pbr => 'PBR';

  @override
  String get veryUndervalued => 'Very undervalued';

  @override
  String get undervaluedLabel => 'Undervalued';

  @override
  String get nearFairValue => 'Near fair value';

  @override
  String get expensive => 'Expensive';

  @override
  String get veryExpensive => 'Very expensive';

  @override
  String get aboutApp => 'About';

  @override
  String get loading => 'Loading...';

  @override
  String get companyDescription =>
      'An app for conservative investors who focus on clear financial data rather than uncertain future predictions or speculative trading.';

  @override
  String get contact => 'Contact';

  @override
  String get emailInquiry => 'Email inquiry';

  @override
  String get update => 'Update';

  @override
  String get checkForUpdates => 'Check for updates in store';

  @override
  String get installLatestVersion => 'Install the latest version';

  @override
  String get misc => 'Misc';

  @override
  String get close => 'Close';

  @override
  String get invalidLink => 'The link format is invalid.';

  @override
  String get cannotOpenLink => 'Unable to open the link.';

  @override
  String get cannotOpenMailApp => 'Unable to open the mail app.';

  @override
  String get privacyOpenWeb => 'Open web page';

  @override
  String get appInquirySubject => '[App Inquiry]';

  @override
  String versionLabel(String version) {
    return 'Version: $version';
  }

  @override
  String get rankingPageTitle => 'Undervalued Companies';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get clear => 'Clear';

  @override
  String get krRankSearchHint => 'Search by stock name or code';

  @override
  String get usRankSearchHint => 'Search by company name or ticker';

  @override
  String rankingUpdatedMeta(String updated) {
    return '$updated (based on expected return)';
  }

  @override
  String rankingItemCount(int count) {
    return '$count items';
  }

  @override
  String get rankingPriceMayUpdate =>
      'Current prices may update again after opening this screen.';

  @override
  String get rankingStillGeneratingWait =>
      'Ranking is being generated... Please wait!';

  @override
  String get requestUrlLabel => 'Request URL';

  @override
  String get krRankingGeneratingWait =>
      'KR ranking is being generated... Please wait.';

  @override
  String get krRankingGeneratingRetry =>
      'KR ranking is being generated... Please try again shortly.';

  @override
  String get krRankingPreparing => 'Preparing KR ranking...';

  @override
  String get krRankingSearchEmpty => 'No results found in KR ranking search.';

  @override
  String get usRankingGeneratingWait =>
      'US ranking is being generated... Please wait.';

  @override
  String get usRankingGeneratingRetry =>
      'US ranking is being generated... Please try again shortly.';

  @override
  String get usRankingPreparing => 'Preparing US ranking...';

  @override
  String get usRankingSearchEmpty => 'No results found in US ranking search.';

  @override
  String get previousDayChangeNone => 'Previous day -';

  @override
  String get changeNone => 'Change -';

  @override
  String usRankingError(String error) {
    return 'US ranking error: $error';
  }

  @override
  String get searchPageCompactHintKr => 'Name/Code';

  @override
  String get searchPageCompactHintUs => 'Ticker';

  @override
  String get searchPageHintKr =>
      'Korean stock name or code (e.g. Samsung Electronics / 005930)';

  @override
  String get searchPageHintUs => 'US ticker (e.g. AAPL / TSLA)';

  @override
  String get searchTabLooksKrGuide =>
      'This looks like a Korean stock. Please search in the Korea tab.';

  @override
  String get searchErrorEmpty => 'No results found.';

  @override
  String get searchButton => 'Search';

  @override
  String get clearButton => 'Clear';

  @override
  String get marketUs => 'US';

  @override
  String get marketUnknown => '-';

  @override
  String get favorites => 'Favorites';

  @override
  String get searchPageTitle => 'Stock Search';

  @override
  String get moreMenu => 'More';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupImport => 'Import backup';

  @override
  String get exportBackupCanceled => 'Backup export was canceled.';

  @override
  String exportBackupCreated(String path) {
    return 'Backup file created.\n$path';
  }

  @override
  String exportBackupFailed(String error) {
    return 'Backup export failed: $error';
  }

  @override
  String get importBackupCanceled => 'Backup import was canceled.';

  @override
  String get importBackupTitle => 'Import backup';

  @override
  String get importBackupConfirm =>
      'This will replace the current device\'s favorites, recent searches, and inputs with the contents of the backup file.\n\nDo you want to continue?';

  @override
  String get importButton => 'Import';

  @override
  String get importBackupSuccess => 'Backup file imported.';

  @override
  String importBackupFailed(String error) {
    return 'Backup import failed: $error';
  }

  @override
  String get recentDeleteTitle => 'Delete recent search';

  @override
  String recentDeleteConfirm(String name, String code) {
    return 'Remove $name($code) from recent searches?';
  }

  @override
  String get clearRecentTitle => 'Delete all recent searches';

  @override
  String get clearRecentConfirm => 'Delete all recent searches?';

  @override
  String get favoritesDeleteTitle => 'Delete favorite';

  @override
  String favoritesDeleteConfirm(String name, String code) {
    return 'Remove $name($code) from favorites?';
  }

  @override
  String get clearFavoritesTitle => 'Delete all favorites';

  @override
  String get clearFavoritesConfirm => 'Delete all favorites?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAll => 'Delete all';

  @override
  String deletedItem(String name) {
    return '$name deleted';
  }

  @override
  String get recentCleared => 'All recent searches have been deleted.';

  @override
  String get favoritesCleared => 'All favorites have been deleted.';

  @override
  String get viewValuation => 'View valuation';

  @override
  String get autoSearchHelp =>
      'Auto-search runs automatically, and you can also search immediately with the magnifier on the right.';

  @override
  String get recentSearchesDeleteAllTooltip => 'Delete all recent searches';

  @override
  String get favoritesDeleteAllTooltip => 'Delete all favorites';

  @override
  String get recentSearchesEmptyTitle => 'No recent searches yet';

  @override
  String get recentSearchesEmptyDesc =>
      'Try searching for a stock above. Your search history will appear here.';

  @override
  String get favoritesEmptyTitle => 'Favorites are empty';

  @override
  String get favoritesEmptyDesc =>
      'Tap the ⭐ button on the stock valuation screen to collect items here.';

  @override
  String get emptySearchTitle => 'No search results';

  @override
  String get emptySearchDescKrTryUs =>
      'If there are no results in Korea, try searching the ticker in the US tab.';

  @override
  String get emptySearchDescKrCheck =>
      'Please check the stock name/code again.';

  @override
  String get emptySearchDescUsCheck => 'Please check the ticker again.';

  @override
  String detailPageOpenFailed(String error) {
    return 'Failed to open details screen: $error';
  }

  @override
  String get favorite => 'Favorite';

  @override
  String get showAdvancedView => 'Show advanced view';

  @override
  String get hideAdvancedView => 'Hide advanced view';

  @override
  String get openNaverKr => 'Open Naver Securities';

  @override
  String get openNaverGlobal => 'Open Naver Global Search';

  @override
  String get retry => 'Retry';

  @override
  String get loadingPriceStart => 'Loading price';

  @override
  String get loadingPriceTimeout => 'Price request timed out (8s)';

  @override
  String get loadingFundamentalsStart => 'Loading fundamentals (EPS/BPS/DPS)';

  @override
  String get loadingFundamentalsTimeout =>
      'Fundamentals request timed out (12s)';

  @override
  String get loadingApplyInitial => 'Applying initial values';

  @override
  String get loadingRestoreSaved => 'Restoring saved values';

  @override
  String get loadingDone => 'Done';

  @override
  String get reloadedValues => 'Values were reloaded.';

  @override
  String get naverOpenFailed => 'Unable to open the Naver page.';

  @override
  String get naverUsHint =>
      'For overseas stocks, search the ticker in Naver Global Stocks.';

  @override
  String get viewFinancialStatements => 'View financial statements';

  @override
  String get savePdf => 'Save PDF';

  @override
  String financialSourceLabel(String source) {
    return 'Financial source: $source';
  }

  @override
  String get valuationErrorInvalidRequiredReturn =>
      'Required return r must be greater than 0.';

  @override
  String get valuationErrorInvalidPrice =>
      'Current price must be greater than 0.';

  @override
  String get valuationErrorInvalidBps =>
      'It is difficult to calculate when BPS is 0 or below.';

  @override
  String get backupErrorInvalidFormat => 'The backup format is invalid.';

  @override
  String get backupErrorWrongApp => 'This is not a backup file for this app.';

  @override
  String get backupErrorUnsupportedVersion =>
      'This backup version is not supported.';

  @override
  String get fsPdfDocumentTitleSuffix => 'Financial Statements';

  @override
  String get fsPdfSummarySectionTitle => 'Financial Statement Summary';

  @override
  String get fsPdfBuffettAssistSectionTitle => 'Buffett-style Helper Metrics';

  @override
  String get fsPdfTrendSectionTitle => 'Long-term Trend';

  @override
  String get fsPdfStabilitySectionTitle => 'Stability';

  @override
  String get fsPdfPeriodLabel => 'Period';

  @override
  String get fsPdfRevenueLabel => 'Revenue';

  @override
  String get fsPdfOpIncomeLabel => 'Operating income';

  @override
  String get fsPdfNetIncomeLabel => 'Net income';

  @override
  String get fsPdfEquityLabel => 'Equity';

  @override
  String get fsPdfLiabilitiesLabel => 'Liabilities';

  @override
  String get fsPdfFinancialSourceLabel => 'Financial source';

  @override
  String get fsPdfAvg3yEpsLabel => '3Y average EPS';

  @override
  String get fsPdfAvg5yRoeLabel => '5Y average ROE';

  @override
  String get fsPdfYearlyEpsLabel => 'EPS by year';

  @override
  String get fsPdfYearlyRoeLabel => 'ROE by year';

  @override
  String get fsPdfLossYearsLabel => 'Loss years';

  @override
  String get fsPdfDebtRatioLabel => 'Debt ratio';

  @override
  String get fsPdfRecentDividendLabel => 'Recent dividend';

  @override
  String get fsPdfDisclaimerText =>
      'This document is for investment reference only.';

  @override
  String get fsPdfShareTextSuffix => 'Financial Statements PDF';

  @override
  String get fsPdfPlatformNotSupportedText =>
      'Saving PDF is not supported on this platform.';

  @override
  String get fsPdfFontLoadErrorText =>
      'Failed to load PDF fonts.\nCheck assets/fonts/NotoSansKR-Regular.ttf\nCheck assets/fonts/NotoSansKR-Bold.ttf\nThen run flutter clean and try again.';

  @override
  String get resultPdfInputSectionTitle => 'Inputs';

  @override
  String get resultPdfResultSectionTitle => 'Result';

  @override
  String get resultPdfRatingSummarySectionTitle => 'Rating Summary';

  @override
  String get resultPdfFinancialSummarySectionTitle => 'Financial Summary';

  @override
  String get resultPdfNoteSectionTitle => 'Notes';

  @override
  String get resultPdfCurrentPriceLabel => 'Current price';

  @override
  String get resultPdfEpsLabel => 'EPS';

  @override
  String get resultPdfBpsLabel => 'BPS';

  @override
  String get resultPdfDpsLabel => 'DPS';

  @override
  String get resultPdfRequiredReturnLabel => 'Required return r';

  @override
  String get resultPdfFairPriceLabel => 'Fair price';

  @override
  String get resultPdfExpectedReturnLabel => 'Expected return';

  @override
  String get resultPdfValuationStatusLabel => 'Valuation status';

  @override
  String get resultPdfRoeLabel => 'ROE';

  @override
  String get resultPdfDividendYieldLabel => 'Dividend yield';

  @override
  String get resultPdfPerLabel => 'PER';

  @override
  String get resultPdfPbrLabel => 'PBR';

  @override
  String get resultPdfRatingLabel => 'Rating';

  @override
  String get resultPdfFinancialBasisLabel => 'Basis';

  @override
  String get resultPdfRevenueLabel => 'Revenue';

  @override
  String get resultPdfOpIncomeLabel => 'Operating income';

  @override
  String get resultPdfNetIncomeLabel => 'Net income';

  @override
  String get resultPdfEquityLabel => 'Equity';

  @override
  String get resultPdfLiabilitiesLabel => 'Liabilities';

  @override
  String get resultPdfFinancialSourceLabel => 'Financial source';

  @override
  String get resultPdfCalcUnavailablePrefix => 'Calculation unavailable';

  @override
  String get resultPdfDisclaimerText =>
      'This document is for investment reference only.';

  @override
  String get resultPdfShareTextSuffix => 'PDF report';

  @override
  String get resultPdfPlatformNotSupportedText =>
      'Saving PDF is not supported on this platform.';

  @override
  String get resultPdfFontLoadErrorText =>
      'Failed to load PDF fonts.\n1) Check assets/fonts/NotoSansKR-Regular.ttf\n2) Check assets/fonts/NotoSansKR-Bold.ttf\n3) Register them in pubspec.yaml\n4) Run flutter clean and try again.';

  @override
  String get updateAvailableTitle => 'An update is available';

  @override
  String get updateAvailableMessage =>
      'A new version is ready. Would you like to update now?';

  @override
  String get updateLater => 'Later';

  @override
  String get updateNow => 'Update';

  @override
  String get updateAvailableBadge => 'Update available';

  @override
  String get updateFromAbout => 'Update';

  @override
  String get updateCheckInAboutHint =>
      'You can continue the update from About.';

  @override
  String get updateAvailableMenuTitle => 'Update available';

  @override
  String get updateAvailableMenuSubtitle =>
      'A new version is available. Tap to update.';

  @override
  String get loadingApplyRankingSnapshot => 'Applying ranking values';
}
