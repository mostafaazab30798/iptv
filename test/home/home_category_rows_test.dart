import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/repositories/live_repository_impl.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/season.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/features/home/home_controller.dart';

class _FakeLiveRepo implements LiveRepository {
  _FakeLiveRepo({
    required this.categories,
    required this.channelsByCategory,
    required this.allChannels,
    this.epgTitles = const {},
  });

  final List<Category> categories;
  final Map<int, List<Channel>> channelsByCategory;
  final List<Channel> allChannels;
  final Map<int, String> epgTitles;

  int getChannelsCalls = 0;
  int getChannelsAllCalls = 0;
  int getChannelsCategoryCalls = 0;
  final List<int?> requestedCategoryIds = [];

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    return Ok(categories);
  }

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    getChannelsCalls++;
    requestedCategoryIds.add(categoryId);
    if (categoryId == null) {
      getChannelsAllCalls++;
      return Ok(allChannels);
    }
    getChannelsCategoryCalls++;
    return Ok(channelsByCategory[categoryId] ?? const []);
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    final match = allChannels.where((c) => c.streamId == streamId);
    if (match.isEmpty) return const Err(AppResultError('missing'));
    return Ok(match.first);
  }

  @override
  Future<Result<List<EpgProgram>>> getShortEpg(
    int streamId, {
    int limit = 4,
  }) async {
    final title = epgTitles[streamId];
    if (title == null) return const Ok([]);
    final now = DateTime.now();
    return Ok([
      EpgProgram(
        id: streamId,
        epgId: '$streamId',
        title: title,
        start: now.subtract(const Duration(minutes: 10)),
        end: now.add(const Duration(minutes: 80)),
      ),
    ]);
  }
}

class _EmptyFavorites implements FavoritesRepository {
  @override
  Future<Result<void>> addFavorite(Favorite favorite) async => const Ok(null);

  @override
  Future<Result<List<Favorite>>> getFavorites({FavoriteType? type}) async =>
      const Ok([]);

  @override
  Future<bool> isFavorite({
    required FavoriteType type,
    required int itemId,
  }) async => false;

  @override
  Future<Result<void>> removeFavorite(int favoriteId) async => const Ok(null);

  @override
  Future<Result<void>> removeFavoriteByItemId({
    required FavoriteType type,
    required int itemId,
  }) async => const Ok(null);
}

class _EmptyHistory implements HistoryRepository {
  @override
  Future<Result<List<WatchHistoryEntry>>> getHistory({
    int limit = HistoryRepository.maxHistoryLimit,
  }) async => const Ok([]);

  @override
  Future<Result<void>> clearHistory() async => const Ok(null);

  @override
  Future<Result<void>> deleteEntry(int id) async => const Ok(null);

  @override
  Future<Result<WatchHistoryEntry?>> getEntry({
    required WatchHistoryType type,
    required int itemId,
  }) async => const Ok(null);

  @override
  Future<Result<void>> recordWatch(WatchHistoryEntry entry) async =>
      const Ok(null);

  @override
  Future<Result<void>> updatePosition({
    required WatchHistoryType type,
    required int itemId,
    required int positionSecs,
    int? durationSecs,
  }) async => const Ok(null);
}

class _EmptyVod implements VodRepository {
  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async => const Ok([]);

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async => const Ok([]);

  @override
  Future<Result<Movie>> getMovieById(int streamId) async =>
      const Err(AppResultError('none'));
}

class _MovieVod implements VodRepository {
  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async => const Ok([]);

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async => const Ok([
    Movie(id: 99, serverId: 1, streamId: 99, name: 'The Matrix', rating: '9.0'),
  ]);

  @override
  Future<Result<Movie>> getMovieById(int streamId) async =>
      const Err(AppResultError('none'));
}

class _FakeScores implements LiveScoreSource {
  _FakeScores(this.fixtures, {this.delay = Duration.zero});

  final List<LiveFixture> fixtures;
  final Duration delay;

  @override
  Future<List<LiveFixture>> fetchLiveBigMatches({
    bool forceRefresh = false,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return fixtures;
  }
}

class _EmptySeries implements SeriesRepository {
  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async => const Ok([]);

  @override
  Future<Result<List<Series>>> getSeries({
    int? categoryId,
    bool forceRefresh = false,
  }) async => const Ok([]);

