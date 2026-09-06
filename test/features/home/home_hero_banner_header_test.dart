import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/home/widgets/home_hero_banner.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/layouts/form_factor.dart';
import 'package:iptv/shared/navigation/shell_portrait_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestBanner({
    required HomeHeroItem item,
    VoidCallback? onRefresh,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.zero,
        ),
        child: Scaffold(
          body: HomeHeroBanner(
            item: item,
            onPlay: (_) {},
            onRefresh: onRefresh,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'HomeHeroBanner with movie item renders ShellPortraitHeader and capsule',
    (tester) async {
      const movieHero = HomeHeroItem(
        title: 'Dune: Part Two',
        subtitle: 'Sci-Fi • 2024 • ★ 8.6',
        type: HeroItemType.movie,
        genre: 'Sci-Fi',
        rating: '8.6',
      );

      var refreshed = false;

      await tester.pumpWidget(
        buildTestBanner(item: movieHero, onRefresh: () => refreshed = true),
      );

      expect(find.byType(ShellPortraitHeader), findsOneWidget);
      expect(find.byType(ShellActionCapsule), findsOneWidget);

      final header = tester.widget<ShellPortraitHeader>(
        find.byType(ShellPortraitHeader),
      );
      expect(header.currentPath, Routes.home);
      expect(header.titleColor, AppColors.accent);
      expect(header.showBackgroundGradient, isFalse);
      expect(header.titleShadows, isNotNull);

      // Verify refresh tap triggers callback
      expect(find.byType(ShellSpinningRefreshButton), findsOneWidget);
      await tester.tap(find.byType(ShellSpinningRefreshButton));
      await tester.pump();
      expect(refreshed, isTrue);
    },
  );

  testWidgets(
    'live badge on portrait hero sits below the floating shell chrome',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 47);
      addTearDown(tester.view.reset);

      const liveHero = HomeHeroItem(
        title: 'Team Alpha vs Team Beta',
        subtitle: 'Friendly',
        type: HeroItemType.live,
        match: LiveMatch(
          channel: Channel(id: 1, serverId: 1, streamId: 1, name: 'Sports 1'),
          programTitle: 'Team Alpha vs Team Beta',
          teams: [],
          fixture: LiveFixture(
            homeName: 'Team Alpha',
            awayName: 'Team Beta',
            teams: [],
            state: 'in',
            clock: "45'",
            league: 'Friendly',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              // Home strips MediaQuery top padding; chrome still uses View inset.
              return MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: const Scaffold(
                  body: HomeHeroBanner(item: liveHero, onPlay: _noopPlay),
                ),
              );
            },
          ),
        ),
      );

      expect(find.byType(ShellPortraitHeader), findsOneWidget);
      expect(find.text('LIVE'), findsOneWidget);

      final headerBottom = tester
          .getBottomLeft(find.byType(ShellPortraitHeader))
          .dy;
      final badgeTop = tester.getTopLeft(find.text('LIVE')).dy;
      expect(badgeTop, greaterThanOrEqualTo(headerBottom));
    },
  );

  testWidgets(
    'landscape hero height includes overlay chrome and skips portrait header',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      late double height;
      late double overlayInset;

      const movieHero = HomeHeroItem(
        title: 'Dune: Part Two',
        subtitle: 'Sci-Fi • 2024 • ★ 8.6',
        type: HeroItemType.movie,
        genre: 'Sci-Fi',
        rating: '8.6',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 800)),
            child: Builder(
              builder: (context) {
                height = HomeHeroBanner.heightOf(context);
                overlayInset = ChromeHeights.headerExtentOf(
                  context,
                  fromView: true,
                );
                return const Scaffold(
                  body: HomeHeroBanner(item: movieHero, onPlay: _noopPlay),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(ShellPortraitHeader), findsNothing);
      expect(overlayInset, ChromeHeights.forFactor(FormFactor.desktop).header);
      expect(height, 420.0 + overlayInset);
    },
  );
}

void _noopPlay(HomeHeroItem item) {}
