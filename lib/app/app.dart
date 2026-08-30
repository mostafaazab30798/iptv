import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/bootstrap.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/features/updates/update_dialog.dart';
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
    await _syncAnalytics(ref.read(appAccountSessionProvider));
  }

  Future<void> _syncAnalytics(AppAccountSessionState session) async {
    if (!CommercialApiConfig.isConfigured) return;
    final analytics = ref.read(analyticsRepositoryProvider);
    if (session.isSignedIn) {
      final deviceRepo = ref.read(deviceRepositoryProvider);
      final deviceId = await deviceRepo.currentDeviceId();
      await analytics.start(deviceId: deviceId);
      await analytics.track(AnalyticsEventName.sessionStarted);
      await ref.read(updateProvider.notifier).checkForUpdates(silent: true);
    } else {
      await analytics.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppAccountSessionState>(appAccountSessionProvider, (prev, next) {
      unawaited(_syncAnalytics(next));
    });

    ref.listen<UpdateState>(updateProvider, (prev, next) {
      if (next.updateAvailable && next.manifest != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(showUpdateDialogIfNeeded(context, ref));
          }
        });
      }
    });

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
