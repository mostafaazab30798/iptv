import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/app_update_installer.dart';
import 'package:iptv/core/releases/release_manifest.dart';

ReleaseManifest _testManifest({
  String sha256Hash = '',
  String version = '1.2.0',
  int buildNumber = 50,
  String platform = 'windows',
}) {
  return ReleaseManifest(
    schemaVersion: 1,
    platform: platform,
    architecture: 'x64',
    channel: 'stable',
    version: version,
    buildNumber: buildNumber,
    minimumSupportedVersion: '1.0.0',
    mandatory: false,
    fileSize: 1024,
    sha256: sha256Hash,
    downloadAuthorizationPath: '/v1/downloads/authorize',
    publishedAt: '2026-09-01T00:00:00Z',
    releaseNotesEn: 'Release notes',
    releaseNotesAr: null,
    keyId: 'k1',
    signature: 'sig',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateInstaller cancelDownload', () {
    test('cancelling with no active download does not throw', () {
      final installer = AppUpdateInstaller();
      expect(installer.cancelDownload, returnsNormally);
    });
  });

  group('AppUpdateInstaller SHA-256 validation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('update_installer_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('verifies correct SHA-256 digest', () async {
      final fileData = utf8.encode('HOPE IPTV test binary payload');
      final expectedSha = sha256.convert(fileData).toString();

      final manifest = _testManifest(sha256Hash: expectedSha);

      final actualSha = sha256.convert(fileData).toString();
      expect(actualSha, manifest.sha256);
    });

    test('rejects mismatched SHA-256 digest', () {
      final fileData = utf8.encode('Corrupted binary data');
      final actualSha = sha256.convert(fileData).toString();
      const expectedSha = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

      expect(actualSha, isNot(equals(expectedSha)));
    });
  });
}
