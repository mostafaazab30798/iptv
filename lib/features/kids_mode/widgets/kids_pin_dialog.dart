import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// The operation mode for the PIN dialog.
enum KidsPinDialogMode {
  /// Prompt for current PIN (1 step: verify/toggle).
  enter,

  /// Create new master PIN (2 steps: Set PIN -> Confirm PIN).
  create,

  /// Change existing PIN (3 steps: Current PIN -> New PIN -> Confirm PIN in 1 unified dialog).
  change,
}

/// Result object returned when [KidsPinDialogMode.change] completes.
class KidsChangePinData {
  const KidsChangePinData({
    required this.currentPin,
    required this.newPin,
  });

  final String currentPin;
  final String newPin;
}

/// Helper method to show the stylish PIN dialog for entering or creating a PIN.
Future<String?> showKidsPinDialog({
  required BuildContext context,
  required bool createPin,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'KidsPinDialog',
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => KidsPinDialog(
      mode: createPin ? KidsPinDialogMode.create : KidsPinDialogMode.enter,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Helper method to show the unified Change PIN dialog in 1 single dialog.
Future<KidsChangePinData?> showKidsChangePinDialog({
  required BuildContext context,
}) {
  return showGeneralDialog<KidsChangePinData>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'KidsChangePinDialog',
    barrierColor: Colors.black.withAlpha(180),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => const KidsPinDialog(
      mode: KidsPinDialogMode.change,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// State-of-the-art Frosted Glass 4-Digit PIN Dialog with OTP Digit Cells,
/// Multi-Step Animated Transitions, On-Screen Numeric Keypad, and Shake Feedback.
class KidsPinDialog extends StatefulWidget {
  const KidsPinDialog({
    super.key,
    required this.mode,
  });

  final KidsPinDialogMode mode;

  @override
  State<KidsPinDialog> createState() => _KidsPinDialogState();
}

class _KidsPinDialogState extends State<KidsPinDialog>
    with SingleTickerProviderStateMixin {
  static const int _pinLength = 4;

  // Step indices:
  // For 'enter': step 0 (Enter PIN)
  // For 'create': step 0 (Set PIN), step 1 (Confirm PIN)
  // For 'change': step 0 (Current PIN), step 1 (New PIN), step 2 (Confirm PIN)
  int _currentStep = 0;

  String _enteredCurrentPin = '';
  String _enteredNewPin = '';
  String _currentStepBuffer = '';

  String? _errorMessage;
  late final AnimationController _shakeController;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  int get _totalSteps => switch (widget.mode) {
    KidsPinDialogMode.enter => 1,
    KidsPinDialogMode.create => 2,
    KidsPinDialogMode.change => 3,
  };

  void _onDigitPressed(String digit) {
    if (_currentStepBuffer.length >= _pinLength) return;
    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;
      _currentStepBuffer += digit;
    });

    if (_currentStepBuffer.length == _pinLength) {
      _handleStepComplete();
    }
  }

  void _onBackspacePressed() {
    if (_currentStepBuffer.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errorMessage = null;
      _currentStepBuffer =
          _currentStepBuffer.substring(0, _currentStepBuffer.length - 1);
    });
  }

  void _onClearPressed() {
    if (_currentStepBuffer.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errorMessage = null;
      _currentStepBuffer = '';
    });
  }

  void _triggerShake(String errorText) {
    HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = errorText;
      _currentStepBuffer = '';
    });
    _shakeController.forward(from: 0.0);
  }

  void _handleStepComplete() {
    final pin = _currentStepBuffer;

    switch (widget.mode) {
      case KidsPinDialogMode.enter:
        Navigator.of(context).pop(pin);
        break;

      case KidsPinDialogMode.create:
        if (_currentStep == 0) {
          // Move from Set PIN -> Confirm PIN
          setState(() {
            _enteredNewPin = pin;
            _currentStep = 1;
            _currentStepBuffer = '';
          });
        } else {
          // Check confirmation
          if (pin == _enteredNewPin) {
            Navigator.of(context).pop(pin);
          } else {
            _triggerShake(context.l10n.kidsModePinMismatch);
          }
        }
        break;

      case KidsPinDialogMode.change:
        if (_currentStep == 0) {
          // Current PIN entered -> Move to New PIN
          setState(() {
            _enteredCurrentPin = pin;
            _currentStep = 1;
            _currentStepBuffer = '';
          });
        } else if (_currentStep == 1) {
          // New PIN entered -> Move to Confirm New PIN
          setState(() {
            _enteredNewPin = pin;
            _currentStep = 2;
            _currentStepBuffer = '';
          });
        } else {
          // Confirm PIN checked
          if (pin == _enteredNewPin) {
            Navigator.of(context).pop(
              KidsChangePinData(
                currentPin: _enteredCurrentPin,
                newPin: _enteredNewPin,
              ),
            );
          } else {
            _triggerShake(context.l10n.kidsModePinMismatch);
          }
        }
        break;
    }
  }

  void _onStepBack() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
        _currentStepBuffer = '';
      });
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _onBackspacePressed();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && RegExp(r'^[0-9]$').hasMatch(char)) {
      _onDigitPressed(char);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String _getStepTitle() {
    switch (widget.mode) {
      case KidsPinDialogMode.enter:
        return context.l10n.kidsModeEnterPinTitle;
      case KidsPinDialogMode.create:
        return _currentStep == 0
            ? context.l10n.kidsModeCreatePinTitle
            : context.l10n.kidsModeConfirmPinLabel;
      case KidsPinDialogMode.change:
        if (_currentStep == 0) return context.l10n.kidsModeCurrentPinTitle;
        if (_currentStep == 1) return context.l10n.kidsModeNewPinTitle;
        return context.l10n.kidsModeConfirmNewPinTitle;
    }
  }

  String _getStepSubtitle() {
    switch (widget.mode) {
      case KidsPinDialogMode.enter:
        return context.l10n.kidsModeEnterPinPrompt;
      case KidsPinDialogMode.create:
        return _currentStep == 0
            ? context.l10n.kidsModeCreatePinPrompt
            : context.l10n.kidsModeConfirmPinPrompt;
      case KidsPinDialogMode.change:
        if (_currentStep == 0) return context.l10n.kidsModeCurrentPinPrompt;
        if (_currentStep == 1) return context.l10n.kidsModeCreatePinPrompt;
        return context.l10n.kidsModeConfirmPinPrompt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _getStepTitle();
    final subtitle = _getStepSubtitle();
    final showStepProgress = _totalSteps > 1;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Center(
        child: SingleChildScrollView(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 360,
                  decoration: BoxDecoration(
                    color: const Color(0xF210131B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(150),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Header Controls (Back & Close) ---
                      Row(
                        children: [
                          if (_currentStep > 0)
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: _onStepBack,
                              tooltip: context.l10n.actionBack,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          else
                            const SizedBox(width: 18),
                          const Spacer(),
                          if (showStepProgress)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(22),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withAlpha(60),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                context.l10n.kidsModeStep(
                                  _currentStep + 1,
                                  _totalSteps,
                                ),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: context.l10n.actionClose,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // --- Glowing Shield / Lock Badge ---
                      _GlowingBadge(mode: widget.mode, step: _currentStep),
                      const SizedBox(height: 14),

                      // --- Title & Subtitle ---
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          key: ValueKey('header_$_currentStep'),
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary.withAlpha(210),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- 4-Digit OTP Boxes with Animated Shake ---
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final sine =
                              _shakeController.isAnimating
                                  ? (2 * (1 - _shakeController.value)) *
                                      (0.5 -
                                          (_shakeController.value * 6 % 1).abs())
                                  : 0.0;
                          final offset = sine * 18.0;
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pinLength, (index) {
                              final isFilled =
                                  index < _currentStepBuffer.length;
                              final isCurrent =
                                  index == _currentStepBuffer.length;
                              final hasError = _errorMessage != null;

                              return _PinDigitBox(
                                isFilled: isFilled,
                                isFocused: isCurrent,
                                hasError: hasError,
                              );
                            }),
                          ),
                        ),
                      ),

                      // --- Error Message Banner ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _errorMessage != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withAlpha(28),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.error.withAlpha(120),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        size: 15,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 22),

                      // --- Built-in Numeric Keypad ---
                      _PinNumericKeypad(
                        onDigitPressed: _onDigitPressed,
                        onBackspacePressed: _onBackspacePressed,
                        onClearPressed: _onClearPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glowing Header Icon Badge
class _GlowingBadge extends StatelessWidget {
  const _GlowingBadge({required this.mode, required this.step});

  final KidsPinDialogMode mode;
  final int step;

  @override
  Widget build(BuildContext context) {
    final List<List<dynamic>> iconToken;
    final List<Color> gradientColors;

    if (mode == KidsPinDialogMode.enter) {
      iconToken = AppIcons.lock;
      gradientColors = const [Color(0xFF00C2FF), Color(0xFF0066FF)];
    } else if (mode == KidsPinDialogMode.create) {
      iconToken = step == 0 ? AppIcons.securityCheck : AppIcons.check;
      gradientColors = const [Color(0xFF8A2BE2), Color(0xFF00C2FF)];
    } else {
      iconToken = step == 0
          ? AppIcons.lock
          : (step == 1 ? AppIcons.edit : AppIcons.check);
      gradientColors = const [Color(0xFFFF7A00), Color(0xFF8A2BE2)];
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF191F2C),
        border: Border.all(
          color: gradientColors.first.withAlpha(80),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: HugeIcon(
          icon: iconToken,
          color: gradientColors.first,
          size: 24,
        ),
      ),
    );
  }
}

/// Single OTP / PIN Box Cell
class _PinDigitBox extends StatelessWidget {
  const _PinDigitBox({
    required this.isFilled,
    required this.isFocused,
    required this.hasError,
  });

  final bool isFilled;
  final bool isFocused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;

    if (hasError) {
      borderColor = AppColors.error;
      bgColor = AppColors.error.withAlpha(20);
    } else if (isFocused) {
      borderColor = AppColors.accent;
      bgColor = AppColors.accent.withAlpha(15);
    } else if (isFilled) {
      borderColor = AppColors.accent.withAlpha(120);
      bgColor = const Color(0xFF161B26);
    } else {
      borderColor = Colors.white.withAlpha(16);
      bgColor = const Color(0xFF10131A);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 52,
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isFocused || hasError ? 1.4 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: child,
          ),
          child: isFilled
              ? Container(
                  key: const ValueKey('filled_dot'),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasError ? AppColors.error : AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: (hasError ? AppColors.error : AppColors.accent)
                            .withAlpha(120),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                )
              : (isFocused
                  ? Container(
                      key: const ValueKey('cursor_bar'),
                      width: 16,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(180),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// On-Screen Luxury Glass Numeric Keypad (1-9, 0, Backspace, Clear)
class _PinNumericKeypad extends StatelessWidget {
  const _PinNumericKeypad({
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((k) {
                if (k == 'C') {
                  return _KeypadButton(
                    label: 'C',
                    isSpecial: true,
                    onTap: onClearPressed,
                  );
                } else if (k == '⌫') {
                  return _KeypadButton(
                    icon: Icons.backspace_outlined,
                    isSpecial: true,
                    onTap: onBackspacePressed,
                  );
                } else {
                  return _KeypadButton(
                    label: k,
                    onTap: () => onDigitPressed(k),
                  );
                }
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    this.isSpecial = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool isSpecial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accent.withAlpha(40),
        highlightColor: AppColors.accent.withAlpha(20),
        child: Ink(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: isSpecial
                ? const Color(0x1AFFFFFF)
                : const Color(0x2BFFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withAlpha(20),
              width: 0.8,
            ),
          ),
          child: Center(
            child: icon != null
                ? Icon(
                    icon,
                    size: 20,
                    color: AppColors.textPrimary.withAlpha(220),
                  )
                : Text(
                    label!,
                    style: TextStyle(
                      color: isSpecial
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: isSpecial ? 16 : 21,
                      fontWeight:
                          isSpecial ? FontWeight.w600 : FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
