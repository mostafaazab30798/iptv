import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/features/updates/update_dialog_format.dart';

ReleaseManifest _manifest({String? en, String? ar}) {
  return ReleaseManifest(
    schemaVersion: 1,
    platform: 'android',
    architecture: 'arm64-v8a',
    channel: 'stable',
    version: '1.0.0',
    buildNumber: 1,
    minimumSupportedVersion: '1.0.0',
    mandatory: false,
    fileSize: 1536,
    sha256: 'abc',
    downloadAuthorizationPath: '/v1/downloads/authorize',
    publishedAt: '2026-09-01T12:00:00Z',
    releaseNotesEn: en,
    releaseNotesAr: ar,
    keyId: 'k',
    signature: 's',
  );
}

void main() {
  group('update_dialog_format', () {
    test('releaseNotesForLocale prefers matching language with fallback', () {
      final m = _manifest(en: 'EN', ar: 'AR');
      expect(releaseNotesForLocale(m, const Locale('en')), 'EN');
      expect(releaseNotesForLocale(m, const Locale('ar')), 'AR');
      expect(releaseNotesForLocale(_manifest(en: 'EN'), const Locale('ar')), 'EN');
    });

    test('formatUpdateFileSize', () {
      expect(formatUpdateFileSize(null), '—');
      expect(formatUpdateFileSize(0), '—');
      expect(formatUpdateFileSize(1536), '1.5 KB');
      expect(formatUpdateFileSize(2 * 1024 * 1024), '2.0 MB');
    });
  });
}
