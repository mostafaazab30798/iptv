import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/identity/trusted_time_service.dart';
import 'package:iptv/core/security/signed_payload_verifier.dart';
import 'package:iptv/domain/entities/app_entitlement.dart';
import 'package:iptv/domain/repositories/entitlement_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class EntitlementRepositoryImpl implements EntitlementRepository {
  EntitlementRepositoryImpl({
    required TrustedTimeService trustedTime,
    CommercialEdgeFunctionsClient? edgeClient,
    SignedPayloadVerifier? verifier,
    FlutterSecureStorage? storage,
  })  : _trustedTime = trustedTime,
        _edge = edgeClient ?? CommercialEdgeFunctionsClient(),
        _verifier = verifier ?? SignedPayloadVerifier(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              wOptions: WindowsOptions(),
              webOptions: WebOptions(dbName: 'hope_tv_entitlement_vault'),
            );

  final TrustedTimeService _trustedTime;
  final CommercialEdgeFunctionsClient _edge;
  final SignedPayloadVerifier _verifier;
  final FlutterSecureStorage _storage;

  static const _cacheKey = 'hope_tv_entitlement_cache_v1';

  @override
  Future<AppEntitlement> refresh({required String deviceId}) async {
    final payload = await _edge.invoke(
      'entitlement',
      method: HttpMethod.post,
      body: {'deviceId': deviceId},
    );
    final entitlement = AppEntitlement.fromJson(payload);
    await _trustedTime.observeServerTime(entitlement.serverTime);
    await _storage.write(key: _cacheKey, value: jsonEncode(entitlement.toJson()));
    return entitlement;
  }

  @override
  Future<AppEntitlement?> loadCached() async {
    final raw = await _storage.read(key: _cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppEntitlement.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    await _storage.delete(key: _cacheKey);
    await _trustedTime.clear();
  }

  @override
  Future<void> activateTrial({
    required String deviceId,
    required String idempotencyKey,
    String? platform,
  }) async {
    await _edge.invoke(
      'trial-activate',
      method: HttpMethod.post,
      body: {
        'idempotencyKey': idempotencyKey,
        'deviceId': deviceId,
        'platform': platform ?? 'unknown',
        'event': 'iptv_connection_succeeded',
      },
    );
  }

  @override
  Future<AppEntitlement?> evaluateOfflineLease({required String deviceId}) async {
    final cached = await loadCached();
    final lease = cached?.lease;
    if (cached == null || lease == null) return null;

    final now = await _trustedTime.nowUtc();
    try {
      final claims = await _verifier.verifyLease(
        payloadB64Url: lease.payload,
        signatureB64Url: lease.signature,
        keyId: lease.keyId,
        expectedDeviceId: deviceId,
        nowUtc: now,
      );
      final status = AccessStatus.fromWire(claims['accessStatus'] as String?);
      if (!status.allowsPremium) return null;
      return AppEntitlement(
        accessStatus: status,
        accountStatus: cached.accountStatus,
        serverTime: now,
        features: Map<String, bool>.from(
          (claims['features'] as Map?)?.map((k, v) => MapEntry('$k', v == true)) ??
              cached.features,
        ),
        deviceLimit: cached.deviceLimit,
        minimumSupportedVersion: cached.minimumSupportedVersion,
        reason: 'offline_lease',
        refreshAfterSeconds: cached.refreshAfterSeconds,
        planCode: cached.planCode,
        validUntil: DateTime.fromMillisecondsSinceEpoch(
          (claims['exp'] as num).toInt() * 1000,
          isUtc: true,
        ),
        lease: lease,
      );
    } on LeaseVerificationException {
      return null;
    }
  }
}

/// Helpers for idempotent trial activation keys.
String newTrialIdempotencyKey() => const Uuid().v4();
