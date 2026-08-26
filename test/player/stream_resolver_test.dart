import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';
import 'package:iptv/player/infrastructure/stream_resolver.dart';

void main() {
  group('StreamResolver', () {
    const resolver = StreamResolver();

    test('builds structured Live PlayerSource correctly', () {
      final source = resolver.resolveLive(
        serverUrl: 'http://iptv.server.com:8080',
        username: 'test_user',
        password: 'test_password',
        streamId: 4410,
        title: 'Sky Sports Premier League',
        format: 'm3u8',
      );

      expect(source.title, equals('Sky Sports Premier League'));
      expect(source.channelId, equals(4410));
      expect(source.profile, equals(PlaybackProfile.live));
      expect(source.streamType, equals(StreamType.hls));
      expect(source.url, equals('http://iptv.server.com:8080/live/test_user/test_password/4410.m3u8'));
      expect(source.headers['User-Agent'], isNotEmpty);
      expect(source.headers['Connection'], equals('keep-alive'));
    });

    test('builds structured VOD PlayerSource correctly', () {
      final source = resolver.resolveVod(
        serverUrl: 'https://secure.stream.net:8443',
        username: 'user1',
        password: 'pass1',
        streamId: 9988,
        title: 'Inception (2010)',
        containerExtension: 'mkv',
        startAt: const Duration(minutes: 15),
      );

      expect(source.title, equals('Inception (2010)'));
      expect(source.channelId, equals(9988));
      expect(source.profile, equals(PlaybackProfile.vod));
      expect(source.streamType, equals(StreamType.file));
      expect(source.url, equals('https://secure.stream.net:8443/movie/user1/pass1/9988.mkv'));
      expect(source.startAt, equals(const Duration(minutes: 15)));
    });

    test('resolves direct stream URLs and preserves custom headers', () {
      final source = resolver.resolveDirect(
        url: 'http://direct.stream.com/live.ts',
        title: 'Direct Stream',
        customHeaders: {'Authorization': 'Bearer token123'},
      );

      expect(source.streamType, equals(StreamType.mpegTs));
      expect(source.headers['Authorization'], equals('Bearer token123'));
    });
  });
}
