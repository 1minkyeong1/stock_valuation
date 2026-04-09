import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Fair Value Calculator'**
  String get appTitle;

  /// No description provided for @tabKr.
  ///
  /// In en, this message translates to:
  /// **'Korea'**
  String get tabKr;

  /// No description provided for @tabUs.
  ///
  /// In en, this message translates to:
  /// **'US'**
  String get tabUs;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search stocks'**
  String get searchHint;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearches;

  /// No description provided for @financialStatements.
  ///
  /// In en, this message translates to:
  /// **'Financial statements'**
  String get financialStatements;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @undervalued.
  ///
  /// In en, this message translates to:
  /// **'Undervalued'**
  String get undervalued;

  /// No description provided for @fairValue.
  ///
  /// In en, this message translates to:
  /// **'Fair value'**
  String get fairValue;

  /// No description provided for @currentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get currentPrice;

  /// No description provided for @expectedReturn.
  ///
  /// In en, this message translates to:
  /// **'Expected return'**
  String get expectedReturn;

  /// No description provided for @dividendYield.
  ///
  /// In en, this message translates to:
  /// **'Dividend yield'**
  String get dividendYield;

  /// No description provided for @roe.
  ///
  /// In en, this message translates to:
  /// **'ROE'**
  String get roe;

  /// No description provided for @per.
  ///
  /// In en, this message translates to:
  /// **'PER'**
  String get per;

  /// No description provided for @pbr.
  ///
  /// In en, this message translates to:
  /// **'PBR'**
  String get pbr;

  /// No description provided for @veryUndervalued.
  ///
  /// In en, this message translates to:
  /// **'Very undervalued'**
  String get veryUndervalued;

  /// No description provided for @undervaluedLabel.
  ///
  /// In en, this message translates to:
  /// **'Undervalued'**
  String get undervaluedLabel;

  /// No description provided for @nearFairValue.
  ///
  /// In en, this message translates to:
  /// **'Near fair value'**
  String get nearFairValue;

  /// No description provided for @expensive.
  ///
  /// In en, this message translates to:
  /// **'Expensive'**
  String get expensive;

  /// No description provided for @veryExpensive.
  ///
  /// In en, this message translates to:
  /// **'Very expensive'**
  String get veryExpensive;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @companyDescription.
  ///
  /// In en, this message translates to:
  /// **'An app for conservative investors who focus on clear financial data rather than uncertain future predictions or speculative trading.'**
  String get companyDescription;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @emailInquiry.
  ///
  /// In en, this message translates to:
  /// **'Email inquiry'**
  String get emailInquiry;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates in store'**
  String get checkForUpdates;

  /// No description provided for @installLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Install the latest version'**
  String get installLatestVersion;

  /// No description provided for @misc.
  ///
  /// In en, this message translates to:
  /// **'Misc'**
  String get misc;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @invalidLink.
  ///
  /// In en, this message translates to:
  /// **'The link format is invalid.'**
  String get invalidLink;

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the link.'**
  String get cannotOpenLink;

  /// No description provided for @cannotOpenMailApp.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the mail app.'**
  String get cannotOpenMailApp;

  /// No description provided for @privacyOpenWeb.
  ///
  /// In en, this message translates to:
  /// **'Open web page'**
  String get privacyOpenWeb;

  /// No description provided for @appInquirySubject.
  ///
  /// In en, this message translates to:
  /// **'[App Inquiry]'**
  String get appInquirySubject;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String versionLabel(String version);

  /// No description provided for @rankingPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Undervalued Companies'**
  String get rankingPageTitle;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @krRankSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by stock name or code'**
  String get krRankSearchHint;

  /// No description provided for @usRankSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by company name or ticker'**
  String get usRankSearchHint;

  /// No description provided for @rankingUpdatedMeta.
  ///
  /// In en, this message translates to:
  /// **'{updated} (based on expected return)'**
  String rankingUpdatedMeta(String updated);

  /// No description provided for @rankingItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String rankingItemCount(int count);

  /// No description provided for @rankingPriceMayUpdate.
  ///
  /// In en, this message translates to:
  /// **'Current prices may update again after opening this screen.'**
  String get rankingPriceMayUpdate;

  /// No description provided for @rankingStillGeneratingWait.
  ///
  /// In en, this message translates to:
  /// **'Ranking is being generated... Please wait!'**
  String get rankingStillGeneratingWait;

  /// No description provided for @requestUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Request URL'**
  String get requestUrlLabel;

  /// No description provided for @krRankingGeneratingWait.
  ///
  /// In en, this message translates to:
  /// **'KR ranking is being generated... Please wait.'**
  String get krRankingGeneratingWait;

  /// No description provided for @krRankingGeneratingRetry.
  ///
  /// In en, this message translates to:
  /// **'KR ranking is being generated... Please try again shortly.'**
  String get krRankingGeneratingRetry;

  /// No description provided for @krRankingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing KR ranking...'**
  String get krRankingPreparing;

  /// No description provided for @krRankingSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results found in KR ranking search.'**
  String get krRankingSearchEmpty;

  /// No description provided for @usRankingGeneratingWait.
  ///
  /// In en, this message translates to:
  /// **'US ranking is being generated... Please wait.'**
  String get usRankingGeneratingWait;

  /// No description provided for @usRankingGeneratingRetry.
  ///
  /// In en, this message translates to:
  /// **'US ranking is being generated... Please try again shortly.'**
  String get usRankingGeneratingRetry;

  /// No description provided for @usRankingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing US ranking...'**
  String get usRankingPreparing;

  /// No description provided for @usRankingSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results found in US ranking search.'**
  String get usRankingSearchEmpty;

  /// No description provided for @previousDayChangeNone.
  ///
  /// In en, this message translates to:
  /// **'Previous day -'**
  String get previousDayChangeNone;

  /// No description provided for @changeNone.
  ///
  /// In en, this message translates to:
  /// **'Change -'**
  String get changeNone;

  /// No description provided for @usRankingError.
  ///
  /// In en, this message translates to:
  /// **'US ranking error: {error}'**
  String usRankingError(String error);

  /// No description provided for @searchPageCompactHintKr.
  ///
  /// In en, this message translates to:
  /// **'Name/Code'**
  String get searchPageCompactHintKr;

  /// No description provided for @searchPageCompactHintUs.
  ///
  /// In en, this message translates to:
  /// **'Ticker'**
  String get searchPageCompactHintUs;

  /// No description provided for @searchPageHintKr.
  ///
  /// In en, this message translates to:
  /// **'Korean stock name or code (e.g. Samsung Electronics / 005930)'**
  String get searchPageHintKr;

  /// No description provided for @searchPageHintUs.
  ///
  /// In en, this message translates to:
  /// **'US ticker (e.g. AAPL / TSLA)'**
  String get searchPageHintUs;

  /// No description provided for @searchTabLooksKrGuide.
  ///
  /// In en, this message translates to:
  /// **'This looks like a Korean stock. Please search in the Korea tab.'**
  String get searchTabLooksKrGuide;

  /// No description provided for @searchErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchErrorEmpty;

  /// No description provided for @searchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @marketUs.
  ///
  /// In en, this message translates to:
  /// **'US'**
  String get marketUs;

  /// No description provided for @marketUnknown.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get marketUnknown;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @searchPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock Search'**
  String get searchPageTitle;

  /// No description provided for @moreMenu.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreMenu;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImport;

  /// No description provided for @exportBackupCanceled.
  ///
  /// In en, this message translates to:
  /// **'Backup export was canceled.'**
  String get exportBackupCanceled;

  /// No description provided for @exportBackupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup file created.\n{path}'**
  String exportBackupCreated(String path);

  /// No description provided for @exportBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup export failed: {error}'**
  String exportBackupFailed(String error);

  /// No description provided for @importBackupCanceled.
  ///
  /// In en, this message translates to:
  /// **'Backup import was canceled.'**
  String get importBackupCanceled;

  /// No description provided for @importBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackupTitle;

  /// No description provided for @importBackupConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will replace the current device\'s favorites, recent searches, and inputs with the contents of the backup file.\n\nDo you want to continue?'**
  String get importBackupConfirm;

  /// No description provided for @importButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importButton;

  /// No description provided for @importBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup file imported.'**
  String get importBackupSuccess;

  /// No description provided for @importBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup import failed: {error}'**
  String importBackupFailed(String error);

  /// No description provided for @recentDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recent search'**
  String get recentDeleteTitle;

  /// No description provided for @recentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}({code}) from recent searches?'**
  String recentDeleteConfirm(String name, String code);

  /// No description provided for @clearRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all recent searches'**
  String get clearRecentTitle;

  /// No description provided for @clearRecentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all recent searches?'**
  String get clearRecentConfirm;

  /// No description provided for @favoritesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete favorite'**
  String get favoritesDeleteTitle;

  /// No description provided for @favoritesDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}({code}) from favorites?'**
  String favoritesDeleteConfirm(String name, String code);

  /// No description provided for @clearFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all favorites'**
  String get clearFavoritesTitle;

  /// No description provided for @clearFavoritesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all favorites?'**
  String get clearFavoritesConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deletedItem.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String deletedItem(String name);

  /// No description provided for @recentCleared.
  ///
  /// In en, this message translates to:
  /// **'All recent searches have been deleted.'**
  String get recentCleared;

  /// No description provided for @favoritesCleared.
  ///
  /// In en, this message translates to:
  /// **'All favorites have been deleted.'**
  String get favoritesCleared;

  /// No description provided for @viewValuation.
  ///
  /// In en, this message translates to:
  /// **'View valuation'**
  String get viewValuation;

  /// No description provided for @autoSearchHelp.
  ///
  /// In en, this message translates to:
  /// **'Auto-search runs automatically, and you can also search immediately with the magnifier on the right.'**
  String get autoSearchHelp;

  /// No description provided for @recentSearchesDeleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all recent searches'**
  String get recentSearchesDeleteAllTooltip;

  /// No description provided for @favoritesDeleteAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all favorites'**
  String get favoritesDeleteAllTooltip;

  /// No description provided for @recentSearchesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent searches yet'**
  String get recentSearchesEmptyTitle;

  /// No description provided for @recentSearchesEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Try searching for a stock above. Your search history will appear here.'**
  String get recentSearchesEmptyDesc;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites are empty'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap the ⭐ button on the stock valuation screen to collect items here.'**
  String get favoritesEmptyDesc;

  /// No description provided for @emptySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get emptySearchTitle;

  /// No description provided for @emptySearchDescKrTryUs.
  ///
  /// In en, this message translates to:
  /// **'If there are no results in Korea, try searching the ticker in the US tab.'**
  String get emptySearchDescKrTryUs;

  /// No description provided for @emptySearchDescKrCheck.
  ///
  /// In en, this message translates to:
  /// **'Please check the stock name/code again.'**
  String get emptySearchDescKrCheck;

  /// No description provided for @emptySearchDescUsCheck.
  ///
  /// In en, this message translates to:
  /// **'Please check the ticker again.'**
  String get emptySearchDescUsCheck;

  /// No description provided for @detailPageOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open details screen: {error}'**
  String detailPageOpenFailed(String error);

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @openNaverKr.
  ///
  /// In en, this message translates to:
  /// **'Naver'**
  String get openNaverKr;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadingPriceStart.
  ///
  /// In en, this message translates to:
  /// **'Loading price'**
  String get loadingPriceStart;

  /// No description provided for @loadingPriceTimeout.
  ///
  /// In en, this message translates to:
  /// **'Price request timed out (8s)'**
  String get loadingPriceTimeout;

  /// No description provided for @loadingFundamentalsStart.
  ///
  /// In en, this message translates to:
  /// **'Loading fundamentals (EPS/BPS/DPS)'**
  String get loadingFundamentalsStart;

  /// No description provided for @loadingFundamentalsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Fundamentals request timed out (12s)'**
  String get loadingFundamentalsTimeout;

  /// No description provided for @loadingApplyInitial.
  ///
  /// In en, this message translates to:
  /// **'Applying initial values'**
  String get loadingApplyInitial;

  /// No description provided for @loadingRestoreSaved.
  ///
  /// In en, this message translates to:
  /// **'Restoring saved values'**
  String get loadingRestoreSaved;

  /// No description provided for @loadingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get loadingDone;

  /// No description provided for @reloadedValues.
  ///
  /// In en, this message translates to:
  /// **'Values were reloaded.'**
  String get reloadedValues;

  /// No description provided for @naverOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the Naver page.'**
  String get naverOpenFailed;

  /// No description provided for @naverUsHint.
  ///
  /// In en, this message translates to:
  /// **'For overseas stocks, search the ticker in Naver Global Stocks.'**
  String get naverUsHint;

  /// No description provided for @viewFinancialStatements.
  ///
  /// In en, this message translates to:
  /// **'View financial statements'**
  String get viewFinancialStatements;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @financialSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial source: {source}'**
  String financialSourceLabel(String source);

  /// No description provided for @valuationErrorInvalidRequiredReturn.
  ///
  /// In en, this message translates to:
  /// **'Required return r must be greater than 0.'**
  String get valuationErrorInvalidRequiredReturn;

  /// No description provided for @valuationErrorInvalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Current price must be greater than 0.'**
  String get valuationErrorInvalidPrice;

  /// No description provided for @valuationErrorInvalidBps.
  ///
  /// In en, this message translates to:
  /// **'It is difficult to calculate when BPS is 0 or below.'**
  String get valuationErrorInvalidBps;

  /// No description provided for @backupErrorInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'The backup format is invalid.'**
  String get backupErrorInvalidFormat;

  /// No description provided for @backupErrorWrongApp.
  ///
  /// In en, this message translates to:
  /// **'This is not a backup file for this app.'**
  String get backupErrorWrongApp;

  /// No description provided for @backupErrorUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'This backup version is not supported.'**
  String get backupErrorUnsupportedVersion;

  /// No description provided for @fsPdfDocumentTitleSuffix.
  ///
  /// In en, this message translates to:
  /// **'Financial Statements'**
  String get fsPdfDocumentTitleSuffix;

  /// No description provided for @fsPdfSummarySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Statement Summary'**
  String get fsPdfSummarySectionTitle;

  /// No description provided for @fsPdfBuffettAssistSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Buffett-style Helper Metrics'**
  String get fsPdfBuffettAssistSectionTitle;

  /// No description provided for @fsPdfTrendSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Long-term Trend'**
  String get fsPdfTrendSectionTitle;

  /// No description provided for @fsPdfStabilitySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stability'**
  String get fsPdfStabilitySectionTitle;

  /// No description provided for @fsPdfPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get fsPdfPeriodLabel;

  /// No description provided for @fsPdfRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get fsPdfRevenueLabel;

  /// No description provided for @fsPdfOpIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Operating income'**
  String get fsPdfOpIncomeLabel;

  /// No description provided for @fsPdfNetIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Net income'**
  String get fsPdfNetIncomeLabel;

  /// No description provided for @fsPdfEquityLabel.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get fsPdfEquityLabel;

  /// No description provided for @fsPdfLiabilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get fsPdfLiabilitiesLabel;

  /// No description provided for @fsPdfFinancialSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial source'**
  String get fsPdfFinancialSourceLabel;

  /// No description provided for @fsPdfAvg3yEpsLabel.
  ///
  /// In en, this message translates to:
  /// **'3Y average EPS'**
  String get fsPdfAvg3yEpsLabel;

  /// No description provided for @fsPdfAvg5yRoeLabel.
  ///
  /// In en, this message translates to:
  /// **'5Y average ROE'**
  String get fsPdfAvg5yRoeLabel;

  /// No description provided for @fsPdfYearlyEpsLabel.
  ///
  /// In en, this message translates to:
  /// **'EPS by year'**
  String get fsPdfYearlyEpsLabel;

  /// No description provided for @fsPdfYearlyRoeLabel.
  ///
  /// In en, this message translates to:
  /// **'ROE by year'**
  String get fsPdfYearlyRoeLabel;

  /// No description provided for @fsPdfLossYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Loss years'**
  String get fsPdfLossYearsLabel;

  /// No description provided for @fsPdfDebtRatioLabel.
  ///
  /// In en, this message translates to:
  /// **'Debt ratio'**
  String get fsPdfDebtRatioLabel;

  /// No description provided for @fsPdfRecentDividendLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent dividend'**
  String get fsPdfRecentDividendLabel;

  /// No description provided for @fsPdfDisclaimerText.
  ///
  /// In en, this message translates to:
  /// **'This document is for investment reference only.'**
  String get fsPdfDisclaimerText;

  /// No description provided for @fsPdfShareTextSuffix.
  ///
  /// In en, this message translates to:
  /// **'Financial Statements PDF'**
  String get fsPdfShareTextSuffix;

  /// No description provided for @fsPdfPlatformNotSupportedText.
  ///
  /// In en, this message translates to:
  /// **'Saving PDF is not supported on this platform.'**
  String get fsPdfPlatformNotSupportedText;

  /// No description provided for @fsPdfFontLoadErrorText.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF fonts.\nCheck assets/fonts/NotoSansKR-Regular.ttf\nCheck assets/fonts/NotoSansKR-Bold.ttf\nThen run flutter clean and try again.'**
  String get fsPdfFontLoadErrorText;

  /// No description provided for @resultPdfInputSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get resultPdfInputSectionTitle;

  /// No description provided for @resultPdfResultSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultPdfResultSectionTitle;

  /// No description provided for @resultPdfRatingSummarySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rating Summary'**
  String get resultPdfRatingSummarySectionTitle;

  /// No description provided for @resultPdfFinancialSummarySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get resultPdfFinancialSummarySectionTitle;

  /// No description provided for @resultPdfNoteSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get resultPdfNoteSectionTitle;

  /// No description provided for @resultPdfCurrentPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current price'**
  String get resultPdfCurrentPriceLabel;

  /// No description provided for @resultPdfEpsLabel.
  ///
  /// In en, this message translates to:
  /// **'EPS'**
  String get resultPdfEpsLabel;

  /// No description provided for @resultPdfBpsLabel.
  ///
  /// In en, this message translates to:
  /// **'BPS'**
  String get resultPdfBpsLabel;

  /// No description provided for @resultPdfDpsLabel.
  ///
  /// In en, this message translates to:
  /// **'DPS'**
  String get resultPdfDpsLabel;

  /// No description provided for @resultPdfRequiredReturnLabel.
  ///
  /// In en, this message translates to:
  /// **'Required return r'**
  String get resultPdfRequiredReturnLabel;

  /// No description provided for @resultPdfFairPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Fair price'**
  String get resultPdfFairPriceLabel;

  /// No description provided for @resultPdfExpectedReturnLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected return'**
  String get resultPdfExpectedReturnLabel;

  /// No description provided for @resultPdfValuationStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Valuation status'**
  String get resultPdfValuationStatusLabel;

  /// No description provided for @resultPdfRoeLabel.
  ///
  /// In en, this message translates to:
  /// **'ROE'**
  String get resultPdfRoeLabel;

  /// No description provided for @resultPdfDividendYieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Dividend yield'**
  String get resultPdfDividendYieldLabel;

  /// No description provided for @resultPdfPerLabel.
  ///
  /// In en, this message translates to:
  /// **'PER'**
  String get resultPdfPerLabel;

  /// No description provided for @resultPdfPbrLabel.
  ///
  /// In en, this message translates to:
  /// **'PBR'**
  String get resultPdfPbrLabel;

  /// No description provided for @resultPdfRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get resultPdfRatingLabel;

  /// No description provided for @resultPdfFinancialBasisLabel.
  ///
  /// In en, this message translates to:
  /// **'Basis'**
  String get resultPdfFinancialBasisLabel;

  /// No description provided for @resultPdfRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get resultPdfRevenueLabel;

  /// No description provided for @resultPdfOpIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Operating income'**
  String get resultPdfOpIncomeLabel;

  /// No description provided for @resultPdfNetIncomeLabel.
  ///
  /// In en, this message translates to:
  /// **'Net income'**
  String get resultPdfNetIncomeLabel;

  /// No description provided for @resultPdfEquityLabel.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get resultPdfEquityLabel;

  /// No description provided for @resultPdfLiabilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get resultPdfLiabilitiesLabel;

  /// No description provided for @resultPdfFinancialSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Financial source'**
  String get resultPdfFinancialSourceLabel;

  /// No description provided for @resultPdfCalcUnavailablePrefix.
  ///
  /// In en, this message translates to:
  /// **'Calculation unavailable'**
  String get resultPdfCalcUnavailablePrefix;

  /// No description provided for @resultPdfDisclaimerText.
  ///
  /// In en, this message translates to:
  /// **'This document is for investment reference only.'**
  String get resultPdfDisclaimerText;

  /// No description provided for @resultPdfShareTextSuffix.
  ///
  /// In en, this message translates to:
  /// **'PDF report'**
  String get resultPdfShareTextSuffix;

  /// No description provided for @resultPdfPlatformNotSupportedText.
  ///
  /// In en, this message translates to:
  /// **'Saving PDF is not supported on this platform.'**
  String get resultPdfPlatformNotSupportedText;

  /// No description provided for @resultPdfFontLoadErrorText.
  ///
  /// In en, this message translates to:
  /// **'Failed to load PDF fonts.\n1) Check assets/fonts/NotoSansKR-Regular.ttf\n2) Check assets/fonts/NotoSansKR-Bold.ttf\n3) Register them in pubspec.yaml\n4) Run flutter clean and try again.'**
  String get resultPdfFontLoadErrorText;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'An update is available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version is ready. Would you like to update now?'**
  String get updateAvailableMessage;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateNow;

  /// No description provided for @updateAvailableBadge.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableBadge;

  /// No description provided for @updateFromAbout.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateFromAbout;

  /// No description provided for @updateCheckInAboutHint.
  ///
  /// In en, this message translates to:
  /// **'You can continue the update from About.'**
  String get updateCheckInAboutHint;

  /// No description provided for @updateAvailableMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableMenuTitle;

  /// No description provided for @updateAvailableMenuSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. Tap to update.'**
  String get updateAvailableMenuSubtitle;

  /// No description provided for @loadingApplyRankingSnapshot.
  ///
  /// In en, this message translates to:
  /// **'Applying ranking values'**
  String get loadingApplyRankingSnapshot;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
