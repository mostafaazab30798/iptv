import 'package:flutter/widgets.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

/// Scales phone UI so every handset matches the S24 Ultra reference composition,
/// and scales Android TV UI so every TV box renders at a consistent 10-foot canvas.
///
/// Phone baseline: shortest side = [referenceShortestSide] (411 logical dp —
/// Galaxy S24 Ultra at default display size).
/// TV baseline: shortest side = [tvReferenceShortestSide] (680 logical dp —
/// ≈1209×680 at 16:9). Standard Android TV boxes report 960×540 logical dp
/// (1080p at `tvdpi` 2.0x) or 640×360, which makes unscaled mobile/desktop
/// widgets appear huge on a television screen.
class PhoneDesignScaler extends StatelessWidget {
  const PhoneDesignScaler({
    super.key,
    required this.formFactor,
    required this.child,
  });

  /// Galaxy S24 Ultra portrait width / landscape height at default density.
  static const double referenceShortestSide = 411.0;

  /// Reference 10-foot TV shortest side (≈ 1209×680 at 16:9).
  /// Scales 960×540 Android TV viewports down by ~0.79x so cards, headers,
  /// dialogs, and rows look crisp and proportionate instead of oversized.
  static const double tvReferenceShortestSide = 680.0;

  /// Skip transform when already within ~1% of the reference (perf + crispness).
  static const double _identityEpsilon = 0.01;

  final FormFactor formFactor;
  final Widget child;

  static double? referenceShortestSideFor(FormFactor factor) {
    return switch (factor) {
      FormFactor.phone => referenceShortestSide,
      FormFactor.tv => tvReferenceShortestSide,
      FormFactor.tablet || FormFactor.desktop => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final targetShortestSide = referenceShortestSideFor(formFactor);
    if (targetShortestSide == null) return child;

    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    if (size.shortestSide <= 0) return child;

    final scale = size.shortestSide / targetShortestSide;
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
