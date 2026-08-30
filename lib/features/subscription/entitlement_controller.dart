import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/data/repositories/device_repository_impl.dart';
import 'package:iptv/data/repositories/entitlement_repository_impl.dart';
import 'package:iptv/domain/entities/app_entitlement.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';
import 'package:iptv/domain/repositories/device_repository.dart';
import 'package:iptv/domain/repositories/entitlement_repository.dart';

class EntitlementState {
  const EntitlementState({
    required this.loading,
    this.entitlement,
    this.errorMessage,
    this.offline = false,
  });

  final bool loading;
  final AppEntitlement? entitlement;
  final String? errorMessage;
  final bool offline;

  bool get allowsPremium => entitlement?.allowsPremium ?? false;

  EntitlementState copyWith({
    bool? loading,
    AppEntitlement? entitlement,
    String? errorMessage,
    bool? offline,
    bool clearEntitlement = false,
    bool clearError = false,
  }) {
    return EntitlementState(
      loading: loading ?? this.loading,
      entitlement: clearEntitlement ? null : (entitlement ?? this.entitlement),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      offline: offline ?? this.offline,
    );
  }
}

class EntitlementController extends StateNotifier<EntitlementState> {
  EntitlementController({
    required EntitlementRepository entitlementRepository,
    required DeviceRepository deviceRepository,
    required InstallationIdentity installationIdentity,
    AnalyticsRepository? analyticsRepository,
  })  : _entitlements = entitlementRepository,
        _devices = deviceRepository,
        _identity = installationIdentity,
        _analytics = analyticsRepository,
        super(const EntitlementState(loading: false));

  final EntitlementRepository _entitlements;
  final DeviceRepository _devices;
  final InstallationIdentity _identity;
  final AnalyticsRepository? _analytics;

  Future<String?> _deviceId() async {
    if (_devices is DeviceRepositoryImpl) {
      final id = await _devices.currentDeviceId();
      if (id != null) return id;
    }
    try {
      return await _devices.registerCurrentDevice();
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh({bool allowOfflineFallback = true}) async {
    if (!CommercialApiConfig.isConfigured) {
      state = const EntitlementState(loading: false);
      return;
    }

    state = state.copyWith(loading: true, clearError: true);
    final deviceId = await _deviceId();
    if (deviceId == null) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Device registration required.',
        clearEntitlement: true,
      );
      return;
    }

    try {
      final entitlement = await _entitlements.refresh(deviceId: deviceId);
      state = EntitlementState(
        loading: false,
        entitlement: entitlement,
        offline: false,
      );
      if (entitlement.allowsPremium) {
        unawaited(_analytics?.track(AnalyticsEventName.entitlementRefreshed));
      } else {
        unawaited(_analytics?.track(AnalyticsEventName.entitlementDenied));
      }
    } catch (e) {
      AppLogger.error('Entitlement refresh failed: $e', feature: 'entitlement');
      if (allowOfflineFallback) {
        final offline = await _entitlements.evaluateOfflineLease(deviceId: deviceId);
        if (offline != null) {
          state = EntitlementState(
            loading: false,
            entitlement: offline,
            offline: true,
          );
          return;
        }
      }
      state = state.copyWith(
        loading: false,
        errorMessage: e.toString(),
        clearEntitlement: true,
      );
    }
  }

  Future<void> activateTrialAfterIptvSuccess() async {
    if (!CommercialApiConfig.isConfigured) return;
    final deviceId = await _deviceId();
    if (deviceId == null) {
      throw StateError('Device id missing for trial activation.');
    }
    await _entitlements.activateTrial(
      deviceId: deviceId,
      idempotencyKey: newTrialIdempotencyKey(),
      platform: _identity.platformCode(),
    );
    unawaited(_analytics?.track(AnalyticsEventName.trialStarted));
    await refresh(allowOfflineFallback: false);
  }

  Future<void> clear() async {
    await _entitlements.clearCache();
    state = const EntitlementState(loading: false);
  }
}
