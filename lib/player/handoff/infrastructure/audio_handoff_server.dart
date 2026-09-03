import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/handoff/infrastructure/audio_handoff_discovery.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef HandoffCommandHandler = void Function(HandoffCommand command);
typedef HandoffClientCountCallback = void Function(int connectedClients);

/// Lightweight host server running on the TV/Player device to broadcast
/// low-latency sync frames and stream metadata to companion phones.
class AudioHandoffServer {
  AudioHandoffServer({
    int port = 8998,
    String? deviceName,
  })  : _port = port,
        _deviceName = deviceName ?? _detectDefaultDeviceName();

  final int _port;
  final String _deviceName;

  static String _detectDefaultDeviceName() {
    try {
      final host = Platform.localHostname;
      if (Platform.isWindows) return 'Windows PC ($host)';
      if (Platform.isMacOS) return 'Mac ($host)';
      if (Platform.isLinux) return 'Linux PC ($host)';
      if (Platform.isAndroid) return 'Android Screen ($host)';
      if (Platform.isIOS) return 'iOS Device ($host)';
    } catch (_) {}
    return 'IPTV Screen';
  }

  HttpServer? _server;
  final Set<WebSocketChannel> _clients = {};
  final AudioHandoffDiscoveryBroadcaster _discoveryBroadcaster =
      AudioHandoffDiscoveryBroadcaster();
  Timer? _syncTimer;

  HandoffSessionInfo? _sessionInfo;
  PlayerSource? _currentSource;
  HandoffCommandHandler? _commandHandler;
  HandoffClientCountCallback? _clientCountCallback;

  // TV Player State supplier
  int Function()? _getPositionMs;
  int Function()? _getDurationMs;
  bool Function()? _getIsPlaying;
  bool Function()? _getIsBuffering;

  bool get isRunning => _server != null;
  int get clientCount => _clients.length;
  HandoffSessionInfo? get sessionInfo => _sessionInfo;

