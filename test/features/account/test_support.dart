import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_theme.dart';
import 'package:iptv/core/analytics/analytics_event.dart';
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/app_account.dart';
import 'package:iptv/domain/entities/app_device.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';
import 'package:iptv/domain/repositories/app_account_repository.dart';
import 'package:iptv/domain/repositories/auth_repository.dart';
import 'package:iptv/domain/repositories/device_repository.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory [AppAccountRepository] test double. Every network method is
/// tracked so tests can assert what was actually requested, and every
/// method's error/latency can be configured per test.
class FakeAppAccountRepository implements AppAccountRepository {
  FakeAppAccountRepository({bool configured = true})
    : _configured = configured;

  final bool _configured;
  final _controller = StreamController<AppAccount?>.broadcast();
  AppAccount? _current;

  int requestOtpCalls = 0;
  int verifyOtpCalls = 0;
  String? lastRequestedEmail;
  String? lastVerifiedToken;

  Object? requestOtpError;
  Object? verifyOtpError;
  Duration requestOtpDelay = Duration.zero;
  Duration verifyOtpDelay = Duration.zero;

  @override
  bool get isCommercialConfigured => _configured;

  @override
  Future<void> initialize() async {}

  @override
  Stream<AppAccount?> watchAccount() => _controller.stream;

  @override
  Future<AppAccount?> currentAccount() async => _current;

  @override
  Future<void> requestEmailOtp(String email) async {
    requestOtpCalls++;
    lastRequestedEmail = email;
    if (requestOtpDelay > Duration.zero) {
      await Future<void>.delayed(requestOtpDelay);
    }
    if (requestOtpError != null) throw requestOtpError!;
  }

  @override
  Future<AppAccount> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    verifyOtpCalls++;
    lastVerifiedToken = token;
    if (verifyOtpDelay > Duration.zero) {
      await Future<void>.delayed(verifyOtpDelay);
    }
    if (verifyOtpError != null) throw verifyOtpError!;
    final account = AppAccount(
      id: 'fake-user',
      status: AppAccountStatus.active,
      email: email,
    );
    _current = account;
    _controller.add(account);
    return account;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<AppAccount?> refreshProfile() async => _current;

  @override
  Future<AccountDeletionRequest> requestDeletion({
    required String confirmation,
    bool acknowledgeSubscriptionLoss = false,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<void> cancelDeletion() async {}

  @override
  Future<AccountDeletionStatus?> deletionStatus() async => null;
}

/// [AuthRepository] double whose methods are never expected to be called —
/// [TestSessionNotifier] short-circuits [SessionNotifier.loadSession] before
/// it can reach the repository, so this only exists to satisfy the
/// constructor signature.
class _UnusedAuthRepository implements AuthRepository {
  @override
  Future<Result<ServerConfig>> authenticate({
    required String serverUrl,
    required String username,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<ServerConfig?> loadSavedConfig() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<bool> get isAuthenticated => throw UnimplementedError();
}

/// A [SessionNotifier] that resolves immediately to a fixed [ServerConfig]
/// (or `null`) instead of touching secure storage, so widget tests exercising
/// the post-verification navigation branch stay hermetic and synchronous.
class TestSessionNotifier extends SessionNotifier {
  TestSessionNotifier([ServerConfig? initial])
    : _initial = initial,
      super(_UnusedAuthRepository());

  final ServerConfig? _initial;

  @override
  Future<void> loadSession() async {
    state = AsyncValue.data(_initial);
  }
}

class FakeDeviceRepository implements DeviceRepository {
  @override
  Future<({int deviceLimit, List<AppDevice> devices})> listDevices() async =>
      (deviceLimit: 5, devices: const <AppDevice>[]);

  @override
  Future<String?> currentDeviceId() async => 'fake-device';

  @override
  Future<String> registerCurrentDevice({
    String? displayName,
    String? appVersion,
  }) async => 'fake-device';

  @override
  Future<void> revokeDevice(String deviceId) async {}
}

class FakeAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<void> track(
    AnalyticsEventName name, {
    Map<String, Object?> properties = const {},
  }) async {}

  @override
  Future<void> start({String? deviceId}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> flush() async {}

  @override
  void updateDeviceId(String? deviceId) {}
}

/// Exposes a `emit` seam so tests can drive [AppAccountSessionState]
/// directly, on top of the real [AppAccountController] request/verify/resend
/// logic (so persistence + error propagation still exercise real code).
class TestAccountController extends AppAccountController {
  TestAccountController({
    required super.accountRepository,
    required super.deviceRepository,
    required super.analyticsRepository,
  });

  void emit(AppAccountSessionState newState) {
    state = newState;
  }
}

class AccountTestHarness {
  AccountTestHarness({bool configured = true})
    : accountRepository = FakeAppAccountRepository(configured: configured) {
    controller = TestAccountController(
      accountRepository: accountRepository,
      deviceRepository: FakeDeviceRepository(),
      analyticsRepository: FakeAnalyticsRepository(),
    );
  }

  final FakeAppAccountRepository accountRepository;
  late final TestAccountController controller;

  /// Real bootstrap always resolves to `configured: false` in test binaries
  /// (no SUPABASE_* dart-defines), regardless of the repository. Call this
  /// once bootstrap's microtasks have settled to force the state a given
  /// test actually wants to exercise.
  Future<void> settle(WidgetTester tester, AppAccountSessionState state) async {
    await tester.pump();
    await tester.pump();
    controller.emit(state);
    await tester.pump();
  }

  List<Override> get overrides => [
    appAccountSessionProvider.overrideWith((ref) => controller),
    sessionProvider.overrideWith((ref) => TestSessionNotifier()),
  ];
}

/// Wraps [child] with the same routing shell the app uses for the sign-in
/// journey, so `context.go(Routes.signIn/verifyCode/...)` calls in the
/// screens under test actually navigate within the test's widget tree.
Widget buildAuthTestApp({
  required List<Override> overrides,
  required String initialLocation,
  required Map<String, WidgetBuilder> routes,
  Locale locale = const Locale('en'),
  double textScale = 1.0,
  bool disableAnimations = false,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      for (final entry in routes.entries)
        GoRoute(
          path: entry.key,
          builder: (context, state) => entry.value(context),
        ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      theme: AppTheme.darkTheme(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        );
      },
    ),
  );
}

/// Sets the test surface's logical size for this test (defaults restore
/// automatically at the end of each test via [addTearDown]).
void setSurfaceSize(WidgetTester tester, Size logicalSize) {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> initFakePreferences({String? pendingOtpEmail}) async {
  SharedPreferences.setMockInitialValues({
    'pending_otp_email': ?pendingOtpEmail,
  });
  await PreferencesStorage.initialize();
}
