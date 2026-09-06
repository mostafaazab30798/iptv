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
Future<bool> nativeVodPlay(Object videoElement, String url) async {
  final helper = _hopeTvNativeVod();
  if (helper == null) {
    return false;
  }

  final result = helper.callMethodVarArgs('play'.toJS, <JSAny?>[
    videoElement as JSAny,
    url.toJS,
  ]);
  if (result != null && result.isA<JSPromise>()) {
    await (result as JSPromise).toDart;
  }
  return true;
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
