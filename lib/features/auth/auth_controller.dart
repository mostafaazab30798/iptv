import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/repositories/auth_repository.dart';

class AuthController extends StateNotifier<AsyncValue<ServerConfig?>> {
  AuthController(this._authRepo, this._ref) : super(const AsyncValue.data(null));

  final AuthRepository _authRepo;
  final Ref _ref;

  Future<Result<ServerConfig>> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _authRepo.authenticate(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    if (result.isOk) {
      final config = result.value;
      state = AsyncValue.data(config);
      _ref.read(sessionProvider.notifier).setConfig(config);
      // Credential-free trial activation after IPTV success (Phase 3).
      try {
        await _ref.read(entitlementProvider.notifier).activateTrialAfterIptvSuccess();
      } catch (_) {
        // Do not roll back IPTV login; access gate will require retry/connectivity.
      }
    } else {
      state = AsyncValue.error(result.error.message, StackTrace.current);
    }

    return result;
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _ref.read(sessionProvider.notifier).clearSession();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<ServerConfig?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo, ref);
});
