import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:path_provider/path_provider.dart';

typedef DownloadProgressCallback = void Function(
  double progress,
  int receivedBytes,
  int totalBytes,
);

class AppUpdateInstaller {
  AppUpdateInstaller({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  static const _platformChannel = MethodChannel('com.hopetv.iptvplayer/platform');
  CancelToken? _activeCancelToken;

  void cancelDownload() {
    _activeCancelToken?.cancel('User cancelled download');
    _activeCancelToken = null;
  }

  /// Downloads the release artifact with real-time progress, verifies SHA-256,
  /// and initiates OS installation.
  Future<void> downloadAndInstall({
    required ReleaseManifest manifest,
    required String downloadUrl,
    DownloadProgressCallback? onProgress,
  }) async {
    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    try {
      final tempDir = await getTemporaryDirectory();
      final isWindows = PlatformService.instance.isWindows;
      final fileName = isWindows ? 'HOPE_IPTV_Setup.exe' : 'HOPE_IPTV.apk';
      final targetFile = File('${tempDir.path}/$fileName');

      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {}
      }

      AppLogger.info(
        'Starting in-app update download: $downloadUrl -> ${targetFile.path}',
        feature: 'updates',
      );

      await _dio.download(
        downloadUrl,
        targetFile.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            final progress = (received / total).clamp(0.0, 1.0);
            onProgress(progress, received, total);
          }
        },
      );

      // Verify checksum
      if (manifest.sha256.isNotEmpty && !manifest.sha256.startsWith('PLACEHOLDER')) {
        AppLogger.info('Verifying SHA-256 digest of downloaded update...', feature: 'updates');
        final bytes = await targetFile.readAsBytes();
        final actualDigest = sha256.convert(bytes).toString().toLowerCase();
        final expectedDigest = manifest.sha256.toLowerCase();

        if (actualDigest != expectedDigest) {
          await targetFile.delete();
          throw Exception(
            'Checksum verification failed. Expected $expectedDigest, got $actualDigest',
          );
        }
        AppLogger.info('SHA-256 checksum verified successfully.', feature: 'updates');
      }

      // Trigger installation
      if (PlatformService.instance.isAndroid || PlatformService.instance.isAndroidTv) {
        AppLogger.info('Invoking native Android APK installer: ${targetFile.path}', feature: 'updates');
        await _platformChannel.invokeMethod('installApk', {
          'filePath': targetFile.path,
        });
      } else if (isWindows) {
        AppLogger.info('Executing Windows installer: ${targetFile.path}', feature: 'updates');
        await Process.start(
          targetFile.path,
          [],
          mode: ProcessStartMode.detached,
        );
      } else {
        throw UnsupportedError('In-app installation is not supported on this platform.');
      }
    } finally {
      if (identical(_activeCancelToken, cancelToken)) {
        _activeCancelToken = null;
      }
    }
  }
}
