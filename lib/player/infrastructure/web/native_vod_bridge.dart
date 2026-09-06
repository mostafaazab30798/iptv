/// JS bridge to `window.HopeTvNativeVod` (web only).
library;

export 'native_vod_bridge_stub.dart'
    if (dart.library.html) 'native_vod_bridge_web.dart';
