import 'package:dpad/dpad.dart';
import 'package:flutter/widgets.dart';
import 'package:iptv/shared/navigation/shell_focus_bridge.dart';

/// Moves D-pad focus from deep shell content up to the top nav or portrait
/// hero chrome entry, whichever is mounted.
bool focusUpToShell(BuildContext context) {
  final dpad = Dpad.maybeOf(context);

  final navEntry = ShellFocusBridge.navEntryOf(context);
  if (navEntry != null &&
      navEntry.context != null &&
      navEntry.canRequestFocus) {
    if (dpad != null) {
      return dpad.requestFocus(navEntry);
    }
    navEntry.requestFocus();
    return true;
  }

  final heroChromeEntry = ShellFocusBridge.heroChromeEntryOf(context);
  if (heroChromeEntry != null &&
      heroChromeEntry.context != null &&
      heroChromeEntry.canRequestFocus) {
    if (dpad != null) {
      return dpad.requestFocus(heroChromeEntry);
    }
    heroChromeEntry.requestFocus();
    return true;
  }

  return dpad?.moveUp() ?? false;
}
