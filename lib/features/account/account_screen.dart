import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/commercial/commercial_edge_functions_client.dart';
import 'package:iptv/domain/entities/app_account.dart';
import 'package:iptv/l10n/app_localizations.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  AccountDeletionStatus? _deletionStatus;
  bool _loadingDeletion = true;
  String? _deletionError;

  @override
  void initState() {
    super.initState();
    _loadDeletionStatus();
  }

  Future<void> _loadDeletionStatus() async {
    setState(() {
      _loadingDeletion = true;
      _deletionError = null;
    });
    try {
      final status = await ref
          .read(appAccountRepositoryProvider)
          .deletionStatus();
      if (mounted) {
        setState(() {
          _deletionStatus = status;
          _loadingDeletion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deletionError = e.toString();
          _loadingDeletion = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final acknowledgeSubscription =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.accountDeleteTitle),
            content: Text(l10n.accountDeleteWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.accountDeleteCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.accountDeleteContinue),
              ),
            ],
          ),
        ) ??
        false;

    if (!acknowledgeSubscription || !mounted) return;

    final controller = TextEditingController();
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.accountDeleteConfirmTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.accountDeleteConfirmBody),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: l10n.accountDeleteConfirmLabel,
                    hintText: accountDeletionConfirmPhrase,
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.accountDeleteCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.accountDeleteAction),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(appAccountRepositoryProvider)
          .requestDeletion(
            confirmation: controller.text.trim(),
            acknowledgeSubscriptionLoss: true,
          );
      await ref.read(entitlementProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountDeleteScheduled)));
        context.go(Routes.signIn);
      }
    } on CommercialApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'active_subscription'
          ? l10n.accountDeleteActiveSubscription
          : e.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountDeleteFailed)));
    }
  }

  Future<void> _cancelDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(appAccountRepositoryProvider).cancelDeletion();
      await _loadDeletionStatus();
      await ref.read(appAccountRepositoryProvider).refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountDeleteCanceled)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountDeleteCancelFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appAccountSessionProvider);
    final account = session.account;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(l10n.accountEmailLabel),
            subtitle: Text(account?.email ?? l10n.accountUnknown),
          ),
          ListTile(
            title: Text(l10n.accountStatusLabel),
            subtitle: Text(account?.status.name ?? l10n.accountUnknown),
          ),
          if (_loadingDeletion)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else if (_deletionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.accountDeleteStatusFailed,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            )
          else if (_deletionStatus?.isPending == true &&
              _deletionStatus?.request != null)
            Card(
              color: AppColors.bg1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountDeletePendingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.accountDeletePendingBody(
                        _deletionStatus!.request!.scheduledFor
                            .toLocal()
                            .toString(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _cancelDeletion,
                      child: Text(l10n.accountDeleteCancelRequest),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(),
          ListTile(
            title: Text(l10n.accountDevicesTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.devices),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () async {
              await ref.read(entitlementProvider.notifier).clear();
              await ref.read(appAccountSessionProvider.notifier).signOut();
              if (context.mounted) context.go(Routes.signIn);
            },
            child: Text(l10n.accountSignOut),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.accountDeleteSectionTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.accountDeleteSectionBody,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_deletionStatus?.isPending != true)
            OutlinedButton(
              onPressed: _confirmDeleteAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: Text(l10n.accountDeleteAction),
            ),
          const SizedBox(height: 12),
          Text(
            l10n.accountIptvSeparateHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
