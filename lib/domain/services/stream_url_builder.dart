import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/network/url_helpers.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/player/infrastructure/web/web_player_engine.dart';

/// Builds Xtream playback URLs without coupling presentation to the datasource.
class StreamUrlBuilder {
  const StreamUrlBuilder();

  String live({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String? extension,
  }) {
    // Safari/iOS native <video> needs HLS (.m3u8). MediaKit on desktop web
    // handles progressive MPEG-TS more reliably than proxied HLS right now.
    final ext = extension ??
        (kIsWeb && isIosOrSafariWeb() ? 'm3u8' : 'ts');
    final base = UrlHelpers.normalizeServerUrl(serverUrl);
    final raw = '$base/live/$username/$password/$streamId.$ext';
    return UrlHelpers.wrapWebProxy(raw);
  }

  String vod({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'mp4',
  }) {
    final base = UrlHelpers.normalizeServerUrl(serverUrl);
    final raw = '$base/movie/$username/$password/$streamId.$extension';
    return UrlHelpers.wrapWebProxy(raw);
  }

  String series({
    required String serverUrl,
    required String username,
    required String password,
    required int streamId,
    String extension = 'mp4',
  }) {
    final base = UrlHelpers.normalizeServerUrl(serverUrl);
    final raw = '$base/series/$username/$password/$streamId.$extension';
    return UrlHelpers.wrapWebProxy(raw);
  }

  String liveForSession(
    ServerConfig session, {
    required int streamId,
    String? extension,
  }) =>
      live(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: streamId,
        extension: extension,
      );

  String vodForSession(
    ServerConfig session, {
    required int streamId,
    String extension = 'mp4',
  }) =>
      vod(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: streamId,
        extension: extension,
      );

  String seriesForSession(
    ServerConfig session, {
    required int streamId,
    String extension = 'mp4',
  }) =>
      series(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: streamId,
        extension: extension,
      );
}
