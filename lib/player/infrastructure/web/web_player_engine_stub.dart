import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';

/// Stub implementation for non-web platforms.
bool isIosSafariWeb() => false;

/// Backwards-compatible alias for existing callers.
bool isIosOrSafariWeb() => false;

/// Stub factory for non-web platforms.
PlayerEngine createWebIosPlayerEngine({
  PlaybackBufferMode? initialBufferMode,
}) {
  throw UnsupportedError('WebIosPlayerEngine is only available on web platforms.');
}
