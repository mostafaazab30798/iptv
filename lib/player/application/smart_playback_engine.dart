import 'dart:async';
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

/// Smart coordinator managing engine lifecycle, capability enforcement, retry logic, and latency metrics.
///
/// SW decode escalation (§8.2):
/// When libmpv reports `hwdec-current=no`, this engine monitors the rolling frame-drop rate
/// every second and escalates through two tiers:
///   Tier 1 (loopFilterSkip): Applied immediately on SW decode detection.
///   Tier 2 (frameSkip):      Applied if drops > [_dropRateTier2Threshold]/s for 3+ consecutive seconds.
///   De-escalation:           Reverts to Tier 1 if drops stay below threshold for 10+ consecutive seconds.
class SmartPlaybackEngine {
  SmartPlaybackEngine({
    required PlayerEngine engine,
    PlaybackRetryManager? retryManager,
    DeviceDecodeProber? decodeProber,
  })  : _engine = engine,
        _retryManager = retryManager ?? PlaybackRetryManager(),
        _decodeProber = decodeProber ?? DeviceDecodeProber();

  final PlayerEngine _engine;
  final PlaybackRetryManager _retryManager;
  final DeviceDecodeProber _decodeProber;

  DateTime? _switchStartTime; // T0
  PlayerMetrics _latestMetrics = PlayerMetrics.empty;

  // ── SW decode escalation state ──────────────────────────────────────────────

  /// Consecutive seconds where drops/s > tier-2 threshold.
  int _tier2ConsecutiveSeconds = 0;

  /// Consecutive seconds where drops/s is low enough to de-escalate from Tier 2.
  int _deEscalateConsecutiveSeconds = 0;

  /// Last sampled total frame-drop count used to compute delta/s.
  int _lastTotalDrops = 0;

  /// Current escalation tier being applied.
  SoftwareDecodeFallbackTier _currentTier = SoftwareDecodeFallbackTier.none;

  /// Drops/s above which Tier 2 escalation is triggered (sustained for 3s).
  static const _dropRateTier2Threshold = 15;

  /// Consecutive seconds below threshold required to de-escalate Tier 2 → Tier 1.
  static const _deEscalateWindow = 10;

  /// Consecutive seconds above threshold required to escalate Tier 1 → Tier 2.
  static const _escalateWindow = 3;

  Timer? _escalationTimer;

  // ── Adaptive network buffer escalation ──────────────────────────────────────────
  //
  // The SW-decode tiers above only fire when mpv confirms software decoding is
  // active. Most real-world "laggy stream / dropped frames" complaints on IPTV
  // are actually network-side: the read-ahead buffer empties faster than the
  // stream downloads (slow/variable Wi-Fi, congested ISP link, overloaded
  // Xtream panel), which shows up as `isNetworkBottleneck` / rising
  // `bufferingCount` even with hardware decode fully active. Nothing previously
  // reacted to that signal — buffer mode stayed wherever the user last set it.
  //
  // This mirrors the same escalate/de-escalate-with-hysteresis pattern as the
  // SW-decode tiers, but walks PlaybackBufferMode lowLatency → balanced →
  // stability under sustained stress, and steps back down (only as far as
  // `balanced`, never back to `lowLatency` automatically) after a long enough
  // healthy window, to avoid oscillating back into the mode that caused the
  // stress in the first place.

  PlaybackBufferMode _currentBufferMode = PlaybackBufferMode.balanced;
  int _networkStressConsecutiveSeconds = 0;
  int _networkHealthyConsecutiveSeconds = 0;
  int _lastBufferingCount = 0;

  /// Consecutive seconds of sustained network stress before escalating buffer mode.
  static const _networkEscalateWindow = 4;

  /// Consecutive seconds of sustained health before stepping buffer mode back down.
  static const _networkDeEscalateWindow = 20;

  PlaybackBufferMode get currentBufferMode => _currentBufferMode;

  // ────────────────────────────────────────────────────────────────────────────

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
    _switchStartTime = DateTime.now(); // T0: User selects / changes channel
    _retryManager.cancel();

    // Reset escalation state for the new channel.
    _stopEscalationMonitor();
    await _applyEscalationTier(SoftwareDecodeFallbackTier.none);
    _lastTotalDrops = 0;
    _tier2ConsecutiveSeconds = 0;
    _deEscalateConsecutiveSeconds = 0;
    _networkStressConsecutiveSeconds = 0;
    _networkHealthyConsecutiveSeconds = 0;
    _lastBufferingCount = 0;

