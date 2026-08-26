import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/utils/m3u_converter.dart';

void main() {
  group('M3uToXtreamConverter', () {
    test('converts standard get.php m3u link with query parameters', () {
      const url =
          'http://example-server.com:8080/get.php?username=my_user&password=my_password123&type=m3u_plus&output=ts';
      final result = M3uToXtreamConverter.tryConvert(url);

      expect(result, isNotNull);
      expect(result!.serverUrl, equals('http://example-server.com:8080'));
      expect(result.username, equals('my_user'));
      expect(result.password, equals('my_password123'));
    });

    test('converts https get.php with user and pass short keys', () {
      const url =
          'https://iptv-gateway.net/get.php?user=stream_fan&pass=superSecret!&output=m3u8';
      final result = M3uToXtreamConverter.tryConvert(url);

      expect(result, isNotNull);
      expect(result!.serverUrl, equals('https://iptv-gateway.net'));
      expect(result.username, equals('stream_fan'));
      expect(result.password, equals('superSecret!'));
    });

    test('converts live stream URL path format', () {
      const url = 'http://fasttv.tv:9000/live/john/pass456/12345.ts';
      final result = M3uToXtreamConverter.tryConvert(url);

      expect(result, isNotNull);
      expect(result!.serverUrl, equals('http://fasttv.tv:9000'));
      expect(result.username, equals('john'));
      expect(result.password, equals('pass456'));
    });

    test('converts movie stream URL path format', () {
      const url = 'http://fasttv.tv:9000/movie/alice/secret789/999.mp4';
      final result = M3uToXtreamConverter.tryConvert(url);

      expect(result, isNotNull);
      expect(result!.serverUrl, equals('http://fasttv.tv:9000'));
      expect(result.username, equals('alice'));
      expect(result.password, equals('secret789'));
    });

    test('converts basic auth URL format', () {
      const url = 'http://demo_user:demo_pass@stream.tv:8000/playlist.m3u';
      final result = M3uToXtreamConverter.tryConvert(url);

      expect(result, isNotNull);
      expect(result!.serverUrl, equals('http://stream.tv:8000'));
      expect(result.username, equals('demo_user'));
      expect(result.password, equals('demo_pass'));
    });

    test('converts raw M3U playlist file content with stream links', () {
      const m3uContent = '''
#EXTM3U
#EXTINF:-1 tvg-id="beIN1" tvg-name="beIN Sports 1",beIN Sports 1 HD
http://fndueo.2m2h.im:80/live/myaccount/mypassword/4051.ts
#EXTINF:-1 tvg-id="beIN2" tvg-name="beIN Sports 2",beIN Sports 2 HD
http://fndueo.2m2h.im:80/live/myaccount/mypassword/4052.ts
''';
      final result = M3uToXtreamConverter.tryConvert(m3uContent);

      expect(result, isNotNull);
      expect(result!.serverUrl, equals('http://fndueo.2m2h.im:80'));
      expect(result.username, equals('myaccount'));
      expect(result.password, equals('mypassword'));
    });

    test('isM3uLink helper detects m3u indicators', () {
      expect(
          M3uToXtreamConverter.isM3uLink(
              'http://server.com/get.php?username=u&password=p'),
          isTrue);
      expect(
          M3uToXtreamConverter.isM3uLink('http://server.com/playlist.m3u8'),
          isTrue);
      expect(
          M3uToXtreamConverter.isM3uLink('http://server.com:8080'), isFalse);
    });
  });
}
