import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/focus/shell_focus_navigation.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';

/// Shared EN / العربية language control.
enum LanguagePickerStyle {
  /// Compact pill used on onboarding and auth.
  compact,

  /// Full-width segmented control used in Settings.
  segmented,
}

class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({
    super.key,
    this.style = LanguagePickerStyle.compact,
    this.onLocaleSelected,
  });

  final LanguagePickerStyle style;

  /// Optional override; defaults to [localeProvider].
  final ValueChanged<String>? onLocaleSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    void select(String code) {
      if (onLocaleSelected != null) {
        onLocaleSelected!(code);
      } else {
        ref.read(localeProvider.notifier).setLocale(code);
      }
    }

    return switch (style) {
      LanguagePickerStyle.compact => _CompactPicker(
          currentLocale: current,
          onLocaleSelected: select,
        ),
      LanguagePickerStyle.segmented => _SegmentedPicker(
          currentLocale: current,
          onLocaleSelected: select,
        ),
    };
  }
}

class _CompactPicker extends StatelessWidget {
  const _CompactPicker({
    required this.currentLocale,
    required this.onLocaleSelected,
  });

  final String currentLocale;
  final ValueChanged<String> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = currentLocale == 'ar';

    return Semantics(
      label: l10n.settingsLanguage,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg2.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CompactSegment(
              label: 'EN',
              selected: !isAr,
              onTap: () => onLocaleSelected('en'),
            ),
            _CompactSegment(
              label: 'العربية',
              selected: isAr,
              onTap: () => onLocaleSelected('ar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSegment extends StatefulWidget {
  const _CompactSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CompactSegment> createState() => _CompactSegmentState();
}

class _CompactSegmentState extends State<_CompactSegment> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _focused || _hovered;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.gameButtonSelect)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.focusDuration,
            curve: AppMotion.focusCurve,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.accent.withValues(alpha: 0.22)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: _focused
                    ? AppColors.focusRing
                    : widget.selected
                    ? AppColors.accent.withValues(alpha: 0.55)
                    : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: widget.selected
                  ? const [
                      BoxShadow(
                        color: AppColors.accentGlow,
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selected) ...[
                  const HugeIcon(
                    icon: AppIcons.language,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: widget.label == 'EN' ? 0.6 : 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedPicker extends StatelessWidget {
  const _SegmentedPicker({
    required this.currentLocale,
    required this.onLocaleSelected,
  });

  final String currentLocale;
  final ValueChanged<String> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14), width: 0.8),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: 'English',
              sublabel: 'EN',
              isSelected: currentLocale == 'en',
              onTap: () => onLocaleSelected('en'),
              entry: true,
              autofocus: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentItem(
              label: 'العربية',
              sublabel: 'AR',
              isSelected: currentLocale == 'ar',
              onTap: () => onLocaleSelected('ar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    this.entry = false,
    this.autofocus = false,
  });

  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final bool entry;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      entry: entry,
      autofocus: autofocus,
      onSelect: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onDirection: entry
          ? (direction) {
              if (direction == TraversalDirection.up) {
                return focusUpToShell(context);
              }
              return false;
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2536) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withAlpha(70)
                : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withAlpha(25)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sublabel,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textDisabled,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
