import 'package:drift/drift.dart';
import 'package:iptv/core/storage/database/app_database.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl({required this.database});

  final AppDatabase database;
  static const int maxHistoryEntries = HistoryRepository.maxHistoryLimit;

  @override
  Future<Result<List<WatchHistoryEntry>>> getHistory({int limit = maxHistoryEntries}) async {
    try {
      final query = database.select(database.watchHistory)
        ..orderBy([(tbl) => OrderingTerm.desc(tbl.watchedAt), (tbl) => OrderingTerm.desc(tbl.id)])
        ..limit(limit);
      final rows = await query.get();
      final items = rows.map((r) {
        return WatchHistoryEntry(
          id: r.id,
          type: WatchHistoryType.values.firstWhere(
            (e) => e.name == r.type,
            orElse: () => WatchHistoryType.channel,
          ),
          itemId: r.itemId,
          name: r.name,
          imageUrl: r.imageUrl,
          positionSecs: r.positionSecs,
          durationSecs: r.durationSecs,
          watchedAt: r.watchedAt,
        );
      }).toList();
      return Ok(items);
    } catch (e) {
      return Err(AppResultError('Failed to load history', cause: e));
    }
  }

  @override
  Future<Result<WatchHistoryEntry?>> getEntry({
    required WatchHistoryType type,
    required int itemId,
  }) async {
    try {
      final query = database.select(database.watchHistory)
        ..where((tbl) => tbl.type.equals(type.name) & tbl.itemId.equals(itemId))
        ..limit(1);
      final row = await query.getSingleOrNull();
      if (row == null) return const Ok(null);

      return Ok(WatchHistoryEntry(
        id: row.id,
        type: type,
        itemId: row.itemId,
        name: row.name,
        imageUrl: row.imageUrl,
        positionSecs: row.positionSecs,
        durationSecs: row.durationSecs,
        watchedAt: row.watchedAt,
      ));
    } catch (e) {
      return Err(AppResultError('Failed to get history entry', cause: e));
    }
  }

  @override
  Future<Result<void>> recordWatch(WatchHistoryEntry entry) async {
    try {
      final existing = await (database.select(database.watchHistory)
            ..where((tbl) => tbl.type.equals(entry.type.name) & tbl.itemId.equals(entry.itemId))
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        await (database.update(database.watchHistory)..where((tbl) => tbl.id.equals(existing.id))).write(
          WatchHistoryCompanion(
            name: Value(entry.name),
            imageUrl: entry.imageUrl != null ? Value(entry.imageUrl) : const Value.absent(),
            positionSecs: entry.positionSecs > 0 ? Value(entry.positionSecs) : const Value.absent(),
            durationSecs: entry.durationSecs != null && entry.durationSecs! > 0
                ? Value(entry.durationSecs)
                : const Value.absent(),
            watchedAt: Value(entry.watchedAt),
          ),
        );
      } else {
        await database.into(database.watchHistory).insert(
          WatchHistoryCompanion.insert(
            type: entry.type.name,
            itemId: entry.itemId,
            name: entry.name,
            imageUrl: Value(entry.imageUrl),
            positionSecs: Value(entry.positionSecs),
            durationSecs: Value(entry.durationSecs),
            watchedAt: Value(entry.watchedAt),
          ),
        );
      }

      // Preserve the 20 item limit: prune the oldest (first in) entries
      await _pruneHistory(maxHistoryEntries);

      return const Ok(null);
    } catch (e) {
      return Err(AppResultError('Failed to record watch history', cause: e));
    }
  }

  @override
  Future<Result<void>> updatePosition({
    required WatchHistoryType type,
    required int itemId,
    required int positionSecs,
    int? durationSecs,
  }) async {
    try {
      final existing = await (database.select(database.watchHistory)
            ..where((tbl) => tbl.type.equals(type.name) & tbl.itemId.equals(itemId))
            ..limit(1))
          .getSingleOrNull();

      if (existing != null) {
        await (database.update(database.watchHistory)..where((tbl) => tbl.id.equals(existing.id))).write(
          WatchHistoryCompanion(
            positionSecs: Value(positionSecs),
            durationSecs: durationSecs != null && durationSecs > 0
                ? Value(durationSecs)
                : const Value.absent(),
            watchedAt: Value(DateTime.now()),
          ),
        );
        await _pruneHistory(maxHistoryEntries);
      }
      return const Ok(null);
    } catch (e) {
      return Err(AppResultError('Failed to update watch position', cause: e));
    }
  }

  /// Ensures that only the newest [maxLimit] items are kept in watch history.
  /// Any older items beyond [maxLimit] (the oldest / first in) are deleted.
  Future<void> _pruneHistory([int maxLimit = maxHistoryEntries]) async {
    try {
      final allRows = await (database.select(database.watchHistory)
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.watchedAt),
              (tbl) => OrderingTerm.desc(tbl.id),
            ]))
          .get();

      if (allRows.length > maxLimit) {
        final toDelete = allRows.sublist(maxLimit);
        final idsToDelete = toDelete.map((e) => e.id).toList();
        await (database.delete(database.watchHistory)..where((tbl) => tbl.id.isIn(idsToDelete))).go();
      }
    } catch (_) {
      // Best-effort pruning; ignore errors to avoid disrupting playback
    }
  }

  @override
  Future<Result<void>> deleteEntry(int id) async {
    try {
      await (database.delete(database.watchHistory)..where((tbl) => tbl.id.equals(id))).go();
      return const Ok(null);
    } catch (e) {
      return Err(AppResultError('Failed to delete history entry', cause: e));
    }
  }

  @override
  Future<Result<void>> clearHistory() async {
    try {
      await database.delete(database.watchHistory).go();
      return const Ok(null);
    } catch (e) {
      return Err(AppResultError('Failed to clear watch history', cause: e));
    }
  }
}


