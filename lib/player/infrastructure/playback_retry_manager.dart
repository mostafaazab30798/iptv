import 'dart:async';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/utils/player_logger.dart';

/// Manages bounded retry attempts with exponential backoff for playback recovery.
class PlaybackRetryManager {
  PlaybackRetryManager({
    this.maxRetries = 4,
    this.initialDelay = const Duration(milliseconds: 2000),
    this.maxDelay = const Duration(milliseconds: 15000),
  });

  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;

  int _retryCount = 0;
  Timer? _pendingRetryTimer;

  int get retryCount => _retryCount;
  bool get canRetry => _retryCount < maxRetries;

  /// Resets the retry counter on successful playback (first frame).
  void reset() {
    _pendingRetryTimer?.cancel();
    _pendingRetryTimer = null;
    _retryCount = 0;
  }

  /// Calculates the next delay with bounded exponential backoff.
  Duration getNextDelay() {
    final factor = 1 << _retryCount; // 1, 2, 4
    final delayMs = initialDelay.inMilliseconds * factor;
    final capped = delayMs > maxDelay.inMilliseconds ? maxDelay.inMilliseconds : delayMs;
    return Duration(milliseconds: capped);
  }

  /// Schedules an automatic retry callback if error is retryable and within retry limit.
  bool scheduleRetry({
    required PlayerErrorType errorType,
    required Future<void> Function() onExecuteRetry,
    required void Function(Duration delay, int attempt) onRetryScheduled,
  }) {
    _pendingRetryTimer?.cancel();

    if (!errorType.isRetryable || !canRetry) {
      return false;
    }

    final delay = getNextDelay();
    _retryCount++;
    PlayerLogger.retry(_retryCount, delay);
    onRetryScheduled(delay, _retryCount);

    _pendingRetryTimer = Timer(delay, () async {
      try {
        await onExecuteRetry();
      } catch (_) {}
    });

    return true;
  }

  /// Cancels any scheduled retry.
  void cancel() {
    _pendingRetryTimer?.cancel();
    _pendingRetryTimer = null;
  }
}
