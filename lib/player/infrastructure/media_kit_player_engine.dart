import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:iptv/player/utils/player_logger.dart';


/// Concrete [PlayerEngine] backed by `media_kit` and `media_kit_video`.
///
/// Provides hardware accelerated decoding on Android, Android TV, Windows, and Linux,
/// with low-latency and jitter-resilient libmpv tuning for live IPTV streams.
class MediaKitPlayerEngine implements PlayerEngine {
  MediaKitPlayerEngine({
    this.enableHardwareAcceleration = true,
    this.initialBufferMode = PlaybackBufferMode.balanced,
  }) : _bufferMode = initialBufferMode;

  final bool enableHardwareAcceleration;
  final PlaybackBufferMode initialBufferMode;

  mk.Player? _player;
  mkv.VideoController? _videoController;

  final _statusController = StreamController<PlayerStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _errorController = StreamController<PlayerErrorType>.broadcast();
  final _audioTracksController = StreamController<List<PlayerAudioTrack>>.broadcast();
  final _subtitleTracksController = StreamController<List<PlayerSubtitleTrack>>.broadcast();
  final _metricsController = StreamController<PlayerMetrics>.broadcast();

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _telemetryTimer;

  PlayerStatus _status = PlayerStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerSource? _currentSource;
  PlayerMetrics _metrics = PlayerMetrics.empty;
  DateTime? _openStartTime;
  bool _firstFrameReceived = false;
  PlaybackBufferMode _bufferMode;

  @override
  PlayerStatus get currentStatus => _status;

  @override
  Duration get currentPosition => _position;

  @override
  Duration get currentDuration => _duration;

  @override
  PlayerSource? get currentSource => _currentSource;

  @override
  dynamic get platformHandle => _videoController;

  PlaybackBufferMode get currentBufferMode => _bufferMode;

  @override
  Stream<PlayerStatus> get statusStream => _statusController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<Duration> get bufferStream => _bufferController.stream;

  @override
  Stream<PlayerErrorType> get errorStream => _errorController.stream;

  @override
  Stream<List<PlayerAudioTrack>> get audioTracksStream => _audioTracksController.stream;

  @override
  Stream<List<PlayerSubtitleTrack>> get subtitleTracksStream => _subtitleTracksController.stream;

  @override
  Stream<PlayerMetrics> get metricsStream => _metricsController.stream;

  @override
  Future<void> initialize() async {
    if (_player != null) return;

    _updateStatus(PlayerStatus.initializing);

    _player = mk.Player(
      configuration: mk.PlayerConfiguration(
        bufferSize: _bufferMode.bufferSizeBytes,
        logLevel: mk.MPVLogLevel.warn,
        // Disable libmpv's own ready/buffering events so we drive status ourselves.
        ready: null,
      ),
    );

    _videoController = mkv.VideoController(
      _player!,
      configuration: mkv.VideoControllerConfiguration(
        enableHardwareAcceleration: enableHardwareAcceleration,
      ),
    );

    // Apply low-level mpv optimizations for streaming and low-latency sports
    await _applyLowLevelMpvProperties();

    _setupListeners();
    _startTelemetryPolling();
    _updateStatus(PlayerStatus.idle);
  }

