import 'package:iptv/core/releases/release_manifest.dart';

abstract class ReleaseRepository {
  Future<ReleaseCheckResult> checkForUpdate();
  Future<DownloadAuthorization> authorizeDownload(String releaseId);
}
