import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/account/account_auth_errors.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('isValidEmailOtpCode accepts exactly six digits', () {
    expect(isValidEmailOtpCode('123456'), isTrue);
    expect(isValidEmailOtpCode('12345'), isFalse);
    expect(isValidEmailOtpCode('1234567'), isFalse);
    expect(isValidEmailOtpCode('12a456'), isFalse);
  });

  test('accountAuthErrorMessage maps rate limit auth errors', () {
    final message = accountAuthErrorMessage(
      l10n,
      const AuthException('over_email_send_rate_limit'),
      fallback: l10n.accountOtpSendFailed,
    );
    expect(message, l10n.accountOtpRateLimited);
  });

  test('accountAuthErrorMessage maps missing pending email state', () {
    final message = accountAuthErrorMessage(
      l10n,
      StateError('No pending email for OTP verification.'),
      fallback: l10n.accountOtpVerifyFailed,
    );
    expect(message, l10n.accountOtpSessionExpired);
  });
}
