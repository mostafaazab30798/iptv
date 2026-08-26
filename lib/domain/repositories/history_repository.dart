import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/watch_history.dart';

abstract interface class HistoryRepository {
  static const int maxHistoryLimit = 20;

  Future<Result<List<WatchHistoryEntry>>> getHistory({int limit = maxHistoryLimit});
  Future<Result<WatchHistoryEntry?>> getEntry({
    required WatchHistoryType type,
    required int itemId,
  });
  Future<Result<void>> recordWatch(WatchHistoryEntry entry);
  Future<Result<void>> updatePosition({
    required WatchHistoryType type,
    required int itemId,
    required int positionSecs,
    int? durationSecs,
  });
  Future<Result<void>> deleteEntry(int id);
  Future<Result<void>> clearHistory();
}


