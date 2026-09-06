import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';
import 'package:url_launcher/url_launcher.dart';

part 'update_optional_dialog.dart';
part 'update_mandatory_screen.dart';
part 'update_dialog_widgets.dart';

bool _updateSurfaceVisible = false;

/// Checks if an update is available and presents the corresponding update dialog or screen.
Future<void> showUpdateDialogIfNeeded(
  BuildContext context,
  WidgetRef ref, {
  bool mandatoryOnly = false,
}) async {
  final state = ref.read(updateProvider);
  final manifest = state.manifest;
  if (!state.updateAvailable || manifest == null) return;
  if (mandatoryOnly && !manifest.mandatory) return;
  if (_updateSurfaceVisible) return;
  if (!context.mounted) return;

  if (manifest.mandatory) {
    await _showMandatoryUpdateSurface(context, ref, manifest);
    return;
  }

  _updateSurfaceVisible = true;
  try {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.scrimDark,
      builder: (ctx) => _OptionalUpdateDialog(manifest: manifest),
    );
  } finally {
    _updateSurfaceVisible = false;
  }
}

Future<void> _showMandatoryUpdateSurface(
  BuildContext context,
  WidgetRef ref,
  ReleaseManifest manifest,
) async {
  _updateSurfaceVisible = true;
  try {
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        barrierDismissible: false,
        pageBuilder: (_, _, _) => _MandatoryUpdateScreen(manifest: manifest),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  } finally {
    _updateSurfaceVisible = false;
  }
}


Future<void> _launchDownload(
  BuildContext context,
  WidgetRef ref, {
  ReleaseManifest? manifest,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final session = ref.read(appAccountSessionProvider);
  final updateManifest = manifest ?? ref.read(updateProvider).manifest;
  var url = await ref
      .read(updateProvider.notifier)
      .requestDownloadUrl(
        isSignedIn: session.isSignedIn,
        manifestOverride: updateManifest,
      );

  if ((url == null || url.isEmpty) && updateManifest != null) {
    url = updateManifest.directDownloadUrl;
  }

  if (url == null || url.isEmpty) {
    AppLogger.error('Download URL could not be resolved.', feature: 'updates');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.updateLaunchFailed),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  AppLogger.info('Launching download URL: $url', feature: 'updates');
  final uri = Uri.parse(url);
  var launched = false;

  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    AppLogger.warning('launch externalApplication failed: $e', feature: 'updates');
  }

  if (!launched) {
    try {
      launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      AppLogger.warning('launch platformDefault failed: $e', feature: 'updates');
    }
  }

  // Fallback: If opening direct asset failed, try opening the GitHub release page
  if (!launched && updateManifest != null) {
    final pageUri = Uri.parse(updateManifest.releasePageUrl);
    AppLogger.info('Attempting fallback to release page: $pageUri', feature: 'updates');
    try {
      launched = await launchUrl(pageUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!launched) {
      try {
        launched = await launchUrl(pageUri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  // If still not launched, copy URL to clipboard as reliable fallback
  if (!launched) {
    await Clipboard.setData(ClipboardData(text: url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.updateLaunchFailed} (${l10n.updateLinkCopied})'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l10n.actionCopy,
            textColor: Colors.white,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url!));
            },
          ),
        ),
      );
    }
  }
}

String? releaseNotesForLocale(ReleaseManifest manifest, Locale locale) {
  if (locale.languageCode == 'ar') {
    return manifest.releaseNotesAr ?? manifest.releaseNotesEn;
  }
  return manifest.releaseNotesEn ?? manifest.releaseNotesAr;
}

String formatUpdateFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
