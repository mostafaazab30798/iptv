import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/bootstrap.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/identity/trusted_time_service.dart';
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/core/releases/installed_app_info.dart';
import 'package:iptv/core/storage/database/app_database.dart' hide Channel;
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/core/storage/secure_storage.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/repositories/analytics_repository_impl.dart';
import 'package:iptv/data/repositories/app_account_repository_impl.dart';
import 'package:iptv/data/repositories/auth_repository_impl.dart';
import 'package:iptv/data/repositories/device_repository_impl.dart';
import 'package:iptv/data/repositories/entitlement_repository_impl.dart';
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
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/features/subscription/entitlement_controller.dart';
import 'package:iptv/domain/repositories/release_repository.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/features/catalog_filter/excluded_categories_live_repository.dart';
import 'package:iptv/features/catalog_filter/excluded_live_categories_policy.dart';
import 'package:iptv/features/kids_mode/kids_content_policy.dart';
import 'package:iptv/features/kids_mode/kids_filtered_repositories.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/kids_mode_state.dart';
import 'package:iptv/features/kids_mode/kids_mode_storage.dart';
import 'package:iptv/features/kids_mode/kids_allowed_content.dart';

// -----------------------------------------------------------------------------
// Core Storage & Infrastructure Providers
// -----------------------------------------------------------------------------

final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage.instance,
);

final kidsModeProvider =
    StateNotifierProvider<KidsModeController, KidsModeState>((ref) {
      return KidsModeController(
        SecureKidsModeStorage(ref.watch(secureStorageProvider)),
      );
    });

final kidsContentPolicyProvider = Provider<KidsContentPolicy>(
  (_) => const KidsContentPolicy(),
);

final excludedLiveCategoriesPolicyProvider =
    Provider<ExcludedLiveCategoriesPolicy>(
  (_) => const ExcludedLiveCategoriesPolicy(),
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

final _rawLiveRepositoryProvider = Provider<LiveRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return LiveRepositoryImpl(remoteDataSource: ds);
});

final _rawVodRepositoryProvider = Provider<VodRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return VodRepositoryImpl(remoteDataSource: ds);
});

final _rawSeriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return SeriesRepositoryImpl(remoteDataSource: ds);
});

final liveRepositoryProvider = Provider<LiveRepository?>((ref) {
  final repository = ref.watch(_rawLiveRepositoryProvider);
  final kidsMode = ref.watch(kidsModeProvider);
  if (repository == null || !kidsMode.isInitialized) return null;

  final excludedPolicy = ref.watch(excludedLiveCategoriesPolicyProvider);
  // Always hide non–Middle-East country packages; Kids Mode also applies them.
  final catalogFiltered = ExcludedCategoriesLiveRepository(
    repository,
    excludedPolicy,
  );
  return kidsMode.isEnabled
      ? KidsFilteredLiveRepository(
          catalogFiltered,
          ref.watch(kidsContentPolicyProvider),
          excludedCategories: excludedPolicy,
        )
      : catalogFiltered;
});

final vodRepositoryProvider = Provider<VodRepository?>((ref) {
  final repository = ref.watch(_rawVodRepositoryProvider);
  final kidsMode = ref.watch(kidsModeProvider);
  if (repository == null || !kidsMode.isInitialized) return null;
  return kidsMode.isEnabled
      ? KidsFilteredVodRepository(
          repository,
          ref.watch(kidsContentPolicyProvider),
        )
      : repository;
});

final seriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final repository = ref.watch(_rawSeriesRepositoryProvider);
  final kidsMode = ref.watch(kidsModeProvider);
  if (repository == null || !kidsMode.isInitialized) return null;
  return kidsMode.isEnabled
      ? KidsFilteredSeriesRepository(
          repository,
          ref.watch(kidsContentPolicyProvider),
        )
      : repository;
});

final kidsAllowedContentProvider = FutureProvider<KidsAllowedContent>((
  ref,
) async {
  final mode = ref.watch(kidsModeProvider);
  if (!mode.isInitialized) return const KidsAllowedContent.denyAll();
  if (!mode.isEnabled) return const KidsAllowedContent.unrestricted();

  final liveRepository = ref.watch(liveRepositoryProvider);
  final vodRepository = ref.watch(vodRepositoryProvider);
  final seriesRepository = ref.watch(seriesRepositoryProvider);
  if (liveRepository == null ||
      vodRepository == null ||
      seriesRepository == null) {
    return const KidsAllowedContent.denyAll();
  }

  final results = await Future.wait([
    liveRepository.getChannels(),
    vodRepository.getMovies(),
    seriesRepository.getSeries(),
  ]);
  final channels = (results[0] as Result<List<Channel>>).when(
    ok: (items) => items,
    err: (_) => <Channel>[],
  );
  final movies = (results[1] as Result<List<Movie>>).when(
    ok: (items) => items,
    err: (_) => <Movie>[],
  );
  final series = (results[2] as Result<List<Series>>).when(
    ok: (items) => items,
    err: (_) => <Series>[],
  );
  return KidsAllowedContent(
    restricted: true,
    channelIds: {for (final item in channels) item.streamId},
    movieIds: {for (final item in movies) item.streamId},
    seriesIds: {for (final item in series) item.seriesId},
  );
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
  return EntitlementRepositoryImpl(trustedTime: ref.watch(trustedTimeProvider));
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

final installedAppInfoProvider = Provider<InstalledAppInfo>((ref) {
  return PackageInfoInstalledAppInfo();
});

final appVersionStringProvider = FutureProvider<String>((ref) async {
  final appInfo = ref.watch(installedAppInfoProvider);
  try {
    final version = await appInfo.getVersion();
    final build = await appInfo.getBuildNumber();
    if (version.isNotEmpty) {
      return build != null ? 'v$version ($build)' : 'v$version';
    }
  } catch (_) {}
  return 'v${AppConstants.appVersion} (${AppConstants.appBuildNumber})';
});

final updateProvider = StateNotifierProvider<UpdateController, UpdateState>((
  ref,
) {
  return UpdateController(ref.watch(releaseRepositoryProvider));
});
