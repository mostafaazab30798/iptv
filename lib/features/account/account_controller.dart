import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/domain/entities/app_account.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';
import 'package:iptv/domain/repositories/app_account_repository.dart';
import 'package:iptv/domain/repositories/device_repository.dart';

/// Local-only auth walkthrough for UI development and screenshot testing.
///
/// Release/profile builds can never enable this bypass. Pass
/// `--dart-define=DEBUG_AUTH_PREVIEW=false` when a debug build must exercise
/// the real Supabase/Resend flow.
const bool debugEmailOtpPreviewEnabled =
    kDebugMode &&
    bool.fromEnvironment('DEBUG_AUTH_PREVIEW', defaultValue: true);

class AppAccountSessionState {
  const AppAccountSessionState({
    required this.loading,
    required this.configured,
    this.account,
    this.errorMessage,
    this.pendingEmail,
  });

  final bool loading;
  final bool configured;
  final AppAccount? account;
  final String? errorMessage;
  final String? pendingEmail;

  bool get isSignedIn => account != null;

  AppAccountSessionState copyWith({
    bool? loading,
    bool? configured,
    AppAccount? account,
    String? errorMessage,
    String? pendingEmail,
    bool clearAccount = false,
    bool clearError = false,
    bool clearPendingEmail = false,
  }) {
    return AppAccountSessionState(
      loading: loading ?? this.loading,
      configured: configured ?? this.configured,
      account: clearAccount ? null : (account ?? this.account),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingEmail: clearPendingEmail
          ? null
          : (pendingEmail ?? this.pendingEmail),
    );
  }
}

/// Whether the OTP screen no longer has enough state to verify a code.
///
/// A loading session must remain on the screen because bootstrap may still
/// restore [AppAccountSessionState.pendingEmail] from preferences.
bool shouldLeaveOtpVerification(AppAccountSessionState state) {
  final email = state.pendingEmail;
  return !state.loading &&
      !state.isSignedIn &&
      (email == null || email.isEmpty);
}

class AppAccountController extends StateNotifier<AppAccountSessionState> {
  AppAccountController({
    required AppAccountRepository accountRepository,
    required DeviceRepository deviceRepository,
    required AnalyticsRepository analyticsRepository,
  }) : _accounts = accountRepository,
       _devices = deviceRepository,
       _analytics = analyticsRepository,
       super(
         AppAccountSessionState(
           loading: true,
           configured:
               debugEmailOtpPreviewEnabled ||
               accountRepository.isCommercialConfigured,
         ),
       ) {
    _bootstrap();
  }

  final AppAccountRepository _accounts;
  final DeviceRepository _devices;
  final AnalyticsRepository _analytics;
  StreamSubscription<AppAccount?>? _sub;

  Future<void> _bootstrap() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      if (debugEmailOtpPreviewEnabled) {
        state = state.copyWith(
          loading: false,
          configured: true,
          clearAccount: true,
          pendingEmail: _readPendingOtpEmail(),
        );
        return;
      }

      await _accounts.initialize();

      if (!CommercialApiConfig.isConfigured) {
        state = state.copyWith(
          loading: false,
          configured: false,
          clearAccount: true,
        );
        return;
      }

      final restoredPendingEmail = _readPendingOtpEmail();

      _sub = _accounts.watchAccount().listen((account) {
        state = state.copyWith(
          loading: false,
          configured: true,
          account: account,
          clearAccount: account == null,
          clearError: true,
        );
      });

      final current = await _accounts.currentAccount();
      state = state.copyWith(
        loading: false,
        configured: true,
        account: current,
        clearAccount: current == null,
        pendingEmail: current == null ? restoredPendingEmail : null,
        clearPendingEmail: current != null,
      );

