// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/network/url_helpers.dart';
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/entities/web_video_handle.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:iptv/player/infrastructure/web/native_vod_bridge.dart';
import 'package:iptv/player/infrastructure/web/native_vod_policy.dart';

int _instanceIdCounter = 0;

/// Detects iOS/iPadOS Safari, where native AVPlayer playback is preferred.
bool isIosSafariWeb() {
  try {
    // Hardware/Native HLS capability probe:
    // Safari on Apple platforms (iOS/iPadOS/macOS) responds with 'probably' or 'maybe'
    // Chrome, Firefox, and Edge on non-Apple engines respond with '' (empty string).
    final probe = html.VideoElement();
    final canPlayHls =
        probe.canPlayType('application/vnd.apple.mpegurl').isNotEmpty ||
            probe.canPlayType('application/x-mpegurl').isNotEmpty;

    if (!canPlayHls) {
      return false;
    }

    final ua = html.window.navigator.userAgent.toLowerCase();

    // Check for iOS devices: iPhone, iPad, iPod
    final isIosDevice =
        ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');

    // iPadOS 13+ desktop-class Safari reports as Macintosh with multi-touch points
    final isIpadOs = ua.contains('macintosh') &&
        (html.window.navigator.maxTouchPoints ?? 0) > 1;

    // Safari browser (excluding alternative iOS browsers and embedded WebViews).
    final isSafariBrowser = ua.contains('safari') &&
        !ua.contains('chrome') &&
        !ua.contains('crios') &&
        !ua.contains('fxios') &&
        !ua.contains('edgios') &&
        !ua.contains('opios') &&
        !ua.contains('android');

    return (isIosDevice || isIpadOs) && isSafariBrowser;
  } catch (_) {
    return false;
  }
}

/// Backwards-compatible alias for existing callers.
bool isIosOrSafariWeb() => isIosSafariWeb();

/// Factory function to create [WebIosPlayerEngine] on web.
PlayerEngine createWebIosPlayerEngine({
  PlaybackBufferMode? initialBufferMode,
}) {
  return WebIosPlayerEngine();
}

/// Native HTML5 `<video>` based [PlayerEngine] for iOS Safari and macOS Safari.
///
/// Uses Apple's native AVPlayer via `<video src="...">` to achieve hardware-accelerated
/// HLS (.m3u8) and MP4 playback without third-party JS dependencies.
class WebIosPlayerEngine implements PlayerEngine {
  WebIosPlayerEngine() {
    _instanceId = ++_instanceIdCounter;
    _viewTypeId = 'web-ios-player-$_instanceId';
  }

  late final int _instanceId;
  late final String _viewTypeId;
  html.VideoElement? _videoElement;
  WebVideoHandle? _handle;

  final _statusController = StreamController<PlayerStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferController = StreamController<Duration>.broadcast();
  final _errorController = StreamController<PlayerErrorType>.broadcast();
  final _audioTracksController =
      StreamController<List<PlayerAudioTrack>>.broadcast();
  final _subtitleTracksController =
      StreamController<List<PlayerSubtitleTrack>>.broadcast();
  final _metricsController = StreamController<PlayerMetrics>.broadcast();

  final List<StreamSubscription<dynamic>> _eventSubscriptions = [];
  Timer? _metricsTimer;

  PlayerStatus _status = PlayerStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  PlayerSource? _currentSource;
  PlayerMetrics _metrics = PlayerMetrics.empty;
  bool _isDisposed = false;
  bool _usingNativeVodHelper = false;

  @override
  PlayerStatus get currentStatus => _status;

  @override
  Duration get currentPosition => _position;

  @override
  Duration get currentDuration => _duration;

  @override
  PlayerSource? get currentSource => _currentSource;

  @override
  dynamic get platformHandle => _handle;

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
  Stream<List<PlayerAudioTrack>> get audioTracksStream =>
      _audioTracksController.stream;

  @override
  Stream<List<PlayerSubtitleTrack>> get subtitleTracksStream =>
      _subtitleTracksController.stream;

  @override
  Stream<PlayerMetrics> get metricsStream => _metricsController.stream;

