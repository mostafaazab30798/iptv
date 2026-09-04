import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/sports/live_match_finder.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/features/kids_mode/kids_allowed_content.dart';

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
    this.match,
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
  final LiveMatch? match;
}

class HomeState {
  const HomeState({
    this.heroItem,
    this.heroItems = const [],
    this.continueWatching = const [],
    this.liveChannels = const [],
    this.favorites = const [],
    this.featuredMovies = const [],
    this.popularSeries = const [],
    this.sportsChannels = const [],
    this.newsChannels = const [],
    this.isLoading = false,
    this.isHeroPending = false,
    this.error,
  });

  final HomeHeroItem? heroItem;
  final List<HomeHeroItem> heroItems;
  final List<WatchHistoryEntry> continueWatching;
  final List<Channel> liveChannels;
  final List<Favorite> favorites;
  final List<Movie> featuredMovies;
  final List<Series> popularSeries;
  final List<Channel> sportsChannels;
  final List<Channel> newsChannels;
  final bool isLoading;

  /// True while we still might replace the hero with live matches.
  final bool isHeroPending;
  final String? error;

  HomeState copyWith({
    HomeHeroItem? heroItem,
    List<HomeHeroItem>? heroItems,
    List<WatchHistoryEntry>? continueWatching,
    List<Channel>? liveChannels,
    List<Favorite>? favorites,
    List<Movie>? featuredMovies,
    List<Series>? popularSeries,
    List<Channel>? sportsChannels,
    List<Channel>? newsChannels,
    bool? isLoading,
    bool? isHeroPending,
    String? error,
    bool clearError = false,
  }) {
    return HomeState(
      heroItem: heroItem ?? this.heroItem,
      heroItems: heroItems ?? this.heroItems,
      continueWatching: continueWatching ?? this.continueWatching,
      liveChannels: liveChannels ?? this.liveChannels,
      favorites: favorites ?? this.favorites,
      featuredMovies: featuredMovies ?? this.featuredMovies,
      popularSeries: popularSeries ?? this.popularSeries,
      sportsChannels: sportsChannels ?? this.sportsChannels,
      newsChannels: newsChannels ?? this.newsChannels,
      isLoading: isLoading ?? this.isLoading,
      isHeroPending: isHeroPending ?? this.isHeroPending,
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
    LiveScoreSource? liveScores,
    KidsAllowedContent allowedContent = const KidsAllowedContent.unrestricted(),
  }) : _liveRepo = liveRepo,
       _vodRepo = vodRepo,
       _seriesRepo = seriesRepo,
       _favoritesRepo = favoritesRepo,
       _historyRepo = historyRepo,
       _liveScores = liveScores,
       _allowedContent = allowedContent,
       // Start loading so Home shows skeleton instead of an empty flash
       // before the first loadData() frame runs.
       super(const HomeState(isLoading: true, isHeroPending: true)) {
    loadData();
  }

  final LiveRepository? _liveRepo;
  final VodRepository? _vodRepo;
  final SeriesRepository? _seriesRepo;
  final FavoritesRepository _favoritesRepo;
  final HistoryRepository _historyRepo;
  final LiveScoreSource? _liveScores;
  final KidsAllowedContent _allowedContent;

  bool _isFetching = false;
  bool _matchHeroResolved = false;
  List<Movie>? _pendingHeroMovies;

