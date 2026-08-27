import 'dart:async';
import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:iptv/core/cache/local_catalog_cache.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

List<Channel> _parseChannelsIsolate(List<Map<String, dynamic>> raw) {
  return raw.map(DataMapper.channelFromJson).toList();
}

class LiveRepositoryImpl implements LiveRepository {
  const LiveRepositoryImpl({required this.remoteDataSource});

  final XtreamRemoteDataSource remoteDataSource;

  static const _ttl = Duration(minutes: 10);
  static List<Category>? _cachedCategories;
  static DateTime? _categoriesFetchedAt;

  static List<Channel>? _cachedAllChannels;
  static DateTime? _channelsFetchedAt;
  static final Map<int, List<Channel>> _cachedCategoryChannels = {};

  // In-memory channel map populated after the first getChannels() call.
  // Avoids fetching the entire live-stream list (10k+ entries) just to look up one channel.
  static final Map<int, Channel> _channelMap = {};

  /// Precomputed category → channels slices from the full catalog cache.
  /// Lets Home/Guide pull category rows without O(n) scans of all channels.
  static final Map<int, List<Channel>> _channelsByCategoryIndex = {};

  static bool _isFresh(DateTime? fetchedAt) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < _ttl;
  }

  static void _rebuildCategoryIndex(List<Channel> channels) {
    _channelsByCategoryIndex
      ..clear()
      ..addEntries(_groupChannelsByCategory(channels).entries);
  }

  static Map<int, List<Channel>> _groupChannelsByCategory(List<Channel> channels) {
    final map = <int, List<Channel>>{};
    for (final c in channels) {
      final catId = c.categoryId;
      if (catId == null) continue;
      (map[catId] ??= <Channel>[]).add(c);
    }
    return map;
  }

  /// Test/debug helper: clear static catalog caches between suites.
  @visibleForTesting
  static void debugResetCaches() {
    _cachedCategories = null;
    _categoriesFetchedAt = null;
    _cachedAllChannels = null;
    _channelsFetchedAt = null;
    _cachedCategoryChannels.clear();
    _channelMap.clear();
    _channelsByCategoryIndex.clear();
  }

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCategories != null && _isFresh(_categoriesFetchedAt)) {
      return Ok(_cachedCategories!);
    }

    // Disk cache check on cold start
    if (!forceRefresh && _cachedCategories == null) {
      final diskCategories = await LocalCatalogCache.instance.loadCategories('live', CategoryType.live);
      if (diskCategories != null && diskCategories.isNotEmpty) {
        _cachedCategories = diskCategories;
        _categoriesFetchedAt = DateTime.now();
        // Background refresh if needed
        unawaited(remoteDataSource.getLiveCategories().then((raw) {
          if (raw.isNotEmpty) {
            final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.live)).toList();
            _cachedCategories = categories;
            _categoriesFetchedAt = DateTime.now();
            LocalCatalogCache.instance.saveCategories('live', raw);
          }
        }).catchError((_) {}));
        return Ok(diskCategories);
      }
    }

    try {
      final raw = await remoteDataSource.getLiveCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.live)).toList();
      _cachedCategories = categories;
      _categoriesFetchedAt = DateTime.now();
      if (raw.isNotEmpty) {
        unawaited(LocalCatalogCache.instance.saveCategories('live', raw));
      }
      return Ok(categories);
    } catch (e) {
      if (_cachedCategories != null) {
        return Ok(_cachedCategories!);
      }
      return Err(AppResultError('Failed to load live categories', cause: e));
    }
  }

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    // Fast path 1: Unfiltered request and cached all channels is fresh in memory
    if (categoryId == null && !forceRefresh && _cachedAllChannels != null && _isFresh(_channelsFetchedAt)) {
      return Ok(_cachedAllChannels!);
    }

    // Fast path 2: Filtered request and full catalog is already cached in memory
    if (categoryId != null && !forceRefresh && _cachedAllChannels != null && _isFresh(_channelsFetchedAt)) {
      if (_channelsByCategoryIndex.isEmpty) {
        _rebuildCategoryIndex(_cachedAllChannels!);
      }
      return Ok(List<Channel>.unmodifiable(
        _channelsByCategoryIndex[categoryId] ?? const <Channel>[],
      ));
    }

    // Fast path 3: Cold-start disk cache loading (< 15ms)
    if (!forceRefresh && _cachedAllChannels == null) {
      final diskChannels = await LocalCatalogCache.instance.loadChannels();
      if (diskChannels != null && diskChannels.isNotEmpty) {
        _cachedAllChannels = diskChannels;
        _channelsFetchedAt = DateTime.now();
        _cachedCategoryChannels.clear();
        _rebuildCategoryIndex(diskChannels);
        _channelMap
          ..clear()
          ..addEntries(diskChannels.map((c) => MapEntry(c.streamId, c)));

        // Trigger silent background update
        unawaited(remoteDataSource.getLiveStreams().then((raw) async {
          if (raw.isNotEmpty) {
            final channels = raw.length > 250
                ? await compute(_parseChannelsIsolate, raw)
                : raw.map(DataMapper.channelFromJson).toList();
            _cachedAllChannels = channels;
            _channelsFetchedAt = DateTime.now();
            _cachedCategoryChannels.clear();
            _rebuildCategoryIndex(channels);
            _channelMap
              ..clear()
              ..addEntries(channels.map((c) => MapEntry(c.streamId, c)));
            unawaited(LocalCatalogCache.instance.saveChannels(raw));
          }
        }).catchError((_) {}));

        if (categoryId != null) {
          return Ok(List<Channel>.unmodifiable(
            _channelsByCategoryIndex[categoryId] ?? const <Channel>[],
          ));
        }
        return Ok(diskChannels);
      }
    }

    // Fast path 4: Filtered request and specific category is cached
    if (categoryId != null && !forceRefresh && _cachedCategoryChannels.containsKey(categoryId)) {
      return Ok(_cachedCategoryChannels[categoryId]!);
    }

    try {
      final raw = await remoteDataSource.getLiveStreams(categoryId: categoryId);
      final channels = raw.length > 250
          ? await compute(_parseChannelsIsolate, raw)
          : raw.map(DataMapper.channelFromJson).toList();

      if (categoryId == null) {
        _cachedAllChannels = channels;
        _channelsFetchedAt = DateTime.now();
        _cachedCategoryChannels.clear();
        _rebuildCategoryIndex(channels);
        _channelMap
          ..clear()
          ..addEntries(channels.map((c) => MapEntry(c.streamId, c)));
        if (raw.isNotEmpty) {
          unawaited(LocalCatalogCache.instance.saveChannels(raw));
        }
      } else {
        _cachedCategoryChannels[categoryId] = channels;
        for (final c in channels) {
          _channelMap[c.streamId] = c;
        }
      }

      return Ok(channels);
    } catch (e) {
      if (categoryId == null && _cachedAllChannels != null) {
        return Ok(_cachedAllChannels!);
      }
      if (categoryId != null && _cachedAllChannels != null) {
        if (_channelsByCategoryIndex.isEmpty) {
          _rebuildCategoryIndex(_cachedAllChannels!);
        }
        return Ok(List<Channel>.unmodifiable(
          _channelsByCategoryIndex[categoryId] ?? const <Channel>[],
        ));
      }
      return Err(AppResultError('Failed to load channels', cause: e));
    }
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    // Fast path: use the already-fetched channel map — avoids a full-catalog network fetch.
    if (_channelMap.containsKey(streamId)) {
      return Ok(_channelMap[streamId]!);
    }

    // Check cached full channels list if map doesn't have it yet
    if (_cachedAllChannels != null) {
      try {
        final channel = _cachedAllChannels!.firstWhere((c) => c.streamId == streamId);
        _channelMap[streamId] = channel;
        return Ok(channel);
      } catch (_) {}
    }

    // Slow path: fetch channels
    try {
      await getChannels();
      final channel = _channelMap[streamId];
      if (channel != null) {
        return Ok(channel);
      }
      return const Err(AppResultError('Channel not found'));
    } catch (e) {
      return Err(AppResultError('Channel not found', cause: e));
    }
  }
}
