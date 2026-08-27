import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

enum HeroItemType { live, movie, series }

class HomeHeroItem {
  const HomeHeroItem({
    required this.title,
    required this.subtitle,
    required this.type,
    this.badge,
    this.rating,
    this.genre,
    this.description,
    this.backdropUrl,
    this.posterUrl,
    this.channel,
    this.movie,
    this.series,
  });

  final String title;
  final String subtitle;
  final HeroItemType type;
  final String? badge;
  final String? rating;
  final String? genre;
  final String? description;
  final String? backdropUrl;
  final String? posterUrl;
  final Channel? channel;
  final Movie? movie;
  final Series? series;
}

class HomeState {
  const HomeState({
    this.heroItem,
    this.continueWatching = const [],
    this.liveChannels = const [],
    this.favorites = const [],
    this.featuredMovies = const [],
    this.popularSeries = const [],
    this.sportsChannels = const [],
    this.newsChannels = const [],
    this.isLoading = false,
    this.error,
  });

  final HomeHeroItem? heroItem;
  final List<WatchHistoryEntry> continueWatching;
  final List<Channel> liveChannels;
  final List<Favorite> favorites;
  final List<Movie> featuredMovies;
  final List<Series> popularSeries;
  final List<Channel> sportsChannels;
  final List<Channel> newsChannels;
  final bool isLoading;
  final String? error;

