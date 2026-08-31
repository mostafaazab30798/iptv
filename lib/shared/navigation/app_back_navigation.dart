import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/navigation/navigator_keys.dart';

/// LIFO inner-view back handlers (category lists, etc.).
///
/// Shell child [PopScope]s never see Android back — the nested navigator is
/// under the shell page. Screens register here so [handleShellSystemBack]
/// can collapse inner views before leaving the tab.
class InnerBackDispatcher {
  InnerBackDispatcher._();
  static final InnerBackDispatcher instance = InnerBackDispatcher._();

  final List<bool Function()> _handlers = [];

  @visibleForTesting
  void reset() => _handlers.clear();

  void register(bool Function() handler) => _handlers.add(handler);

  void unregister(bool Function() handler) => _handlers.remove(handler);

  /// Returns true when a screen consumed the back press.
  bool handle() {
    for (var i = _handlers.length - 1; i >= 0; i--) {
      if (_handlers[i]()) return true;
    }
    return false;
  }
}

/// Registers [onBack] while this widget is mounted.
/// Return true from [onBack] when the screen consumed the event.
class InnerBackScope extends StatefulWidget {
  const InnerBackScope({super.key, required this.onBack, required this.child});

  final bool Function() onBack;
  final Widget child;

  @override
  State<InnerBackScope> createState() => _InnerBackScopeState();
}

class _InnerBackScopeState extends State<InnerBackScope> {
  late final bool Function() _handler = () => widget.onBack();

  @override
  void initState() {
    super.initState();
    InnerBackDispatcher.instance.register(_handler);
  }

  @override
  void dispose() {
    InnerBackDispatcher.instance.unregister(_handler);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

bool _isHomePath(String path) =>
    path == Routes.home || path.startsWith('${Routes.home}/');

bool _isAuthPath(String path) =>
    path == Routes.splash ||
    path == Routes.signIn ||
    path == Routes.verifyCode ||
    path == Routes.onboarding ||
    path == Routes.accessRequired;

/// System back for shell destinations (Home, Live, Movies, …).
///
/// Must run on [AppShell], which sits on the root shell route — the route
/// Android actually pops after the fullscreen player is dismissed.
Future<void> handleShellSystemBack(
  BuildContext context,
  String currentPath,
) async {
  final nested = shellNavigatorKey.currentState;
  if (nested != null && nested.canPop()) {
    await nested.maybePop();
    return;
  }

  if (InnerBackDispatcher.instance.handle()) return;

  if (!context.mounted) return;

  if (_isHomePath(currentPath)) {
    await confirmLeaveApp(context);
    return;
  }

  context.go(Routes.home);
}

/// Pops a pushed root route, or returns to Home. Never finishes the activity.
void popOrGoHome(BuildContext context) {
  final navigator = Navigator.maybeOf(context);
  if (navigator != null && navigator.canPop()) {
    navigator.pop();
    return;
  }
  if (!context.mounted) return;

  final path = GoRouterState.of(context).uri.path;
  if (_isHomePath(path) || _isAuthPath(path)) {
    unawaited(confirmLeaveApp(context));
    return;
  }
  context.go(Routes.home);
}

/// Root-level pages (search, account, onboarding, …) that sit on the same
/// navigator as the player. Blocks Android from closing the process.
class RootBackScope extends StatelessWidget {
  const RootBackScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) popOrGoHome(context);
      },
      child: child,
    );
  }
}

/// Asks the user to confirm leaving, then exits the process if they accept.
Future<void> confirmLeaveApp(BuildContext context) async {
  final shouldLeave = await showLeaveAppDialog(context);
  if (shouldLeave == true) {
    await SystemNavigator.pop();
  }
}

Future<bool?> showLeaveAppDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'LeaveAppDialog',
    barrierColor: Colors.black.withAlpha(190),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim1, anim2) => const LeaveAppDialog(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class LeaveAppDialog extends StatelessWidget {
  const LeaveAppDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: const Color(0xFF11141D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(18), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(140),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withAlpha(22),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(60),
                    width: 0.8,
                  ),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: AppIcons.logout,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.exitAppTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.exitAppMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withAlpha(200),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withAlpha(20),
                          width: 0.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        context.l10n.actionCancel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textOnAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        context.l10n.exitAppConfirm,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
