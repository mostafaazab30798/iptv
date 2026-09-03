import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:iptv/player/handoff/application/audio_handoff_server_controller.dart';
import 'package:iptv/player/handoff/presentation/companion_pointer_overlay.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/focus/remote_focus.dart';
import 'package:iptv/shared/navigation/app_back_navigation.dart';
import 'package:iptv/shared/navigation/navigator_keys.dart';


/// Root application widget.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initialize());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  Future<void> _initialize() async {
    await initializeAfterFirstFrame();
    if (!mounted) return;
    ref.read(localeProvider.notifier).refreshFromStorage();

    // First start: binds immediately, may have an early/wrong IP if Wi-Fi just connected
    unawaited(ref.read(audioHandoffServerProvider.notifier).startHosting(
          playerController: ref.read(playerControllerProvider.notifier),
          autoMuteTv: true,
        ));

    await _syncAnalytics(ref.read(appAccountSessionProvider));
    if (CommercialApiConfig.isConfigured) {
      await ref.read(updateProvider.notifier).checkForUpdates(silent: true);
    }

    // Second start after 3 seconds: ensures Wi-Fi is fully initialized before
    // resolving the local IP, so the correct LAN IP is broadcast in the beacon.
    await Future<void>.delayed(const Duration(seconds: 3));
    if (mounted) {
      unawaited(ref.read(audioHandoffServerProvider.notifier).startHosting(
            playerController: ref.read(playerControllerProvider.notifier),
            autoMuteTv: true,
          ));
    }
  }



  Future<void> _onAppResumed() async {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
    // Re-start handoff server on resume to refresh the LAN IP (could have changed
    // if device connected to a different network while backgrounded).
    // Refresh advertised LAN IP on resume without dropping companion clients.
    unawaited(ref.read(audioHandoffServerProvider.notifier).startHosting(
          playerController: ref.read(playerControllerProvider.notifier),
          autoMuteTv: true,
        ));
    if (!CommercialApiConfig.isConfigured) return;
    final updateState = ref.read(updateProvider);
    if (updateState.isMandatoryBlocking) {
      await ref.read(updateProvider.notifier).checkForUpdates(force: true);
      if (mounted) {
        await showUpdateDialogIfNeeded(context, ref, mandatoryOnly: true);
      }
      return;
    }
    await ref.read(updateProvider.notifier).checkForUpdates(silent: true);
  }

  Future<void> _syncAnalytics(AppAccountSessionState session) async {
    if (!CommercialApiConfig.isConfigured) return;
    final analytics = ref.read(analyticsRepositoryProvider);
    if (session.isSignedIn) {
      final deviceRepo = ref.read(deviceRepositoryProvider);
      final deviceId = await deviceRepo.currentDeviceId();
      await analytics.start(deviceId: deviceId);
      await analytics.track(AnalyticsEventName.sessionStarted);

      final updateState = ref.read(updateProvider);
      if (updateState.pendingDownloadAfterSignIn &&
          updateState.updateAvailable) {
        ref.read(updateProvider.notifier).clearPendingDownloadAfterSignIn();
        if (mounted) {
          await showUpdateDialogIfNeeded(context, ref);
        }
      }
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

      // D-pad / TV remote navigation covers every route, dialog and sheet.
      // The companion cursor sits above it so trackpad aiming stays visible.
      builder: (context, child) {
        return RemoteFocusScope(
          child: Dpad(
            theme: const DpadThemeData(
              effects: [ArmedDpadEffects()],
              scrollPadding: 56,
            ),
            keySet: const DpadKeySet().copyWith(
              select: [
                ...DpadKeySet.defaultSelect,
                LogicalKeyboardKey.gameButtonSelect,
              ],
            ),
            debugOverlay: kDebugMode &&
                const bool.fromEnvironment(
                  'TV_FOCUS_INSPECTOR',
                  defaultValue: false,
                ),
            onBack: () {
              final ctx = rootNavigatorKey.currentContext;
              if (ctx == null) return false;
              unawaited(handleRemoteBack(ctx));
              return true;
            },
            child: CompanionPointerOverlay(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },

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
