import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/update_service.dart';

abstract class ReleaseRepository {
  Future<ReleaseCheckResult> checkForUpdate();
  Future<DownloadAuthorization> authorizeDownload(String releaseId);
}
