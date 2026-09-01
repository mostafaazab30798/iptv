import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/features/player/player_screen.dart';
import 'package:iptv/player/application/player_controller.dart';
import 'package:iptv/player/application/player_state.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';
import 'package:iptv/player/presentation/buffering_indicator.dart';
import 'package:iptv/player/presentation/player_error_view.dart';
import 'package:iptv/player/presentation/player_controls.dart';
import 'package:iptv/player/presentation/player_view.dart';

void main() {
  group('PlayerScreen Widget Tests', () {
    late FakePlayerEngine fakeEngine;
    late PlayerController controller;

    setUp(() {
      fakeEngine = FakePlayerEngine();
      controller = PlayerController(engine: fakeEngine);
    });

    tearDown(() {
      // Safe if already disposed at end of the test body.
      if (controller.mounted) {
        controller.dispose();
      }
    });

    /// Removes PlayerScreen, drains dispose post-frame callbacks, and cancels
    /// player timers (progress saver) before Flutter's pending-timer invariant check.
    Future<void> finishPlayerTest(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      if (controller.mounted) {
        controller.dispose();
      }
    }

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((_) => controller),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: PlayerScreen(),
        ),
      );
    }

    testWidgets('renders PlayerView and overlay initial state', (tester) async {
      await tester.pumpWidget(createTestApp());
      // Overlay schedules a 4s hide timer — advance past it instead of hanging
      // on pumpAndSettle for the full duration.
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(PlayerView), findsOneWidget);
      expect(find.byType(BufferingIndicator), findsOneWidget);
      expect(find.byType(PlayerErrorView), findsNothing);

      await finishPlayerTest(tester);
    });

    testWidgets('displays channel title when playing a live channel', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final source = PlayerSource.live(
        url: 'http://test.live/ch.m3u8',
        title: 'HBO HD',
        channelId: 10,
        currentProgramTitle: 'Game of Thrones',
      );

      await controller.load(source);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('HBO HD'), findsAtLeast(1));
      expect(find.text('Game of Thrones'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      await finishPlayerTest(tester);
    });

    testWidgets('renders PlayerErrorView on unrecoverable error and handles retry', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final source = PlayerSource.live(
        url: 'http://broken.stream/ch.m3u8',
        title: 'Broken Stream',
      );
      await controller.load(source);

      fakeEngine.simulateError(PlayerErrorType.unauthorized);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(PlayerErrorView), findsOneWidget);
      expect(find.text('Access denied. Please check your subscription credentials.'), findsOneWidget);

      final retryBtn = find.text('Retry');
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await finishPlayerTest(tester);
    });

    testWidgets('shows non-blocking reconnecting HUD during auto-reconnect attempts', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final source = PlayerSource.live(
        url: 'http://live.stream/ch.m3u8',
        title: 'Live Stream',
      );
      await controller.load(source);

      fakeEngine.simulateError(PlayerErrorType.networkUnavailable);
      await tester.pump();

      expect(find.byType(PlayerErrorView), findsNothing);
      expect(find.byType(BufferingIndicator), findsOneWidget);
      expect(find.textContaining('Reconnecting... (1/5)'), findsOneWidget);

      await finishPlayerTest(tester);
    });

    testWidgets('stops playback and releases resources when PlayerScreen is popped or closed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((_) => controller),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
                  ),
                  child: const Text('Open Player'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Player'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'Interstellar',
        movieId: 707,
      );
      await controller.load(source);
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.state.isPlaying, isTrue);
      expect(fakeEngine.currentStatus, equals(PlayerStatus.playing));

      final backBtn = find.byTooltip('Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 5));

      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.text('Open Player'), findsOneWidget);

      expect(controller.state.status, equals(PlayerStatus.stopped));
      expect(controller.state.source, isNull);
      expect(fakeEngine.currentStatus, equals(PlayerStatus.stopped));
      expect(fakeEngine.currentSource, isNull);

      await finishPlayerTest(tester);
    });

    testWidgets('renders Replay 10s and Forward 10s buttons and handles taps', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'The Dark Knight',
        movieId: 808,
      );
      await controller.load(source);
      await controller.seek(const Duration(seconds: 40));
      await tester.pump(const Duration(milliseconds: 100));

      final replayBtn = find.byTooltip('Replay 10s');
      final forwardBtn = find.byTooltip('Forward 10s');

      expect(replayBtn, findsOneWidget);
      expect(forwardBtn, findsOneWidget);

      await tester.tap(forwardBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.state.position, equals(const Duration(seconds: 50)));

      await tester.tap(replayBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.state.position, equals(const Duration(seconds: 40)));

      await finishPlayerTest(tester);
    });

    testWidgets('double-tap on left and right screen edges triggers 10s seek', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();

      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'The Matrix',
        movieId: 909,
      );
      await controller.load(source);
      await controller.seek(const Duration(seconds: 60));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      await tester.tapAt(const Offset(700, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(700, 300));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(controller.state.position, equals(const Duration(seconds: 70)));

      await tester.tapAt(const Offset(100, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(100, 300));
      await tester.pump(const Duration(milliseconds: 1000));

      expect(controller.state.position, equals(const Duration(seconds: 60)));

      await finishPlayerTest(tester);
    });
  });

  testWidgets('seek bar previews while dragging and commits the final position',
      (tester) async {
    final seeks = <Duration>[];
    final previews = <Duration>[];
    final source = PlayerSource.vod(
      url: 'http://test.vod/movie.mp4',
      title: 'Scrub Test',
      movieId: 99,
      posterUrl: null,
    );
    final state = PlayerState(
      status: PlayerStatus.playing,
      source: source,
      position: const Duration(minutes: 10),
      duration: const Duration(minutes: 90),
      bufferedPosition: const Duration(minutes: 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SizedBox.expand(
            child: PlayerControls(
              playerState: state,
              onPlayPause: () {},
              onRequestSeekPreview: (position) async {
                previews.add(position);
                return null;
              },
              onScrubStart: () {},
              onScrubEnd: seeks.add,
              onSeekRelative: (_) {},
              onVolumeChanged: (_) {},
              onToggleMute: () {},
              onNextChannel: () {},
              onPreviousChannel: () {},
              onCycleAspectRatio: () {},
              onSelectPlaybackRate: (_) {},
              onOpenAudioTracks: () {},
              onOpenSubtitles: () {},
              onToggleLock: () {},
              onOpenQuickSettings: () {},
              onToggleFullscreen: () {},
              onClose: () {},
            ),
          ),
        ),
      ),
    );

    final slider = find.byKey(const ValueKey('interactive-player-seek-bar'));
    expect(slider, findsOneWidget);

    final rect = tester.getRect(slider);
    final gesture = await tester.startGesture(
      rect.centerLeft + Offset(rect.width * 0.2, 0),
    );
    await gesture.moveTo(rect.centerLeft + Offset(rect.width * 0.75, 0));
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byKey(const ValueKey('player-seek-preview')), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 180));

    expect(previews, isNotEmpty);
    expect(seeks, hasLength(1));
    expect(seeks.last, greaterThan(const Duration(minutes: 45)));
  });
}
