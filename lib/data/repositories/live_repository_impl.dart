import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

class LiveRepositoryImpl implements LiveRepository {
  const LiveRepositoryImpl({required this.remoteDataSource});

  final XtreamRemoteDataSource remoteDataSource;

  // In-memory channel map populated after the first getChannels() call.
  // Avoids fetching the entire live-stream list (10k+ entries) just to look up one channel.
  static final Map<int, Channel> _channelMap = {};

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    try {
      final raw = await remoteDataSource.getLiveCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.live)).toList();
      return Ok(categories);
    } catch (e) {
      return Err(AppResultError('Failed to load live categories', cause: e));
    }
  }

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      final raw = await remoteDataSource.getLiveStreams(categoryId: categoryId);
      final channels = raw.map(DataMapper.channelFromJson).toList();

      // Populate the lookup map whenever we fetch without a category filter
      // (i.e. the full unfiltered list) so getChannelById can use it.
      if (categoryId == null) {
        _channelMap
          ..clear()
          ..addEntries(channels.map((c) => MapEntry(c.streamId, c)));
      }

      return Ok(channels);
    } catch (e) {
      return Err(AppResultError('Failed to load channels', cause: e));
    }
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    // Fast path: use the already-fetched channel map — avoids a full-catalog network fetch.
    if (_channelMap.containsKey(streamId)) {
      return Ok(_channelMap[streamId]!);
    }

    // Slow path: map is empty (e.g. cold start) — fetch the full list to populate it.
    try {
      final raw = await remoteDataSource.getLiveStreams();
      final channels = raw.map(DataMapper.channelFromJson).toList();
      _channelMap
        ..clear()
        ..addEntries(channels.map((c) => MapEntry(c.streamId, c)));

      final channel = _channelMap[streamId];
      if (channel == null) {
        return const Err(AppResultError('Channel not found'));
      }
      return Ok(channel);
    } catch (e) {
      return Err(AppResultError('Channel not found', cause: e));
    }
  }
}
