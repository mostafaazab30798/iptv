import 'package:equatable/equatable.dart';

/// Result of converting an M3U URL / playlist text into Xtream Codes credentials.
class M3uXtreamCredentials extends Equatable {
  final String serverUrl;
  final String username;
  final String password;
  final String? detectedType;

  const M3uXtreamCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.detectedType,
  });

  @override
  List<Object?> get props => [serverUrl, username, password, detectedType];
}

/// Utility for analyzing, parsing, and converting M3U URLs or M3U playlist content
/// into high-performance Xtream Codes API credentials (Server URL, Username, Password).
abstract final class M3uToXtreamConverter {
  /// Attempts to parse and extract Xtream credentials from an M3U URL or M3U content.
  /// Returns [M3uXtreamCredentials] if successful, or `null` if unable to extract.
  static M3uXtreamCredentials? tryConvert(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. If multi-line M3U playlist file content, extract the first valid stream URL
    if (trimmed.contains('\n') || trimmed.startsWith('#EXTM3U')) {
      final lines = trimmed.split(RegExp(r'[\r\n]+'));
      for (final line in lines) {
        final lineTrimmed = line.trim();
        if (lineTrimmed.startsWith('http://') || lineTrimmed.startsWith('https://')) {
          final result = _parseSingleUrl(lineTrimmed);
          if (result != null) return result;
        }
      }
      return null;
    }

    // 2. Otherwise parse as a single URL string
    return _parseSingleUrl(trimmed);
  }

  static M3uXtreamCredentials? _parseSingleUrl(String rawUrl) {
    try {
      final uri = Uri.tryParse(rawUrl);
      if (uri == null || (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https')))) {
        return null;
      }

      final scheme = uri.scheme;
      final host = uri.host;
      if (host.isEmpty) return null;

      // Retain explicit port if present in raw URL or URI
      String baseServerUrl = '$scheme://$host';
      final hostIndex = rawUrl.indexOf('://$host');
      if (hostIndex != -1) {
        final afterHost = rawUrl.substring(hostIndex + 3 + host.length);
        final portMatch = RegExp(r'^:(\d+)').firstMatch(afterHost);
        if (portMatch != null) {
          baseServerUrl = '$scheme://$host:${portMatch.group(1)}';
        } else if (uri.hasPort) {
          baseServerUrl = '$scheme://$host:${uri.port}';
        }
      } else if (uri.hasPort) {
        baseServerUrl = '$scheme://$host:${uri.port}';
      }

      // Check query parameters (most common for get.php M3U links)
      final queryParams = uri.queryParameters;
      final username = queryParams['username'] ??
          queryParams['user'] ??
          queryParams['u'];
      final password = queryParams['password'] ??
          queryParams['pass'] ??
          queryParams['p'];

      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        return M3uXtreamCredentials(
          serverUrl: baseServerUrl,
          username: username,
          password: password,
          detectedType: 'Query Parameter (get.php / playlist)',
        );
      }

      // Check Basic Auth inside URI (http://user:pass@host:port/...)
      if (uri.userInfo.isNotEmpty && uri.userInfo.contains(':')) {
        final parts = uri.userInfo.split(':');
        if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          return M3uXtreamCredentials(
            serverUrl: baseServerUrl,
            username: Uri.decodeComponent(parts[0]),
            password: Uri.decodeComponent(parts[1]),
            detectedType: 'Basic Auth in URL',
          );
        }
      }

      // Check Path Segments (e.g. /live/username/password/stream_id.ts or /movie/user/pass/id.mp4)
      final segments = uri.pathSegments;
      if (segments.length >= 4) {
        final prefix = segments[0].toLowerCase();
        if (prefix == 'live' || prefix == 'movie' || prefix == 'series' || prefix == 'play') {
          final user = segments[1];
          final pass = segments[2];
          if (user.isNotEmpty && pass.isNotEmpty) {
            return M3uXtreamCredentials(
              serverUrl: baseServerUrl,
              username: user,
              password: pass,
              detectedType: 'Stream URL Path Segments (/$prefix/user/pass/...)',
            );
          }
        }
      } else if (segments.length >= 3) {
        // e.g. /username/password/stream_id
        final user = segments[0];
        final pass = segments[1];
        if (user.isNotEmpty &&
            pass.isNotEmpty &&
            !user.contains('.') &&
            !pass.contains('.')) {
          return M3uXtreamCredentials(
            serverUrl: baseServerUrl,
            username: user,
            password: pass,
            detectedType: 'Direct Path Segments (/user/pass/...)',
          );
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks if a string looks like an M3U link or playlist.
  static bool isM3uLink(String input) {
    final lower = input.toLowerCase().trim();
    return lower.contains('get.php') ||
        lower.contains('.m3u') ||
        lower.contains('.m3u8') ||
        lower.contains('type=m3u') ||
        lower.startsWith('#extm3u');
  }
}
