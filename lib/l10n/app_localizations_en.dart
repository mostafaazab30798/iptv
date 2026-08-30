// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HOPE IPTV';

  @override
  String get navHome => 'Home';

  @override
  String get navLive => 'Live TV';

  @override
  String get navMovies => 'Movies';

  @override
  String get navSeries => 'Series';

  @override
  String get navGuide => 'Guide';

  @override
  String get navSearch => 'Search';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionWatch => 'Watch';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionTryAgain => 'Try Again';

  @override
  String get actionSignIn => 'Sign In';

  @override
  String get actionSignOut => 'Sign Out';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClearAll => 'Clear All';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionClose => 'Close';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionDetails => 'Details';

  @override
  String get actionSeeAll => 'See All';

  @override
  String get actionSelect => 'Select';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionDone => 'Done';

  @override
  String get actionReplay => 'Replay';

  @override
  String get labelServerUrl => 'Server URL';

  @override
  String get labelUsername => 'Username';

  @override
  String get labelPassword => 'Password';

  @override
  String get labelLoading => 'Loading...';

  @override
  String get labelNoResults => 'No results';

  @override
  String get labelEmpty => 'Nothing here yet';

  @override
  String get labelLive => 'LIVE';

  @override
  String get labelFavorites => 'Favorites';

  @override
  String get labelContinueWatching => 'Continue Watching';

  @override
  String get labelLiveNow => 'Live Now';

  @override
  String get labelRecentlyWatched => 'Recently Watched';

  @override
  String get labelChannels => 'Channels';

  @override
  String get labelMovies => 'Movies';

  @override
  String get labelSeries => 'Series';

  @override
  String get labelCategories => 'Categories';

  @override
  String get labelAll => 'All';

  @override
  String get labelAllChannels => 'All Channels';

  @override
  String get labelAllMovies => 'All Movies';

  @override
  String get labelAllSeries => 'All Series';

  @override
  String get labelEpisodes => 'Episodes';

  @override
  String get labelSeasons => 'Seasons';

  @override
  String labelSeason(int number) {
    return 'Season $number';
  }

  @override
  String labelEpisode(int number) {
    return 'Episode $number';
  }

  @override
  String get labelNoDescription => 'No description available.';

  @override
  String get labelRating => 'Rating';

  @override
  String get labelYear => 'Year';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelDirector => 'Director';

  @override
  String get labelCast => 'Cast';

  @override
  String get labelGenre => 'Genre';

  @override
  String get labelPlot => 'Plot';

  @override
  String get labelReleaseDate => 'Release Date';

  @override
  String get labelNowPlaying => 'Now Playing';

  @override
  String get labelUpcoming => 'Upcoming';

  @override
  String get labelNoEpg => 'No EPG Available';

  @override
  String labelChannelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Channels',
      one: '1 Channel',
      zero: 'No channels',
    );
    return '$_temp0';
  }

  @override
  String labelMovieCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Movies',
      one: '1 Movie',
      zero: 'No movies',
    );
    return '$_temp0';
  }

  @override
  String labelSeriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Series',
      one: '1 Series',
      zero: 'No series',
    );
    return '$_temp0';
  }

  @override
  String get homeFeaturedMovies => 'Featured Movies';

  @override
  String get homePopularSeries => 'Popular Series';

  @override
  String get homeSportsChannels => 'Sports Channels';

  @override
  String get homeNewsChannels => 'News & Current Affairs';

  @override
  String get homeTvGuide => 'TV Guide';

  @override
  String get homeAllMovies => 'All Movies';

  @override
  String get homeEmptyPlaylist => 'No media content found';

  @override
  String get homeEmptyPlaylistSubtitle =>
      'Please check your playlist or server configuration.';

  @override
  String get homeCheckConnection =>
      'Please check your server settings or network connection.';

  @override
  String get liveCategoriesHub => 'Live Channels';

  @override
  String get liveSearchHint => 'Search in channels...';

  @override
  String get liveNoChannelsFound => 'No channels found in this category.';

  @override
  String get liveMiniPreview => 'Live Preview';

  @override
  String liveNextProgram(String title) {
    return 'Next: $title';
  }

  @override
  String get moviesCategoriesHub => 'Movie Categories';

  @override
  String get moviesSearchHint => 'Search movies...';

  @override
  String get moviesNoMoviesFound => 'No movies found in this category.';

  @override
  String get seriesCategoriesHub => 'Series Categories';

  @override
  String get seriesSearchHint => 'Search series...';

  @override
  String get seriesNoSeriesFound => 'No series found in this category.';

  @override
  String get seriesSelectSeason => 'Select Season';

  @override
  String get guideTitle => 'Electronic Program Guide';

  @override
  String get guideNoData => 'No Guide Data Available';

  @override
  String get guideNoDataSubtitle => 'Channels or EPG data could not be loaded.';

  @override
  String get guideToday => 'Today';

  @override
  String get guideTomorrow => 'Tomorrow';

  @override
  String get guideYesterday => 'Yesterday';

  @override
  String get searchHint => 'Search channels, movies, series...';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchNoResultsSubtitle =>
      'Try checking the spelling or use different keywords.';

  @override
  String searchLiveTab(int count) {
    return 'Live Channels ($count)';
  }

  @override
  String searchMoviesTab(int count) {
    return 'Movies ($count)';
  }

  @override
  String searchSeriesTab(int count) {
    return 'Series ($count)';
  }

  @override
  String get searchRecentSearches => 'Recent Searches';

  @override
  String get searchTypeToFind => 'Search anything across your IPTV library';

  @override
  String get favoritesTitle => 'My Favorites';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Add channels, movies, or series to your favorites to access them quickly.';

  @override
  String get historyTitle => 'Watch History';

  @override
  String get historyClearTooltip => 'Clear History';

  @override
  String get historyClearDialogTitle => 'Clear Watch History';

  @override
  String get historyClearDialogContent =>
      'Are you sure you want to clear your entire watch history? This cannot be undone.';

  @override
  String get historyEmptyTitle => 'No watch history';

  @override
  String get historyEmptySubtitle =>
      'Streams, movies, and series you watch will appear here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsConnectedServer => 'Connected Server';

  @override
  String get settingsUser => 'User';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsArabic => 'العربية';

  @override
  String get settingsConfirmSignOut => 'Sign Out';

  @override
  String get settingsConfirmSignOutMessage =>
      'Are you sure you want to sign out from this server?';

  @override
  String get onboardingTitle => 'Welcome to IPTV';

  @override
  String get onboardingSubtitle => 'Enter your server details to get started.';

  @override
  String get onboardingServerGateway => 'Server Gateway';

  @override
  String get onboardingCustomServer => 'Custom Xtream Server';

  @override
  String get onboardingM3uNotice =>
      '✨ M3U link detected & converted to Xtream Fast Stream mode!';

  @override
  String get onboardingFillFields => 'Please fill in all fields.';

  @override
  String get authConnectServer => 'Connect Server';

  @override
  String get authSignInSubtitle =>
      'Sign in with your IPTV provider credentials';

  @override
  String get authServerUrl => 'Server URL (or Paste M3U Link)';

  @override
  String get authUsername => 'Username';

  @override
  String get authPassword => 'Password';

  @override
  String get actionConnectStream => 'Connect & Stream';

  @override
  String get onboardingBadge => 'STREAMING ENGINE V2';

  @override
  String get onboardingHeroTitle => 'Experience TV\nWithout Limits.';

  @override
  String get onboardingHeroSubtitle =>
      'Connect to your Xtream cluster or convert any M3U link to enjoy zero-buffer streaming, 4K HDR playback, and live electronic program guides.';

  @override
  String get onboardingFeat1Title => 'Zero-Buffer Fast Zapping';

  @override
  String get onboardingFeat1Subtitle =>
      'Instant stream decoding with hardware acceleration';

  @override
  String get onboardingFeat2Title => 'Smart M3U → Xtream Engine';

  @override
  String get onboardingFeat2Subtitle =>
      'Converts raw playlist links to direct APIs for instant buffering';

  @override
  String get onboardingFeat3Title => 'Modular Gateway Clusters';

  @override
  String get onboardingFeat3Subtitle =>
      'Seamlessly switch between primary, backup, and custom servers';

  @override
  String get onboardingFeat4Title => 'Live EPG & Catch-Up Guide';

  @override
  String get onboardingFeat4Subtitle =>
      'Complete schedule synchronization and timeline recall';

  @override
  String get onboardingClientTitle => 'IPTV CLIENT';

  @override
  String get onboardingClientSubtitle =>
      'Sign in to access your live channels & VOD';

  @override
  String get onboardingHaveM3u => 'Have an M3U Playlist Link?';

  @override
  String get onboardingM3uConvertHint =>
      'Convert to zero-buffer Xtream engine in 1-tap';

  @override
  String get actionConvert => 'Convert';

  @override
  String get onboardingActiveGateway => 'ACTIVE SERVER GATEWAY';

  @override
  String onboardingGatewaysAvailable(int count) {
    return '$count Available';
  }

  @override
  String get onboardingManual => 'MANUAL';

  @override
  String get onboardingOnline => 'ONLINE';

  @override
  String get onboardingCustomConfig => 'Custom server URL configuration';

  @override
  String get actionChange => 'Change';

  @override
  String get onboardingAutoConfig => 'AUTO-CONFIG';

  @override
  String get onboardingEnterCustomUrl => 'Enter custom URL manually';

  @override
  String get onboardingUrlHint => 'http://example.com:8080 or get.php M3U link';

  @override
  String get validationUsernameRequired => 'Username is required';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationUrlRequired => 'Server URL is required';

  @override
  String get validationUrlInvalid => 'URL must start with http:// or https://';

  @override
  String get gatewayDialogTitle => 'Select Server Gateway';

  @override
  String gatewayDialogSubtitle(int count) {
    return 'Choose from $count configured clusters or custom endpoint';
  }

  @override
  String get gatewaySearchHint => 'Search server by name, location, or URL...';

  @override
  String gatewayFilterAll(int count) {
    return 'All Gateways ($count)';
  }

  @override
  String gatewayFilterOfficial(int count) {
    return 'Official ($count)';
  }

  @override
  String get gatewayFilterCustom => 'Custom Endpoint';

  @override
  String get gatewayNoMatches => 'No server gateways match your search';

  @override
  String get m3uConverterTitle => 'M3U to Xtream Converter';

  @override
  String get m3uConverterSubtitle =>
      'Extracts Xtream credentials for zero buffering';

  @override
  String get m3uPasteLabel => 'PASTE M3U URL OR STREAM LINK';

  @override
  String get actionPaste => 'Paste';

  @override
  String get m3uExtractError =>
      'Could not extract Xtream credentials from this M3U link.';

  @override
  String get m3uExtractedSuccess => 'Xtream Credentials Extracted';

  @override
  String get m3uAdvantageHint =>
      'Xtream format unlocks category filtering, live EPG, VOD metadata, and zero-buffering hardware streaming.';

  @override
  String get actionConvertAndConnect => 'Convert & Connect';

  @override
  String get playerConnecting => 'Connecting...';

  @override
  String get playerReconnecting => 'Reconnecting...';

  @override
  String get playerBuffering => 'Buffering...';

  @override
  String get playerStreamUnavailable => 'Stream unavailable';

  @override
  String get playerAudioTracks => 'Audio Tracks';

  @override
  String get playerSubtitles => 'Subtitles';

  @override
  String get playerAspectRatio => 'Aspect Ratio';

  @override
  String get playerQuality => 'Quality';

  @override
  String get playerTapToRetry => 'Tap to retry';

  @override
  String get playerPreviousChannel => 'Previous Channel';

  @override
  String get playerNextChannel => 'Next Channel';

  @override
  String get playerReplay10 => 'Replay 10s';

  @override
  String get playerForward10 => 'Forward 10s';

  @override
  String historyResumeAt(String time) {
    return 'Resume at $time';
  }

  @override
  String get historyResumePlayback => 'Resume playback';

  @override
  String get historyCompleted => 'Completed';

  @override
  String historyTimeLeftHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes m left';
  }

  @override
  String historyTimeLeftMinutes(int minutes) {
    return '$minutes min left';
  }

  @override
  String historyWatchedOn(String date) {
    return 'Watched on $date';
  }

  @override
  String historyProgressSubtitle(int pos, int dur, String date) {
    return '$pos/$dur min • Watched on $date';
  }

  @override
  String get historyTypeLive => 'LIVE';

  @override
  String get historyTypeMovie => 'MOVIE';

  @override
  String get historyTypeSeries => 'SERIES';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorServer => 'Server error. Please try again.';

  @override
  String get errorAuth => 'Invalid credentials. Please check your details.';

  @override
  String get errorPlayback => 'Stream unavailable';

  @override
  String get errorUnknown => 'Something went wrong.';

  @override
  String get accountTitle => 'HOPE TV Account';

  @override
  String get accountSignInTitle => 'Sign in';

  @override
  String get accountSignInSubtitle =>
      'Enter your email and we\'ll send a one-time code. No password needed.';

  @override
  String get accountSignInStep => '01 · EMAIL';

  @override
  String get accountVerifyStep => '02 · VERIFY';

  @override
  String get accountBrandTagline =>
      'One secure step to every channel, movie, and live match.';

  @override
  String get accountPrivacyReassurance =>
      'We only use your email to verify it\'s you — never shared, never sold.';

  @override
  String get accountEmailHelperText =>
      'No password needed — we\'ll email you a secure code.';

  @override
  String get accountSendingCode => 'Sending code…';

  @override
  String get accountSlowNetworkHint =>
      'This is taking a little longer than usual…';

  @override
  String get accountDebugOtpPreview =>
      'Debug preview — no email is sent. Enter any valid email and use any 6 digits.';

  @override
  String get accountNotConfigured =>
      'Commercial auth is not configured in this build. Set SUPABASE_URL and SUPABASE_ANON_KEY dart-defines.';

  @override
  String get accountEmailLabel => 'Email';

  @override
  String get accountEmailInvalid => 'Enter a valid email address.';

  @override
  String get accountSendCode => 'Continue';

  @override
  String get accountOtpSendFailed => 'Could not send the sign-in code.';

  @override
  String get accountVerifyTitle => 'Enter your code';

  @override
  String accountVerifySubtitle(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get accountCodeLabel => 'Verification code';

  @override
  String get accountCodeFieldHint =>
      'Enter the 6-digit code sent to your email';

  @override
  String get accountCodeInvalid => 'Enter the 6-digit code from your email.';

  @override
  String get accountVerifyAction => 'Verify and continue';

  @override
  String get accountVerifyingCode => 'Verifying…';

  @override
  String get accountOtpVerifiedConfirmation => 'Verified';

  @override
  String get accountEditEmail => 'Edit email';

  @override
  String get accountOtpNewestCodeHint =>
      'Only your most recently requested code will work.';

  @override
  String get accountResendHint =>
      'Check your spam folder if it hasn\'t arrived.';

  @override
  String get accountOtpVerifyFailed => 'Invalid or expired code.';

  @override
  String get accountResendCode => 'Resend code';

  @override
  String accountResendCooldown(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get accountOtpResent => 'A new code was sent to your email.';

  @override
  String get accountOtpRateLimited =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get accountOtpSessionExpired =>
      'Sign-in session expired. Request a new code.';

  @override
  String get accountDeviceLimitReached =>
      'Device limit reached. Revoke an old device from Account > Devices.';

  @override
  String get accountStatusLabel => 'Status';

  @override
  String get accountUnknown => 'Unknown';

  @override
  String get accountSignOut => 'Sign out of HOPE TV';

  @override
  String get accountIptvSeparateHint =>
      'Signing out of HOPE TV does not delete your saved IPTV provider credentials. Use Settings to disconnect the IPTV server.';

  @override
  String get accountDevicesTitle => 'Devices';

  @override
  String accountDeviceLimitLabel(int limit) {
    return 'Device limit: $limit';
  }

  @override
  String get accountDeviceActive => 'Active';

  @override
  String get accountDeviceRevoked => 'Revoked';

  @override
  String get accountRevokeDeviceTitle => 'Revoke device';

  @override
  String accountRevokeDeviceMessage(String name) {
    return 'Remove access for \"$name\"?';
  }

  @override
  String get accountRevokeDeviceAction => 'Revoke';

  @override
  String get accountDeleteSectionTitle => 'Delete account';

  @override
  String get accountDeleteSectionBody =>
      'Permanently delete your HOPE TV account and commercial data after a grace period. IPTV credentials stored on this device are not removed automatically.';

  @override
  String get accountDeleteTitle => 'Delete HOPE TV account?';

  @override
  String get accountDeleteWarning =>
      'This schedules deletion of your account, devices, and personal analytics. Active subscriptions should be canceled first. You can cancel the deletion request during the grace period.';

  @override
  String get accountDeleteContinue => 'Continue';

  @override
  String get accountDeleteCancel => 'Cancel';

  @override
  String get accountDeleteConfirmTitle => 'Confirm deletion';

  @override
  String get accountDeleteConfirmBody =>
      'Type DELETE_MY_ACCOUNT below to confirm. You will be signed out on all devices.';

  @override
  String get accountDeleteConfirmLabel => 'Confirmation phrase';

  @override
  String get accountDeleteAction => 'Delete my account';

  @override
  String get accountDeleteScheduled =>
      'Account deletion scheduled. You have been signed out.';

  @override
  String get accountDeleteFailed => 'Could not schedule account deletion.';

  @override
  String get accountDeleteActiveSubscription =>
      'Cancel your subscription or acknowledge subscription loss before deleting your account.';

  @override
  String get accountDeletePendingTitle => 'Deletion scheduled';

  @override
  String accountDeletePendingBody(String date) {
    return 'Your account will be deleted after $date. You can cancel this request until then.';
  }

  @override
  String get accountDeleteCancelRequest => 'Cancel deletion request';

  @override
  String get accountDeleteCanceled => 'Account deletion canceled.';

  @override
  String get accountDeleteCancelFailed =>
      'Could not cancel the deletion request.';

  @override
  String get accountDeleteStatusFailed => 'Could not load deletion status.';

  @override
  String get settingsSignOutIptvHint => 'Disconnect IPTV provider only';

  @override
  String get accessRequiredTitle => 'Access required';

  @override
  String get accessRequiredHeadline => 'Your HOPE TV access is not active';

  @override
  String get accessRequiredBody =>
      'Your free trial may have ended, or your subscription needs attention. Refresh access after reconnecting, or subscribe on our website.';

  @override
  String accessRequiredReason(String reason) {
    return 'Status: $reason';
  }

  @override
  String get accessRequiredRefresh => 'Refresh access';

  @override
  String get accessRequiredSubscribe => 'Subscribe on our website';

  @override
  String get subscriptionPortalNotConfigured =>
      'Subscription website is not configured yet.';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableBody(String version, String size) {
    return 'HOPE TV $version is available ($size).';
  }

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String updateRequiredBody(String version) {
    return 'Install HOPE TV $version to continue.';
  }

  @override
  String get updateLater => 'Later';

  @override
  String get updateDownload => 'Download update';

  @override
  String get updateExitApp => 'Exit app';

  @override
  String get updateSignInRequired => 'Sign in to download this update.';

  @override
  String get updateLaunchFailed => 'Could not open the download link.';

  @override
  String get updateStatusAvailable => 'Update available';

  @override
  String get updateStatusUpToDate => 'Up to date';

  @override
  String get updateStatusUnsupported =>
      'Updates not supported on this platform';

  @override
  String get updateStatusNotConfigured => 'Update service not configured';

  @override
  String get updateStatusChecking => 'Checking for updates…';

  @override
  String get updateStatusError => 'Could not check for updates';
}
