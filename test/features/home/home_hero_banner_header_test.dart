import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/home/widgets/home_hero_banner.dart';
import 'package:iptv/l10n/app_localizations.dart';
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

  testWidgets('HomeHeroBanner with movie item renders ShellPortraitHeader and capsule', (tester) async {
    final movieHero = const HomeHeroItem(
      title: 'Dune: Part Two',
      subtitle: 'Sci-Fi • 2024 • ★ 8.6',
      type: HeroItemType.movie,
      genre: 'Sci-Fi',
      rating: '8.6',
    );

    var refreshed = false;

    await tester.pumpWidget(
      buildTestBanner(
        item: movieHero,
        onRefresh: () => refreshed = true,
      ),
    );

    expect(find.byType(ShellPortraitHeader), findsOneWidget);
    expect(find.byType(ShellActionCapsule), findsOneWidget);

    final header = tester.widget<ShellPortraitHeader>(find.byType(ShellPortraitHeader));
    expect(header.currentPath, Routes.home);
    expect(header.titleColor, AppColors.accent);
    expect(header.showBackgroundGradient, isFalse);
    expect(header.titleShadows, isNotNull);

    // Verify refresh tap triggers callback
    expect(find.byType(ShellSpinningRefreshButton), findsOneWidget);
    await tester.tap(find.byType(ShellSpinningRefreshButton));
    await tester.pump();
    expect(refreshed, isTrue);
  });
}
