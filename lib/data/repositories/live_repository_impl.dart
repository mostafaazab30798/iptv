import 'dart:async';
import 'package:flutter/foundation.dart' show compute, visibleForTesting;
import 'package:iptv/core/cache/local_catalog_cache.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/cache/catalog_memory_cache.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

List<Channel> _parseChannelsIsolate(List<Map<String, dynamic>> raw) {
  return raw.map(DataMapper.channelFromJson).toList();
}

class LiveRepositoryImpl implements LiveRepository {
  LiveRepositoryImpl({
    required this.remoteDataSource,
    required this.cache,
  });

  final XtreamRemoteDataSource remoteDataSource;
  final CatalogMemoryCache cache;

  static const _ttl = Duration(minutes: 10);
  static const _epgTtl = Duration(minutes: 8);

  bool _isFresh(DateTime? fetchedAt, [Duration ttl = _ttl]) {
    if (fetchedAt == null) return false;
    return DateTime.now().difference(fetchedAt) < ttl;
  }

  void _rebuildCategoryIndex(List<Channel> channels) {
    cache.liveChannelsByCategoryIndex
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

  /// Test/debug helper: clear session catalog caches between suites.
  @visibleForTesting
  void debugResetCaches() => cache.clear();

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && cache.liveCategories != null && _isFresh(cache.liveCategoriesFetchedAt)) {
      return Ok(cache.liveCategories!);
    }

