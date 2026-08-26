import 'package:flutter/foundation.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/player/domain/entities/player_capabilities.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';

/// Evaluates and yields runtime player capabilities per platform and stream characteristics.
class PlayerCapabilityService {
  const PlayerCapabilityService._();

  static PlayerCapabilities getCapabilities({StreamType? streamType}) {
    if (kIsWeb) {
      return const PlayerCapabilities(
        playPause: true,
        seek: true,
        volume: true,
        fullscreen: true,
        audioTracks: false,
        subtitles: false,
        aspectRatio: true,
        pictureInPicture: false,
        liveSeek: false,
        retry: true,
        hardwareAcceleration: false,
      );
    }

    final isTv = PlatformService.instance.isAndroidTv;
    final isDesktop = PlatformService.instance.isWindows;

    return PlayerCapabilities(
      playPause: true,
      seek: true,
      volume: true,
      fullscreen: true,
      audioTracks: true,
      subtitles: true,
      aspectRatio: true,
      pictureInPicture: !isTv && !isDesktop,
      liveSeek: streamType == StreamType.hls,
      retry: true,
      hardwareAcceleration: true,
    );
  }
}