    PlayerLogger.open(source.title, streamType: source.streamType.name);

    await _engine.open(source);

    // Setup first-frame latency tracking.
    final sub = _engine.positionStream.listen(null);
    sub.onData((pos) {
      if (pos > Duration.zero && _switchStartTime != null) {
        final totalSwitchDuration = DateTime.now().difference(_switchStartTime!);
        _latestMetrics = _latestMetrics.copyWith(
          switchLatency: totalSwitchDuration,
        );
        _switchStartTime = null;
        _retryManager.reset();
        sub.cancel();
      }
    });

    // Subscribe to metrics stream to run escalation monitor after first frame.
    _startEscalationMonitor();
  }

  // ── SW Decode Escalation Monitor ─────────────────────────────────────────────

  void _startEscalationMonitor() {
    _stopEscalationMonitor();
    // Sample every second — same cadence as the mpv telemetry poll.
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickEscalation(_latestMetrics);
      _tickNetworkAdaptation(_latestMetrics);
    });

    // Also subscribe to the engine metrics stream so _latestMetrics stays current.
    _engine.metricsStream.listen((m) {
      _latestMetrics = m;
      // Reconcile device profile if we have fresh hwdec data.
      if (m.hwdecCurrent != null) {
        _decodeProber.reconcile(m.hwdecCurrent);
      }
      // If hwdec just became active, immediately de-escalate back to none.
      if (m.isHardwareDecodingActive && _currentTier != SoftwareDecodeFallbackTier.none) {
        _applyEscalationTier(SoftwareDecodeFallbackTier.none);
        _tier2ConsecutiveSeconds = 0;
        _deEscalateConsecutiveSeconds = 0;
      }
    });
  }

  void _stopEscalationMonitor() {
    _escalationTimer?.cancel();
    _escalationTimer = null;
  }

  /// Called every second. Drives the two-tier escalation / de-escalation state machine.
  void _tickEscalation(PlayerMetrics m) {
    // Only run when software decode is confirmed active.
    if (m.hwdecCurrent == null || m.isHardwareDecodingActive) return;

    final totalDrops = m.totalFrameDrops;
    final dropDelta = (totalDrops - _lastTotalDrops).clamp(0, 1 << 30);
    _lastTotalDrops = totalDrops;

    // Apply Tier 1 immediately if SW decode is active and we haven't escalated yet.
    if (_currentTier == SoftwareDecodeFallbackTier.none) {
      _applyEscalationTier(SoftwareDecodeFallbackTier.loopFilterSkip);
      return;
    }

    if (_currentTier == SoftwareDecodeFallbackTier.loopFilterSkip) {
      if (dropDelta > _dropRateTier2Threshold) {
        _tier2ConsecutiveSeconds++;
        _deEscalateConsecutiveSeconds = 0;
        if (_tier2ConsecutiveSeconds >= _escalateWindow) {
          // Sustained high drops — escalate to Tier 2.
          PlayerLogger.note(
            '[hwdec-escalation] Escalating to Tier 2 (frameSkip): '
            '$dropDelta drops/s for $_tier2ConsecutiveSeconds consecutive seconds.',
          );
          _applyEscalationTier(SoftwareDecodeFallbackTier.frameSkip);
          _tier2ConsecutiveSeconds = 0;
        }
      } else {
        _tier2ConsecutiveSeconds = 0;
      }
    } else if (_currentTier == SoftwareDecodeFallbackTier.frameSkip) {
      if (dropDelta <= _dropRateTier2Threshold) {
        _deEscalateConsecutiveSeconds++;
        _tier2ConsecutiveSeconds = 0;
        if (_deEscalateConsecutiveSeconds >= _deEscalateWindow) {
          // Drops recovered — de-escalate back to Tier 1.
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

  // ── Adaptive network buffer escalation ──────────────────────────────────────────

  /// Called every second alongside [_tickEscalation]. Drives buffer-mode
  /// escalation/de-escalation based on network-side stress signals.
  void _tickNetworkAdaptation(PlayerMetrics m) {
    final bufferingDelta = (m.bufferingCount - _lastBufferingCount).clamp(0, 1 << 30);
    _lastBufferingCount = m.bufferingCount;

    final stressedNow = m.isNetworkBottleneck || bufferingDelta > 0;

    if (stressedNow) {
      _networkStressConsecutiveSeconds++;
      _networkHealthyConsecutiveSeconds = 0;
      if (_networkStressConsecutiveSeconds >= _networkEscalateWindow) {
        _escalateBufferMode();
        _networkStressConsecutiveSeconds = 0;
      }
    } else {
      _networkHealthyConsecutiveSeconds++;
      _networkStressConsecutiveSeconds = 0;
      if (_networkHealthyConsecutiveSeconds >= _networkDeEscalateWindow) {
        _deEscalateBufferMode();
        _networkHealthyConsecutiveSeconds = 0;
      }
    }
  }

  Future<void> _escalateBufferMode() async {
    final next = switch (_currentBufferMode) {
      PlaybackBufferMode.lowLatency => PlaybackBufferMode.balanced,
      PlaybackBufferMode.balanced => PlaybackBufferMode.stability,
      PlaybackBufferMode.stability => PlaybackBufferMode.stability,
    };
    if (next == _currentBufferMode) return;
    PlayerLogger.note(
      '[buffer-adapt] Escalating buffer mode ${_currentBufferMode.displayName} -> '
      '${next.displayName} (sustained network stress for $_networkEscalateWindow s)',
    );
    _currentBufferMode = next;
    await _engine.setBufferMode(next);
  }

  Future<void> _deEscalateBufferMode() async {
    // Only ever step back down to `balanced`, never automatically back to
    // `lowLatency` — that's the mode most likely to have caused the stress,
    // and re-entering it would just restart the escalate/de-escalate cycle.
    // Returning to low-latency requires an explicit user choice.
    if (_currentBufferMode == PlaybackBufferMode.stability) {
      _currentBufferMode = PlaybackBufferMode.balanced;
      PlayerLogger.note(
        '[buffer-adapt] De-escalating buffer mode stability -> balanced '
        '(network stable for $_networkDeEscalateWindow s)',
      );
      await _engine.setBufferMode(_currentBufferMode);
    }
  }

  // ── DeviceDecodeProber integration ──────────────────────────────────────────

  /// Loads or initialises the device decode profile from cache.
  ///
  /// Should be called once after [open] has been invoked on the first channel.
  /// The profile will be probed from the live `hwdec-current` telemetry value
  /// via [reconcile] on the next metrics tick — no blocking call required.
  Future<void> initDeviceProfile() async {
    await _decodeProber.loadCached();
    if (_decodeProber.cachedProfile == null) {
      PlayerLogger.note('[SmartPlaybackEngine] No cached decode profile — will probe from live telemetry.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────

  /// Handles playback error with bounded retry mechanism.
  bool handleError(
    PlayerErrorType errorType, {
    required Future<void> Function() onExecuteRetry,
    required void Function(Duration delay, int attempt) onRetryScheduled,
  }) {
    return _retryManager.scheduleRetry(
      errorType: errorType,
      onExecuteRetry: onExecuteRetry,
      onRetryScheduled: onRetryScheduled,
    );
  }

  Future<void> play() => _engine.play();
  Future<void> pause() => _engine.pause();
  Future<void> stop() {
    _switchStartTime = null;
    _retryManager.cancel();
    _stopEscalationMonitor();
    return _engine.stop();
  }

  Future<void> seek(Duration position) => _engine.seek(position);
  Future<void> seekRelative(Duration offset) => _engine.seekRelative(offset);
  Future<void> setPlaybackRate(double rate) => _engine.setPlaybackRate(rate);
  Future<void> setVolume(double volume) => _engine.setVolume(volume);
  Future<void> setMuted(bool muted) => _engine.setMuted(muted);
  Future<void> setAudioTrack(PlayerAudioTrack track) => _engine.setAudioTrack(track);
  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) => _engine.setSubtitleTrack(track);
  Future<void> setBufferMode(PlaybackBufferMode mode) {
    _currentBufferMode = mode;
    return _engine.setBufferMode(mode);
  }
  Future<void> retry() => _engine.retry();

  Future<void> dispose() async {
    _retryManager.cancel();
    _stopEscalationMonitor();
    await _engine.dispose();
  }
}
