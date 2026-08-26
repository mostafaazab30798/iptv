import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/storage/database/app_database.dart';
import 'package:iptv/data/repositories/history_repository_impl.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/history_repository.dart';

void main() {
  late AppDatabase db;
  late HistoryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HistoryRepositoryImpl(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('HistoryRepository - 20 Item FIFO Limit', () {
    test('records up to 20 items successfully', () async {
      for (int i = 1; i <= 20; i++) {
        final entry = WatchHistoryEntry(
          id: 0,
          type: WatchHistoryType.movie,
          itemId: i,
          name: 'Movie $i',
          positionSecs: 100 * i,
          durationSecs: 7200,
          watchedAt: DateTime(2026, 1, 1, 0, i),
        );
        final res = await repo.recordWatch(entry);
        expect(res.isOk, isTrue);
      }

      final historyRes = await repo.getHistory(limit: 50);
      expect(historyRes.isOk, isTrue);
      final list = historyRes.value;
      expect(list.length, 20);
      // Newest watched first
      expect(list.first.itemId, 20);
      expect(list.last.itemId, 1);
    });

    test('item 21 replaces the first-in (oldest) item preserving 20 item limit', () async {
      // Record items 1 to 20
      for (int i = 1; i <= 20; i++) {
        final entry = WatchHistoryEntry(
          id: 0,
          type: WatchHistoryType.movie,
          itemId: i,
          name: 'Movie $i',
          positionSecs: 100,
          durationSecs: 7200,
          watchedAt: DateTime(2026, 1, 1, 0, i),
        );
        await repo.recordWatch(entry);
      }

      var historyRes = await repo.getHistory(limit: 50);
      var list = historyRes.value;
      expect(list.length, 20);
      expect(list.any((e) => e.itemId == 1), isTrue);

      // Now insert item 21
      final entry21 = WatchHistoryEntry(
        id: 0,
        type: WatchHistoryType.movie,
        itemId: 21,
        name: 'Movie 21',
        positionSecs: 50,
        durationSecs: 7200,
        watchedAt: DateTime(2026, 1, 1, 0, 21),
      );
      final res21 = await repo.recordWatch(entry21);
      expect(res21.isOk, isTrue);

      // Verify list still has exactly 20 items
      historyRes = await repo.getHistory(limit: 50);
      list = historyRes.value;
      expect(list.length, 20);

      // Item 21 is present at the front
      expect(list.first.itemId, 21);
      // Item 1 (oldest / first in) has been evicted
      expect(list.any((e) => e.itemId == 1), isFalse);
      // Item 2 is now the oldest
      expect(list.last.itemId, 2);

      // Now insert item 22
      final entry22 = WatchHistoryEntry(
        id: 0,
        type: WatchHistoryType.episode,
        itemId: 22,
        name: 'Episode 22',
        positionSecs: 60,
        durationSecs: 3600,
        watchedAt: DateTime(2026, 1, 1, 0, 22),
      );
      await repo.recordWatch(entry22);

      historyRes = await repo.getHistory(limit: 50);
      list = historyRes.value;
      expect(list.length, 20);
      expect(list.first.itemId, 22);
      // Item 2 is now evicted
      expect(list.any((e) => e.itemId == 2), isFalse);
      // Item 3 is now the oldest
      expect(list.last.itemId, 3);
    });

    test('re-watching an existing item updates its recency and avoids premature eviction', () async {
      // Record items 1 to 20
      for (int i = 1; i <= 20; i++) {
        final entry = WatchHistoryEntry(
          id: 0,
          type: WatchHistoryType.movie,
          itemId: i,
          name: 'Movie $i',
          positionSecs: 100,
          durationSecs: 7200,
          watchedAt: DateTime(2026, 1, 1, 0, i),
        );
        await repo.recordWatch(entry);
      }

      // Re-watch item 1 (originally the oldest) with newest timestamp
      final updatedEntry1 = WatchHistoryEntry(
        id: 0,
        type: WatchHistoryType.movie,
        itemId: 1,
        name: 'Movie 1 Updated',
        positionSecs: 500,
        durationSecs: 7200,
        watchedAt: DateTime(2026, 1, 1, 0, 25),
      );
      await repo.recordWatch(updatedEntry1);

      // Count is still 20
      var list = (await repo.getHistory()).value;
      expect(list.length, 20);
      expect(list.first.itemId, 1);
      // Item 2 is now the oldest
      expect(list.last.itemId, 2);

      // Now add item 21
      final entry21 = WatchHistoryEntry(
        id: 0,
        type: WatchHistoryType.movie,
        itemId: 21,
        name: 'Movie 21',
        positionSecs: 50,
        durationSecs: 7200,
        watchedAt: DateTime(2026, 1, 1, 0, 26),
      );
      await repo.recordWatch(entry21);

      list = (await repo.getHistory()).value;
      expect(list.length, 20);
      // Item 2 was evicted instead of item 1
      expect(list.any((e) => e.itemId == 2), isFalse);
      expect(list.any((e) => e.itemId == 1), isTrue);
    });

    test('updatePosition maintains 20 item limit', () async {
      for (int i = 1; i <= 20; i++) {
        await repo.recordWatch(WatchHistoryEntry(
          id: 0,
          type: WatchHistoryType.movie,
          itemId: i,
          name: 'Movie $i',
          watchedAt: DateTime(2026, 1, 1, 0, i),
        ));
      }

      // Update position of item 5
      await repo.updatePosition(
        type: WatchHistoryType.movie,
        itemId: 5,
        positionSecs: 1200,
        durationSecs: 7200,
      );

      final list = (await repo.getHistory()).value;
      expect(list.length, 20);
      expect(list.first.itemId, 5);
    });
  });
}
