part of 'update_dialog.dart';

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
      bgColor = AppColors.accent;
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

class _DownloadProgressWidget extends StatelessWidget {
  const _DownloadProgressWidget({
    required this.progress,
    required this.statusMessage,
    required this.receivedBytes,
    required this.totalBytes,
    required this.onCancel,
    this.isInstalling = false,
    this.onExitApp,
    this.onMinimize,
  });

  final double progress;
  final String statusMessage;
  final int receivedBytes;
  final int totalBytes;
  final VoidCallback onCancel;
  final bool isInstalling;
  final VoidCallback? onExitApp;
  final VoidCallback? onMinimize;

  @override
  Widget build(BuildContext context) {
    if (isInstalling) {
      final isDesktop = PlatformService.instance.isWindows;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Installer Ready',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDesktop) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onMinimize != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMinimize,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedMinusSign,
                          color: AppColors.textPrimary,
                          size: 16,
                        ),
                        label: const Text(
                          'Minimize',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (onExitApp != null)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onExitApp,
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLogout01,
                          color: Colors.black,
                          size: 16,
                        ),
                        label: const Text(
                          'Exit App to Install',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    final percent = (progress * 100).clamp(0, 100).toInt();
    final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
    final bytesText = totalBytes > 0 ? '$recMb MB / $totMb MB' : '';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusMessage,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: AppColors.bg2,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bytesText,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  l10n.actionCancel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

