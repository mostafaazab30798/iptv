import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:iptv/app/app.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/storage/database/app_database.dart';
import 'package:iptv/core/storage/preferences_storage.dart';

/// Bootstrap sequence:
/// 1. Initialize Flutter bindings
/// 2. Initialize MediaKit playback subsystem
/// 3. Initialize logging
/// 4. Initialize platform service
/// 5. Initialize preferences
/// 6. Open local database
/// 7. Support all device orientations (portrait + landscape)
/// 8. Launch app
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Logging first — so everything below can log.
  AppLogger.initialize(verbose: false);
  AppLogger.info('Bootstrap starting', feature: 'bootstrap');

  // Platform detection.
  await PlatformService.instance.initialize();
  AppLogger.info(
    'Platform: ${PlatformService.instance.platformType}',
    feature: 'bootstrap',
  );

  // Preferences — non-sensitive settings.
  await PreferencesStorage.initialize();

  // Support both portrait and landscape orientations on mobile and tablet devices.
  if (PlatformService.instance.isAndroid) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Immersive mode on TV/Android.
  if (PlatformService.instance.isAndroid || PlatformService.instance.isAndroidTv) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // Open database — isolated so crash is caught before UI renders.
  final db = AppDatabase();
  AppLogger.info('Database opened', feature: 'bootstrap');

  AppLogger.info('Bootstrap complete', feature: 'bootstrap');

  runApp(
    ProviderScope(
      overrides: [
        // Provide the database to the widget tree.
        _dbProvider.overrideWithValue(db),
      ],
      child: const App(),
    ),
  );
}

/// Global database provider — override in ProviderScope during bootstrap.
final _dbProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError('Database not initialized'),
);

/// Public accessor for database from Riverpod.
final appDatabaseProvider = _dbProvider;
