import 'dart:async';
import 'dart:typed_data';
import 'package:iptv/player/application/device_decode_prober.dart';
import 'package:iptv/player/domain/entities/device_decode_profile.dart';
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:iptv/player/infrastructure/playback_retry_manager.dart';
import 'package:iptv/player/utils/player_logger.dart';

/// Soft catch-up / hard-resync / decode-heal state for live edge control.
enum LiveEdgePhase {
  atTarget,
  catchingUp,
  cooldown,
}

/// Smart coordinator managing engine lifecycle, capability enforcement, retry logic,
/// software-decode escalation, adaptive buffers, and live-edge drift recovery.
///
/// SW decode escalation:
/// When libmpv reports software decode, monitor rolling frame-drop rate and escalate:
///   Tier 1 (loopFilterSkip): Only after sustained [PlayerMetrics.isDecodeBottleneck].
///   Tier 2 (frameSkip): After sustained high drops under Tier 1.
///   De-escalation: Reverts when drops recover or hardware decode returns.
///
/// Live-edge controller (live sources only):
///   AtTarget -> CatchingUp (1.01x–1.03x) -> HardResync (reopen) -> Cooldown
/// Decode-heal shares the same cool-downed reopen path.
class SmartPlaybackEngine {
  SmartPlaybackEngine({
    required PlayerEngine engine,
    PlaybackRetryManager? retryManager,
    DeviceDecodeProber? decodeProber,
    PlaybackBufferMode initialBufferMode = PlaybackBufferMode.balanced,
    DateTime Function()? clock,
    this.dropRateTier2Threshold = 15,
    this.deEscalateWindow = 10,
    this.escalateWindow = 3,
    this.decodeBottleneckWindow = 3,
    this.networkEscalateWindow = 4,
    this.networkDeEscalateWindow = 20,
    this.liveLowLatencyRecoverWindow = 45,
    this.softCatchUpOverTargetSecs = 1.5,
    this.softCatchUpMaxOverTargetSecs = 6.0,
    this.hardResyncOverTargetSecs = 8.0,
    this.hardResyncImmediateSecs = 20.0,
    this.catchUpRate = 1.02,
    this.resyncCooldown = const Duration(seconds: 45),
    this.decodeHealDropDeltaThreshold = 40,
    this.decodeHealSpikeWindow = 2,
  })  : _engine = engine,
        _retryManager = retryManager ?? PlaybackRetryManager(),
        _decodeProber = decodeProber ?? DeviceDecodeProber(),
        _currentBufferMode = initialBufferMode,
        _clock = clock ?? DateTime.now;

  final PlayerEngine _engine;
  final PlaybackRetryManager _retryManager;
  final DeviceDecodeProber _decodeProber;
  final DateTime Function() _clock;

  DateTime? _switchStartTime;
  PlayerMetrics _latestMetrics = PlayerMetrics.empty;
  PlayerSource? _activeSource;
  bool _wasBuffering = false;

  // ── SW decode escalation state ──────────────────────────────────────────────

  int _tier2ConsecutiveSeconds = 0;
  int _deEscalateConsecutiveSeconds = 0;
  int _decodeBottleneckConsecutiveSeconds = 0;
  int _lastTotalDrops = 0;
  SoftwareDecodeFallbackTier _currentTier = SoftwareDecodeFallbackTier.none;

  final int dropRateTier2Threshold;
  final int deEscalateWindow;
  final int escalateWindow;
  final int decodeBottleneckWindow;

  Timer? _escalationTimer;
  StreamSubscription<PlayerMetrics>? _metricsSubscription;
  StreamSubscription<Duration>? _firstFrameSubscription;

  // ── Adaptive network buffer escalation ──────────────────────────────────────

  PlaybackBufferMode _currentBufferMode;
  int _networkStressConsecutiveSeconds = 0;
  int _networkHealthyConsecutiveSeconds = 0;
  int _lastBufferingCount = 0;
  bool _userPinnedBufferMode = false;

