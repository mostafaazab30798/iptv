import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/secure_connection/application/secure_connection_controller.dart';
import 'package:iptv/features/secure_connection/data/secure_route_diagnostics.dart';
import 'package:iptv/features/secure_connection/data/warp_platform_service.dart';
import 'package:iptv/features/secure_connection/domain/secure_connection_state.dart';

final class _FakeWarpPlatformService implements WarpPlatformService {
  bool installed = false;
  bool vpnActive = false;
  bool opensWarp = true;
  int openWarpCalls = 0;
  int openStoreCalls = 0;

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Future<bool> isVpnActive() async => vpnActive;

  @override
  Future<bool> openWarp() async {
    openWarpCalls++;
    return opensWarp;
  }

  @override
  Future<void> openStore() async {
    openStoreCalls++;
  }
}

final class _FakeSecureRouteDiagnostics implements SecureRouteDiagnostics {
  bool reachable = false;
  int calls = 0;
  Map<String, String>? lastHeaders;

  @override
  Future<bool> endpointReachable(
    Uri endpoint, {
    Map<String, String> headers = const {},
  }) async {
    calls++;
    lastHeaders = headers;
    return reachable;
  }
}

void main() {
  group('SecureConnectionController', () {
    late _FakeWarpPlatformService warp;
    late _FakeSecureRouteDiagnostics diagnostics;
    late SecureConnectionController controller;
    late int retryCalls;

    setUp(() {
      warp = _FakeWarpPlatformService();
      diagnostics = _FakeSecureRouteDiagnostics();
      retryCalls = 0;
      controller = SecureConnectionController(
        warp: warp,
        diagnostics: diagnostics,
        delay: (_) async {},
      );
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> start() => controller.start(
      endpoint: Uri.parse('https://stream.example/channel/1.m3u8'),
      headers: const {'Referer': 'https://stream.example/'},
      retry: () async {
        retryCalls++;
      },
    );

    test(
      'should offer the official install flow when WARP is missing',
      () async {
        await start();

        expect(controller.state.phase, SecureConnectionPhase.warpNotInstalled);
        expect(warp.openWarpCalls, 0);

        await controller.installWarp();

        expect(warp.openStoreCalls, 1);
        expect(
          controller.state.phase,
          SecureConnectionPhase.waitingForInstallation,
        );
      },
    );

    test('should detect installation when returning from the store', () async {
      await start();
      await controller.installWarp();
      warp.installed = true;

      await controller.onAppResumed();

      expect(controller.state.phase, SecureConnectionPhase.warpInstalled);
      expect(warp.openWarpCalls, 0);
    });

    test('should verify the endpoint and retry the exact action', () async {
      warp.installed = true;
      warp.vpnActive = true;
      diagnostics.reachable = true;

      await start();
      expect(controller.state.phase, SecureConnectionPhase.waitingForWarp);
      await controller.onAppResumed();

      expect(controller.state.phase, SecureConnectionPhase.secureRouteReady);
      expect(diagnostics.calls, 1);
      expect(diagnostics.lastHeaders, const {
        'Referer': 'https://stream.example/',
      });
      expect(retryCalls, 1);
    });

    test('should not test or retry when no VPN transport is active', () async {
      warp.installed = true;
      diagnostics.reachable = true;

      await start();
      await controller.onAppResumed();

      expect(controller.state.phase, SecureConnectionPhase.warpInstalled);
      expect(diagnostics.calls, 0);
      expect(retryCalls, 0);
    });

    test(
      'should never relaunch WARP automatically after a failed return',
      () async {
        warp.installed = true;

        await start();
        await controller.onAppResumed();
        await controller.onAppResumed();

        expect(warp.openWarpCalls, 1);
        expect(controller.state.phase, SecureConnectionPhase.warpInstalled);
      },
    );

    test('should bound automatic route verification retries', () async {
      warp.installed = true;
      warp.vpnActive = true;

      await start();
      await controller.onAppResumed();
      await controller.verifyAgain();
      await controller.verifyAgain();

      expect(diagnostics.calls, 2);
      expect(controller.state.phase, SecureConnectionPhase.secureRouteFailed);
      expect(retryCalls, 0);
    });
  });
}
