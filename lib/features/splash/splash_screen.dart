import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/bootstrap.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/shared/widgets/shimmer.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await initializeAfterFirstFrame();
    // Kick app-account bootstrap (separate from IPTV session).
    ref.read(appAccountSessionProvider);
    await ref.read(sessionProvider.notifier).loadSession();
    if (!mounted) return;

    if (CommercialApiConfig.accessGateEnabled) {
      // The commercial gate may be re-enabled in a future build. Only that
      // build needs to wait for account bootstrap before choosing a route.
      for (var i = 0; i < 40; i++) {
        if (!ref.read(appAccountSessionProvider).loading) break;
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;
      }

      final app = ref.read(appAccountSessionProvider);
      if (!app.isSignedIn) {
        context.go(Routes.signIn);
        return;
      }
    }

    final iptv = ref.read(sessionProvider).valueOrNull;

    if (iptv != null && iptv.isValid) {
      if (CommercialApiConfig.accessGateEnabled) {
        await ref.read(entitlementProvider.notifier).refresh();
        if (!mounted) return;
        final entitlement = ref.read(entitlementProvider);
        context.go(
          (kDebugMode || entitlement.allowsPremium)
              ? Routes.home
              : Routes.accessRequired,
        );
      } else {
        context.go(Routes.home);
      }
    } else {
      context.go(Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo with Ambient Glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 50,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    AppConstants.appLogo,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'HOPE',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'IPTV',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                      shadows: [
                        Shadow(color: Color(0x9600E5FF), blurRadius: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 140,
                  height: 4,
                  child: Shimmer(
                    baseColor: AppColors.bg3,
                    highlightColor: AppColors.accent,
                    child: Container(color: AppColors.bg3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
