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

  @override
  String get accountTitle => 'حساب HOPE TV';

  @override
  String get accountSignInTitle => 'تسجيل الدخول';

  @override
  String get accountSignInSubtitle =>
      'أدخل بريدك الإلكتروني وسنرسل رمزاً لمرة واحدة. لا حاجة لكلمة مرور.';

  @override
  String get accountSignInStep => '01 · البريد';

  @override
  String get accountVerifyStep => '02 · التحقق';

  @override
  String get accountBrandTagline =>
      'خطوة أمان واحدة تفتح لك كل القنوات والأفلام والمباريات المباشرة.';

  @override
  String get accountPrivacyReassurance =>
      'نستخدم بريدك الإلكتروني فقط للتحقق من هويتك — لا نشاركه أو نبيعه أبداً.';

  @override
  String get accountEmailHelperText =>
      'لا حاجة لكلمة مرور — سنرسل لك رمزاً آمناً عبر البريد الإلكتروني.';

  @override
  String get accountSendingCode => 'جارٍ إرسال الرمز…';

  @override
  String get accountSlowNetworkHint => 'يستغرق هذا وقتاً أطول من المعتاد…';

  @override
  String get accountDebugOtpPreview =>
      'معاينة التصحيح — لن يتم إرسال بريد. أدخل أي بريد صالح واستخدم أي 6 أرقام.';

  @override
  String get accountNotConfigured =>
      'لم يتم إعداد مصادقة الحساب في هذا البناء. عيّن SUPABASE_URL و SUPABASE_ANON_KEY.';

  @override
  String get accountEmailLabel => 'البريد الإلكتروني';

  @override
  String get accountEmailInvalid => 'أدخل بريداً إلكترونياً صالحاً.';

  @override
  String get accountSendCode => 'متابعة';

  @override
  String get accountOtpSendFailed => 'تعذر إرسال رمز تسجيل الدخول.';

  @override
  String get accountVerifyTitle => 'أدخل رمزك';

  @override
  String accountVerifySubtitle(String email) {
    return 'أرسلنا رمزاً إلى $email';
  }

  @override
  String get accountCodeLabel => 'رمز التحقق';

  @override
  String get accountCodeFieldHint =>
      'أدخل الرمز المكوّن من 6 أرقام المرسل إلى بريدك الإلكتروني';

  @override
  String get accountCodeInvalid => 'أدخل الرمز المكوّن من 6 أرقام من بريدك.';

  @override
  String get accountVerifyAction => 'تحقق ومتابعة';

  @override
  String get accountVerifyingCode => 'جارٍ التحقق…';

  @override
  String get accountOtpVerifiedConfirmation => 'تم التحقق';

  @override
  String get accountEditEmail => 'تعديل البريد الإلكتروني';

  @override
  String get accountOtpNewestCodeHint => 'يعمل فقط آخر رمز تم إرساله إليك.';

  @override
  String get accountResendHint =>
      'تحقق من مجلد الرسائل غير المرغوب فيها إذا لم يصلك الرمز.';

  @override
  String get accountOtpVerifyFailed => 'رمز غير صالح أو منتهٍ.';

  @override
  String get accountResendCode => 'إعادة إرسال الرمز';

  @override
  String accountResendCooldown(int seconds) {
    return 'إعادة الإرسال خلال $seconds ث';
  }

  @override
  String get accountOtpResent => 'تم إرسال رمز جديد إلى بريدك.';

  @override
  String get accountOtpRateLimited =>
      'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.';

  @override
  String get accountOtpSessionExpired =>
      'انتهت جلسة تسجيل الدخول. اطلب رمزاً جديداً.';

  @override
  String get accountDeviceLimitReached =>
      'تم بلوغ حد الأجهزة. ألغِ جهازاً قديماً من الحساب > الأجهزة.';

  @override
  String get accountStatusLabel => 'الحالة';

  @override
  String get accountUnknown => 'غير معروف';

  @override
  String get accountSignOut => 'تسجيل الخروج من HOPE TV';

  @override
  String get accountIptvSeparateHint =>
      'تسجيل الخروج من HOPE TV لا يحذف بيانات مزود IPTV المحفوظة. استخدم الإعدادات لقطع اتصال خادم IPTV.';

  @override
  String get accountDevicesTitle => 'الأجهزة';

  @override
  String accountDeviceLimitLabel(int limit) {
    return 'حد الأجهزة: $limit';
  }

  @override
  String get accountDeviceActive => 'نشط';

  @override
  String get accountDeviceRevoked => 'ملغى';

  @override
  String get accountRevokeDeviceTitle => 'إلغاء الجهاز';

  @override
  String accountRevokeDeviceMessage(String name) {
    return 'إزالة الوصول لـ \"$name\"؟';
  }

  @override
  String get accountRevokeDeviceAction => 'إلغاء';

  @override
  String get accountDeleteSectionTitle => 'حذف الحساب';

  @override
  String get accountDeleteSectionBody =>
      'حذف حساب HOPE TV والبيانات التجارية نهائياً بعد فترة سماح. بيانات مزود IPTV المحفوظة على هذا الجهاز لا تُحذف تلقائياً.';

  @override
  String get accountDeleteTitle => 'حذف حساب HOPE TV؟';

  @override
  String get accountDeleteWarning =>
      'سيتم جدولة حذف حسابك وأجهزتك والتحليلات الشخصية. يُفضّل إلغاء الاشتراك النشط أولاً. يمكنك إلغاء طلب الحذف خلال فترة السماح.';

  @override
  String get accountDeleteContinue => 'متابعة';

  @override
  String get accountDeleteCancel => 'إلغاء';

  @override
  String get accountDeleteConfirmTitle => 'تأكيد الحذف';

  @override
  String get accountDeleteConfirmBody =>
      'اكتب DELETE_MY_ACCOUNT أدناه للتأكيد. سيتم تسجيل خروجك من جميع الأجهزة.';

  @override
  String get accountDeleteConfirmLabel => 'عبارة التأكيد';

  @override
  String get accountDeleteAction => 'حذف حسابي';

  @override
  String get accountDeleteScheduled => 'تم جدولة حذف الحساب. تم تسجيل خروجك.';

  @override
  String get accountDeleteFailed => 'تعذر جدولة حذف الحساب.';

  @override
  String get accountDeleteActiveSubscription =>
      'ألغِ اشتراكك أو أكّد فقدان الاشتراك قبل حذف الحساب.';

  @override
  String get accountDeletePendingTitle => 'الحذف مجدول';

  @override
  String accountDeletePendingBody(String date) {
    return 'سيُحذف حسابك بعد $date. يمكنك إلغاء الطلب حتى ذلك الحين.';
  }

  @override
  String get accountDeleteCancelRequest => 'إلغاء طلب الحذف';

  @override
  String get accountDeleteCanceled => 'تم إلغاء حذف الحساب.';

  @override
  String get accountDeleteCancelFailed => 'تعذر إلغاء طلب الحذف.';

  @override
  String get accountDeleteStatusFailed => 'تعذر تحميل حالة الحذف.';

  @override
  String get settingsSignOutIptvHint => 'قطع اتصال مزود IPTV فقط';

  @override
  String get accessRequiredTitle => 'الوصول مطلوب';

  @override
  String get accessRequiredHeadline => 'وصول HOPE TV غير نشط';

  @override
  String get accessRequiredBody =>
      'قد تكون الفترة التجريبية قد انتهت، أو يحتاج اشتراكك إلى متابعة. حدّث الوصول بعد الاتصال، أو اشترك عبر موقعنا.';

  @override
  String accessRequiredReason(String reason) {
    return 'الحالة: $reason';
  }

  @override
  String get accessRequiredRefresh => 'تحديث الوصول';

  @override
  String get accessRequiredSubscribe => 'اشترك عبر موقعنا';

  @override
  String get accessRequiredChangeServer => 'استخدام خادم IPTV آخر';

  @override
  String get subscriptionPortalNotConfigured => 'موقع الاشتراك غير مُعد بعد.';

  @override
  String get updateAvailableTitle => 'تحديث متاح';

  @override
  String updateAvailableBody(String version, String size) {
    return 'HOPE TV $version متاح ($size).';
  }

  @override
  String get updateRequiredTitle => 'التحديث مطلوب';

  @override
  String updateRequiredBody(String version) {
    return 'ثبّت HOPE TV $version للمتابعة.';
  }

  @override
  String get updateLater => 'لاحقاً';

  @override
  String get updateDownload => 'تنزيل التحديث';

  @override
  String get updateExitApp => 'إغلاق التطبيق';

  @override
  String get updateSignInRequired => 'سجّل الدخول لتنزيل هذا التحديث.';

  @override
  String get updateLaunchFailed => 'تعذّر فتح رابط التنزيل.';

  @override
  String get updateStatusAvailable => 'تحديث متاح';

  @override
  String get updateStatusUpToDate => 'محدّث';

  @override
  String get updateStatusUnsupported => 'التحديثات غير مدعومة على هذه المنصة';

  @override
  String get updateStatusNotConfigured => 'خدمة التحديث غير مُعدّة';

  @override
  String get updateStatusChecking => 'جاري البحث عن تحديثات…';

  @override
  String get updateStatusError => 'تعذّر التحقق من التحديثات';
}
