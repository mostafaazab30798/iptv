import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/account/account_auth_errors.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';
import 'package:iptv/domain/repositories/app_account_repository.dart';
import 'package:iptv/domain/repositories/device_repository.dart';
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

  test('accountAuthErrorMessage maps OTP timeouts to network error', () {
    final message = accountAuthErrorMessage(
      l10n,
      TimeoutException('Email OTP request timed out.'),
      fallback: l10n.accountOtpSendFailed,
    );
    expect(message, l10n.errorNetwork);
  });

  test('OTP verification waits for pending email restoration', () {
    expect(
      shouldLeaveOtpVerification(
        const AppAccountSessionState(loading: true, configured: true),
      ),
      isFalse,
    );
    expect(
      shouldLeaveOtpVerification(
        const AppAccountSessionState(
          loading: false,
          configured: true,
          pendingEmail: 'viewer@example.com',
        ),
      ),
      isFalse,
    );
    expect(
      shouldLeaveOtpVerification(
        const AppAccountSessionState(loading: false, configured: true),
      ),
      isTrue,
    );
  });

  test('debug OTP preview never calls the real backend', () async {
    expect(debugEmailOtpPreviewEnabled, isTrue);
    final controller = AppAccountController(
      accountRepository: _NoBackendAccountRepository(),
      deviceRepository: _NoBackendDeviceRepository(),
      analyticsRepository: _NoBackendAnalyticsRepository(),
    );
    addTearDown(controller.dispose);

    expect(controller.state.configured, isTrue);
    expect(controller.state.loading, isFalse);

    await controller.requestOtp('Viewer@Example.com');
    expect(controller.state.pendingEmail, 'viewer@example.com');
    expect(controller.state.isSignedIn, isFalse);

    await controller.verifyOtp('123456');
    expect(controller.state.isSignedIn, isTrue);
    expect(controller.state.account?.id, 'debug-auth-preview-user');
    expect(controller.state.account?.email, 'viewer@example.com');
  });
}

class _NoBackendAccountRepository implements AppAccountRepository {
  @override
  bool get isCommercialConfigured => false;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Debug preview attempted to call the account backend.');
  }
}

class _NoBackendDeviceRepository implements DeviceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Debug preview attempted to call the device backend.');
  }
}

class _NoBackendAnalyticsRepository implements AnalyticsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Debug preview attempted to call analytics.');
  }
}
