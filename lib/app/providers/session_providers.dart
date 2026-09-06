import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers/core_providers.dart';
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/datasources/yallakora_matches_datasource.dart';
import 'package:iptv/data/repositories/auth_repository_impl.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/repositories/auth_repository.dart';
import 'package:iptv/domain/services/stream_url_builder.dart';
import 'package:iptv/repositories/matches_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(secureStorage: storage);
});

/// Current active session / ServerConfig provider.
class SessionNotifier extends StateNotifier<AsyncValue<ServerConfig?>> {
  SessionNotifier(this._authRepo) : super(const AsyncValue.loading()) {
    loadSession();
  }

  final AuthRepository _authRepo;

  Future<void> loadSession() async {
    state = const AsyncValue.loading();
    try {
      final config = await _authRepo.loadSavedConfig();
      state = AsyncValue.data(config);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setConfig(ServerConfig config) {
    state = AsyncValue.data(config);
  }

  /// Refreshes provider-owned account metadata without discarding a working
  /// IPTV session when the provider is temporarily unreachable.
  Future<bool> refreshServerMetadata() async {
    final current = state.valueOrNull;
    if (current == null || !current.isValid) return false;
    final result = await _authRepo.authenticate(
      serverUrl: current.serverUrl,
      username: current.username,
      password: current.password,
    );
    if (result.isErr) return false;
    state = AsyncValue.data(result.value);
    return true;
  }

  Future<void> clearSession() async {
    await _authRepo.signOut();
    state = const AsyncValue.data(null);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<ServerConfig?>>((ref) {
      final authRepo = ref.watch(authRepositoryProvider);
      return SessionNotifier(authRepo);
    });

final apiClientProvider = Provider<ApiClient?>((ref) {
  final sessionAsync = ref.watch(sessionProvider);
  final config = sessionAsync.valueOrNull;
  if (config == null || !config.isValid) return null;

  return ApiClient(
    ApiConfig(
      baseUrl: config.serverUrl,
      username: config.username,
      password: config.password,
    ),
  );
});

final xtreamDataSourceProvider = Provider<XtreamRemoteDataSource?>((ref) {
  final client = ref.watch(apiClientProvider);
  if (client == null) return null;
  return XtreamRemoteDataSource(client);
});

final streamUrlBuilderProvider = Provider<StreamUrlBuilder>(
  (_) => const StreamUrlBuilder(),
);

final yallakoraMatchesDataSourceProvider =
    Provider<YallakoraMatchesDataSource>((_) => YallakoraMatchesDataSource());

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final ds = ref.watch(yallakoraMatchesDataSourceProvider);
  return MatchesRepository(dataSource: ds);
});

final liveScoreSourceProvider = Provider<LiveScoreSource>((ref) {
  return ref.watch(yallakoraMatchesDataSourceProvider);
});
