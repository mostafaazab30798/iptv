import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/shared/layouts/app_breakpoints.dart';

/// Adaptive scaffold that switches between top bar navigation on compact/tablet
/// and a permanent side rail / drawer on wide desktop screens.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.sideRail,
    this.bottomRail,
  });

  final Widget body;
  final PreferredSizeWidget? topBar;
  final Widget? sideRail;
  final Widget? bottomRail;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    if (isWide && sideRail != null) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        body: Row(
          children: [
            sideRail!,
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              child: Column(
                children: [
                  ?topBar,
                  Expanded(child: body),
                  ?bottomRail,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: topBar,
      body: Column(
        children: [
          Expanded(child: body),
          ?bottomRail,
        ],
      ),
    );
  }
}
