import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/constants/api_constants.dart';
import 'package:iptv/core/network/url_helpers.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/utils/stream_type_detector.dart';

/// Resolves raw IPTV channel/VOD metadata into a structured, validated [PlayerSource].
///
/// Ensures structured URL construction with safe encoding, ports, and headers without logging secrets.
class StreamResolver {
  const StreamResolver({
    this.defaultUserAgent = ApiConstants.defaultUserAgent,
  });

  final String defaultUserAgent;

  /// Builds a live stream [PlayerSource] from IPTV server credentials.
  PlayerSource resolveLive({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    required String title,
    String? logoUrl,
    int? categoryId,
    String? currentProgramTitle,
    String? nextProgramTitle,
    double? programProgress,
    String format = 'm3u8',
    Map<String, String>? customHeaders,
    Map<String, dynamic>? metadata,
  }) {
    final cleanFormat = format.trim().replaceAll('.', '');
    final uri = _buildUri(
      serverUrl: serverUrl,
      pathSegments: ['live', username, password, '$streamId.$cleanFormat'],
    );

    final rawUrl = uri.toString();
    final streamType = StreamTypeDetector.detect(rawUrl, hint: cleanFormat);
    final finalUrl = UrlHelpers.wrapWebProxy(rawUrl);

    final headers = <String, String>{
      if (!kIsWeb) ApiConstants.userAgentHeader: defaultUserAgent,
      'Connection': 'keep-alive',
      if (customHeaders != null) ...customHeaders,
    };

    return PlayerSource.live(
      url: finalUrl,
      title: title,
      channelId: streamId,
      categoryId: categoryId,
      logoUrl: logoUrl,
      currentProgramTitle: currentProgramTitle,
      nextProgramTitle: nextProgramTitle,
      programProgress: programProgress,
      streamType: streamType,
      headers: headers,
      metadata: metadata ?? const {},
    );
  }

  /// Builds a VOD movie [PlayerSource].
  PlayerSource resolveVod({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    required String title,
    String? containerExtension,
    String? posterUrl,
    int? categoryId,
    Duration? startAt,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? metadata,
  }) {
    final ext = (containerExtension ?? 'mp4').trim().replaceAll('.', '');
    final uri = _buildUri(
      serverUrl: serverUrl,
      pathSegments: ['movie', username, password, '$streamId.$ext'],
    );

    final rawUrl = uri.toString();
    final streamType = StreamTypeDetector.detect(rawUrl, hint: ext);
    final finalUrl = UrlHelpers.wrapWebProxy(rawUrl);

    final headers = <String, String>{
      if (!kIsWeb) ApiConstants.userAgentHeader: defaultUserAgent,
      'Connection': 'keep-alive',
      if (customHeaders != null) ...customHeaders,
    };

    return PlayerSource.vod(
      url: finalUrl,
      title: title,
      movieId: streamId,
      categoryId: categoryId,
      posterUrl: posterUrl,
      startAt: startAt,
      streamType: streamType,
      headers: headers,
      metadata: metadata ?? const {},
    );
  }

  /// Resolves an arbitrary or direct URL source.
  PlayerSource resolveDirect({
    required String url,
    required String title,
    PlaybackProfile profile = PlaybackProfile.live,
    String? logoUrl,
    Map<String, String>? customHeaders,
    Map<String, dynamic>? metadata,
  }) {
    final streamType = StreamTypeDetector.detect(url);
    final finalUrl = UrlHelpers.wrapWebProxy(url);

    final headers = <String, String>{
      if (!kIsWeb) ApiConstants.userAgentHeader: defaultUserAgent,
      'Connection': 'keep-alive',
      if (customHeaders != null) ...customHeaders,
    };

    return PlayerSource(
      url: finalUrl,
      title: title,
      profile: profile,
      streamType: streamType,
      logoUrl: logoUrl,
      headers: headers,
      metadata: metadata ?? const {},
    );
  }

  /// Structured URI builder with robust port and path segment handling.
  Uri _buildUri({
    required String serverUrl,
    required List<String> pathSegments,
  }) {
    final baseUri = Uri.parse(UrlHelpers.normalizeServerUrl(serverUrl));
    final existingSegments = List<String>.from(baseUri.pathSegments)
      ..removeWhere((s) => s.isEmpty);

    return Uri(
      scheme: baseUri.scheme,
      userInfo: baseUri.userInfo.isNotEmpty ? baseUri.userInfo : null,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      pathSegments: [...existingSegments, ...pathSegments],
    );
  }
}
