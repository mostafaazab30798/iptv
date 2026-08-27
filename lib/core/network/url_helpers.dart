import 'package:flutter/foundation.dart' show kIsWeb;

/// Shared URL helpers for Xtream panel bases and Flutter Web `/proxy` wrapping.
abstract final class UrlHelpers {
  /// Normalizes a panel base URL: ensure scheme, strip `player_api.php`, no trailing slash.
  static String normalizeServerUrl(String serverUrl) {
    var normalized = serverUrl.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    return normalized
        .replaceAll(RegExp(r'/player_api\.php.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'/+$'), '');
  }

  /// Wraps [rawUrl] with the Cloudflare `/proxy` endpoint when needed on Flutter Web.
  ///
  /// Default (streams/API): proxy when the page is HTTPS or the target is plain HTTP
  /// (mixed-content / CORS bypass), excluding localhost.
  ///
  /// Set [proxyAllHttpTargets] for image loads that should also proxy remote HTTPS URLs.
  static String wrapWebProxy(
    String rawUrl, {
    bool proxyAllHttpTargets = false,
  }) {
    if (!kIsWeb) return rawUrl;

    final isLocalhost =
        Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1';
    if (isLocalhost) return rawUrl;

    final shouldProxy = proxyAllHttpTargets
        ? (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
        : (Uri.base.scheme == 'https' || rawUrl.startsWith('http://'));

    if (!shouldProxy) return rawUrl;

    return '${Uri.base.origin}/proxy?url=${Uri.encodeComponent(rawUrl)}';
  }
}