  Future<void> loadData({bool forceRefresh = false}) async {
    final liveRepo = _liveRepo;
    if (liveRepo == null) {
      // Session / kids-mode gate is not ready yet. Stay in loading so Home
      // keeps the skeleton instead of flashing "No media content found".
      if (mounted && !state.isLoading) {
        state = state.copyWith(
          isLoading: true,
          isHeroPending: true,
          clearError: true,
        );
      }
      return;
    }
    if (_isFetching && !forceRefresh) return;
    _isFetching = true;
    _matchHeroResolved = false;
    _pendingHeroMovies = null;

    state = state.copyWith(
      isLoading: true,
      isHeroPending: true,
      clearError: true,
    );

    try {
      // 1. Instant local DB data (History & Favorites) — resolves in < 5ms
      final localResults = await Future.wait([
        _historyRepo.getHistory(limit: 20),
        _favoritesRepo.getFavorites(),
      ]);

      final historyRes = localResults[0] as Result<List<WatchHistoryEntry>>?;
      final history =
          historyRes?.when(ok: (h) => h, err: (_) => <WatchHistoryEntry>[]) ??
          <WatchHistoryEntry>[];
      final activeContinueWatching = history
          .where(_allowedContent.allowsHistory)
          .where(
            (h) =>
                h.type != WatchHistoryType.channel &&
                !h.isFinished &&
                h.positionSecs >= 5,
          )
          .take(20)
          .toList();

      final favoritesRes = localResults[1] as Result<List<Favorite>>?;
      final favorites =
          favoritesRes?.when(ok: (f) => f, err: (_) => <Favorite>[]) ??
          <Favorite>[];
      final visibleFavorites = favorites
          .where(_allowedContent.allowsFavorite)
          .toList();

      // Immediately render local data if mounted
      if (!mounted) return;
      state = state.copyWith(
        continueWatching: activeContinueWatching,
        favorites: visibleFavorites,
      );

      // Kick off the scoreboard immediately so match hero does not wait on VOD
      // or sports/news rows. Movies still load in parallel; only the movie
      // hero is held until we know whether matches exist.
      final fixturesFuture = _fetchLiveFixtures(forceRefresh: forceRefresh);
      if (_liveScores == null) {
        _finishMatchHeroResolution();
      } else {
        unawaited(
          fixturesFuture.then((fixtures) {
            if (fixtures.isEmpty) _finishMatchHeroResolution();
          }),
        );
      }

      // 2. Launch catalog fetches in parallel, updating state progressively as each finishes.
      // Featured live uses take(20); sports/news use category-indexed slices
      // (no full-catalog name keyword scan on Home).
      final liveTask = () async {
        try {
          final channelsRes = await liveRepo.getChannels(
            forceRefresh: forceRefresh,
          );
          final channels = channelsRes.when(
            ok: (c) => c,
            err: (_) => <Channel>[],
          );
          unawaited(_bindMatchHero(channels, fixturesFuture));
          if (channels.isEmpty || !mounted) return;

          if (mounted) {
            state = state.copyWith(liveChannels: channels.take(20).toList());
          }

          final rowSlices = await _loadSportsAndNewsRows(
            forceRefresh: forceRefresh,
          );
          if (!mounted) return;

          state = state.copyWith(
            sportsChannels: rowSlices.sports,
            newsChannels: rowSlices.news,
          );
        } catch (_) {
          unawaited(_bindMatchHero(const [], fixturesFuture));
        }
      }();

      final vodTask = (_vodRepo != null)
          ? _vodRepo
                .getMovies(forceRefresh: forceRefresh)
                .then((res) {
                  final movies = res.when(ok: (m) => m, err: (_) => <Movie>[]);
                  if (movies.isNotEmpty && mounted) {
                    state = state.copyWith(
                      featuredMovies: movies.take(20).toList(),
                    );
                    _maybeApplyMovieHero(movies);
                  }
                })
                .catchError((_) {})
          : Future<void>.value();

      final seriesTask = (_seriesRepo != null)
          ? _seriesRepo
                .getSeries(forceRefresh: forceRefresh)
                .then((res) {
                  final series = res.when(ok: (s) => s, err: (_) => <Series>[]);
                  if (series.isNotEmpty && mounted) {
                    state = state.copyWith(
                      popularSeries: series.take(20).toList(),
                    );
                  }
                })
                .catchError((_) {})
          : Future<void>.value();

      await Future.wait([liveTask, vodTask, seriesTask]);
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      _finishMatchHeroResolution();
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } finally {
      _isFetching = false;
    }
  }

