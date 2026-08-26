import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/server_config.dart';

abstract interface class AuthRepository {
  /// Validates credentials against the server and persists them locally.
  Future<Result<ServerConfig>> authenticate({
    required String serverUrl,
    required String username,
    required String password,
  });

  /// Loads the saved active server config from secure storage.
  Future<ServerConfig?> loadSavedConfig();

  /// Clears all stored credentials and signs out.
  Future<void> signOut();

  /// Whether there is a saved, valid config.
  Future<bool> get isAuthenticated;
}
