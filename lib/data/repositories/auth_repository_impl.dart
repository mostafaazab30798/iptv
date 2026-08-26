import 'dart:developer' as dev;
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/api_config.dart';
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
      // Clean and normalize input server URL
      var normalizedUrl = serverUrl.trim();
      if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
        normalizedUrl = 'http://$normalizedUrl';
      }
      // Remove trailing slash and any trailing /player_api.php
      normalizedUrl = normalizedUrl
          .replaceAll(RegExp(r'/player_api\.php.*$', caseSensitive: false), '')
          .replaceAll(RegExp(r'/+$'), '');

      final user = username.trim();
      final pass = password.trim();

      dev.log('Authenticating with server: $normalizedUrl, user: $user', name: 'AuthRepo');

      // Create client to validate credentials with server
      final tempClient = ApiClient(ApiConfig(
        baseUrl: normalizedUrl,
        username: user,
        password: pass,
      ));

      final dataSource = XtreamRemoteDataSource(tempClient);
      final response = await dataSource.authenticate();

      dev.log('Server response: $response', name: 'AuthRepo');

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
      dev.log('Authentication failed with error: $e', name: 'AuthRepo');
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
