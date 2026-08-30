import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/app_account.dart';

void main() {
  group('Account deletion entities', () {
    test('confirm phrase matches backend contract', () {
      expect(accountDeletionConfirmPhrase, 'DELETE_MY_ACCOUNT');
    });

    test('AccountDeletionStatus.isPending when account is deletion_pending', () {
      const status = AccountDeletionStatus(
        accountStatus: AppAccountStatus.deletionPending,
      );
      expect(status.isPending, isTrue);
    });

    test('AccountDeletionStatus.isPending when request is pending', () {
      final status = AccountDeletionStatus(
        accountStatus: AppAccountStatus.active,
        request: AccountDeletionRequest(
          id: 'req-1',
          status: AccountDeletionRequestStatus.pending,
          scheduledFor: DateTime.utc(2026, 9, 1),
          hasActiveSubscription: false,
          graceDays: 14,
        ),
      );
      expect(status.isPending, isTrue);
    });

    test('AccountDeletionRequestStatus parses wire values', () {
      expect(
        AccountDeletionRequestStatus.fromWire('completed'),
        AccountDeletionRequestStatus.completed,
      );
      expect(
        AccountDeletionRequestStatus.fromWire('unknown_value'),
        AccountDeletionRequestStatus.unknown,
      );
    });
  });
}