  final int networkEscalateWindow;
  final int networkDeEscalateWindow;
  final int liveLowLatencyRecoverWindow;

  // ── Live-edge drift / decode-heal ───────────────────────────────────────────

  LiveEdgePhase _liveEdgePhase = LiveEdgePhase.atTarget;
  DateTime? _resyncCooldownUntil;
  int _decodeDropSpikeSeconds = 0;
  int _lastDecoderDrops = 0;
  bool _catchUpActive = false;

  final double softCatchUpOverTargetSecs;
  final double softCatchUpMaxOverTargetSecs;
  final double hardResyncOverTargetSecs;
  final double hardResyncImmediateSecs;
  final double catchUpRate;
  final Duration resyncCooldown;
  final int decodeHealDropDeltaThreshold;
  final int decodeHealSpikeWindow;

  PlaybackBufferMode get currentBufferMode => _currentBufferMode;
  LiveEdgePhase get liveEdgePhase => _liveEdgePhase;
  SoftwareDecodeFallbackTier get currentSwDecodeTier => _currentTier;
  bool get isCatchUpActive => _catchUpActive;

  PlayerEngine get engine => _engine;
  PlaybackRetryManager get retryManager => _retryManager;
  DeviceDecodeProber get decodeProber => _decodeProber;
  PlayerMetrics get latestMetrics => _latestMetrics;
  DeviceDecodeProfile? get deviceDecodeProfile => _decodeProber.cachedProfile;

  /// Starts playback of a new source, measuring switch latency and scheduling retry upon failures.
  Future<void> open(
    PlayerSource source, {
    void Function(Duration delay, int attempt)? onRetryScheduled,
  }) async {
    _switchStartTime = _clock();
    _retryManager.cancel();
    _stopEscalationMonitor();
    final firstFrameSub = _firstFrameSubscription;
    _firstFrameSubscription = null;
    await firstFrameSub?.cancel();

    _activeSource = source;
    _wasBuffering = false;
    _userPinnedBufferMode = false;

    await _resetLiveEdgeState(restoreRate: true);
    await _applyEscalationTier(SoftwareDecodeFallbackTier.none);
    _lastTotalDrops = 0;
    _lastDecoderDrops = 0;
    _tier2ConsecutiveSeconds = 0;
    _deEscalateConsecutiveSeconds = 0;
    _decodeBottleneckConsecutiveSeconds = 0;
    _decodeDropSpikeSeconds = 0;
    _networkStressConsecutiveSeconds = 0;
    _networkHealthyConsecutiveSeconds = 0;
    _lastBufferingCount = 0;

    PlayerLogger.open(source.title, streamType: source.streamType.name);

    await _engine.open(source);

    _firstFrameSubscription = _engine.positionStream.listen(null);
    _firstFrameSubscription?.onData((pos) {
      if (pos > Duration.zero && _switchStartTime != null) {
        final totalSwitchDuration = _clock().difference(_switchStartTime!);
        _latestMetrics = _latestMetrics.copyWith(
          switchLatency: totalSwitchDuration,
        );
        _switchStartTime = null;
        _retryManager.reset();
        _firstFrameSubscription?.cancel();
        _firstFrameSubscription = null;
      }
    });

    _startEscalationMonitor();
  }

