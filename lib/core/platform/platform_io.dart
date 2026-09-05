import 'dart:io' show Platform, exit;

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

bool isWindows() => Platform.isWindows;
bool isAndroid() => Platform.isAndroid;

const _platformChannel = MethodChannel('com.hopetv.iptvplayer/platform');

/// True when the host is an Android TV / Fire TV / Leanback device.
Future<bool> isTelevision() async {
  if (!Platform.isAndroid) return false;
  try {
    final result = await _platformChannel.invokeMethod<bool>('isTelevision');
    return result ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> initPlatformWindow() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
    } catch (_) {}
  }
}

Future<void> setPlatformFullScreen(bool isFullScreen) async {
  if (Platform.isWindows) {
    try {
      await _platformChannel.invokeMethod<void>('setFullScreen', {
        'isFullScreen': isFullScreen,
      });
      return;
    } catch (_) {
      // Fall through to windowManager fallback if platform channel fails
    }
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setFullScreen(isFullScreen);
    } catch (_) {}
  } else if (Platform.isAndroid) {
    // Fullscreen is the app-wide Android policy, including after leaving the
    // video player. Never restore the battery/Wi-Fi status bar here.
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}
  } else if (Platform.isIOS) {
    try {
      if (isFullScreen) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (_) {}
  }
}

Future<bool> isPlatformFullScreen() async {
  if (Platform.isWindows) {
    try {
      final res = await _platformChannel.invokeMethod<bool>('isFullScreen');
      if (res != null) return res;
    } catch (_) {}
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      return await windowManager.isFullScreen();
    } catch (_) {
      return false;
    }
  }
  return false;
}

Future<void> minimizePlatformWindow() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.minimize();
    } catch (_) {}
  }
}

void exitPlatformApp() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    exit(0);
  } else {
    SystemNavigator.pop();
  }
}
