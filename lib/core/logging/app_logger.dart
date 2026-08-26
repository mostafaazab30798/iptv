import 'package:logger/logger.dart';

/// Structured logging abstraction.
///
/// Always use this instead of [print] or direct [Logger] calls.
/// Automatically redacts sensitive fields and includes context tags.
///
/// Usage:
/// ```dart
/// AppLogger.info('Channels loaded', feature: 'live', data: {'count': 42});
/// AppLogger.error('Playback failed', feature: 'player', error: e);
/// ```
class AppLogger {
  AppLogger._();

  static late final Logger _logger;
  static bool _initialized = false;

  static void initialize({bool verbose = false}) {
    if (_initialized) return;
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 100,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: verbose ? Level.trace : Level.info,
      output: ConsoleOutput(),
    );
    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static void debug(
    String message, {
    String? feature,
    String? operation,
    Map<String, Object?>? data,
  }) {
    _log(Level.debug, message, feature: feature, operation: operation, data: data);
  }

  static void info(
    String message, {
    String? feature,
    String? operation,
    Map<String, Object?>? data,
  }) {
    _log(Level.info, message, feature: feature, operation: operation, data: data);
  }

  static void warning(
    String message, {
    String? feature,
    String? operation,
    Map<String, Object?>? data,
    Object? error,
  }) {
    _log(Level.warning, message,
        feature: feature, operation: operation, data: data, error: error);
  }

  static void error(
    String message, {
    String? feature,
    String? operation,
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(Level.error, message,
        feature: feature,
        operation: operation,
        data: data,
        error: error,
        stackTrace: stackTrace);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static void _log(
    Level level,
    String message, {
    String? feature,
    String? operation,
    Map<String, Object?>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_initialized) return;

    final context = <String, Object?>{
      'feature': ?feature,
      'op': ?operation,
      if (data != null) ..._redact(data),
    };

    final contextStr = context.isEmpty ? '' : ' $context';
    _logger.log(
      level,
      '$message$contextStr',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Redacts known sensitive keys so they never appear in logs.
  static Map<String, Object?> _redact(Map<String, Object?> data) {
    const sensitiveKeys = {
      'password',
      'token',
      'secret',
      'credentials',
      'auth',
      'key',
      'url',   // full URLs may contain credentials
    };
    return {
      for (final entry in data.entries)
        entry.key: sensitiveKeys.contains(entry.key.toLowerCase())
            ? '***'
            : entry.value,
    };
  }
}
