import 'dart:async';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';

typedef SeekExecutionCallback = Future<void> Function(Duration targetPosition);
typedef RateAdjustmentCallback = Future<void> Function(double rate);

/// High-precision synchronization engine that compares TV host timestamps
/// against phone companion playback time and executes micro-seeks or rate trimmings.
class CompanionSyncEngine {
  CompanionSyncEngine({
    this.microSeekThresholdMs = 100,
    this.hardSeekThresholdMs = 1500,
    required this.onSeek,
    required this.onAdjustRate,
  });

  final int microSeekThresholdMs;
  final int hardSeekThresholdMs;
  final SeekExecutionCallback onSeek;
  final RateAdjustmentCallback onAdjustRate;

  int _bluetoothOffsetMs = 0;
  int _lastSeekTimestamp = 0;
  double _smoothDriftMs = 0;
  bool _isLive = false;

  int get bluetoothOffsetMs => _bluetoothOffsetMs;
  double get smoothDriftMs => _smoothDriftMs;
  bool get isInSync => _smoothDriftMs.abs() <= microSeekThresholdMs;
  bool get isLive => _isLive;

  /// Sets manual audio offset (+/- ms) to compensate for Bluetooth headphone latency.
  void setBluetoothOffset(int offsetMs) {
    _bluetoothOffsetMs = offsetMs.clamp(-1000, 1000);
  }

  void setIsLive(bool isLive) {
    _isLive = isLive;
  }

  /// Processes a 500ms sync frame from the TV.
  Future<void> processSyncTick({
    required HandoffSyncPacket packet,
    required Duration localPhonePosition,
    required int estimatedRttMs,
    required bool isPhonePlaying,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final oneWayDelay = (estimatedRttMs / 2).round();

    // Adjusted TV playback position accounting for network delay and user BT headphone latency
    final targetTvPosMs = packet.positionMs + oneWayDelay + _bluetoothOffsetMs;
    final localPosMs = localPhonePosition.inMilliseconds;

    // Drift calculation: Positive means phone is BEHIND TV, Negative means phone is AHEAD of TV
    final rawDrift = targetTvPosMs - localPosMs;

    // Low-pass exponential smoothing filter on drift calculation
    _smoothDriftMs = (_smoothDriftMs * 0.6) + (rawDrift * 0.4);

    // If TV is paused, the companion controller already mirrored pause.
    if (!packet.isPlaying && isPhonePlaying) {
      return;
    }

    // Live / unbounded streams do not share a seekable timeline. Two independent
    // HLS/TS clients sit at their own live edges; seeking causes stutter and
    // desync instead of lip-sync. Bluetooth offset is applied as audio-delay.
    if (_isLive || packet.isLive || packet.durationMs <= 0) {
      _smoothDriftMs = 0;
      return;
    }

    final absDrift = _smoothDriftMs.abs();

    // In-sync zone: within +/- 100ms tolerance
    if (absDrift <= microSeekThresholdMs) {
      return;
    }

    // Rate-limit seeks to prevent decoder thrashing (min 1200ms between seeks)
    final timeSinceLastSeek = now - _lastSeekTimestamp;
    if (timeSinceLastSeek < 1200) {
      return;
    }

    _lastSeekTimestamp = now;

    if (absDrift >= hardSeekThresholdMs) {
      // Large drift: execute hard seek to immediately realign
      AppLogger.info(
        'Companion hard-aligning: drift=${_smoothDriftMs.round()}ms -> target=${targetTvPosMs}ms',
        feature: 'audio_handoff',
      );
      final target = Duration(milliseconds: targetTvPosMs.clamp(0, packet.durationMs > 0 ? packet.durationMs : targetTvPosMs));
      await onSeek(target);
    } else {
      // Micro-drift (100ms - 1500ms): execute micro-seek
      AppLogger.debug(
        'Companion micro-seeking: drift=${_smoothDriftMs.round()}ms -> target=${targetTvPosMs}ms',
        feature: 'audio_handoff',
      );
      final target = Duration(milliseconds: targetTvPosMs.clamp(0, packet.durationMs > 0 ? packet.durationMs : targetTvPosMs));
      await onSeek(target);
    }
  }

  void reset() {
    _smoothDriftMs = 0;
    _lastSeekTimestamp = 0;
  }
}
