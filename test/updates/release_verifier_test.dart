import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/release_verifier.dart';

void main() {
  const hmacSecret = 'test-release-hmac-secret';
  final verifier = ReleaseVerifier(hmacSecret: hmacSecret);

  ReleaseManifest baseManifest() {
    return ReleaseManifest(
      schemaVersion: 1,
      platform: 'android',
      architecture: 'arm64-v8a',
      channel: 'stable',
      version: '0.1.0',
      buildNumber: 2,
      minimumSupportedVersion: null,
      mandatory: false,
      fileSize: 1024,
      sha256: 'a' * 64,
      downloadAuthorizationPath: '/v1/downloads/authorize',
      publishedAt: '2026-08-30T00:00:00Z',
      releaseNotesEn: 'Notes',
      releaseNotesAr: null,
      keyId: 'release-dev-1',
      signature: '',
    );
  }

  ReleaseManifest sign(ReleaseManifest manifest) {
    final payloadB64 = base64Url
        .encode(utf8.encode(manifest.canonicalJson()))
        .replaceAll('=', '');
    final digest = crypto.Hmac(
      crypto.sha256,
      utf8.encode(hmacSecret),
    ).convert(utf8.encode(payloadB64));
    final signature = base64Url.encode(digest.bytes).replaceAll('=', '');
    return ReleaseManifest(
      schemaVersion: manifest.schemaVersion,
      platform: manifest.platform,
      architecture: manifest.architecture,
      channel: manifest.channel,
      version: manifest.version,
      buildNumber: manifest.buildNumber,
      minimumSupportedVersion: manifest.minimumSupportedVersion,
      mandatory: manifest.mandatory,
      fileSize: manifest.fileSize,
      sha256: manifest.sha256,
      downloadAuthorizationPath: manifest.downloadAuthorizationPath,
      publishedAt: manifest.publishedAt,
      releaseNotesEn: manifest.releaseNotesEn,
      releaseNotesAr: manifest.releaseNotesAr,
      keyId: manifest.keyId,
      signature: signature,
    );
  }

  test('accepts valid HMAC manifest', () async {
    final signed = sign(baseManifest());
    await expectLater(verifier.verify(signed), completes);
  });

  test('rejects tampered manifest', () async {
    final signed = sign(baseManifest());
    final tampered = ReleaseManifest(
      schemaVersion: signed.schemaVersion,
      platform: signed.platform,
      architecture: signed.architecture,
      channel: signed.channel,
      version: signed.version,
      buildNumber: signed.buildNumber + 1,
      minimumSupportedVersion: signed.minimumSupportedVersion,
      mandatory: signed.mandatory,
      fileSize: signed.fileSize,
      sha256: signed.sha256,
      downloadAuthorizationPath: signed.downloadAuthorizationPath,
      publishedAt: signed.publishedAt,
      releaseNotesEn: signed.releaseNotesEn,
      releaseNotesAr: signed.releaseNotesAr,
      keyId: signed.keyId,
      signature: signed.signature,
    );

    await expectLater(
      verifier.verify(tampered),
      throwsA(isA<ReleaseVerificationException>()),
    );
  });
}
