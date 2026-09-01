import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/commercial/commercial_api_config.dart';
import 'package:iptv/core/security/signed_payload_verifier.dart';
import 'package:iptv/domain/entities/app_account.dart';
import 'package:iptv/domain/entities/app_device.dart';
import 'package:iptv/domain/entities/app_entitlement.dart';

void main() {
  test('CommercialApiConfig treats placeholders as unconfigured', () {
    expect(CommercialApiConfig.isConfigured, isFalse);
    expect(CommercialApiConfig.accessGateEnabled, isTrue);
    expect(CommercialApiConfig.productName, 'HOPE TV');
    expect(CommercialApiConfig.subscriptionPortalUri, isNull);
  });

  test('AppAccountStatus parses wire values', () {
    expect(AppAccountStatus.fromWire('active'), AppAccountStatus.active);
    expect(
      AppAccountStatus.fromWire('deletion_pending'),
      AppAccountStatus.deletionPending,
    );
  });

  test('AppDevice.fromJson maps fields', () {
    final device = AppDevice.fromJson({
      'id': 'd1',
      'displayName': 'Windows PC',
      'platform': 'windows',
      'revokedAt': null,
    });
    expect(device.isActive, isTrue);
    expect(device.platform, 'windows');
  });

  test('AccessStatus allows premium for trial and paid', () {
    expect(AccessStatus.trialing.allowsPremium, isTrue);
    expect(AccessStatus.active.allowsPremium, isTrue);
    expect(AccessStatus.denied.allowsPremium, isFalse);
  });

  test('SignedPayloadVerifier rejects unverifiable lease', () async {
    final verifier = SignedPayloadVerifier(hmacSecret: 'test-secret');
    expect(
      () => verifier.verifyLease(
        payloadB64Url: 'e30',
        signatureB64Url: 'AAAA',
        keyId: 'entitlement-dev-1',
        expectedDeviceId: 'device-1',
        nowUtc: DateTime.now().toUtc(),
      ),
      throwsA(isA<LeaseVerificationException>()),
    );
  });
}
