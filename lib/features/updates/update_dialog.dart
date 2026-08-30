import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showUpdateDialogIfNeeded(
  BuildContext context,
  WidgetRef ref, {
  bool mandatoryOnly = false,
}) async {
  final state = ref.read(updateProvider);
  final manifest = state.manifest;
  if (!state.updateAvailable || manifest == null) return;
  if (mandatoryOnly && !manifest.mandatory) return;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: !manifest.mandatory,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bg1,
      title: Text(
        manifest.mandatory ? 'Update required' : 'Update available',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        manifest.releaseNotesEn ??
            'HOPE TV ${manifest.version} is available.',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        if (!manifest.mandatory)
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
        FilledButton(
          onPressed: () async {
            final url = await ref.read(updateProvider.notifier).requestDownloadUrl();
            if (url != null && url.isNotEmpty) {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('Download'),
        ),
      ],
    ),
  );
}