  @override
  Future<void> initialize() async {
    if (_videoElement != null) return;

    final video = html.VideoElement()
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..setAttribute('x-webkit-airplay', 'allow')
      ..autoplay = true
      ..preload = 'auto'
      ..controls = false;

    // Absolute fill + pointer-events:none so the platform view gets a real
    // layout box and Flutter overlays (back/controls) receive taps on iOS.
    video.style
      ..position = 'absolute'
      ..top = '0'
      ..left = '0'
      ..width = '100%'
      ..height = '100%'
      ..objectFit = 'contain'
      ..display = 'block'
      ..pointerEvents = 'none'
      ..backgroundColor = 'black'
      ..border = 'none'
      ..outline = 'none'
      ..setProperty('z-index', '0');

    final host = html.DivElement()
      ..style.position = 'relative'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.overflow = 'hidden'
      ..style.backgroundColor = 'black';
    host.append(video);

    _videoElement = video;
    _handle = WebVideoHandle(
      viewTypeId: _viewTypeId,
      videoElement: video,
      onAspectRatioChanged: (index, [_ = 1.0]) {
        if (index == 2) {
          // Fill (100% cover)
          video.style.objectFit = 'cover';
        } else {
          // Preserve the source ratio for Best Fit, Fit, 16:9, and 4:3.
          // The Flutter view constrains forced-ratio modes; CSS only decides
          // how the native video is fitted inside that box.
          video.style.objectFit = 'contain';
        }
        video.style.transform = 'none';
      },
    );

    // Register with Flutter Web platform view registry
    ui_web.platformViewRegistry.registerViewFactory(
      _viewTypeId,
      (int viewId) => host,
    );

    _attachEventListeners(video);
    _startMetricsTimer();

    AppLogger.info('WebIosPlayerEngine initialized (viewId: $_viewTypeId)', feature: 'player');
  }

  void _attachEventListeners(html.VideoElement video) {
    _eventSubscriptions.addAll([
      video.onLoadedMetadata.listen((_) => _emitDimensions(video)),
      video.onResize.listen((_) => _emitDimensions(video)),
      video.onPlay.listen((_) => _setStatus(PlayerStatus.playing)),
      video.onPlaying.listen((_) => _setStatus(PlayerStatus.playing)),
      video.onPause.listen((_) {
        if (_status != PlayerStatus.completed &&
            _status != PlayerStatus.idle &&
            !_isDisposed) {
          _setStatus(PlayerStatus.paused);
        }
      }),
      video.onWaiting.listen((_) {
        if (_status != PlayerStatus.idle && !_isDisposed) {
          _setStatus(PlayerStatus.buffering);
        }
      }),
      video.onTimeUpdate.listen((_) {
        if (_isDisposed) return;
        final currentSec = video.currentTime;
        _position = Duration(milliseconds: (currentSec * 1000).round());
        _positionController.add(_position);
      }),
      video.onDurationChange.listen((_) {
        if (_isDisposed) return;
        final d = video.duration;
        if (d.isFinite && d > 0) {
          _duration = Duration(milliseconds: (d * 1000).round());
          _durationController.add(_duration);
        }
      }),
      video.on['progress'].listen((_) {
        if (_isDisposed) return;
        try {
          final buffered = video.buffered;
          if (buffered.length > 0) {
            final endSec = buffered.end(buffered.length - 1);
            _bufferController.add(Duration(milliseconds: (endSec * 1000).round()));
          }
        } catch (_) {}
      }),
      video.onEnded.listen((_) => _setStatus(PlayerStatus.completed)),
      video.onError.listen((_) {
        final err = video.error;
        AppLogger.warning('WebIosPlayerEngine error: code=${err?.code} message=${err?.message}', feature: 'player');
        _handleError(err);
      }),
    ]);
  }

  void _emitDimensions(html.VideoElement video) {
    if (_isDisposed) return;
    if (video.videoWidth > 0 && video.videoHeight > 0) {
      _metrics = _metrics.copyWith(
        videoWidth: video.videoWidth,
        videoHeight: video.videoHeight,
      );
      _metricsController.add(_metrics);
    }
  }

