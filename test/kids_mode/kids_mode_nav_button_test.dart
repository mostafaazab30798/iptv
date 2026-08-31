import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/kids_mode_storage.dart';
import 'package:iptv/features/kids_mode/widgets/kids_mode_nav_button.dart';
import 'package:iptv/features/kids_mode/widgets/kids_pin_dialog.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/navigation/app_shell.dart';

class _MemoryKidsModeStorage implements KidsModeStorage {
  _MemoryKidsModeStorage({this.enabled = false, this.salt, this.verifier});

  bool enabled;
  String? salt;
  String? verifier;

  @override
  Future<StoredKidsModeConfig> load() async => StoredKidsModeConfig(
    enabled: enabled,
    pinSalt: salt,
    pinVerifier: verifier,
  );

  @override
  Future<void> savePin({required String salt, required String verifier}) async {
    this.salt = salt;
    this.verifier = verifier;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

void _setSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<bool> _readVisibility(WidgetTester tester) async {
  late bool visible;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          visible = KidsModeNavButton.visibleFor(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return visible;
}

Widget _buttonApp(KidsModeController controller) {
  return ProviderScope(
    overrides: [kidsModeProvider.overrideWith((_) => controller)],
    child: MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: const Scaffold(body: Center(child: KidsModeNavButton())),
    ),
  );
}

Widget _shellApp({
  required KidsModeController controller,
  required String location,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(state: state, child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (_, __) => const SizedBox()),
          GoRoute(path: Routes.live, builder: (_, __) => const SizedBox()),
          GoRoute(
            path: Routes.movies,
            builder: (_, __) => const Text('movies-stub'),
          ),
          GoRoute(path: Routes.series, builder: (_, __) => const SizedBox()),
          GoRoute(path: Routes.favorites, builder: (_, __) => const SizedBox()),
          GoRoute(
            path: Routes.search,
            builder: (_, __) => const Text('search-stub'),
          ),
          GoRoute(
            path: Routes.settings,
            builder: (_, __) => const Text('settings-stub'),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [kidsModeProvider.overrideWith((_) => controller)],
    child: MaterialApp.router(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('shows on tablet, TV, and desktop widths', (tester) async {
    _setSurface(tester, const Size(1024, 768));
    expect(await _readVisibility(tester), isTrue);

    _setSurface(tester, const Size(1920, 1080));
    expect(await _readVisibility(tester), isTrue);

    _setSurface(tester, const Size(1280, 800));
    expect(await _readVisibility(tester), isTrue);
  });

  testWidgets('hides on a compact phone', (tester) async {
    _setSurface(tester, const Size(390, 844));
    expect(await _readVisibility(tester), isFalse);
  });

  testWidgets('is a labeled button, not a switch', (tester) async {
    final controller = KidsModeController(_MemoryKidsModeStorage());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buttonApp(controller));
    await tester.pump();

    expect(find.byKey(KidsModeNavButton.buttonKey), findsOneWidget);
    expect(find.text(en.kidsModeTitle), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('tap opens the parent PIN dialog', (tester) async {
    final controller = KidsModeController(_MemoryKidsModeStorage());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_buttonApp(controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(KidsModeNavButton.buttonKey));
    await tester.pumpAndSettle();

    expect(find.byType(KidsPinDialog), findsOneWidget);
    expect(find.text(en.kidsModeCreatePinTitle), findsOneWidget);
  });

  testWidgets('landscape shell places the button in the top nav', (
    tester,
  ) async {
    _setSurface(tester, const Size(1920, 1080));
    final controller = KidsModeController(_MemoryKidsModeStorage());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _shellApp(controller: controller, location: Routes.movies),
    );
    await tester.pump();

    expect(find.byKey(KidsModeNavButton.buttonKey), findsOneWidget);
    expect(find.text(en.kidsModeTitle), findsWidgets);
  });

  testWidgets('portrait phone shell does not show the shortcut', (
    tester,
  ) async {
    _setSurface(tester, const Size(390, 844));
    final controller = KidsModeController(_MemoryKidsModeStorage());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _shellApp(controller: controller, location: Routes.movies),
    );
    await tester.pump();

    expect(find.byKey(KidsModeNavButton.buttonKey), findsNothing);
  });
}
