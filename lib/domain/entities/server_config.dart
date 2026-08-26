import 'package:equatable/equatable.dart';

class ServerConfig extends Equatable {
  const ServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  final String serverUrl;
  final String username;
  final String password;

  bool get isValid =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  @override
  List<Object?> get props => [serverUrl, username, password];
}
