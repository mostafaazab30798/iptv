import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/releases/release_manifest.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

bool _updateSurfaceVisible = false;

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
  await Navigator.of(context, rootNavigator: true).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (_, _, _) => _MandatoryUpdateScreen(manifest: manifest),
    ),
  );
  _updateSurfaceVisible = false;
}

class _OptionalUpdateDialog extends ConsumerWidget {
  const _OptionalUpdateDialog({required this.manifest});

  final ReleaseManifest manifest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final notes = _releaseNotes(manifest, locale);

    return AlertDialog(
      backgroundColor: AppColors.bg1,
      title: Text(
        l10n.updateAvailableTitle,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.updateAvailableBody(
              manifest.version,
              _formatFileSize(manifest.fileSize),
            ),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (notes != null) ...[
            const SizedBox(height: 12),
            Text(notes, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await ref.read(updateProvider.notifier).skipOptionalUpdate();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n.updateLater),
        ),
        FilledButton(
          onPressed: () => _launchDownload(context, ref),
          child: Text(l10n.updateDownload),
        ),
      ],
    );
  }
}

class _MandatoryUpdateScreen extends ConsumerStatefulWidget {
  const _MandatoryUpdateScreen({required this.manifest});

  final ReleaseManifest manifest;

  @override
  ConsumerState<_MandatoryUpdateScreen> createState() =>
      _MandatoryUpdateScreenState();
}

class _MandatoryUpdateScreenState
    extends ConsumerState<_MandatoryUpdateScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final notes = _releaseNotes(widget.manifest, locale);
    final updateState = ref.watch(updateProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.updateRequiredTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.updateRequiredBody(widget.manifest.version),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (notes != null) ...[
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        notes,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ] else
                  const Spacer(),
                if (_error != null || updateState.errorMessage != null) ...[
                  Text(
                    _error ?? updateState.errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: updateState.status == UpdateFlowStatus.launching
                      ? null
                      : () => _launchDownload(context, ref),
                  child: Text(l10n.updateDownload),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref
                        .read(updateProvider.notifier)
                        .checkForUpdates(force: true);
                  },
                  child: Text(l10n.actionRetry),
                ),
                if (PlatformService.instance.isWindows ||
                    PlatformService.instance.isAndroid) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: SystemNavigator.pop,
                    child: Text(l10n.updateExitApp),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _launchDownload(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final session = ref.read(appAccountSessionProvider);
  final url = await ref
      .read(updateProvider.notifier)
      .requestDownloadUrl(isSignedIn: session.isSignedIn);

  if (!session.isSignedIn) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.updateSignInRequired)));
    }
    return;
  }

  if (url == null || url.isEmpty) {
    return;
  }

  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.updateLaunchFailed)));
    }
    return;
  }

  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.updateLaunchFailed)));
  }
}

String? _releaseNotes(ReleaseManifest manifest, Locale locale) {
  if (locale.languageCode == 'ar') {
    return manifest.releaseNotesAr ?? manifest.releaseNotesEn;
  }
  return manifest.releaseNotesEn ?? manifest.releaseNotesAr;
}

String _formatFileSize(int? bytes) {
  if (bytes == null || bytes <= 0) return '—';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
