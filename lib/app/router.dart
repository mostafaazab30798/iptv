import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/features/subscription/access_required_screen.dart';
import 'package:iptv/features/account/account_screen.dart';
import 'package:iptv/features/account/devices_screen.dart';
import 'package:iptv/features/account/sign_in_screen.dart';
import 'package:iptv/features/account/verify_code_screen.dart';
import 'package:iptv/features/favorites/favorites_screen.dart';
import 'package:iptv/features/history/history_screen.dart';
import 'package:iptv/features/home/home_screen.dart';
import 'package:iptv/features/live/live_screen.dart';
import 'package:iptv/features/movies/movies_screen.dart';
import 'package:iptv/features/onboarding/onboarding_screen.dart';
import 'package:iptv/features/player/player_screen.dart';
import 'package:iptv/features/search/search_screen.dart';
import 'package:iptv/features/series/series_screen.dart';
import 'package:iptv/features/settings/settings_screen.dart';
import 'package:iptv/features/splash/splash_screen.dart';
import 'package:iptv/shared/navigation/app_back_navigation.dart';
import 'package:iptv/shared/navigation/app_shell.dart';
import 'package:iptv/shared/navigation/navigator_keys.dart';

// ---------------------------------------------------------------------------
// Route names — use these constants instead of raw strings.
// ---------------------------------------------------------------------------

abstract final class Routes {
  static const splash = '/';
  static const signIn = '/sign-in';
  static const verifyCode = '/verify-code';
  static const account = '/account';
  static const devices = '/devices';
  static const accessRequired = '/access-required';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const live = '/live';
  static const movies = '/movies';
  static const series = '/series';
  static const favorites = '/favorites';
  static const history = '/history';
  static const settings = '/settings';
  static const search = '/search';
  static const player = '/player';
}

/// Resolves navigation from the two independent authentication layers.
///
/// When the commercial gate is enabled, an IPTV session is only routed to
/// premium screens after entitlement resolution has completed.
String? routeRedirectForSession({
  required String location,
  required bool iptvAuthenticated,
  required bool appAccountSignedIn,
  bool accessGateEnabled = false,
  bool entitlementAllowsPremium = false,
  bool entitlementLoading = false,
  bool entitlementInitialized = true,
}) {
  final onAppAuthRoute =
      location == Routes.signIn || location == Routes.verifyCode;
  final onAccountRoute =
      location == Routes.account || location == Routes.devices;
  final onOnboarding = location == Routes.onboarding;
  final onAccessRequired = location == Routes.accessRequired;

  if (accessGateEnabled) {
    if (!appAccountSignedIn && !onAppAuthRoute) return Routes.signIn;
    if (appAccountSignedIn && onAppAuthRoute) {
      return iptvAuthenticated ? Routes.home : Routes.onboarding;
    }
    if (appAccountSignedIn && !iptvAuthenticated && !onAccountRoute) {
      return onOnboarding ? null : Routes.onboarding;
    }
    if (appAccountSignedIn &&
        iptvAuthenticated &&
        !onAccountRoute &&
        !onAppAuthRoute) {
      if (!entitlementInitialized) return Routes.splash;
      if (entitlementAllowsPremium) {
        return onAccessRequired ? Routes.home : null;
      }
      if (entitlementLoading) return null;
      return onAccessRequired ? null : Routes.accessRequired;
    }
    return null;
  }

  if (iptvAuthenticated) {
    if (onAccountRoute && !appAccountSignedIn) return Routes.signIn;
    if (onAppAuthRoute || onOnboarding || onAccessRequired) return Routes.home;
    return null;
  }

  if (onAccountRoute) {
    return appAccountSignedIn ? null : Routes.signIn;
  }
  if (onAppAuthRoute) {
    return appAccountSignedIn ? Routes.onboarding : null;
  }
  if (onOnboarding) return null;
  return Routes.onboarding;
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (previous, next) {
    refresh.value++;
  });
  ref.listen(appAccountSessionProvider, (previous, next) {
    refresh.value++;
  });
  if (CommercialApiConfig.accessGateEnabled) {
    ref.listen(entitlementProvider, (previous, next) {
      refresh.value++;
    });
  }
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Splash owns the initial session load + first navigation.
      if (loc == Routes.splash) return null;

      final appAccount = ref.read(appAccountSessionProvider);
      final iptvAsync = ref.read(sessionProvider);
      final entitlement = ref.read(entitlementProvider);
      return routeRedirectForSession(
        location: loc,
        iptvAuthenticated: iptvAsync.valueOrNull?.isValid ?? false,
        appAccountSignedIn: appAccount.isSignedIn,
        accessGateEnabled: CommercialApiConfig.accessGateEnabled,
        entitlementAllowsPremium: kDebugMode || entitlement.allowsPremium,
        entitlementLoading: entitlement.loading,
        entitlementInitialized: entitlement.initialized,
      );
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => _fade(const SplashScreen()),
      ),
      GoRoute(
        path: Routes.signIn,
        pageBuilder: (context, state) =>
            _fade(const SignInScreen(), interceptBack: true),
      ),
      GoRoute(
        path: Routes.verifyCode,
        pageBuilder: (context, state) =>
            _fade(const VerifyCodeScreen(), interceptBack: true),
      ),
      GoRoute(
        path: Routes.account,
        pageBuilder: (context, state) =>
            _fade(const AccountScreen(), interceptBack: true),
      ),
      GoRoute(
        path: Routes.devices,
        pageBuilder: (context, state) =>
            _fade(const DevicesScreen(), interceptBack: true),
      ),
      GoRoute(
        path: Routes.accessRequired,
        pageBuilder: (context, state) =>
            _fade(const AccessRequiredScreen(), interceptBack: true),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            _fade(const OnboardingScreen(), interceptBack: true),
      ),
      GoRoute(
        path: Routes.player,
        pageBuilder: (context, state) => _noTransition(const PlayerScreen()),
      ),
      GoRoute(
        path: Routes.search,
        pageBuilder: (context, state) =>
            _fade(const SearchScreen(), interceptBack: true),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) =>
            AppShell(state: state, child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => _fade(const HomeScreen()),
          ),
          GoRoute(
            path: Routes.live,
            pageBuilder: (context, state) => _fade(const LiveScreen()),
          ),
          GoRoute(
            path: Routes.movies,
            pageBuilder: (context, state) => _fade(const MoviesScreen()),
          ),
          GoRoute(
            path: Routes.series,
            pageBuilder: (context, state) => _fade(const SeriesScreen()),
          ),
          GoRoute(
            path: Routes.favorites,
            pageBuilder: (context, state) => _fade(const FavoritesScreen()),
          ),
          GoRoute(
            path: Routes.history,
            pageBuilder: (context, state) => _fade(const HistoryScreen()),
          ),
          GoRoute(
            path: Routes.settings,
            pageBuilder: (context, state) => _fade(const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Page transitions
// ---------------------------------------------------------------------------

CustomTransitionPage<void> _fade(Widget child, {bool interceptBack = false}) {
  return CustomTransitionPage<void>(
    child: interceptBack ? RootBackScope(child: child) : child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _noTransition(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}
