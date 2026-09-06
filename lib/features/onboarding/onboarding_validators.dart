/// Pure validation helpers for onboarding Xtream credentials.
library;

abstract final class OnboardingValidators {
  /// Returns `null` when valid, otherwise `'empty'` / `'invalid'`.
  static String? validateServerUrl(
    String? value, {
    required bool isCustomServer,
  }) {
    if (!isCustomServer) return null;
    if (value == null || value.trim().isEmpty) return 'empty';
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    final hasHttpScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    if (!hasHttpScheme ||
        uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'invalid';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'empty';
    return null;
  }

  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'empty';
    return null;
  }
}
