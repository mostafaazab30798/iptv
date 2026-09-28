import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/features/secure_connection/data/secure_route_diagnostics.dart';
import 'package:iptv/features/secure_connection/data/warp_platform_service.dart';
import 'package:iptv/features/secure_connection/domain/secure_connection_state.dart';

typedef PendingSecureRetry = Future<void> Function();

/// Coordinates WARP hand-off, route verification, and exact-action retry.
final class SecureConnectionController
    extends StateNotifier<SecureConnectionState> {
  SecureConnectionController({
    required WarpPlatformService warp,
    required SecureRouteDiagnostics diagnostics,
    PreferencesStorage? preferences,
    Future<void> Function(Duration duration)? delay,
  }) : _warp = warp,
       _diagnostics = diagnostics,
       _preferences = preferences,
       _delay = delay ?? Future<void>.delayed,
       super(const SecureConnectionState());

  static const int _maximumRetryAttempts = 2;
  static const Duration _resumeSettleDelay = Duration(milliseconds: 750);

  final WarpPlatformService _warp;
  final SecureRouteDiagnostics _diagnostics;
  final PreferencesStorage? _preferences;
  final Future<void> Function(Duration duration) _delay;

  Uri? _pendingEndpoint;
  Map<String, String> _pendingHeaders = const {};
  PendingSecureRetry? _pendingRetry;
  bool _resuming = false;

  /// Starts the flow only after the user explicitly requests it.
  Future<void> start({
    required Uri endpoint,
    required PendingSecureRetry retry,
    Map<String, String> headers = const {},
  }) async {
    _pendingEndpoint = endpoint;
    _pendingHeaders = Map.unmodifiable(headers);
    _pendingRetry = retry;
    state = const SecureConnectionState(
      phase: SecureConnectionPhase.checkingWarp,
    );
    await _preferences?.setSecureConnectionEnabledByUser(true);

    final installed = await _warp.isInstalled();
    if (!mounted) return;
    if (!installed) {
      state = state.copyWith(phase: SecureConnectionPhase.warpNotInstalled);
      return;
    }
    await openWarp();
  }

  /// Opens the official store listing after a user gesture.
  Future<void> installWarp() async {
    try {
      await _warp.openStore();
      if (!mounted) return;
      state = state.copyWith(
        phase: SecureConnectionPhase.waitingForInstallation,
      );
    } on MissingPluginException {
      if (!mounted) return;
      state = state.copyWith(phase: SecureConnectionPhase.secureRouteFailed);
    } on PlatformException {
      if (!mounted) return;
      state = state.copyWith(phase: SecureConnectionPhase.secureRouteFailed);
    }
  }

  /// Opens WARP once per flow after a user gesture.
  Future<void> openWarp() async {
    state = state.copyWith(phase: SecureConnectionPhase.openingWarp);
    final opened = await _warp.openWarp();
    if (!mounted) return;
    if (!opened) {
      await installWarp();
      return;
    }
    state = state.copyWith(
      phase: SecureConnectionPhase.waitingForWarp,
      launchAttempts: state.launchAttempts + 1,
    );
  }

  /// Re-checks installation or verifies the secure route after app resume.
  Future<void> onAppResumed() async {
    if (_resuming || !mounted) return;
    final phase = state.phase;
    if (phase == SecureConnectionPhase.waitingForInstallation) {
      final installed = await _warp.isInstalled();
      if (mounted && installed) {
        state = state.copyWith(phase: SecureConnectionPhase.warpInstalled);
      }
      return;
    }
    if (phase != SecureConnectionPhase.waitingForWarp) return;
    await _verifyRoute();
  }

  /// Re-tests without foregrounding another application.
  Future<void> verifyAgain() => _verifyRoute();

  Future<void> _verifyRoute() async {
    final endpoint = _pendingEndpoint;
    final retry = _pendingRetry;
    if (_resuming || endpoint == null || retry == null) return;
    if (state.retryAttempts >= _maximumRetryAttempts) {
      state = state.copyWith(phase: SecureConnectionPhase.secureRouteFailed);
      return;
    }
    _resuming = true;
    try {
      state = state.copyWith(phase: SecureConnectionPhase.checkingVpn);
      await _delay(_resumeSettleDelay);
      final vpnActive = await _warp.isVpnActive();
      if (!mounted) return;
      if (!vpnActive) {
        state = state.copyWith(
          phase: SecureConnectionPhase.warpInstalled,
          vpnActive: false,
        );
        return;
      }

      state = state.copyWith(
        phase: SecureConnectionPhase.testingSecureRoute,
        vpnActive: true,
        retryAttempts: state.retryAttempts + 1,
      );
      final reachable = await _diagnostics.endpointReachable(
        endpoint,
        headers: _pendingHeaders,
      );
      if (!mounted) return;
      if (!reachable) {
        state = state.copyWith(phase: SecureConnectionPhase.secureRouteFailed);
        return;
      }

      state = state.copyWith(phase: SecureConnectionPhase.secureRouteReady);
      await Future.wait<void>([
        _preferences?.setWarpSetupCompleted(true) ?? Future<void>.value(),
        _preferences?.setLastSuccessfulSecureRoute(DateTime.now()) ??
            Future<void>.value(),
      ]);
      await retry();
      _pendingEndpoint = null;
      _pendingHeaders = const {};
      _pendingRetry = null;
    } finally {
      _resuming = false;
    }
  }

  /// Leaves playback on the direct route and clears the pending action.
  void cancel() {
    _pendingEndpoint = null;
    _pendingHeaders = const {};
    _pendingRetry = null;
    state = const SecureConnectionState();
  }
}
