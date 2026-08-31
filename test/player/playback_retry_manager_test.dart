import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/infrastructure/playback_retry_manager.dart';

void main() {
  group('PlaybackRetryManager', () {
    test('calculates exponential backoff delay correctly', () {
      final manager = PlaybackRetryManager(
        maxRetries: 3,
        initialDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(milliseconds: 4000),
      );

      expect(manager.canRetry, isTrue);
      expect(manager.retryCount, equals(0));

      // Attempt 1: factor 1 => 500ms
      expect(manager.getNextDelay(), equals(const Duration(milliseconds: 500)));

      manager.scheduleRetry(
        errorType: PlayerErrorType.networkUnavailable,
        onExecuteRetry: () async {},
        onRetryScheduled: (delay, attempt) {},
      );

      expect(manager.retryCount, equals(1));
      // Attempt 2: factor 2 => 1000ms
      expect(manager.getNextDelay(), equals(const Duration(milliseconds: 1000)));

      manager.scheduleRetry(
        errorType: PlayerErrorType.timeout,
        onExecuteRetry: () async {},
        onRetryScheduled: (delay, attempt) {},
      );

      expect(manager.retryCount, equals(2));
      // Attempt 3: factor 4 => 2000ms
      expect(manager.getNextDelay(), equals(const Duration(milliseconds: 2000)));

      manager.scheduleRetry(
        errorType: PlayerErrorType.playbackFailure,
        onExecuteRetry: () async {},
        onRetryScheduled: (delay, attempt) {},
      );

      expect(manager.retryCount, equals(3));
      expect(manager.canRetry, isFalse);
    });

    test('refuses to retry non-retryable authentication or invalid source errors', () {
      final manager = PlaybackRetryManager();

      final scheduledUnauthorized = manager.scheduleRetry(
        errorType: PlayerErrorType.unauthorized,
        onExecuteRetry: () async {},
        onRetryScheduled: (delay, attempt) {},
      );

      expect(scheduledUnauthorized, isFalse);
      expect(manager.retryCount, equals(0));

      final scheduledInvalid = manager.scheduleRetry(
        errorType: PlayerErrorType.invalidSource,
        onExecuteRetry: () async {},
        onRetryScheduled: (delay, attempt) {},
      );

      expect(scheduledInvalid, isFalse);
      expect(manager.retryCount, equals(0));
    });

    test('cancel() clears pending timer so isRetrying becomes false', () {
      final manager = PlaybackRetryManager(
        initialDelay: const Duration(seconds: 30),
      );

      final scheduled = manager.scheduleRetry(
        errorType: PlayerErrorType.networkUnavailable,
        onExecuteRetry: () async {},
        onRetryScheduled: (_, _) {},
      );

      expect(scheduled, isTrue);
      expect(manager.isRetrying, isTrue);

      manager.cancel();
      expect(manager.isRetrying, isFalse);
      expect(manager.retryCount, equals(1));
    });
  });
}
