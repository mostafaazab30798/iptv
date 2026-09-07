import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/infrastructure/web/native_vod_policy.dart';

void main() {
  group('requiresIosVodRemux', () {
    test('uses native playback directly for AVPlayer-compatible VOD', () {
      expect(
        requiresIosVodRemux('https://panel.test/movie/u/p/42.mp4'),
        isFalse,
      );
      expect(
        requiresIosVodRemux('https://panel.test/series/u/p/43.m4v'),
        isFalse,
      );
      expect(
        requiresIosVodRemux('https://cdn.test/video.mov?token=abc'),
        isFalse,
      );
    });

    test('requests remux only for known unsupported containers', () {
      expect(
        requiresIosVodRemux('https://panel.test/movie/u/p/42.mkv'),
        isTrue,
      );
      expect(
        requiresIosVodRemux('https://panel.test/series/u/p/43.AVI?token=abc'),
        isTrue,
      );
    });

    test('examines the target nested inside the web proxy URL', () {
      final target = Uri.encodeComponent(
        'http://panel.test/series/u/p/43.mkv?token=abc',
      );

      expect(
        requiresIosVodRemux('https://hope-tv.site/proxy?url=$target'),
        isTrue,
      );
      expect(
        unwrapWebProxyTarget('https://hope-tv.site/proxy?url=$target'),
        'http://panel.test/series/u/p/43.mkv?token=abc',
      );
    });
  });
}
