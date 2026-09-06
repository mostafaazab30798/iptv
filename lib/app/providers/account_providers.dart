import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/identity/trusted_time_service.dart';
import 'package:iptv/core/releases/installed_app_info.dart';
import 'package:iptv/core/storage/preferences_storage.dart';
import 'package:iptv/data/repositories/analytics_repository_impl.dart';
import 'package:iptv/data/repositories/app_account_repository_impl.dart';
import 'package:iptv/data/repositories/device_repository_impl.dart';
import 'package:iptv/data/repositories/entitlement_repository_impl.dart';
import 'package:iptv/data/repositories/release_repository_impl.dart';
import 'package:iptv/domain/repositories/analytics_repository.dart';
import 'package:iptv/domain/repositories/app_account_repository.dart';
import 'package:iptv/domain/repositories/device_repository.dart';
import 'package:iptv/domain/repositories/entitlement_repository.dart';
import 'package:iptv/domain/repositories/release_repository.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/features/subscription/entitlement_controller.dart';
import 'package:iptv/features/updates/update_controller.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_initialLocale());

  static Locale _initialLocale() {
    try {
      final code = PreferencesStorage.instance.locale;
      return Locale(code);
    } catch (_) {
      return const Locale('en');
    }
  }

  Future<void> setLocale(String code) async {
    try {
      await PreferencesStorage.instance.setLocale(code);
    } catch (_) {}
    state = Locale(code);
  }

  void refreshFromStorage() {
    state = _initialLocale();
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

final installationIdentityProvider = Provider<InstallationIdentity>((ref) {
  return InstallationIdentity();
});

final appAccountRepositoryProvider = Provider<AppAccountRepository>((ref) {
  final repo = AppAccountRepositoryImpl();
  ref.onDispose(repo.dispose);
  return repo;
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    installationIdentity: ref.watch(installationIdentityProvider),
  );
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl();
});

final appAccountSessionProvider =
    StateNotifierProvider<AppAccountController, AppAccountSessionState>((ref) {
      return AppAccountController(
        accountRepository: ref.watch(appAccountRepositoryProvider),
        deviceRepository: ref.watch(deviceRepositoryProvider),
        analyticsRepository: ref.watch(analyticsRepositoryProvider),
      );
    });

final trustedTimeProvider = Provider<TrustedTimeService>((ref) {
  return TrustedTimeService();
});

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepositoryImpl(trustedTime: ref.watch(trustedTimeProvider));
});

final entitlementProvider =
    StateNotifierProvider<EntitlementController, EntitlementState>((ref) {
      return EntitlementController(
        entitlementRepository: ref.watch(entitlementRepositoryProvider),
        deviceRepository: ref.watch(deviceRepositoryProvider),
        installationIdentity: ref.watch(installationIdentityProvider),
        analyticsRepository: ref.watch(analyticsRepositoryProvider),
      );
    });

final releaseRepositoryProvider = Provider<ReleaseRepository>((ref) {
  return ReleaseRepositoryImpl();
});

final installedAppInfoProvider = Provider<InstalledAppInfo>((ref) {
  return PackageInfoInstalledAppInfo();
});

final appVersionStringProvider = FutureProvider<String>((ref) async {
  final appInfo = ref.watch(installedAppInfoProvider);
  try {
    final version = await appInfo.getVersion();
    final build = await appInfo.getBuildNumber();
    if (version.isNotEmpty) {
      return build != null ? 'v$version ($build)' : 'v$version';
    }
  } catch (_) {}
  return 'v${AppConstants.appVersion} (${AppConstants.appBuildNumber})';
});

final updateProvider = StateNotifierProvider<UpdateController, UpdateState>((
  ref,
) {
  return UpdateController(ref.watch(releaseRepositoryProvider));
});
