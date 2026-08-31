/// Application-wide constants.
abstract final class AppConstants {
  // App identity
  static const String appName = 'HOPE IPTV';
  static const String appVersion = '0.1.4';
  /// Integer build number compared against server release metadata.
  static const int appBuildNumber = 9;
  static const String appLogo = 'assets/icons/app_logo.png';


  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const Duration networkRetryDelay = Duration(seconds: 3);
  static const int maxRetryCount = 2;

  // Cache TTL
  static const Duration channelCacheTtl = Duration(hours: 6);
  static const Duration epgCacheTtl = Duration(hours: 1);
  static const Duration vodCacheTtl = Duration(hours: 24);
  static const Duration categoryCacheTtl = Duration(hours: 6);
  static const Duration imageCacheTtl = Duration(days: 7);

  // Player
  static const Duration playerBufferDuration = Duration(seconds: 10);
  static const int playerMaxReconnectAttempts = 3;
  static const Duration playerReconnectDelay = Duration(seconds: 2);

  // UI
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration splashMinDuration = Duration(milliseconds: 300);

  // Pagination
  static const int defaultPageSize = 50;
  static const int searchPageSize = 30;

  // Local DB
  static const String dbName = 'iptv.db';
  static const int dbVersion = 1;
}
