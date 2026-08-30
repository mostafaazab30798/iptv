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
    final info = await _load();
    return info.version;
  }

  @override
  Future<int?> getBuildNumber() async {
    final info = await _load();
    final raw = info.buildNumber.trim();
    if (raw.isEmpty) {
      AppLogger.error('Installed build number is empty.', feature: 'updates');
      return null;
    }
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      AppLogger.error(
        'Invalid installed build number: $raw',
        feature: 'updates',
      );
      return null;
    }
    return parsed;
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
