// ignore_for_file: deprecated_member_use
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool isWindows() => false;
bool isAndroid() => false;

Future<bool> isTelevision() async => false;

Future<void> initPlatformWindow() async {
  // Web does not require desktop window manager initialization.
}

Future<void> setPlatformFullScreen(bool isFullScreen) async {
  try {
    if (isFullScreen) {
      await html.document.documentElement?.requestFullscreen();
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
