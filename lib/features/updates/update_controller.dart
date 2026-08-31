import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/core/releases/release_verifier.dart';
import 'package:iptv/core/releases/update_platform.dart';
import 'package:iptv/domain/repositories/release_repository.dart';
import 'package:iptv/features/updates/update_preferences.dart';

enum UpdateFlowStatus {
  idle,
  checking,
  available,
  launching,
  upToDate,
  unsupported,
  notConfigured,
  error,
}

class UpdateState {
  const UpdateState({
    this.status = UpdateFlowStatus.idle,
    this.updateAvailable = false,
    this.releaseId,
    this.manifest,
    this.errorMessage,
    this.errorCode,
    this.downloadUrl,
    this.installedBuildNumber,
    this.pendingDownloadAfterSignIn = false,
  });

  final UpdateFlowStatus status;
  final bool updateAvailable;
  final String? releaseId;
  final ReleaseManifest? manifest;
  final String? errorMessage;
  final String? errorCode;
  final String? downloadUrl;
  final int? installedBuildNumber;
  final bool pendingDownloadAfterSignIn;

  bool get isMandatoryBlocking =>
      updateAvailable && manifest != null && manifest!.mandatory;

  UpdateState copyWith({
    UpdateFlowStatus? status,
    bool? updateAvailable,
    String? releaseId,
    ReleaseManifest? manifest,
    String? errorMessage,
    String? errorCode,
    String? downloadUrl,
    int? installedBuildNumber,
    bool? pendingDownloadAfterSignIn,
    bool clearError = false,
    bool clearDownloadUrl = false,
    bool clearManifest = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      releaseId: releaseId ?? this.releaseId,
      manifest: clearManifest ? null : (manifest ?? this.manifest),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      downloadUrl: clearDownloadUrl ? null : (downloadUrl ?? this.downloadUrl),
      installedBuildNumber: installedBuildNumber ?? this.installedBuildNumber,
      pendingDownloadAfterSignIn:
          pendingDownloadAfterSignIn ?? this.pendingDownloadAfterSignIn,
    );
  }
}

class UpdateController extends StateNotifier<UpdateState> {
  UpdateController(
    this._releases, {
    UpdatePreferences? preferences,
    ReleaseVerifier? verifier,
    bool Function()? isConfigured,
    bool Function()? supportsUpdates,
  }) : _preferences = preferences ?? UpdatePreferences(),
       _verifier = verifier ?? ReleaseVerifier(),
       _isConfigured = isConfigured ?? (() => CommercialApiConfig.isConfigured),
       _supportsUpdates = supportsUpdates ?? supportsNativeUpdates,
       super(const UpdateState());

  final ReleaseRepository _releases;
  final UpdatePreferences _preferences;
  final ReleaseVerifier _verifier;
  final bool Function() _isConfigured;
  final bool Function() _supportsUpdates;
  Future<void>? _checkInFlight;

  static const checkCacheTtl = Duration(hours: 6);

  Future<void> checkForUpdates({
    bool silent = false,
    bool force = false,
  }) {
    final activeCheck = _checkInFlight;
    if (activeCheck != null) return activeCheck;

    final check = _performCheck(silent: silent, force: force);
    _checkInFlight = check;
    return check.whenComplete(() {
      if (identical(_checkInFlight, check)) {
        _checkInFlight = null;
      }
    });
  }

