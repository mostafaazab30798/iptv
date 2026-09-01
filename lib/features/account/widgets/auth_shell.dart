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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= wideBreakpoint;
            if (isWide) {
              return _WideLayout(
                formCard: formCard,
                topTrailing: topTrailing,
              );
            }
            return _CompactLayout(
              formCard: formCard,
              topTrailing: topTrailing,
            );
          },
        ),
      ),
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.formCard,
    this.topTrailing,
  });

  final Widget formCard;
  final Widget? topTrailing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topTrailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5l,
                AppSpacing.md,
                AppSpacing.x5l,
                0,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: topTrailing,
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.x5l,
                    AppSpacing.xl,
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
                    AppSpacing.xl,
                    AppSpacing.x5l,
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
        ],
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.formCard,
    this.topTrailing,
  });

  final Widget formCard;
  final Widget? topTrailing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topTrailing != null ? AppSpacing.md : AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (topTrailing != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: topTrailing,
                ),
              ),
            const AuthBrandPanel(compact: true),
            const SizedBox(height: AppSpacing.xl),
            formCard,
          ],
        ),
      ),
    );
  }
}
