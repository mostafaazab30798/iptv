/// Unified application error hierarchy.
///
/// All errors flowing through the app should be one of these sealed subtypes.
/// The UI translates them to user-friendly messages; raw stack traces never
/// reach the user.
sealed class AppError {
  const AppError({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

// ---------------------------------------------------------------------------
// Network errors
// ---------------------------------------------------------------------------

final class NetworkError extends AppError {
  const NetworkError({required super.message, super.cause});
}

final class TimeoutError extends AppError {
  const TimeoutError({required super.message, super.cause});
}

final class ServerError extends AppError {
  const ServerError({
    required super.message,
    required this.statusCode,
    super.cause,
  });

  final int statusCode;
}

// ---------------------------------------------------------------------------
// Auth errors
// ---------------------------------------------------------------------------

final class AuthenticationError extends AppError {
  const AuthenticationError({required super.message, super.cause});
}

final class SessionExpiredError extends AppError {
  const SessionExpiredError({
    super.message = 'Session expired. Please sign in again.',
    super.cause,
  });
}

// ---------------------------------------------------------------------------
// Data errors
// ---------------------------------------------------------------------------

final class ParsingError extends AppError {
  const ParsingError({required super.message, super.cause});
}

final class DatabaseError extends AppError {
  const DatabaseError({required super.message, super.cause});
}

// ---------------------------------------------------------------------------
// Media / player errors
// ---------------------------------------------------------------------------

final class PlaybackError extends AppError {
  const PlaybackError({
    required super.message,
    this.code,
    super.cause,
  });

  final int? code;
}

final class StreamUnavailableError extends AppError {
  const StreamUnavailableError({
    super.message = 'Stream is currently unavailable.',
    super.cause,
  });
}

// ---------------------------------------------------------------------------
// Platform errors
// ---------------------------------------------------------------------------

final class UnsupportedPlatformError extends AppError {
  const UnsupportedPlatformError({required super.message, super.cause});
}

// ---------------------------------------------------------------------------
// Generic / unexpected errors
// ---------------------------------------------------------------------------

final class UnknownError extends AppError {
  const UnknownError({
    super.message = 'An unexpected error occurred.',
    super.cause,
  });
}
