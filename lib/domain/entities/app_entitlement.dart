import 'package:equatable/equatable.dart';

enum AccessStatus {
  none,
  trialing,
  active,
  gracePeriod,
  denied;

  static AccessStatus fromWire(String? value) {
    switch (value) {
      case 'none':
        return AccessStatus.none;
      case 'trialing':
        return AccessStatus.trialing;
      case 'active':
        return AccessStatus.active;
      case 'grace_period':
        return AccessStatus.gracePeriod;
      case 'denied':
        return AccessStatus.denied;
      default:
        return AccessStatus.denied;
    }
  }

  bool get allowsPremium =>
      this == AccessStatus.trialing ||
      this == AccessStatus.active ||
      this == AccessStatus.gracePeriod;
}

class SignedLease extends Equatable {
  const SignedLease({
    required this.payload,
    required this.signature,
    required this.keyId,
  });

  final String payload;
  final String signature;
  final String keyId;

  factory SignedLease.fromJson(Map<String, dynamic> json) {
    return SignedLease(
      payload: json['payload'] as String,
      signature: json['signature'] as String,
      keyId: json['keyId'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'payload': payload,
        'signature': signature,
        'keyId': keyId,
      };

  @override
  List<Object?> get props => [payload, signature, keyId];
}

class AppEntitlement extends Equatable {
  const AppEntitlement({
    required this.accessStatus,
    required this.accountStatus,
    required this.serverTime,
    required this.features,
    required this.deviceLimit,
    required this.minimumSupportedVersion,
    required this.reason,
    required this.refreshAfterSeconds,
    this.planCode,
    this.validUntil,
    this.lease,
  });

  final AccessStatus accessStatus;
  final String accountStatus;
  final DateTime serverTime;
  final Map<String, bool> features;
  final int deviceLimit;
  final String minimumSupportedVersion;
  final String reason;
  final int refreshAfterSeconds;
  final String? planCode;
  final DateTime? validUntil;
  final SignedLease? lease;

  bool get allowsPremium => accessStatus.allowsPremium;

  factory AppEntitlement.fromJson(Map<String, dynamic> json) {
    final featuresRaw = json['features'];
    final features = <String, bool>{};
    if (featuresRaw is Map) {
      featuresRaw.forEach((k, v) {
        if (v is bool) features['$k'] = v;
      });
    }

    SignedLease? lease;
    final leaseRaw = json['lease'];
    if (leaseRaw is Map) {
      lease = SignedLease.fromJson(Map<String, dynamic>.from(leaseRaw));
    }

    return AppEntitlement(
      accessStatus: AccessStatus.fromWire(json['accessStatus'] as String?),
      accountStatus: (json['accountStatus'] as String?) ?? 'active',
      serverTime: DateTime.tryParse(json['serverTime'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      features: features,
      deviceLimit: (json['deviceLimit'] as num?)?.toInt() ?? 3,
      minimumSupportedVersion:
          (json['minimumSupportedVersion'] as String?) ?? '0.1.0',
      reason: (json['reason'] as String?) ?? 'unknown',
      refreshAfterSeconds: (json['refreshAfterSeconds'] as num?)?.toInt() ?? 3600,
      planCode: json['planCode'] as String?,
      validUntil: DateTime.tryParse(json['validUntil'] as String? ?? '')?.toUtc(),
      lease: lease,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessStatus': accessStatus.name == 'gracePeriod'
            ? 'grace_period'
            : accessStatus.name,
        'accountStatus': accountStatus,
        'serverTime': serverTime.toIso8601String(),
        'features': features,
        'deviceLimit': deviceLimit,
        'minimumSupportedVersion': minimumSupportedVersion,
        'reason': reason,
        'refreshAfterSeconds': refreshAfterSeconds,
        'planCode': planCode,
        'validUntil': validUntil?.toIso8601String(),
        'lease': lease?.toJson(),
      };

  @override
  List<Object?> get props => [
        accessStatus,
        accountStatus,
        serverTime,
        features,
        deviceLimit,
        minimumSupportedVersion,
        reason,
        refreshAfterSeconds,
        planCode,
        validUntil,
        lease,
      ];
}
