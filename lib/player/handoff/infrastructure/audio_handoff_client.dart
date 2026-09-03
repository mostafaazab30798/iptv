import 'dart:async';
import 'dart:convert';

import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Client running on the mobile companion app that maintains WebSocket connection
/// with the TV host, receives continuous sync packets, and computes clock offset.
class AudioHandoffClient {
  AudioHandoffClient();

  WebSocketChannel? _channel;
  HandoffSessionInfo? _activeSession;

  final StreamController<HandoffConnectionState> _stateController =
      StreamController<HandoffConnectionState>.broadcast();
  final StreamController<HandoffSyncPacket> _syncController =
      StreamController<HandoffSyncPacket>.broadcast();
  final StreamController<PlayerSource> _sourceController =
      StreamController<PlayerSource>.broadcast();

  HandoffConnectionState _state = HandoffConnectionState.idle;
  int _estimatedRttMs = 20; // Default estimate
  Timer? _rttPingTimer;

  HandoffConnectionState get state => _state;
  HandoffSessionInfo? get activeSession => _activeSession;
  int get estimatedRttMs => _estimatedRttMs;

  Stream<HandoffConnectionState> get stateStream => _stateController.stream;
  Stream<HandoffSyncPacket> get syncStream => _syncController.stream;
  Stream<PlayerSource> get sourceStream => _sourceController.stream;

  /// Connects to the TV session specified by [sessionInfo].
  Future<void> connect(HandoffSessionInfo sessionInfo) async {
    await disconnect();

    _activeSession = sessionInfo;
    _setState(HandoffConnectionState.connecting);

    try {
      final wsUri = Uri.parse(sessionInfo.wsUrl);
      AppLogger.info(
        'Connecting to TV Audio Handoff: $wsUri',
        feature: 'audio_handoff',
      );
      _channel = WebSocketChannel.connect(wsUri);

      // Start listening to the stream
      _channel!.stream.listen(
        _handleMessage,
        onDone: () {
          AppLogger.info(
            'Audio handoff client connection closed',
            feature: 'audio_handoff',
          );
          _setState(HandoffConnectionState.disconnected);
          _stopRttPings();
        },
        onError: (Object error) {
          AppLogger.warning(
            'Audio handoff client error: $error',
            feature: 'audio_handoff',
          );
          _setState(HandoffConnectionState.error);
          _stopRttPings();
        },
        cancelOnError: true,
      );

      // Await socket handshake completion
      await _channel!.ready.timeout(const Duration(seconds: 5));

      _setState(HandoffConnectionState.connected);
      _startRttPings();
    } catch (e) {
      AppLogger.error(
        'Failed to connect to audio handoff server (${sessionInfo.wsUrl}): $e',
        feature: 'audio_handoff',
      );
      _setState(HandoffConnectionState.error);
    }
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final map = jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'handshake_ack' || type == 'source_change') {
        final srcMap = map['src'] as Map<String, dynamic>?;
        if (srcMap != null) {
          final source = _parsePlayerSource(srcMap);
          if (source != null) {
            _sourceController.add(source);
          }
        }
        if (type == 'handshake_ack' && map.containsKey('sync')) {
          final syncMap = map['sync'] as Map<String, dynamic>;
          _syncController.add(HandoffSyncPacket.fromJson(syncMap));
        }
        return;
      }

      if (type == 'sync_tick') {
        final packet = HandoffSyncPacket.fromJson(map);
        _syncController.add(packet);
        return;
      }

      if (type == 'pong') {
        final clientSentTime = (map['clientTime'] as num?)?.toInt();
        if (clientSentTime != null) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final rtt = (now - clientSentTime).clamp(1, 2000);
          // Exponential moving average for smooth RTT
          _estimatedRttMs = ((_estimatedRttMs * 0.7) + (rtt * 0.3)).round();
        }
        return;
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to parse incoming WS message: $e',
        feature: 'audio_handoff',
      );
    }
  }

  PlayerSource? _parsePlayerSource(Map<String, dynamic> srcMap) {
    try {
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

      return PlayerSource(
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
    } catch (_) {
      return null;
    }
  }

  void _startRttPings() {
    _stopRttPings();
    // Ping every 3 seconds to track RTT network latency accurately
    _rttPingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_state == HandoffConnectionState.connected && _channel != null) {
        try {
          _channel!.sink.add(
            jsonEncode({
              'type': 'ping',
              't': DateTime.now().millisecondsSinceEpoch,
            }),
          );
        } catch (_) {}
      }
    });
  }

  void _stopRttPings() {
    _rttPingTimer?.cancel();
    _rttPingTimer = null;
  }

  /// Sends a remote control command to the TV (e.g. mute TV speakers, play/pause).
  void sendCommand(HandoffCommand command) {
    if (_state != HandoffConnectionState.connected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(command.toJson()));
    } catch (e) {
      AppLogger.warning(
        'Failed to send command to TV: $e',
        feature: 'audio_handoff',
      );
    }
  }

  void _setState(HandoffConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Closes the connection.
  Future<void> disconnect() async {
    _stopRttPings();
    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }
    _activeSession = null;
    _setState(HandoffConnectionState.idle);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _syncController.close();
    _sourceController.close();
  }
}
