import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/releases/installed_app_info.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/release_verifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks for signed updates and requests download authorization.
class UpdateService {
  UpdateService({
    CommercialEdgeFunctionsClient? api,
    InstallationIdentity? identity,
    ReleaseVerifier? verifier,
    InstalledAppInfo? installedAppInfo,
    UpdatePlatformTarget? platformTargetOverride,
  }) : _api = api ?? CommercialEdgeFunctionsClient(),
       _identity = identity ?? InstallationIdentity(),
       _verifier = verifier ?? ReleaseVerifier(),
       _installedAppInfo = installedAppInfo ?? PackageInfoInstalledAppInfo(),
       _platformTargetOverride = platformTargetOverride;

  final CommercialEdgeFunctionsClient _api;
  final InstallationIdentity _identity;
  final ReleaseVerifier _verifier;
  final InstalledAppInfo _installedAppInfo;
  final UpdatePlatformTarget? _platformTargetOverride;

  UpdatePlatformTarget? _resolvePlatformTarget() {
    if (_platformTargetOverride != null) return _platformTargetOverride;
    final platform = PlatformService.instance;
    return UpdatePlatformTarget.forCurrentPlatform(
      isAndroid: platform.isAndroid,
      isAndroidTv: platform.isAndroidTv,
      isWindows: platform.isWindows,
      isWeb: platform.isWeb,
    );
  }

  Future<ReleaseCheckResult> checkForUpdate({String channel = 'stable'}) async {
    final target = _resolvePlatformTarget();
    if (target == null) {
      return const ReleaseCheckResult(
        updateAvailable: false,
        unsupportedPlatform: true,
      );
    }

    final buildNumber = await _installedAppInfo.getBuildNumber();
    if (buildNumber == null) {
      throw UpdateCheckException(
        'invalid_build_number',
        'Installed build number is missing or invalid.',
      );
    }

    final platform = _identity.platformCode();
    if (platform != target.platform) {
      AppLogger.error(
        'Platform code mismatch: $platform vs ${target.platform}',
        feature: 'updates',
      );
    }

    final payload = await _api.invoke(
      'version',
      queryParameters: {
        'platform': target.platform,
        'architecture': target.architecture,
        'buildNumber': '$buildNumber',
        'channel': channel,
      },
      requireSession: false,
    );

    final updateAvailable = payload['updateAvailable'] == true;
    final releaseId = payload['releaseId'] as String?;
    final manifestJson = payload['manifest'];
    if (!updateAvailable || manifestJson is! Map) {
      return ReleaseCheckResult(
        updateAvailable: false,
        releaseId: releaseId,
        installedBuildNumber: buildNumber,
      );
    }

    final manifest = await _verifier.verify(
      ReleaseManifest.fromJson(Map<String, dynamic>.from(manifestJson)),
    );
    return ReleaseCheckResult(
      updateAvailable: true,
      releaseId: releaseId,
      manifest: manifest,
      installedBuildNumber: buildNumber,
    );
  }

  Future<DownloadAuthorization> authorizeDownload(String releaseId) async {
    final payload = await _api.invoke(
      'downloads',
      method: HttpMethod.post,
      body: {'releaseId': releaseId},
    );
    return DownloadAuthorization.fromJson(payload);
  }
}

class UpdateCheckException implements Exception {
  UpdateCheckException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'UpdateCheckException($code): $message';
}
