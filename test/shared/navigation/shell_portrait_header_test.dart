import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/navigation/shell_portrait_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    required Widget child,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: MediaQuery(
        data: MediaQueryData(
          padding: viewPadding,
          viewPadding: viewPadding,
        ),
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('ShellPortraitHeader metrics', () {
    testWidgets('topInsetOf returns 48.0 when top padding is 0', (tester) async {
      double? topInset;
      double? height;

      await tester.pumpWidget(
        buildTestWidget(
          child: Builder(
            builder: (context) {
              topInset = ShellPortraitHeader.topInsetOf(context);
              height = ShellPortraitHeader.heightOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(topInset, 48.0);
      expect(height, 48.0 + 42.0 + AppSpacing.sm);
    });

    testWidgets('renders title and triggers refresh callback', (tester) async {
      var refreshed = false;

      await tester.pumpWidget(
        buildTestWidget(
          child: ShellPortraitHeader(
            title: 'Watch',
            currentPath: Routes.home,
            onRefresh: () => refreshed = true,
            titleColor: AppColors.accent,
            showBackgroundGradient: false,
          ),
        ),
      );

      expect(find.text('Watch'), findsOneWidget);
      expect(find.byType(ShellActionCapsule), findsOneWidget);
      expect(find.byType(ShellSpinningRefreshButton), findsOneWidget);

      await tester.tap(find.byType(ShellSpinningRefreshButton));
      await tester.pump();

      expect(refreshed, isTrue);
    });

    testWidgets('supports custom title shadows on hero card', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const ShellPortraitHeader(
            title: 'Movies',
            currentPath: Routes.movies,
            titleShadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Movies'));
      expect(textWidget.style?.shadows?.length, 1);
      expect(textWidget.style?.fontSize, 26);
      expect(textWidget.style?.fontWeight, FontWeight.w900);
    });
  });
}
