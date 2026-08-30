import 'dart:async';

import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/commercial/supabase_client_factory.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/domain/entities/app_account.dart';
import 'package:iptv/domain/repositories/app_account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppAccountRepositoryImpl implements AppAccountRepository {
  AppAccountRepositoryImpl({CommercialEdgeFunctionsClient? edgeClient})
    : _edge = edgeClient ?? CommercialEdgeFunctionsClient();

  final CommercialEdgeFunctionsClient _edge;
  final _controller = StreamController<AppAccount?>.broadcast();
  static const _authRequestTimeout = Duration(seconds: 20);
  StreamSubscription<AuthState>? _authSub;
  AppAccount? _cached;

  @override
  bool get isCommercialConfigured => CommercialApiConfig.isConfigured;

  @override
  Future<void> initialize() async {
    final ok = await SupabaseClientFactory.ensureInitialized();
    if (!ok) {
      _cached = null;
      _controller.add(null);
      return;
    }

    _authSub ??= SupabaseClientFactory.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (data.session == null) {
        _cached = null;
        _controller.add(null);
        return;
      }
      try {
        final account = await refreshProfile();
        _controller.add(account);
      } catch (e) {
        AppLogger.error(
          'Profile refresh on auth change failed: $e',
          feature: 'account',
        );
        final fallback = _accountFromSession(data.session!);
        _cached = fallback;
        _controller.add(fallback);
      }
    });

    final session = SupabaseClientFactory.client.auth.currentSession;
    if (session != null) {
      try {
        _cached = await refreshProfile();
      } catch (_) {
        _cached = _accountFromSession(session);
      }
    } else {
      _cached = null;
    }
    _controller.add(_cached);
  }

  @override
  Stream<AppAccount?> watchAccount() => _controller.stream;

  @override
  Future<AppAccount?> currentAccount() async => _cached;

  @override
  Future<void> requestEmailOtp(String email) async {
    _ensureConfigured();
    final normalized = email.trim().toLowerCase();
    await SupabaseClientFactory.client.auth
        .signInWithOtp(email: normalized, shouldCreateUser: true)
        .timeout(
          _authRequestTimeout,
          onTimeout: () => throw TimeoutException(
            'Email OTP request timed out after '
            '${_authRequestTimeout.inSeconds} seconds.',
          ),
        );
    AppLogger.info('App account OTP requested', feature: 'account');
  }

  @override
  Future<AppAccount> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    _ensureConfigured();
    final response = await SupabaseClientFactory.client.auth
        .verifyOTP(
          email: email.trim().toLowerCase(),
          token: token.trim(),
          type: OtpType.email,
        )
        .timeout(
          _authRequestTimeout,
          onTimeout: () => throw TimeoutException(
            'Email OTP verification timed out after '
            '${_authRequestTimeout.inSeconds} seconds.',
          ),
        );
    final session = response.session;
    if (session == null) {
      throw StateError('OTP verification did not return a session.');
    }
    try {
      final account = await refreshProfile();
      return account ?? _accountFromSession(session);
    } catch (_) {
      final account = _accountFromSession(session);
      _cached = account;
      _controller.add(account);
      return account;
    }
  }

  @override
  Future<void> signOut() async {
    if (!SupabaseClientFactory.isInitialized) {
      _cached = null;
      _controller.add(null);
      return;
    }
    await SupabaseClientFactory.client.auth.signOut();
    _cached = null;
    _controller.add(null);
    AppLogger.info('App account signed out', feature: 'account');
  }

  @override
  Future<AppAccount?> refreshProfile() async {
    _ensureConfigured();
    final session = SupabaseClientFactory.client.auth.currentSession;
    if (session == null) {
      _cached = null;
      return null;
    }

    try {
      final payload = await _edge.invoke('me');
      final raw = payload['account'];
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final account = AppAccount(
          id: map['id'] as String,
          status: AppAccountStatus.fromWire(map['status'] as String?),
          email: session.user.email,
          createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
          lastLoginAt: DateTime.tryParse(map['lastLoginAt'] as String? ?? ''),
        );
        _cached = account;
        return account;
      }
    } catch (e) {
      AppLogger.error(
        'me() failed, using session claims: $e',
        feature: 'account',
      );
    }

    final account = _accountFromSession(session);
    _cached = account;
    return account;
  }

  @override
  Future<AccountDeletionRequest> requestDeletion({
    required String confirmation,
    bool acknowledgeSubscriptionLoss = false,
    String? idempotencyKey,
  }) async {
    _ensureConfigured();
    final payload = await _edge.invoke(
      'account-deletion',
      method: HttpMethod.post,
      body: {
        'action': 'request',
        'confirmation': confirmation,
        'acknowledgeSubscriptionLoss': acknowledgeSubscriptionLoss,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
    );

    final raw = payload['deletionRequest'];
    if (raw is! Map) {
      throw StateError('Deletion request response was invalid.');
    }
    final map = Map<String, dynamic>.from(raw);
    final request = AccountDeletionRequest(
      id: map['requestId'] as String,
      status: AccountDeletionRequestStatus.fromWire(map['status'] as String?),
      scheduledFor: DateTime.parse(map['scheduledFor'] as String),
      hasActiveSubscription: map['hasActiveSubscription'] == true,
      graceDays: (map['graceDays'] as num?)?.toInt() ?? 14,
      sessionsRevoked: payload['sessionsRevoked'] == true,
    );

    _cached = null;
    _controller.add(null);
    AppLogger.info('Account deletion requested', feature: 'account');
    return request;
  }

  @override
  Future<void> cancelDeletion() async {
    _ensureConfigured();
    await _edge.invoke(
      'account-deletion',
      method: HttpMethod.post,
      body: {'action': 'cancel'},
    );
    await refreshProfile();
    AppLogger.info('Account deletion canceled', feature: 'account');
  }

  @override
  Future<AccountDeletionStatus?> deletionStatus() async {
    _ensureConfigured();
    if (SupabaseClientFactory.client.auth.currentSession == null) {
      return null;
    }

    final payload = await _edge.invoke(
      'account-deletion',
      method: HttpMethod.post,
      body: {'action': 'status'},
    );

    final accountStatus = AppAccountStatus.fromWire(
      payload['accountStatus'] as String?,
    );
    final raw = payload['deletionRequest'];
    AccountDeletionRequest? request;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      request = AccountDeletionRequest(
        id: map['id'] as String,
        status: AccountDeletionRequestStatus.fromWire(map['status'] as String?),
        scheduledFor:
            DateTime.tryParse(map['scheduledFor'] as String? ?? '') ??
            DateTime.now().toUtc(),
        hasActiveSubscription: map['hasActiveSubscription'] == true,
        graceDays: 14,
      );
    }

    return AccountDeletionStatus(
      accountStatus: accountStatus,
      request: request,
    );
  }

  AppAccount _accountFromSession(Session session) {
    return AppAccount(
      id: session.user.id,
      status: AppAccountStatus.active,
      email: session.user.email,
    );
  }

  void _ensureConfigured() {
    if (!isCommercialConfigured || !SupabaseClientFactory.isInitialized) {
      throw StateError(
        'HOPE TV commercial auth is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _controller.close();
  }
}
