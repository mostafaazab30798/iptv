import 'package:equatable/equatable.dart';

class AppDevice extends Equatable {
  const AppDevice({
    required this.id,
    required this.displayName,
    required this.platform,
    this.appVersion,
    this.osVersionCategory,
    this.firstSeenAt,
    this.lastSeenAt,
    this.revokedAt,
  });

  final String id;
  final String displayName;
  final String platform;
  final String? appVersion;
  final String? osVersionCategory;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;

  factory AppDevice.fromJson(Map<String, dynamic> json) {
    return AppDevice(
      id: json['id'] as String,
      displayName: (json['displayName'] as String?) ?? 'Device',
      platform: (json['platform'] as String?) ?? 'unknown',
      appVersion: json['appVersion'] as String?,
      osVersionCategory: json['osVersionCategory'] as String?,
      firstSeenAt: _parseTime(json['firstSeenAt']),
      lastSeenAt: _parseTime(json['lastSeenAt']),
      revokedAt: _parseTime(json['revokedAt']),
    );
  }

  static DateTime? _parseTime(Object? value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toUtc();
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        displayName,
        platform,
        appVersion,
        osVersionCategory,
        firstSeenAt,
        lastSeenAt,
        revokedAt,
      ];
}
