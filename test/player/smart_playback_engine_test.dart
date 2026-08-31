import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/application/smart_playback_engine.dart';
import 'package:iptv/player/domain/entities/player_metrics.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';

PlayerMetrics _metrics({
  String? hwdecCurrent,
  int frameDropCount = 0,
  int decoderFrameDropCount = 0,
  int? cacheBufferingState = 90,
  Duration? cacheDuration = const Duration(seconds: 3),
  int bufferingCount = 0,
  PlaybackBufferMode bufferMode = PlaybackBufferMode.lowLatency,
}) {
  return PlayerMetrics(
    hwdecCurrent: hwdecCurrent,
    frameDropCount: frameDropCount,
    decoderFrameDropCount: decoderFrameDropCount,
    cacheBufferingState: cacheBufferingState,
    cacheDuration: cacheDuration,
    bufferingCount: bufferingCount,
    bufferMode: bufferMode,
  );
}

void main() {
  group('SmartPlaybackEngine with FakePlayerEngine', () {
    late FakePlayerEngine fakeEngine;
    late SmartPlaybackEngine smartEngine;
    late DateTime now;

    setUp(() {
      now = DateTime.utc(2026, 9, 1, 12);
      fakeEngine = FakePlayerEngine();
      smartEngine = SmartPlaybackEngine(
        engine: fakeEngine,
        initialBufferMode: PlaybackBufferMode.lowLatency,
        clock: () => now,
        // Short windows so unit tests stay fast and deterministic.
        decodeBottleneckWindow: 3,
        escalateWindow: 3,
        deEscalateWindow: 3,
        networkEscalateWindow: 2,
        networkDeEscalateWindow: 3,
        liveLowLatencyRecoverWindow: 5,
        resyncCooldown: const Duration(seconds: 30),
        softCatchUpOverTargetSecs: 1.5,
        softCatchUpMaxOverTargetSecs: 6.0,
        hardResyncOverTargetSecs: 8.0,
        hardResyncImmediateSecs: 20.0,
        decodeHealDropDeltaThreshold: 40,
        decodeHealSpikeWindow: 2,
      );
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

    test('SW decode alone does not apply Tier 1 immediately', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);

      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'no',
          frameDropCount: 0,
          cacheDuration: const Duration(seconds: 3),
        ),
      );

      expect(
        fakeEngine.lastAppliedSwDecodeTier,
        equals(SoftwareDecodeFallbackTier.none),
      );
      expect(smartEngine.currentSwDecodeTier, equals(SoftwareDecodeFallbackTier.none));
    });

    test('sustained decode bottleneck applies Tier 1', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);

      for (var i = 0; i < 3; i++) {
        smartEngine.debugTick(
          _metrics(
            hwdecCurrent: 'no',
            frameDropCount: 20,
            cacheBufferingState: 90,
            cacheDuration: const Duration(seconds: 3),
          ),
        );
      }

      expect(
        fakeEngine.lastAppliedSwDecodeTier,
        equals(SoftwareDecodeFallbackTier.loopFilterSkip),
      );
    });

    test('soft catch-up engages then restores 1.0x when cache recovers', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);

      // lowLatency target=3s; cache=6s => +3s over target => soft catch-up band.
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          cacheDuration: const Duration(seconds: 6),
          cacheBufferingState: 90,
        ),
      );
      await pumpEventQueue();

      expect(smartEngine.isCatchUpActive, isTrue);
      expect(smartEngine.liveEdgePhase, equals(LiveEdgePhase.catchingUp));
      expect(fakeEngine.playbackRate, equals(1.02));

      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          cacheDuration: const Duration(seconds: 3),
          cacheBufferingState: 90,
        ),
      );
      await pumpEventQueue();

      expect(smartEngine.isCatchUpActive, isFalse);
      expect(fakeEngine.playbackRate, equals(1.0));
    });

    test('hard resync fires once under large lag then respects cooldown', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);
      final opensAfterFirst = fakeEngine.openCount;

      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          cacheDuration: const Duration(seconds: 22),
          cacheBufferingState: 90,
        ),
      );
      await pumpEventQueue();

      expect(fakeEngine.openCount, equals(opensAfterFirst + 1));
      expect(smartEngine.liveEdgePhase, equals(LiveEdgePhase.cooldown));

      // Still in cooldown — another fat cache must not reopen again.
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          cacheDuration: const Duration(seconds: 25),
          cacheBufferingState: 90,
        ),
      );
      await pumpEventQueue();

      expect(fakeEngine.openCount, equals(opensAfterFirst + 1));

      // After cooldown expires, another lag can resync again.
      now = now.add(const Duration(seconds: 31));
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          cacheDuration: const Duration(seconds: 22),
          cacheBufferingState: 90,
        ),
      );
      await pumpEventQueue();

      expect(fakeEngine.openCount, equals(opensAfterFirst + 2));
    });

    test('live buffer adaptation recovers balanced to lowLatency after healthy window', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);

      // Force escalate lowLatency -> balanced via network stress.
      for (var i = 0; i < 2; i++) {
        smartEngine.debugTick(
          _metrics(
            hwdecCurrent: 'mediacodec',
            cacheBufferingState: 10,
            cacheDuration: const Duration(milliseconds: 200),
            bufferingCount: i + 1,
          ),
        );
      }
      await pumpEventQueue();
      expect(smartEngine.currentBufferMode, equals(PlaybackBufferMode.balanced));
      expect(fakeEngine.lastBufferMode, equals(PlaybackBufferMode.balanced));

      // Healthy window long enough to recover to lowLatency.
      for (var i = 0; i < 5; i++) {
        smartEngine.debugTick(
          _metrics(
            hwdecCurrent: 'mediacodec',
            cacheBufferingState: 90,
            cacheDuration: const Duration(seconds: 3),
            bufferingCount: 2,
          ),
        );
      }
      await pumpEventQueue();

      expect(smartEngine.currentBufferMode, equals(PlaybackBufferMode.lowLatency));
      expect(fakeEngine.lastBufferMode, equals(PlaybackBufferMode.lowLatency));
    });

    test('decode-heal shares cooldown with hard resync', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);
      final opensAfterFirst = fakeEngine.openCount;

      // Two consecutive spikes of decoder drops with healthy cache.
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          decoderFrameDropCount: 50,
          cacheBufferingState: 90,
          cacheDuration: const Duration(seconds: 3),
        ),
      );
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          decoderFrameDropCount: 100,
          cacheBufferingState: 90,
          cacheDuration: const Duration(seconds: 3),
        ),
      );
      await pumpEventQueue();

      expect(fakeEngine.openCount, equals(opensAfterFirst + 1));
      expect(smartEngine.liveEdgePhase, equals(LiveEdgePhase.cooldown));

      // Decode-heal must not fire again during shared cooldown.
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          decoderFrameDropCount: 160,
          cacheBufferingState: 90,
          cacheDuration: const Duration(seconds: 3),
        ),
      );
      smartEngine.debugTick(
        _metrics(
          hwdecCurrent: 'mediacodec',
          decoderFrameDropCount: 220,
          cacheBufferingState: 90,
          cacheDuration: const Duration(seconds: 3),
        ),
      );
      await pumpEventQueue();

      expect(fakeEngine.openCount, equals(opensAfterFirst + 1));
    });

    test('does not jump stability straight to lowLatency', () async {
      final source = PlayerSource.live(
        url: 'http://stream.example/live.ts',
        title: 'Sports',
        channelId: 1,
      );
      await smartEngine.open(source);

      // Escalate lowLatency -> balanced -> stability under sustained stress.
      var bufferingCount = 0;
      for (var step = 0; step < 2; step++) {
        for (var i = 0; i < 2; i++) {
          bufferingCount++;
          smartEngine.debugTick(
            _metrics(
              hwdecCurrent: 'mediacodec',
              cacheBufferingState: 10,
              cacheDuration: const Duration(milliseconds: 200),
              bufferingCount: bufferingCount,
            ),
          );
        }
      }
      await pumpEventQueue();
      expect(smartEngine.currentBufferMode, equals(PlaybackBufferMode.stability));

      // First healthy window only steps to balanced.
      for (var i = 0; i < 3; i++) {
        smartEngine.debugTick(
          _metrics(
            hwdecCurrent: 'mediacodec',
            cacheBufferingState: 90,
            cacheDuration: const Duration(seconds: 3),
            bufferingCount: bufferingCount,
          ),
        );
      }
      await pumpEventQueue();
      expect(smartEngine.currentBufferMode, equals(PlaybackBufferMode.balanced));

      // Counter reset — still short of the lowLatency recover window.
      for (var i = 0; i < 4; i++) {
        smartEngine.debugTick(
          _metrics(
            hwdecCurrent: 'mediacodec',
            cacheBufferingState: 90,
            cacheDuration: const Duration(seconds: 3),
            bufferingCount: bufferingCount,
          ),
        );
      }
      await pumpEventQueue();
      expect(smartEngine.currentBufferMode, equals(PlaybackBufferMode.balanced));
    });
  });
}
