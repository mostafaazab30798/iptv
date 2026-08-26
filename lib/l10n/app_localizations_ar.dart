// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'HOPE IPTV';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLive => 'البث المباشر';

  @override
  String get navMovies => 'أفلام';

  @override
  String get navSeries => 'مسلسلات';

  @override
  String get navGuide => 'دليل البرامج';

  @override
  String get navSearch => 'بحث';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get navHistory => 'سجل المشاهدة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get actionPlay => 'تشغيل';

  @override
  String get actionPause => 'إيقاف مؤقت';

  @override
  String get actionStop => 'إيقاف';

  @override
  String get actionResume => 'استئناف';

  @override
  String get actionWatch => 'مشاهدة';

  @override
  String get actionRetry => 'إعادة المحاولة';

  @override
  String get actionTryAgain => 'حاول مرة أخرى';

  @override
  String get actionSignIn => 'تسجيل الدخول';

  @override
  String get actionSignOut => 'تسجيل الخروج';

  @override
  String get actionSave => 'حفظ';

  @override
  String get actionCancel => 'إلغاء';

  @override
  String get actionContinue => 'متابعة';

  @override
  String get actionRefresh => 'تحديث';

  @override
  String get actionClear => 'مسح';

  @override
  String get actionClearAll => 'مسح الكل';

  @override
  String get actionDelete => 'حذف';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionBack => 'رجوع';

  @override
  String get actionSearch => 'بحث';

  @override
  String get actionDetails => 'التفاصيل';

  @override
  String get actionSeeAll => 'عرض الكل';

  @override
  String get actionSelect => 'تحديد';

  @override
  String get actionApply => 'تطبيق';

  @override
  String get actionDone => 'تم';

  @override
  String get actionReplay => 'إعادة التشغيل';

  @override
  String get labelServerUrl => 'رابط الخادم';

  @override
  String get labelUsername => 'اسم المستخدم';

  @override
  String get labelPassword => 'كلمة المرور';

  @override
  String get labelLoading => 'جارٍ التحميل...';

  @override
  String get labelNoResults => 'لا توجد نتائج';

  @override
  String get labelEmpty => 'لا يوجد شيء هنا بعد';

  @override
  String get labelLive => 'مباشر';

  @override
  String get labelFavorites => 'المفضلة';

  @override
  String get labelContinueWatching => 'متابعة المشاهدة';

  @override
  String get labelLiveNow => 'يُعرض الآن';

  @override
  String get labelRecentlyWatched => 'شاهدت مؤخراً';

  @override
  String get labelChannels => 'القنوات';

  @override
  String get labelMovies => 'الأفلام';

  @override
  String get labelSeries => 'المسلسلات';

  @override
  String get labelCategories => 'الفئات';

  @override
  String get labelAll => 'الكل';

  @override
  String get labelAllChannels => 'جميع القنوات';

  @override
  String get labelAllMovies => 'جميع الأفلام';

  @override
  String get labelAllSeries => 'جميع المسلسلات';

  @override
  String get labelEpisodes => 'الحلقات';

  @override
  String get labelSeasons => 'المواسم';

  @override
  String labelSeason(int number) {
    return 'الموسم $number';
  }

  @override
  String labelEpisode(int number) {
    return 'الحلقة $number';
  }

  @override
  String get labelNoDescription => 'لا يوجد وصف متاح.';

  @override
  String get labelRating => 'التقييم';

  @override
  String get labelYear => 'السنة';

  @override
  String get labelDuration => 'المدة';

  @override
  String get labelDirector => 'المخرج';

  @override
  String get labelCast => 'طاقم العمل';

  @override
  String get labelGenre => 'النوع';

  @override
  String get labelPlot => 'القصة';

  @override
  String get labelReleaseDate => 'تاريخ الإصدار';

  @override
  String get labelNowPlaying => 'يُعرض حالياً';

  @override
  String get labelUpcoming => 'القادم';

  @override
  String get labelNoEpg => 'لا تتوفر بيانات الدليل';

  @override
  String labelChannelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قناة',
      many: '$count قناة',
      few: '$count قنوات',
      two: 'قناتان',
      one: 'قناة واحدة',
      zero: 'لا توجد قنوات',
    );
    return '$_temp0';
  }

  @override
  String labelMovieCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فيلم',
      many: '$count فيلماً',
      few: '$count أفلام',
      two: 'فيلمان',
      one: 'فيلم واحد',
      zero: 'لا توجد أفلام',
    );
    return '$_temp0';
  }

  @override
  String labelSeriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مسلسل',
      many: '$count مسلسلاً',
      few: '$count مسلسلات',
      two: 'مسلسلان',
      one: 'مسلسل واحد',
      zero: 'لا توجد مسلسلات',
    );
    return '$_temp0';
  }

  @override
  String get homeFeaturedMovies => 'أفلام مميزة';

  @override
  String get homePopularSeries => 'مسلسلات شائعة';

  @override
  String get homeSportsChannels => 'قنوات رياضية';

  @override
  String get homeNewsChannels => 'أخبار وشؤون جارية';

  @override
  String get homeTvGuide => 'دليل القنوات';

  @override
  String get homeAllMovies => 'جميع الأفلام';

  @override
  String get homeEmptyPlaylist => 'لم يتم العثور على محتوى';

  @override
  String get homeEmptyPlaylistSubtitle =>
      'يرجى التحقق من قائمة التشغيل أو إعدادات الخادم.';

  @override
  String get homeCheckConnection =>
      'يرجى التحقق من إعدادات الخادم أو الاتصال بالإنترنت.';

  @override
  String get liveCategoriesHub => 'قنوات البث المباشر';

  @override
  String get liveSearchHint => 'ابحث في القنوات...';

  @override
  String get liveNoChannelsFound => 'لا توجد قنوات في هذه الفئة.';

  @override
  String get liveMiniPreview => 'معاينة البث المباشر';

  @override
  String liveNextProgram(String title) {
    return 'التالي: $title';
  }

  @override
  String get moviesCategoriesHub => 'فئات الأفلام';

  @override
  String get moviesSearchHint => 'ابحث في الأفلام...';

  @override
  String get moviesNoMoviesFound => 'لا توجد أفلام في هذه الفئة.';

  @override
  String get seriesCategoriesHub => 'فئات المسلسلات';

  @override
  String get seriesSearchHint => 'ابحث في المسلسلات...';

  @override
  String get seriesNoSeriesFound => 'لا توجد مسلسلات في هذه الفئة.';

  @override
  String get seriesSelectSeason => 'اختر الموسم';

  @override
  String get guideTitle => 'دليل البرامج الإلكتروني';

  @override
  String get guideNoData => 'لا تتوفر بيانات الدليل';

  @override
  String get guideNoDataSubtitle =>
      'تعذر تحميل القنوات أو بيانات دليل البرامج.';

  @override
  String get guideToday => 'اليوم';

  @override
  String get guideTomorrow => 'غداً';

  @override
  String get guideYesterday => 'أمس';

  @override
  String get searchHint => 'ابحث في القنوات والأفلام والمسلسلات...';

  @override
  String searchNoResults(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String get searchNoResultsSubtitle =>
      'تحقق من صحة الكلمات أو جرب كلمات مفتاحية أخرى.';

  @override
  String searchLiveTab(int count) {
    return 'القنوات المباشرة ($count)';
  }

  @override
  String searchMoviesTab(int count) {
    return 'الأفلام ($count)';
  }

  @override
  String searchSeriesTab(int count) {
    return 'المسلسلات ($count)';
  }

  @override
  String get searchRecentSearches => 'عمليات البحث الأخيرة';

  @override
  String get searchTypeToFind => 'ابحث في كل محتويات مكتبة IPTV الخاصة بك';

  @override
  String get favoritesTitle => 'مفضلاتي';

  @override
  String get favoritesEmptyTitle => 'لا توجد عناصر مفضلة بعد';

  @override
  String get favoritesEmptySubtitle =>
      'أضف القنوات والأفلام والمسلسلات إلى مفضلتك للوصول إليها بسرعة.';

  @override
  String get historyTitle => 'سجل المشاهدة';

  @override
  String get historyClearTooltip => 'مسح السجل';

  @override
  String get historyClearDialogTitle => 'مسح سجل المشاهدة';

  @override
  String get historyClearDialogContent =>
      'هل أنت متأكد من رغبتك في مسح سجل المشاهدة بالكامل؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get historyEmptyTitle => 'لا يوجد سجل مشاهدة';

  @override
  String get historyEmptySubtitle =>
      'ستظهر هنا القنوات والأفلام والمسلسلات التي تشاهدها.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsConnectedServer => 'الخادم المتصل';

  @override
  String get settingsUser => 'المستخدم';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsAccount => 'الحساب';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String get settingsVersion => 'الإصدار';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsArabic => 'العربية';

  @override
  String get settingsConfirmSignOut => 'تسجيل الخروج';

  @override
  String get settingsConfirmSignOutMessage =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من هذا الخادم؟';

  @override
  String get onboardingTitle => 'مرحباً بك في IPTV';

  @override
  String get onboardingSubtitle => 'أدخل تفاصيل الخادم للبدء.';

  @override
  String get onboardingServerGateway => 'بوابة الخادم';

  @override
  String get onboardingCustomServer => 'خادم Xtream مخصص';

  @override
  String get onboardingM3uNotice =>
      '✨ تم اكتشاف رابط M3U وتحويله إلى وضع Xtream السريع!';

  @override
  String get onboardingFillFields => 'يرجى ملء جميع الحقول المطلوبة.';

  @override
  String get authConnectServer => 'الاتصال بالخادم';

  @override
  String get authSignInSubtitle =>
      'سجل الدخول باستخدام بيانات مزود IPTV الخاص بك';

  @override
  String get authServerUrl => 'رابط الخادم (أو الصق رابط M3U)';

  @override
  String get authUsername => 'اسم المستخدم';

  @override
  String get authPassword => 'كلمة المرور';

  @override
  String get actionConnectStream => 'اتصال وبدء المشاهدة';

  @override
  String get onboardingBadge => 'محرك البث المتقدم V2';

  @override
  String get onboardingHeroTitle => 'تجربة تلفزيونية\nبلا حدود.';

  @override
  String get onboardingHeroSubtitle =>
      'اتصل بمزود Xtream أو حوّل روابط M3U للاستمتاع ببث سلس وفوري وبجودة عالية مع دليل البرامج التلفزيونية.';

  @override
  String get onboardingFeat1Title => 'تنقل فوري فائق السرعة';

  @override
  String get onboardingFeat1Subtitle =>
      'فك تشفير فوري للقنوات مع تسريع العتاد وبدون تأخير';

  @override
  String get onboardingFeat2Title => 'محول M3U الذكي إلى Xtream';

  @override
  String get onboardingFeat2Subtitle =>
      'تحويل روابط القوائم المباشرة لتقليل التخزين المؤقت وتحسين الاستجابة';

  @override
  String get onboardingFeat3Title => 'بوابات خوادم متعددة';

  @override
  String get onboardingFeat3Subtitle =>
      'تبديل سلس بين الخوادم الأساسية والاحتياطية والمخصصة';

  @override
  String get onboardingFeat4Title => 'دليل البرامج التلفزيونية EPG';

  @override
  String get onboardingFeat4Subtitle =>
      'مزامنة كاملة لجداول البث ومواعيد البرامج مع ميزة الإعادة';

  @override
  String get onboardingClientTitle => 'مشغل IPTV';

  @override
  String get onboardingClientSubtitle =>
      'سجل الدخول للوصول إلى القنوات المباشرة والأفلام والمسلسلات';

  @override
  String get onboardingHaveM3u => 'هل لديك رابط قائمة M3U؟';

  @override
  String get onboardingM3uConvertHint =>
      'تحويل إلى وضع Xtream فائق السرعة بنقرة واحدة';

  @override
  String get actionConvert => 'تحويل';

  @override
  String get onboardingActiveGateway => 'بوابة الخادم النشطة';

  @override
  String onboardingGatewaysAvailable(int count) {
    return '$count متاح';
  }

  @override
  String get onboardingManual => 'يدوي';

  @override
  String get onboardingOnline => 'متصل';

  @override
  String get onboardingCustomConfig => 'إعداد رابط الخادم المخصص';

  @override
  String get actionChange => 'تغيير';

  @override
  String get onboardingAutoConfig => 'إعداد تلقائي';

  @override
  String get onboardingEnterCustomUrl => 'أدخل رابط الخادم المخصص يدوياً';

  @override
  String get onboardingUrlHint => 'http://example.com:8080 أو رابط get.php';

  @override
  String get validationUsernameRequired => 'اسم المستخدم مطلوب';

  @override
  String get validationPasswordRequired => 'كلمة المرور مطلوبة';

  @override
  String get validationUrlRequired => 'رابط الخادم مطلوب';

  @override
  String get validationUrlInvalid =>
      'يجب أن يبدأ الرابط بـ http:// أو https://';

  @override
  String get gatewayDialogTitle => 'اختيار بوابة الخادم';

  @override
  String gatewayDialogSubtitle(int count) {
    return 'اختر من بين $count خوادم مهيأة أو أدخل خادماً مخصصاً';
  }

  @override
  String get gatewaySearchHint => 'البحث عن خادم بالاسم أو العنوان...';

  @override
  String gatewayFilterAll(int count) {
    return 'جميع البوابات ($count)';
  }

  @override
  String gatewayFilterOfficial(int count) {
    return 'الرسمية ($count)';
  }

  @override
  String get gatewayFilterCustom => 'خادم مخصص';

  @override
  String get gatewayNoMatches => 'لا توجد خوادم مطابقة لبحثك';

  @override
  String get m3uConverterTitle => 'محول M3U إلى Xtream';

  @override
  String get m3uConverterSubtitle =>
      'استخراج بيانات Xtream لتشغيل أسرع وبدون تقطيع';

  @override
  String get m3uPasteLabel => 'الصق رابط M3U أو رابط البث';

  @override
  String get actionPaste => 'لصق';

  @override
  String get m3uExtractError => 'تعذر استخراج بيانات Xtream من هذا الرابط.';

  @override
  String get m3uExtractedSuccess => 'تم استخراج بيانات Xtream بنجاح';

  @override
  String get m3uAdvantageHint =>
      'يوفر وضع Xtream تصنيفاً منظماً للمحتوى ودليلاً للبرامج وسرعة تشغيل فائقة.';

  @override
  String get actionConvertAndConnect => 'تحويل والاتصال فوراً';

  @override
  String get playerConnecting => 'جارٍ الاتصال...';

  @override
  String get playerReconnecting => 'إعادة الاتصال...';

  @override
  String get playerBuffering => 'جارٍ التخزين المؤقت...';

  @override
  String get playerStreamUnavailable => 'البث غير متاح';

  @override
  String get playerAudioTracks => 'المسارات الصوتية';

  @override
  String get playerSubtitles => 'الترجمة';

  @override
  String get playerAspectRatio => 'نسبة العرض';

  @override
  String get playerQuality => 'الجودة';

  @override
  String get playerTapToRetry => 'انقر لإعادة المحاولة';

  @override
  String get playerPreviousChannel => 'القناة السابقة';

  @override
  String get playerNextChannel => 'القناة التالية';

  @override
  String get playerReplay10 => 'إرجاع 10 ثوانٍ';

  @override
  String get playerForward10 => 'تقديم 10 ثوانٍ';

  @override
  String historyResumeAt(String time) {
    return 'استئناف عند $time';
  }

  @override
  String get historyResumePlayback => 'استئناف التشغيل';

  @override
  String get historyCompleted => 'مكتمل';

  @override
  String historyTimeLeftHoursMinutes(int hours, int minutes) {
    return 'متبقي $hours س $minutes د';
  }

  @override
  String historyTimeLeftMinutes(int minutes) {
    return 'متبقي $minutes دقيقة';
  }

  @override
  String historyWatchedOn(String date) {
    return 'تمت المشاهدة في $date';
  }

  @override
  String historyProgressSubtitle(int pos, int dur, String date) {
    return '$pos/$dur دقيقة • تمت المشاهدة في $date';
  }

  @override
  String get historyTypeLive => 'مباشر';

  @override
  String get historyTypeMovie => 'فيلم';

  @override
  String get historyTypeSeries => 'مسلسل';

  @override
  String get errorNetwork => 'خطأ في الشبكة. تحقق من اتصالك.';

  @override
  String get errorServer => 'خطأ في الخادم. يُرجى المحاولة مرة أخرى.';

  @override
  String get errorAuth => 'بيانات اعتماد غير صحيحة. تحقق من بياناتك.';

  @override
  String get errorPlayback => 'البث غير متاح';

  @override
  String get errorUnknown => 'حدث خطأ ما.';
}
