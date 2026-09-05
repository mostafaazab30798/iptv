import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/platform_io.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    File? activeTargetFile;

    try {
      final tempDir = await getTemporaryDirectory();
      final isWindows = PlatformService.instance.isWindows;
      final baseFileName = isWindows
          ? 'HOPE_IPTV_Setup_${manifest.version}_${manifest.buildNumber}.exe'
          : 'HOPE_IPTV_${manifest.version}_${manifest.buildNumber}.apk';
      var targetFile = File('${tempDir.path}/$baseFileName');

      if (await targetFile.exists()) {
        try {
          await targetFile.delete();
        } catch (_) {
          // If locked by another process or Defender, use a timestamped alternative
          targetFile = File(
            '${tempDir.path}/HOPE_IPTV_Setup_${manifest.version}_${manifest.buildNumber}_${DateTime.now().millisecondsSinceEpoch}.exe',
          );
        }
      }
      activeTargetFile = targetFile;

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
        final digest = await sha256.bind(targetFile.openRead()).first;
        final actualDigest = digest.toString().toLowerCase();
        final expectedDigest = manifest.sha256.toLowerCase();

        if (actualDigest != expectedDigest) {
          try {
            await targetFile.delete();
          } catch (_) {}
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
        await _launchWindowsInstaller(targetFile.path);
      } else {
        throw UnsupportedError('In-app installation is not supported on this platform.');
      }
    } catch (e) {
      if (activeTargetFile != null && await activeTargetFile.exists()) {
        try {
          await activeTargetFile.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      if (identical(_activeCancelToken, cancelToken)) {
        _activeCancelToken = null;
      }
    }
  }

  /// Robust multi-layer launcher for Windows installers with UAC elevation support.
  Future<void> _launchWindowsInstaller(String filePath) async {
    AppLogger.info('Executing Windows installer: $filePath', feature: 'updates');

    // Exit fullscreen if active so installer window is clearly visible
    try {
      if (await isPlatformFullScreen()) {
        await setPlatformFullScreen(false);
      }
    } catch (e) {
      AppLogger.warning('Could not exit fullscreen before installer launch: $e', feature: 'updates');
    }

    // Attempt 1: Direct Process.start (detached)
    try {
      await Process.start(
        filePath,
        [],
        mode: ProcessStartMode.detached,
      );
      AppLogger.info('Direct Process.start succeeded.', feature: 'updates');
      return;
    } catch (e) {
      AppLogger.warning(
        'Direct Process.start failed ($e). Attempting shell elevation via cmd.exe...',
        feature: 'updates',
      );
    }

    // Attempt 2: cmd.exe /c start "" "filePath" (ShellExecuteEx handles UAC elevation)
    try {
      final res = await Process.run('cmd.exe', ['/c', 'start', '""', filePath]);
      if (res.exitCode == 0) {
        AppLogger.info('cmd.exe start launcher succeeded.', feature: 'updates');
        return;
      }
      AppLogger.warning('cmd.exe start returned exit code ${res.exitCode}: ${res.stderr}', feature: 'updates');
    } catch (e) {
      AppLogger.warning('cmd.exe start threw exception: $e', feature: 'updates');
    }

    // Attempt 3: PowerShell Start-Process
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Start-Process',
        '-FilePath',
        '"$filePath"',
      ]);
      if (res.exitCode == 0) {
        AppLogger.info('PowerShell Start-Process succeeded.', feature: 'updates');
        return;
      }
    } catch (e) {
      AppLogger.warning('PowerShell Start-Process threw exception: $e', feature: 'updates');
    }

    // Attempt 4: url_launcher externalApplication with file scheme
    try {
      final uri = Uri.file(filePath);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        AppLogger.info('launchUrl file URI succeeded.', feature: 'updates');
        return;
      }
    } catch (e) {
      AppLogger.warning('launchUrl file URI threw exception: $e', feature: 'updates');
    }

    throw Exception('Failed to execute Windows installer at: $filePath');
  }
}
