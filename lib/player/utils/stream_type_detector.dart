import 'package:iptv/player/domain/enums/stream_type.dart';

/// Utility to detect and normalize media stream delivery formats.
class StreamTypeDetector {
  const StreamTypeDetector._();

  /// Detects [StreamType] from URL, path, and optional mime type / hints.
  static StreamType detect(String url, {String? contentType, String? hint}) {
    if (hint != null) {
      final normalizedHint = hint.trim().toLowerCase();
      if (normalizedHint == 'm3u8' || normalizedHint == 'hls') return StreamType.hls;
      if (normalizedHint == 'ts' || normalizedHint == 'mpegts') return StreamType.mpegTs;
      if (normalizedHint == 'mpd' || normalizedHint == 'dash') return StreamType.dash;
      if (normalizedHint == 'rtsp') return StreamType.rtsp;
      if (normalizedHint == 'rtp') return StreamType.rtp;
      if (normalizedHint == 'udp') return StreamType.udp;
    }

    final lowerUrl = url.trim().toLowerCase();

    // Scheme based transport stream detection
    if (lowerUrl.startsWith('udp://')) return StreamType.udp;
    if (lowerUrl.startsWith('rtp://')) return StreamType.rtp;
    if (lowerUrl.startsWith('rtsp://')) return StreamType.rtsp;

    if (contentType != null) {
      final normalizedType = contentType.trim().toLowerCase();
      if (normalizedType.contains('application/x-mpegurl') ||
          normalizedType.contains('application/vnd.apple.mpegurl')) {
        return StreamType.hls;
      }
      if (normalizedType.contains('video/mp2t') ||
          normalizedType.contains('video/ts')) {
        return StreamType.mpegTs;
      }
      if (normalizedType.contains('application/dash+xml')) {
        return StreamType.dash;
      }
      if (normalizedType.contains('application/rtsp')) {
        return StreamType.rtsp;
      }
    }

    // For web `/proxy?...&url=<real>` (or `/proxy/playlist.m3u8?url=`), detect
    // from the inner stream URL so outer paths like playlist.ts are ignored.
    final detectionUrl = _unwrapProxyTarget(lowerUrl);
    final cleanUrl = detectionUrl.split('?').first;

    if (cleanUrl.endsWith('.m3u8') ||
        detectionUrl.contains('output=m3u8') ||
        detectionUrl.contains('.m3u8?')) {
      return StreamType.hls;
    }

    if (cleanUrl.endsWith('.ts') ||
        detectionUrl.contains('output=ts') ||
        detectionUrl.contains('.ts?')) {
      return StreamType.mpegTs;
    }

    if (cleanUrl.endsWith('.mpd') || detectionUrl.contains('.mpd?')) {
      return StreamType.dash;
    }

    if (cleanUrl.endsWith('.mp4') ||
        cleanUrl.endsWith('.mkv') ||
        cleanUrl.endsWith('.avi') ||
        cleanUrl.endsWith('.mov')) {
      return StreamType.file;
    }

    return StreamType.unknown;
  }

  /// Returns the decoded `url` query value for `/proxy` URLs, otherwise [url].
  static String _unwrapProxyTarget(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (!uri.path.contains('/proxy')) return url;
    final target = uri.queryParameters['url'];
    if (target == null || target.isEmpty) return url;
    return target.toLowerCase();
  }
}
