import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// Announces [message] to screen readers without depending on a visible
/// widget rebuild — used for validation errors, timeouts, resend
/// confirmations, and the verified state, none of which otherwise trigger
/// an automatic accessibility announcement.
void announceForAccessibility(BuildContext context, String message) {
  if (message.isEmpty) return;
  final view = View.maybeOf(context);
  if (view == null) return;
  unawaited(
    SemanticsService.sendAnnouncement(
      view,
      message,
      Directionality.of(context),
    ),
  );
}
