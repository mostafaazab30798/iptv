/// Classified playback error categories.
enum PlayerErrorType {
  networkUnavailable,
  timeout,
  serverUnavailable,
  unauthorized,
  invalidSource,
  unsupportedFormat,
  codecError,
  playbackFailure,
  unknown;

  /// Whether a bounded retry could potentially recover from this error.
  bool get isRetryable => switch (this) {
        PlayerErrorType.networkUnavailable => true,
        PlayerErrorType.timeout => true,
        PlayerErrorType.serverUnavailable => true,
        PlayerErrorType.playbackFailure => true,
        PlayerErrorType.unauthorized => false,
        PlayerErrorType.invalidSource => false,
        PlayerErrorType.unsupportedFormat => true,
        PlayerErrorType.codecError => false,
        PlayerErrorType.unknown => true,
      };

  String get defaultMessage => switch (this) {
        PlayerErrorType.networkUnavailable => 'Network connection lost. Please check your internet.',
        PlayerErrorType.timeout => 'Stream connection timed out.',
        PlayerErrorType.serverUnavailable => 'IPTV stream server is currently unreachable.',
        PlayerErrorType.unauthorized => 'Access denied. Please check your subscription credentials.',
        PlayerErrorType.invalidSource => 'Invalid or expired stream URL.',
        PlayerErrorType.unsupportedFormat => 'This stream format is not supported on this device.',
        PlayerErrorType.codecError => 'Device codec error encountered during playback.',
        PlayerErrorType.playbackFailure => 'Playback interrupted unexpectedly.',
        PlayerErrorType.unknown => 'An unexpected playback error occurred.',
      };
}
