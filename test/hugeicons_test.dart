import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  test('hugeicons availability', () {
    expect(HugeIcons.strokeRoundedHome01, isNotNull);
    expect(HugeIcons.strokeRoundedTv01, isNotNull);
    expect(HugeIcons.strokeRoundedFilm01, isNotNull);
    expect(HugeIcons.strokeRoundedPlay, isNotNull);
    expect(HugeIcons.strokeRoundedFavourite, isNotNull);
    expect(HugeIcons.strokeRoundedSettings02, isNotNull);
    expect(HugeIcons.strokeRoundedSearch01, isNotNull);
  });
}
