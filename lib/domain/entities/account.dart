import 'package:equatable/equatable.dart';

class Account extends Equatable {
  const Account({
    required this.id,
    required this.serverUrl,
    required this.username,
    this.displayName,
    this.isActive = false,
    required this.createdAt,
  });

  final int id;
  final String serverUrl;
  final String username;
  final String? displayName;
  final bool isActive;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, serverUrl, username];
}
