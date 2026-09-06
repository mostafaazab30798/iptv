import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';

/// Network/IO helpers for companion QR pairing (kept out of pure UI widgets).
abstract final class CompanionScannerActions {
  static const int defaultAuthHandoffPort = 8998;

  static String companionDeviceName() {
    if (Platform.isAndroid) return 'Android Phone';
    if (Platform.isIOS) return 'iPhone';
    return Platform.localHostname;
  }

  /// Normalizes manual IP/host input (`http://host:port/` → host + port).
  static ({String host, int port}) normalizeManualHost(
    String raw, {
    int defaultPort = defaultAuthHandoffPort,
  }) {
    var host = raw.trim();
    if (host.startsWith('http://')) host = host.substring(7);
    if (host.startsWith('https://')) host = host.substring(8);
    if (host.endsWith('/')) host = host.substring(0, host.length - 1);

    var port = defaultPort;
    if (host.contains(':')) {
      final parts = host.split(':');
      host = parts[0];
      port = int.tryParse(parts[1]) ?? defaultPort;
    }
    return (host: host, port: port);
  }

  static IconData deviceIconForName(String devName) {
    final lower = devName.toLowerCase();
    if (lower.contains('pc') ||
        lower.contains('windows') ||
        lower.contains('mac') ||
        lower.contains('linux') ||
        lower.contains('desktop') ||
        lower.contains('laptop')) {
      return Icons.laptop_chromebook;
    }
    if (lower.contains('tablet') || lower.contains('pad')) {
      return Icons.tablet_android;
    }
    if (lower.contains('phone') || lower.contains('mobile')) {
      return Icons.smartphone;
    }
    return Icons.tv;
  }

  static Future<bool> transferAuthCredentials({
    required CompanionAuthHandoffInfo authInfo,
    required CompanionAuthCredentialsPayload payload,
    Dio? dio,
  }) async {
    final client = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {'content-type': 'application/json'},
          ),
        );
    final res = await client.post<Map<String, dynamic>>(
      authInfo.transferUrl,
      data: jsonEncode(payload.toJson()),
    );
    return res.statusCode == 200 && (res.data?['success'] == true);
  }

  static Future<Map<String, dynamic>> fetchAuthHandoffInfo({
    required String host,
    required int port,
    Dio? dio,
  }) async {
    final client = dio ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
    final res = await client.get<Map<String, dynamic>>(
      'http://$host:$port/auth-handoff',
    );
    return res.data ?? <String, dynamic>{};
  }
}