  /// Sets low-level mpv properties for fast zap, low latency, hw acceleration, and stability.
  Future<void> _applyLowLevelMpvProperties() async {
    // ── Caching: maintain a smooth pre-buffer to prevent starved playback ─────
    await _setProperty('cache', 'yes');
    await _setProperty('cache-pause', 'yes');
    await _setProperty('cache-pause-initial', 'yes');
    await _setProperty('cache-pause-wait', '1.0'); // 1s safety buffer for seamless 60fps playback

    // ── Video sync: audio clock master ────────────────────────────────────────
    // video-sync=audio syncs video frames to the audio clock without heavy GPU/CPU
    // interpolation shaders (display-resample), preventing severe stuttering on Windows/mobile.
    await _setProperty('video-sync', 'audio');
    await _setProperty('interpolation', 'no');

    // ── Frame drop policy: drop VO frames if decode/render falls behind ───────
    // framedrop=vo drops late frames to maintain real-time sync instead of getting stuck in lag.
    await _setProperty('framedrop', 'vo');
    await _setProperty('hr-seek-framedrop', 'yes');
    await _setProperty('correct-pts', 'yes');
    await _setProperty('fps', '0'); // Auto-detect stream fps

    // ── Deinterlacing ─────────────────────────────────────────────────────────
    await _setProperty('deinterlace', 'no');

    // ── Hardware decoding & multithreading ────────────────────────────────────
    if (enableHardwareAcceleration) {
      await _setProperty('hwdec', 'auto');
      await _setProperty('hwdec-codecs', 'all');
      await _setProperty('vd-lavc-fast', 'yes'); // Skip non-essential decode steps
    }
    await _setProperty('vd-lavc-threads', '0'); // Auto-detect CPU core count
    await _setProperty('demuxer-thread', 'yes'); // Demux on separate thread

    // ── Stream probing: fast startup ─────────────────────────────────────────
    await _setProperty('demuxer-lavf-o', 'fflags=+genpts+discardcorrupt');
    await _setProperty('demuxer-lavf-probesize', '1048576'); // 1MB probe
    await _setProperty('demuxer-lavf-analyzeduration', '0.5');
    await _setProperty('demuxer-lavf-buffersize', '1048576'); // 1MB network chunk buffer

    // ── Buffer sizing per active mode ─────────────────────────────────────────
    await _applyBufferModeProperties(_bufferMode);

    // ── Network: persistent connections, best quality ABR ────────────────────
    await _setProperty('network-timeout', '10'); // Fail fast on dead streams
    await _setProperty('http-header-fields', 'Connection: keep-alive');
    await _setProperty('tls-verify', 'no'); // Some IPTV providers use self-signed certs
    await _setProperty('hls-bitrate', 'max');
  }

  Future<void> _applyBufferModeProperties(PlaybackBufferMode mode) async {
    await _setProperty('demuxer-readahead-secs', mode.demuxerReadaheadSecs.toString());
    await _setProperty('cache-secs', mode.cacheSecs.toString());
    await _setProperty('demuxer-max-bytes', mode.demuxerMaxBytes);
    await _setProperty('demuxer-max-back-bytes', mode.demuxerMaxBackBytes);
  }

  Future<void> _setProperty(String name, String value) async {
    try {
      final platform = _player?.platform;
      if (platform != null) {
        await (platform as dynamic).setProperty(name, value);
      }
    } catch (_) {
      // Platform doesn't support direct setProperty (e.g. non-native or test mock)
    }
  }

  @override
  Future<void> setBufferMode(PlaybackBufferMode mode) async {
    _bufferMode = mode;
    await _applyBufferModeProperties(mode);
    _metrics = _metrics.copyWith(bufferMode: mode);
    if (!_metricsController.isClosed) {
      _metricsController.add(_metrics);
    }
  }

  @override
  Future<void> applySoftwareDecodeEscalation(SoftwareDecodeFallbackTier tier) async {
    switch (tier) {
      case SoftwareDecodeFallbackTier.none:
        // Restore libmpv defaults — hardware decode re-engaged or no longer needed.
        await _setProperty('vd-lavc-skiploopfilter', 'default');
        await _setProperty('vd-lavc-skipframe', 'default');
      case SoftwareDecodeFallbackTier.loopFilterSkip:
        // Tier 1: Skip loop filter on non-key frames only.
        // Frees ~15-20% CPU with almost no visible quality impact.
        await _setProperty('vd-lavc-skiploopfilter', 'nonkey');
        await _setProperty('vd-lavc-skipframe', 'default');
      case SoftwareDecodeFallbackTier.frameSkip:
        // Tier 2: Also skip non-reference B/P-frames under sustained high drop rate.
        // Maintains frame rate at cost of motion ghosting on fast-moving content.
        await _setProperty('vd-lavc-skiploopfilter', 'nonkey');
        await _setProperty('vd-lavc-skipframe', 'nonref');
    }
    PlayerLogger.note(
      '[hwdec-escalation] Applied SW decode tier: ${tier.displayName}',
    );
    _metrics = _metrics.copyWith(swDecodeTier: tier);
    if (!_metricsController.isClosed) {
      _metricsController.add(_metrics);
    }
  }

