import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'HOPE IPTV'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get navLive;

  /// No description provided for @navMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get navMovies;

  /// No description provided for @navSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get navSeries;

  /// No description provided for @navGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get navGuide;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @actionPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actionPlay;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get actionWatch;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get actionTryAgain;

  /// No description provided for @actionSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get actionSignIn;

  /// No description provided for @actionSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get actionSignOut;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get actionClearAll;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get actionDetails;

  /// No description provided for @actionSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get actionSeeAll;

  /// No description provided for @actionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get actionSelect;

  /// No description provided for @actionApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get actionReplay;

  /// No description provided for @labelServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get labelServerUrl;

  /// No description provided for @labelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get labelUsername;

  /// No description provided for @labelPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get labelPassword;

  /// No description provided for @labelLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get labelLoading;

  /// No description provided for @labelNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get labelNoResults;

  /// No description provided for @labelEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get labelEmpty;

  /// No description provided for @labelLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get labelLive;

  /// No description provided for @labelFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get labelFavorites;

  /// No description provided for @labelContinueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get labelContinueWatching;

  /// No description provided for @labelLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get labelLiveNow;

  /// No description provided for @labelRecentlyWatched.
  ///
  /// In en, this message translates to:
  /// **'Recently Watched'**
  String get labelRecentlyWatched;

  /// No description provided for @labelChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get labelChannels;

  /// No description provided for @labelMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get labelMovies;

  /// No description provided for @labelSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get labelSeries;

  /// No description provided for @labelCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get labelCategories;

  /// No description provided for @labelAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get labelAll;

  /// No description provided for @labelAllChannels.
  ///
  /// In en, this message translates to:
  /// **'All Channels'**
  String get labelAllChannels;

  /// No description provided for @labelAllMovies.
  ///
  /// In en, this message translates to:
  /// **'All Movies'**
  String get labelAllMovies;

  /// No description provided for @labelAllSeries.
  ///
  /// In en, this message translates to:
  /// **'All Series'**
  String get labelAllSeries;

  /// No description provided for @labelEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get labelEpisodes;

  /// No description provided for @labelSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get labelSeasons;

  /// No description provided for @labelSeason.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String labelSeason(int number);

  /// No description provided for @labelEpisode.
  ///
  /// In en, this message translates to:
  /// **'Episode {number}'**
  String labelEpisode(int number);

  /// No description provided for @labelNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get labelNoDescription;

  /// No description provided for @labelRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get labelRating;

  /// No description provided for @labelYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get labelYear;

  /// No description provided for @labelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDuration;

  /// No description provided for @labelDirector.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get labelDirector;

  /// No description provided for @labelCast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get labelCast;

  /// No description provided for @labelGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get labelGenre;

  /// No description provided for @labelPlot.
  ///
  /// In en, this message translates to:
  /// **'Plot'**
  String get labelPlot;

  /// No description provided for @labelReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get labelReleaseDate;

  /// No description provided for @labelNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get labelNowPlaying;

  /// No description provided for @labelUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get labelUpcoming;

  /// No description provided for @labelNoEpg.
  ///
  /// In en, this message translates to:
  /// **'No EPG Available'**
  String get labelNoEpg;

  /// No description provided for @labelChannelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No channels} =1{1 Channel} other{{count} Channels}}'**
  String labelChannelCount(int count);

  /// No description provided for @labelMovieCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No movies} =1{1 Movie} other{{count} Movies}}'**
  String labelMovieCount(int count);

  /// No description provided for @labelSeriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No series} =1{1 Series} other{{count} Series}}'**
  String labelSeriesCount(int count);

  /// No description provided for @homeFeaturedMovies.
  ///
  /// In en, this message translates to:
  /// **'Featured Movies'**
  String get homeFeaturedMovies;

  /// No description provided for @homePopularSeries.
  ///
  /// In en, this message translates to:
  /// **'Popular Series'**
  String get homePopularSeries;

  /// No description provided for @homeSportsChannels.
  ///
  /// In en, this message translates to:
  /// **'Sports Channels'**
  String get homeSportsChannels;

  /// No description provided for @homeNewsChannels.
  ///
  /// In en, this message translates to:
  /// **'News & Current Affairs'**
  String get homeNewsChannels;

  /// No description provided for @homeTvGuide.
  ///
  /// In en, this message translates to:
  /// **'TV Guide'**
  String get homeTvGuide;

  /// No description provided for @homeAllMovies.
  ///
  /// In en, this message translates to:
  /// **'All Movies'**
  String get homeAllMovies;

  /// No description provided for @homeEmptyPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No media content found'**
  String get homeEmptyPlaylist;

  /// No description provided for @homeEmptyPlaylistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please check your playlist or server configuration.'**
  String get homeEmptyPlaylistSubtitle;

  /// No description provided for @homeCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your server settings or network connection.'**
  String get homeCheckConnection;

  /// No description provided for @liveCategoriesHub.
  ///
  /// In en, this message translates to:
  /// **'Live Channels'**
  String get liveCategoriesHub;

  /// No description provided for @liveSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in channels...'**
  String get liveSearchHint;

  /// No description provided for @liveNoChannelsFound.
  ///
  /// In en, this message translates to:
  /// **'No channels found in this category.'**
  String get liveNoChannelsFound;

  /// No description provided for @liveMiniPreview.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get liveMiniPreview;

  /// No description provided for @liveNextProgram.
  ///
  /// In en, this message translates to:
  /// **'Next: {title}'**
  String liveNextProgram(String title);

  /// No description provided for @moviesCategoriesHub.
  ///
  /// In en, this message translates to:
  /// **'Movie Categories'**
  String get moviesCategoriesHub;

  /// No description provided for @moviesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search movies...'**
  String get moviesSearchHint;

  /// No description provided for @moviesNoMoviesFound.
  ///
  /// In en, this message translates to:
  /// **'No movies found in this category.'**
  String get moviesNoMoviesFound;

  /// No description provided for @seriesCategoriesHub.
  ///
  /// In en, this message translates to:
  /// **'Series Categories'**
  String get seriesCategoriesHub;

  /// No description provided for @seriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search series...'**
  String get seriesSearchHint;

  /// No description provided for @seriesNoSeriesFound.
  ///
  /// In en, this message translates to:
  /// **'No series found in this category.'**
  String get seriesNoSeriesFound;

  /// No description provided for @seriesSelectSeason.
  ///
  /// In en, this message translates to:
  /// **'Select Season'**
  String get seriesSelectSeason;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Electronic Program Guide'**
  String get guideTitle;

  /// No description provided for @guideNoData.
  ///
  /// In en, this message translates to:
  /// **'No Guide Data Available'**
  String get guideNoData;

  /// No description provided for @guideNoDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Channels or EPG data could not be loaded.'**
  String get guideNoDataSubtitle;

  /// No description provided for @guideToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get guideToday;

  /// No description provided for @guideTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get guideTomorrow;

  /// No description provided for @guideYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get guideYesterday;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels, movies, series...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try checking the spelling or use different keywords.'**
  String get searchNoResultsSubtitle;

  /// No description provided for @searchLiveTab.
  ///
  /// In en, this message translates to:
  /// **'Live Channels ({count})'**
  String searchLiveTab(int count);

  /// No description provided for @searchMoviesTab.
  ///
  /// In en, this message translates to:
  /// **'Movies ({count})'**
  String searchMoviesTab(int count);

  /// No description provided for @searchSeriesTab.
  ///
  /// In en, this message translates to:
  /// **'Series ({count})'**
  String searchSeriesTab(int count);

  /// No description provided for @searchRecentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get searchRecentSearches;

  /// No description provided for @searchTypeToFind.
  ///
  /// In en, this message translates to:
  /// **'Search anything across your IPTV library'**
  String get searchTypeToFind;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add channels, movies, or series to your favorites to access them quickly.'**
  String get favoritesEmptySubtitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch History'**
  String get historyTitle;

  /// No description provided for @historyClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get historyClearTooltip;

  /// No description provided for @historyClearDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Watch History'**
  String get historyClearDialogTitle;

  /// No description provided for @historyClearDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your entire watch history? This cannot be undone.'**
  String get historyClearDialogContent;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No watch history'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Streams, movies, and series you watch will appear here.'**
  String get historyEmptySubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsConnectedServer.
  ///
  /// In en, this message translates to:
  /// **'Connected Server'**
  String get settingsConnectedServer;

  /// No description provided for @settingsUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get settingsUser;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get settingsArabic;

  /// No description provided for @settingsConfirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsConfirmSignOut;

  /// No description provided for @settingsConfirmSignOutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out from this server?'**
  String get settingsConfirmSignOutMessage;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to IPTV'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your server details to get started.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingServerGateway.
  ///
  /// In en, this message translates to:
  /// **'Server Gateway'**
  String get onboardingServerGateway;

  /// No description provided for @onboardingCustomServer.
  ///
  /// In en, this message translates to:
  /// **'Custom Xtream Server'**
  String get onboardingCustomServer;

  /// No description provided for @onboardingM3uNotice.
  ///
  /// In en, this message translates to:
  /// **'✨ M3U link detected & converted to Xtream Fast Stream mode!'**
  String get onboardingM3uNotice;

  /// No description provided for @onboardingFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get onboardingFillFields;

  /// No description provided for @authConnectServer.
  ///
  /// In en, this message translates to:
  /// **'Connect Server'**
  String get authConnectServer;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your IPTV provider credentials'**
  String get authSignInSubtitle;

  /// No description provided for @authServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL (or Paste M3U Link)'**
  String get authServerUrl;

  /// No description provided for @authUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @actionConnectStream.
  ///
  /// In en, this message translates to:
  /// **'Connect & Stream'**
  String get actionConnectStream;

  /// No description provided for @onboardingBadge.
  ///
  /// In en, this message translates to:
  /// **'STREAMING ENGINE V2'**
  String get onboardingBadge;

  /// No description provided for @onboardingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Experience TV\nWithout Limits.'**
  String get onboardingHeroTitle;

  /// No description provided for @onboardingHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to your Xtream cluster or convert any M3U link to enjoy zero-buffer streaming, 4K HDR playback, and live electronic program guides.'**
  String get onboardingHeroSubtitle;

  /// No description provided for @onboardingFeat1Title.
  ///
  /// In en, this message translates to:
  /// **'Zero-Buffer Fast Zapping'**
  String get onboardingFeat1Title;

  /// No description provided for @onboardingFeat1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant stream decoding with hardware acceleration'**
  String get onboardingFeat1Subtitle;

  /// No description provided for @onboardingFeat2Title.
  ///
  /// In en, this message translates to:
  /// **'Smart M3U → Xtream Engine'**
  String get onboardingFeat2Title;

  /// No description provided for @onboardingFeat2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Converts raw playlist links to direct APIs for instant buffering'**
  String get onboardingFeat2Subtitle;

  /// No description provided for @onboardingFeat3Title.
  ///
  /// In en, this message translates to:
  /// **'Modular Gateway Clusters'**
  String get onboardingFeat3Title;

  /// No description provided for @onboardingFeat3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Seamlessly switch between primary, backup, and custom servers'**
  String get onboardingFeat3Subtitle;

  /// No description provided for @onboardingFeat4Title.
  ///
  /// In en, this message translates to:
  /// **'Live EPG & Catch-Up Guide'**
  String get onboardingFeat4Title;

  /// No description provided for @onboardingFeat4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete schedule synchronization and timeline recall'**
  String get onboardingFeat4Subtitle;

  /// No description provided for @onboardingClientTitle.
  ///
  /// In en, this message translates to:
  /// **'IPTV CLIENT'**
  String get onboardingClientTitle;

  /// No description provided for @onboardingClientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access your live channels & VOD'**
  String get onboardingClientSubtitle;

  /// No description provided for @onboardingHaveM3u.
  ///
  /// In en, this message translates to:
  /// **'Have an M3U Playlist Link?'**
  String get onboardingHaveM3u;

  /// No description provided for @onboardingM3uConvertHint.
  ///
  /// In en, this message translates to:
  /// **'Convert to zero-buffer Xtream engine in 1-tap'**
  String get onboardingM3uConvertHint;

  /// No description provided for @actionConvert.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get actionConvert;

  /// No description provided for @onboardingActiveGateway.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE SERVER GATEWAY'**
  String get onboardingActiveGateway;

  /// No description provided for @onboardingGatewaysAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} Available'**
  String onboardingGatewaysAvailable(int count);

  /// No description provided for @onboardingManual.
  ///
  /// In en, this message translates to:
  /// **'MANUAL'**
  String get onboardingManual;

  /// No description provided for @onboardingOnline.
  ///
  /// In en, this message translates to:
  /// **'ONLINE'**
  String get onboardingOnline;

  /// No description provided for @onboardingCustomConfig.
  ///
  /// In en, this message translates to:
  /// **'Custom server URL configuration'**
  String get onboardingCustomConfig;

  /// No description provided for @actionChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get actionChange;

  /// No description provided for @onboardingAutoConfig.
  ///
  /// In en, this message translates to:
  /// **'AUTO-CONFIG'**
  String get onboardingAutoConfig;

  /// No description provided for @onboardingEnterCustomUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter custom URL manually'**
  String get onboardingEnterCustomUrl;

  /// No description provided for @onboardingUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://example.com:8080 or get.php M3U link'**
  String get onboardingUrlHint;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get validationUsernameRequired;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Server URL is required'**
  String get validationUrlRequired;

  /// No description provided for @validationUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'URL must start with http:// or https://'**
  String get validationUrlInvalid;

  /// No description provided for @gatewayDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Server Gateway'**
  String get gatewayDialogTitle;

  /// No description provided for @gatewayDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose from {count} configured clusters or custom endpoint'**
  String gatewayDialogSubtitle(int count);

  /// No description provided for @gatewaySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search server by name, location, or URL...'**
  String get gatewaySearchHint;

  /// No description provided for @gatewayFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All Gateways ({count})'**
  String gatewayFilterAll(int count);

  /// No description provided for @gatewayFilterOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official ({count})'**
  String gatewayFilterOfficial(int count);

  /// No description provided for @gatewayFilterCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom Endpoint'**
  String get gatewayFilterCustom;

  /// No description provided for @gatewayNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No server gateways match your search'**
  String get gatewayNoMatches;

  /// No description provided for @m3uConverterTitle.
  ///
  /// In en, this message translates to:
  /// **'M3U to Xtream Converter'**
  String get m3uConverterTitle;

  /// No description provided for @m3uConverterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Extracts Xtream credentials for zero buffering'**
  String get m3uConverterSubtitle;

  /// No description provided for @m3uPasteLabel.
  ///
  /// In en, this message translates to:
  /// **'PASTE M3U URL OR STREAM LINK'**
  String get m3uPasteLabel;

  /// No description provided for @actionPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get actionPaste;

  /// No description provided for @m3uExtractError.
  ///
  /// In en, this message translates to:
  /// **'Could not extract Xtream credentials from this M3U link.'**
  String get m3uExtractError;

  /// No description provided for @m3uExtractedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Xtream Credentials Extracted'**
  String get m3uExtractedSuccess;

  /// No description provided for @m3uAdvantageHint.
  ///
  /// In en, this message translates to:
  /// **'Xtream format unlocks category filtering, live EPG, VOD metadata, and zero-buffering hardware streaming.'**
  String get m3uAdvantageHint;

  /// No description provided for @actionConvertAndConnect.
  ///
  /// In en, this message translates to:
  /// **'Convert & Connect'**
  String get actionConvertAndConnect;

  /// No description provided for @playerConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get playerConnecting;

  /// No description provided for @playerReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get playerReconnecting;

  /// No description provided for @playerBuffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering...'**
  String get playerBuffering;

  /// No description provided for @playerStreamUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Stream unavailable'**
  String get playerStreamUnavailable;

  /// No description provided for @playerAudioTracks.
  ///
  /// In en, this message translates to:
  /// **'Audio Tracks'**
  String get playerAudioTracks;

  /// No description provided for @playerSubtitles.
  ///
  /// In en, this message translates to:
  /// **'Subtitles'**
  String get playerSubtitles;

  /// No description provided for @playerAspectRatio.
  ///
  /// In en, this message translates to:
  /// **'Aspect Ratio'**
  String get playerAspectRatio;

  /// No description provided for @playerQuality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get playerQuality;

  /// No description provided for @playerTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get playerTapToRetry;

  /// No description provided for @playerPreviousChannel.
  ///
  /// In en, this message translates to:
  /// **'Previous Channel'**
  String get playerPreviousChannel;

  /// No description provided for @playerNextChannel.
  ///
  /// In en, this message translates to:
  /// **'Next Channel'**
  String get playerNextChannel;

  /// No description provided for @playerReplay10.
  ///
  /// In en, this message translates to:
  /// **'Replay 10s'**
  String get playerReplay10;

  /// No description provided for @playerForward10.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get playerForward10;

  /// No description provided for @historyResumeAt.
  ///
  /// In en, this message translates to:
  /// **'Resume at {time}'**
  String historyResumeAt(String time);

  /// No description provided for @historyResumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Resume playback'**
  String get historyResumePlayback;

  /// No description provided for @historyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get historyCompleted;

  /// No description provided for @historyTimeLeftHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m left'**
  String historyTimeLeftHoursMinutes(int hours, int minutes);

  /// No description provided for @historyTimeLeftMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String historyTimeLeftMinutes(int minutes);

  /// No description provided for @historyWatchedOn.
  ///
  /// In en, this message translates to:
  /// **'Watched on {date}'**
  String historyWatchedOn(String date);

  /// No description provided for @historyProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{pos}/{dur} min • Watched on {date}'**
  String historyProgressSubtitle(int pos, int dur, String date);

  /// No description provided for @historyTypeLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get historyTypeLive;

  /// No description provided for @historyTypeMovie.
  ///
  /// In en, this message translates to:
  /// **'MOVIE'**
  String get historyTypeMovie;

  /// No description provided for @historyTypeSeries.
  ///
  /// In en, this message translates to:
  /// **'SERIES'**
  String get historyTypeSeries;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again.'**
  String get errorServer;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please check your details.'**
  String get errorAuth;

  /// No description provided for @errorPlayback.
  ///
  /// In en, this message translates to:
  /// **'Stream unavailable'**
  String get errorPlayback;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorUnknown;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'HOPE TV Account'**
  String get accountTitle;

  /// No description provided for @accountSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to HOPE TV'**
  String get accountSignInTitle;

  /// No description provided for @accountSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a one-time sign-in code. This is separate from your IPTV provider login.'**
  String get accountSignInSubtitle;

  /// No description provided for @accountNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Commercial auth is not configured in this build. Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.'**
  String get accountNotConfigured;

  /// No description provided for @accountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmailLabel;

  /// No description provided for @accountEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get accountEmailInvalid;

  /// No description provided for @accountSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get accountSendCode;

  /// No description provided for @accountOtpSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the sign-in code.'**
  String get accountOtpSendFailed;

  /// No description provided for @accountVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get accountVerifyTitle;

  /// No description provided for @accountVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}'**
  String accountVerifySubtitle(String email);

  /// No description provided for @accountCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get accountCodeLabel;

  /// No description provided for @accountCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the code from your email.'**
  String get accountCodeInvalid;

  /// No description provided for @accountVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify and continue'**
  String get accountVerifyAction;

  /// No description provided for @accountOtpVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code.'**
  String get accountOtpVerifyFailed;

  /// No description provided for @accountStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get accountStatusLabel;

  /// No description provided for @accountUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get accountUnknown;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out of HOPE TV'**
  String get accountSignOut;

  /// No description provided for @accountIptvSeparateHint.
  ///
  /// In en, this message translates to:
  /// **'Signing out of HOPE TV does not delete your saved IPTV provider credentials. Use Settings to disconnect the IPTV server.'**
  String get accountIptvSeparateHint;

  /// No description provided for @accountDevicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get accountDevicesTitle;

  /// No description provided for @accountDeviceLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Device limit: {limit}'**
  String accountDeviceLimitLabel(int limit);

  /// No description provided for @accountDeviceActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountDeviceActive;

  /// No description provided for @accountDeviceRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get accountDeviceRevoked;

  /// No description provided for @accountRevokeDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke device'**
  String get accountRevokeDeviceTitle;

  /// No description provided for @accountRevokeDeviceMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove access for \"{name}\"?'**
  String accountRevokeDeviceMessage(String name);

  /// No description provided for @accountRevokeDeviceAction.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get accountRevokeDeviceAction;

  /// No description provided for @accountDeleteSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteSectionTitle;

  /// No description provided for @accountDeleteSectionBody.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your HOPE TV account and commercial data after a grace period. IPTV credentials stored on this device are not removed automatically.'**
  String get accountDeleteSectionBody;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete HOPE TV account?'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This schedules deletion of your account, devices, and personal analytics. Active subscriptions should be canceled first. You can cancel the deletion request during the grace period.'**
  String get accountDeleteWarning;

  /// No description provided for @accountDeleteContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accountDeleteContinue;

  /// No description provided for @accountDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountDeleteCancel;

  /// No description provided for @accountDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get accountDeleteConfirmTitle;

  /// No description provided for @accountDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE_MY_ACCOUNT below to confirm. You will be signed out on all devices.'**
  String get accountDeleteConfirmBody;

  /// No description provided for @accountDeleteConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmation phrase'**
  String get accountDeleteConfirmLabel;

  /// No description provided for @accountDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get accountDeleteAction;

  /// No description provided for @accountDeleteScheduled.
  ///
  /// In en, this message translates to:
  /// **'Account deletion scheduled. You have been signed out.'**
  String get accountDeleteScheduled;

  /// No description provided for @accountDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not schedule account deletion.'**
  String get accountDeleteFailed;

  /// No description provided for @accountDeleteActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel your subscription or acknowledge subscription loss before deleting your account.'**
  String get accountDeleteActiveSubscription;

  /// No description provided for @accountDeletePendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion scheduled'**
  String get accountDeletePendingTitle;

  /// No description provided for @accountDeletePendingBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deleted after {date}. You can cancel this request until then.'**
  String accountDeletePendingBody(String date);

  /// No description provided for @accountDeleteCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion request'**
  String get accountDeleteCancelRequest;

  /// No description provided for @accountDeleteCanceled.
  ///
  /// In en, this message translates to:
  /// **'Account deletion canceled.'**
  String get accountDeleteCanceled;

  /// No description provided for @accountDeleteCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel the deletion request.'**
  String get accountDeleteCancelFailed;

  /// No description provided for @accountDeleteStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load deletion status.'**
  String get accountDeleteStatusFailed;

  /// No description provided for @settingsSignOutIptvHint.
  ///
  /// In en, this message translates to:
  /// **'Disconnect IPTV provider only'**
  String get settingsSignOutIptvHint;

  /// No description provided for @accessRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Access required'**
  String get accessRequiredTitle;

  /// No description provided for @accessRequiredHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your HOPE TV access is not active'**
  String get accessRequiredHeadline;

  /// No description provided for @accessRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your free trial may have ended, or your subscription needs attention. Refresh access after reconnecting, or subscribe on our website.'**
  String get accessRequiredBody;

  /// No description provided for @accessRequiredReason.
  ///
  /// In en, this message translates to:
  /// **'Status: {reason}'**
  String accessRequiredReason(String reason);

  /// No description provided for @accessRequiredRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh access'**
  String get accessRequiredRefresh;

  /// No description provided for @accessRequiredSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe on our website'**
  String get accessRequiredSubscribe;

  /// No description provided for @subscriptionPortalNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Subscription website is not configured yet.'**
  String get subscriptionPortalNotConfigured;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
