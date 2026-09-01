import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

bool isWindows() => Platform.isWindows;
bool isAndroid() => Platform.isAndroid;

Future<void> initPlatformWindow() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();
    } catch (_) {}
  }
}

Future<void> setPlatformFullScreen(bool isFullScreen) async {
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
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      return await windowManager.isFullScreen();
    } catch (_) {
      return false;
    }
  }
  return false;
}
