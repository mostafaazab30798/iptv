import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef CompanionCredentialsCallback =
    void Function(CompanionAuthCredentialsPayload credentials);

/// Server hosted on the target device during Onboarding to securely receive
/// transferred IPTV & App Account credentials from an already signed-in companion phone.
class CompanionAuthServer {
  CompanionAuthServer({
    int port = 8998,
    String? deviceName,
  }) : _port = port,
       _deviceName = deviceName ?? _detectDefaultDeviceName();

  final int _port;
  final String _deviceName;

  HttpServer? _server;
  CompanionAuthHandoffInfo? _sessionInfo;
  CompanionCredentialsCallback? _credentialsCallback;
  final Set<WebSocketChannel> _wsClients = {};

  bool get isRunning => _server != null;
  CompanionAuthHandoffInfo? get sessionInfo => _sessionInfo;

  static String _detectDefaultDeviceName() {
    try {
      final host = Platform.localHostname;
      if (Platform.isWindows) return 'Windows Screen ($host)';
      if (Platform.isMacOS) return 'Mac Screen ($host)';
      if (Platform.isLinux) return 'Linux Screen ($host)';
      if (Platform.isAndroid) return 'Android Screen ($host)';
      if (Platform.isIOS) return 'iOS Screen ($host)';
    } catch (_) {}
    return 'IPTV Screen';
  }

  /// Starts the pairing listener on local LAN.
  Future<CompanionAuthHandoffInfo> start({
    required CompanionCredentialsCallback onCredentialsReceived,
  }) async {
    await stop();
    _credentialsCallback = onCredentialsReceived;

    final localIp = await _findLocalIpAddress();
    final token = _generateRandomToken(16);
    final pin = (1000 + Random().nextInt(9000)).toString();

    final wsHandler = webSocketHandler((WebSocketChannel channel) {
      _wsClients.add(channel);
      channel.stream.listen(
        (dynamic rawMessage) {
          _handleWsMessage(channel, rawMessage);
        },
        onDone: () => _wsClients.remove(channel),
        onError: (_) => _wsClients.remove(channel),
        cancelOnError: true,
      );
    });

    shelf.Response handleHttp(shelf.Request request) {
      // 1. Health probe / GET beacon
      if (request.method == 'GET') {
        if (request.url.path == 'auth-handoff' ||
            request.url.path == 'companion-info' ||
            request.url.path.isEmpty) {
          return shelf.Response.ok(
            jsonEncode({
              'type': 'auth_handoff',
              'dev': _deviceName,
              'ip': localIp,
              'port': _server?.port ?? _port,
              'tok': token,
              'pin': pin,
            }),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      }

      // 2. HTTP POST Credential Transfer
      if (request.method == 'POST' &&
          (request.url.path == 'transfer-auth' ||
              request.url.path == 'auth-handoff')) {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': 'use_async_handler'}),
        );
      }

      return shelf.Response.notFound('Not found');
    }

    Future<shelf.Response> appPipeline(shelf.Request request) async {
      // WebSocket upgrade check
      if (request.headers['upgrade']?.toLowerCase() == 'websocket' ||
          request.url.path == 'companion-auth') {
        return wsHandler(request);
      }

      // Direct HTTP POST payload
      if (request.method == 'POST' &&
          (request.url.path == 'transfer-auth' ||
              request.url.path == 'auth-handoff')) {
        try {
          final bodyString = await request.readAsString();
          final map = jsonDecode(bodyString) as Map<String, dynamic>;
          final payload = CompanionAuthCredentialsPayload.fromJson(map);

          // Verify token and PIN
          if (payload.token != token || payload.pin != pin) {
            AppLogger.warning(
              'Rejected auth transfer: invalid token or PIN',
              feature: 'companion_auth',
            );
            return shelf.Response.forbidden(
              jsonEncode({
                'success': false,
                'error': 'Invalid token or PIN code',
              }),
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }

          AppLogger.info(
            'Received valid companion credentials payload for server: ${payload.serverUrl}',
            feature: 'companion_auth',
          );

          // Notify listener callback
          _credentialsCallback?.call(payload);

          // Notify any connected WS clients
          _broadcastWs({
            'type': 'auth_success',
            'dev': payload.companionDeviceName,
          });

          return shelf.Response.ok(
            jsonEncode({'success': true}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } catch (e) {
          AppLogger.error(
            'Error parsing transfer-auth POST: $e',
            feature: 'companion_auth',
          );
          return shelf.Response.badRequest(
            body: jsonEncode({'success': false, 'error': e.toString()}),
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
      }

      return handleHttp(request);
    }

    HttpServer? bound;
    for (final candidate in [_port, 8997, 8996, 0]) {
      try {
        bound = await shelf_io.serve(
          appPipeline,
          InternetAddress.anyIPv4,
          candidate,
          shared: false,
        );
        break;
      } catch (e) {
        AppLogger.warning(
          'Port $candidate unavailable for Companion Auth server: $e',
          feature: 'companion_auth',
        );
      }
    }

    if (bound == null) {
      throw Exception('Could not bind port for Companion Auth Server');
    }

    _server = bound;
    _sessionInfo = CompanionAuthHandoffInfo(
      hostIp: localIp,
      port: bound.port,
      sessionToken: token,
      pinCode: pin,
      targetDeviceName: _deviceName,
    );

    AppLogger.info(
      'Companion Auth Server listening at http://$localIp:${bound.port} (PIN: $pin)',
      feature: 'companion_auth',
    );

    return _sessionInfo!;
  }

  void _handleWsMessage(WebSocketChannel channel, dynamic raw) {
    try {
      final map = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'auth_transfer') {
        final payload = CompanionAuthCredentialsPayload.fromJson(map);
        if (payload.token == _sessionInfo?.sessionToken &&
            payload.pin == _sessionInfo?.pinCode) {
          _credentialsCallback?.call(payload);
          channel.sink.add(
            jsonEncode({'type': 'auth_ack', 'success': true}),
          );
        } else {
          channel.sink.add(
            jsonEncode({
              'type': 'auth_ack',
              'success': false,
              'error': 'Invalid token or PIN',
            }),
          );
        }
      }
    } catch (_) {}
  }

  void _broadcastWs(Map<String, dynamic> data) {
    final raw = jsonEncode(data);
    for (final client in _wsClients) {
      try {
        client.sink.add(raw);
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    for (final client in _wsClients) {
      try {
        await client.sink.close();
      } catch (_) {}
    }
    _wsClients.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }
    _sessionInfo = null;
    _credentialsCallback = null;
    AppLogger.info('Companion Auth Server stopped', feature: 'companion_auth');
  }

  Future<String> _findLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        // Skip virtual or VPN adapters
        if (name.contains('vethernet') ||
            name.contains('wsl') ||
            name.contains('virtual') ||
            name.contains('pseudo') ||
            name.contains('vmware') ||
            name.contains('vbox') ||
            name.contains('tun') ||
            name.contains('tap') ||
            name.contains('docker') ||
            name.contains('loopback')) {
          continue;
        }
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              !addr.address.startsWith('169.254.') &&
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    try {
      final s = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(milliseconds: 350),
      );
      final ip = s.address.address;
      s.destroy();
      if (ip != '127.0.0.1' && !ip.startsWith('169.254.')) {
        return ip;
      }
    } catch (_) {}

    return '127.0.0.1';
  }

  String _generateRandomToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