  /// Starts the WebSocket & Web Companion server.
  Future<HandoffSessionInfo> start({
    PlayerSource? source,
    int Function()? getPositionMs,
    int Function()? getDurationMs,
    bool Function()? getIsPlaying,
    bool Function()? getIsBuffering,
    HandoffCommandHandler? onCommand,
    HandoffClientCountCallback? onClientCountChanged,
  }) async {
    await stop();

    final effectiveSource = source ??
        const PlayerSource(
          url: '',
          title: 'IPTV Screen',
        );

    _currentSource = effectiveSource;
    _getPositionMs = getPositionMs;
    _getDurationMs = getDurationMs;
    _getIsPlaying = getIsPlaying;
    _getIsBuffering = getIsBuffering;
    _commandHandler = onCommand;
    _clientCountCallback = onClientCountChanged;

    final localIp = await _findLocalIpAddress();
    final token = _generateRandomToken(12);
    final pin = (1000 + Random().nextInt(9000)).toString();

    final wsHandler = webSocketHandler(_handleNewClient);

    // Pre-fetch all LAN IPs once — used in the companion-info response
    final allLanIps = await getAllLanIps();

    shelf.Response httpHandler(shelf.Request request) {
      if (request.headers['upgrade']?.toLowerCase() == 'websocket' ||
          request.url.path == 'audio-handoff') {
        return shelf.Response.notFound('WebSocket endpoint');
      }

      // JSON metadata probe endpoint for direct subnet scanners
      if (request.url.path == 'companion-info' ||
          request.url.path == 'handoff-info') {
        return shelf.Response.ok(
          jsonEncode({
            't': 'hope_tv_beacon',
            'dev': _deviceName,
            'ip': localIp,
            'ips': allLanIps, // All available LAN IPs
            'p': _server?.port ?? _port,
            'tok': token,
            'pin': pin,
            'title': effectiveSource.title,
            'logo': effectiveSource.logoUrl,
            'url': effectiveSource.url,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }

      return shelf.Response.ok(
        _renderWebCompanionHtml(
          token: token,
          pin: pin,
          localIp: localIp,
          port: _port,
          source: effectiveSource,
        ),
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    }

    final cascade = shelf.Cascade().add(wsHandler).add(httpHandler);
    final handler = const shelf.Pipeline().addHandler(cascade.handler);

    HttpServer? boundServer;
    for (final candidatePort in [_port, 8997, 8996, 0]) {
      try {
        boundServer = await shelf_io.serve(
          handler,
          InternetAddress.anyIPv4,
          candidatePort,
          shared: false,
        );
        break;
      } catch (e) {
        AppLogger.warning(
          'Port $candidatePort unavailable for Audio Handoff server: $e',
          feature: 'audio_handoff',
        );
      }
    }

    if (boundServer == null) {
      throw Exception('Could not bind any port for Audio Handoff Server');
    }

    _server = boundServer;

    _sessionInfo = HandoffSessionInfo(
      hostIp: localIp,
      port: _server!.port,
      sessionToken: token,
      pinCode: pin,
      source: effectiveSource,
      serverDeviceName: _deviceName,
    );



    AppLogger.info(
      'Audio Handoff Server started on ws://$localIp:${_server!.port}',
      feature: 'audio_handoff',
    );

    _startBroadcastLoop();
    unawaited(_discoveryBroadcaster.start(_sessionInfo!));
    return _sessionInfo!;
  }

  /// Updates the media source if TV channel/VOD changes while server is running.
  void updateSource(PlayerSource source) {
    _currentSource = source;
    if (_sessionInfo != null) {
      _sessionInfo = HandoffSessionInfo(
        hostIp: _sessionInfo!.hostIp,
        port: _sessionInfo!.port,
        sessionToken: _sessionInfo!.sessionToken,
        pinCode: _sessionInfo!.pinCode,
        source: source,
        serverDeviceName: _deviceName,
      );
    }

    _broadcastSourceChange(source);
  }

  void _handleNewClient(WebSocketChannel channel) {
    _clients.add(channel);
    AppLogger.info(
      'Companion connected. Total clients: ${_clients.length}',
      feature: 'audio_handoff',
    );
    _clientCountCallback?.call(_clients.length);

    // Immediately send current source and initial sync snapshot to the newly connected companion
    if (_currentSource != null) {
      _sendInitialPayload(channel, _currentSource!);
    }

    channel.stream.listen(
      (dynamic rawMessage) {
        _handleClientMessage(channel, rawMessage);
      },
      onDone: () {
        _clients.remove(channel);
        AppLogger.info(
          'Companion disconnected. Remaining: ${_clients.length}',
          feature: 'audio_handoff',
        );
        _clientCountCallback?.call(_clients.length);
      },
      onError: (Object error) {
        _clients.remove(channel);
        AppLogger.warning(
          'Companion socket error: $error',
          feature: 'audio_handoff',
        );
        _clientCountCallback?.call(_clients.length);
      },
      cancelOnError: true,
    );
  }

  void _sendInitialPayload(WebSocketChannel channel, PlayerSource source) {
    try {
      final initialMsg = {
        'type': 'handshake_ack',
        'dev': _deviceName,
        'src': {
          'url': source.url,
          'title': source.title,
          'logo': source.logoUrl,
          'prof': source.profile.name,
          'st': source.streamType.name,
          'hdrs': source.headers,
          'chId': source.channelId,
          'catId': source.categoryId,
          'prog': source.currentProgramTitle,
        },
        'sync': _buildCurrentSyncPacket().toJson(),
      };
      channel.sink.add(jsonEncode(initialMsg));
    } catch (e) {
      AppLogger.error(
        'Failed to send initial payload: $e',
        feature: 'audio_handoff',
      );
    }
  }

  void _broadcastSourceChange(PlayerSource source) {
    final msg = jsonEncode({
      'type': 'source_change',
      'src': {
        'url': source.url,
        'title': source.title,
        'logo': source.logoUrl,
        'prof': source.profile.name,
        'st': source.streamType.name,
        'hdrs': source.headers,
        'chId': source.channelId,
        'catId': source.categoryId,
        'prog': source.currentProgramTitle,
      },
    });

    _broadcastRaw(msg);
  }

  void _startBroadcastLoop() {
    _syncTimer?.cancel();
    // Broadcast sync state every 500ms for tight sub-100ms synchronization
    _syncTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_clients.isEmpty) return;
      final packet = _buildCurrentSyncPacket();
      final raw = jsonEncode(packet.toJson());
      _broadcastRaw(raw);
    });
  }

  HandoffSyncPacket _buildCurrentSyncPacket() {
    return HandoffSyncPacket(
      serverTimestampMs: DateTime.now().millisecondsSinceEpoch,
      positionMs: _getPositionMs?.call() ?? 0,
      durationMs: _getDurationMs?.call() ?? 0,
      isPlaying: _getIsPlaying?.call() ?? false,
      isBuffering: _getIsBuffering?.call() ?? false,
      streamUrl: _currentSource?.url,
      title: _currentSource?.title,
      channelId: _currentSource?.channelId,
      isLive: _currentSource?.isLive ?? false,
    );
  }

  /// Updates playback clock suppliers without restarting the WebSocket server.
  void bindPlaybackSuppliers({
    int Function()? getPositionMs,
    int Function()? getDurationMs,
    bool Function()? getIsPlaying,
    bool Function()? getIsBuffering,
    HandoffCommandHandler? onCommand,
    HandoffClientCountCallback? onClientCountChanged,
  }) {
    if (getPositionMs != null) _getPositionMs = getPositionMs;
    if (getDurationMs != null) _getDurationMs = getDurationMs;
    if (getIsPlaying != null) _getIsPlaying = getIsPlaying;
    if (getIsBuffering != null) _getIsBuffering = getIsBuffering;
    if (onCommand != null) _commandHandler = onCommand;
    if (onClientCountChanged != null) {
      _clientCountCallback = onClientCountChanged;
    }
  }

  /// Updates the LAN IP advertised in discovery beacons without dropping clients.
  Future<HandoffSessionInfo?> refreshAdvertisedIp() async {
    if (_sessionInfo == null) return null;
    final localIp = await _findLocalIpAddress();
    _sessionInfo = HandoffSessionInfo(
      hostIp: localIp,
      port: _sessionInfo!.port,
      sessionToken: _sessionInfo!.sessionToken,
      pinCode: _sessionInfo!.pinCode,
      source: _currentSource ?? _sessionInfo!.source,
      serverDeviceName: _deviceName,
    );
    _discoveryBroadcaster.updateSession(_sessionInfo!);
    return _sessionInfo;
  }

  void updateAdvertisedSession(HandoffSessionInfo session) {
    _sessionInfo = session;
    _discoveryBroadcaster.updateSession(session);
  }

  void _broadcastRaw(String raw) {
    final deadClients = <WebSocketChannel>[];
    for (final client in _clients) {
      try {
        client.sink.add(raw);
      } catch (e) {
        deadClients.add(client);
      }
    }
    if (deadClients.isNotEmpty) {
      _clients.removeAll(deadClients);
      _clientCountCallback?.call(_clients.length);
    }
  }

  void _handleClientMessage(WebSocketChannel channel, dynamic rawMessage) {
    try {
      final map = jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'ping') {
        final clientTime = map['t'];
        channel.sink.add(
          jsonEncode({
            'type': 'pong',
            'clientTime': clientTime,
            'serverTime': DateTime.now().millisecondsSinceEpoch,
          }),
        );
        return;
      }

      if (type == 'command') {
        final command = HandoffCommand.fromJson(map);
        _commandHandler?.call(command);
      }
    } catch (e) {
      AppLogger.warning(
        'Invalid client message: $e',
        feature: 'audio_handoff',
      );
    }
  }

