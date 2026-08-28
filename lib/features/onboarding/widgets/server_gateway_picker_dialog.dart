import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/constants/server_presets.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';

/// Modular Server Gateway Picker Dialog capable of scaling smoothly to 10, 20+ servers.
class ServerGatewayPickerDialog extends StatefulWidget {
  final List<ServerPreset> allPresets;
  final ServerPreset selectedPreset;
  final ValueChanged<ServerPreset> onSelected;

  const ServerGatewayPickerDialog({
    super.key,
    required this.allPresets,
    required this.selectedPreset,
    required this.onSelected,
  });

  @override
  State<ServerGatewayPickerDialog> createState() =>
      ServerGatewayPickerDialogState();
}

class ServerGatewayPickerDialogState extends State<ServerGatewayPickerDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'all'; // 'all', 'presets', 'custom'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allPresets.where((preset) {
      final isCustom = preset.id == ServerPresets.customServerId;

      // Category filter
      if (_filterCategory == 'presets' && isCustom) return false;
      if (_filterCategory == 'custom' && !isCustom) return false;

      // Search query filter
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchName = preset.name.toLowerCase().contains(q);
      final matchDesc = (preset.description ?? '').toLowerCase().contains(q);
      final matchUrl = preset.url.toLowerCase().contains(q);
      return matchName || matchDesc || matchUrl;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          child: AdaptiveGlass(
            sigma: 25,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131A).withValues(alpha: 0.96),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
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
                            icon: AppIcons.dns,
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
                              context.l10n.gatewayDialogTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.l10n.gatewayDialogSubtitle(
                                widget.allPresets.length,
                              ),
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

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: context.l10n.gatewaySearchHint,
                      hintStyle: const TextStyle(
                        color: AppColors.textDisabled,
                        fontSize: 12,
                      ),
                      prefixIcon: const HugeIcon(
                        icon: AppIcons.search,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const HugeIcon(
                                icon: AppIcons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.bg1,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
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
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab(
                          'all',
                          context.l10n.gatewayFilterAll(
                            widget.allPresets.length,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          'presets',
                          context.l10n.gatewayFilterOfficial(
                            widget.allPresets
                                .where(
                                  (p) => p.id != ServerPresets.customServerId,
                                )
                                .length,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          'custom',
                          context.l10n.gatewayFilterCustom,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Server List
                  Flexible(
                    child: filtered.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(
                                  icon: AppIcons.searchOff,
                                  size: 36,
                                  color: AppColors.textDisabled,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n.gatewayNoMatches,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final preset = filtered[index];
                              final isSelected =
                                  widget.selectedPreset.id == preset.id;
                              final isCustom =
                                  preset.id == ServerPresets.customServerId;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onSelected(preset);
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accent.withValues(
                                              alpha: 0.12,
                                            )
                                          : AppColors.bg1,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.sm,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.accent
                                            : AppColors.border,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Status / Icon Indicator
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.accent.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : AppColors.bg2,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: HugeIcon(
                                              icon: isCustom
                                                  ? AppIcons.tune
                                                  : AppIcons.dns,
                                              size: 18,
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Server Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      preset.name,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? AppColors
                                                                  .textPrimary
                                                            : AppColors
                                                                  .textPrimary
                                                                  .withValues(
                                                                    alpha: 0.9,
                                                                  ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isCustom
                                                          ? AppColors.warning
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                )
                                                          : AppColors.success
                                                                .withValues(
                                                                  alpha: 0.15,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      isCustom
                                                          ? context
                                                                .l10n
                                                                .onboardingManual
                                                          : context
                                                                .l10n
                                                                .onboardingOnline,
                                                      style: TextStyle(
                                                        color: isCustom
                                                            ? AppColors.warning
                                                            : AppColors.success,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isCustom
                                                    ? context
                                                          .l10n
                                                          .onboardingEnterCustomUrl
                                                    : (preset.description ??
                                                          preset.url),
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (!isCustom &&
                                                  preset.url.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  preset.url,
                                                  style: TextStyle(
                                                    color: AppColors
                                                        .textDisabled
                                                        .withValues(alpha: 0.8),
                                                    fontSize: 10,
                                                    fontFamily: 'monospace',
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Selection Radio Icon
                                        HugeIcon(
                                          icon: isSelected
                                              ? AppIcons.checkCircle
                                              : AppIcons.circle,
                                          color: isSelected
                                              ? AppColors.accent
                                              : AppColors.textDisabled,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String category, String label) {
    final isCurrent = _filterCategory == category;
    return InkWell(
      onTap: () => setState(() => _filterCategory = category),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.bg1,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.accent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
