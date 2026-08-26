import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/repositories/auth_repository.dart';

class AuthenticateUseCase {
  const AuthenticateUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<ServerConfig>> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    return _repository.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }
}