  List<HomeHeroItem> _computeHeroItems(List<Movie> movies) {
    if (movies.isEmpty) return const [];

    final validMovies = movies.where((m) => m.name.isNotEmpty).toList();

    // Sort by top rating & latest release year to pick top 3
    validMovies.sort((a, b) {
      final ratingA = double.tryParse(a.rating ?? '') ?? 0.0;
      final ratingB = double.tryParse(b.rating ?? '') ?? 0.0;
      final yearA = a.releaseYear ?? 0;
      final yearB = b.releaseYear ?? 0;

      if ((ratingA - ratingB).abs() > 0.5) {
        return ratingB.compareTo(ratingA);
      }
      if (yearA != yearB) {
        return yearB.compareTo(yearA);
      }
      return ratingB.compareTo(ratingA);
    });

    final top3 = validMovies.take(3).toList();

    return top3.map((m) {
      final ratingStr = m.rating != null && m.rating!.isNotEmpty
          ? m.rating!
          : null;
      final yearStr = m.releaseYear != null ? '${m.releaseYear}' : null;
      final genreStr = m.genre ?? 'Action';

      final subtitleParts = <String>[];
      if (genreStr.isNotEmpty) subtitleParts.add(genreStr);
      if (yearStr != null) subtitleParts.add(yearStr);
      if (ratingStr != null) subtitleParts.add('★ $ratingStr');

      return HomeHeroItem(
        title: m.name,
        subtitle: subtitleParts.join(' • '),
        type: HeroItemType.movie,
        badge: ratingStr != null ? '★ $ratingStr' : (yearStr ?? 'HD'),
        rating: ratingStr,
        genre: genreStr,
        description:
            m.plot ??
            'Stream in ultra high definition on your favorite screen.',
        backdropUrl: m.streamIcon,
        posterUrl: m.streamIcon,
        movie: m,
      );
    }).toList();
  }

  bool get _hasLiveMatchHero =>
      state.heroItems.any((item) => item.type == HeroItemType.live);

  Future<List<LiveFixture>> _fetchLiveFixtures({
    required bool forceRefresh,
  }) async {
    final scores = _liveScores;
    if (scores == null) return const [];
    try {
      return await scores.fetchLiveBigMatches(forceRefresh: forceRefresh);
    } catch (e) {
      AppLogger.error('Live match hero failed', feature: 'sports', error: e);
      return const [];
    }
  }

  void _maybeApplyMovieHero(List<Movie> movies) {
    if (!mounted || _hasLiveMatchHero) return;
    if (!_matchHeroResolved) {
      _pendingHeroMovies = movies;
      return;
    }
    _pendingHeroMovies = null;
    final items = _computeHeroItems(movies);
    if (items.isEmpty || !mounted || _hasLiveMatchHero) return;
    state = state.copyWith(
      heroItem: items.first,
      heroItems: items,
      isHeroPending: false,
    );
  }

  void _finishMatchHeroResolution() {
    _matchHeroResolved = true;
    final pending = _pendingHeroMovies;
    _pendingHeroMovies = null;
    if (!mounted) return;
    if (_hasLiveMatchHero) {
      if (state.isHeroPending) {
        state = state.copyWith(isHeroPending: false);
      }
      return;
    }
    if (pending != null) {
      _maybeApplyMovieHero(pending);
      return;
    }
    if (state.isHeroPending) {
      state = state.copyWith(isHeroPending: false);
    }
  }

  void _applyMatchHero(List<LiveMatch> matches) {
    if (matches.isEmpty || !mounted) return;
    final items = _heroFromMatches(matches);
    if (items.isEmpty) return;
    state = state.copyWith(
      heroItem: items.first,
      heroItems: items,
      isHeroPending: false,
    );
  }

  List<HomeHeroItem> _heroFromMatches(List<LiveMatch> matches) {
    return matches.take(LiveMatchFinder.heroLimit).map((match) {
      final channelName = match.channel.name;
      final fixture = match.fixture;
      final isLive = fixture?.isLive == true;
      return HomeHeroItem(
        title: match.displayTitle,
        subtitle: [
          if (fixture?.clock != null) fixture!.clock!,
          match.teamsLabel,
        ].join(' • '),
        type: HeroItemType.live,
        badge: match.resolutionLabel,
        genre: isLive ? 'LIVE MATCH' : 'UPCOMING MATCH',
        description: 'Watch on $channelName',
        backdropUrl: fixture?.heroBackdropUrl ?? match.channel.streamIcon,
        posterUrl:
            fixture?.heroPosterUrl ??
            fixture?.heroBackdropUrl ??
            match.channel.streamIcon,
        channel: match.channel,
        match: match,
      );
    }).toList();
  }