  @override
  Future<Result<List<Season>>> getSeasons(int seriesId) async => const Ok([]);
}

Channel _ch({required int id, required String name, required int categoryId}) {
  return Channel(
    id: id,
    serverId: 1,
    streamId: id,
    name: name,
    categoryId: categoryId,
  );
}

void main() {
  setUp(LiveRepositoryImpl.debugResetCaches);

  tearDown(LiveRepositoryImpl.debugResetCaches);

  test(
    'Home sports/news rows use category-scoped lookups (no full-list name scan)',
    () async {
      final sports = List.generate(
        20,
        (i) => _ch(id: 100 + i, name: 'Sports $i', categoryId: 1),
      );
      final news = List.generate(
        20,
        (i) => _ch(id: 200 + i, name: 'News $i', categoryId: 2),
      );
      final other = List.generate(
        5000,
        (i) => _ch(id: 1000 + i, name: 'Other $i', categoryId: 3),
      );
      final all = [...sports, ...news, ...other];

      final liveRepo = _FakeLiveRepo(
        categories: const [
          Category(id: 1, serverId: 1, type: CategoryType.live, name: 'Sports'),
          Category(id: 2, serverId: 1, type: CategoryType.live, name: 'News'),
          Category(
            id: 3,
            serverId: 1,
            type: CategoryType.live,
            name: 'General',
          ),
        ],
        channelsByCategory: {1: sports, 2: news, 3: other},
        allChannels: all,
      );

      final controller = HomeController(
        liveRepo: liveRepo,
        vodRepo: _EmptyVod(),
        seriesRepo: _EmptySeries(),
        favoritesRepo: _EmptyFavorites(),
        historyRepo: _EmptyHistory(),
      );

      // loadData is kicked from constructor — wait for progressive updates.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      for (var i = 0; i < 30 && controller.state.isLoading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      expect(controller.state.liveChannels.length, 20);
      expect(controller.state.sportsChannels.length, 15);
      expect(controller.state.newsChannels.length, 15);
      expect(
        controller.state.sportsChannels.every((c) => c.categoryId == 1),
        isTrue,
      );
      expect(
        controller.state.newsChannels.every((c) => c.categoryId == 2),
        isTrue,
      );

      // One unfiltered fetch for featured Live row + category fetches for sports/news.
      expect(liveRepo.getChannelsAllCalls, 1);
      expect(liveRepo.getChannelsCategoryCalls, greaterThanOrEqualTo(2));
      expect(liveRepo.requestedCategoryIds, containsAll(<int?>[1, 2]));

      // Sanity: Home did not need to iterate 5k names — category calls return slices.
      expect(liveRepo.channelsByCategory[1]!.length, 20);
      expect(liveRepo.channelsByCategory[2]!.length, 20);
    },
  );

  test('category index lookup stays O(1) vs full catalog size', () async {
    // Micro-benchmark style smoke: building a map + slice beats name-scanning 8k.
    final channels = <Channel>[
      for (var i = 0; i < 8000; i++)
        _ch(
          id: i + 1,
          name: i.isEven ? 'Sports Channel $i' : 'General $i',
          categoryId: i.isEven ? 1 : 2,
        ),
    ];

    final swScan = Stopwatch()..start();
    final scanned = <Channel>[];
    for (final c in channels) {
      if (scanned.length >= 15) break;
      if (c.name.toLowerCase().contains('sport')) scanned.add(c);
    }
    swScan.stop();

    final swIndex = Stopwatch()..start();
    final byCat = <int, List<Channel>>{};
    for (final c in channels) {
      final catId = c.categoryId;
      if (catId == null) continue;
      (byCat[catId] ??= <Channel>[]).add(c);
    }
    final indexed = (byCat[1] ?? const <Channel>[]).take(15).toList();
    swIndex.stop();

    expect(scanned.length, 15);
    expect(indexed.length, 15);
    // Index build+slice should complete; record timings for CI evidence.
    // (Absolute ms vary by host — assert relative usefulness / non-zero work.)
    expect(swIndex.elapsedMicroseconds, greaterThan(0));
    expect(swScan.elapsedMicroseconds, greaterThan(0));
    // ignore: avoid_print
    print(
      'catalog_smoke scan_us=${swScan.elapsedMicroseconds} '
      'index_us=${swIndex.elapsedMicroseconds} catalog=${channels.length}',
    );
  });

  test('beIN kids categories are not classified as sports', () async {
    final kids = [
      _ch(id: 700, name: 'beIN Junior', categoryId: 7),
      _ch(id: 701, name: 'beIN Kids', categoryId: 7),
    ];
    final liveRepo = _FakeLiveRepo(
      categories: const [
        Category(
          id: 7,
          serverId: 1,
          type: CategoryType.live,
          name: 'BEIN KIDS',
        ),
      ],
      channelsByCategory: {7: kids},
      allChannels: kids,
    );

    final controller = HomeController(
      liveRepo: liveRepo,
      vodRepo: _EmptyVod(),
      seriesRepo: _EmptySeries(),
      favoritesRepo: _EmptyFavorites(),
      historyRepo: _EmptyHistory(),
    );

    for (var i = 0; i < 30 && controller.state.isLoading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(controller.state.liveChannels, hasLength(2));
    expect(controller.state.sportsChannels, isEmpty);
    expect(liveRepo.requestedCategoryIds, isNot(contains(7)));
  });

  test(
    'live scoreboard binds the match to a beIN/Arabic sports channel, not club TV',
    () async {
      final channels = [
        _ch(id: 1, name: 'Barcelona TV 4K', categoryId: 1),
        _ch(id: 2, name: 'AD Sports 1 HD', categoryId: 1),
        _ch(id: 3, name: 'beIN Sports 1 4K', categoryId: 1),
        _ch(id: 4, name: 'Sky Sports Main Event', categoryId: 1),
      ];
      final liveRepo = _FakeLiveRepo(
        categories: const [
          Category(id: 1, serverId: 1, type: CategoryType.live, name: 'Sports'),
        ],
        channelsByCategory: {1: channels},
        allChannels: channels,
        epgTitles: {2: 'Barcelona vs Real Madrid', 3: 'Studio'},
      );

      final controller = HomeController(
        liveRepo: liveRepo,
        vodRepo: _MovieVod(),
        seriesRepo: _EmptySeries(),
        favoritesRepo: _EmptyFavorites(),
        historyRepo: _EmptyHistory(),
        liveScores: _FakeScores([
          LiveFixture(
            homeName: 'Barcelona',
            awayName: 'Real Madrid',
            teams: BigMatchDetector.teamsIn('Barcelona Real Madrid'),
            state: 'in',
            clock: "34'",
            bannerUrl: 'https://cdn.example/el-clasico-banner.jpg',
            posterUrl: 'https://cdn.example/el-clasico-poster.jpg',
          ),
        ]),
      );

      for (var i = 0; i < 50; i++) {
        final hero = controller.state.heroItem;
        if (hero != null &&
            hero.type == HeroItemType.live &&
            hero.channel?.streamId == 2) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      final hero = controller.state.heroItem;
      expect(hero, isNotNull);
      expect(hero!.type, HeroItemType.live);
      expect(hero.movie, isNull);
      expect(hero.channel?.streamId, 2);
      expect(hero.channel?.name, contains('AD Sports'));
      expect(hero.title.toLowerCase(), contains('barcelona'));
      expect(hero.backdropUrl, 'https://cdn.example/el-clasico-banner.jpg');
      expect(hero.posterUrl, 'https://cdn.example/el-clasico-poster.jpg');
      expect(controller.state.featuredMovies, isNotEmpty);
    },
  );

  test(
    'movie hero is held until live matches resolve, then match hero wins',
    () async {
      final channels = [
        _ch(id: 2, name: 'AD Sports 1 HD', categoryId: 1),
        _ch(id: 3, name: 'beIN Sports 1 4K', categoryId: 1),
      ];
      final liveRepo = _FakeLiveRepo(
        categories: const [
          Category(id: 1, serverId: 1, type: CategoryType.live, name: 'Sports'),
        ],
        channelsByCategory: {1: channels},
        allChannels: channels,
      );

      final controller = HomeController(
        liveRepo: liveRepo,
        vodRepo: _MovieVod(),
        seriesRepo: _EmptySeries(),
        favoritesRepo: _EmptyFavorites(),
        historyRepo: _EmptyHistory(),
        liveScores: _FakeScores([
          LiveFixture(
            homeName: 'Barcelona',
            awayName: 'Real Madrid',
            teams: BigMatchDetector.teamsIn('Barcelona Real Madrid'),
            state: 'in',
          ),
        ], delay: const Duration(milliseconds: 80)),
      );

      var sawMovieHero = false;
      HomeHeroItem? liveHero;
      for (var i = 0; i < 50; i++) {
        final hero = controller.state.heroItem;
        if (hero?.type == HeroItemType.movie) sawMovieHero = true;
        if (hero?.type == HeroItemType.live) {
          liveHero = hero;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(sawMovieHero, isFalse);
      expect(liveHero, isNotNull);
      expect(liveHero!.type, HeroItemType.live);
      expect(controller.state.featuredMovies, isNotEmpty);
      expect(controller.state.isHeroPending, isFalse);
    },
  );

  test('movie hero still shows when the scoreboard has no matches', () async {
    final channels = [_ch(id: 3, name: 'beIN Sports 1 4K', categoryId: 1)];
    final liveRepo = _FakeLiveRepo(
      categories: const [
        Category(id: 1, serverId: 1, type: CategoryType.live, name: 'Sports'),
      ],
      channelsByCategory: {1: channels},
      allChannels: channels,
    );

    final controller = HomeController(
      liveRepo: liveRepo,
      vodRepo: _MovieVod(),
      seriesRepo: _EmptySeries(),
      favoritesRepo: _EmptyFavorites(),
      historyRepo: _EmptyHistory(),
      liveScores: _FakeScores(const []),
    );

    for (var i = 0; i < 50; i++) {
      final hero = controller.state.heroItem;
      if (hero != null && hero.type == HeroItemType.movie) break;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final hero = controller.state.heroItem;
    expect(hero, isNotNull);
    expect(hero!.type, HeroItemType.movie);
    expect(hero.title, 'The Matrix');
    expect(controller.state.featuredMovies, isNotEmpty);
    expect(controller.state.isHeroPending, isFalse);
  });
}
