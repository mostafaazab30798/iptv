import 'package:equatable/equatable.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';

/// Diagnostics and performance telemetry metrics for IPTV playback.
class PlayerMetrics extends Equatable {
  const PlayerMetrics({
    this.sourceResolveDuration,
    this.playerOpenDuration,
    this.firstFrameDuration,
    this.switchLatency,
    this.bufferingCount = 0,
    this.bufferingDuration = Duration.zero,
    this.playbackErrorCount = 0,
    this.retryCount = 0,
    this.videoWidth,
    this.videoHeight,
    this.videoBitrate,
    this.audioBitrate,
    this.videoCodec,
    this.audioCodec,
    this.hwdecCurrent,
    this.videoParams,
    this.fps,
    this.cacheDuration,
    this.cacheBufferingState,
    this.frameDropCount,
    this.decoderFrameDropCount,
    this.bufferMode = PlaybackBufferMode.balanced,
    this.swDecodeTier = SoftwareDecodeFallbackTier.none,
  });

  final Duration? sourceResolveDuration;
  final Duration? playerOpenDuration;
  final Duration? firstFrameDuration;
  final Duration? switchLatency;
  final int bufferingCount;
  final Duration bufferingDuration;
  final int playbackErrorCount;
  final int retryCount;
  final int? videoWidth;
  final int? videoHeight;
  final int? videoBitrate;
  final int? audioBitrate;
  final String? videoCodec;
  final String? audioCodec;
  final String? hwdecCurrent;
  final String? videoParams;
  final double? fps;
  final Duration? cacheDuration;
  final int? cacheBufferingState;
  final int? frameDropCount;
  final int? decoderFrameDropCount;
  final PlaybackBufferMode bufferMode;

  /// The active software decode escalation tier for this channel.
  final SoftwareDecodeFallbackTier swDecodeTier;

  static const empty = PlayerMetrics();

  /// Whether to show the persistent "software decode / hardware limit" badge in the player UI.
  /// True whenever hwdec has been observed to be inactive (confirmed 'no') and there is evidence
  /// from a prior telemetry poll — i.e. we actually know the answer, not just 'still probing'.
  bool get showSoftwareDecodeBadge {
    return hwdecCurrent != null && !isHardwareDecodingActive;
  }

  /// Instantaneous total frame drop count (VO + decoder) for threshold comparisons.
  int get totalFrameDrops => (frameDropCount ?? 0) + (decoderFrameDropCount ?? 0);

  /// Whether hardware decoding is actively engaged and accelerated.
  bool get isHardwareDecodingActive {
    if (hwdecCurrent == null) return false;
    final val = hwdecCurrent!.toLowerCase().trim();
    return val.isNotEmpty && val != 'no' && val != 'auto-safe' && val != 'disabled';
  }

  /// Whether frame drops indicate a CPU/GPU decoding bottleneck rather than network issues.
  bool get isDecodeBottleneck {
    final drops = (frameDropCount ?? 0) + (decoderFrameDropCount ?? 0);
    final cacheHealthy = (cacheBufferingState == null || cacheBufferingState! >= 70) &&
        (cacheDuration == null || cacheDuration!.inSeconds >= 2);
    return drops > 5 && cacheHealthy;
  }

  /// Whether playback drops/stalls indicate a network or server throughput bottleneck.
  bool get isNetworkBottleneck {
    return (cacheBufferingState != null && cacheBufferingState! < 30) ||
        (cacheDuration != null && cacheDuration!.inMilliseconds < 500 && bufferingCount > 0);
  }

  PlayerMetrics copyWith({
    Duration? sourceResolveDuration,
    Duration? playerOpenDuration,
    Duration? firstFrameDuration,
    Duration? switchLatency,
    int? bufferingCount,
    Duration? bufferingDuration,
    int? playbackErrorCount,
    int? retryCount,
    int? videoWidth,
    int? videoHeight,
    int? videoBitrate,
    int? audioBitrate,
    String? videoCodec,
    String? audioCodec,
    String? hwdecCurrent,
    String? videoParams,
    double? fps,
    Duration? cacheDuration,
    int? cacheBufferingState,
    int? frameDropCount,
    int? decoderFrameDropCount,
    PlaybackBufferMode? bufferMode,
    SoftwareDecodeFallbackTier? swDecodeTier,
  }) {
    return PlayerMetrics(
      sourceResolveDuration:
          sourceResolveDuration ?? this.sourceResolveDuration,
      playerOpenDuration: playerOpenDuration ?? this.playerOpenDuration,
      firstFrameDuration: firstFrameDuration ?? this.firstFrameDuration,
      switchLatency: switchLatency ?? this.switchLatency,
      bufferingCount: bufferingCount ?? this.bufferingCount,
      bufferingDuration: bufferingDuration ?? this.bufferingDuration,
      playbackErrorCount: playbackErrorCount ?? this.playbackErrorCount,
      retryCount: retryCount ?? this.retryCount,
      videoWidth: videoWidth ?? this.videoWidth,
      videoHeight: videoHeight ?? this.videoHeight,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      hwdecCurrent: hwdecCurrent ?? this.hwdecCurrent,
      videoParams: videoParams ?? this.videoParams,
      fps: fps ?? this.fps,
      cacheDuration: cacheDuration ?? this.cacheDuration,
      cacheBufferingState: cacheBufferingState ?? this.cacheBufferingState,
      frameDropCount: frameDropCount ?? this.frameDropCount,
      decoderFrameDropCount:
          decoderFrameDropCount ?? this.decoderFrameDropCount,
      bufferMode: bufferMode ?? this.bufferMode,
      swDecodeTier: swDecodeTier ?? this.swDecodeTier,
    );
  }

  @override
  List<Object?> get props => [
        sourceResolveDuration,
        playerOpenDuration,
        firstFrameDuration,
        switchLatency,
        bufferingCount,
        bufferingDuration,
        playbackErrorCount,
        retryCount,
        videoWidth,
        videoHeight,
        videoBitrate,
        audioBitrate,
        videoCodec,
        audioCodec,
        hwdecCurrent,
        videoParams,
        fps,
        cacheDuration,
        cacheBufferingState,
        frameDropCount,
        decoderFrameDropCount,
        bufferMode,
        swDecodeTier,
      ];
}

