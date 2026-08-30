import 'package:iptv/domain/entities/app_entitlement.dart';

abstract class EntitlementRepository {
  Future<AppEntitlement> refresh({required String deviceId});

  Future<AppEntitlement?> loadCached();

  Future<void> clearCache();

  /// Activate trial after IPTV connection succeeds (credential-free).
  Future<void> activateTrial({
    required String deviceId,
    required String idempotencyKey,
    String? platform,
  });

  /// Evaluate cached lease offline; returns null if unavailable/invalid.
  Future<AppEntitlement?> evaluateOfflineLease({required String deviceId});
}
