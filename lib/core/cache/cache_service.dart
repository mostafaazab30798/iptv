import 'package:iptv/core/cache/local_catalog_cache.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/storage/database/app_database.dart';

/// Central cache coordinator for metadata and images.
class CacheService {
  const CacheService(this._db);

  final AppDatabase _db;

  Future<void> clearAll() async {
    AppLogger.info('Clearing all caches', feature: 'cache');
    await LocalCatalogCache.instance.clearAll();
    await _db.delete(_db.channels).go();
    await _db.delete(_db.categories).go();
    await _db.delete(_db.epgPrograms).go();
    await _db.delete(_db.movies).go();
    await _db.delete(_db.seriesTable).go();
    await _db.delete(_db.seasons).go();
    await _db.delete(_db.episodes).go();
  }

  Future<void> clearMetadata() async {
    AppLogger.info('Clearing metadata cache', feature: 'cache');
    await LocalCatalogCache.instance.clearAll();
    await _db.delete(_db.channels).go();
    await _db.delete(_db.categories).go();
    await _db.delete(_db.movies).go();
    await _db.delete(_db.seriesTable).go();
  }
}