  HomeState copyWith({
    HomeHeroItem? heroItem,
    List<WatchHistoryEntry>? continueWatching,
    List<Channel>? liveChannels,
    List<Favorite>? favorites,
    List<Movie>? featuredMovies,
    List<Series>? popularSeries,
    List<Channel>? sportsChannels,
    List<Channel>? newsChannels,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      heroItem: heroItem ?? this.heroItem,
      continueWatching: continueWatching ?? this.continueWatching,
      liveChannels: liveChannels ?? this.liveChannels,
      favorites: favorites ?? this.favorites,
      featuredMovies: featuredMovies ?? this.featuredMovies,
      popularSeries: popularSeries ?? this.popularSeries,
      sportsChannels: sportsChannels ?? this.sportsChannels,
      newsChannels: newsChannels ?? this.newsChannels,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController({
    required LiveRepository? liveRepo,
    required VodRepository? vodRepo,
    required SeriesRepository? seriesRepo,
    required FavoritesRepository favoritesRepo,
    required HistoryRepository historyRepo,
  })  : _liveRepo = liveRepo,
        _vodRepo = vodRepo,
        _seriesRepo = seriesRepo,
        _favoritesRepo = favoritesRepo,
        _historyRepo = historyRepo,
        super(const HomeState()) {
    loadData();
  }

  final LiveRepository? _liveRepo;
  final VodRepository? _vodRepo;
  final SeriesRepository? _seriesRepo;
  final FavoritesRepository _favoritesRepo;
  final HistoryRepository _historyRepo;

  bool _isFetching = false;

  Future<void> loadData({bool forceRefresh = false}) async {
    if (_liveRepo == null) return;
    if (_isFetching && !forceRefresh) return;
    _isFetching = true;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Instant local DB data (History & Favorites) — resolves in < 5ms
      final localResults = await Future.wait([
        _historyRepo.getHistory(limit: 20),
        _favoritesRepo.getFavorites(),
      ]);

      final historyRes = localResults[0] as Result<List<WatchHistoryEntry>>?;
      final history = historyRes?.when(ok: (h) => h, err: (_) => <WatchHistoryEntry>[]) ?? <WatchHistoryEntry>[];
      final activeContinueWatching = history
          .where((h) => h.type != WatchHistoryType.channel && !h.isFinished && h.positionSecs >= 5)
          .take(20)
          .toList();

      final favoritesRes = localResults[1] as Result<List<Favorite>>?;
      final favorites = favoritesRes?.when(ok: (f) => f, err: (_) => <Favorite>[]) ?? <Favorite>[];

      // Immediately render local data
      state = state.copyWith(
        continueWatching: activeContinueWatching,
        favorites: favorites,
      );

      // 2. Launch catalog fetches in parallel, updating state progressively as each finishes
      var currentHero = state.heroItem;
      List<Movie> latestMovies = state.featuredMovies;
      List<Channel> latestChannels = state.liveChannels;

      // Featured live uses take(20); sports/news use category-indexed slices
      // (no full-catalog name keyword scan on Home).
      final liveTask = () async {
        try {
          final channelsRes =
              await _liveRepo!.getChannels(forceRefresh: forceRefresh);
          final channels =
              channelsRes.when(ok: (c) => c, err: (_) => <Channel>[]);
          if (channels.isEmpty) return;

          latestChannels = channels;
          currentHero ??= _computeHeroItem(latestMovies, channels);

          final rowSlices =
              await _loadSportsAndNewsRows(forceRefresh: forceRefresh);
          state = state.copyWith(
            liveChannels: channels.take(20).toList(),
            sportsChannels: rowSlices.sports,
            newsChannels: rowSlices.news,
            heroItem: currentHero,
          );
        } catch (_) {}
      }();

      final vodTask = (_vodRepo != null)
          ? _vodRepo.getMovies(forceRefresh: forceRefresh).then((res) {
              final movies = res.when(ok: (m) => m, err: (_) => <Movie>[]);
              if (movies.isNotEmpty) {
                latestMovies = movies;
                final featured = movies.take(20).toList();
                currentHero = _computeHeroItem(movies, latestChannels);
                state = state.copyWith(
                  featuredMovies: featured,
                  heroItem: currentHero,
                );
              }
            }).catchError((_) {})
          : Future<void>.value();

      final seriesTask = (_seriesRepo != null)
          ? _seriesRepo.getSeries(forceRefresh: forceRefresh).then((res) {
              final series = res.when(ok: (s) => s, err: (_) => <Series>[]);
              if (series.isNotEmpty) {
                state = state.copyWith(
                  popularSeries: series.take(20).toList(),
                );
              }
            }).catchError((_) {})
          : Future<void>.value();

      await Future.wait([liveTask, vodTask, seriesTask]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  HomeHeroItem? _computeHeroItem(List<Movie> movies, List<Channel> channels) {
    final featuredMoviesList = movies.take(20).toList();
    if (featuredMoviesList.isNotEmpty) {
      double highestRating = -1.0;
      for (final m in featuredMoviesList) {
        final r = double.tryParse(m.rating ?? '');
        if (r != null && r > highestRating) {
          highestRating = r;
        }
      }

      Movie latestTopRatedMovie = featuredMoviesList.first;
      int latestYear = -1;
      double bestRating = -1.0;

      for (final m in featuredMoviesList) {
        final r = double.tryParse(m.rating ?? '') ?? -1.0;
        final year = m.releaseYear ?? 0;
        final isTopTier = highestRating > 0 && r >= (highestRating - 0.8).clamp(0.0, 10.0);

        if (isTopTier) {
          if (year > latestYear || (year == latestYear && r > bestRating)) {
            latestYear = year;
            bestRating = r;
            latestTopRatedMovie = m;
          }
        }
      }

      if (bestRating < 0) {
        int newestYear = -1;
        for (final m in featuredMoviesList) {
          final y = m.releaseYear ?? 0;
          if (y > newestYear) {
            newestYear = y;
            latestTopRatedMovie = m;
          }
        }
      }

      final ratingStr = latestTopRatedMovie.rating != null && latestTopRatedMovie.rating!.isNotEmpty
          ? latestTopRatedMovie.rating!
          : null;

      return HomeHeroItem(
        title: latestTopRatedMovie.name,
        subtitle: 'Featured Movie',
        type: HeroItemType.movie,
        badge: ratingStr != null ? '★ $ratingStr' : (latestTopRatedMovie.releaseYear?.toString() ?? 'HD'),
        rating: ratingStr,
        genre: latestTopRatedMovie.genre ?? 'Top Rated Cinema',
        description: latestTopRatedMovie.plot ?? 'Stream in high definition on your favorite screen.',
        backdropUrl: latestTopRatedMovie.streamIcon,
        posterUrl: latestTopRatedMovie.streamIcon,
        movie: latestTopRatedMovie,
      );
    } else if (channels.isNotEmpty) {
      final topChannel = channels.first;
      return HomeHeroItem(
        title: topChannel.name,
        subtitle: 'Featured Live Stream',
        type: HeroItemType.live,
        badge: 'LIVE NOW',
        genre: 'Live Television',
        description: 'Watch real-time live broadcasting with zero latency.',
        backdropUrl: topChannel.streamIcon,
        posterUrl: topChannel.streamIcon,
        channel: topChannel,
      );
    }
    return null;
  }

  /// Builds Home sports/news rows from category-scoped live cache slices.
  Future<({List<Channel> sports, List<Channel> news})> _loadSportsAndNewsRows({
    required bool forceRefresh,
  }) async {
    final liveRepo = _liveRepo;
    if (liveRepo == null) {
      return (sports: const <Channel>[], news: const <Channel>[]);
    }

    final catsRes = await liveRepo.getCategories(forceRefresh: forceRefresh);
    final categories = catsRes.when(ok: (c) => c, err: (_) => <Category>[]);

    final sportsCatIds = <int>[];
    final newsCatIds = <int>[];
    for (final cat in categories) {
      if (_isSportsCategoryName(cat.name)) {
        sportsCatIds.add(cat.id);
      } else if (_isNewsCategoryName(cat.name)) {
        newsCatIds.add(cat.id);
      }
    }

    final sports = await _channelsFromCategoryIds(
      sportsCatIds,
      limit: 15,
      forceRefresh: forceRefresh,
    );
    final news = await _channelsFromCategoryIds(
      newsCatIds,
      limit: 15,
      forceRefresh: forceRefresh,
    );
    return (sports: sports, news: news);
  }

  Future<List<Channel>> _channelsFromCategoryIds(
    List<int> categoryIds, {
    required int limit,
    required bool forceRefresh,
  }) async {
    if (categoryIds.isEmpty || _liveRepo == null) return const [];

    final out = <Channel>[];
    final seen = <int>{};
    for (final categoryId in categoryIds) {
      if (out.length >= limit) break;
      final res = await _liveRepo.getChannels(
        categoryId: categoryId,
        forceRefresh: forceRefresh,
      );
      final slice = res.when(ok: (c) => c, err: (_) => <Channel>[]);
      for (final c in slice) {
        if (!seen.add(c.streamId)) continue;
        out.add(c);
        if (out.length >= limit) break;
      }
    }
    return out;
  }

  static bool _isSportsCategoryName(String name) {
    final n = name.toLowerCase();
    return n.contains('sport') ||
        n.contains('espn') ||
        n.contains('bein') ||
        n.contains('nba') ||
        n.contains('football') ||
        n.contains('رياض') ||
        n.contains('كره') ||
        n.contains('كرة');
  }

  static bool _isNewsCategoryName(String name) {
    final n = name.toLowerCase();
    return n.contains('news') ||
        n.contains('cnn') ||
        n.contains('bbc') ||
        n.contains('jazeera') ||
        n.contains('اخبار') ||
        n.contains('أخبار') ||
        n.contains('إخبار');
  }

  /// Fast refresh of watch history/continue watching items (e.g. on returning to Home).
  Future<void> refreshContinueWatching() async {
    try {
      final historyRes = await _historyRepo.getHistory(limit: 20);
      final history = historyRes.when(
        ok: (h) => h,
        err: (_) => <WatchHistoryEntry>[],
      );
      final active = history
          .where((h) => h.type != WatchHistoryType.channel && !h.isFinished && h.positionSecs >= 5)
          .take(20)
          .toList();
      state = state.copyWith(continueWatching: active);
    } catch (_) {}
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  final liveRepo = ref.watch(liveRepositoryProvider);
  final vodRepo = ref.watch(vodRepositoryProvider);
  final seriesRepo = ref.watch(seriesRepositoryProvider);
  final favoritesRepo = ref.watch(favoritesRepositoryProvider);
  final historyRepo = ref.watch(historyRepositoryProvider);

  return HomeController(
    liveRepo: liveRepo,
    vodRepo: vodRepo,
    seriesRepo: seriesRepo,
    favoritesRepo: favoritesRepo,
    historyRepo: historyRepo,
  );
});
