import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';

/// Connection state of the audio handoff session.
enum HandoffConnectionState {
  idle,
  hosting,
  connecting,
  connected,
  disconnected,
  error,
}

/// Information packet describing an active TV Audio Handoff session.
class HandoffSessionInfo extends Equatable {
  const HandoffSessionInfo({
    required this.hostIp,
    required this.port,
    required this.sessionToken,
    required this.pinCode,
    required this.source,
    this.serverDeviceName = 'HOPE IPTV TV',
  });

  final String hostIp;
  final int port;
  final String sessionToken;
  final String pinCode;
  final PlayerSource source;
  final String serverDeviceName;

  String get wsUrl => 'ws://$hostIp:$port/audio-handoff?token=$sessionToken';
  String get httpUrl => 'http://$hostIp:$port/?tok=$sessionToken&pin=$pinCode';

  /// Serializes into a standard clickable HTTP URL format so any phone camera
  /// or QR reader can instantly open the companion web app or IPTV app.
  String toQrPayload() => httpUrl;

  /// Deserializes a QR code payload (HTTP URL, deep link, or JSON string).
  static HandoffSessionInfo? fromQrPayload(String raw) {
    try {
      final trimmed = raw.trim();

      // 1. Try parsing as HTTP/HTTPS or deep-link URI
      if (trimmed.startsWith('http://') ||
          trimmed.startsWith('https://') ||
          trimmed.startsWith('iptv://') ||
          trimmed.startsWith('ws://')) {
        final uri = Uri.parse(trimmed);
        final host = uri.host.isNotEmpty ? uri.host : (uri.queryParameters['host'] ?? uri.queryParameters['ip']);
        final port = uri.hasPort ? uri.port : (int.tryParse(uri.queryParameters['port'] ?? uri.queryParameters['p'] ?? '') ?? 8998);
        final tok = uri.queryParameters['tok'] ?? uri.queryParameters['token'] ?? 'companion_token';
        final pin = uri.queryParameters['pin'] ?? '0000';
        final dev = uri.queryParameters['dev'] ?? 'HOPE IPTV TV';

        if (host != null && host.isNotEmpty) {
          return HandoffSessionInfo(
            hostIp: host,
            port: port,
            sessionToken: tok,
            pinCode: pin,
            source: PlayerSource.live(
              url: uri.queryParameters['url'] ?? '',
              title: uri.queryParameters['title'] ?? 'TV Broadcast',
            ),
            serverDeviceName: dev,
          );
        }
      }

      // 2. Try parsing as JSON payload
      if (trimmed.startsWith('{')) {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        final ip = map['ip'] as String?;
        final port = (map['p'] as num?)?.toInt() ?? 8998;
        final token = map['tok'] as String? ?? 'companion_token';
        final pin = map['pin']?.toString() ?? '0000';
        final dev = map['dev'] as String? ?? 'HOPE IPTV TV';
        final srcMap = map['src'] as Map<String, dynamic>?;

        if (ip == null) return null;

        PlayerSource source;
        if (srcMap != null) {
          final streamUrl = srcMap['url'] as String? ?? '';
          final title = srcMap['title'] as String? ?? 'Live Stream';
          final logo = srcMap['logo'] as String?;
          final profStr = srcMap['prof'] as String?;
          final stStr = srcMap['st'] as String?;
          final hdrsRaw = srcMap['hdrs'] as Map<String, dynamic>? ?? {};
          final hdrs = hdrsRaw.map((k, v) => MapEntry(k, v.toString()));
          final chId = (srcMap['chId'] as num?)?.toInt();
          final catId = (srcMap['catId'] as num?)?.toInt();
          final prog = srcMap['prog'] as String?;

          final profile = PlaybackProfile.values.firstWhere(
            (p) => p.name == profStr,
            orElse: () => PlaybackProfile.live,
          );
          final streamType = StreamType.values.firstWhere(
            (s) => s.name == stStr,
            orElse: () => StreamType.auto,
          );

          source = PlayerSource(
            url: streamUrl,
            title: title,
            logoUrl: logo,
            profile: profile,
            streamType: streamType,
            headers: hdrs,
            channelId: chId,
            categoryId: catId,
            currentProgramTitle: prog,
          );
        } else {
          source = PlayerSource.live(url: '', title: 'TV Stream');
        }

        return HandoffSessionInfo(
          hostIp: ip,
          port: port,
          sessionToken: token,
          pinCode: pin,
          source: source,
          serverDeviceName: dev,
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  List<Object?> get props => [hostIp, port, sessionToken, pinCode, source, serverDeviceName];
}

/// Periodic synchronization packet broadcasted by the TV server every 500ms.
class HandoffSyncPacket extends Equatable {
  const HandoffSyncPacket({
    required this.serverTimestampMs,
    required this.positionMs,
    required this.durationMs,
    required this.isPlaying,
    required this.isBuffering,
    this.streamUrl,
    this.title,
    this.channelId,
    this.epoch = 0,
    this.isLive = false,
  });

  final int serverTimestampMs;
  final int positionMs;
  final int durationMs;
  final bool isPlaying;
  final bool isBuffering;
  final String? streamUrl;
  final String? title;
  final int? channelId;
  final int epoch;
  final bool isLive;

  Map<String, dynamic> toJson() => {
        'type': 'sync_tick',
        'st': serverTimestampMs,
        'pos': positionMs,
        'dur': durationMs,
        'play': isPlaying,
        'buf': isBuffering,
        'live': isLive,
        if (streamUrl != null) 'url': streamUrl,
        if (title != null) 'title': title,
        if (channelId != null) 'chId': channelId,
        'ep': epoch,
      };

  factory HandoffSyncPacket.fromJson(Map<String, dynamic> json) {
    return HandoffSyncPacket(
      serverTimestampMs: (json['st'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      positionMs: (json['pos'] as num?)?.toInt() ?? 0,
      durationMs: (json['dur'] as num?)?.toInt() ?? 0,
      isPlaying: json['play'] as bool? ?? false,
      isBuffering: json['buf'] as bool? ?? false,
      streamUrl: json['url'] as String?,
      title: json['title'] as String?,
      channelId: (json['chId'] as num?)?.toInt(),
      epoch: (json['ep'] as num?)?.toInt() ?? 0,
      isLive: json['live'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        serverTimestampMs,
        positionMs,
        durationMs,
        isPlaying,
        isBuffering,
        streamUrl,
        title,
        channelId,
        epoch,
        isLive,
      ];
}

/// Remote command sent between companion phone and host TV.
class HandoffCommand {
  const HandoffCommand({
    required this.action,
    this.payload = const {},
  });

  final String action;
  final Map<String, dynamic> payload;

  static const actionMuteTv = 'mute_tv';
  static const actionUnmuteTv = 'unmute_tv';
  static const actionTogglePlayPause = 'toggle_play_pause';
  static const actionSeek = 'seek';
  static const actionDisconnect = 'disconnect';
  static const actionPing = 'ping';
  static const actionPong = 'pong';

  // Remote Touchpad / Mouse Actions
  static const actionMouseMove = 'mouse_move';
  static const actionMouseClick = 'mouse_click';
  static const actionMouseTap = 'mouse_tap';
  static const actionMouseScroll = 'mouse_scroll';

  // Remote Keyboard & Navigation Actions
  static const actionKeyPress = 'key_press';
  static const actionTypeText = 'type_text';

  // Factory helpers for clean companion calls
  factory HandoffCommand.mouseMove({required double dx, required double dy}) =>
      HandoffCommand(
        action: actionMouseMove,
        payload: {'dx': dx, 'dy': dy},
      );

  factory HandoffCommand.mouseClick({String button = 'left', bool down = true}) =>
      HandoffCommand(
        action: actionMouseClick,
        payload: {'button': button, 'down': down},
      );

  factory HandoffCommand.mouseTap({String button = 'left'}) => HandoffCommand(
        action: actionMouseTap,
        payload: {'button': button},
      );

  factory HandoffCommand.mouseScroll({required double dx, required double dy}) =>
      HandoffCommand(
        action: actionMouseScroll,
        payload: {'dx': dx, 'dy': dy},
      );

  factory HandoffCommand.keyPress(String key) => HandoffCommand(
        action: actionKeyPress,
        payload: {'key': key},
      );

  factory HandoffCommand.typeText(String text, {bool replace = false}) =>
      HandoffCommand(
        action: actionTypeText,
        payload: {'text': text, 'replace': replace},
      );

  Map<String, dynamic> toJson() => {
        'type': 'command',
        'act': action,
        'data': payload,
      };

  factory HandoffCommand.fromJson(Map<String, dynamic> json) {
    return HandoffCommand(
      action: json['act'] as String? ?? '',
      payload: (json['data'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