  /// Rewrites `.ts` → `.m3u8` on the real stream URL (including proxied `?url=`).
  static String _ensureNativeHlsUrl(String streamUrl) {
    String convertTsToM3u8(String url) {
      return url.replaceAllMapped(
        RegExp(r'\.ts(\?|$)', caseSensitive: false),
        (match) => '.m3u8${match.group(1) ?? ''}',
      );
    }

    if (streamUrl.contains('/proxy')) {
      final uri = Uri.tryParse(streamUrl);
      final rawTarget = uri?.queryParameters['url'];
      if (rawTarget != null &&
          rawTarget.toLowerCase().contains('.ts') &&
          !rawTarget.toLowerCase().contains('.m3u8')) {
        final convertedTarget = convertTsToM3u8(rawTarget);
        final proxied = UrlHelpers.wrapWebProxy(convertedTarget);
        AppLogger.info(
          'Web iOS Player converted proxied TS to HLS: $proxied',
          feature: 'player',
        );
        return proxied;
      }
      return streamUrl;
    }

    if (streamUrl.toLowerCase().contains('.ts') &&
        !streamUrl.toLowerCase().contains('.m3u8')) {
      final convertedUrl = convertTsToM3u8(streamUrl);
      AppLogger.info(
        'Web iOS Player converted direct TS to HLS: $convertedUrl',
        feature: 'player',
      );
      return convertedUrl;
    }

    return streamUrl;
  }

  void _handleError(html.MediaError? err) {
    if (_isDisposed) return;
    _setStatus(PlayerStatus.error);

    PlayerErrorType errorType = PlayerErrorType.unknown;
    if (err != null) {
      switch (err.code) {
        case 1: // MEDIA_ERR_ABORTED
          return;
        case 2: // MEDIA_ERR_NETWORK
          errorType = PlayerErrorType.timeout;
          break;
        case 3: // MEDIA_ERR_DECODE
          errorType = PlayerErrorType.codecError;
          break;
        case 4: // MEDIA_ERR_SRC_NOT_SUPPORTED
          errorType = PlayerErrorType.unsupportedFormat;
          break;
      }
    }
    _errorController.add(errorType);
  }

