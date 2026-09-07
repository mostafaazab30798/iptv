// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

JSObject? _hopeTvNativeVod() {
  final value = globalContext.getProperty('HopeTvNativeVod'.toJS);
  if (value == null || value.isUndefinedOrNull || !value.isA<JSObject>()) {
    return null;
  }
  return value as JSObject;
}

/// Calls `window.HopeTvNativeVod.play(video, url)`.
/// Returns `false` when the helper script is not loaded.
Future<bool> nativeVodPlay(
  Object videoElement,
  String url, {
  Duration startAt = Duration.zero,
}) async {
  final helper = _hopeTvNativeVod();
  if (helper == null) {
    return false;
  }

  final result = helper.callMethodVarArgs('play'.toJS, <JSAny?>[
    videoElement as JSAny,
    url.toJS,
    (startAt.inMilliseconds / 1000).toJS,
  ]);
  if (result != null && result.isA<JSPromise>()) {
    await (result as JSPromise).toDart;
  }
  return true;
}

/// Performs a seek through the compatibility helper. For a remuxed MKV/AVI,
/// the helper rebuilds the fragmented stream at the requested timestamp.
Future<void> nativeVodSeek(Object videoElement, Duration position) async {
  final helper = _hopeTvNativeVod();
  if (helper == null) return;

  final result = helper.callMethodVarArgs('seek'.toJS, <JSAny?>[
    videoElement as JSAny,
    (position.inMilliseconds / 1000).toJS,
  ]);
  if (result != null && result.isA<JSPromise>()) {
    await (result as JSPromise).toDart;
  }
}

/// Calls `window.HopeTvNativeVod.stop(video)`.
Future<void> nativeVodStop(Object videoElement) async {
  final helper = _hopeTvNativeVod();
  if (helper == null) {
    return;
  }

  final result = helper.callMethodVarArgs('stop'.toJS, <JSAny?>[
    videoElement as JSAny,
  ]);
  if (result != null && result.isA<JSPromise>()) {
    await (result as JSPromise).toDart;
  }
}
