import 'package:flutter/foundation.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/network/url_helpers.dart';
import 'package:iptv/core/storage/secure_storage.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.secureStorage});

  final SecureStorage secureStorage;

  @override
  Future<Result<ServerConfig>> authenticate({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    try {
      final normalizedUrl = UrlHelpers.normalizeServerUrl(serverUrl);

      final user = username.trim();
      final pass = password.trim();

      if (kDebugMode) {
        AppLogger.debug(
          'Authenticating with server: $normalizedUrl',
          feature: 'auth',
        );
      }

      // Create client to validate credentials with server
      final tempClient = ApiClient(ApiConfig(
        baseUrl: normalizedUrl,
        username: user,
        password: pass,
      ));

      final dataSource = XtreamRemoteDataSource(tempClient);
      final response = await dataSource.authenticate();

      final userInfo = response['user_info'] as Map<String, dynamic>?;
      if (userInfo == null) {
        tempClient.close();
        return const Err(AppResultError('Could not verify server response. Check your server address and port.'));
      }

      final authValue = userInfo['auth'];
      final status = userInfo['status']?.toString().toLowerCase();

      final isAuthorized = authValue == 1 || authValue == '1' || authValue == true || status == 'active';
      if (!isAuthorized) {
        tempClient.close();
        final msg = userInfo['message']?.toString() ?? 'Invalid username or password';
        return Err(AppResultError(msg));
      }

      if (status == 'expired' || status == 'banned' || status == 'disabled') {
        tempClient.close();
        return Err(AppResultError('Account is $status. Please contact your provider.'));
      }

      // Save verified credentials to secure storage
      await secureStorage.saveCredentials(
        serverUrl: normalizedUrl,
        username: user,
        password: pass,
      );

      tempClient.close();

      return Ok(ServerConfig(
        serverUrl: normalizedUrl,
        username: user,
        password: pass,
      ));
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug(
          'Authentication failed: ${e.runtimeType}',
          feature: 'auth',
        );
      }
      return Err(AppResultError('Could not connect to server: ${e.toString()}', cause: e));
    }
  }

  @override
  Future<ServerConfig?> loadSavedConfig() async {
    final creds = await secureStorage.loadCredentials();
    if (creds == null) return null;
    return ServerConfig(
      serverUrl: creds.serverUrl,
      username: creds.username,
      password: creds.password,
    );
  }

  @override
  Future<void> signOut() => secureStorage.clearCredentials();

  @override
  Future<bool> get isAuthenticated => secureStorage.hasCredentials;
}
