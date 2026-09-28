/// Steps in the user-initiated Secure Connection flow.
enum SecureConnectionPhase {
  idle,
  checkingWarp,
  warpNotInstalled,
  waitingForInstallation,
  warpInstalled,
  openingWarp,
  waitingForWarp,
  checkingVpn,
  testingSecureRoute,
  secureRouteReady,
  secureRouteFailed,
}

/// Immutable state for the Secure Connection experience.
final class SecureConnectionState {
  const SecureConnectionState({
    this.phase = SecureConnectionPhase.idle,
    this.launchAttempts = 0,
    this.retryAttempts = 0,
    this.vpnActive,
  });

  final SecureConnectionPhase phase;
  final int launchAttempts;
  final int retryAttempts;
  final bool? vpnActive;

  bool get isVisible => switch (phase) {
    SecureConnectionPhase.idle ||
    SecureConnectionPhase.secureRouteReady => false,
    _ => true,
  };

  SecureConnectionState copyWith({
    SecureConnectionPhase? phase,
    int? launchAttempts,
    int? retryAttempts,
    bool? vpnActive,
    bool clearVpnState = false,
  }) {
    return SecureConnectionState(
      phase: phase ?? this.phase,
      launchAttempts: launchAttempts ?? this.launchAttempts,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      vpnActive: clearVpnState ? null : (vpnActive ?? this.vpnActive),
    );
  }
}
