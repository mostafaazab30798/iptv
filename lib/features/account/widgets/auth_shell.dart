import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/account/widgets/ambient_background.dart';
import 'package:iptv/features/account/widgets/auth_brand_panel.dart';

/// Shared page scaffold for the sign-in and OTP screens.
///
/// Content is pinned to the upper area (not vertically centered) so opening
/// the soft keyboard does not shove the form mid-screen. Narrow layouts
/// scroll when needed; wide layouts keep the brand + card near the top.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.formCard,
    this.topTrailing,
  });

  final Widget formCard;

  /// Optional control pinned to the top trailing corner (language switcher).
  final Widget? topTrailing;

  /// Below this width, phones and narrow desktop windows use the compact
  /// single-column composition instead of the two-region layout.
  static const double wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return AmbientBackground(
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= wideBreakpoint;
                  if (isWide) {
                    return _WideLayout(formCard: formCard);
                  }
                  return _CompactLayout(formCard: formCard);
                },
              ),
            ),
            if (topTrailing != null)
              PositionedDirectional(
                top: AppSpacing.md,
                end: AppSpacing.lg,
                child: topTrailing!,
              ),
          ],
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.formCard});

  final Widget formCard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 6,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.x5l,
                AppSpacing.x3l,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: AuthBrandPanel(),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.x3l,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: formCard,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.formCard});

  final Widget formCard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        // Leave room for the language switcher when present.
        AppSpacing.x3l + AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthBrandPanel(compact: true),
            const SizedBox(height: AppSpacing.xl),
            formCard,
          ],
        ),
      ),
    );
  }
}
