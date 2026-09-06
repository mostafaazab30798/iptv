part of 'update_dialog.dart';

/// Redesigned optional update dialog with dark media-center aesthetic.
class _OptionalUpdateDialog extends ConsumerStatefulWidget {
  const _OptionalUpdateDialog({required this.manifest});

  final ReleaseManifest manifest;

  @override
  ConsumerState<_OptionalUpdateDialog> createState() =>
      _OptionalUpdateDialogState();
}

class _OptionalUpdateDialogState extends ConsumerState<_OptionalUpdateDialog> {
  final FocusNode _downloadFocusNode = FocusNode();
  final FocusNode _laterFocusNode = FocusNode();

  @override
  void dispose() {
    _downloadFocusNode.dispose();
    _laterFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final notes = releaseNotesForLocale(widget.manifest, locale);
    final updateState = ref.watch(updateProvider);
    final isLaunching = updateState.status == UpdateFlowStatus.launching;
    final isDownloading = updateState.status == UpdateFlowStatus.downloading ||
        updateState.status == UpdateFlowStatus.installing;
    final session = ref.watch(appAccountSessionProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            border: Border.all(color: AppColors.borderFocused, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            child: AdaptiveGlass(
              sigma: 16,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section with icon & title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x3300C2FF),
                                Color(0x1100C2FF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedRocket,
                              color: AppColors.accent,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.updateAvailableTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.updateAvailableBody(
                                  widget.manifest.version,
                                  formatUpdateFileSize(widget.manifest.fileSize),
                                ),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BadgePill(
                          label: 'v${widget.manifest.version}',
                          icon: HugeIcons.strokeRoundedSparkles,
                          isHighlight: true,
                        ),
                        _BadgePill(
                          label: 'Build ${widget.manifest.buildNumber}',
                          icon: HugeIcons.strokeRoundedCpu,
                        ),
                        if (widget.manifest.fileSize != null &&
                            widget.manifest.fileSize! > 0)
                          _BadgePill(
                            label: formatUpdateFileSize(widget.manifest.fileSize),
                            icon: HugeIcons.strokeRoundedDownload01,
                          ),
                        if (widget.manifest.channel.isNotEmpty &&
                            widget.manifest.channel != 'stable')
                          _BadgePill(
                            label: widget.manifest.channel.toUpperCase(),
                            icon: HugeIcons.strokeRoundedFlash,
                          ),
                      ],
                    ),

                    // Release notes section
                    if (notes != null && notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ReleaseNotesCard(notes: notes.trim()),
                    ],

                    if (updateState.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedAlertCircle,
                                  color: AppColors.error,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    updateState.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _launchDownload(
                                  context,
                                  ref,
                                  manifest: widget.manifest,
                                ),
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedGlobe02,
                                  color: AppColors.accent,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Download via Browser',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons or Download progress
                    if (isDownloading)
                      _DownloadProgressWidget(
                        progress: updateState.downloadProgress,
                        statusMessage: updateState.statusMessage ?? 'Downloading update...',
                        receivedBytes: updateState.receivedBytes,
                        totalBytes: updateState.totalBytes,
                        isInstalling: updateState.status == UpdateFlowStatus.installing,
                        onExitApp: () => PlatformService.instance.exitApp(),
                        onMinimize: () => PlatformService.instance.minimizeWindow(),
                        onCancel: () {
                          ref.read(updateProvider.notifier).cancelDownload();
                        },
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              focusNode: _laterFocusNode,
                              label: l10n.updateLater,
                              isPrimary: false,
                              onPressed: () async {
                                await ref
                                    .read(updateProvider.notifier)
                                    .skipOptionalUpdate();
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _ActionButton(
                              focusNode: _downloadFocusNode,
                              autofocus: true,
                              label: l10n.updateDownload,
                              icon: HugeIcons.strokeRoundedDownload01,
                              isPrimary: true,
                              isLoading: isLaunching,
                              onPressed: isLaunching
                                  ? null
                                  : () => ref
                                        .read(updateProvider.notifier)
                                        .startDownloadAndInstall(
                                          isSignedIn: session.isSignedIn,
                                          manifestOverride: widget.manifest,
                                        ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Redesigned mandatory blocking update screen with high-visibility layout.
