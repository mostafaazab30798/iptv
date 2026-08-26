import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
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

  Future<void> loadData({bool forceRefresh = false}) async {
    if (_liveRepo == null) {
      state = state.copyWith(isLoading: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Execute all repository fetches in parallel for maximum speed
      final results = await Future.wait([
        _liveRepo.getChannels(forceRefresh: forceRefresh),
        _historyRepo.getHistory(limit: 20),
        _favoritesRepo.getFavorites(),
        if (_vodRepo != null)
          _vodRepo.getMovies(forceRefresh: forceRefresh)
        else
          Future.value(null),
        if (_seriesRepo != null)
          _seriesRepo.getSeries(forceRefresh: forceRefresh)
        else
          Future.value(null),
      ]);

      // 1. Live channels
      final channelsRes = results[0] as Result<List<Channel>>?;
      final List<Channel> allChannels = channelsRes != null
          ? channelsRes.when(
              ok: (c) => c,
              err: (_) => <Channel>[],
            )
          : <Channel>[];

      // 2. Watch History
      final historyRes = results[1] as Result<List<WatchHistoryEntry>>?;
      final List<WatchHistoryEntry> history = historyRes != null
          ? historyRes.when(
              ok: (h) => h,
              err: (_) => <WatchHistoryEntry>[],
            )
          : <WatchHistoryEntry>[];

      // 3. Favorites
      final favoritesRes = results[2] as Result<List<Favorite>>?;
      final List<Favorite> favorites = favoritesRes != null
          ? favoritesRes.when(
              ok: (f) => f,
              err: (_) => <Favorite>[],
            )
          : <Favorite>[];

      // 4. Movies
      final moviesRes = results[3] as Result<List<Movie>>?;
      final List<Movie> movies = moviesRes != null
          ? moviesRes.when(
              ok: (m) => m,
              err: (_) => <Movie>[],
            )
          : <Movie>[];

      // 5. Series
      final seriesRes = results[4] as Result<List<Series>>?;
      final List<Series> series = seriesRes != null
          ? seriesRes.when(
              ok: (s) => s,
              err: (_) => <Series>[],
            )
          : <Series>[];

      // Filter categorized channels for highlighted rows (Sports / News)
      final sports = allChannels
          .where((c) =>
              c.name.toLowerCase().contains('sport') ||
              c.name.toLowerCase().contains('espn') ||
              c.name.toLowerCase().contains('bein') ||
              c.name.toLowerCase().contains('nba') ||
              c.name.toLowerCase().contains('football'))
          .take(15)
          .toList();

      final news = allChannels
          .where((c) =>
              c.name.toLowerCase().contains('news') ||
              c.name.toLowerCase().contains('cnn') ||
              c.name.toLowerCase().contains('bbc') ||
              c.name.toLowerCase().contains('al jazeera') ||
              c.name.toLowerCase().contains('sky news'))
          .take(15)
          .toList();

      // Pick an engaging hero item:
      // Priority: Featured Movie with backdrop/plot -> Popular Series -> Top Live Channel
      final featuredMoviesList = movies.take(20).toList();

      // Pick the latest top-rated movie from featured movies:
      HomeHeroItem? heroItem;
      if (featuredMoviesList.isNotEmpty) {
        double highestRating = -1.0;
        for (final m in featuredMoviesList) {
          final r = double.tryParse(m.rating ?? '');
          if (r != null && r > highestRating) {
            highestRating = r;
          }
        }

        // Among top-rated tier movies, select the one with the latest release year
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

        // If no rating available, select newest movie with plot or artwork
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

        heroItem = HomeHeroItem(
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
      } else if (allChannels.isNotEmpty) {
        final topChannel = allChannels.first;
        heroItem = HomeHeroItem(
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

      // Filter active in-progress VOD/Episodes for Continue Watching row (max 20 items)
      final activeContinueWatching = history
          .where((h) => h.type != WatchHistoryType.channel && !h.isFinished && h.positionSecs >= 5)
          .take(20)
          .toList();

      state = state.copyWith(
        heroItem: heroItem,
        liveChannels: allChannels.take(20).toList(),
        continueWatching: activeContinueWatching,
        favorites: favorites,
        featuredMovies: featuredMoviesList,
        popularSeries: series.take(20).toList(),
        sportsChannels: sports,
        newsChannels: news,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
