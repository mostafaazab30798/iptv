import 'package:equatable/equatable.dart';

class ServerConfig extends Equatable {
  const ServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.expiresAt,
  });

  final String serverUrl;
  final String username;
  final String password;
  final DateTime? expiresAt;

  bool get hasCredentials =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !expiry.isAfter(now.toUtc());
  }

  bool get isExpired => isExpiredAt(DateTime.now());

  /// Expired credentials must never enter catalog routes. Those routes can
  /// otherwise remain on loading/error UI and strand the user away from the
  /// account switch and disconnect actions.
  bool get isValid => hasCredentials && !isExpired;

  @override
  List<Object?> get props => [serverUrl, username, password, expiresAt];
}
