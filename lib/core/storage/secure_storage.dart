import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/storage/preferences_storage.dart';

/// Secure key-value store for sensitive data (credentials, tokens).
///
/// Passwords live only in hardware-backed [FlutterSecureStorage]
/// (Windows DPAPI, Android KeyStore, WebCrypto). URL/username may also be
/// mirrored to preferences for UX prefill — never the password.
class SecureStorage {
  SecureStorage._()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(),
        wOptions: WindowsOptions(),
        webOptions: WebOptions(dbName: 'iptv_vault'),
      );

  static SecureStorage? _instance;
  static SecureStorage get instance {
    _instance ??= SecureStorage._();
    return _instance!;
  }

  final FlutterSecureStorage _storage;

  static const String _keyServerUrl = 'server_url';
  static const String _keyUsername = 'username';
  static const String _keyPassword = 'password';
  static const String _keyServerExpiresAt = 'server_expires_at';
  static const String _keyKidsModeEnabled = 'kids_mode_enabled';
  static const String _keyKidsPinSalt = 'kids_mode_pin_salt';
  static const String _keyKidsPinVerifier = 'kids_mode_pin_verifier';

  String? _decodeString(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return utf8.decode(base64Decode(value));
    } catch (_) {
      return value;
    }
  }

  // ---------------------------------------------------------------------------
  // Server credentials
  // ---------------------------------------------------------------------------

  Future<void> saveCredentials({
    required String serverUrl,
    required String username,
    required String password,
    DateTime? serverExpiresAt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyServerUrl, value: serverUrl),
        _storage.write(key: _keyUsername, value: username),
        _storage.write(key: _keyPassword, value: password),
        if (serverExpiresAt != null)
          _storage.write(
            key: _keyServerExpiresAt,
            value: serverExpiresAt.toUtc().toIso8601String(),
          )
        else
          _storage.delete(key: _keyServerExpiresAt),
      ]);
    } catch (e) {
      AppLogger.error('SecureStorage write warning: $e', feature: 'storage');
    }

    // Mirror non-sensitive identity only; always clear legacy Base64 password.
    try {
      final prefs = PreferencesStorage.maybeInstance;
      if (prefs != null) {
        await prefs.saveAuthIdentity(
          serverUrl: serverUrl,
          username: username,
        );
        AppLogger.info('Credentials saved to secure storage', feature: 'storage');
      }
    } catch (e) {
      AppLogger.error(
        'Failed to save auth identity prefs: $e',
        feature: 'storage',
      );
    }
  }

  Future<
    ({
      String serverUrl,
      String username,
      String password,
      DateTime? serverExpiresAt,
    })?
  >
  loadCredentials() async {
    // 1. Prefer FlutterSecureStorage
    String? serverUrl;
    String? username;
    String? password;
    DateTime? serverExpiresAt;

    try {
      final results = await Future.wait([
        _storage.read(key: _keyServerUrl),
        _storage.read(key: _keyUsername),
        _storage.read(key: _keyPassword),
        _storage.read(key: _keyServerExpiresAt),
      ]);
      serverUrl = results[0];
      username = results[1];
      password = results[2];
      serverExpiresAt = DateTime.tryParse(results[3] ?? '')?.toUtc();
    } catch (e) {
      AppLogger.error('SecureStorage read warning: $e', feature: 'storage');
    }

    if (serverUrl != null &&
        serverUrl.isNotEmpty &&
        username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      try {
        final prefs = PreferencesStorage.maybeInstance;
        if (prefs != null) {
          unawaited(
            prefs
                .saveAuthIdentity(serverUrl: serverUrl, username: username)
                .catchError((_) {}),
          );
        }
      } catch (e) {
        AppLogger.warning('Could not save auth identity: $e', feature: 'storage');
      }
      return (
        serverUrl: serverUrl,
        username: username,
        password: password,
        serverExpiresAt: serverExpiresAt,
      );
    }

    // 2. One-time migrate legacy Base64 password from preferences, then clear it.
    try {
      final prefs = PreferencesStorage.maybeInstance;
      if (prefs != null) {
        final prefUrl = prefs.authServerUrl;
        final prefUser = prefs.authUsername;
        final prefPassEnc = prefs.authPasswordEnc;

        if (prefUrl != null &&
            prefUrl.isNotEmpty &&
            prefUser != null &&
            prefUser.isNotEmpty &&
            prefPassEnc != null &&
            prefPassEnc.isNotEmpty) {
          final decodedPass = _decodeString(prefPassEnc);
          if (decodedPass != null && decodedPass.isNotEmpty) {
            await saveCredentials(
              serverUrl: prefUrl,
              username: prefUser,
              password: decodedPass,
            );
            return (
              serverUrl: prefUrl,
              username: prefUser,
              password: decodedPass,
              serverExpiresAt: null,
            );
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> clearCredentials() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyServerUrl),
        _storage.delete(key: _keyUsername),
        _storage.delete(key: _keyPassword),
        _storage.delete(key: _keyServerExpiresAt),
      ]);
    } catch (e) {
      AppLogger.error('SecureStorage clear warning: $e', feature: 'storage');
    }

    try {
      final prefs = PreferencesStorage.maybeInstance;
      if (prefs != null) {
        await prefs.clearAuthCredentials();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to clear auth identity prefs: $e',
        feature: 'storage',
      );
    }
  }

  Future<bool> get hasCredentials async {
    final creds = await loadCredentials();
    return creds != null;
  }

  Future<({bool enabled, String? pinSalt, String? pinVerifier})>
  loadKidsModeConfig() async {
    final values = await Future.wait([
      _storage.read(key: _keyKidsModeEnabled),
      _storage.read(key: _keyKidsPinSalt),
      _storage.read(key: _keyKidsPinVerifier),
    ]);
    return (
      enabled: values[0] == 'true',
      pinSalt: values[1],
      pinVerifier: values[2],
    );
  }

  Future<void> saveKidsModePin({
    required String salt,
    required String verifier,
  }) async {
    await Future.wait([
      _storage.write(key: _keyKidsPinSalt, value: salt),
      _storage.write(key: _keyKidsPinVerifier, value: verifier),
    ]);
  }

  Future<void> setKidsModeEnabled(bool enabled) =>
      _storage.write(key: _keyKidsModeEnabled, value: enabled.toString());
}
