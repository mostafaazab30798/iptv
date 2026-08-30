import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/identity/installation_identity.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/release_verifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks for signed updates and requests download authorization.
class UpdateService {
  UpdateService({
    CommercialEdgeFunctionsClient? api,
    InstallationIdentity? identity,
    ReleaseVerifier? verifier,
  })  : _api = api ?? CommercialEdgeFunctionsClient(),
        _identity = identity ?? InstallationIdentity(),
        _verifier = verifier ?? ReleaseVerifier();

  final CommercialEdgeFunctionsClient _api;
  final InstallationIdentity _identity;
  final ReleaseVerifier _verifier;

  Future<ReleaseCheckResult> checkForUpdate() async {
    final platform = _identity.platformCode();
    final payload = await _api.invoke(
      'version',
      queryParameters: {
        'platform': platform,
        'buildNumber': '${AppConstants.appBuildNumber}',
        'channel': 'stable',
      },
      requireSession: false,
    );

    final updateAvailable = payload['updateAvailable'] == true;
    final releaseId = payload['releaseId'] as String?;
    final manifestJson = payload['manifest'];
    if (!updateAvailable || manifestJson is! Map) {
      return ReleaseCheckResult(updateAvailable: false, releaseId: releaseId);
    }

    final manifest = await _verifier.verify(
      ReleaseManifest.fromJson(Map<String, dynamic>.from(manifestJson)),
    );
    return ReleaseCheckResult(
      updateAvailable: true,
      releaseId: releaseId,
      manifest: manifest,
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
