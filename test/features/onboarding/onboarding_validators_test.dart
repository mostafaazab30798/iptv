import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/onboarding/onboarding_validators.dart';

void main() {
  group('OnboardingValidators', () {
    test('validateServerUrl only required for custom servers', () {
      expect(OnboardingValidators.validateServerUrl('', isCustomServer: false), isNull);
      expect(OnboardingValidators.validateServerUrl('', isCustomServer: true), 'empty');
      expect(
        OnboardingValidators.validateServerUrl('not a url', isCustomServer: true),
        'invalid',
      );
      expect(
        OnboardingValidators.validateServerUrl('https://example.com', isCustomServer: true),
        isNull,
      );
    });

    test('username/password emptiness', () {
      expect(OnboardingValidators.validateUsername('  '), 'empty');
      expect(OnboardingValidators.validateUsername('user'), isNull);
      expect(OnboardingValidators.validatePassword(''), 'empty');
      expect(OnboardingValidators.validatePassword('secret'), isNull);
    });
  });
}
