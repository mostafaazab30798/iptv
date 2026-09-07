import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv/core/logging/app_logger.dart';

/// Non-sensitive app preferences (theme, language, player settings, etc.)
class PreferencesStorage {
  PreferencesStorage._(this._prefs);

  static PreferencesStorage? _instance;

  final SharedPreferences _prefs;

  static Future<PreferencesStorage> initialize() async {
    if (_instance != null) return _instance!;
    final prefs = await SharedPreferences.getInstance();
    final instance = PreferencesStorage._(prefs);
    _instance = instance;
    AppLogger.info('Preferences initialized', feature: 'storage');
    return instance;
  }

  static bool get isInitialized => _instance != null;

  static PreferencesStorage? get maybeInstance => _instance;

  static PreferencesStorage get instance {
    if (_instance == null) {
      AppLogger.warning(
        'PreferencesStorage.instance accessed before initialize() completed',
        feature: 'storage',
      );
    }
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
  static const String _keyAuthServerExpiresAt = 'auth_server_expires_at';
  static const String _keyPendingOtpEmail = 'pending_otp_email';

  // ---------------------------------------------------------------------------
  // Auth identity (non-sensitive) — password must never be stored here.
  // ---------------------------------------------------------------------------

  String? get authServerUrl => _prefs.getString(_keyAuthServerUrl);
  String? get authUsername => _prefs.getString(_keyAuthUsername);

  /// Durable browser fallback for iOS PWAs, and a legacy migration source.
  ///
  /// On web, `flutter_secure_storage` and SharedPreferences are both backed by
  /// origin-scoped browser storage. Keeping this fallback prevents a WebCrypto
  /// failure from turning every PWA relaunch into a new login prompt.
  String? get authPasswordEnc => _prefs.getString(_keyAuthPasswordEnc);

  DateTime? get authServerExpiresAt => DateTime.tryParse(
    _prefs.getString(_keyAuthServerExpiresAt) ?? '',
  )?.toUtc();

  /// Persists the server identity and, on web only, a durable credential
  /// fallback for browsers where WebCrypto storage cannot be restored.
  Future<void> saveAuthIdentity({
    required String serverUrl,
    required String username,
    String? webPassword,
    DateTime? serverExpiresAt,
  }) async {
    await Future.wait([
      _prefs.setString(_keyAuthServerUrl, serverUrl),
      _prefs.setString(_keyAuthUsername, username),
      if (kIsWeb && webPassword != null)
        _prefs.setString(
          _keyAuthPasswordEnc,
          base64Encode(utf8.encode(webPassword)),
        )
      else
        _prefs.remove(_keyAuthPasswordEnc),
      if (serverExpiresAt != null)
        _prefs.setString(
          _keyAuthServerExpiresAt,
          serverExpiresAt.toUtc().toIso8601String(),
        )
      else
        _prefs.remove(_keyAuthServerExpiresAt),
    ]);
  }

  Future<void> clearLegacyPasswordEnc() => _prefs.remove(_keyAuthPasswordEnc);

  Future<void> clearAuthCredentials() async {
    await Future.wait([
      _prefs.remove(_keyAuthServerUrl),
      _prefs.remove(_keyAuthUsername),
      _prefs.remove(_keyAuthPasswordEnc),
      _prefs.remove(_keyAuthServerExpiresAt),
    ]);
  }

  // ---------------------------------------------------------------------------
  // App account OTP (non-secret — cleared after verification)
  // ---------------------------------------------------------------------------

  String? get pendingOtpEmail => _prefs.getString(_keyPendingOtpEmail);

  Future<void> setPendingOtpEmail(String email) =>
      _prefs.setString(_keyPendingOtpEmail, email.trim().toLowerCase());

  Future<void> clearPendingOtpEmail() => _prefs.remove(_keyPendingOtpEmail);

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
