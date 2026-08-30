import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/update_service.dart';
import 'package:iptv/domain/repositories/release_repository.dart';

class ReleaseRepositoryImpl implements ReleaseRepository {
  ReleaseRepositoryImpl({UpdateService? updateService})
      : _updates = updateService ?? UpdateService();

  final UpdateService _updates;

  @override
  Future<ReleaseCheckResult> checkForUpdate() => _updates.checkForUpdate();

  @override
  Future<DownloadAuthorization> authorizeDownload(String releaseId) =>
      _updates.authorizeDownload(releaseId);
}
