import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/kids_mode/kids_mode_state.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// Ultra-stylish Kids Mode card & controls with frosted glass aesthetics,
/// glowing state badges, fluid micro-interactions, and Change PIN action.
class KidsModeCard extends StatelessWidget {
  const KidsModeCard({
    super.key,
    required this.state,
    required this.onToggle,
    required this.onChangePin,
  });

  final KidsModeState state;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onChangePin;

  @override
  Widget build(BuildContext context) {
    final isEnabled = state.isEnabled;
    final isLockedOut = state.isLockedOut;
    final canToggle = state.isInitialized && !isLockedOut && onToggle != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [
                  const Color(0xFF151C28),
                  const Color(0xFF0F121A),
                ]
              : [
                  const Color(0xFF13161F),
                  const Color(0xFF0E1017),
                ],
        ),
        border: Border.all(
          color: isEnabled
              ? AppColors.accent.withAlpha(65)
              : Colors.white.withAlpha(16),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Top Row: Avatar Badge + Title & Status + Switch ---
                Row(
                  children: [
                    // Playful Shield / Avatar Badge
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEnabled
                            ? AppColors.accent.withAlpha(25)
                            : const Color(0xFF1E2330),
                        border: Border.all(
                          color: isEnabled
                              ? AppColors.accent.withAlpha(80)
                              : Colors.white.withAlpha(16),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: isEnabled ? AppIcons.securityCheck : AppIcons.user,
                          color: isEnabled ? AppColors.accent : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Title & Protected Status Pill
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.l10n.kidsModeTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status pill badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isEnabled
                                      ? AppColors.accent.withAlpha(35)
                                      : Colors.white.withAlpha(12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isEnabled
                                        ? AppColors.accent.withAlpha(120)
                                        : Colors.white.withAlpha(24),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  isEnabled
                                      ? context.l10n.kidsModeProtectedBadge
                                      : context.l10n.kidsModeStandardBadge,
                                  style: TextStyle(
                                    color: isEnabled
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEnabled
                                ? context.l10n.kidsModeEnabledSubtitle
                                : context.l10n.kidsModeDisabledSubtitle,
                            style: TextStyle(
                              color: AppColors.textSecondary.withAlpha(210),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Modern Custom Fluid Switch
                    _StylishSwitch(
                      key: const ValueKey('kids_mode_switch'),
                      value: isEnabled,
                      enabled: canToggle,
                      onChanged: canToggle ? onToggle : null,
                    ),
                  ],
                ),

                // --- Change PIN Section (if PIN is set) ---
                if (state.hasPin) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const ValueKey('kids_mode_change_pin'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: isLockedOut || onChangePin == null
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              onChangePin!();
                            },
                      splashColor: AppColors.accent.withAlpha(30),
                      highlightColor: AppColors.accent.withAlpha(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(22),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.accent.withAlpha(50),
                                  width: 0.8,
                                ),
                              ),
                              child: const HugeIcon(
                                icon: AppIcons.lock,
                                color: AppColors.accent,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.kidsModeChangePinAction,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    context.l10n.kidsModeChangePinSubtitle,
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withAlpha(190),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Fluid Animated Switch Widget
class _StylishSwitch extends StatelessWidget {
  const _StylishSwitch({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: value
                ? [const Color(0xFF00C2FF), const Color(0xFF0077FF)]
                : [const Color(0xFF222733), const Color(0xFF161A22)],
          ),
          border: Border.all(
            color: value
                ? AppColors.accent.withAlpha(120)
                : Colors.white.withAlpha(16),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? Colors.white : AppColors.textSecondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                value ? Icons.check_rounded : Icons.circle,
                size: value ? 13 : 6,
                color: value ? const Color(0xFF0066FF) : const Color(0xFF161A22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
