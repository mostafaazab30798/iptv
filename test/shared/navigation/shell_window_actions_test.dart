import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/navigation/shell_portrait_header.dart';

Widget _wrapWithL10n(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en')],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('supportsFullscreen is only true on Windows and false on Android/TV', () {
    if (PlatformService.instance.isWindows) {
      expect(PlatformService.instance.supportsFullscreen, isTrue);
    } else {
      expect(PlatformService.instance.supportsFullscreen, isFalse);
    }
  });

  testWidgets('Appshell header does not display minimize, maximize, or close buttons', (tester) async {
    await tester.pumpWidget(
      _wrapWithL10n(
        const ShellActionCapsule(currentPath: '/home'),
      ),
    );

    // Minimize, Maximize, and Close must NOT be in the Flutter appshell
    expect(find.byTooltip('Minimize'), findsNothing);
    expect(find.byTooltip('Maximize'), findsNothing);
    expect(find.byTooltip('Restore'), findsNothing);
    expect(find.byTooltip('Close'), findsNothing);
  });

  testWidgets('ShellActionCapsule displays ShellFullscreenToggleButton only when supportsFullscreen is true', (tester) async {
    await tester.pumpWidget(
      _wrapWithL10n(
        const ShellActionCapsule(currentPath: '/home'),
      ),
    );

    if (PlatformService.instance.supportsFullscreen) {
      expect(find.byType(ShellFullscreenToggleButton), findsOneWidget);
    } else {
      expect(find.byType(ShellFullscreenToggleButton), findsNothing);
    }
  });
}
