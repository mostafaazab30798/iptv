import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_backend.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:iptv/player/infrastructure/android_alternative_player_engine.dart';
import 'package:iptv/player/infrastructure/media_kit_player_engine.dart';
import 'package:iptv/player/infrastructure/web/web_player_engine.dart';

/// Central factory for instantiating the appropriate [PlayerEngine]
/// depending on platform and browser capabilities.
PlayerEngine createDefaultPlayerEngine({
  PlaybackBufferMode? initialBufferMode,
  PlayerBackend backend = PlayerBackend.mediaKit,
}) {
  // iOS/iPadOS Safari uses the native HTML video/AVPlayer pipeline.
  // Other browsers and non-web platforms continue to use MediaKit.
  if (kIsWeb && isIosSafariWeb()) {
    return createWebIosPlayerEngine(initialBufferMode: initialBufferMode);
  }

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      backend != PlayerBackend.mediaKit) {
    return AndroidAlternativePlayerEngine(backend);
  }

  return MediaKitPlayerEngine(
    initialBufferMode: initialBufferMode ?? PlaybackBufferMode.deviceDefault,
  );
}
