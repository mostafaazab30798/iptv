import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps auth/commercial errors to localized, user-safe messages.
String accountAuthErrorMessage(
  AppLocalizations l10n,
  Object error, {
  required String fallback,
}) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('rate') || msg.contains('too many') || msg.contains('over_email_send_rate_limit')) {
      return l10n.accountOtpRateLimited;
    }
    if (msg.contains('expired') ||
        msg.contains('invalid') ||
        msg.contains('otp') ||
        msg.contains('token')) {
      return l10n.accountOtpVerifyFailed;
    }
    if (msg.contains('network') ||
        msg.contains('fetch') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return l10n.errorNetwork;
    }
    return fallback;
  }

  if (error is CommercialApiException) {
    if (error.code == 'device_limit_reached') {
      return l10n.accountDeviceLimitReached;
    }
    return fallback;
  }

  if (error is StateError) {
    final msg = error.message.toLowerCase();
    if (msg.contains('pending email')) {
      return l10n.accountOtpSessionExpired;
    }
  }

  final raw = error.toString().toLowerCase();
  if (raw.contains('device_limit_reached')) {
    return l10n.accountDeviceLimitReached;
  }
  if (raw.contains('network') || raw.contains('socket') || raw.contains('connection')) {
    return l10n.errorNetwork;
  }

  return fallback;
}

/// Validates a six-digit email OTP token.
bool isValidEmailOtpCode(String value) => RegExp(r'^\d{6}$').hasMatch(value.trim());
