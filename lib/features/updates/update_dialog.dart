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
    final notes = _releaseNotes(widget.manifest, locale);
    final updateState = ref.watch(updateProvider);
    final isLaunching = updateState.status == UpdateFlowStatus.launching;

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
                                  _formatFileSize(widget.manifest.fileSize),
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
                            label: _formatFileSize(widget.manifest.fileSize),
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
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
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
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
                                : () => _launchDownload(
                                      context,
                                      ref,
                                      manifest: widget.manifest,
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
    final notes = _releaseNotes(widget.manifest, locale);
    final updateState = ref.watch(updateProvider);
    final isLaunching = updateState.status == UpdateFlowStatus.launching;

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
                                label: _formatFileSize(widget.manifest.fileSize),
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
                          child: Row(
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
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Action Buttons
                      _ActionButton(
                        focusNode: _primaryFocusNode,
                        autofocus: true,
                        label: l10n.updateDownload,
                        icon: HugeIcons.strokeRoundedDownload01,
                        isPrimary: true,
                        isLoading: isLaunching,
                        onPressed: isLaunching
                            ? null
                            : () => _launchDownload(
                                  context,
                                  ref,
                                  manifest: widget.manifest,
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
class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.icon,
    this.isHighlight = false,
  });

  final String label;
  final List<List<dynamic>> icon;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final bgColor = isHighlight
        ? AppColors.accent.withValues(alpha: 0.12)
        : AppColors.bg3;
    final borderColor = isHighlight
        ? AppColors.accent.withValues(alpha: 0.4)
        : AppColors.border;
    final textColor =
        isHighlight ? AppColors.accent : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            color: textColor,
            size: 13,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Release notes card container with custom scrollbar and changelog title.
class _ReleaseNotesCard extends StatefulWidget {
  const _ReleaseNotesCard({
    required this.notes,
    this.maxHeight = 150,
  });

  final String notes;
  final double maxHeight;

  @override
  State<_ReleaseNotesCard> createState() => _ReleaseNotesCardState();
}

class _ReleaseNotesCardState extends State<_ReleaseNotesCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFlash,
                  color: AppColors.accentDim,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  "What's New",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(14),
                child: Text(
                  widget.notes,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom TV & keyboard focusable action button with rich glow & hover styling.
class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isLoading = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final List<List<dynamic>>? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _focused || _hovered;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (widget.isPrimary) {
      bgColor = isActive ? AppColors.accent : const Color(0xFF00A8DE);
      borderColor = AppColors.accent;
      textColor = AppColors.textOnAccent;
    } else if (widget.isDestructive) {
      bgColor = isActive
          ? AppColors.error.withValues(alpha: 0.2)
          : AppColors.bg2;
      borderColor = isActive ? AppColors.error : AppColors.border;
      textColor = AppColors.error;
    } else {
      bgColor = isActive ? AppColors.bg3 : AppColors.bg2;
      borderColor = isActive ? AppColors.accentDim : AppColors.border;
      textColor = isActive ? AppColors.textPrimary : AppColors.textSecondary;
    }

    return Focus(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          if (!widget.isLoading) {
            widget.onPressed?.call();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.isLoading ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: AppMotion.focusDuration,
            curve: AppMotion.focusCurve,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: _focused && widget.isPrimary
                  ? const [
                      BoxShadow(
                        color: AppColors.accentGlow,
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (widget.icon != null) ...[
                  HugeIcon(
                    icon: widget.icon!,
                    color: textColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: widget.isPrimary
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          content: Text('${l10n.updateLaunchFailed} (Link copied)'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Copy',
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