      if (current != null) {
        unawaited(_clearPendingOtpEmail());
        unawaited(_registerDeviceQuietly());
      }
    } catch (e) {
      AppLogger.error('App account bootstrap failed: $e', feature: 'account');
      state = state.copyWith(loading: false, errorMessage: e.toString());
    }
  }

  String? _readPendingOtpEmail() {
    try {
      return PreferencesStorage.instance.pendingOtpEmail;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistPendingOtpEmail(String email) async {
    try {
      await PreferencesStorage.instance.setPendingOtpEmail(email);
    } catch (e) {
      AppLogger.error(
        'Failed to persist pending OTP email: $e',
        feature: 'account',
      );
    }
  }

  Future<void> _clearPendingOtpEmail() async {
    try {
      await PreferencesStorage.instance.clearPendingOtpEmail();
    } catch (_) {}
  }

  Future<void> requestOtp(String email) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final normalized = email.trim().toLowerCase();
      if (debugEmailOtpPreviewEnabled) {
        await _persistPendingOtpEmail(normalized);
        state = state.copyWith(
          loading: false,
          configured: true,
          pendingEmail: normalized,
        );
        return;
      }

      await _accounts.requestEmailOtp(normalized);
      await _persistPendingOtpEmail(normalized);
      state = state.copyWith(loading: false, pendingEmail: normalized);
    } catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> resendOtp() async {
    final email = state.pendingEmail ?? _readPendingOtpEmail();
    if (email == null || email.isEmpty) {
      throw StateError('No pending email for OTP verification.');
    }
    await requestOtp(email);
  }

  Future<void> verifyOtp(String token) async {
    final email = state.pendingEmail ?? _readPendingOtpEmail();
    if (email == null || email.isEmpty) {
      throw StateError('No pending email for OTP verification.');
    }
    state = state.copyWith(
      loading: true,
      clearError: true,
      pendingEmail: email,
    );
    try {
      if (debugEmailOtpPreviewEnabled) {
        if (!RegExp(r'^\d{6}$').hasMatch(token.trim())) {
          throw const FormatException('Debug OTP must contain six digits.');
        }
        final account = AppAccount(
          id: 'debug-auth-preview-user',
          status: AppAccountStatus.active,
          email: email,
          lastLoginAt: DateTime.now().toUtc(),
        );
        await _clearPendingOtpEmail();
        state = state.copyWith(
          loading: false,
          configured: true,
          account: account,
          clearPendingEmail: true,
        );
        return;
      }

      final account = await _accounts.verifyEmailOtp(
        email: email,
        token: token,
      );
      await _clearPendingOtpEmail();
      await _registerDeviceQuietly();
      state = state.copyWith(
        loading: false,
        account: account,
        clearPendingEmail: true,
      );
    } catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!debugEmailOtpPreviewEnabled) {
      await _accounts.signOut();
    }
    await _clearPendingOtpEmail();
    state = state.copyWith(clearAccount: true, clearPendingEmail: true);
  }

  /// Signs in from credentials/session transferred by a companion device.
  Future<void> signInFromCompanion({
    required String email,
    String? refreshToken,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final normalized = email.trim().toLowerCase();
      if (debugEmailOtpPreviewEnabled) {
        final account = AppAccount(
          id: 'companion-transfer-user',
          status: AppAccountStatus.active,
          email: normalized,
          lastLoginAt: DateTime.now().toUtc(),
        );
        await _clearPendingOtpEmail();
        state = state.copyWith(
          loading: false,
          configured: true,
          account: account,
          clearPendingEmail: true,
        );
        return;
      }

      if (refreshToken != null &&
          refreshToken.isNotEmpty &&
          CommercialApiConfig.isConfigured) {
        try {
          final account = await _accounts.setSessionFromToken(
            refreshToken: refreshToken,
            email: normalized,
          );
          if (account != null) {
            await _clearPendingOtpEmail();
            await _registerDeviceQuietly();
            state = state.copyWith(
              loading: false,
              configured: true,
              account: account,
              clearPendingEmail: true,
            );
            return;
          }
        } catch (e) {
          AppLogger.warning(
            'setSessionFromToken failed, falling back to local claim: $e',
            feature: 'account',
          );
        }
      }

      final fallback = AppAccount(
        id: 'companion-transferred-${DateTime.now().millisecondsSinceEpoch}',
        status: AppAccountStatus.active,
        email: normalized,
        lastLoginAt: DateTime.now().toUtc(),
      );
      await _clearPendingOtpEmail();
      state = state.copyWith(
        loading: false,
        configured: true,
        account: fallback,
        clearPendingEmail: true,
      );
    } catch (e) {
      AppLogger.error('Companion sign-in error: $e', feature: 'account');
      state = state.copyWith(loading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Re-runs the server-authoritative account bootstrap after OTP verification.
  ///
  /// This calls `me` again (which provisions the one-time trial), then requires
  /// device registration to succeed. Unlike background bootstrap, errors are
  /// deliberately surfaced so the OTP UI can offer a safe retry.
  Future<void> synchronizeVerifiedAccount() async {
    if (debugEmailOtpPreviewEnabled) return;
    final account = await _accounts.refreshProfile();
    if (account == null) {
      throw StateError('Verified account could not be synchronized.');
    }
    final deviceId = await _devices.registerCurrentDevice();
    _analytics.updateDeviceId(deviceId);
    state = state.copyWith(
      loading: false,
      configured: true,
      account: account,
      clearError: true,
      clearPendingEmail: true,
    );
  }

  Future<void> _registerDeviceQuietly() async {
    try {
      final deviceId = await _devices.registerCurrentDevice();
      // Notify analytics so it can fire the first heartbeat immediately.
      _analytics.updateDeviceId(deviceId);
      unawaited(_analytics.track(AnalyticsEventName.deviceRegistered));
    } catch (e) {
      AppLogger.error('Device registration failed: $e', feature: 'account');
      if (e.toString().contains('device_limit_reached')) {
        state = state.copyWith(
          errorMessage:
              'Device limit reached. Revoke an old device from Account > Devices.',
        );
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
