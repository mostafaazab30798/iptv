import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/features/splash/splash_screen.dart';
import 'package:iptv/features/onboarding/onboarding_screen.dart';
import 'package:iptv/features/home/home_screen.dart';
import 'package:iptv/features/live/live_screen.dart';
import 'package:iptv/features/guide/guide_screen.dart';
import 'package:iptv/features/movies/movies_screen.dart';
import 'package:iptv/features/series/series_screen.dart';
import 'package:iptv/features/favorites/favorites_screen.dart';
import 'package:iptv/features/history/history_screen.dart';
import 'package:iptv/features/settings/settings_screen.dart';
import 'package:iptv/features/player/player_screen.dart';
import 'package:iptv/shared/navigation/app_shell.dart';

// ---------------------------------------------------------------------------
// Route names — use these constants instead of raw strings.
// ---------------------------------------------------------------------------

abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const live = '/live';
  static const guide = '/guide';
  static const movies = '/movies';
  static const series = '/series';
  static const favorites = '/favorites';
  static const history = '/history';
  static const settings = '/settings';
  static const player = '/player';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => _fade(const SplashScreen()),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => _fade(const OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.player,
        pageBuilder: (context, state) => _noTransition(const PlayerScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(state: state, child: child),
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
            path: Routes.guide,
            pageBuilder: (context, state) => _fade(const GuideScreen()),
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

CustomTransitionPage<void> _fade(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
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
