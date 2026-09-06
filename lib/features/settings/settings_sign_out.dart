part of 'settings_screen.dart';

class _SignOutActionTile extends StatelessWidget {
  const _SignOutActionTile({required this.onSignOutTap});

  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14), width: 0.8),
      ),
      child: TvFocusable(
        onSelect: () {
          HapticFeedback.lightImpact();
          onSignOutTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withAlpha(45),
                    width: 0.8,
                  ),
                ),
                child: const HugeIcon(
                  icon: AppIcons.logout,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.actionSignOut,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.settingsSignOutIptvHint,
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(190),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign Out Confirmation Dialog
// ---------------------------------------------------------------------------

class _SignOutConfirmDialog extends StatelessWidget {
  const _SignOutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: const Color(0xFF11141D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(18), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(140),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withAlpha(20),
                  border: Border.all(
                    color: AppColors.error.withAlpha(50),
                    width: 0.8,
                  ),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: AppIcons.logout,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.settingsConfirmSignOut,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.settingsConfirmSignOutMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withAlpha(200),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TvFocusable(
                      autofocus: true,
                      onSelect: () => Navigator.of(context).pop(false),
                      child: IgnorePointer(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withAlpha(20),
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: Text(
                            context.l10n.actionCancel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TvFocusable(
                      onSelect: () => Navigator.of(context).pop(true),
                      child: IgnorePointer(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: Text(
                            context.l10n.actionSignOut,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
