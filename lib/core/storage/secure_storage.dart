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
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyServerUrl, value: serverUrl),
        _storage.write(key: _keyUsername, value: username),
        _storage.write(key: _keyPassword, value: password),
      ]);
    } catch (e) {
      AppLogger.error('SecureStorage write warning: $e', feature: 'storage');
    }

    // Mirror non-sensitive identity only; always clear legacy Base64 password.
    try {
      await PreferencesStorage.instance.saveAuthIdentity(
        serverUrl: serverUrl,
        username: username,
      );
      AppLogger.info('Credentials saved to secure storage', feature: 'storage');
    } catch (e) {
      AppLogger.error('Failed to save auth identity prefs: $e', feature: 'storage');
    }
  }

  Future<({String serverUrl, String username, String password})?> loadCredentials() async {
    // 1. Prefer FlutterSecureStorage
    String? serverUrl;
    String? username;
    String? password;

    try {
      final results = await Future.wait([
        _storage.read(key: _keyServerUrl),
        _storage.read(key: _keyUsername),
        _storage.read(key: _keyPassword),
      ]);
      serverUrl = results[0];
      username = results[1];
      password = results[2];
    } catch (e) {
      AppLogger.error('SecureStorage read warning: $e', feature: 'storage');
    }

    if (serverUrl != null &&
        serverUrl.isNotEmpty &&
        username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      unawaited(
        PreferencesStorage.instance
            .saveAuthIdentity(serverUrl: serverUrl, username: username)
            .catchError((_) {}),
      );
      return (serverUrl: serverUrl, username: username, password: password);
    }

    // 2. One-time migrate legacy Base64 password from preferences, then clear it.
    try {
      final prefUrl = PreferencesStorage.instance.authServerUrl;
      final prefUser = PreferencesStorage.instance.authUsername;
      final prefPassEnc = PreferencesStorage.instance.authPasswordEnc;

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
          return (serverUrl: prefUrl, username: prefUser, password: decodedPass);
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
      ]);
    } catch (e) {
      AppLogger.error('SecureStorage clear warning: $e', feature: 'storage');
    }

    try {
      await PreferencesStorage.instance.clearAuthCredentials();
    } catch (e) {
      AppLogger.error('Failed to clear auth identity prefs: $e', feature: 'storage');
    }
  }

  Future<bool> get hasCredentials async {
    final creds = await loadCredentials();
    return creds != null;
  }
}
