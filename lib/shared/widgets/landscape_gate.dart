import 'package:flutter/material.dart';

/// Pass-through widget that previously enforced landscape-only view.
/// Now supports both portrait and landscape orientation seamlessly.
class LandscapeGate extends StatelessWidget {
  const LandscapeGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
