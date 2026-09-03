import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';


const int kHandoffDiscoveryPort = 8999;
const String kDiscoveryBeaconType = 'hope_tv_beacon';
const String kDiscoveryProbeType = 'hope_phone_probe';

/// Tracks self session tokens across broadcaster and scanner instances on this device.
final Set<String> _kSelfSessionTokens = <String>{};
final Set<String> _kSelfIps = <String>{};

/// Broadcasts UDP discovery beacons on the local network / mobile hotspot
/// so companion phones can auto-discover the TV without manual IP or QR scanning.
class AudioHandoffDiscoveryBroadcaster {
  RawDatagramSocket? _socket;
  Timer? _beaconTimer;
  HandoffSessionInfo? _sessionInfo;

  bool get isRunning => _socket != null;

  /// Starts broadcasting UDP beacons on port 8999 with directed subnet broadcast.
  Future<void> start(HandoffSessionInfo sessionInfo) async {
    await stop();
    _sessionInfo = sessionInfo;
    _kSelfSessionTokens.add(sessionInfo.sessionToken);
    _kSelfIps.add(sessionInfo.hostIp);

    try {
      RawDatagramSocket? boundSocket;
      try {
        boundSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          kHandoffDiscoveryPort,
          reuseAddress: true,
        );
      } catch (_) {
        boundSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          0,
          reuseAddress: true,
        );
      }
      _socket = boundSocket;
      _socket?.broadcastEnabled = true;

      // Listen for incoming probe queries from companion clients
      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleIncomingPacket(datagram);
          }
        }
      });

      // Broadcast beacon every 1.5 seconds
      _beaconTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _sendBeacon(),
      );

      // Send initial beacon immediately
      unawaited(_sendBeacon());


      AppLogger.info(
        'Audio Handoff UDP Discovery Broadcaster active on port ${_socket?.port}',
        feature: 'audio_handoff',
      );
    } catch (e) {
      AppLogger.warning(
        'Could not start UDP discovery broadcaster: $e',
        feature: 'audio_handoff',
      );
    }
  }

  void updateSession(HandoffSessionInfo sessionInfo) {
    _sessionInfo = sessionInfo;
    _sendBeacon();
  }

  Future<void> _sendBeacon() async {
    if (_socket == null || _sessionInfo == null) return;

    try {
      // Collect ALL local LAN IPs to broadcast in the beacon
      // This is critical: on Android, a device may have Wi-Fi IP + mobile data IP.
      // We broadcast all IPs so the scanner on the other device can try each one.
      final allLocalIps = <String>[_sessionInfo!.hostIp];
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final ip = addr.address;
            if (!ip.startsWith('169.254.') &&
                ip != '127.0.0.1' &&
                ip != '0.0.0.0') {
              if (!allLocalIps.contains(ip)) allLocalIps.add(ip);
            }
          }
        }
      } catch (_) {}

      final payload = jsonEncode({
        't': kDiscoveryBeaconType,
        'ip': _sessionInfo!.hostIp,
        'ips': allLocalIps, // ALL local IPs — scanner will try each
        'p': _sessionInfo!.port,
        'tok': _sessionInfo!.sessionToken,
        'pin': _sessionInfo!.pinCode,
        'dev': _sessionInfo!.serverDeviceName,
        'title': _sessionInfo!.source.title,
        'logo': _sessionInfo!.source.logoUrl,
        'url': _sessionInfo!.source.url,
      });

      final bytes = utf8.encode(payload);

      // 1. Send to global broadcast 255.255.255.255
      try {
        _socket?.send(
          bytes,
          InternetAddress('255.255.255.255'),
          kHandoffDiscoveryPort,
        );
      } catch (_) {}

      // 2. Send to directed subnet broadcast addresses for all known interfaces
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final ip = addr.address;
            if (ip.startsWith('169.254.') || ip == '127.0.0.1') continue;
            final parts = ip.split('.');
            if (parts.length == 4) {
              final bcastIp = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              try {
                _socket?.send(
                  bytes,
                  InternetAddress(bcastIp),
                  kHandoffDiscoveryPort,
                );
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    } catch (_) {}
  }

  void _handleIncomingPacket(Datagram datagram) {
    if (_sessionInfo == null) return;
    try {
      final text = utf8.decode(datagram.data);
      if (text.contains(kDiscoveryProbeType)) {
        // Direct response to the probing client
        final payload = jsonEncode({
          't': kDiscoveryBeaconType,
          'ip': _sessionInfo!.hostIp,
          'p': _sessionInfo!.port,
          'tok': _sessionInfo!.sessionToken,
          'pin': _sessionInfo!.pinCode,
          'dev': _sessionInfo!.serverDeviceName,
          'title': _sessionInfo!.source.title,
          'logo': _sessionInfo!.source.logoUrl,
          'url': _sessionInfo!.source.url,
        });
        final bytes = utf8.encode(payload);
        _socket?.send(bytes, datagram.address, datagram.port);
      }
    } catch (_) {}
  }


  Future<void> stop() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    try {
      if (_socket != null && _sessionInfo != null) {
        final stopMsg = jsonEncode({
          't': 'hope_tv_stopped',
          'ip': _sessionInfo!.hostIp,
          'p': _sessionInfo!.port,
        });
        final bytes = utf8.encode(stopMsg);
        _socket?.send(
          bytes,
          InternetAddress('255.255.255.255'),
          kHandoffDiscoveryPort,
        );
      }
    } catch (_) {}
    _socket?.close();
    _socket = null;
    if (_sessionInfo != null) {
      _kSelfSessionTokens.remove(_sessionInfo!.sessionToken);
    }
    _sessionInfo = null;
  }
}

