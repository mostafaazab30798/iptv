import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/navigation/app_back_navigation.dart';
import 'package:iptv/shared/navigation/navigator_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(InnerBackDispatcher.instance.reset);

  Widget app({required Widget home}) {
    return MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    );
  }

  testWidgets('inner back is consumed before leaving the tab', (tester) async {
    var innerHandled = false;
    var inList = true;

    await tester.pumpWidget(
      app(
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (InnerBackDispatcher.instance.handle()) return;
          },
          child: InnerBackScope(
            onBack: () {
              if (!inList) return false;
              innerHandled = true;
              inList = false;
              return true;
            },
            child: const Scaffold(body: Text('channels-stub')),
          ),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(innerHandled, isTrue);
    expect(find.text('channels-stub'), findsOneWidget);
  });

  testWidgets('after player pops, shell back goes home instead of exiting', (
    tester,
  ) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: Routes.live,
      routes: [
        GoRoute(
          path: Routes.player,
          builder: (_, _) => const Scaffold(body: Text('player-stub')),
        ),
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  handleShellSystemBack(context, state.uri.path);
                }
              },
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => const Text('home-stub'),
            ),
            GoRoute(
              path: Routes.live,
              builder: (_, _) => const Scaffold(body: Text('live-stub')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
    await tester.pump();

    unawaited(router.push(Routes.player));
    await tester.pumpAndSettle();
    expect(find.text('player-stub'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('live-stub'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('home-stub'), findsOneWidget);
    expect(find.text('live-stub'), findsNothing);
  });

  testWidgets('home system back shows a leave confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: Builder(
          builder: (context) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) showLeaveAppDialog(context);
              },
              child: const Scaffold(body: Text('home-stub')),
            );
          },
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(LeaveAppDialog), findsOneWidget);
    expect(find.text(en.exitAppTitle), findsOneWidget);
    expect(find.text('home-stub'), findsOneWidget);
  });

  testWidgets('cancelling the leave dialog keeps the current screen', (
    tester,
  ) async {
    await tester.pumpWidget(app(home: const Scaffold(body: LeaveAppDialog())));

    await tester.tap(find.text(en.actionCancel));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveAppDialog), findsNothing);
  });

  testWidgets('RootBackScope pops a pushed page instead of exiting', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: RootBackScope(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const Scaffold(body: Text('details-stub')),
                      ),
                    );
                  },
                  child: const Text('open-details'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-details'));
    await tester.pumpAndSettle();
    expect(find.text('details-stub'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('details-stub'), findsNothing);
    expect(find.text('open-details'), findsOneWidget);
  });
}
