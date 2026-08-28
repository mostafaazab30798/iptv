import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/bootstrap.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// Root application widget.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    await initializeAfterFirstFrame();
    if (!mounted) return;
    ref.read(localeProvider.notifier).refreshFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'HOPE IPTV',
      debugShowCheckedModeBanner: false,

      // Routing
      routerConfig: router,

      // Theme
      theme: AppTheme.darkTheme(locale),
      darkTheme: AppTheme.darkTheme(locale),
      themeMode: ThemeMode.dark,

      // Localization
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
    );
  }
}
