import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists Supabase Auth sessions in platform secure storage.
///
/// Kept separate from IPTV credential keys in [SecureStorage].
/// Matches supabase_flutter [LocalStorage]: [accessToken] returns the full
/// persisted session payload string.
class SupabaseSecureAuthStorage extends LocalStorage {
  SupabaseSecureAuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              wOptions: WindowsOptions(),
              webOptions: WebOptions(dbName: 'hope_tv_auth_vault'),
            );

  final FlutterSecureStorage _storage;

  static const _sessionKey = 'hope_tv_supabase_auth_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<bool> hasAccessToken() async {
    final session = await accessToken();
    return session != null && session.isNotEmpty;
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() {
    return _storage.delete(key: _sessionKey);
  }
}