  /// Stops the server and closes all active companion sessions.
  Future<void> stop() async {
    _syncTimer?.cancel();
    _syncTimer = null;

    for (final client in _clients) {
      try {
        await client.sink.close();
      } catch (_) {}
    }
    _clients.clear();
    _clientCountCallback?.call(0);
    await _discoveryBroadcaster.stop();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _sessionInfo = null;
    AppLogger.info('Audio Handoff Server stopped', feature: 'audio_handoff');
  }

  /// Discovers the active LAN IPv4 address reachable by devices on the local Wi-Fi / Ethernet / Mobile Hotspot.
  ///
  /// IMPORTANT: On Android, Socket.connect('8.8.8.8') can return the mobile data
  /// interface IP when the device is simultaneously on Wi-Fi + mobile data. We
  /// ALWAYS prioritize the physical Wi-Fi/Ethernet interface IP to ensure LAN
  /// devices on the same network can reach each other.
  Future<String> _findLocalIpAddress() async {
    // 1. ALWAYS prefer physical Wi-Fi / Ethernet interface first (most reliable for LAN)
    try {
      final allIps = await getAvailableLocalIps();
      if (allIps.isNotEmpty) {
        AppLogger.info(
          'Active LAN IP resolved via interface scan: ${allIps.first} (all: $allIps)',
          feature: 'audio_handoff',
        );
        return allIps.first;
      }
    } catch (e) {
      AppLogger.warning(
        'Failed to resolve local IP from interfaces: $e',
        feature: 'audio_handoff',
      );
    }

    // 2. Fallback: routing socket trick
    try {
      final s = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(milliseconds: 300),
      );
      final ip = s.address.address;
      s.destroy();
      if (ip != '127.0.0.1' && !ip.startsWith('169.254.') && ip != '0.0.0.0') {
        return ip;
      }
    } catch (_) {}

