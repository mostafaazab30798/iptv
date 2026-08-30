import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/bootstrap.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/identity/trusted_time_service.dart';
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/storage/database/app_database.dart';
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/core/storage/secure_storage.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/repositories/analytics_repository_impl.dart';
import 'package:iptv/data/repositories/app_account_repository_impl.dart';
import 'package:iptv/data/repositories/auth_repository_impl.dart';
import 'package:iptv/data/repositories/device_repository_impl.dart';
import 'package:iptv/data/repositories/entitlement_repository_impl.dart';
import 'package:iptv/data/repositories/epg_repository_impl.dart';
import 'package:iptv/data/repositories/favorites_repository_impl.dart';
import 'package:iptv/data/repositories/history_repository_impl.dart';
import 'package:iptv/data/repositories/live_repository_impl.dart';
import 'package:iptv/data/repositories/release_repository_impl.dart';
import 'package:iptv/data/repositories/series_repository_impl.dart';
import 'package:iptv/data/repositories/vod_repository_impl.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';
import 'package:iptv/domain/repositories/app_account_repository.dart';
import 'package:iptv/domain/repositories/auth_repository.dart';
import 'package:iptv/domain/repositories/device_repository.dart';
import 'package:iptv/domain/repositories/entitlement_repository.dart';
import 'package:iptv/domain/repositories/epg_repository.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/features/subscription/entitlement_controller.dart';
import 'package:iptv/domain/repositories/release_repository.dart';
import 'package:iptv/features/updates/update_controller.dart';

// -----------------------------------------------------------------------------
// Core Storage & Infrastructure Providers
// -----------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage.instance,
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => ref.watch(appDatabaseProvider),
);

// -----------------------------------------------------------------------------
// Auth & Session Providers
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Networking & Remote DataSource Providers
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Domain Repositories Providers
// -----------------------------------------------------------------------------

final liveRepositoryProvider = Provider<LiveRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return LiveRepositoryImpl(remoteDataSource: ds);
});

final vodRepositoryProvider = Provider<VodRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return VodRepositoryImpl(remoteDataSource: ds);
});

final seriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return SeriesRepositoryImpl(remoteDataSource: ds);
});

final epgRepositoryProvider = Provider<EpgRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return EpgRepositoryImpl(remoteDataSource: ds);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FavoritesRepositoryImpl(database: db);
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HistoryRepositoryImpl(database: db);
});

// -----------------------------------------------------------------------------
// App Locale Provider
// -----------------------------------------------------------------------------

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_initialLocale());

  static Locale _initialLocale() {
    try {
      final code = PreferencesStorage.instance.locale;
      return Locale(code);
    } catch (_) {
      return const Locale('en');
    }
  }

  Future<void> setLocale(String code) async {
    try {
      await PreferencesStorage.instance.setLocale(code);
    } catch (_) {}
    state = Locale(code);
  }

  void refreshFromStorage() {
    state = _initialLocale();
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

// -----------------------------------------------------------------------------
// App account (HOPE TV commercial — separate from IPTV sessionProvider)
// -----------------------------------------------------------------------------

final installationIdentityProvider = Provider<InstallationIdentity>((ref) {
  return InstallationIdentity();
});

final appAccountRepositoryProvider = Provider<AppAccountRepository>((ref) {
  final repo = AppAccountRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    installationIdentity: ref.watch(installationIdentityProvider),
  );
});

final appAccountSessionProvider =
    StateNotifierProvider<AppAccountController, AppAccountSessionState>((ref) {
  return AppAccountController(
    accountRepository: ref.watch(appAccountRepositoryProvider),
    deviceRepository: ref.watch(deviceRepositoryProvider),
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
});

final trustedTimeProvider = Provider<TrustedTimeService>((ref) {
  return TrustedTimeService();
});

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepositoryImpl(
    trustedTime: ref.watch(trustedTimeProvider),
  );
});

final entitlementProvider =
    StateNotifierProvider<EntitlementController, EntitlementState>((ref) {
  return EntitlementController(
    entitlementRepository: ref.watch(entitlementRepositoryProvider),
    deviceRepository: ref.watch(deviceRepositoryProvider),
    installationIdentity: ref.watch(installationIdentityProvider),
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl();
});

final releaseRepositoryProvider = Provider<ReleaseRepository>((ref) {
  return ReleaseRepositoryImpl();
});

final updateProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
  return UpdateController(ref.watch(releaseRepositoryProvider));
});
