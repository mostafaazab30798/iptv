import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/features/account/sign_in_screen.dart';
import 'package:iptv/features/account/verify_code_screen.dart';
import 'package:iptv/features/account/widgets/auth_primary_button.dart';
import 'package:iptv/features/account/widgets/resend_code_action.dart';
import 'package:iptv/l10n/app_localizations.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations en;
  const email = 'viewer@example.com';

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
      initialLocation: Routes.verifyCode,
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

  testWidgets('shows the pending destination email and an edit action',
      (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(en.accountVerifySubtitle(email)), findsOneWidget);
    expect(find.text(en.accountEditEmail), findsOneWidget);
  });

  testWidgets(
    'redirects back to sign-in when there is no pending email to verify',
    (tester) async {
      setSurfaceSize(tester, const Size(390, 844));
      final harness = AccountTestHarness();
      await tester.pumpWidget(pumpableApp(harness));
      await tester.pump();
      await tester.pump();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(VerifyCodeScreen), findsNothing);
    },
  );

  testWidgets('"Edit email" navigates back to the sign-in screen',
      (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.tap(find.text(en.accountEditEmail));
    await tester.pump();

    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('entering fewer than six digits shows a validation error '
      'without attempting verification', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.byType(AuthPrimaryButton));
    await tester.pump();

    expect(find.text(en.accountCodeInvalid), findsOneWidget);
    expect(find.byType(VerifyCodeScreen), findsOneWidget);
  });

  testWidgets(
    'pasting all six digits fills the code field and verifies successfully',
    (tester) async {
      setSurfaceSize(tester, const Size(390, 844));
      await initFakePreferences(pendingOtpEmail: email);
      final harness = AccountTestHarness();
      await tester.pumpWidget(pumpableApp(harness));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '123456',
      );

      await tester.tap(find.byType(AuthPrimaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('onboarding-stub'), findsOneWidget);
    },
  );

  testWidgets('submitting the code with Enter verifies successfully',
      (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '654321');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('onboarding-stub'), findsOneWidget);
  });

  testWidgets(
    'resend shows a countdown, disables itself, then re-enables',
    (tester) async {
      setSurfaceSize(tester, const Size(390, 844));
      await initFakePreferences(pendingOtpEmail: email);
      final harness = AccountTestHarness();
      await tester.pumpWidget(pumpableApp(harness));
      await tester.pump();

      expect(find.text(en.accountResendCode), findsOneWidget);

      await tester.tap(find.byType(ResendCodeAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text(en.accountResendCooldown(60)), findsOneWidget);
      expect(find.text(en.accountOtpResent), findsOneWidget);

      await tester.pump(const Duration(seconds: 61));

      expect(find.text(en.accountResendCode), findsOneWidget);
    },
  );

  testWidgets('renders Arabic RTL layout without overflow', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(
      pumpableApp(harness, locale: const Locale('ar')),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final context = tester.element(find.byType(VerifyCodeScreen));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('renders without overflow at 200% text scale', (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness, textScale: 2.0));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without throwing when reduced motion is enabled',
      (tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(
      pumpableApp(harness, disableAnimations: true),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(en.accountVerifyAction), findsOneWidget);
  });

  testWidgets('wide layout shows the two-region composition', (tester) async {
    setSurfaceSize(tester, const Size(1920, 1080));
    await initFakePreferences(pendingOtpEmail: email);
    final harness = AccountTestHarness();
    await tester.pumpWidget(pumpableApp(harness));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(VerifyCodeScreen), findsOneWidget);
  });
}
