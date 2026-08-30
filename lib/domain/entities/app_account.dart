import 'package:equatable/equatable.dart';

enum AppAccountStatus {
  active,
  suspended,
  deletionPending,
  deleted,
  unknown;

  static AppAccountStatus fromWire(String? value) {
    switch (value) {
      case 'active':
        return AppAccountStatus.active;
      case 'suspended':
        return AppAccountStatus.suspended;
      case 'deletion_pending':
        return AppAccountStatus.deletionPending;
      case 'deleted':
        return AppAccountStatus.deleted;
      default:
        return AppAccountStatus.unknown;
    }
  }
}

class AppAccount extends Equatable {
  const AppAccount({
    required this.id,
    required this.status,
    this.email,
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final AppAccountStatus status;
  final String? email;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  bool get isUsable =>
      status == AppAccountStatus.active || status == AppAccountStatus.unknown;

  @override
  List<Object?> get props => [id, status, email, createdAt, lastLoginAt];
}

/// Confirmation phrase required by the account-deletion Edge Function.
const accountDeletionConfirmPhrase = 'DELETE_MY_ACCOUNT';

enum AccountDeletionRequestStatus {
  pending,
  processing,
  completed,
  canceled,
  unknown;

  static AccountDeletionRequestStatus fromWire(String? value) {
    switch (value) {
      case 'pending':
        return AccountDeletionRequestStatus.pending;
      case 'processing':
        return AccountDeletionRequestStatus.processing;
      case 'completed':
        return AccountDeletionRequestStatus.completed;
      case 'canceled':
        return AccountDeletionRequestStatus.canceled;
      default:
        return AccountDeletionRequestStatus.unknown;
    }
  }
}

class AccountDeletionRequest extends Equatable {
  const AccountDeletionRequest({
    required this.id,
    required this.status,
    required this.scheduledFor,
    required this.hasActiveSubscription,
    required this.graceDays,
    this.sessionsRevoked = false,
  });

  final String id;
  final AccountDeletionRequestStatus status;
  final DateTime scheduledFor;
  final bool hasActiveSubscription;
  final int graceDays;
  final bool sessionsRevoked;

  @override
  List<Object?> get props => [
        id,
        status,
        scheduledFor,
        hasActiveSubscription,
        graceDays,
        sessionsRevoked,
      ];
}

class AccountDeletionStatus extends Equatable {
  const AccountDeletionStatus({
    required this.accountStatus,
    this.request,
  });

  final AppAccountStatus accountStatus;
  final AccountDeletionRequest? request;

  bool get isPending =>
      accountStatus == AppAccountStatus.deletionPending ||
      request?.status == AccountDeletionRequestStatus.pending;

  @override
  List<Object?> get props => [accountStatus, request];
}
