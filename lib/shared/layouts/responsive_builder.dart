import 'package:flutter/material.dart';
import 'package:iptv/shared/layouts/app_breakpoints.dart';

/// Calls [builder] with the current [ScreenSize] whenever the viewport changes.
enum ScreenSize { compact, standard, wide }

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    final ScreenSize size;
    if (AppBreakpoints.isCompact(context)) {
      size = ScreenSize.compact;
    } else if (AppBreakpoints.isWide(context)) {
      size = ScreenSize.wide;
    } else {
      size = ScreenSize.standard;
    }
    return builder(context, size);
  }
}
