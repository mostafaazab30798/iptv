import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/releases/installed_app_info.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/release_verifier.dart';
import 'package:iptv/core/releases/update_service.dart';
import 'package:iptv/features/updates/update_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi extends CommercialEdgeFunctionsClient {
  _FakeApi(this.handler);

  final Future<Map<String, dynamic>> Function(
    String functionName,
    Map<String, String>? queryParameters,
  )
  handler;

  @override
  Future<Map<String, dynamic>> invoke(
    String functionName, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    dynamic method,
    bool requireSession = true,
  }) {
    return handler(functionName, queryParameters);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hmacSecret = 'test-release-hmac-secret';

  group('UpdateService query construction', () {
    test('installed build 1 finds server build 2', () async {
      Map<String, String>? captured;
      final manifest = _manifest(buildNumber: 2);
      final signed = _signManifest(manifest, hmacSecret);
      final service = UpdateService(
        api: _FakeApi((name, query) async {
          captured = query;
          return {
            'updateAvailable': true,
            'releaseId': 'rel-1',
            'manifest': _manifestJson(signed),
          };
        }),
        installedAppInfo: FakeInstalledAppInfo(
          version: '0.1.0',
          buildNumber: 1,
        ),
        platformTargetOverride: const UpdatePlatformTarget(
          platform: 'android',
          architecture: 'arm64-v8a',
        ),
        verifier: ReleaseVerifier(hmacSecret: hmacSecret),
      );

      final result = await service.checkForUpdate();
      expect(result.updateAvailable, isTrue);
      expect(captured?['platform'], 'android');
      expect(captured?['architecture'], 'arm64-v8a');
      expect(captured?['buildNumber'], '1');
      expect(captured?['channel'], 'stable');
    });

    test('installed build 2 does not find build 2', () async {
      final service = UpdateService(
        api: _FakeApi((_, __) async {
          return {'updateAvailable': false, 'releaseId': 'rel-1'};
        }),
        installedAppInfo: FakeInstalledAppInfo(
          version: '0.1.0',
          buildNumber: 2,
        ),
        platformTargetOverride: const UpdatePlatformTarget(
          platform: 'android',
          architecture: 'arm64-v8a',
        ),
        verifier: ReleaseVerifier(hmacSecret: hmacSecret),
      );

      final result = await service.checkForUpdate();
      expect(result.updateAvailable, isFalse);
    });
  });

  group('UpdatePreferences skip policy', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('stores skipped build number', () async {
      final prefs = await SharedPreferences.getInstance();
      final updatePrefs = UpdatePreferences(preferences: prefs);
      await updatePrefs.setSkippedBuildNumber(7);
      expect(await updatePrefs.skippedBuildNumber(), 7);
    });
  });
}

ReleaseManifest _manifest({required int buildNumber}) {
  return ReleaseManifest(
    schemaVersion: 1,
    platform: 'android',
    architecture: 'arm64-v8a',
    channel: 'stable',
    version: '0.1.0',
    buildNumber: buildNumber,
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

ReleaseManifest _signManifest(ReleaseManifest manifest, String secret) {
  final payloadB64 = base64Url
      .encode(utf8.encode(manifest.canonicalJson()))
      .replaceAll('=', '');
  final digest = crypto.Hmac(
    crypto.sha256,
    utf8.encode(secret),
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

Map<String, dynamic> _manifestJson(ReleaseManifest manifest) {
  return {
    'schemaVersion': manifest.schemaVersion,
    'platform': manifest.platform,
    'architecture': manifest.architecture,
    'channel': manifest.channel,
    'version': manifest.version,
    'buildNumber': manifest.buildNumber,
    'minimumSupportedVersion': manifest.minimumSupportedVersion,
    'mandatory': manifest.mandatory,
    'fileSize': manifest.fileSize,
    'sha256': manifest.sha256,
    'downloadAuthorizationPath': manifest.downloadAuthorizationPath,
    'publishedAt': manifest.publishedAt,
    'releaseNotesEn': manifest.releaseNotesEn,
    'releaseNotesAr': manifest.releaseNotesAr,
    'keyId': manifest.keyId,
    'signature': manifest.signature,
  };
}
