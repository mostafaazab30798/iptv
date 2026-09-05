import 'package:flutter/foundation.dart' show kIsWeb;

/// Shared URL helpers for Xtream panel bases and Flutter Web `/proxy` wrapping.
abstract final class UrlHelpers {
  static const String _envProxyUrl = String.fromEnvironment('WEB_PROXY_URL');

  /// Detects if [uri] (or [Uri.base]) points to a local or private network host.
  static bool isLocalHost([Uri? uri]) {
    final u = uri ?? Uri.base;
    final host = u.host.toLowerCase();
    if (host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1' ||
        host == '[::1]') {
      return true;
    }
    if (host.endsWith('.local') || host.endsWith('.localhost')) {
      return true;
    }
    if (host.startsWith('192.168.') || host.startsWith('10.')) {
      return true;
    }
    final match = RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').firstMatch(host);
    if (match != null) return true;

    return false;
  }

  /// Base URL of the web reverse proxy endpoint (defaults to `${Uri.base.origin}/proxy`).
  static String get proxyBaseUrl {
    if (_envProxyUrl.isNotEmpty) return _envProxyUrl;
    return '${Uri.base.origin}/proxy';
  }

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
  /// Default (streams/API): proxy when the page is HTTPS and the target is plain HTTP
  /// (mixed-content bypass), excluding localhost and local network hosts.
  ///
  /// Set [proxyAllHttpTargets] for image loads that should also proxy remote HTTPS URLs.
  static String wrapWebProxy(
    String rawUrl, {
    bool proxyAllHttpTargets = false,
  }) {
    if (!kIsWeb) return rawUrl;
    if (isLocalHost()) return rawUrl;

    final isHttpsOrigin = Uri.base.scheme == 'https';
    final isTargetHttp = rawUrl.startsWith('http://');

    final shouldProxy = proxyAllHttpTargets
        ? (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
        : (isHttpsOrigin && isTargetHttp);

    if (!shouldProxy) return rawUrl;

    return '$proxyBaseUrl?url=${Uri.encodeComponent(rawUrl)}';
  }
}
