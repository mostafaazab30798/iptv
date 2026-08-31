import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/features/kids_mode/kids_mode_actions.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// Compact labeled Kids Mode action for large-screen top navigation.
///
/// This is a pressable button (not a switch). Visual state — accent fill
/// when on, quiet glass when off — is the only on/off indicator.
class KidsModeNavButton extends ConsumerStatefulWidget {
  const KidsModeNavButton({super.key});

  static const Key buttonKey = ValueKey<String>('kids_mode_nav_button');

  /// Tablets, TVs, and desktop windows — not compact phones.
  static bool visibleFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.shortestSide >= 600 || size.width >= 960;
  }

  @override
  ConsumerState<KidsModeNavButton> createState() => _KidsModeNavButtonState();
}

class _KidsModeNavButtonState extends ConsumerState<KidsModeNavButton> {
  bool _hovered = false;
  bool _busy = false;

  Future<void> _onPressed() async {
    if (_busy) return;
    final state = ref.read(kidsModeProvider);
    if (!state.isInitialized || state.isLockedOut) return;

    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    try {
      await confirmKidsModeChange(
        context: context,
        ref: ref,
        enable: !state.isEnabled,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kidsMode = ref.watch(kidsModeProvider);
    final isEnabled = kidsMode.isEnabled;
    final canPress = kidsMode.isInitialized && !kidsMode.isLockedOut && !_busy;
    final highlighted = isEnabled || _hovered;

    final tooltip = kidsMode.isLockedOut
        ? context.l10n.kidsModeLockedOut
        : isEnabled
        ? context.l10n.kidsModeDisableAction
        : context.l10n.kidsModeEnableAction;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: canPress ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        enabled: canPress,
        selected: isEnabled,
        label: context.l10n.kidsModeTitle,
        hint: tooltip,
        child: Tooltip(
          message: tooltip,
          child: GestureDetector(
            key: KidsModeNavButton.buttonKey,
            onTap: canPress ? _onPressed : null,
            child: AnimatedOpacity(
              duration: MotionPolicy.of(context).focus,
              opacity: canPress ? 1 : 0.45,
              child: AnimatedContainer(
                duration: MotionPolicy.of(context).standard,
                curve: AppMotion.curveEnter,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.accent.withAlpha(38)
                      : (_hovered
                            ? Colors.white.withAlpha(18)
                            : Colors.white.withAlpha(12)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isEnabled
                        ? AppColors.accent.withAlpha(130)
                        : (_hovered
                              ? Colors.white.withAlpha(36)
                              : Colors.white.withAlpha(22)),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isEnabled
                          ? AppColors.accent.withAlpha(48)
                          : Colors.black.withAlpha(60),
                      blurRadius: isEnabled ? 12 : 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: isEnabled ? 1.06 : 1.0,
                      duration: MotionPolicy.of(context).focus,
                      child: HugeIcon(
                        icon: isEnabled
                            ? AppIcons.securityCheck
                            : AppIcons.kids,
                        size: 17,
                        color: isEnabled
                            ? AppColors.accent
                            : (highlighted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      context.l10n.kidsModeTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isEnabled
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isEnabled
                            ? Colors.white
                            : (highlighted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary),
                        letterSpacing: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
