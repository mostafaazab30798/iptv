import 'package:iptv/core/platform/platform_service.dart';

/// GitHub release download URLs allowed for external OS installation.
abstract final class UpdateUrlValidator {
  static const allowedExactHosts = {
    'github.com',
    'objects.githubusercontent.com',
    'release-assets.githubusercontent.com',
  };

  static bool isAllowedDownloadUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();

    final isAllowedHost = allowedExactHosts.contains(host) ||
        host.endsWith('.github.com') ||
        host.endsWith('.githubusercontent.com') ||
        host.endsWith('.s3.amazonaws.com') ||
        host.endsWith('.blob.core.windows.net');

    if (!isAllowedHost) return false;

    if (host == 'github.com') {
      if (uri.pathSegments.length < 4) return false;
      final isReleaseDownload = uri.pathSegments.length >= 5 &&
          uri.pathSegments[2] == 'releases' &&
          uri.pathSegments[3] == 'download';
      final isReleaseTag = uri.pathSegments.length >= 4 &&
          uri.pathSegments[2] == 'releases' &&
          uri.pathSegments[3] == 'tag';
      return isReleaseDownload || isReleaseTag;
    }
    return true;
  }
}

String? nativeArchitectureCode() {
  final platform = PlatformService.instance;
  if (platform.isAndroid || platform.isAndroidTv) return 'arm64-v8a';
  if (platform.isWindows) return 'x64';
  return null;
}

bool supportsNativeUpdates() => nativeArchitectureCode() != null;