    return '127.0.0.1';
  }

  /// Returns ALL valid LAN IPs (Wi-Fi + others). Used to embed in beacon
  /// so the scanner can try each IP, ensuring discovery even when the
  /// primary IP advertised is behind a virtual adapter.
  Future<List<String>> getAllLanIps() async {
    return getAvailableLocalIps();
  }


  /// Lists all valid, non-virtual IPv4 addresses on the host device.
  Future<List<String>> getAvailableLocalIps() async {
    final physicalIps = <String>[];
    final otherIps = <String>[];

    const virtualKeywords = [
      'wsl',
      'vethernet',
      'hyper-v',
      'virtual',
      'vmware',
      'vbox',
      'docker',
      'container',
      'tap',
      'tun',
      'pseudo',
      'dummy',
      'bridge',
      'teredo',
      'isatap',
      'bluetooth',
      'loopback',
    ];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        final nameLower = iface.name.toLowerCase();
        final isVirtual = virtualKeywords.any(nameLower.contains);

        for (final addr in iface.addresses) {
          if (addr.isLoopback || addr.type != InternetAddressType.IPv4) continue;
          final ip = addr.address;
          if (ip.startsWith('169.254.') || ip == '0.0.0.0' || ip == '127.0.0.1') {
            continue;
          }

          if (!isVirtual) {
            final isWifiOrEth = nameLower.contains('wi-fi') ||
                nameLower.contains('wifi') ||
                nameLower.contains('wlan') ||
                nameLower.contains('eth') ||
                nameLower.contains('en');
            if (isWifiOrEth) {
              physicalIps.insert(0, ip); // Highest priority
            } else {
              physicalIps.add(ip);
            }
          } else {
            otherIps.add(ip);
          }
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Error querying network interfaces: $e',
        feature: 'audio_handoff',
      );
    }

    final combined = [...physicalIps, ...otherIps];
    return combined.toSet().toList();
  }

  String _generateRandomToken(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  String _renderWebCompanionHtml({
    required String token,
    required String pin,
    required String localIp,
    required int port,
    required PlayerSource source,
  }) {
    final title = source.title.replaceAll('"', '&quot;');
    final streamUrl = source.url;

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <title>HOPE TV Remote & Audio Companion</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
    body {
      background: #090B0F;
      color: #F8FAFC;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 12px 14px;
      user-select: none;
      -webkit-user-select: none;
    }
    .card {
      background: rgba(30, 41, 59, 0.85);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 24px;
      padding: 18px 16px;
      width: 100%;
      max-width: 440px;
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.6);
      backdrop-filter: blur(24px);
      -webkit-backdrop-filter: blur(24px);
      display: flex;
      flex-direction: column;
      gap: 12px;
    }
    .header-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 10px;
      border-radius: 20px;
      font-size: 11.5px;
      font-weight: 700;
      letter-spacing: 0.5px;
      background: rgba(16, 185, 129, 0.15);
      color: #10B981;
      border: 1px solid rgba(16, 185, 129, 0.3);
    }
    .dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #10B981;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
      0% { opacity: 0.4; }
      50% { opacity: 1; transform: scale(1.15); }
      100% { opacity: 0.4; }
    }
    .status-text {
      font-size: 11px;
      color: #94A3B8;
      font-weight: 600;
    }
    .title-banner {
      background: rgba(0, 0, 0, 0.3);
      border-radius: 12px;
      padding: 8px 12px;
      border: 1px solid rgba(255, 255, 255, 0.05);
    }
    .title {
      font-size: 16px;
      font-weight: 800;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      color: #FFF;
    }
    .sub {
      color: #94A3B8;
      font-size: 11.5px;
      margin-top: 2px;
    }

    /* Tab Switcher */
    .tab-bar {
      display: flex;
      background: rgba(15, 23, 42, 0.7);
      border-radius: 14px;
      padding: 4px;
      border: 1px solid rgba(255, 255, 255, 0.08);
      gap: 4px;
    }
    .tab-btn {
      flex: 1;
      padding: 8px 4px;
      border-radius: 10px;
      border: none;
      background: transparent;
      color: #94A3B8;
      font-size: 12.5px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.2s;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 5px;
    }
    .tab-btn.active {
      background: #00F0FF;
      color: #000;
      box-shadow: 0 2px 10px rgba(0, 240, 255, 0.3);
    }

    /* Tab Views */
    .tab-content {
      display: none;
      flex-direction: column;
      gap: 12px;
    }
    .tab-content.active {
      display: flex;
    }

    /* Buttons */
    .btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 100%;
      padding: 12px;
      border-radius: 12px;
      border: none;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
      transition: all 0.15s active;
    }
    .btn:active {
      transform: scale(0.97);
    }
    .btn-primary {
      background: #00F0FF;
      color: #000;
      box-shadow: 0 4px 14px rgba(0, 240, 255, 0.35);
    }
    .btn-secondary {
      background: rgba(255, 255, 255, 0.08);
      color: #FFF;
      border: 1px solid rgba(255, 255, 255, 0.12);
    }
    .btn-app {
      background: rgba(255, 255, 255, 0.05);
      color: #CBD5E1;
      border: 1px solid rgba(255, 255, 255, 0.1);
      text-decoration: none;
      font-size: 12px;
      padding: 8px;
    }

    .section {
      background: rgba(0, 0, 0, 0.28);
      border-radius: 14px;
      padding: 12px;
      border: 1px solid rgba(255, 255, 255, 0.06);
    }
    .section-title {
      display: flex;
      justify-content: space-between;
      font-size: 11.5px;
      font-weight: 600;
      color: #CBD5E1;
      margin-bottom: 6px;
    }
    input[type=range] {
      width: 100%;
      accent-color: #00F0FF;
      margin: 6px 0;
    }
    .nudge-row {
      display: flex;
      gap: 6px;
      justify-content: center;
      margin-top: 4px;
    }
    .nudge-btn {
      padding: 5px 10px;
      border-radius: 6px;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: #CBD5E1;
      font-size: 11px;
      font-weight: 600;
      cursor: pointer;
    }
    .nudge-btn:active {
      background: rgba(0, 240, 255, 0.2);
    }

    /* Trackpad Tab */
    .trackpad-area {
      height: 250px;
      background: radial-gradient(circle at center, rgba(30, 41, 59, 0.9), rgba(15, 23, 42, 0.95));
      border: 1.5px dashed rgba(0, 240, 255, 0.35);
      border-radius: 18px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      color: #64748B;
      font-size: 13px;
      font-weight: 600;
      touch-action: none;
      position: relative;
      overflow: hidden;
      box-shadow: inset 0 2px 10px rgba(0, 0, 0, 0.5);
    }
    .trackpad-area.active {
      border-color: #00F0FF;
      box-shadow: inset 0 0 20px rgba(0, 240, 255, 0.2);
    }
    .trackpad-hint {
      pointer-events: none;
      text-align: center;
      line-height: 1.5;
    }
    .trackpad-buttons {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
    }
    .click-btn {
      padding: 14px;
      border-radius: 12px;
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.12);
      color: #FFF;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      text-align: center;
    }
    .click-btn:active {
      background: #00F0FF;
      color: #000;
    }

    /* Keyboard & D-Pad Tab */
    .input-box-row {
      display: flex;
      gap: 8px;
    }
    .text-input {
      flex: 1;
      padding: 12px 14px;
      border-radius: 12px;
      background: rgba(0, 0, 0, 0.4);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: #FFF;
      font-size: 14px;
      outline: none;
      user-select: auto;
      -webkit-user-select: auto;
    }
    .text-input:focus {
      border-color: #00F0FF;
      box-shadow: 0 0 10px rgba(0, 240, 255, 0.25);
    }
    .send-btn {
      padding: 0 16px;
      border-radius: 12px;
      background: #00F0FF;
      color: #000;
      border: none;
      font-weight: 700;
      font-size: 13px;
      cursor: pointer;
    }

    .dpad-container {
      display: flex;
      flex-direction: column;
      align-items: center;
      margin: 6px 0;
    }
    .dpad-grid {
      display: grid;
      grid-template-columns: 56px 56px 56px;
      grid-template-rows: 56px 56px 56px;
      gap: 8px;
    }
    .dpad-btn {
      background: rgba(255, 255, 255, 0.07);
      border: 1px solid rgba(255, 255, 255, 0.12);
      border-radius: 14px;
      color: #FFF;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
      cursor: pointer;
      transition: all 0.1s;
    }
    .dpad-btn:active {
      background: #00F0FF;
      color: #000;
      transform: scale(0.92);
    }
    .dpad-ok {
      background: rgba(0, 240, 255, 0.2);
      border: 1px solid rgba(0, 240, 255, 0.4);
      color: #00F0FF;
      font-size: 13px;
      font-weight: 800;
    }
    .dpad-ok:active {
      background: #00F0FF;
      color: #000;
    }

    .nav-actions-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 8px;
    }
    .nav-act-btn {
      padding: 10px 4px;
      border-radius: 10px;
      background: rgba(255, 255, 255, 0.06);
      border: 1px solid rgba(255, 255, 255, 0.1);
      color: #CBD5E1;
      font-size: 11.5px;
      font-weight: 600;
      text-align: center;
      cursor: pointer;
    }
    .nav-act-btn:active {
      background: rgba(0, 240, 255, 0.2);
      color: #FFF;
    }
  </style>
