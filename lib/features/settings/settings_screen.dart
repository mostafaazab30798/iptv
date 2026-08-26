import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/features/auth/auth_controller.dart';

import 'package:iptv/shared/extensions/context_extensions.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Text(
          context.l10n.settingsConfirmSignOut,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.l10n.settingsConfirmSignOutMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.actionSignOut),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(Routes.onboarding);
      }
    }
  }

  void _setLocale(WidgetRef ref, String code) {
    ref.read(localeProvider.notifier).setLocale(code);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final currentLocale = ref.watch(localeProvider).languageCode;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            if (session != null) ...[
              _SettingsSection(
                title: context.l10n.settingsConnectedServer,
                children: [
                  ListTile(
                    tileColor: AppColors.bg1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    leading: const HugeIcon(icon: AppIcons.dns, color: AppColors.accent, size: 22),
                    title: Text(session.serverUrl, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    subtitle: Text('${context.l10n.settingsUser}: ${session.username}', style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            _SettingsSection(
              title: context.l10n.settingsLanguage,
              children: [
                _LanguageOption(
                  label: 'English',
                  code: 'en',
                  selected: currentLocale == 'en',
                  onTap: () => _setLocale(ref, 'en'),
                ),
                const SizedBox(height: 6),
                _LanguageOption(
                  label: 'العربية',
                  code: 'ar',
                  selected: currentLocale == 'ar',
                  onTap: () => _setLocale(ref, 'ar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SettingsSection(
              title: context.l10n.settingsAccount,
              children: [
                ListTile(
                  tileColor: AppColors.bg1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  leading: const HugeIcon(icon: AppIcons.logout, color: AppColors.error, size: 22),
                  title: Text(context.l10n.actionSignOut, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SettingsSection(
              title: context.l10n.settingsAbout,
              children: [
                ListTile(
                  tileColor: AppColors.bg1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      AppConstants.appLogo,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(context.l10n.settingsVersion, style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: const Text('0.1.0', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: AppColors.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      trailing: selected
          ? const HugeIcon(icon: AppIcons.checkCircle, color: AppColors.accent, size: 20)
          : const HugeIcon(icon: AppIcons.circle, color: AppColors.textDisabled, size: 20),
      onTap: onTap,
    );
  }
}
