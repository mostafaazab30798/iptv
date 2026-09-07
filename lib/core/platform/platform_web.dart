// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:iptv/core/platform/platform_service.dart';

bool _videoFullscreen = false;

bool get _isIosWeb {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') ||
      ua.contains('ipad') ||
      ua.contains('ipod') ||
      (ua.contains('macintosh') &&
          (html.window.navigator.maxTouchPoints ?? 0) > 1);
}

html.VideoElement? get _activeVideo {
  final videos = html.document.querySelectorAll('video');
  for (final element in videos.reversed) {
    if (element is html.VideoElement && element.src.isNotEmpty) return element;
  }
  return null;
}

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
      // iPhone fullscreen is most reliable through the media element. Invoke
      // it before any await so Safari still sees the originating button tap as
      // a user gesture.
      final video = _activeVideo;
      if (_isIosWeb && video != null) {
        video.on['webkitbeginfullscreen'].listen((_) {
          _videoFullscreen = true;
          PlatformService.instance.isFullScreenNotifier.value = true;
        });
        video.on['webkitendfullscreen'].listen((_) {
          _videoFullscreen = false;
          PlatformService.instance.isFullScreenNotifier.value = false;
        });
        video.enterFullscreen();
        _videoFullscreen = true;
        return;
      }

      final doc = html.document.documentElement;
      if (doc != null && html.document.fullscreenElement == null) {
        await doc.requestFullscreen();
      }
    } else {
      final video = _activeVideo;
      if (_videoFullscreen && video != null) {
        video.exitFullscreen();
        _videoFullscreen = false;
        return;
      }
      if (html.document.fullscreenElement != null) {
        html.document.exitFullscreen();
      }
    }
  } catch (_) {}
}

Future<bool> isPlatformFullScreen() async {
  try {
    return _videoFullscreen || html.document.fullscreenElement != null;
  } catch (_) {
    return false;
  }
}

Future<void> minimizePlatformWindow() async {}
Future<void> maximizePlatformWindow() async {}
Future<void> unmaximizePlatformWindow() async {}
Future<bool> isPlatformWindowMaximized() async => false;

void exitPlatformApp() {}
