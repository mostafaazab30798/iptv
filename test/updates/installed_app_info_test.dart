import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/releases/installed_app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('UpdatePlatformTarget', () {
    test('maps Android to arm64-v8a', () {
      final target = UpdatePlatformTarget.forCurrentPlatform(
        isAndroid: true,
        isAndroidTv: false,
        isWindows: false,
        isWeb: false,
      );
      expect(target?.platform, 'android');
      expect(target?.architecture, 'arm64-v8a');
    });

    test('maps Windows to x64', () {
      final target = UpdatePlatformTarget.forCurrentPlatform(
        isAndroid: false,
        isAndroidTv: false,
        isWindows: true,
        isWeb: false,
      );
      expect(target?.platform, 'windows');
      expect(target?.architecture, 'x64');
    });

    test('returns null for web', () {
      final target = UpdatePlatformTarget.forCurrentPlatform(
        isAndroid: false,
        isAndroidTv: false,
        isWindows: false,
        isWeb: true,
      );
      expect(target, isNull);
    });
  });

  group('FakeInstalledAppInfo', () {
    test('parses positive build numbers', () async {
      final info = FakeInstalledAppInfo(version: '1.2.3', buildNumber: 42);
      expect(await info.getBuildNumber(), 42);
      expect(await info.getVersion(), '1.2.3');
    });

    test('rejects invalid build numbers', () async {
      final info = FakeInstalledAppInfo(version: '1.0.0', buildNumber: null);
      expect(await info.getBuildNumber(), isNull);
    });
  });

  group('PackageInfoInstalledAppInfo', () {
    test('falls back to AppConstants on empty buildNumber and version', () async {
      final info = PackageInfoInstalledAppInfo(
        packageInfo: PackageInfo(
          appName: 'HOPE IPTV',
          packageName: 'com.hopetv.iptv',
          version: '',
          buildNumber: '',
          buildSignature: '',
        ),
      );
      expect(await info.getVersion(), AppConstants.appVersion);
      expect(await info.getBuildNumber(), AppConstants.appBuildNumber);
    });

    test('uses real values when packageInfo is valid', () async {
      final info = PackageInfoInstalledAppInfo(
        packageInfo: PackageInfo(
          appName: 'HOPE IPTV',
          packageName: 'com.hopetv.iptv',
          version: '3.0.0',
          buildNumber: '99',
          buildSignature: '',
        ),
      );
      expect(await info.getVersion(), '3.0.0');
      expect(await info.getBuildNumber(), 99);
    });
  });

  group('appVersionStringProvider', () {
    test('formats version with build number', () async {
      final container = ProviderContainer(
        overrides: [
          installedAppInfoProvider.overrideWithValue(
            FakeInstalledAppInfo(version: '1.0.0', buildNumber: 13),
          ),
        ],
      );
      addTearDown(container.dispose);

      final version = await container.read(appVersionStringProvider.future);
      expect(version, 'v1.0.0 (13)');
    });
  });
}