  void _setupListeners() {
    final player = _player;
    if (player == null) return;

    _subscriptions.add(
      player.stream.playing.listen((playing) {
        if (_status == PlayerStatus.disposed || _status == PlayerStatus.error) return;
        if (playing) {
          if (_status != PlayerStatus.buffering && _status != PlayerStatus.loading) {
            _updateStatus(PlayerStatus.playing);
          }
        } else if (_status == PlayerStatus.playing) {
          _updateStatus(PlayerStatus.paused);
        }
      }),
    );

    _subscriptions.add(
      player.stream.buffering.listen((buffering) {
        if (_status == PlayerStatus.disposed || _status == PlayerStatus.error) return;
        if (buffering) {
          PlayerLogger.bufferingStart();
          _metrics = _metrics.copyWith(bufferingCount: _metrics.bufferingCount + 1);
          _metricsController.add(_metrics);
          _updateStatus(PlayerStatus.buffering);
        } else if (_status == PlayerStatus.buffering) {
          PlayerLogger.bufferingEnd(Duration.zero);
          _updateStatus(player.state.playing ? PlayerStatus.playing : PlayerStatus.paused);
        }
      }),
    );

    _subscriptions.add(
      player.stream.position.listen((pos) {
        _position = pos;
        _positionController.add(pos);

        if (!_firstFrameReceived && pos > Duration.zero && _openStartTime != null) {
          _firstFrameReceived = true;
          final firstFrameLatency = DateTime.now().difference(_openStartTime!);
          PlayerLogger.firstFrame(firstFrameLatency);
          _metrics = _metrics.copyWith(firstFrameDuration: firstFrameLatency);
          _metricsController.add(_metrics);
          if (_status == PlayerStatus.loading || _status == PlayerStatus.buffering) {
            _updateStatus(PlayerStatus.playing);
          }
        }
      }),
    );

    _subscriptions.add(
      player.stream.duration.listen((dur) {
        _duration = dur;
        _durationController.add(dur);
      }),
    );

    _subscriptions.add(
      player.stream.buffer.listen(_bufferController.add),
    );

    _subscriptions.add(
      player.stream.completed.listen((completed) {
        if (completed) {
          _updateStatus(PlayerStatus.completed);
        }
      }),
    );

    _subscriptions.add(
      player.stream.error.listen((err) {
        if (err.isNotEmpty) {
          _handleBackendError(err);
        }
      }),
    );

    _subscriptions.add(
      player.stream.tracks.listen((tracks) {
        final audioList = tracks.audio.map((a) {
          return PlayerAudioTrack(
            id: a.id,
            title: a.title ?? a.language ?? 'Audio Track ${a.id}',
            language: a.language,
            bitrate: a.bitrate,
            channels: a.channels != null ? int.tryParse(a.channels.toString()) : null,
          );
        }).toList();
        _audioTracksController.add(audioList);

        final subtitleList = tracks.subtitle.map((s) {
          return PlayerSubtitleTrack(
            id: s.id,
            title: s.title ?? s.language ?? 'Subtitle ${s.id}',
            language: s.language,
          );
        }).toList();
        _subtitleTracksController.add(subtitleList);
      }),
    );

    _subscriptions.add(
      player.stream.width.listen((width) {
        if (width != null && width > 0) {
          _metrics = _metrics.copyWith(videoWidth: width);
          _metricsController.add(_metrics);
        }
      }),
    );

    _subscriptions.add(
      player.stream.height.listen((height) {
        if (height != null && height > 0) {
          _metrics = _metrics.copyWith(videoHeight: height);
          _metricsController.add(_metrics);
        }
      }),
    );
  }

  /// Telemetry poll cadence. Kept slower than 1s since this data only feeds the
  /// debug-only DiagnosticsOverlay and the adaptive escalation loops — while every
  /// tick costs up to 9 platform-channel round trips that can contend with the
  /// video render/decode pipeline on constrained devices (Android TV / STBs).
  static const _telemetryInterval = Duration(seconds: 2);

  void _startTelemetryPolling() {
    // Telemetry polling makes 9 sequential platform-channel calls every second.
    // The only consumer (DiagnosticsOverlay) is debug-only, so skip entirely in release builds.
    if (!kDebugMode) return;
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(_telemetryInterval, (_) => _pollMpvTelemetry());
  }

