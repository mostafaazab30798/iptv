import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:iptv/core/constants/app_constants.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverUrl => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  TextColumn get type => text()(); // live | vod | series
  TextColumn get name => text()();
  IntColumn get parentId => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  IntColumn get streamId => integer()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get streamIcon => text().nullable()();
  TextColumn get epgChannelId => text().nullable()();
  BoolColumn get tvArchive => boolean().withDefault(const Constant(false))();
  IntColumn get tvArchiveDuration => integer().nullable()();
  TextColumn get streamType => text().withDefault(const Constant('live'))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get epgId => text()();
  IntColumn get channelId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  TextColumn get lang => text().withDefault(const Constant('en'))();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class Movies extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  IntColumn get streamId => integer()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get streamIcon => text().nullable()();
  TextColumn get rating => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get plot => text().nullable()();
  TextColumn get cast => text().nullable()();
  TextColumn get director => text().nullable()();
  IntColumn get releaseDate => integer().nullable()(); // year
  IntColumn get durationSecs => integer().nullable()();
  TextColumn get containerExtension => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class SeriesTable extends Table {
  @override
  String get tableName => 'series';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer()();
  IntColumn get seriesId => integer()();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get cover => text().nullable()();
  TextColumn get plot => text().nullable()();
  TextColumn get cast => text().nullable()();
  TextColumn get director => text().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get rating => text().nullable()();
  IntColumn get releaseDate => integer().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class Seasons extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seriesLocalId => integer()();
  IntColumn get seasonNumber => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get cover => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seasonLocalId => integer()();
  IntColumn get episodeNum => integer()();
  TextColumn get title => text()();
  IntColumn get streamId => integer()();
  TextColumn get containerExtension => text().nullable()();
  IntColumn get durationSecs => integer().nullable()();
  TextColumn get plot => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();
}

class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // channel | movie | series
  IntColumn get itemId => integer()();
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

class WatchHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // channel | movie | episode
  IntColumn get itemId => integer()();
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get positionSecs => integer().withDefault(const Constant(0))();
  IntColumn get durationSecs => integer().nullable()();
  DateTimeColumn get watchedAt => dateTime().withDefault(currentDateAndTime)();
}

class AppSettings extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class SyncMetadata extends Table {
  TextColumn get entityType => text()();
  IntColumn get serverId => integer()();
  DateTimeColumn get lastSyncedAt => dateTime()();
  TextColumn get etag => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {entityType, serverId};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [
  Accounts,
  Categories,
  Channels,
  EpgPrograms,
  Movies,
  SeriesTable,
  Seasons,
  Episodes,
  Favorites,
  WatchHistory,
  AppSettings,
  SyncMetadata,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppConstants.dbVersion;


  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here.
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_stream_id ON channels(stream_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_channels_category_id ON channels(category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_channel_id ON epg_programs(channel_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_epg_start ON epg_programs(start)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_movies_category_id ON movies(category_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_watch_history_watched_at ON watch_history(watched_at DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_favorites_type ON favorites(type)',
    );
  }
}

DatabaseConnection _openConnection() {
  return DatabaseConnection(driftDatabase(name: AppConstants.dbName));
}
