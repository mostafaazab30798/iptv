import 'package:flutter/material.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// Extension methods on BuildContext for quick access to theme, media query, and l10n.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
