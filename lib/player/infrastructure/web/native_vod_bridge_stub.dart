/// Non-web stub for the native VOD JS helper.
Future<bool> nativeVodPlay(
  Object videoElement,
  String url, {
  Duration startAt = Duration.zero,
}) async => false;

Future<void> nativeVodSeek(Object videoElement, Duration position) async {}

Future<void> nativeVodStop(Object videoElement) async {}
