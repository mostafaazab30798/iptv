import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Runtime installed package metadata used for update comparisons.
abstract class InstalledAppInfo {
  Future<String> getVersion();
  Future<int?> getBuildNumber();
}

class PackageInfoInstalledAppInfo implements InstalledAppInfo {
  PackageInfoInstalledAppInfo({PackageInfo? packageInfo})
    : _packageInfo = packageInfo;

  PackageInfo? _packageInfo;

  Future<PackageInfo> _load() async {
    return _packageInfo ??= await PackageInfo.fromPlatform();
  }

  @override
  Future<String> getVersion() async {
    try {
      final info = await _load();
      if (info.version.trim().isNotEmpty) {
        return info.version.trim();
      }
    } catch (e) {
      AppLogger.warning('Failed reading package version: $e', feature: 'updates');
    }
    return AppConstants.appVersion;
  }

  @override
  Future<int?> getBuildNumber() async {
    try {
      final info = await _load();
      final raw = info.buildNumber.trim();
      if (raw.isNotEmpty) {
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
    } catch (e) {
      AppLogger.warning('Failed reading package build number: $e', feature: 'updates');
    }
    return AppConstants.appBuildNumber;
  }
}

/// Test double for update logic without platform channels.
class FakeInstalledAppInfo implements InstalledAppInfo {
  FakeInstalledAppInfo({required this.version, required this.buildNumber});

  final String version;
  final int? buildNumber;

  @override
  Future<String> getVersion() async => version;

  @override
  Future<int?> getBuildNumber() async => buildNumber;
}

/// Maps the running platform to update catalog query parameters.
class UpdatePlatformTarget {
  const UpdatePlatformTarget({
    required this.platform,
    required this.architecture,
  });

  final String platform;
  final String architecture;

  static UpdatePlatformTarget? forCurrentPlatform({
    required bool isAndroid,
    required bool isAndroidTv,
    required bool isWindows,
    required bool isWeb,
  }) {
    if (isAndroid || isAndroidTv) {
      return const UpdatePlatformTarget(
        platform: 'android',
        architecture: 'arm64-v8a',
      );
    }
    if (isWindows) {
      return const UpdatePlatformTarget(
        platform: 'windows',
        architecture: 'x64',
      );
    }
    if (isWeb) return null;
    return null;
  }
}