/// Discovered TV session from UDP beacon.
class DiscoveredTvSession {
  const DiscoveredTvSession({
    required this.sessionInfo,
    required this.lastSeen,
  });

  final HandoffSessionInfo sessionInfo;
  final DateTime lastSeen;
}

/// UDP discovery scanner running on the mobile app to detect active TV streams.
class AudioHandoffDiscoveryScanner {
  RawDatagramSocket? _socket;
  Timer? _probeTimer;
  final _sessionStreamController =
      StreamController<List<DiscoveredTvSession>>.broadcast();
  final Map<String, DiscoveredTvSession> _activeSessions = {};

  Stream<List<DiscoveredTvSession>> get sessionsStream =>
      _sessionStreamController.stream;
  List<DiscoveredTvSession> get currentSessions =>
      _activeSessions.values.toList();

  Future<void> _updateSelfIps() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: true,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          _kSelfIps.add(addr.address);
        }
      }
    } catch (_) {}
  }

  Future<void> start() async {
    await stop();
    _activeSessions.clear();
    _sessionStreamController.add(const []);
    await _updateSelfIps();

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Bind to ephemeral port
        reuseAddress: true,
      );
      _socket?.broadcastEnabled = true;

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _processDatagram(datagram);
          }
        }
      });

      // Send probe broadcasts every 1.5 seconds
      _probeTimer = Timer.periodic(
        const Duration(milliseconds: 1500),
        (_) => _sendProbe(),
      );

      _sendProbe();

      // UDP beacons first. Subnet TCP scan is expensive — delay it so
      // opening the companion sheet stays responsive.
      _subnetTimer = Timer(const Duration(seconds: 2), () {
        if (_socket == null) return;
        unawaited(_scanSubnet());
        _subnetTimer = Timer.periodic(
          const Duration(seconds: 12),
          (_) => unawaited(_scanSubnet()),
        );
      });
    } catch (e) {
      AppLogger.warning(
        'Could not start UDP discovery scanner: $e',
        feature: 'audio_handoff',
      );
    }
  }

  Timer? _subnetTimer;
  bool _isSubnetScanning = false;

  Future<void> _scanSubnet() async {
    if (_isSubnetScanning) return;
    _isSubnetScanning = true;
    await _updateSelfIps();

    try {
      final subnetsToScan = <String, int>{}; // subnetPrefix -> selfLastByte

      // Collect ALL local subnets from network interfaces (preferred)
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        );
        for (final iface in interfaces) {
          final nameLower = iface.name.toLowerCase();
          if (nameLower.contains('wsl') ||
              nameLower.contains('vethernet') ||
              nameLower.contains('virtual') ||
              nameLower.contains('docker')) {
            continue;
          }
          for (final addr in iface.addresses) {
            final ip = addr.address;
            if (ip.startsWith('169.254.') || ip == '127.0.0.1' || ip == '0.0.0.0') {
              continue;
            }
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnetsToScan['${parts[0]}.${parts[1]}.${parts[2]}.'] =
                  int.tryParse(parts[3]) ?? -1;
            }
          }
        }
      } catch (_) {}

      // Fallback: routing socket trick
      if (subnetsToScan.isEmpty) {
        try {
          final s = await Socket.connect('8.8.8.8', 53,
              timeout: const Duration(milliseconds: 300));
          final ip = s.address.address;
          s.destroy();
          if (ip != '127.0.0.1' && !ip.startsWith('169.254.') && ip != '0.0.0.0') {
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnetsToScan['${parts[0]}.${parts[1]}.${parts[2]}.'] =
                  int.tryParse(parts[3]) ?? -1;
            }
          }
        } catch (_) {}
      }

      // Scan in small batches so 250 TCP probes never freeze the UI isolate.
      for (final entry in subnetsToScan.entries) {
        final subnetPrefix = entry.key;
        final selfLastByte = entry.value;

        const batchSize = 16;
        for (var j = 1; j <= 254; j += batchSize) {
          if (_socket == null) return;
          final batch = <Future<void>>[];
          final end = (j + batchSize - 1).clamp(1, 254);
          for (var k = j; k <= end; k++) {
            if (k == selfLastByte) continue;
            batch.add(_probeCandidate('$subnetPrefix$k'));
          }
          await Future.wait(batch);
          await Future<void>.delayed(const Duration(milliseconds: 24));
        }
      }
    } catch (_) {} finally {
      _isSubnetScanning = false;
    }
  }

  /// Fast two-phase probe:
  /// Phase 1 — TCP connect to check if port is open at all (150ms timeout).
  /// Phase 2 — HTTP GET /companion-info only if TCP succeeds.
  /// This avoids the 300ms wait on every dead IP.
  Future<void> _probeCandidate(String ip) async {
    if (_kSelfIps.contains(ip)) return;

    for (final port in [8998, 8997, 8996]) {
      // Phase 1: fast TCP connect
      try {
        final socket =
            await Socket.connect(ip, port, timeout: const Duration(milliseconds: 80));
        socket.destroy();
      } catch (_) {
        continue; // Port closed or timeout — skip HTTP probe
      }

      // Phase 2: HTTP confirm it's our server
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 500);
        final request =
            await client.getUrl(Uri.parse('http://$ip:$port/companion-info'));
        final response =
            await request.close().timeout(const Duration(milliseconds: 500));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final map = jsonDecode(body) as Map<String, dynamic>;

          final token = map['tok'] as String? ?? 'companion_token';
          if (_kSelfSessionTokens.contains(token)) {
            client.close(force: true);
            return;
          }

          final dev = map['dev'] as String? ?? 'IPTV Screen';
          final pin = map['pin']?.toString() ?? '0000';
          final title = map['title'] as String? ?? 'IPTV Screen';
          final logo = map['logo'] as String?;
          final url = map['url'] as String? ?? '';
          final actualPort = (map['p'] as num?)?.toInt() ?? port;

          final session = HandoffSessionInfo(
            hostIp: ip,
            port: actualPort,
            sessionToken: token,
            pinCode: pin,
            source: PlayerSource.live(
              url: url,
              title: title,
              logoUrl: logo,
            ),
            serverDeviceName: dev,
          );

          final key = '$ip:$actualPort';
          _activeSessions[key] = DiscoveredTvSession(
            sessionInfo: session,
            lastSeen: DateTime.now(),
          );
          _sessionStreamController.add(_activeSessions.values.toList());
          client.close(force: true);
          return; // Found one port on this IP — no need to try others
        }
        client.close(force: true);
      } catch (_) {}
    }
  }


  void triggerProbe() {
    _sendProbe();
  }

  void triggerSubnetScan() {
    _sendProbe();
    unawaited(_scanSubnet());
  }


  void _sendProbe() {
    if (_socket == null) return;
    try {
      final probe = jsonEncode({'t': kDiscoveryProbeType});
      final bytes = utf8.encode(probe);

      // 1. Send to global broadcast 255.255.255.255
      try {
        _socket?.send(
          bytes,
          InternetAddress('255.255.255.255'),
          kHandoffDiscoveryPort,
        );
      } catch (_) {}

      // 2. Send to all interface directed broadcast addresses
      try {
        NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false,
        ).then((interfaces) {
          for (final iface in interfaces) {
            for (final addr in iface.addresses) {
              final ip = addr.address;
              if (ip.startsWith('169.254.') || ip == '127.0.0.1') continue;
              final parts = ip.split('.');
              if (parts.length == 4) {
                final bcastIp = '${parts[0]}.${parts[1]}.${parts[2]}.255';
                try {
                  _socket?.send(
                    bytes,
                    InternetAddress(bcastIp),
                    kHandoffDiscoveryPort,
                  );
                } catch (_) {}
              }
            }
          }
        });
      } catch (_) {}

      // Clean up stale sessions (older than 8 seconds)
      final now = DateTime.now();
      final beforeCount = _activeSessions.length;
      _activeSessions.removeWhere(
        (_, s) => now.difference(s.lastSeen).inMilliseconds > 8000,
      );
      if (_activeSessions.length != beforeCount) {
        _sessionStreamController.add(_activeSessions.values.toList());
      }
    } catch (_) {}
  }

  void _processDatagram(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final map = jsonDecode(text) as Map<String, dynamic>;

      if (map['t'] == 'hope_tv_stopped') {
        final ip = map['ip'] as String? ?? datagram.address.address;
        final port = (map['p'] as num?)?.toInt() ?? 8998;
        _activeSessions.remove('$ip:$port');
        _sessionStreamController.add(_activeSessions.values.toList());
        return;
      }

      if (map['t'] == kDiscoveryBeaconType) {
        final senderIp = datagram.address.address;
        final advertisedIp = map['ip'] as String?;
        final token = map['tok'] as String? ?? 'companion_token';

        // Ignore self device broadcasts
        if (_kSelfSessionTokens.contains(token)) return;
        if (_kSelfIps.contains(senderIp)) return;
        if (advertisedIp != null && _kSelfIps.contains(advertisedIp)) return;

        final port = (map['p'] as num?)?.toInt() ?? 8998;
        final pin = map['pin']?.toString() ?? '0000';
        final dev = map['dev'] as String? ?? 'IPTV Screen';
        final title = map['title'] as String? ?? 'Live Stream';
        final logo = map['logo'] as String?;
        final url = map['url'] as String? ?? '';

        // Collect all IP candidates to probe: advertised IP, sender IP, and any extra IPs
        final rawIps = <String>{
          senderIp, // Most reliable: the actual packet sender
        };
        if (advertisedIp != null &&
            !advertisedIp.startsWith('127.') &&
            !advertisedIp.startsWith('169.254.')) {
          rawIps.add(advertisedIp);
        }
        final extraIps = map['ips'] as List<dynamic>?;
        if (extraIps != null) {
          for (final extra in extraIps) {
            final s = extra?.toString() ?? '';
            if (s.isNotEmpty &&
                !s.startsWith('127.') &&
                !s.startsWith('169.254.')) {
              rawIps.add(s);
            }
          }
        }

        // Use senderIp as primary if advertised IP differs (NAT/virtual adapter situation)
        final primaryIp = senderIp;

        final session = HandoffSessionInfo(
          hostIp: primaryIp,
          port: port,
          sessionToken: token,
          pinCode: pin,
          source: PlayerSource.live(
            url: url,
            title: title,
            logoUrl: logo,
          ),
          serverDeviceName: dev,
        );

        final key = '$primaryIp:$port';
        _activeSessions[key] = DiscoveredTvSession(
          sessionInfo: session,
          lastSeen: DateTime.now(),
        );

        _sessionStreamController.add(_activeSessions.values.toList());

        // Background-probe all candidate IPs — pick the one that actually responds
        // This handles cases where the advertised IP is wrong (mobile data IP vs Wi-Fi IP)
        unawaited(_resolveReachableIp(rawIps, port, token, pin, dev, url, title, logo));
      }
    } catch (_) {}
  }

  /// Tries all candidate IPs in parallel and updates the session with the first
  /// reachable one. This handles Android devices that advertise their mobile data
  /// IP instead of Wi-Fi IP.
  Future<void> _resolveReachableIp(
    Set<String> candidateIps,
    int port,
    String token,
    String pin,
    String dev,
    String url,
    String title,
    String? logo,
  ) async {
    for (final ip in candidateIps) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(milliseconds: 400);
        final request =
            await client.getUrl(Uri.parse('http://$ip:$port/companion-info'));
        final response =
            await request.close().timeout(const Duration(milliseconds: 500));
        client.close(force: true);

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final infoMap = jsonDecode(body) as Map<String, dynamic>;
          final confirmedPort =
              (infoMap['p'] as num?)?.toInt() ?? port;

          final session = HandoffSessionInfo(
            hostIp: ip,
            port: confirmedPort,
            sessionToken: infoMap['tok'] as String? ?? token,
            pinCode: infoMap['pin']?.toString() ?? pin,
            source: PlayerSource.live(
              url: infoMap['url'] as String? ?? url,
              title: infoMap['title'] as String? ?? title,
              logoUrl: infoMap['logo'] as String? ?? logo,
            ),
            serverDeviceName: infoMap['dev'] as String? ?? dev,
          );

          // Update session with confirmed reachable IP
          final key = '$ip:$confirmedPort';
          _activeSessions[key] = DiscoveredTvSession(
            sessionInfo: session,
            lastSeen: DateTime.now(),
          );
          _sessionStreamController.add(_activeSessions.values.toList());
          return; // Stop at first confirmed reachable IP
        }
      } catch (_) {
        continue;
      }
    }
  }

  Future<void> stop() async {
    _probeTimer?.cancel();
    _probeTimer = null;
    _subnetTimer?.cancel();
    _subnetTimer = null;
    _activeSessions.clear();
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    stop();
    _sessionStreamController.close();
  }
}

/// Shared singleton provider for the background LAN discovery scanner.
final discoveryScannerProvider = Provider<AudioHandoffDiscoveryScanner>((ref) {
  final scanner = AudioHandoffDiscoveryScanner();
  scanner.start();
  ref.onDispose(scanner.dispose);
  return scanner;
});

/// Global stream provider for TV & PC sessions discovered on the local network.
final discoveredTvSessionsProvider =
    StreamProvider<List<DiscoveredTvSession>>((ref) {
  final scanner = ref.watch(discoveryScannerProvider);
  return scanner.sessionsStream;
});


