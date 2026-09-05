import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:iptv/app/app.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/device_memory.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/storage/database/app_database.dart';
import 'package:iptv/core/storage/preferences_storage.dart';

Future<void>? _postFrameInitialization;

/// Initializes plugin-backed services after Flutter has rendered its first frame.
Future<void> initializeAfterFirstFrame() {
  return _postFrameInitialization ??= _initializeAfterFirstFrame();
}

Future<void> _initializeAfterFirstFrame() async {
  await Future.wait<void>([
    PlatformService.instance.initialize(),
    PreferencesStorage.initialize(),
  ]);

  final platform = PlatformService.instance;
  AppLogger.info(
    'Platform: ${platform.platformType} lowRam=${DeviceMemory.isLowRamDevice}',
    feature: 'bootstrap',
  );

  if (platform.isAndroidTv) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } else if (platform.isAndroid) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  if (platform.isAndroid || platform.isAndroidTv) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } else if (platform.isWindows) {
    await platform.setFullScreen(true);
  }

  AppLogger.info('Post-frame initialization complete', feature: 'bootstrap');
}

/// Initializes the minimum synchronous services needed to render Flutter UI.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    AppLogger.warning('Unhandled platform error: $error', feature: 'app');
    return true; // Handled to prevent crash
  };
  MediaKit.ensureInitialized();

  // Android is a permanently immersive app: keep status/navigation bars hidden
  // at startup and restore immersive mode if the OS temporarily reveals them.
  final isAndroidHost =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (isAndroidHost) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
      if (!systemOverlaysAreVisible) return;
      // Android blocks UI-visibility changes briefly after the keyboard closes.
      await Future<void>.delayed(const Duration(seconds: 1));
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Cap decoded image RAM — desktop monitors display large 1080p artwork and have
  // ample RAM, while low-spec mobile/TV devices need tight constraints.
  final isDesktop = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);
  final lowRam = DeviceMemory.isLowRamDevice;
  final imageCache = PaintingBinding.instance.imageCache;
  if (isDesktop) {
    // 384 MB / 400 images prevents constantly evicting and re-decoding hero/row artwork
    // during fast scrolling on PC.
    imageCache.maximumSizeBytes = 384 * 1024 * 1024;
    imageCache.maximumSize = 400;
  } else {
    imageCache.maximumSizeBytes = lowRam ? 32 * 1024 * 1024 : 48 * 1024 * 1024;
    imageCache.maximumSize = lowRam ? 80 : 120;
  }

  // Logging first — so everything below can log.
  AppLogger.initialize(verbose: kDebugMode);
  AppLogger.info('Bootstrap starting', feature: 'bootstrap');

  // Initialize preferences so providers and secure storage can safely access them immediately.
  await PreferencesStorage.initialize();

  // Open database — isolated so crash is caught before UI renders.
  final db = AppDatabase();
  AppLogger.info('Database opened', feature: 'bootstrap');

  AppLogger.info('Launching Flutter UI', feature: 'bootstrap');

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
