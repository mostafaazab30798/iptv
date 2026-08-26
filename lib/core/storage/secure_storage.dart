import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iptv/core/logging/app_logger.dart';

/// Secure key-value store for sensitive data (credentials, tokens).
///
/// On Android uses EncryptedSharedPreferences.
/// On iOS/macOS uses Keychain.
/// On Windows uses Windows Credential Manager.
/// On Web falls back to encrypted local storage (treat as less secure).
class SecureStorage {
  SecureStorage._() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    wOptions: WindowsOptions(),
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
      AppLogger.info('Credentials saved', feature: 'storage');
    } catch (e) {
      AppLogger.error('Failed to save credentials', feature: 'storage', error: e);
      rethrow;
    }
  }

  Future<({String serverUrl, String username, String password})?> loadCredentials() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _keyServerUrl),
        _storage.read(key: _keyUsername),
        _storage.read(key: _keyPassword),
      ]);
      final serverUrl = results[0];
      final username = results[1];
      final password = results[2];
      if (serverUrl == null || username == null || password == null) return null;
      return (serverUrl: serverUrl, username: username, password: password);
    } catch (e) {
      AppLogger.error('Failed to load credentials', feature: 'storage', error: e);
      return null;
    }
  }

  Future<void> clearCredentials() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyServerUrl),
        _storage.delete(key: _keyUsername),
        _storage.delete(key: _keyPassword),
      ]);
    } catch (e) {
      AppLogger.error('Failed to clear credentials', feature: 'storage', error: e);
    }
  }

  Future<bool> get hasCredentials async {
    final creds = await loadCredentials();
    return creds != null;
  }
}
