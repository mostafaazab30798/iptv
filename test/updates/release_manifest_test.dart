import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/release_manifest.dart';

ReleaseManifest _manifest({
  String platform = 'android',
  String architecture = 'arm64-v8a',
  String version = '1.0.5',
  int buildNumber = 2023,
  String? downloadUrl,
}) {
  return ReleaseManifest(
    schemaVersion: 1,
    platform: platform,
    architecture: architecture,
    channel: 'stable',
    version: version,
    buildNumber: buildNumber,
    minimumSupportedVersion: null,
    mandatory: false,
    fileSize: 1024,
    sha256: 'a' * 64,
    downloadAuthorizationPath: '/v1/downloads/authorize',
    publishedAt: '2026-09-06T00:00:00Z',
    releaseNotesEn: 'Notes',
    releaseNotesAr: null,
    keyId: 'k1',
    signature: 'sig',
    downloadUrl: downloadUrl,
  );
}

void main() {
  group('ReleaseManifest GitHub URLs', () {
    test('strips Android ABI versionCode offset from the GitHub tag', () {
      final manifest = _manifest();
      expect(manifest.githubReleaseTag, 'v1.0.5-build.23');
      expect(
        manifest.directDownloadUrl,
        'https://github.com/mostafaazab30798/iptv/releases/download/v1.0.5-build.23/HOPE_IPTV.apk',
      );
    });

    test('uses the Android TV artifact name', () {
      final manifest = _manifest(
        architecture: 'android-tv',
        buildNumber: 23,
      );
      expect(manifest.artifactFileName, 'HOPE_TV_Android_TV.apk');
      expect(
        manifest.directDownloadUrl,
        'https://github.com/mostafaazab30798/iptv/releases/download/v1.0.5-build.23/HOPE_TV_Android_TV.apk',
      );
    });

    test('prefers the signed-in or server-provided download URL', () {
      const url =
          'https://github.com/mostafaazab30798/iptv/releases/download/v1.0.5-build.23/HOPE_IPTV.apk';
      final manifest = _manifest(downloadUrl: url);
      expect(manifest.directDownloadUrl, url);
    });

    test('keeps downloadUrl out of the signed canonical JSON', () {
      final withUrl = _manifest(
        downloadUrl:
            'https://github.com/mostafaazab30798/iptv/releases/download/v1.0.5-build.23/HOPE_IPTV.apk',
      );
      final withoutUrl = _manifest();
      expect(withUrl.canonicalJson(), withoutUrl.canonicalJson());
      expect(withUrl.canonicalJson().contains('downloadUrl'), isFalse);
    });

    test('parses downloadUrl from version-function extra fields', () {
      final manifest = ReleaseManifest.fromJson({
        'schemaVersion': 1,
        'platform': 'android',
        'architecture': 'arm64-v8a',
        'channel': 'stable',
        'version': '1.0.5',
        'buildNumber': 2023,
        'mandatory': false,
        'fileSize': 1,
        'sha256': 'a' * 64,
        'downloadAuthorizationPath': '/v1/downloads/authorize',
        'publishedAt': '2026-09-06T00:00:00Z',
        'keyId': 'k1',
        'signature': 'sig',
        'downloadUrl':
            'https://github.com/mostafaazab30798/iptv/releases/download/v1.0.5-build.23/HOPE_IPTV.apk',
      });
      expect(
        manifest.downloadUrl,
        'https://github.com/mostafaazab30798/iptv/releases/download/v1.0.5-build.23/HOPE_IPTV.apk',
      );
    });
  });
}