  Future<void> _pollMpvTelemetry() async {
    if (_player == null || _status == PlayerStatus.disposed || _status == PlayerStatus.idle) return;

    try {
      final platform = _player?.platform;
      if (platform == null) return;
      final p = platform as dynamic;

      // Fire all property reads concurrently instead of one at a time — this was
      // previously 9 sequential platform-channel round trips per tick.
      final results = await Future.wait<dynamic>([
        p.getProperty('estimated-vf-fps') as Future<dynamic>,
        p.getProperty('video-bitrate') as Future<dynamic>,
        p.getProperty('demuxer-cache-duration') as Future<dynamic>,
        p.getProperty('cache-buffering-state') as Future<dynamic>,
        p.getProperty('frame-drop-count') as Future<dynamic>,
        p.getProperty('decoder-frame-drop-count') as Future<dynamic>,
        p.getProperty('hwdec-current') as Future<dynamic>,
        p.getProperty('video-codec') as Future<dynamic>,
        p.getProperty('video-params/pixelformat') as Future<dynamic>,
      ]);

      final fpsStr = results[0];
      final bitrateStr = results[1];
      final cacheDurStr = results[2];
      final cacheStateStr = results[3];
      final frameDropStr = results[4];
      final decoderDropStr = results[5];
      final hwdecCurrentStr = results[6];
      final videoCodecStr = results[7];
      final pixelFormatStr = results[8];

      final fps = fpsStr != null ? double.tryParse(fpsStr.toString()) : null;
      final bitrate = bitrateStr != null ? int.tryParse(bitrateStr.toString()) : null;
      final cacheDurSec = cacheDurStr != null ? double.tryParse(cacheDurStr.toString()) : null;
      final cacheBufferingState = cacheStateStr != null ? int.tryParse(cacheStateStr.toString()) : null;
      final frameDropCount = frameDropStr != null ? int.tryParse(frameDropStr.toString()) : null;
      final decoderFrameDropCount = decoderDropStr != null ? int.tryParse(decoderDropStr.toString()) : null;
      final hwdecCurrent = hwdecCurrentStr?.toString().trim();
      final videoCodec = videoCodecStr?.toString().trim();
      final pixelFormat = pixelFormatStr?.toString().trim();

      String? videoParams;
      if (videoCodec != null || pixelFormat != null) {
        final parts = <String>[];
        if (videoCodec != null) parts.add(videoCodec);
        if (_metrics.videoWidth != null && _metrics.videoHeight != null) {
          parts.add('${_metrics.videoWidth}x${_metrics.videoHeight}');
        }
        if (fps != null) parts.add('${fps.toStringAsFixed(0)}fps');
        if (pixelFormat != null) parts.add(pixelFormat);
        videoParams = parts.join(', ');
      }

      _metrics = _metrics.copyWith(
        fps: fps ?? _metrics.fps,
        videoBitrate: bitrate != null && bitrate > 0 ? bitrate : _metrics.videoBitrate,
        cacheDuration: cacheDurSec != null
            ? Duration(milliseconds: (cacheDurSec * 1000).toInt())
            : _metrics.cacheDuration,
        cacheBufferingState: cacheBufferingState ?? _metrics.cacheBufferingState,
        frameDropCount: frameDropCount ?? _metrics.frameDropCount,
        decoderFrameDropCount: decoderFrameDropCount ?? _metrics.decoderFrameDropCount,
        hwdecCurrent: hwdecCurrent ?? _metrics.hwdecCurrent,
        videoCodec: videoCodec ?? _metrics.videoCodec,
        videoParams: videoParams ?? _metrics.videoParams,
        bufferMode: _bufferMode,
      );

      if (!_metricsController.isClosed) {
        _metricsController.add(_metrics);
      }
    } catch (_) {
      // Ignore if platform does not support getProperty
    }
  }

  @override
  Future<void> open(PlayerSource source) async {
    if (_player == null) {
      await initialize();
    }

    _currentSource = source;
    _firstFrameReceived = false;
    _openStartTime = DateTime.now();
    _updateStatus(PlayerStatus.loading);

    PlayerLogger.open(source.title, streamType: source.streamType.name);

    try {
      final media = mk.Media(
        source.url,
        httpHeaders: source.headers.isNotEmpty ? source.headers : null,
        start: source.profile.isLive ? null : source.startAt,
      );

      await _player?.open(media, play: true);

      final openDuration = DateTime.now().difference(_openStartTime!);
      _metrics = _metrics.copyWith(playerOpenDuration: openDuration, bufferMode: _bufferMode);
      _metricsController.add(_metrics);
    } catch (e) {
      _handleBackendError(e.toString());
    }
  }

  @override
  Future<void> play() async {
    await _player?.play();
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
  }

