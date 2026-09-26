import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/domain/enums/player_aspect_ratio_mode.dart';

void main() {
  group('PlayerAspectRatioMode', () {
    test('should preserve the legacy persisted index order', () {
      expect(
        PlayerAspectRatioMode.values.map((mode) => mode.index),
        orderedEquals([0, 1, 2, 3, 4]),
      );
      expect(PlayerAspectRatioMode.bestFit.next, PlayerAspectRatioMode.fit);
      expect(
        PlayerAspectRatioMode.ratio4x3.next,
        PlayerAspectRatioMode.bestFit,
      );
    });

    test('should safely recover an unknown stored value', () {
      expect(
        PlayerAspectRatioMode.fromIndex(99),
        PlayerAspectRatioMode.bestFit,
      );
    });

    test('should use explicit fixed frames without adding letterboxing', () {
      expect(PlayerAspectRatioMode.ratio16x9.forcedAspectRatio, 16 / 9);
      expect(PlayerAspectRatioMode.ratio4x3.forcedAspectRatio, 4 / 3);
      expect(PlayerAspectRatioMode.ratio16x9.surfaceFit, BoxFit.fill);
      expect(PlayerAspectRatioMode.ratio4x3.surfaceFit, BoxFit.fill);
    });

    test('should distinguish contain, safe crop, and full crop policies', () {
      expect(PlayerAspectRatioMode.bestFit.surfaceFit, BoxFit.contain);
      expect(PlayerAspectRatioMode.fit.surfaceFit, BoxFit.contain);
      expect(PlayerAspectRatioMode.fill.surfaceFit, BoxFit.cover);
    });
  });
}