  void _startEscalationMonitor() {
    _stopEscalationMonitor();
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickEscalation(_latestMetrics);
      _tickNetworkAdaptation(_latestMetrics);
      _tickLiveEdgeControl(_latestMetrics);
    });

    _metricsSubscription = _engine.metricsStream.listen((m) {
      _latestMetrics = m;
      if (m.hwdecCurrent != null) {
        _decodeProber.reconcile(m.hwdecCurrent);
      }
      if (m.isHardwareDecodingActive && _currentTier != SoftwareDecodeFallbackTier.none) {
        _applyEscalationTier(SoftwareDecodeFallbackTier.none);
        _tier2ConsecutiveSeconds = 0;
        _deEscalateConsecutiveSeconds = 0;
        _decodeBottleneckConsecutiveSeconds = 0;
      }
    });
  }

  void _stopEscalationMonitor() {
    _escalationTimer?.cancel();
    _escalationTimer = null;
    _metricsSubscription?.cancel();
    _metricsSubscription = null;
  }

  /// Called every second. Drives the two-tier escalation / de-escalation state machine.
  void _tickEscalation(PlayerMetrics m) {
    if (m.hwdecCurrent == null || m.isHardwareDecodingActive) {
      _decodeBottleneckConsecutiveSeconds = 0;
      return;
    }

    final totalDrops = m.totalFrameDrops;
    final dropDelta = (totalDrops - _lastTotalDrops).clamp(0, 1 << 30);
    _lastTotalDrops = totalDrops;

    // Tier 1 only after sustained decode pressure — SW alone must not skip loop filter.
    if (_currentTier == SoftwareDecodeFallbackTier.none) {
      if (m.isDecodeBottleneck) {
        _decodeBottleneckConsecutiveSeconds++;
        if (_decodeBottleneckConsecutiveSeconds >= decodeBottleneckWindow) {
          PlayerLogger.note(
            '[hwdec-escalation] Applying Tier 1 (loopFilterSkip): '
            'decode bottleneck sustained for $_decodeBottleneckConsecutiveSeconds s.',
          );
          _applyEscalationTier(SoftwareDecodeFallbackTier.loopFilterSkip);
          _decodeBottleneckConsecutiveSeconds = 0;
        }
      } else {
        _decodeBottleneckConsecutiveSeconds = 0;
      }
      return;
    }

    if (_currentTier == SoftwareDecodeFallbackTier.loopFilterSkip) {
      if (dropDelta > dropRateTier2Threshold) {
        _tier2ConsecutiveSeconds++;
        _deEscalateConsecutiveSeconds = 0;
        if (_tier2ConsecutiveSeconds >= escalateWindow) {
          PlayerLogger.note(
            '[hwdec-escalation] Escalating to Tier 2 (frameSkip): '
            '$dropDelta drops/s for $_tier2ConsecutiveSeconds consecutive seconds.',
          );
          _applyEscalationTier(SoftwareDecodeFallbackTier.frameSkip);
          _tier2ConsecutiveSeconds = 0;
        }
      } else {
        _tier2ConsecutiveSeconds = 0;
        if (!m.isDecodeBottleneck) {
          _deEscalateConsecutiveSeconds++;
          if (_deEscalateConsecutiveSeconds >= deEscalateWindow) {
            PlayerLogger.note(
              '[hwdec-escalation] De-escalating to none: decode pressure cleared '
              'for $_deEscalateConsecutiveSeconds consecutive seconds.',
            );
            _applyEscalationTier(SoftwareDecodeFallbackTier.none);
            _deEscalateConsecutiveSeconds = 0;
          }
        } else {
          _deEscalateConsecutiveSeconds = 0;
        }
      }
    } else if (_currentTier == SoftwareDecodeFallbackTier.frameSkip) {
      if (dropDelta <= dropRateTier2Threshold) {
        _deEscalateConsecutiveSeconds++;
        _tier2ConsecutiveSeconds = 0;
        if (_deEscalateConsecutiveSeconds >= deEscalateWindow) {
          PlayerLogger.note(
            '[hwdec-escalation] De-escalating to Tier 1 (loopFilterSkip): '
            'drops recovered for $_deEscalateConsecutiveSeconds consecutive seconds.',
          );
          _applyEscalationTier(SoftwareDecodeFallbackTier.loopFilterSkip);
          _deEscalateConsecutiveSeconds = 0;
        }
      } else {
        _deEscalateConsecutiveSeconds = 0;
      }
    }
  }

  Future<void> _applyEscalationTier(SoftwareDecodeFallbackTier tier) async {
    if (_currentTier == tier) return;
    _currentTier = tier;
    await _engine.applySoftwareDecodeEscalation(tier);
  }

  // ── Adaptive network buffer escalation ──────────────────────────────────────

  void _tickNetworkAdaptation(PlayerMetrics m) {
    if (_userPinnedBufferMode) return;

    final bufferingDelta = (m.bufferingCount - _lastBufferingCount).clamp(0, 1 << 30);
    _lastBufferingCount = m.bufferingCount;

    final stressedNow = m.isNetworkBottleneck || bufferingDelta > 0;

    if (stressedNow) {
      _networkStressConsecutiveSeconds++;
      _networkHealthyConsecutiveSeconds = 0;
      if (_networkStressConsecutiveSeconds >= networkEscalateWindow) {
        _escalateBufferMode();
        _networkStressConsecutiveSeconds = 0;
      }
    } else {
      _networkHealthyConsecutiveSeconds++;
      _networkStressConsecutiveSeconds = 0;
      if (_currentBufferMode == PlaybackBufferMode.stability &&
          _networkHealthyConsecutiveSeconds >= networkDeEscalateWindow) {
        // Step down one rung, then require a fresh healthy window before
        // recovering further to lowLatency (no stability -> lowLatency jump).
        unawaited(_deEscalateBufferMode());
        _networkHealthyConsecutiveSeconds = 0;
      } else if (_currentBufferMode == PlaybackBufferMode.balanced &&
          _networkHealthyConsecutiveSeconds >= liveLowLatencyRecoverWindow) {
        unawaited(_recoverTowardLowLatency());
        _networkHealthyConsecutiveSeconds = 0;
      }
    }
  }

  Future<void> _escalateBufferMode() async {
    final next = switch (_currentBufferMode) {
      PlaybackBufferMode.compact => PlaybackBufferMode.lowLatency,
      PlaybackBufferMode.lowLatency => PlaybackBufferMode.balanced,
      PlaybackBufferMode.balanced => PlaybackBufferMode.stability,
      PlaybackBufferMode.stability => PlaybackBufferMode.stability,
    };
    if (next == _currentBufferMode) return;
    PlayerLogger.note(
      '[buffer-adapt] Escalating buffer mode ${_currentBufferMode.displayName} -> '
      '${next.displayName} (sustained network stress for $networkEscalateWindow s)',
    );
    _currentBufferMode = next;
    await _engine.setBufferMode(next);
  }

  Future<void> _deEscalateBufferMode() async {
    // Step stability -> balanced after the short healthy window.
    if (_currentBufferMode == PlaybackBufferMode.stability) {
      _currentBufferMode = PlaybackBufferMode.balanced;
      PlayerLogger.note(
        '[buffer-adapt] De-escalating buffer mode stability -> balanced '
        '(network stable for $networkDeEscalateWindow s)',
      );
      await _engine.setBufferMode(_currentBufferMode);
    }
  }

  /// Live sports recovery: after a longer healthy stretch, allow balanced -> lowLatency.
  Future<void> _recoverTowardLowLatency() async {
    final isLive = _activeSource?.profile.isLive ?? false;
    if (!isLive) return;
    if (_currentBufferMode != PlaybackBufferMode.balanced) return;
    if (_liveEdgePhase == LiveEdgePhase.cooldown) return;

    _currentBufferMode = PlaybackBufferMode.lowLatency;
    PlayerLogger.note(
      '[buffer-adapt] Recovering buffer mode balanced -> lowLatency '
      '(live healthy for $liveLowLatencyRecoverWindow s)',
    );
    await _engine.setBufferMode(_currentBufferMode);
  }

  // ── Live-edge drift controller + decode-heal ────────────────────────────────

  void _tickLiveEdgeControl(PlayerMetrics m) {
    final source = _activeSource;
    if (source == null || !source.profile.isLive) return;

    final now = _clock();
    if (_resyncCooldownUntil != null && now.isBefore(_resyncCooldownUntil!)) {
      _liveEdgePhase = LiveEdgePhase.cooldown;
      return;
    }
    if (_liveEdgePhase == LiveEdgePhase.cooldown &&
        (_resyncCooldownUntil == null || !now.isBefore(_resyncCooldownUntil!))) {
      _liveEdgePhase = LiveEdgePhase.atTarget;
      _resyncCooldownUntil = null;
    }

    final cacheSecs = (m.cacheDuration?.inMilliseconds ?? 0) / 1000.0;
    final targetSecs = _currentBufferMode.cacheSecs.toDouble();
    final overTarget = cacheSecs - targetSecs;

    // Track buffering edges for post-stall fat-cache resync.
    final bufferingNow = m.isNetworkBottleneck;
    final leftBuffering = _wasBuffering && !bufferingNow;
    _wasBuffering = bufferingNow;

    // Decode-heal: healthy cache + decoder drop storm => broken refs / macroblocks.
    final decoderDrops = m.decoderFrameDropCount ?? 0;
    final decoderDelta = (decoderDrops - _lastDecoderDrops).clamp(0, 1 << 30);
    _lastDecoderDrops = decoderDrops;
    final cacheHealthy = !m.isNetworkBottleneck &&
        (m.cacheBufferingState == null || m.cacheBufferingState! >= 70);
    if (cacheHealthy && decoderDelta >= decodeHealDropDeltaThreshold) {
      _decodeDropSpikeSeconds++;
    } else {
      _decodeDropSpikeSeconds = 0;
    }

    if (_decodeDropSpikeSeconds >= decodeHealSpikeWindow) {
      _decodeDropSpikeSeconds = 0;
      unawaited(_hardResyncLive(reason: 'decode-heal'));
      return;
    }

    // Immediate hard resync on extreme cache lag or fat cache right after stall.
    if (cacheSecs >= hardResyncImmediateSecs ||
        (leftBuffering && overTarget >= hardResyncOverTargetSecs)) {
      unawaited(_hardResyncLive(reason: 'hard-resync'));
      return;
    }

    if (overTarget >= hardResyncOverTargetSecs) {
      unawaited(_hardResyncLive(reason: 'hard-resync'));
      return;
    }

    if (overTarget >= softCatchUpOverTargetSecs &&
        overTarget < softCatchUpMaxOverTargetSecs) {
      unawaited(_enterSoftCatchUp());
      return;
    }

    // Back at / under soft band — restore 1.0x.
    if (_catchUpActive && overTarget < softCatchUpOverTargetSecs) {
      unawaited(_exitSoftCatchUp());
    }
  }

  Future<void> _enterSoftCatchUp() async {
    if (_catchUpActive) {
      _liveEdgePhase = LiveEdgePhase.catchingUp;
      return;
    }
    _catchUpActive = true;
    _liveEdgePhase = LiveEdgePhase.catchingUp;
    PlayerLogger.note(
      '[live-edge] Soft catch-up at ${catchUpRate}x '
      '(cache ahead of target)',
    );
    await _engine.setPlaybackRate(catchUpRate);
  }

  Future<void> _exitSoftCatchUp() async {
    if (!_catchUpActive) return;
    _catchUpActive = false;
    if (_liveEdgePhase == LiveEdgePhase.catchingUp) {
      _liveEdgePhase = LiveEdgePhase.atTarget;
    }
    PlayerLogger.note('[live-edge] Restoring playback rate 1.0x');
    await _engine.setPlaybackRate(1.0);
  }

  Future<void> _hardResyncLive({required String reason}) async {
    final source = _activeSource;
    if (source == null || !source.profile.isLive) return;

    final now = _clock();
    if (_resyncCooldownUntil != null && now.isBefore(_resyncCooldownUntil!)) {
      return;
    }

    _resyncCooldownUntil = now.add(resyncCooldown);
    _liveEdgePhase = LiveEdgePhase.cooldown;
    _decodeDropSpikeSeconds = 0;
    await _exitSoftCatchUp();

    PlayerLogger.note(
      '[$reason] Hard live-edge resync — reopening source '
      '(cooldown ${resyncCooldown.inSeconds}s)',
    );
    await _engine.open(source);
  }

  Future<void> _resetLiveEdgeState({required bool restoreRate}) async {
    _liveEdgePhase = LiveEdgePhase.atTarget;
    _resyncCooldownUntil = null;
    _decodeDropSpikeSeconds = 0;
    if (restoreRate && _catchUpActive) {
      _catchUpActive = false;
      await _engine.setPlaybackRate(1.0);
    } else {
      _catchUpActive = false;
    }
  }

  // ── DeviceDecodeProber integration ──────────────────────────────────────────

  Future<void> initDeviceProfile() async {
    await _decodeProber.loadCached();
    if (_decodeProber.cachedProfile == null) {
      PlayerLogger.note(
        '[SmartPlaybackEngine] No cached decode profile — will probe from live telemetry.',
      );
    }
  }

  bool handleError(
    PlayerErrorType errorType, {
    required Future<void> Function() onExecuteRetry,
    required void Function(Duration delay, int attempt) onRetryScheduled,
  }) {
    unawaited(_exitSoftCatchUp());
    return _retryManager.scheduleRetry(
      errorType: errorType,
      onExecuteRetry: onExecuteRetry,
      onRetryScheduled: onRetryScheduled,
    );
  }

  void cancelRetry() => _retryManager.cancel();

  Future<void> play() => _engine.play();

  Future<void> pause() async {
    await _exitSoftCatchUp();
    await _engine.pause();
  }

  Future<void> stop() async {
    _switchStartTime = null;
    _activeSource = null;
    unawaited(_firstFrameSubscription?.cancel());
    _firstFrameSubscription = null;
    _retryManager.cancel();
    _stopEscalationMonitor();
    await _resetLiveEdgeState(restoreRate: true);
    return _engine.stop();
  }

  Future<void> seek(Duration position) => _engine.seek(position);
  Future<void> seekRelative(Duration offset) => _engine.seekRelative(offset);
  Future<void> seekForPreview(Duration position) =>
      _engine.seekForPreview(position);
  Future<Uint8List?> captureFrame() => _engine.captureFrame();
  Future<void> setPlaybackRate(double rate) => _engine.setPlaybackRate(rate);
  Future<void> setVolume(double volume) => _engine.setVolume(volume);
  Future<void> setMuted(bool muted) => _engine.setMuted(muted);
  Future<void> setAudioTrack(PlayerAudioTrack track) => _engine.setAudioTrack(track);
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) =>
      _engine.setSubtitleTrack(track);

  Future<void> setBufferMode(PlaybackBufferMode mode) {
    _userPinnedBufferMode = true;
    _currentBufferMode = mode;
    return _engine.setBufferMode(mode);
  }

  Future<void> retry() => _engine.retry();

  /// Test/harness helper: drive one adaptation tick with the given metrics.
  void debugTick(PlayerMetrics metrics) {
    _latestMetrics = metrics;
    _tickEscalation(metrics);
    _tickNetworkAdaptation(metrics);
    _tickLiveEdgeControl(metrics);
  }

  Future<void> dispose() async {
    _stopEscalationMonitor();
    _retryManager.cancel();
    final firstFrameSub = _firstFrameSubscription;
    _firstFrameSubscription = null;
    await firstFrameSub?.cancel();
    await _resetLiveEdgeState(restoreRate: true);
    await _engine.dispose();
  }
}
