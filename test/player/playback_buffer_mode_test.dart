import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/application/player_controller.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';

void main() {
  group('PlaybackBufferMode', () {
    test('compact configuration values match low-RAM preset', () {
      const mode = PlaybackBufferMode.compact;
      expect(mode.demuxerReadaheadSecs, equals(3));
      expect(mode.cacheSecs, equals(4));
      expect(mode.bufferSizeBytes, equals(6 * 1024 * 1024));
      expect(mode.demuxerMaxBytes, equals('12MiB'));
      expect(mode.demuxerMaxBackBytes, equals('4MiB'));
    });

    test('lowLatency configuration values match streaming guide specs', () {
      const mode = PlaybackBufferMode.lowLatency;
      expect(mode.demuxerReadaheadSecs, equals(6));
      expect(mode.cacheSecs, equals(8));
      expect(mode.bufferSizeBytes, equals(16 * 1024 * 1024));
      expect(mode.demuxerMaxBytes, equals('32MiB'));
      expect(mode.demuxerMaxBackBytes, equals('8MiB'));
    });

    test('balanced configuration values match streaming guide specs', () {
      const mode = PlaybackBufferMode.balanced;
      expect(mode.demuxerReadaheadSecs, equals(5));
      expect(mode.cacheSecs, equals(10));
      expect(mode.bufferSizeBytes, equals(32 * 1024 * 1024));
      expect(mode.demuxerMaxBytes, equals('64MiB'));
      expect(mode.demuxerMaxBackBytes, equals('16MiB'));
    });

    test('stability configuration values match streaming guide specs', () {
      const mode = PlaybackBufferMode.stability;
      expect(mode.demuxerReadaheadSecs, equals(15));
      expect(mode.cacheSecs, equals(25));
      expect(mode.bufferSizeBytes, equals(64 * 1024 * 1024));
      expect(mode.demuxerMaxBytes, equals('128MiB'));
      expect(mode.demuxerMaxBackBytes, equals('32MiB'));
    });

    test('PlayerController dynamically switches buffer mode', () async {
      final fakeEngine = FakePlayerEngine();
      final controller = PlayerController(engine: fakeEngine);

      expect(controller.state.bufferMode, equals(PlaybackBufferMode.balanced));

      await controller.setBufferMode(PlaybackBufferMode.lowLatency);
      expect(controller.state.bufferMode, equals(PlaybackBufferMode.lowLatency));

      await controller.setBufferMode(PlaybackBufferMode.stability);
      expect(controller.state.bufferMode, equals(PlaybackBufferMode.stability));

      controller.dispose();
    });

    test('PlayerSource detects transport stream types correctly', () {
      final liveUdp = PlayerSource.live(
        url: 'udp://239.255.0.1:5000',
        title: 'Sports UDP 4K',
        streamType: StreamType.udp,
      );
      expect(liveUdp.streamType.isTransportStream, isTrue);
      expect(liveUdp.streamType.isHls, isFalse);

      final liveHls = PlayerSource.live(
        url: 'http://example.com/sports/index.m3u8',
        title: 'Sports HLS',
        streamType: StreamType.hls,
      );
      expect(liveHls.streamType.isTransportStream, isFalse);
      expect(liveHls.streamType.isHls, isTrue);
    });
  });
}
