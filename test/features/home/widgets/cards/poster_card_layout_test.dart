import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/home/widgets/cards/poster_card_layout.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

void main() {
  group('PosterCardLayout.fit', () {
    test('scales poster height from width by default aspect', () {
      final fitted = PosterCardLayout.fit(maxWidth: 104);
      expect(fitted.width, 104);
      expect(fitted.posterHeight, closeTo(104 * (175 / 120), 0.01));
    });

    test('clamps poster so title strip fits maxHeight', () {
      final fitted = PosterCardLayout.fit(maxWidth: 120, maxHeight: 160);
      expect(fitted.posterHeight, 160 - PosterCardLayout.titleStrip);
      expect(
        fitted.posterHeight + PosterCardLayout.titleStrip,
        lessThanOrEqualTo(160),
      );
    });

    test('falls back when width is non-finite', () {
      final fitted = PosterCardLayout.fit(maxWidth: double.infinity);
      expect(fitted.width, PosterCardLayout.defaultWidth);
    });
  });

  group('PosterCardLayout.posterRowMetrics', () {
    test('TV uses a compact 10-foot poster row', () {
      final m = PosterCardLayout.posterRowMetrics(FormFactor.tv);
      expect(m.itemWidth, 120);
      expect(m.height, 200);
    });

    test('phone keeps legacy 215×120', () {
      final m = PosterCardLayout.posterRowMetrics(FormFactor.phone);
      expect(m.itemWidth, 120);
      expect(m.height, 215);
    });
  });

  testWidgets('grid aspect ratio leaves room for title under poster', (
    tester,
  ) async {
    const cellW = 140.0;
    const cellH = cellW / PosterCardLayout.gridChildAspectRatio;
    final fitted = PosterCardLayout.fit(maxWidth: cellW, maxHeight: cellH);
    expect(
      fitted.posterHeight + PosterCardLayout.titleStrip,
      lessThanOrEqualTo(cellH + 0.5),
    );
  });
}
