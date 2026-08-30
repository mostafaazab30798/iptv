import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/features/account/widgets/auth_brand_panel.dart';
import 'package:iptv/features/account/widgets/auth_card.dart';
import 'package:iptv/features/account/widgets/auth_email_field.dart';
import 'package:iptv/features/account/widgets/auth_primary_button.dart';
import 'package:iptv/features/account/sign_in_screen.dart';
import 'package:iptv/features/account/verify_code_screen.dart';
import 'package:iptv/l10n/app_localizations.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  setUp(() async {
    await initFakePreferences();
  });

  Widget pumpableApp(
    AccountTestHarness harness, {
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    bool disableAnimations = false,
  }) {
    return buildAuthTestApp(
      overrides: harness.overrides,
      initialLocation: Routes.signIn,
      locale: locale,
      textScale: textScale,
      disableAnimations: disableAnimations,
      routes: {
        Routes.signIn: (_) => const SignInScreen(),
        Routes.verifyCode: (_) => const VerifyCodeScreen(),
        Routes.onboarding: (_) => const Scaffold(body: Text('onboarding-stub')),
        Routes.home: (_) => const Scaffold(body: Text('home-stub')),
      },
    );
  }

  testWidgets('compact layout on a narrow phone shows the form without the '
      'wide brand tagline, and without overflow', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(AuthEmailField), findsOneWidget);
    expect(find.byType(AuthPrimaryButton), findsOneWidget);
    expect(find.text('HOPE TV'), findsOneWidget);
    // The full brand panel (with tagline) is only shown in the wide layout.
    expect(find.text(en.accountBrandTagline), findsNothing);
  });

  testWidgets(
    'wide layout on a desktop/TV width shows the two-region composition',
    (tester) async {
      setSurfaceSize(tester, const Size(1920, 1080));
      final harness = AccountTestHarness();
      await tester.pumpWidget(pumpableApp(harness));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(AuthBrandPanel), findsOneWidget);
      expect(find.byType(AuthCard), findsOneWidget);
      expect(find.text(en.accountBrandTagline), findsOneWidget);
    },
  );

  testWidgets('invalid email shows inline validation error and does not '
      'navigate away', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(find.byType(AuthPrimaryButton));
    await tester.pump();
    await tester.pump();

    expect(find.text(en.accountEmailInvalid), findsOneWidget);
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(VerifyCodeScreen), findsNothing);
  });

  testWidgets('valid email submits and navigates to the verification screen', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'viewer@example.com');
    await tester.tap(find.byType(AuthPrimaryButton));
    await pumpUntil(
      tester,
      () => find.byType(VerifyCodeScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(VerifyCodeScreen), findsOneWidget);
    expect(find.text(en.accountVerifyTitle), findsOneWidget);
  });

  testWidgets('pressing Enter in the email field submits the form', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'viewer@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpUntil(
      tester,
      () => find.byType(VerifyCodeScreen).evaluate().isNotEmpty,
    );

    expect(find.byType(VerifyCodeScreen), findsOneWidget);
  });

  testWidgets('restores a previously entered email pending verification', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: 'returning@example.com');
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    expect(find.text('returning@example.com'), findsOneWidget);
  });

  testWidgets('renders Arabic RTL layout without overflow', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness, locale: const Locale('ar')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(SignInScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('renders without overflow at 200% text scale', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness, textScale: 2.0));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing when reduced motion is enabled', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness, disableAnimations: true));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(en.accountSendCode), findsOneWidget);
  });

  testWidgets('Tab moves focus from the email field to the primary button', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(1920, 1080));
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.tap(find.byType(TextFormField));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    final primaryFocus = FocusManager.instance.primaryFocus;
    expect(primaryFocus, isNotNull);
    expect(
      primaryFocus!.context!.findAncestorWidgetOfExactType<AuthPrimaryButton>(),
      isNotNull,
    );
  });
}
