part of 'update_dialog.dart';

class _MandatoryUpdateScreen extends ConsumerStatefulWidget {
  const _MandatoryUpdateScreen({required this.manifest});

  final ReleaseManifest manifest;

  @override
  ConsumerState<_MandatoryUpdateScreen> createState() =>
      _MandatoryUpdateScreenState();
}

class _MandatoryUpdateScreenState
    extends ConsumerState<_MandatoryUpdateScreen> {
  final FocusNode _primaryFocusNode = FocusNode();
  final FocusNode _retryFocusNode = FocusNode();
  final FocusNode _exitFocusNode = FocusNode();

  @override
  void dispose() {
    _primaryFocusNode.dispose();
    _retryFocusNode.dispose();
    _exitFocusNode.dispose();
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

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.bg1,
                    borderRadius: BorderRadius.circular(AppRadius.dialog),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 36,
                        offset: Offset(0, 18),
                      ),
                      BoxShadow(
                        color: Color(0x22F39C12),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Icon & Mandatory Badge
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0x33F39C12),
                                Color(0x11F39C12),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedShield01,
                              color: AppColors.warning,
                              size: 34,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        l10n.updateRequiredTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        l10n.updateRequiredBody(widget.manifest.version),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Badges
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
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
                          ],
                        ),
                      ),

                      // Release Notes
                      if (notes != null && notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _ReleaseNotesCard(
                          notes: notes.trim(),
                          maxHeight: 180,
                        ),
                      ],

                      if (updateState.errorMessage != null) ...[
                        const SizedBox(height: 16),
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
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      updateState.errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 13,
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

                      const SizedBox(height: 28),

                      // Action Buttons or Download progress
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
                        _ActionButton(
                          focusNode: _primaryFocusNode,
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

                      const SizedBox(height: 10),

                      _ActionButton(
                        focusNode: _retryFocusNode,
                        label: l10n.actionRetry,
                        icon: HugeIcons.strokeRoundedRefresh,
                        isPrimary: false,
                        onPressed: () async {
                          await ref
                              .read(updateProvider.notifier)
                              .checkForUpdates(force: true);
                        },
                      ),

                      if (PlatformService.instance.isWindows ||
                          PlatformService.instance.isAndroid) ...[
                        const SizedBox(height: 10),
                        _ActionButton(
                          focusNode: _exitFocusNode,
                          label: l10n.updateExitApp,
                          icon: HugeIcons.strokeRoundedCancel01,
                          isPrimary: false,
                          isDestructive: true,
                          onPressed: SystemNavigator.pop,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Styled Badge Pill for metadata attributes (version, build, size).
