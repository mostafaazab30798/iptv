import 'dart:convert';

/// Non-secret commercial control-plane configuration for HOPE TV.
///
/// Provide real values via `--dart-define`:
/// `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
///
/// Never put the service-role key here.
class CommercialApiConfig {
  const CommercialApiConfig._();

  static const productName = 'HOPE TV';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'PLACEHOLDER_SUPABASE_URL',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'PLACEHOLDER_SUPABASE_ANON_KEY',
  );

  /// Customer subscription / billing portal (e.g. https://hope-tv.site).
  static const portalOrigin = String.fromEnvironment(
    'PORTAL_ORIGIN',
    defaultValue: 'PLACEHOLDER_PORTAL_ORIGIN',
  );

  /// True only when dart-defines are real HTTPS project values.
  static bool get isConfigured {
    if (supabaseUrl.startsWith('PLACEHOLDER_')) return false;
    if (supabaseAnonKey.startsWith('PLACEHOLDER_')) return false;
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  static String functionsBaseUrl(String functionName) {
    final base = supabaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/functions/v1/$functionName';
  }

  /// Parsed subscription portal URL, or null when not configured in this build.
  static Uri? get subscriptionPortalUri {
    if (portalOrigin.startsWith('PLACEHOLDER_')) return null;
    final uri = Uri.tryParse(portalOrigin);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  /// Optional local-only HMAC verify secret. Never set in production builds.
  static const entitlementHmacVerifySecret = String.fromEnvironment(
    'ENTITLEMENT_HMAC_VERIFY_SECRET',
    defaultValue: '',
  );

  /// JSON map of keyId -> Ed25519 public key hex, e.g. {"entitlement-dev-1":"..."}.
  static Map<String, String> get entitlementPublicKeys {
    const raw = String.fromEnvironment(
      'ENTITLEMENT_PUBLIC_KEYS_JSON',
      defaultValue: '{}',
    );
    try {
      if (raw.isEmpty || raw == '{}') return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {
      return const {};
    }
  }

  /// JSON map of keyId -> Ed25519 public key hex for release manifests.
  static Map<String, String> get releasePublicKeys {
    const raw = String.fromEnvironment(
      'RELEASE_PUBLIC_KEYS_JSON',
      defaultValue: '{}',
    );
    try {
      if (raw.isEmpty || raw == '{}') return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map((k, v) => MapEntry('$k', '$v'));
    } catch (_) {
      return const {};
    }
  }

  /// Optional local-only HMAC verify secret for release manifests.
  static const releaseHmacVerifySecret = String.fromEnvironment(
    'RELEASE_HMAC_VERIFY_SECRET',
    defaultValue: '',
  );
}
