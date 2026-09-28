import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';

void main() {
  group('PlayerErrorType.mayBenefitFromSecureConnection', () {
    test('should allow only plausibly route-related failures', () {
      expect(
        PlayerErrorType.networkUnavailable.mayBenefitFromSecureConnection,
        isTrue,
      );
      expect(PlayerErrorType.timeout.mayBenefitFromSecureConnection, isTrue);
      expect(
        PlayerErrorType.serverUnavailable.mayBenefitFromSecureConnection,
        isTrue,
      );
      expect(
        PlayerErrorType.playbackFailure.mayBenefitFromSecureConnection,
        isTrue,
      );
    });

    test('should exclude credential, source, codec, and unknown failures', () {
      expect(
        PlayerErrorType.unauthorized.mayBenefitFromSecureConnection,
        isFalse,
      );
      expect(
        PlayerErrorType.invalidSource.mayBenefitFromSecureConnection,
        isFalse,
      );
      expect(
        PlayerErrorType.unsupportedFormat.mayBenefitFromSecureConnection,
        isFalse,
      );
      expect(
        PlayerErrorType.codecError.mayBenefitFromSecureConnection,
        isFalse,
      );
      expect(PlayerErrorType.unknown.mayBenefitFromSecureConnection, isFalse);
    });
  });
}
