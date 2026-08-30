import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/domain/repositories/release_repository.dart';

class UpdateState {
  const UpdateState({
    this.checking = false,
    this.updateAvailable = false,
    this.releaseId,
    this.manifest,
    this.errorMessage,
    this.downloadUrl,
  });

  final bool checking;
  final bool updateAvailable;
  final String? releaseId;
  final ReleaseManifest? manifest;
  final String? errorMessage;
  final String? downloadUrl;

  UpdateState copyWith({
    bool? checking,
    bool? updateAvailable,
    String? releaseId,
    ReleaseManifest? manifest,
    String? errorMessage,
    String? downloadUrl,
    bool clearError = false,
    bool clearDownloadUrl = false,
  }) {
    return UpdateState(
      checking: checking ?? this.checking,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      releaseId: releaseId ?? this.releaseId,
      manifest: manifest ?? this.manifest,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      downloadUrl: clearDownloadUrl ? null : (downloadUrl ?? this.downloadUrl),
    );
  }
}

class UpdateController extends StateNotifier<UpdateState> {
  UpdateController(this._releases) : super(const UpdateState());

  final ReleaseRepository _releases;

  Future<void> checkForUpdates({bool silent = false}) async {
    if (!CommercialApiConfig.isConfigured) return;
    state = state.copyWith(checking: true, clearError: true);
    try {
      final result = await _releases.checkForUpdate();
      state = state.copyWith(
        checking: false,
        updateAvailable: result.updateAvailable,
        releaseId: result.releaseId,
        manifest: result.manifest,
      );
    } catch (e) {
      if (!silent) {
        state = state.copyWith(checking: false, errorMessage: e.toString());
      } else {
        state = state.copyWith(checking: false);
      }
    }
  }

  Future<String?> requestDownloadUrl() async {
    final releaseId = state.releaseId;
    if (releaseId == null || releaseId.isEmpty) return null;
    state = state.copyWith(checking: true, clearError: true);
    try {
      final auth = await _releases.authorizeDownload(releaseId);
      state = state.copyWith(
        checking: false,
        downloadUrl: auth.downloadUrl,
      );
      return auth.downloadUrl;
    } catch (e) {
      state = state.copyWith(checking: false, errorMessage: e.toString());
      return null;
    }
  }
}