    // Disk cache check on cold start
    if (!forceRefresh && cache.liveCategories == null) {
      final diskCategories = await LocalCatalogCache.instance.loadCategories('live', CategoryType.live);
      if (diskCategories != null && diskCategories.isNotEmpty) {
        cache.liveCategories = diskCategories;
        cache.liveCategoriesFetchedAt = DateTime.now();
        // Background refresh if needed
        unawaited(remoteDataSource.getLiveCategories().then((raw) {
          if (raw.isNotEmpty) {
            final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.live)).toList();
            cache.liveCategories = categories;
            cache.liveCategoriesFetchedAt = DateTime.now();
            LocalCatalogCache.instance.saveCategories('live', raw);
          }
        }).catchError((_) {}));
        return Ok(diskCategories);
      }
    }

    try {
      final raw = await remoteDataSource.getLiveCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.live)).toList();
      cache.liveCategories = categories;
      cache.liveCategoriesFetchedAt = DateTime.now();
      if (raw.isNotEmpty) {
        unawaited(LocalCatalogCache.instance.saveCategories('live', raw));
      }
      return Ok(categories);
    } catch (e) {
      if (cache.liveCategories != null) {
        return Ok(cache.liveCategories!);
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
    if (categoryId == null && !forceRefresh && cache.liveChannels != null && _isFresh(cache.liveChannelsFetchedAt)) {
      return Ok(cache.liveChannels!);
    }

    // Fast path 2: Filtered request and full catalog is already cached in memory
    if (categoryId != null && !forceRefresh && cache.liveChannels != null && _isFresh(cache.liveChannelsFetchedAt)) {
      if (cache.liveChannelsByCategoryIndex.isEmpty) {
        _rebuildCategoryIndex(cache.liveChannels!);
      }
      return Ok(List<Channel>.unmodifiable(
        cache.liveChannelsByCategoryIndex[categoryId] ?? const <Channel>[],
      ));
    }

    // Fast path 3: Cold-start disk cache loading (< 15ms)
    if (!forceRefresh && cache.liveChannels == null) {
      final diskChannels = await LocalCatalogCache.instance.loadChannels();
      if (diskChannels != null && diskChannels.isNotEmpty) {
        cache.liveChannels = diskChannels;
        cache.liveChannelsFetchedAt = DateTime.now();
        cache.liveCategoryChannels.clear();
        _rebuildCategoryIndex(diskChannels);
        cache.liveChannelMap
          ..clear()
          ..addEntries(diskChannels.map((c) => MapEntry(c.streamId, c)));

        // Trigger silent background update
        unawaited(remoteDataSource.getLiveStreams().then((raw) async {
          if (raw.isNotEmpty) {
            final channels = raw.length > 250
                ? await compute(_parseChannelsIsolate, raw)
                : raw.map(DataMapper.channelFromJson).toList();
            cache.liveChannels = channels;
            cache.liveChannelsFetchedAt = DateTime.now();
            cache.liveCategoryChannels.clear();
            _rebuildCategoryIndex(channels);
            cache.liveChannelMap
              ..clear()
              ..addEntries(channels.map((c) => MapEntry(c.streamId, c)));
            unawaited(LocalCatalogCache.instance.saveChannels(raw));
          }
        }).catchError((_) {}));

        if (categoryId != null) {
          return Ok(List<Channel>.unmodifiable(
            cache.liveChannelsByCategoryIndex[categoryId] ?? const <Channel>[],
          ));
        }
        return Ok(diskChannels);
      }
    }

    // Fast path 4: Filtered request and specific category is cached
    if (categoryId != null && !forceRefresh && cache.liveCategoryChannels.containsKey(categoryId)) {
      return Ok(cache.liveCategoryChannels[categoryId]!);
    }

    try {
      final raw = await remoteDataSource.getLiveStreams(categoryId: categoryId);
      final channels = raw.length > 250
          ? await compute(_parseChannelsIsolate, raw)
          : raw.map(DataMapper.channelFromJson).toList();

      if (categoryId == null) {
        cache.liveChannels = channels;
        cache.liveChannelsFetchedAt = DateTime.now();
        cache.liveCategoryChannels.clear();
        _rebuildCategoryIndex(channels);
        cache.liveChannelMap
          ..clear()
          ..addEntries(channels.map((c) => MapEntry(c.streamId, c)));
        if (raw.isNotEmpty) {
          unawaited(LocalCatalogCache.instance.saveChannels(raw));
        }
      } else {
        cache.liveCategoryChannels[categoryId] = channels;
        for (final c in channels) {
          cache.liveChannelMap[c.streamId] = c;
        }
      }

      return Ok(channels);
    } catch (e) {
      if (categoryId == null && cache.liveChannels != null) {
        return Ok(cache.liveChannels!);
      }
      if (categoryId != null && cache.liveChannels != null) {
        if (cache.liveChannelsByCategoryIndex.isEmpty) {
          _rebuildCategoryIndex(cache.liveChannels!);
        }
        return Ok(List<Channel>.unmodifiable(
          cache.liveChannelsByCategoryIndex[categoryId] ?? const <Channel>[],
        ));
      }
      return Err(AppResultError('Failed to load channels', cause: e));
    }
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    // Fast path: use the already-fetched channel map — avoids a full-catalog network fetch.
    if (cache.liveChannelMap.containsKey(streamId)) {
      return Ok(cache.liveChannelMap[streamId]!);
    }

    // Check cached full channels list if map doesn't have it yet
    if (cache.liveChannels != null) {
      try {
        final channel = cache.liveChannels!.firstWhere((c) => c.streamId == streamId);
        cache.liveChannelMap[streamId] = channel;
        return Ok(channel);
      } catch (_) {}
    }

    // Slow path: fetch channels
    try {
      await getChannels();
      final channel = cache.liveChannelMap[streamId];
      if (channel != null) {
        return Ok(channel);
      }
      return const Err(AppResultError('Channel not found'));
    } catch (e) {
      return Err(AppResultError('Channel not found', cause: e));
    }
  }

  @override
  Future<Result<List<EpgProgram>>> getShortEpg(
    int streamId, {
    int limit = 4,
  }) async {
    final fetchedAt = cache.liveEpgFetchedAt[streamId];
    final cached = cache.liveEpg[streamId];
    if (cached != null && _isFresh(fetchedAt, _epgTtl)) {
      return Ok(cached);
    }

    try {
      final raw = await remoteDataSource.getShortEpg(streamId, limit: limit);
      final nowPlaying = <EpgProgram>[];
      final rest = <EpgProgram>[];
      for (final row in raw) {
        final program = DataMapper.epgFromListing(row, channelId: streamId);
        if (program == null) continue;
        if (DataMapper.listingIsNowPlaying(row) || program.isLive) {
          nowPlaying.add(program);
        } else {
          rest.add(program);
        }
      }
      final programs = [...nowPlaying, ...rest];
      cache.liveEpg[streamId] = programs;
      cache.liveEpgFetchedAt[streamId] = DateTime.now();
      return Ok(programs);
    } catch (e) {
      if (cached != null) return Ok(cached);
      return Err(AppResultError('Failed to load EPG', cause: e));
    }
  }
}
