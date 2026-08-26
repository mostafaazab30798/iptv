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
