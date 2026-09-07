import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/player/domain/entities/web_video_handle.dart';
import 'package:iptv/player/infrastructure/media_kit_player_engine.dart';
import 'package:iptv/player/infrastructure/player_engine_factory.dart';
import 'package:iptv/player/infrastructure/web/web_player_engine.dart';
import 'package:iptv/player/presentation/player_view.dart';

void main() {
  group('WebVideoHandle', () {
    test(
      'instantiates with viewTypeId and triggers onAspectRatioChanged callback',
      () {
        int? changedIndex;
        final handle = WebVideoHandle(
          viewTypeId: 'test-view-123',
          onAspectRatioChanged: (index, [_ = 1.0]) {
            changedIndex = index;
          },
        );

        expect(handle.viewTypeId, equals('test-view-123'));
        expect(handle.toString(), contains('test-view-123'));

        handle.onAspectRatioChanged?.call(2);
        expect(changedIndex, equals(2));
      },
    );
  });

  group('PlayerEngineFactory non-web behavior', () {
    test('isIosSafariWeb returns false on non-web test runtime', () {
      expect(isIosSafariWeb(), isFalse);
    });

    test(
      'createDefaultPlayerEngine defaults to MediaKitPlayerEngine on non-web',
      () {
        final engine = createDefaultPlayerEngine();
        expect(engine, isA<MediaKitPlayerEngine>());
        engine.dispose();
      },
    );
  });

  group('PlayerView handle rendering', () {
    testWidgets(
      'renders placeholder when platformHandle is null or uninitialized',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PlayerView(aspectRatioIndex: 0, platformHandle: null),
            ),
          ),
        );

        expect(find.byType(HugeIcon), findsOneWidget);
      },
    );

    testWidgets(
      'triggers onAspectRatioChanged when platformHandle is WebVideoHandle',
      (tester) async {
        int? observedIndex;
        double? observedScale;
        final handle = WebVideoHandle(
          viewTypeId: 'test-web-view',
          onAspectRatioChanged: (index, [scale = 1.0]) {
            observedIndex = index;
            observedScale = scale;
          },
        );

        // On non-web unit tests, HtmlElementView is registered in widgets
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerView(
                aspectRatioIndex: 0,
                platformHandle: handle,
                videoWidth: 1920,
                videoHeight: 1080,
              ),
            ),
          ),
        );

        expect(observedIndex, equals(0));
        expect(
          observedScale,
          equals(1.0),
          reason: 'iOS web Best Fit must preserve the native source ratio',
        );
      },
    );
  });
}
