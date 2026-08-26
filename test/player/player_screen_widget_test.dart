import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/features/player/player_screen.dart';
import 'package:iptv/player/application/player_controller.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';
import 'package:iptv/player/presentation/buffering_indicator.dart';
import 'package:iptv/player/presentation/player_error_view.dart';
import 'package:iptv/player/presentation/player_view.dart';

void main() {
  group('PlayerScreen Widget Tests', () {
    late FakePlayerEngine fakeEngine;
    late PlayerController controller;

    setUp(() {
      fakeEngine = FakePlayerEngine();
      controller = PlayerController(engine: fakeEngine);
    });

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
      await tester.pumpAndSettle();

      expect(find.byType(PlayerView), findsOneWidget);
      expect(find.byType(BufferingIndicator), findsOneWidget);
      expect(find.byType(PlayerErrorView), findsNothing);
    });

    testWidgets('displays channel title when playing a live channel', (tester) async {
      await tester.pumpWidget(createTestApp());

      final source = PlayerSource.live(
        url: 'http://test.live/ch.m3u8',
        title: 'HBO HD',
        channelId: 10,
        currentProgramTitle: 'Game of Thrones',
      );

      await controller.load(source);
      await tester.pumpAndSettle();

      expect(find.text('HBO HD'), findsAtLeast(1));
      expect(find.text('Game of Thrones'), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('renders PlayerErrorView on unrecoverable error and handles retry', (tester) async {
      await tester.pumpWidget(createTestApp());

      final source = PlayerSource.live(
        url: 'http://broken.stream/ch.m3u8',
        title: 'Broken Stream',
      );
      await controller.load(source);

      fakeEngine.simulateError(PlayerErrorType.serverUnavailable);
      await tester.pumpAndSettle();

      expect(find.byType(PlayerErrorView), findsOneWidget);
      expect(find.text('Server error. Please try again.'), findsOneWidget);

      // Tap retry
      final retryBtn = find.text('Retry');
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();
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

      // Open PlayerScreen
      await tester.tap(find.text('Open Player'));
      await tester.pumpAndSettle();

      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'Interstellar',
        movieId: 707,
      );
      await controller.load(source);
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.state.isPlaying, isTrue);
      expect(fakeEngine.currentStatus, equals(PlayerStatus.playing));

      // Tap close button in player overlay
      final backBtn = find.byTooltip('Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Screen is popped back to previous screen
      expect(find.byType(PlayerScreen), findsNothing);
      expect(find.text('Open Player'), findsOneWidget);

      // Verify controller and engine are completely stopped
      expect(controller.state.status, equals(PlayerStatus.stopped));
      expect(controller.state.source, isNull);
      expect(fakeEngine.currentStatus, equals(PlayerStatus.stopped));
      expect(fakeEngine.currentSource, isNull);
    });

    testWidgets('renders Replay 10s and Forward 10s buttons and handles taps', (tester) async {
      await tester.pumpWidget(createTestApp());

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

      // Tap forward 10s
      await tester.tap(forwardBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.state.position, equals(const Duration(seconds: 50)));

      // Tap replay 10s
      await tester.tap(replayBtn);
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.state.position, equals(const Duration(seconds: 40)));
    });

    testWidgets('double-tap on left and right screen edges triggers 10s seek', (tester) async {
      await tester.pumpWidget(createTestApp());

      final source = PlayerSource.vod(
        url: 'http://test.vod/movie.mp4',
        title: 'The Matrix',
        movieId: 909,
      );
      await controller.load(source);
      await controller.seek(const Duration(seconds: 60));
      await tester.pumpAndSettle();

      // Double tap right edge (e.g. 85% width)
      await tester.tapAt(const Offset(700, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(700, 300));
      await tester.pumpAndSettle();

      expect(controller.state.position, equals(const Duration(seconds: 70)));

      // Double tap left edge (e.g. 15% width)
      await tester.tapAt(const Offset(100, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(100, 300));
      await tester.pumpAndSettle();

      expect(controller.state.position, equals(const Duration(seconds: 60)));
    });
  });
}
