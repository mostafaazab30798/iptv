import 'package:flutter/widgets.dart';

/// Exposes shell navigation entry focus nodes to deep content (e.g. home hero)
/// so D-pad Up can reach the navbar reliably.
class ShellFocusBridge extends InheritedWidget {
  const ShellFocusBridge({
    super.key,
    required this.navEntry,
    required this.heroChromeEntry,
    required super.child,
  });

  /// Landscape / TV top-nav entry (brand logo in [AppShell]).
  final FocusNode? navEntry;

  /// Portrait Home hero chrome entry (search button in [HomeHeroBanner]).
  final FocusNode? heroChromeEntry;

  static ShellFocusBridge? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ShellFocusBridge>();
  }

  static FocusNode? navEntryOf(BuildContext context) {
    return maybeOf(context)?.navEntry;
  }

  static FocusNode? heroChromeEntryOf(BuildContext context) {
    return maybeOf(context)?.heroChromeEntry;
  }

  @override
  bool updateShouldNotify(ShellFocusBridge oldWidget) {
    return navEntry != oldWidget.navEntry ||
        heroChromeEntry != oldWidget.heroChromeEntry;
  }
}
