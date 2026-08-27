import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';

import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/repositories/favorites_repository.dart';
import 'package:iptv/features/live/live_controller.dart';
import 'package:iptv/features/live/live_screen.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/player/presentation/player_view.dart';

class FakeLiveController extends LiveController {
  FakeLiveController() : super(null) {
    state = const LiveState(
      categories: [
        Category(id: 1, serverId: 1, type: CategoryType.live, name: 'Sports'),
        Category(id: 2, serverId: 1, type: CategoryType.live, name: 'News'),
      ],
      filteredChannels: [
        Channel(id: 1, serverId: 1, streamId: 101, name: 'ESPN HD', categoryId: 1),
        Channel(id: 2, serverId: 1, streamId: 102, name: 'BBC News', categoryId: 2),
      ],
      totalChannelCount: 2,
      isLoading: false,
    );
  }

  @override
  void selectCategory(int categoryId) {}
}

class FakeFavoritesRepository implements FavoritesRepository {
  @override
  Future<Result<void>> addFavorite(Favorite favorite) async => const Ok(null);

  @override
  Future<Result<List<Favorite>>> getFavorites({FavoriteType? type}) async => const Ok([]);

  @override
  Future<bool> isFavorite({required FavoriteType type, required int itemId}) async => false;

  @override
  Future<Result<void>> removeFavorite(int favoriteId) async => const Ok(null);

  @override
  Future<Result<void>> removeFavoriteByItemId({
    required FavoriteType type,
    required int itemId,
  }) async =>
      const Ok(null);
}

void main() {
  group('LiveScreen with LiveMiniPreview Widget Tests', () {
    late FakePlayerEngine fakeEngine;
    late PlayerController controller;

    setUp(() {
      fakeEngine = FakePlayerEngine();
      controller = PlayerController(engine: fakeEngine);
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> settleBriefly(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((_) => controller),
          liveControllerProvider.overrideWith((_) => FakeLiveController()),
          favoritesRepositoryProvider.overrideWithValue(FakeFavoritesRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: LiveScreen(),
        ),
      );
    }

    testWidgets('navigates to channels view and toggles between grid and list views', (tester) async {
      await tester.pumpWidget(createTestApp());
      await settleBriefly(tester);

      await tester.tap(find.text('Sports'));
      await settleBriefly(tester);

      expect(find.text('ESPN HD'), findsOneWidget);
      expect(find.text('BBC News'), findsOneWidget);

      final toggleBtn = find.byKey(const ValueKey('live_view_mode_toggle'));
      expect(toggleBtn, findsOneWidget);
      await tester.tap(toggleBtn);
      await settleBriefly(tester);

      expect(find.byTooltip('Switch to List View'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('shows live preview and quick controls when player source is active in channels view', (tester) async {
      await tester.pumpWidget(createTestApp());
      await settleBriefly(tester);

      await tester.tap(find.text('Sports'));
      await settleBriefly(tester);

      await controller.load(
        PlayerSource.live(
          url: 'http://test.live/espn.m3u8',
          title: 'ESPN HD',
          channelId: 101,
        ),
      );
      await settleBriefly(tester);

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Fullscreen'), findsOneWidget);
      expect(find.byType(PlayerView), findsOneWidget);

      await controller.stop();
      expect(controller.state.status, equals(PlayerStatus.stopped));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
