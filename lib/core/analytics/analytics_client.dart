import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/core/analytics/analytics_policy.dart';
import 'package:iptv/core/analytics/analytics_queue.dart';
import 'package:iptv/core/analytics/installation_marker.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/commercial/supabase_client_factory.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Non-blocking analytics client with batching and foreground heartbeat.
///
/// ## Ordering contract
/// 1. Call [start] as early as possible after sign-in.
/// 2. Call [updateDeviceId] once device registration completes.
///    The first meaningful heartbeat fires automatically at that point.
/// 3. Heartbeats are suppressed until a non-null device ID is known.
class AnalyticsClient with WidgetsBindingObserver {
  AnalyticsClient({
    AnalyticsQueue? queue,
    InstallationIdentity? identity,
    InstallationMarker? marker,
    CommercialEdgeFunctionsClient? api,
  })  : _queue = queue ?? AnalyticsQueue(),
        _identity = identity ?? InstallationIdentity(),
        _marker = marker ?? InstallationMarker(),
        _api = api ?? CommercialEdgeFunctionsClient();

  final AnalyticsQueue _queue;
  final InstallationIdentity _identity;
  final InstallationMarker _marker;
  final CommercialEdgeFunctionsClient _api;
  static const _uuid = Uuid();

  Timer? _flushTimer;
  Timer? _heartbeatTimer;
  bool _foreground = true;
  bool _started = false;
  bool _firstHeartbeatSent = false;
  String? _sessionId;
  String? _deviceId;
  String? _platform;
  String? _appVersion;
  String? _installationHash;

  /// Starts the analytics client.
  ///
  /// [deviceId] is optional here — if device registration hasn't completed
  /// yet, call [updateDeviceId] once it does.
  Future<void> start({String? deviceId}) async {
    if (_started) return;
    _started = true;
    _deviceId = deviceId;
    WidgetsBinding.instance.addObserver(this);
    await _queue.init();
    _platform = _identity.platformCode();
    _appVersion = AppConstants.appVersion;
    _installationHash = await _identity.getInstallationIdHash();
    _flushTimer = Timer.periodic(
      const Duration(seconds: AnalyticsPolicy.flushIntervalSeconds),
      (_) => unawaited(flush()),
    );
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: AnalyticsPolicy.heartbeatIntervalSeconds),
      (_) => unawaited(_sendHeartbeat(meaningful: _foreground)),
    );

    // app_first_open: once per installation (durable, survives restarts).
    final isFirst = await _marker.claimFirstOpen();
    if (isFirst) {
      await track(AnalyticsEventName.appFirstOpen);
    }

    // app_updated: once per newly observed version.
    final currentVersion = _appVersion ?? '';
    if (currentVersion.isNotEmpty) {
      final previousVersion = await _marker.claimVersionChange(currentVersion);
      if (previousVersion != null) {
        await track(
          AnalyticsEventName.appUpdated,
          properties: {
            'previous_version': previousVersion,
          },
        );
      }
    }

    // If we already have a device ID, fire the first heartbeat immediately.
    if (_deviceId != null) {
      unawaited(_sendHeartbeat(meaningful: _foreground));
    }
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _flushTimer?.cancel();
    _heartbeatTimer?.cancel();
    _firstHeartbeatSent = false;
    await track(AnalyticsEventName.sessionEnded);
    await flush();
  }

  /// Updates the device ID and fires the first heartbeat if not yet sent.
  ///
  /// Call this when device registration completes after [start] was called
  /// without a device ID.
  void updateDeviceId(String? deviceId) {
    final hadDevice = _deviceId != null;
    _deviceId = deviceId;
    // If we now have a device ID for the first time, fire the first heartbeat.
    if (!hadDevice && deviceId != null && _started && !_firstHeartbeatSent) {
      unawaited(_sendHeartbeat(meaningful: _foreground));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      unawaited(flush());
    } else if (_deviceId != null) {
      // Re-entering foreground: send a heartbeat promptly.
      unawaited(_sendHeartbeat(meaningful: true));
    }
  }

  Future<void> track(
    AnalyticsEventName name, {
    Map<String, Object?> properties = const {},
  }) async {
    if (!CommercialApiConfig.isConfigured) return;

    final safeProps = <String, Object?>{};
    for (final entry in properties.entries) {
      if (AnalyticsPolicy.isPropertyAllowed(entry.key, entry.value)) {
        safeProps[entry.key] = entry.value;
      }
    }

    await _queue.enqueue(AnalyticsEvent(
      eventId: _uuid.v4(),
      name: name,
      occurredAt: DateTime.now().toUtc(),
      platform: _platform,
      appVersion: _appVersion,
      installationIdHash: _installationHash,
      properties: safeProps,
    ));

    if (name == AnalyticsEventName.sessionStarted) {
      unawaited(_sendHeartbeat(meaningful: true));
    }
  }

  Future<void> flush() async {
    if (!CommercialApiConfig.isConfigured) return;
    final batch = _queue.drainBatch();
    if (batch.isEmpty) return;

    try {
      await _api.invoke(
        'analytics-batch',
        method: HttpMethod.post,
        body: {
          'events': batch.map((e) => e.toJson()).toList(),
        },
        requireSession: false,
      );
    } catch (e) {
      AppLogger.error('Analytics flush failed: $e', feature: 'analytics');
      if (e is! CommercialApiException || e.status >= 500) {
        for (final event in batch) {
          await _queue.enqueue(event);
        }
      }
    }
  }

  Future<void> _sendHeartbeat({required bool meaningful}) async {
    if (!CommercialApiConfig.isConfigured || _deviceId == null) return;
    // Only send meaningful heartbeats when foregrounded.
    if (meaningful && !_foreground) return;

    // Heartbeats are tied to an authenticated account session on the backend.
    final ok = await SupabaseClientFactory.ensureInitialized();
    if (!ok || SupabaseClientFactory.client.auth.currentSession == null) {
      return;
    }

    try {
      final response = await _api.invoke(
        'session-heartbeat',
        method: HttpMethod.post,
        body: {
          'deviceId': _deviceId,
          if (_sessionId != null) 'sessionId': _sessionId,
          'platform': _platform,
          'appVersion': _appVersion,
          'installationIdHash': _installationHash,
          'meaningful': meaningful,
        },
      );
      final sid = response['sessionId'];
      if (sid is String) _sessionId = sid;
      _firstHeartbeatSent = true;
    } catch (e) {
      AppLogger.error('Heartbeat failed: $e', feature: 'analytics');
    }
  }
}