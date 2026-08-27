import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/network/url_helpers.dart';

void main() {
  group('UrlHelpers.normalizeServerUrl', () {
    test('adds http scheme when missing', () {
      expect(
        UrlHelpers.normalizeServerUrl('panel.example.com:8080'),
        'http://panel.example.com:8080',
      );
    });

    test('strips trailing slash and player_api.php', () {
      expect(
        UrlHelpers.normalizeServerUrl(
          'https://panel.example.com/player_api.php?username=u',
        ),
        'https://panel.example.com',
      );
      expect(
        UrlHelpers.normalizeServerUrl('http://panel.example.com/iptv/'),
        'http://panel.example.com/iptv',
      );
    });
  });

  group('UrlHelpers.wrapWebProxy', () {
    test('returns raw URL when not on web', () {
      // Unit tests run on VM (non-web); proxy wrap is a no-op.
      expect(
        UrlHelpers.wrapWebProxy('http://cdn.example.com/stream.ts'),
        'http://cdn.example.com/stream.ts',
      );
      expect(
        UrlHelpers.wrapWebProxy(
          'https://cdn.example.com/logo.png',
          proxyAllHttpTargets: true,
        ),
        'https://cdn.example.com/logo.png',
      );
    });
  });
}
