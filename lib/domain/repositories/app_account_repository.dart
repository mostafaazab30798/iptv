import 'package:iptv/domain/entities/app_account.dart';

abstract class AppAccountRepository {
  /// Whether commercial Supabase is configured for this build.
  bool get isCommercialConfigured;

  Future<void> initialize();

  Stream<AppAccount?> watchAccount();

  Future<AppAccount?> currentAccount();

  Future<void> requestEmailOtp(String email);

  Future<AppAccount> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<void> signOut();

  Future<AppAccount?> refreshProfile();

  /// Request account deletion after user confirms with [accountDeletionConfirmPhrase].
  Future<AccountDeletionRequest> requestDeletion({
    required String confirmation,
    bool acknowledgeSubscriptionLoss = false,
    String? idempotencyKey,
  });

  /// Cancel a pending deletion request while still in the grace period.
  Future<void> cancelDeletion();

  /// Load the latest deletion request status for the signed-in account.
  Future<AccountDeletionStatus?> deletionStatus();
}
