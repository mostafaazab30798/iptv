import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/releases/update_platform.dart';

void main() {
  group('UpdateUrlValidator', () {
    test('allows github.com release download URLs', () {
      expect(
        UpdateUrlValidator.isAllowedDownloadUrl(
          'https://github.com/hope-tv/iptv/releases/download/v0.1.0-build.2/HOPE_IPTV.apk',
        ),
        isTrue,
      );
    });

    test('allows objects.githubusercontent.com CDN URLs', () {
      expect(
        UpdateUrlValidator.isAllowedDownloadUrl(
          'https://objects.githubusercontent.com/github-production-release-asset/123/HOPE_IPTV.apk',
        ),
        isTrue,
      );
    });

    test('rejects non-HTTPS URLs', () {
      expect(
        UpdateUrlValidator.isAllowedDownloadUrl(
          'http://github.com/hope-tv/iptv/releases/download/v1/HOPE_IPTV.apk',
        ),
        isFalse,
      );
    });

    test('rejects unknown hosts', () {
      expect(
        UpdateUrlValidator.isAllowedDownloadUrl(
          'https://evil.example.com/releases/download/v1/HOPE_IPTV.apk',
        ),
        isFalse,
      );
    });
  });
}
