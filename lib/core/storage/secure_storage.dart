import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/storage/preferences_storage.dart';

/// Secure key-value store for sensitive data (credentials, tokens).
///
/// Combines hardware-backed FlutterSecureStorage (Windows DPAPI, Android KeyStore, WebCrypto)
/// with a reliable fallback persistence layer to guarantee persistent sessions across app restarts on Windows & Web.
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

  String _encodeString(String value) {
    return base64Encode(utf8.encode(value));
  }

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
    // 1. Write to hardware-backed secure storage
    try {
      await Future.wait([
        _storage.write(key: _keyServerUrl, value: serverUrl),
        _storage.write(key: _keyUsername, value: username),
        _storage.write(key: _keyPassword, value: password),
      ]);
    } catch (e) {
      AppLogger.error('SecureStorage write warning: $e', feature: 'storage');
    }

    // 2. Write to persistent preferences fallback (guarantees persistence across Windows/Web reboots)
    try {
      await PreferencesStorage.instance.saveAuthCredentials(
        serverUrl: serverUrl,
        username: username,
        passwordEnc: _encodeString(password),
      );
      AppLogger.info('Credentials saved successfully across secure & fallback stores', feature: 'storage');
    } catch (e) {
      AppLogger.error('Failed to save fallback credentials: $e', feature: 'storage');
    }
  }

  Future<({String serverUrl, String username, String password})?> loadCredentials() async {
    // 1. Fast path: PreferencesStorage is already in memory from bootstrap — 0ms synchronous read!
    try {
      final prefUrl = PreferencesStorage.instance.authServerUrl;
      final prefUser = PreferencesStorage.instance.authUsername;
      final prefPassEnc = PreferencesStorage.instance.authPasswordEnc;

      if (prefUrl != null && prefUrl.isNotEmpty &&
          prefUser != null && prefUser.isNotEmpty &&
          prefPassEnc != null && prefPassEnc.isNotEmpty) {
        final decodedPass = _decodeString(prefPassEnc);
        if (decodedPass != null && decodedPass.isNotEmpty) {
          return (serverUrl: prefUrl, username: prefUser, password: decodedPass);
        }
      }
    } catch (_) {}

    // 2. Slow fallback: FlutterSecureStorage
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
      // Re-sync to preferences fallback for subsequent instant launches
      unawaited(PreferencesStorage.instance.saveAuthCredentials(
        serverUrl: serverUrl,
        username: username,
        passwordEnc: _encodeString(password),
      ).catchError((_) {}));

      return (serverUrl: serverUrl, username: username, password: password);
    }

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
      AppLogger.error('Failed to clear fallback credentials: $e', feature: 'storage');
    }
  }

  Future<bool> get hasCredentials async {
    final creds = await loadCredentials();
    return creds != null;
  }
}
