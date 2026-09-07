import 'package:flutter/material.dart';
import 'package:iptv/shared/layouts/form_factor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormFactorResolver', () {
    test('Android TV wins over phone-like geometry', () {
      expect(
        FormFactorResolver.resolve(
          size: const Size(960, 540),
          isAndroidTv: true,
        ),
        FormFactor.tv,
      );
    });

    test('narrow phone width is phone', () {
      expect(
        FormFactorResolver.resolve(
          size: const Size(400, 800),
          isAndroidTv: false,
        ),
        FormFactor.phone,
      );
    });

    test('compact+ width is tablet', () {
      expect(
        FormFactorResolver.resolve(
          size: const Size(960, 540),
          isAndroidTv: false,
        ),
        FormFactor.tablet,
      );
    });

    test('standard+ width is desktop', () {
      expect(
        FormFactorResolver.resolve(
          size: const Size(1400, 900),
          isAndroidTv: false,
        ),
        FormFactor.desktop,
      );
    });

    test('large shortest side is tablet', () {
      expect(
        FormFactorResolver.resolve(
          size: const Size(600, 900),
          isAndroidTv: false,
        ),
        FormFactor.tablet,
      );
    });
  });

  group('ChromeHeights', () {
    test('overscan is reserved for TV and zero for other form factors', () {
      expect(ChromeHeights.forFactor(FormFactor.tv).overscan, 28);
      expect(ChromeHeights.forFactor(FormFactor.desktop).overscan, 0);
      expect(ChromeHeights.forFactor(FormFactor.phone).overscan, 0);
      expect(ChromeHeights.forFactor(FormFactor.tablet).overscan, 0);
      expect(ChromeHeights.overscanLogicalPx, 28);
    });

    test('phone defaults match current shell chrome', () {
      final phone = ChromeHeights.forFactor(FormFactor.phone);
      expect(phone.header, 70);
      expect(phone.dock, 64);
      expect(phone.heroFraction, 0.38);
    });

    test('tv budgets use compact header and a zoomed-out hero', () {
      final tv = ChromeHeights.forFactor(FormFactor.tv);
      expect(tv.header, 56);
      expect(tv.dock, 0);
      expect(tv.heroFraction, 0.40);
    });
  });
}