</head>
<body>
  <div class="card">
    <!-- Header -->
    <div class="header-row">
      <div class="badge"><div class="dot"></div> LIVE COMPANION</div>
      <div id="syncStatus" class="status-text">Connecting...</div>
    </div>

    <div class="title-banner">
      <div class="title" id="trackTitle">$title</div>
      <div class="sub">HOPE TV Controller & Audio Sync</div>
    </div>

    <!-- Segmented Tab Navigation -->
    <div class="tab-bar">
      <button class="tab-btn active" onclick="switchTab('audio')">🎧 Audio</button>
      <button class="tab-btn" onclick="switchTab('trackpad')">🖱️ Mouse</button>
      <button class="tab-btn" onclick="switchTab('keyboard')">⌨️ Remote</button>
    </div>

    <!-- TAB 1: AUDIO STREAMING -->
    <div id="tab-audio" class="tab-content active">
      <audio id="audioEl" playsinline preload="auto" src="$streamUrl"></audio>

      <button id="playBtn" class="btn btn-primary" onclick="togglePlay()">
        Tap to Start Listening
      </button>

      <div class="section">
        <div class="section-title">
          <span>Bluetooth Latency Offset</span>
          <span id="offsetLabel" style="color: #00F0FF; font-weight: 700;">0 ms</span>
        </div>
        <input type="range" id="offsetSlider" min="-500" max="500" step="25" value="0" oninput="onOffsetChange(this.value)">
        <div class="nudge-row">
          <button class="nudge-btn" onclick="nudgeOffset(-50)">-50ms</button>
          <button class="nudge-btn" onclick="nudgeOffset(0)">Reset</button>
          <button class="nudge-btn" onclick="nudgeOffset(50)">+50ms</button>
        </div>
      </div>

      <div class="section">
        <div style="display: flex; gap: 8px;">
          <button id="muteTvBtn" class="nudge-btn" style="flex: 1; padding: 10px; color: #FFF;" onclick="toggleTvMute()">
            Mute TV Speakers
          </button>
          <button class="nudge-btn" style="flex: 1; padding: 10px; color: #FFF;" onclick="toggleTvPlayPause()">
            Play / Pause TV
          </button>
        </div>
      </div>

      <a id="appLink" class="btn btn-app" href="iptv://handoff?host=$localIp&port=$port&token=$token&pin=$pin">
        Open in HOPE IPTV App
      </a>
    </div>

    <!-- TAB 2: TOUCHPAD MOUSE -->
    <div id="tab-trackpad" class="tab-content">
      <div id="trackpad" class="trackpad-area">
        <div class="trackpad-hint">
          <span>🖱️ Slide to Move Cursor</span><br>
          <span style="font-size: 11px; opacity: 0.7;">Tap to Click • 2-Finger Scroll</span>
        </div>
      </div>

      <div class="trackpad-buttons">
        <button class="click-btn" onclick="sendMouseTap('left')">Left Click</button>
        <button class="click-btn" onclick="sendKeyPress('back')">Back (Esc)</button>
      </div>

      <div class="section">
        <div class="section-title">
          <span>Pointer Sensitivity</span>
          <span id="sensLabel" style="color: #00F0FF; font-weight: 700;">1.2x</span>
        </div>
        <input type="range" id="sensSlider" min="0.4" max="2.5" step="0.1" value="1.2" oninput="onSensChange(this.value)">
      </div>
    </div>

    <!-- TAB 3: KEYBOARD & REMOTE -->
    <div id="tab-keyboard" class="tab-content">
      <!-- Live Keyboard Input -->
      <div class="input-box-row">
        <input type="text" id="typeInput" class="text-input" placeholder="Type to send text to TV..." autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" onkeydown="onInputKey(event)">
        <button class="send-btn" onclick="submitTypedText()">Send</button>
      </div>

      <div style="display: flex; gap: 6px; justify-content: flex-end;">
        <button class="nudge-btn" onclick="sendKeyPress('backspace')">⌫ Backspace</button>
        <button class="nudge-btn" onclick="sendKeyPress('enter')">↵ Enter</button>
        <button class="nudge-btn" onclick="clearTypedText()">Clear</button>
      </div>

      <!-- D-Pad Directional Controller -->
      <div class="dpad-container">
        <div class="dpad-grid">
          <div></div>
          <button class="dpad-btn" onclick="sendKeyPress('up')">▲</button>
          <div></div>
          <button class="dpad-btn" onclick="sendKeyPress('left')">◀</button>
          <button class="dpad-btn dpad-ok" onclick="sendKeyPress('select')">OK</button>
          <button class="dpad-btn" onclick="sendKeyPress('right')">▶</button>
          <div></div>
          <button class="dpad-btn" onclick="sendKeyPress('down')">▼</button>
          <div></div>
        </div>
      </div>

      <!-- Navigation Actions -->
      <div class="nav-actions-grid">
        <button class="nav-act-btn" onclick="sendKeyPress('back')">↩ Back</button>
        <button class="nav-act-btn" onclick="sendKeyPress('home')">🏠 Home</button>
        <button class="nav-act-btn" onclick="sendKeyPress('play_pause')">⏯ Play</button>
        <button class="nav-act-btn" onclick="toggleTvMute()">🔇 Mute</button>
      </div>
    </div>
  </div>

  <script>
    let ws;
    let bluetoothOffset = 0;
    let sensitivity = 1.2;
    let tvPosMs = 0;
    let lastSeekTime = 0;
    let isTvMuted = false;
    let isLiveStream = false;

    const audio = document.getElementById('audioEl');
    const playBtn = document.getElementById('playBtn');
    const offsetLabel = document.getElementById('offsetLabel');
    const offsetSlider = document.getElementById('offsetSlider');
    const syncStatus = document.getElementById('syncStatus');
    const muteTvBtn = document.getElementById('muteTvBtn');
    const trackpad = document.getElementById('trackpad');
    const sensLabel = document.getElementById('sensLabel');
    const typeInput = document.getElementById('typeInput');

    function switchTab(tabId) {
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
      event.target.classList.add('active');
      document.getElementById('tab-' + tabId).classList.add('active');
    }

    function connectWs() {
      const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
      ws = new WebSocket(proto + '//' + location.host + '/audio-handoff?token=$token');

      ws.onopen = function() {
        syncStatus.innerText = 'Connected';
        syncStatus.style.color = '#10B981';
      };

      ws.onmessage = function(e) {
        try {
          const msg = JSON.parse(e.data);
          if (msg.type === 'sync_tick') {
            tvPosMs = msg.pos;
            isLiveStream = !!msg.live || !msg.dur;
            if (msg.play === false) {
              if (!audio.paused) audio.pause();
            }
            if (msg.title) {
              document.getElementById('trackTitle').innerText = msg.title;
            }
            syncAudio();
          } else if (msg.type === 'handshake_ack' || msg.type === 'source_change') {
            if (msg.src && msg.src.url && msg.src.url !== audio.src) {
              audio.src = msg.src.url;
              if (msg.src.title) {
                document.getElementById('trackTitle').innerText = msg.src.title;
              }
              if (!audio.paused) audio.play();
            }
          }
        } catch(_) {}
      };

      ws.onclose = function() {
        syncStatus.innerText = 'Reconnecting...';
        syncStatus.style.color = '#F59E0B';
        setTimeout(connectWs, 2000);
      };
    }

    function sendCommand(act, payload = {}) {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
          type: 'command',
          act: act,
          data: payload
        }));
      }
    }

    /* --- Audio Sync --- */
    function syncAudio() {
      if (audio.paused) return;
      if (isLiveStream) {
        syncStatus.innerText = 'Live';
        syncStatus.style.color = '#10B981';
        return;
      }
      if (!tvPosMs) return;
      const targetSec = (tvPosMs + bluetoothOffset) / 1000.0;
      const currentSec = audio.currentTime;
      const driftSec = targetSec - currentSec;
      const driftMs = Math.round(driftSec * 1000);

      if (Math.abs(driftMs) <= 120) {
        syncStatus.innerText = 'In Sync (' + (driftMs >= 0 ? '+' : '') + driftMs + 'ms)';
        syncStatus.style.color = '#10B981';
      } else {
        syncStatus.innerText = 'Realigning (' + (driftMs >= 0 ? '+' : '') + driftMs + 'ms)';
        syncStatus.style.color = '#F59E0B';

        const now = Date.now();
        if (now - lastSeekTime > 1500 && Math.abs(driftMs) > 200) {
          lastSeekTime = now;
          audio.currentTime = Math.max(0, targetSec);
        }
      }
    }

    function togglePlay() {
      if (audio.paused) {
        audio.play().then(() => {
          playBtn.innerText = 'Pause Listening';
          playBtn.style.background = 'rgba(255, 255, 255, 0.15)';
          playBtn.style.color = '#FFF';
        }).catch(() => {});
      } else {
        audio.pause();
        playBtn.innerText = 'Resume Listening';
        playBtn.style.background = '#00F0FF';
        playBtn.style.color = '#000';
      }
    }

    function onOffsetChange(val) {
      bluetoothOffset = parseInt(val, 10);
      offsetLabel.innerText = (bluetoothOffset >= 0 ? '+' : '') + bluetoothOffset + ' ms';
      syncAudio();
    }

    function nudgeOffset(val) {
      if (val === 0) bluetoothOffset = 0;
      else bluetoothOffset += val;
      bluetoothOffset = Math.max(-500, Math.min(500, bluetoothOffset));
      offsetSlider.value = bluetoothOffset;
      offsetLabel.innerText = (bluetoothOffset >= 0 ? '+' : '') + bluetoothOffset + ' ms';
      syncAudio();
    }

    function toggleTvMute() {
      isTvMuted = !isTvMuted;
      sendCommand(isTvMuted ? 'mute_tv' : 'unmute_tv');
      muteTvBtn.innerText = isTvMuted ? 'Unmute TV Speakers' : 'Mute TV Speakers';
      muteTvBtn.style.background = isTvMuted ? 'rgba(239, 68, 68, 0.3)' : 'rgba(255, 255, 255, 0.08)';
    }

    function toggleTvPlayPause() {
      sendCommand('toggle_play_pause');
    }

    /* --- Touchpad Logic --- */
    let touchStartX = 0;
    let touchStartY = 0;
    let touchLastX = 0;
    let touchLastY = 0;
    let touchStartTime = 0;
    let hasMoved = false;

    function onSensChange(val) {
      sensitivity = parseFloat(val);
      sensLabel.innerText = sensitivity.toFixed(1) + 'x';
    }

    trackpad.addEventListener('touchstart', function(e) {
      trackpad.classList.add('active');
      const touch = e.touches[0];
      touchStartX = touch.clientX;
      touchStartY = touch.clientY;
      touchLastX = touch.clientX;
      touchLastY = touch.clientY;
      touchStartTime = Date.now();
      hasMoved = false;
    }, { passive: true });

    trackpad.addEventListener('touchmove', function(e) {
      if (e.touches.length === 1) {
        const touch = e.touches[0];
        const dx = (touch.clientX - touchLastX) * sensitivity;
        const dy = (touch.clientY - touchLastY) * sensitivity;
        touchLastX = touch.clientX;
        touchLastY = touch.clientY;

        if (Math.abs(dx) > 0.5 || Math.abs(dy) > 0.5) {
          hasMoved = true;
          sendCommand('mouse_move', { dx: dx, dy: dy });
        }
      } else if (e.touches.length === 2) {
        const touch1 = e.touches[0];
        const dy = (touch1.clientY - touchLastY) * 2.0;
        touchLastY = touch1.clientY;
        sendCommand('mouse_scroll', { dx: 0, dy: -dy });
      }
    }, { passive: true });

    trackpad.addEventListener('touchend', function(e) {
      trackpad.classList.remove('active');
      const duration = Date.now() - touchStartTime;
      if (!hasMoved && duration < 300) {
        sendCommand('mouse_tap', { button: 'left' });
      }
    }, { passive: true });

    function sendMouseTap(btn = 'left') {
      sendCommand('mouse_tap', { button: btn });
    }

    /* --- Remote & Keyboard Logic --- */
    function sendKeyPress(key) {
      sendCommand('key_press', { key: key });
    }

    function onInputKey(e) {
      if (e.key === 'Enter') {
        submitTypedText();
      }
    }

    function submitTypedText() {
      const val = typeInput.value;
      if (val) {
        sendCommand('type_text', { text: val, replace: false });
        typeInput.value = '';
      }
    }

    function clearTypedText() {
      typeInput.value = '';
    }

    connectWs();
  </script>
</body>
</html>
''';
  }
}