  @override
  Future<void> stop() async {
    _currentSource = null;
    _firstFrameReceived = false;
    _openStartTime = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    try {
      await _player?.stop();
    } catch (e) {
      PlayerLogger.error('Error stopping player', message: e.toString());
    }
    _updateStatus(PlayerStatus.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    if (_currentSource?.profile.isLive ?? false) {
      // Live streams are continuous; avoid unbuffered seeks
      return;
    }
    await _player?.seek(position);
  }

  @override
  Future<void> seekRelative(Duration offset) async {
    if (_currentSource?.profile.isLive ?? false) return;
    final current = _position;
    final maxDur = _duration > Duration.zero ? _duration : const Duration(hours: 24);
    var target = current + offset;
    if (target < Duration.zero) target = Duration.zero;
    if (target > maxDur) target = maxDur;
    await seek(target);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    final clamped = rate.clamp(0.25, 3.0);
    await _player?.setRate(clamped);
  }

  @override
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    final volPercent = (clamped * 100.0);

    // Clear mute flag on positive volume
    if (clamped > 0) {
      await _setProperty('mute', 'no');
    } else {
      await _setProperty('mute', 'yes');
    }

    await _player?.setVolume(volPercent);
    await _setProperty('volume', volPercent.toStringAsFixed(1));
    await _setProperty('ao-volume', volPercent.toStringAsFixed(1));
  }

  @override
  Future<void> setMuted(bool muted) async {
    await _setProperty('mute', muted ? 'yes' : 'no');
    if (muted) {
      await _player?.setVolume(0.0);
      await _setProperty('volume', '0.0');
    } else {
      await _player?.setVolume(100.0);
      await _setProperty('volume', '100.0');
    }
  }

  @override
  Future<void> setAudioTrack(PlayerAudioTrack track) async {
    final player = _player;
    if (player == null) return;
    final mkTrack = player.state.tracks.audio.firstWhere(
      (a) => a.id == track.id,
      orElse: mk.AudioTrack.auto,
    );
    await player.setAudioTrack(mkTrack);
  }

  @override
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) async {
    final player = _player;
    if (player == null) return;
    if (track.id == 'no') {
      await player.setSubtitleTrack(mk.SubtitleTrack.no());
    } else {
      final mkTrack = player.state.tracks.subtitle.firstWhere(
        (s) => s.id == track.id,
        orElse: mk.SubtitleTrack.auto,
      );
      await player.setSubtitleTrack(mkTrack);
    }
  }

  @override
  Future<void> retry() async {
    if (_currentSource != null) {
      await open(_currentSource!);
    }
  }

  @override
  Future<void> dispose() async {
    _updateStatus(PlayerStatus.disposed);
    PlayerLogger.dispose();

    _telemetryTimer?.cancel();
    _telemetryTimer = null;

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    await _player?.dispose();
    _player = null;
    _videoController = null;

    await _statusController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _errorController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
    await _metricsController.close();
  }

  void _updateStatus(PlayerStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  bool _isNonFatalMessage(String err) {
    final lower = err.toLowerCase();
    return lower.contains('cannot seek') ||
        lower.contains('force-seekable') ||
        lower.contains('ignoring option') ||
        lower.contains('unsupported parameter') ||
        lower.contains('skipping packet') ||
        lower.contains('pts without');
  }

  void _handleBackendError(String rawError) {
    final safeError = PlayerLogger.sanitizeMessage(rawError);
    if (_isNonFatalMessage(rawError)) {
      PlayerLogger.note('MediaKit non-fatal note: $safeError');
      return;
    }

    PlayerLogger.error('MediaKit error', message: safeError);
    final errorType = _classifyError(rawError);
    _metrics = _metrics.copyWith(playbackErrorCount: _metrics.playbackErrorCount + 1);
    _metricsController.add(_metrics);
    _updateStatus(PlayerStatus.error);
    if (!_errorController.isClosed) {
      _errorController.add(errorType);
    }
  }

  PlayerErrorType _classifyError(String err) {
    final lower = err.toLowerCase();
    if (lower.contains('401') || lower.contains('403') || lower.contains('unauthorized')) {
      return PlayerErrorType.unauthorized;
    }
    if (lower.contains('404') || lower.contains('invalid') || lower.contains('not found')) {
      return PlayerErrorType.invalidSource;
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return PlayerErrorType.timeout;
    }
    if (lower.contains('network') || lower.contains('connection refused') || lower.contains('host')) {
      return PlayerErrorType.networkUnavailable;
    }
    if (lower.contains('codec') || lower.contains('decoder')) {
      return PlayerErrorType.codecError;
    }
    if (lower.contains('format') || lower.contains('demux')) {
      return PlayerErrorType.unsupportedFormat;
    }
    return PlayerErrorType.playbackFailure;
  }
}
