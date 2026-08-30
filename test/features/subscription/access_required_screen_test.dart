import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/features/subscription/access_required_screen.dart';
import 'package:iptv/l10n/app_localizations_en.dart';

import '../account/test_support.dart';

final en = AppLocalizationsEn();

void main() {
  testWidgets(
    'can clear the saved IPTV session and return to server sign-in',
    (tester) async {
      final session = TestSessionNotifier(
        const ServerConfig(
          serverUrl: 'https://provider.example',
          username: 'viewer',
          password: 'secret',
        ),
      );
      final account = AccountTestHarness();

      await tester.pumpWidget(
        buildAuthTestApp(
          overrides: [
            appAccountSessionProvider.overrideWith((ref) => account.controller),
            sessionProvider.overrideWith((ref) => session),
          ],
          initialLocation: Routes.accessRequired,
          routes: {
            Routes.accessRequired: (_) => const AccessRequiredScreen(),
            Routes.onboarding: (_) =>
                const Scaffold(body: Text('server-sign-in')),
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text(en.accessRequiredChangeServer));
      await pumpUntil(
        tester,
        () => find.text('server-sign-in').evaluate().isNotEmpty,
      );

      expect(session.clearSessionCalls, 1);
      expect(session.state.valueOrNull, isNull);
      expect(find.text('server-sign-in'), findsOneWidget);
    },
  );
}