  Future<void> _bindMatchHero(
    List<Channel> channels,
    Future<List<LiveFixture>> fixturesFuture,
  ) async {
    try {
      final fixtures = await fixturesFuture;
      if (!mounted) return;
      if (fixtures.isEmpty) {
        AppLogger.info(
          'No live big matches on the scoreboard',
          feature: 'sports',
        );
        _finishMatchHeroResolution();
        return;
      }
      if (channels.isEmpty) {
        _finishMatchHeroResolution();
        return;
      }

      // Bind immediately (channel names / broadcast / fallback) so the match
      // hero can paint without waiting on EPG probes.
      final matches = LiveMatchFinder.bindFixtures(
        fixtures: fixtures,
        channels: channels,
      );
      AppLogger.info(
        'Live match hero bind',
        feature: 'sports',
        data: {
          'fixtures': fixtures.map((f) => f.headline).toList(),
          'bound': matches.map((m) => m.channel.name).toList(),
        },
      );
      _applyMatchHero(matches);
      _finishMatchHeroResolution();
      unawaited(_refineMatchHeroWithEpg(channels, fixtures));
    } catch (e) {
      AppLogger.error('Live match hero failed', feature: 'sports', error: e);
      _finishMatchHeroResolution();
    }
  }

  Future<void> _refineMatchHeroWithEpg(
    List<Channel> channels,
    List<LiveFixture> fixtures,
  ) async {
    final liveRepo = _liveRepo;
    if (liveRepo == null || fixtures.isEmpty) return;

    try {
      final probe = LiveMatchFinder.epgProbeChannels(channels);
      final epgTitles = <int, String>{};
      for (var i = 0; i < probe.length; i += 4) {
        final chunk = probe.skip(i).take(4);
        final rows = await Future.wait(
          chunk.map((channel) async {
            final result = await liveRepo.getShortEpg(
              channel.streamId,
              limit: 2,
            );
            final programs = result.when(
              ok: (p) => p,
              err: (_) => const <EpgProgram>[],
            );
            if (programs.isEmpty) return null;
            return MapEntry(channel.streamId, programs.first.title);
          }),
        );
        for (final row in rows) {
          if (row != null) epgTitles[row.key] = row.value;
        }
      }
      if (!mounted || epgTitles.isEmpty) return;

      final matches = LiveMatchFinder.bindFixtures(
        fixtures: fixtures,
        channels: channels,
        epgTitles: epgTitles,
      );
      _applyMatchHero(matches);
    } catch (e) {
      AppLogger.error(
        'Live match hero EPG refine failed',
        feature: 'sports',
        error: e,
      );
    }
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
    if (n.contains('kid') ||
        n.contains('child') ||
        n.contains('junior') ||
        n.contains('cartoon') ||
        n.contains('اطفال') ||
        n.contains('أطفال') ||
        n.contains('كرتون')) {
      return false;
    }
    return n.contains('sport') ||
        n.contains('espn') ||
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
          .where(_allowedContent.allowsHistory)
          .where(
            (h) =>
                h.type != WatchHistoryType.channel &&
                !h.isFinished &&
                h.positionSecs >= 5,
          )
          .take(20)
          .toList();
      if (mounted) {
        state = state.copyWith(continueWatching: active);
      }
    } catch (_) {}
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    final liveRepo = ref.watch(liveRepositoryProvider);
    final vodRepo = ref.watch(vodRepositoryProvider);
    final seriesRepo = ref.watch(seriesRepositoryProvider);
    final favoritesRepo = ref.watch(favoritesRepositoryProvider);
    final historyRepo = ref.watch(historyRepositoryProvider);
    final allowedContent =
        ref.watch(kidsAllowedContentProvider).valueOrNull ??
        const KidsAllowedContent.denyAll();

    return HomeController(
      liveRepo: liveRepo,
      vodRepo: vodRepo,
      seriesRepo: seriesRepo,
      favoritesRepo: favoritesRepo,
      historyRepo: historyRepo,
      liveScores: ref.watch(liveScoreSourceProvider),
      allowedContent: allowedContent,
    );
  },
);
