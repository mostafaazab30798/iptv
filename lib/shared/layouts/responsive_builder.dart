import 'package:flutter/material.dart';
import 'package:iptv/shared/layouts/app_breakpoints.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

/// Calls [builder] with the current [ScreenSize] whenever the viewport changes.
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScreenSize size) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, AppBreakpoints.screenSizeOf(context));
  }
}

/// Calls [builder] with the resolved [FormFactor] whenever the viewport changes.
class FormFactorBuilder extends StatelessWidget {
  const FormFactorBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, FormFactor formFactor) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, FormFactorResolver.of(context));
  }
}
