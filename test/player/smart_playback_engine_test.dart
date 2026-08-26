import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/application/smart_playback_engine.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';

void main() {
  group('SmartPlaybackEngine with FakePlayerEngine', () {
    late FakePlayerEngine fakeEngine;
    late SmartPlaybackEngine smartEngine;

    setUp(() {
      fakeEngine = FakePlayerEngine();
      smartEngine = SmartPlaybackEngine(engine: fakeEngine);
    });

    tearDown(() async {
      await smartEngine.dispose();
    });

    test('opens source and transitions status cleanly', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.m3u8',
        title: 'BBC One HD',
        channelId: 101,
      );

      await smartEngine.open(source);

      expect(fakeEngine.currentStatus, equals(PlayerStatus.playing));
      expect(fakeEngine.currentSource?.title, equals('BBC One HD'));
    });

    test('handles playback error and invokes retry scheduler', () async {
      var retryScheduled = false;
      final errorHandled = smartEngine.handleError(
        PlayerErrorType.timeout,
        onExecuteRetry: () async {},
        onRetryScheduled: (delay, attempt) {
          retryScheduled = true;
        },
      );

      expect(errorHandled, isTrue);
      expect(retryScheduled, isTrue);
    });

    test('stops active playback and cancels retries', () async {
      await smartEngine.stop();
      expect(fakeEngine.currentStatus, equals(PlayerStatus.stopped));
    });
  });
}
