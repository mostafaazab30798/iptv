import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AccessRequiredScreen extends ConsumerWidget {
  const AccessRequiredScreen({super.key});

  Future<void> _refreshAccess(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(appAccountSessionProvider.notifier)
          .synchronizeVerifiedAccount();
      await ref
          .read(entitlementProvider.notifier)
          .refresh(allowOfflineFallback: false);
      if (!context.mounted) return;
      if (ref.read(entitlementProvider).allowsPremium) {
        final iptv = ref.read(sessionProvider).valueOrNull;
        context.go(iptv != null && iptv.isValid ? Routes.home : Routes.onboarding);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trialActivationFailedBody)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trialActivationFailedBody)),
      );
    }
  }

  Future<void> _changeServer(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionProvider.notifier).clearSession();
    if (context.mounted) context.go(Routes.onboarding);
  }

  Future<void> _openSubscribe(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = CommercialApiConfig.subscriptionPortalUri;
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.subscriptionPortalNotConfigured)),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entitlement = ref.watch(entitlementProvider).entitlement;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(l10n.accessRequiredTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            onPressed: () => context.push(Routes.account),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.accessRequiredHeadline,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.accessRequiredBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (entitlement != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.accessRequiredReason(entitlement.reason),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () => _refreshAccess(context, ref),
                child: Text(l10n.accessRequiredRefresh),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _openSubscribe(context),
                child: Text(l10n.accessRequiredSubscribe),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _changeServer(context, ref),
                child: Text(l10n.accessRequiredChangeServer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
