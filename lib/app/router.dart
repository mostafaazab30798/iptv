import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/features/favorites/favorites_screen.dart';
import 'package:iptv/features/guide/guide_screen.dart';
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
  static const search = '/search';
  static const player = '/player';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (previous, next) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final sessionAsync = ref.read(sessionProvider);

      // Splash owns the initial session load + first navigation.
      if (loc == Routes.splash) return null;

      if (sessionAsync.isLoading) {
        return Routes.splash;
      }

      final isAuthed = sessionAsync.valueOrNull?.isValid ?? false;
      final isOnboarding = loc == Routes.onboarding;

      if (!isAuthed && !isOnboarding) {
        return Routes.onboarding;
      }

      return null;
    },
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
      GoRoute(
        path: Routes.search,
        pageBuilder: (context, state) => _fade(const SearchScreen()),
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
