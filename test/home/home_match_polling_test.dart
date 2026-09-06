import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/features/home/home_controller.dart';

class _FakeHistory implements HistoryRepository {
  @override
  Future<Result<List<WatchHistoryEntry>>> getHistory({int limit = 20}) async =>
      const Ok([]);
  @override
  Future<Result<void>> clearHistory() async => const Ok(null);
  @override
  Future<Result<void>> deleteEntry(int id) async => const Ok(null);
  @override
  Future<Result<WatchHistoryEntry?>> getEntry({
    required WatchHistoryType type,
    required int itemId,
  }) async =>
      const Ok(null);
  @override
  Future<Result<void>> recordWatch(WatchHistoryEntry entry) async =>
      const Ok(null);
  @override
  Future<Result<void>> updatePosition({
    required WatchHistoryType type,
    required int itemId,
    required int positionSecs,
    int? durationSecs,
  }) async =>
      const Ok(null);
}

class _FakeFavorites implements FavoritesRepository {
  @override
  Future<Result<List<Favorite>>> getFavorites({
    FavoriteType? type,
    int? limit,
    int? offset,
  }) async =>
      const Ok([]);
  @override
  Future<Result<void>> addFavorite(Favorite favorite) async => const Ok(null);
  @override
  Future<bool> isFavorite({
    required FavoriteType type,
    required int itemId,
  }) async =>
      false;
  @override
  Future<Result<void>> removeFavorite(int favoriteId) async => const Ok(null);
  @override
  Future<Result<void>> removeFavoriteByItemId({
    required FavoriteType type,
    required int itemId,
  }) async =>
      const Ok(null);
}

class _FakeLive implements LiveRepository {
  _FakeLive(this.channels);
  final List<Channel> channels;

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async =>
      Ok(channels);

  @override
  Future<Result<Channel>> getChannelById(int streamId) async =>
      Ok(channels.first);

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async =>
      const Ok([]);

  @override
  Future<Result<List<EpgProgram>>> getShortEpg(
    int streamId, {
    int limit = 4,
  }) async =>
      const Ok([]);

  Future<Result<List<EpgProgram>>> getEpg(int streamId) async => Ok(const []);

  Future<Result<List<Channel>>> searchChannels(String query) async =>
      Ok(const []);
}

class _CountingScores implements LiveScoreSource {
  _CountingScores(this.fixtures);
  final List<LiveFixture> fixtures;
  int fetchCount = 0;

  @override
  Future<List<LiveFixture>> fetchLiveBigMatches({
    bool forceRefresh = false,
  }) async {
    fetchCount++;
    return fixtures;
  }
}

void main() {
  test('HomeController does not poll scoreboard for matches scheduled > 10 minutes away', () async {
    const channels = [
      Channel(
        id: 1,
        serverId: 1,
        streamId: 101,
        name: 'beIN Sports 1 HD',
        categoryId: 1,
      ),
    ];

    // Upcoming match 5 hours away
    final futureFixture = LiveFixture(
      homeName: 'Real Madrid',
      awayName: 'Barcelona',
      teams: BigMatchDetector.teamsIn('Real Madrid Barcelona'),
      state: 'pre',
      scheduledTime: '23:59',
      broadcastChannel: 'beIN Sports 1 HD',
    );

    final scoreSource = _CountingScores([futureFixture]);

    final controller = HomeController(
      liveRepo: _FakeLive(channels),
      vodRepo: null,
      seriesRepo: null,
      favoritesRepo: _FakeFavorites(),
      historyRepo: _FakeHistory(),
      liveScores: scoreSource,
    );

    // Allow initial loadData to complete
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Initially fetched once to build Home
    expect(scoreSource.fetchCount, 1);
    expect(controller.state.heroItem?.type, HeroItemType.live);

    // Wait 100ms - no background timer firing because match is 5 hours away!
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(scoreSource.fetchCount, 1);

    controller.dispose();
  });
}
