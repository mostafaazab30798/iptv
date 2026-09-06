import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers/core_providers.dart';
import 'package:iptv/app/providers/session_providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/cache/catalog_memory_cache.dart';
import 'package:iptv/data/repositories/favorites_repository_impl.dart';
import 'package:iptv/data/repositories/history_repository_impl.dart';
import 'package:iptv/data/repositories/live_repository_impl.dart';
import 'package:iptv/data/repositories/series_repository_impl.dart';
import 'package:iptv/data/repositories/vod_repository_impl.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/features/catalog_filter/excluded_categories_live_repository.dart';
import 'package:iptv/features/kids_mode/kids_allowed_content.dart';
import 'package:iptv/features/kids_mode/kids_filtered_repositories.dart';

/// Session-keyed in-memory catalog cache. Recreated when the IPTV session identity changes.
final catalogMemoryCacheProvider = Provider<CatalogMemoryCache>((ref) {
  // Watching session credentials recreates this provider on server/account switch.
  ref.watch(
    sessionProvider.select(
      (s) => (
        url: s.valueOrNull?.serverUrl,
        user: s.valueOrNull?.username,
      ),
    ),
  );
  final cache = CatalogMemoryCache();
  ref.onDispose(cache.clear);
  return cache;
});

final _rawLiveRepositoryProvider = Provider<LiveRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return LiveRepositoryImpl(
    remoteDataSource: ds,
    cache: ref.watch(catalogMemoryCacheProvider),
  );
});

final _rawVodRepositoryProvider = Provider<VodRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return VodRepositoryImpl(
    remoteDataSource: ds,
    cache: ref.watch(catalogMemoryCacheProvider),
  );
});

final _rawSeriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final ds = ref.watch(xtreamDataSourceProvider);
  if (ds == null) return null;
  return SeriesRepositoryImpl(
    remoteDataSource: ds,
    cache: ref.watch(catalogMemoryCacheProvider),
  );
});

final liveRepositoryProvider = Provider<LiveRepository?>((ref) {
  final repository = ref.watch(_rawLiveRepositoryProvider);
  final kidsFilter = ref.watch(
    kidsModeProvider.select(
      (s) => (isInitialized: s.isInitialized, isEnabled: s.isEnabled),
    ),
  );
  if (repository == null || !kidsFilter.isInitialized) return null;

  final excludedPolicy = ref.watch(excludedLiveCategoriesPolicyProvider);
  // Always hide non–Middle-East country packages; Kids Mode also applies them.
  final catalogFiltered = ExcludedCategoriesLiveRepository(
    repository,
    excludedPolicy,
  );
  return kidsFilter.isEnabled
      ? KidsFilteredLiveRepository(
          catalogFiltered,
          ref.watch(kidsContentPolicyProvider),
          excludedCategories: excludedPolicy,
        )
      : catalogFiltered;
});

final vodRepositoryProvider = Provider<VodRepository?>((ref) {
  final repository = ref.watch(_rawVodRepositoryProvider);
  final kidsFilter = ref.watch(
    kidsModeProvider.select(
      (s) => (isInitialized: s.isInitialized, isEnabled: s.isEnabled),
    ),
  );
  if (repository == null || !kidsFilter.isInitialized) return null;
  return kidsFilter.isEnabled
      ? KidsFilteredVodRepository(
          repository,
          ref.watch(kidsContentPolicyProvider),
        )
      : repository;
});

final seriesRepositoryProvider = Provider<SeriesRepository?>((ref) {
  final repository = ref.watch(_rawSeriesRepositoryProvider);
  final kidsFilter = ref.watch(
    kidsModeProvider.select(
      (s) => (isInitialized: s.isInitialized, isEnabled: s.isEnabled),
    ),
  );
  if (repository == null || !kidsFilter.isInitialized) return null;
  return kidsFilter.isEnabled
      ? KidsFilteredSeriesRepository(
          repository,
          ref.watch(kidsContentPolicyProvider),
        )
      : repository;
});

final kidsAllowedContentProvider = FutureProvider<KidsAllowedContent>((
  ref,
) async {
  final kidsFilter = ref.watch(
    kidsModeProvider.select(
      (s) => (isInitialized: s.isInitialized, isEnabled: s.isEnabled),
    ),
  );
  if (!kidsFilter.isInitialized) return const KidsAllowedContent.denyAll();
  if (!kidsFilter.isEnabled) return const KidsAllowedContent.unrestricted();

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
