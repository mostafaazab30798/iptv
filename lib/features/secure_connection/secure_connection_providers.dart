import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/features/secure_connection/application/secure_connection_controller.dart';
import 'package:iptv/features/secure_connection/data/secure_route_diagnostics.dart';
import 'package:iptv/features/secure_connection/data/warp_platform_service.dart';
import 'package:iptv/features/secure_connection/domain/secure_connection_state.dart';

final warpPlatformServiceProvider = Provider<WarpPlatformService>(
  (_) => MethodChannelWarpPlatformService(),
);

final secureRouteDiagnosticsProvider = Provider<SecureRouteDiagnostics>(
  (_) => DioSecureRouteDiagnostics(),
);

final secureConnectionControllerProvider =
    StateNotifierProvider<SecureConnectionController, SecureConnectionState>((
      ref,
    ) {
      return SecureConnectionController(
        warp: ref.watch(warpPlatformServiceProvider),
        diagnostics: ref.watch(secureRouteDiagnosticsProvider),
        preferences: PreferencesStorage.maybeInstance,
      );
    });