  Future<void> _performCheck({
    required bool silent,
    required bool force,
  }) async {
    if (!_isConfigured()) {
      if (!silent) {
        state = state.copyWith(status: UpdateFlowStatus.notConfigured);
      }
      return;
    }

    if (!_supportsUpdates()) {
      if (!silent) {
        state = state.copyWith(status: UpdateFlowStatus.unsupported);
      }
      return;
    }

    if (!force) {
      final lastCheck = await _preferences.lastCheckAt();
      if (lastCheck != null &&
          DateTime.now().toUtc().difference(lastCheck) < checkCacheTtl &&
          state.status != UpdateFlowStatus.error) {
        return;
      }
    }

    state = state.copyWith(status: UpdateFlowStatus.checking, clearError: true);

    try {
      final result = await _releases.checkForUpdate();
      await _preferences.setLastCheckAt(DateTime.now().toUtc());

      if (result.unsupportedPlatform) {
        state = state.copyWith(status: UpdateFlowStatus.unsupported);
        return;
      }

      if (!result.updateAvailable || result.manifest == null) {
        await _clearMandatoryCacheIfSatisfied(result.installedBuildNumber);
        state = state.copyWith(
          status: UpdateFlowStatus.upToDate,
          updateAvailable: false,
          clearManifest: true,
          installedBuildNumber: result.installedBuildNumber,
        );
        return;
      }

      final manifest = result.manifest!;
      final skipped = await _preferences.skippedBuildNumber();
      if (!manifest.mandatory &&
          skipped != null &&
          skipped >= manifest.buildNumber) {
        state = state.copyWith(
          status: UpdateFlowStatus.upToDate,
          updateAvailable: false,
          clearManifest: true,
          installedBuildNumber: result.installedBuildNumber,
        );
        return;
      }

      if (manifest.mandatory) {
        await _preferences.setCachedMandatoryManifestJson(
          jsonEncode({
            ...manifest.toUnsignedJson(),
            'signature': manifest.signature,
          }),
        );
      }

      state = state.copyWith(
        status: UpdateFlowStatus.available,
        updateAvailable: true,
        releaseId: result.releaseId,
        manifest: manifest,
        installedBuildNumber: result.installedBuildNumber,
      );
    } catch (e) {
      final mandatory = await _loadCachedMandatoryManifest();
      if (mandatory != null &&
          (state.installedBuildNumber ?? 0) < mandatory.buildNumber) {
        state = state.copyWith(
          status: UpdateFlowStatus.available,
          updateAvailable: true,
          manifest: mandatory,
          errorMessage: silent ? null : e.toString(),
        );
        return;
      }

      if (!silent) {
        state = state.copyWith(
          status: UpdateFlowStatus.error,
          errorMessage: e.toString(),
        );
      } else {
        state = state.copyWith(status: UpdateFlowStatus.idle);
      }
    }
  }

  Future<void> skipOptionalUpdate() async {
    final manifest = state.manifest;
    if (manifest == null || manifest.mandatory) return;
    await _preferences.setSkippedBuildNumber(manifest.buildNumber);
    state = state.copyWith(
      status: UpdateFlowStatus.upToDate,
      updateAvailable: false,
      clearManifest: true,
    );
  }

  Future<String?> requestDownloadUrl({required bool isSignedIn}) async {
    if (!isSignedIn) {
      state = state.copyWith(pendingDownloadAfterSignIn: true);
      return null;
    }

    final releaseId = state.releaseId;
    if (releaseId == null || releaseId.isEmpty) return null;

    state = state.copyWith(
      status: UpdateFlowStatus.launching,
      clearError: true,
    );
    try {
      final auth = await _releases.authorizeDownload(releaseId);
      if (!UpdateUrlValidator.isAllowedDownloadUrl(auth.downloadUrl)) {
        throw StateError('Download URL is not from an approved host.');
      }
      state = state.copyWith(
        status: UpdateFlowStatus.available,
        downloadUrl: auth.downloadUrl,
        pendingDownloadAfterSignIn: false,
      );
      return auth.downloadUrl;
    } catch (e) {
      state = state.copyWith(
        status: UpdateFlowStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  void clearPendingDownloadAfterSignIn() {
    state = state.copyWith(pendingDownloadAfterSignIn: false);
  }

  Future<ReleaseManifest?> _loadCachedMandatoryManifest() async {
    final raw = await _preferences.cachedMandatoryManifestJson();
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final manifest = ReleaseManifest.fromJson(json);
      return _verifier.verify(manifest);
    } catch (_) {
      await _preferences.setCachedMandatoryManifestJson(null);
      return null;
    }
  }

  Future<void> _clearMandatoryCacheIfSatisfied(int? installedBuild) async {
    final cached = await _loadCachedMandatoryManifest();
    if (cached == null) return;
    if (installedBuild != null && installedBuild >= cached.buildNumber) {
      await _preferences.setCachedMandatoryManifestJson(null);
    }
  }
}
