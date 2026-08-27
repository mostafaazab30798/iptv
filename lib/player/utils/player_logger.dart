import 'package:iptv/core/logging/app_logger.dart';

/// Structured, sanitized logging for the IPTV playback subsystem.
///
/// Guarantees that credentials, tokens, and raw private URLs are never leaked in logs.
class PlayerLogger {
  const PlayerLogger._();

  /// Matches http(s) URLs in free-form log text (stops at whitespace / brackets / quotes).
  static final RegExp _urlInText = RegExp(
    r'https?://[^\s<>\[\](){}]+',
    caseSensitive: false,
  );

  static const _pathAuthKinds = {
    'live',
    'movie',
    'movies',
    'series',
    'timeshift',
  };

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
    final safe = sanitizeMessage(message ?? '');
    AppLogger.error(
      '[Player] error type=$errorType message="$safe"',
      feature: 'player',
    );
  }

  static void note(String message) {
    AppLogger.debug('[Player] ${sanitizeMessage(message)}', feature: 'player');
  }

  static void dispose() {
    AppLogger.info('[Player] dispose', feature: 'player');
  }

  /// Masks credentials embedded in free-form error / note text.
  static String sanitizeMessage(String message) {
    if (message.isEmpty) return message;
    return message.replaceAllMapped(
      _urlInText,
      (match) => sanitizeUrl(match.group(0)!),
    );
  }

  /// Sanitizes any URL before logging by masking credentials and tokens.
  ///
  /// Covers query secrets, URI userInfo, nested proxy `url=` params, and
  /// Xtream path-auth (`/live|movie|series|timeshift/<user>/<pass>/...`).
  static String sanitizeUrl(String url) {
    try {
      // Strip trailing punctuation commonly glued onto URLs in error strings.
      final cleaned = url.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
      final uri = Uri.parse(cleaned);

      final queryParams = Map<String, String>.from(uri.queryParameters);
      for (final key in queryParams.keys.toList()) {
        final lower = key.toLowerCase();
        if (lower == 'url' || lower == 'src' || lower == 'uri') {
          queryParams[key] = sanitizeUrl(queryParams[key]!);
          continue;
        }
        if (lower.contains('pass') ||
            lower.contains('token') ||
            lower.contains('auth') ||
            lower.contains('secret') ||
            lower == 'username' ||
            lower == 'user') {
          queryParams[key] = '***';
        }
      }

      final segments = List<String>.from(uri.pathSegments);
      for (var i = 0; i < segments.length - 2; i++) {
        if (_pathAuthKinds.contains(segments[i].toLowerCase())) {
          segments[i + 1] = '***';
          segments[i + 2] = '***';
          break;
        }
      }

      final path = segments.isEmpty ? '' : '/${segments.join('/')}';
      final query = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
      final auth = uri.userInfo.isNotEmpty ? '***:***@' : '';
      final port = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://$auth${uri.host}$port$path$query';
    } catch (_) {
      return '<masked-url>';
    }
  }
}
