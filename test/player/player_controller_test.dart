import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/application/player_controller.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';

void main() {
  group('PlayerController', () {
    late FakePlayerEngine fakeEngine;
    late PlayerController controller;

    setUp(() {
      fakeEngine = FakePlayerEngine();
      controller = PlayerController(engine: fakeEngine);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is idle with default volume', () {
      expect(controller.state.status, equals(PlayerStatus.idle));
      expect(controller.state.volume, equals(1.0));
      expect(controller.state.isMuted, isFalse);
    });

    test('loads source and updates active state', () async {
      final source = PlayerSource.live(
        url: 'http://test.live/channel.m3u8',
        title: 'Discovery Channel',
        channelId: 202,
      );

      await controller.load(source);

      expect(controller.state.source?.title, equals('Discovery Channel'));
      expect(controller.state.status, equals(PlayerStatus.playing));
    });

    test('switches channels correctly in playlist sequence', () async {
      final ch1 = PlayerSource.live(url: 'http://ch1.m3u8', title: 'Channel 1', channelId: 1);
      final ch2 = PlayerSource.live(url: 'http://ch2.m3u8', title: 'Channel 2', channelId: 2);
      final ch3 = PlayerSource.live(url: 'http://ch3.m3u8', title: 'Channel 3', channelId: 3);

      controller.setChannelPlaylist([ch1, ch2, ch3], initialIndex: 0);
      await controller.load(ch1);
      expect(controller.state.source?.title, equals('Channel 1'));

      await controller.nextChannel();
      expect(controller.state.source?.title, equals('Channel 2'));

      await controller.nextChannel();
      expect(controller.state.source?.title, equals('Channel 3'));

      // Loops back
      await controller.nextChannel();
      expect(controller.state.source?.title, equals('Channel 1'));

      // Previous channel loops backwards
      await controller.previousChannel();
      expect(controller.state.source?.title, equals('Channel 3'));
    });

    test('adjusts volume, mute, and tracks', () async {
      await controller.setVolume(0.75);
      expect(controller.state.volume, equals(0.75));
      expect(fakeEngine.volume, equals(0.75));

      await controller.mute(true);
      expect(controller.state.isMuted, isTrue);

      const track = PlayerAudioTrack(id: '2', title: 'Arabic [5.1]', language: 'ara');
      await controller.setAudioTrack(track);
      expect(controller.state.currentAudioTrack, equals(track));
      expect(fakeEngine.selectedAudioTrack, equals(track));
    });

    test('cycles aspect ratio modes', () {
      expect(controller.state.aspectRatioIndex, equals(0)); // Fit
      controller.cycleAspectRatio();
      expect(controller.state.aspectRatioIndex, equals(1)); // Fill
      controller.cycleAspectRatio();
      expect(controller.state.aspectRatioIndex, equals(2)); // 16:9
      controller.cycleAspectRatio();
      expect(controller.state.aspectRatioIndex, equals(3)); // 4:3
      controller.cycleAspectRatio();
      expect(controller.state.aspectRatioIndex, equals(0)); // Back to Fit
    });

    test('seekRelative adjusts position safely', () async {
      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'Inception',
        movieId: 505,
      );
      await controller.load(source);
      await controller.seek(const Duration(seconds: 30));
      expect(controller.state.position, equals(const Duration(seconds: 30)));

      // Relative seek forward 10s
      await controller.seekRelative(const Duration(seconds: 10));
      expect(controller.state.position, equals(const Duration(seconds: 40)));

      // Relative seek back 10s
      await controller.seekRelative(const Duration(seconds: -10));
      expect(controller.state.position, equals(const Duration(seconds: 30)));
    });

    test('scrubbing stays paused until release and then resumes', () async {
      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'Scrub Session',
        movieId: 506,
      );
      await controller.load(source);
      expect(fakeEngine.currentStatus, PlayerStatus.playing);

      controller.beginSeekScrub();
      await Future<void>.delayed(Duration.zero);

      expect(fakeEngine.currentStatus, PlayerStatus.paused);
      expect(controller.state.isPlaying, isFalse);

      await controller.finishSeekScrub(const Duration(minutes: 25));

      expect(fakeEngine.currentPosition, const Duration(minutes: 25));
      expect(fakeEngine.currentStatus, PlayerStatus.playing);
      expect(controller.state.isPlaying, isTrue);
    });

    test('setPlaybackRate updates playback speed', () async {
      expect(controller.state.playbackRate, equals(1.0));
      await controller.setPlaybackRate(1.5);
      expect(controller.state.playbackRate, equals(1.5));
      expect(fakeEngine.playbackRate, equals(1.5));
    });

    test('toggleLock and setLocked update isLocked state', () {
      expect(controller.state.isLocked, isFalse);
      controller.toggleLock();
      expect(controller.state.isLocked, isTrue);
      controller.setLocked(false);
      expect(controller.state.isLocked, isFalse);
    });

    test('stop() completely stops engine and clears playback state', () async {
      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'Inception',
        movieId: 505,
      );

      await controller.load(source);
      expect(controller.state.isPlaying, isTrue);
      expect(controller.state.source?.title, equals('Inception'));
      expect(fakeEngine.currentSource, isNotNull);

      await controller.stop();
      expect(controller.state.status, equals(PlayerStatus.stopped));
      expect(controller.state.source, isNull);
      expect(controller.state.position, equals(Duration.zero));
      expect(controller.state.duration, equals(Duration.zero));
      expect(controller.state.availableAudioTracks, isEmpty);
      expect(controller.state.availableSubtitleTracks, isEmpty);
      expect(controller.state.isRetrying, isFalse);
      expect(controller.state.retryAttempt, equals(0));
      expect(fakeEngine.currentSource, isNull);
      expect(fakeEngine.currentStatus, equals(PlayerStatus.stopped));
    });

    test('rapid load keeps only the latest channel (stale open discarded)', () async {
      fakeEngine.openDelay = const Duration(milliseconds: 40);

      final first = PlayerSource.live(
        url: 'http://ch1.m3u8',
        title: 'Channel 1',
        channelId: 1,
      );
      final second = PlayerSource.live(
        url: 'http://ch2.m3u8',
        title: 'Channel 2',
        channelId: 2,
      );

      final firstLoad = controller.load(first);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final secondLoad = controller.load(second);
      await Future.wait([firstLoad, secondLoad]);

      expect(controller.state.source?.title, equals('Channel 2'));
      expect(controller.state.source?.channelId, equals(2));
      expect(fakeEngine.currentSource?.channelId, equals(2));
    });

    test('stop() and cancelAutoReconnect clear stuck isRetrying HUD state', () async {
      final source = PlayerSource.live(
        url: 'http://live.stream/ch.m3u8',
        title: 'Live Stream',
        channelId: 9,
      );
      await controller.load(source);

      fakeEngine.simulateError(PlayerErrorType.networkUnavailable);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isRetrying, isTrue);

      controller.cancelAutoReconnect();
      expect(controller.state.isRetrying, isFalse);
      expect(controller.state.retryAttempt, equals(0));
      expect(controller.state.source?.channelId, equals(9));

      fakeEngine.simulateError(PlayerErrorType.networkUnavailable);
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isRetrying, isTrue);

      await controller.stop();
      expect(controller.state.isRetrying, isFalse);
      expect(controller.state.retryAttempt, equals(0));
      expect(controller.state.source, isNull);
    });
  });
}
