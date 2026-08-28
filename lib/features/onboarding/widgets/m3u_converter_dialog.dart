import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/utils/m3u_converter.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';

/// Dedicated dialog to paste and convert any M3U link or playlist content to Xtream.
class M3uConverterDialog extends StatefulWidget {
  final void Function(M3uXtreamCredentials credentials, bool autoConnect)
  onConverted;

  const M3uConverterDialog({super.key, required this.onConverted});

  @override
  State<M3uConverterDialog> createState() => M3uConverterDialogState();
}

class M3uConverterDialogState extends State<M3uConverterDialog> {
  final _inputController = TextEditingController();
  M3uXtreamCredentials? _previewCreds;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    final creds = M3uToXtreamConverter.tryConvert(text);
    setState(() {
      _previewCreds = creds;
      if (text.trim().isNotEmpty && creds == null) {
        _error = context.l10n.m3uExtractError;
      } else {
        _error = null;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _inputController.text = data.text!;
      _onInputChanged(data.text!);
    }
  }

  void _apply(bool autoConnect) {
    if (_previewCreds != null) {
      Navigator.of(context).pop();
      widget.onConverted(_previewCreds!, autoConnect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          child: AdaptiveGlass(
            sigma: 25,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadius.dialog),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, Color(0xFF0072FF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: AppIcons.swap,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.m3uConverterTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                context.l10n.m3uConverterSubtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const HugeIcon(
                            icon: AppIcons.close,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // M3U Link Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.m3uPasteLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: AppIcons.paste,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.actionPaste,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _inputController,
                      maxLines: 3,
                      onChanged: _onInputChanged,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'http://provider.com:8080/get.php?username=...&password=...',
                        hintStyle: const TextStyle(
                          color: AppColors.textDisabled,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: AppColors.bg1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Live Detection Preview Box (with overflow-safe layout)
                    if (_previewCreds != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const HugeIcon(
                                  icon: AppIcons.checkCircle,
                                  color: AppColors.accent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    context.l10n.m3uExtractedSuccess,
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_previewCreds!.detectedType != null)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _previewCreds!.detectedType!,
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            _buildPreviewField(
                              context.l10n.authServerUrl,
                              _previewCreds!.serverUrl,
                            ),
                            const SizedBox(height: 4),
                            _buildPreviewField(
                              context.l10n.authUsername,
                              _previewCreds!.username,
                            ),
                            const SizedBox(height: 4),
                            _buildPreviewField(
                              context.l10n.authPassword,
                              '•••••••• (${_previewCreds!.password.length})',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Info / Advantage
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(
                            icon: AppIcons.info,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.m3uAdvantageHint,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previewCreds == null
                                ? null
                                : () => _apply(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            child: Text(
                              context.l10n.actionApply,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _previewCreds == null
                                ? null
                                : () => _apply(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textOnAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            child: Text(
                              context.l10n.actionConvertAndConnect,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildPreviewField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
