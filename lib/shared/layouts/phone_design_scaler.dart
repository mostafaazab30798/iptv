import 'package:flutter/widgets.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

/// Scales phone UI so every handset matches the S24 Ultra reference composition.
///
/// Design baseline: shortest side = [referenceShortestSide] (411 logical dp —
/// Galaxy S24 Ultra at default display size). Smaller phones shrink uniformly;
/// slightly larger phones grow uniformly. Tablet / desktop / TV are unchanged.
///
/// Implementation: present a virtual [MediaQuery] whose shortest side is always
/// 411, then [Transform.scale] to fill the physical viewport. Fixed logical
/// sizes (hero, rows, posters, chrome) keep the same relative layout everywhere.
class PhoneDesignScaler extends StatelessWidget {
  const PhoneDesignScaler({
    super.key,
    required this.formFactor,
    required this.child,
  });

  /// Galaxy S24 Ultra portrait width / landscape height at default density.
  static const double referenceShortestSide = 411.0;

  /// Skip transform when already within ~1% of the reference (perf + crispness).
  static const double _identityEpsilon = 0.01;

  final FormFactor formFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (formFactor != FormFactor.phone) return child;

    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    if (size.shortestSide <= 0) return child;

    final scale = size.shortestSide / referenceShortestSide;
    if ((scale - 1.0).abs() < _identityEpsilon) return child;

    final inverse = 1.0 / scale;
    final logicalSize = Size(size.width * inverse, size.height * inverse);

    return OverflowBox(
      alignment: Alignment.center,
      minWidth: logicalSize.width,
      maxWidth: logicalSize.width,
      minHeight: logicalSize.height,
      maxHeight: logicalSize.height,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              size: logicalSize,
              padding: mediaQuery.padding * inverse,
              viewPadding: mediaQuery.viewPadding * inverse,
              viewInsets: mediaQuery.viewInsets * inverse,
              systemGestureInsets: mediaQuery.systemGestureInsets * inverse,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
