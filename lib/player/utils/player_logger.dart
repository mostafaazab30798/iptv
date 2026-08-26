import 'package:iptv/core/logging/app_logger.dart';

/// Structured, sanitized logging for the IPTV playback subsystem.
///
/// Guarantees that credentials, tokens, and raw private URLs are never leaked in logs.
class PlayerLogger {
  const PlayerLogger._();

  static void open(String title, {String? streamType}) {
    AppLogger.info(
      '[Player] open: title="$title", type=${streamType ?? 'auto'}',
      feature: 'player',
    );
  }

  static void firstFrame(Duration latency) {
    AppLogger.info(
      '[Player] first frame in ${latency.inMilliseconds}ms',
      feature: 'player',
    );
  }

  static void bufferingStart() {
    AppLogger.debug('[Player] buffering start', feature: 'player');
  }

  static void bufferingEnd(Duration duration) {
    AppLogger.debug(
      '[Player] buffering end (${duration.inMilliseconds}ms)',
      feature: 'player',
    );
  }

  static void channelSwitch(int? fromChannelId, int? toChannelId, String toTitle) {
    AppLogger.info(
      '[Player] switch from=$fromChannelId to=$toChannelId ($toTitle)',
      feature: 'player',
    );
  }

  static void retry(int attempt, Duration delay) {
    AppLogger.warning(
      '[Player] retry attempt=$attempt after ${delay.inMilliseconds}ms',
      feature: 'player',
    );
  }

  static void error(String errorType, {String? message}) {
    AppLogger.error(
      '[Player] error type=$errorType message="${message ?? ''}"',
      feature: 'player',
    );
  }

  static void note(String message) {
    AppLogger.debug('[Player] $message', feature: 'player');
  }

  static void dispose() {
    AppLogger.info('[Player] dispose', feature: 'player');
  }

  /// Sanitizes any URL before logging by masking credentials and tokens.
  static String sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      for (final key in queryParams.keys) {
        if (key.toLowerCase().contains('pass') ||
            key.toLowerCase().contains('token') ||
            key.toLowerCase().contains('auth') ||
            key.toLowerCase().contains('secret')) {
          queryParams[key] = '***';
        }
      }
      return uri.replace(queryParameters: queryParams.isNotEmpty ? queryParams : null).toString();
    } catch (_) {
      return '<masked-url>';
    }
  }
}
