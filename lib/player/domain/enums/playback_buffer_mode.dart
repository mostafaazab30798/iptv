import 'package:iptv/core/platform/device_memory.dart';

/// Playback buffer sizing preset determining latency vs re-buffering tradeoff.
enum PlaybackBufferMode {
  /// Compact mode: ~2–4s behind live, minimal RAM.
  /// Default on low-RAM phones (≤3 GiB).
  compact,

  /// Low Latency mode: ~3–5s behind live.
  /// Best for sports channels on stable/fast connections.
  lowLatency,

  /// Balanced mode: ~8–12s behind live.
  /// Default for typical Wi-Fi and mobile networks.
  balanced,

  /// Stability mode: ~20–30s behind live.
  /// Best for poor, variable, or high-jitter networks.
  stability;

  /// Demuxer read-ahead duration in seconds.
  int get demuxerReadaheadSecs {
    switch (this) {
      case PlaybackBufferMode.compact:
        return 3;
      case PlaybackBufferMode.lowLatency:
        return 6; // 6s — fast fill, resilient to single-segment network jitter
      case PlaybackBufferMode.balanced:
        return 5;
      case PlaybackBufferMode.stability:
        return 15;
    }
  }

  /// mpv cache duration in seconds.
  int get cacheSecs {
    switch (this) {
      case PlaybackBufferMode.compact:
        return 4;
      case PlaybackBufferMode.lowLatency:
        return 8; // 8s cache — keeps smooth when readahead fills
      case PlaybackBufferMode.balanced:
        return 10;
      case PlaybackBufferMode.stability:
        return 25;
    }
  }

  /// App-level buffer size in bytes for PlayerConfiguration.
  int get bufferSizeBytes {
    switch (this) {
      case PlaybackBufferMode.compact:
        return 6 * 1024 * 1024; // 6MB
      case PlaybackBufferMode.lowLatency:
        return 16 * 1024 * 1024; // 16MB
      case PlaybackBufferMode.balanced:
        return 32 * 1024 * 1024; // 32MB
      case PlaybackBufferMode.stability:
        return 64 * 1024 * 1024; // 64MB
    }
  }

  /// mpv demuxer-max-bytes property value.
  String get demuxerMaxBytes {
    switch (this) {
      case PlaybackBufferMode.compact:
        return '12MiB';
      case PlaybackBufferMode.lowLatency:
        return '32MiB';
      case PlaybackBufferMode.balanced:
        return '64MiB';
      case PlaybackBufferMode.stability:
        return '128MiB';
    }
  }

  /// mpv demuxer-max-back-bytes property value.
  String get demuxerMaxBackBytes {
    switch (this) {
      case PlaybackBufferMode.compact:
        return '4MiB';
      case PlaybackBufferMode.lowLatency:
        return '8MiB';
      case PlaybackBufferMode.balanced:
        return '16MiB';
      case PlaybackBufferMode.stability:
        return '32MiB';
    }
  }

  String get displayName {
    switch (this) {
      case PlaybackBufferMode.compact:
        return 'Compact (Low RAM)';
      case PlaybackBufferMode.lowLatency:
        return 'Low Latency (Sports)';
      case PlaybackBufferMode.balanced:
        return 'Balanced';
      case PlaybackBufferMode.stability:
        return 'Stability (High Buffer)';
    }
  }

  /// Compact on ≤3 GiB RAM devices; otherwise low-latency for live zap speed.
  static PlaybackBufferMode get deviceDefault =>
      DeviceMemory.isLowRamDevice
          ? PlaybackBufferMode.compact
          : PlaybackBufferMode.lowLatency;
}
