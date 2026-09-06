// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:iptv/core/platform/platform_service.dart';

bool isWindows() => false;
bool isAndroid() => false;

Future<bool> isTelevision() async => false;

Future<void> initPlatformWindow() async {
  html.document.onFullscreenChange.listen((_) {
    final isFull = html.document.fullscreenElement != null;
    PlatformService.instance.isFullScreenNotifier.value = isFull;
  });
}

Future<void> setPlatformFullScreen(bool isFullScreen) async {
  try {
    if (isFullScreen) {
      final doc = html.document.documentElement;
      if (doc != null && html.document.fullscreenElement == null) {
        await doc.requestFullscreen();
      }
    } else {
      if (html.document.fullscreenElement != null) {
        html.document.exitFullscreen();
      }
    }
  } catch (_) {}
}

Future<bool> isPlatformFullScreen() async {
  try {
    return html.document.fullscreenElement != null;
  } catch (_) {
    return false;
  }
}

Future<void> minimizePlatformWindow() async {}
Future<void> maximizePlatformWindow() async {}
Future<void> unmaximizePlatformWindow() async {}
Future<bool> isPlatformWindowMaximized() async => false;

void exitPlatformApp() {}
