class KidsModeState {
  const KidsModeState({
    this.isInitialized = false,
    this.isEnabled = false,
    this.hasPin = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.error,
  });

  final bool isInitialized;
  final bool isEnabled;
  final bool hasPin;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final String? error;

  bool get isLockedOut =>
      lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  KidsModeState copyWith({
    bool? isInitialized,
    bool? isEnabled,
    bool? hasPin,
    int? failedAttempts,
    DateTime? lockoutUntil,
    bool clearLockout = false,
    String? error,
    bool clearError = false,
  }) {
    return KidsModeState(
      isInitialized: isInitialized ?? this.isInitialized,
      isEnabled: isEnabled ?? this.isEnabled,
      hasPin: hasPin ?? this.hasPin,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