  void _setStatus(PlayerStatus newStatus) {
    if (_isDisposed || _status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void _startMetricsTimer() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isDisposed || _videoElement == null) return;
      final video = _videoElement!;
      _metrics = PlayerMetrics(
        videoWidth: video.videoWidth > 0 ? video.videoWidth : null,
        videoHeight: video.videoHeight > 0 ? video.videoHeight : null,
        hwdecCurrent: 'videotoolbox', // Native AVPlayer hardware decoding
      );
      _metricsController.add(_metrics);
    });
  }

  @override
  Future<void> open(PlayerSource source) async {
    if (_isDisposed) return;
    if (_videoElement == null) {
      await initialize();
    }

    _currentSource = source;
    _position = Duration.zero;
    _duration = Duration.zero;
    _setStatus(PlayerStatus.buffering);

    String streamUrl = source.url;

    // Native iOS AVPlayer does not support raw MPEG-TS (.ts) streams.
    // Convert Xtream .ts live URLs to .m3u8 so Safari can play via native HLS.
    streamUrl = _ensureNativeHlsUrl(streamUrl);

    final video = _videoElement!;

    // Movies/series are often Matroska (.mkv). AVPlayer cannot demux MKV, so
    // remux into fragmented MP4 via HopeTvNativeVod while still using this
    // native <video> element (hardware decode on iOS).
    if (_shouldUseNativeVodHelper(streamUrl)) {
      await _openWithNativeVodHelper(video, streamUrl);
      return;
    }

    _usingNativeVodHelper = false;
    await _openDirect(video, streamUrl);
  }

  Future<void> _openDirect(html.VideoElement video, String streamUrl) async {
    video.src = streamUrl;
    video.load();

    try {
      await video.play();
    } catch (e) {
      AppLogger.warning('Web iOS Player autoplay deferred or restricted: $e', feature: 'player');
      // If autoplay was rejected by iOS policy due to user gesture requirement,
      // it will play once user triggers interaction.
    }
  }

  bool _shouldUseNativeVodHelper(String streamUrl) =>
      requiresIosVodRemux(streamUrl);

  Future<void> _openWithNativeVodHelper(
    html.VideoElement video,
    String streamUrl,
  ) async {
    _usingNativeVodHelper = true;
    try {
      final ok = await nativeVodPlay(video, streamUrl);
      if (!ok) {
        AppLogger.warning(
          'HopeTvNativeVod helper missing; falling back to direct src',
          feature: 'player',
        );
        _usingNativeVodHelper = false;
        await _openDirect(video, streamUrl);
        return;
      }
      AppLogger.info(
        'Web iOS Player VOD via native helper',
        feature: 'player',
      );
    } catch (e) {
      AppLogger.warning('Web iOS native VOD helper failed: $e', feature: 'player');
      _usingNativeVodHelper = false;
      // Some panels report an MKV/AVI extension while returning an MP4
      // container. Give native AVPlayer a final direct attempt and let its
      // media error provide the authoritative failure classification.
      await _openDirect(video, streamUrl);
    }
  }

  @override
  Future<void> play() async {
    if (_isDisposed || _videoElement == null) return;
    try {
      await _videoElement!.play();
    } catch (e) {
      AppLogger.warning('Web iOS Player play error: $e', feature: 'player');
    }
  }

  @override
  Future<void> pause() async {
    if (_isDisposed || _videoElement == null) return;
    _videoElement!.pause();
  }

  @override
  Future<void> stop() async {
    if (_isDisposed || _videoElement == null) return;
    await _stopNativeVodHelper();
    _videoElement!.pause();
    _videoElement!.removeAttribute('src');
    try {
      _videoElement!.srcObject = null;
    } catch (_) {}
    _videoElement!.load();
    _currentSource = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _setStatus(PlayerStatus.idle);
  }

  Future<void> _stopNativeVodHelper() async {
    if (!_usingNativeVodHelper) return;
    final video = _videoElement;
    if (video == null) return;
    try {
      await nativeVodStop(video);
    } catch (_) {}
    _usingNativeVodHelper = false;
  }

  @override
  Future<void> seek(Duration position) async {
    if (_isDisposed || _videoElement == null) return;
    _videoElement!.currentTime = position.inMilliseconds / 1000.0;
  }

  @override
  Future<void> seekRelative(Duration offset) async {
    if (_isDisposed || _videoElement == null) return;
    final current = _videoElement!.currentTime;
    _videoElement!.currentTime = current + (offset.inMilliseconds / 1000.0);
  }

  @override
  Future<void> seekForPreview(Duration position) async {
    await seek(position);
  }

  @override
  Future<Uint8List?> captureFrame() async {
    // Frame capture from cross-origin IPTV streams is blocked by browser security (tainted canvas)
    return null;
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    if (_isDisposed || _videoElement == null) return;
    _videoElement!.playbackRate = rate;
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_isDisposed || _videoElement == null) return;
    _videoElement!.volume = volume.clamp(0.0, 1.0);
  }

  @override
  Future<void> setMuted(bool muted) async {
    if (_isDisposed || _videoElement == null) return;
    _videoElement!.muted = muted;
  }

  @override
  Future<void> setAudioTrack(PlayerAudioTrack track) async {
    // Native iOS Safari handles audio tracks internally in AVPlayer controls.
  }

  @override
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) async {
    // Native iOS Safari handles text tracks internally in AVPlayer controls.
  }

  @override
  Future<void> setBufferMode(PlaybackBufferMode mode) async {
    // Buffer sizing is managed by the underlying hardware AVPlayer.
  }

  @override
  Future<void> applySoftwareDecodeEscalation(SoftwareDecodeFallbackTier tier) async {
    // Hardware decoding escalation is not applicable to iOS AVPlayer.
  }

  @override
  Future<void> retry() async {
    if (_currentSource != null) {
      await open(_currentSource!);
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _metricsTimer?.cancel();
    for (final sub in _eventSubscriptions) {
      await sub.cancel();
    }
    _eventSubscriptions.clear();

    await _stopNativeVodHelper();

    if (_videoElement != null) {
      _videoElement!.pause();
      _videoElement!.removeAttribute('src');
      try {
        _videoElement!.srcObject = null;
      } catch (_) {}
      _videoElement!.load();
      _videoElement = null;
    }

    await _statusController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferController.close();
    await _errorController.close();
    await _audioTracksController.close();
    await _subtitleTracksController.close();
    await _metricsController.close();
  }
}
