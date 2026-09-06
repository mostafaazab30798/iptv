import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/handoff/application/companion_scanner_actions.dart';

void main() {
  group('CompanionScannerActions.normalizeManualHost', () {
    test('strips scheme/trailing slash and parses port', () {
      final parsed = CompanionScannerActions.normalizeManualHost(
        'http://192.168.1.10:8787/',
      );
      expect(parsed.host, '192.168.1.10');
      expect(parsed.port, 8787);
    });

    test('defaults port when omitted', () {
      final parsed = CompanionScannerActions.normalizeManualHost('tv.local');
      expect(parsed.host, 'tv.local');
      expect(parsed.port, CompanionScannerActions.defaultAuthHandoffPort);
    });
  });

  group('CompanionScannerActions.deviceIconForName', () {
    test('maps common device labels', () {
      expect(
        CompanionScannerActions.deviceIconForName('Windows PC'),
        Icons.laptop_chromebook,
      );
      expect(
        CompanionScannerActions.deviceIconForName('iPad'),
        Icons.tablet_android,
      );
      expect(
        CompanionScannerActions.deviceIconForName('Living Room TV'),
        Icons.tv,
      );
    });
  });
}
