import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:iptv/player/infrastructure/media_kit_player_engine.dart';
import 'package:iptv/player/infrastructure/web/web_player_engine.dart';

/// Central factory for instantiating the appropriate [PlayerEngine]
/// depending on platform and browser capabilities.
PlayerEngine createDefaultPlayerEngine({
  PlaybackBufferMode? initialBufferMode,
}) {
  // On Web: If running on iOS (iPhone/iPad) or Safari, utilize native hardware AVPlayer.
  // Other browsers (Chrome, Firefox, Edge) and non-web platforms use MediaKit.
  if (kIsWeb && isIosOrSafariWeb()) {
    return createWebIosPlayerEngine(
      initialBufferMode: initialBufferMode,
    );
  }

  return MediaKitPlayerEngine(
    initialBufferMode: initialBufferMode ?? PlaybackBufferMode.deviceDefault,
  );
}
