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

  bool get isValid =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  @override
  List<Object?> get props => [serverUrl, username, password, expiresAt];
}
