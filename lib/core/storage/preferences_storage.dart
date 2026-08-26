import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv/core/logging/app_logger.dart';

/// Non-sensitive app preferences (theme, language, player settings, etc.)
class PreferencesStorage {
  PreferencesStorage._(this._prefs);

  static PreferencesStorage? _instance;

  final SharedPreferences _prefs;

  static Future<PreferencesStorage> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final instance = PreferencesStorage._(prefs);
    _instance = instance;
    AppLogger.info('Preferences initialized', feature: 'storage');
    return instance;
  }

  static PreferencesStorage get instance {
    assert(_instance != null, 'PreferencesStorage.initialize() not called');
    return _instance!;
  }

  // ---------------------------------------------------------------------------
  // Keys
  // ---------------------------------------------------------------------------

  static const String _keyLocale = 'locale';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPlayerVolume = 'player_volume';
  static const String _keyLastRoute = 'last_route';
  static const String _keyAuthServerUrl = 'auth_server_url';
  static const String _keyAuthUsername = 'auth_username';
  static const String _keyAuthPasswordEnc = 'auth_password_enc';

  // ---------------------------------------------------------------------------
  // Auth Credentials Fallback
  // ---------------------------------------------------------------------------

  String? get authServerUrl => _prefs.getString(_keyAuthServerUrl);
  String? get authUsername => _prefs.getString(_keyAuthUsername);
  String? get authPasswordEnc => _prefs.getString(_keyAuthPasswordEnc);

  Future<void> saveAuthCredentials({
    required String serverUrl,
    required String username,
    required String passwordEnc,
  }) async {
    await Future.wait([
      _prefs.setString(_keyAuthServerUrl, serverUrl),
      _prefs.setString(_keyAuthUsername, username),
      _prefs.setString(_keyAuthPasswordEnc, passwordEnc),
    ]);
  }

  Future<void> clearAuthCredentials() async {
    await Future.wait([
      _prefs.remove(_keyAuthServerUrl),
      _prefs.remove(_keyAuthUsername),
      _prefs.remove(_keyAuthPasswordEnc),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Locale
  // ---------------------------------------------------------------------------

  String get locale => _prefs.getString(_keyLocale) ?? 'en';
  Future<void> setLocale(String code) => _prefs.setString(_keyLocale, code);

  // ---------------------------------------------------------------------------
  // Theme
  // ---------------------------------------------------------------------------

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark';
  Future<void> setThemeMode(String mode) => _prefs.setString(_keyThemeMode, mode);

  // ---------------------------------------------------------------------------
  // Player
  // ---------------------------------------------------------------------------

  double get playerVolume => _prefs.getDouble(_keyPlayerVolume) ?? 1.0;
  Future<void> setPlayerVolume(double volume) =>
      _prefs.setDouble(_keyPlayerVolume, volume);

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  String? get lastRoute => _prefs.getString(_keyLastRoute);
  Future<void> setLastRoute(String route) =>
      _prefs.setString(_keyLastRoute, route);

  // ---------------------------------------------------------------------------
  // Generic helpers
  // ---------------------------------------------------------------------------

  Future<void> clear() => _prefs.clear();
}
