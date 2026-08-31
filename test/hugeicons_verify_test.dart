import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/app/theme/app_icons.dart';

void main() {
  test('verify AppIcons are loaded correctly', () {
    expect(AppIcons.home, isNotEmpty);
    expect(AppIcons.live, isNotEmpty);
    expect(AppIcons.movies, isNotEmpty);
    expect(AppIcons.series, isNotEmpty);
    expect(AppIcons.favorites, isNotEmpty);
    expect(AppIcons.settings, isNotEmpty);
    expect(AppIcons.search, isNotEmpty);
    expect(AppIcons.play, isNotEmpty);
    expect(AppIcons.pause, isNotEmpty);
    expect(AppIcons.deleteSweep, isNotEmpty);
    expect(AppIcons.time, isNotEmpty);
    expect(AppIcons.paste, isNotEmpty);
    expect(AppIcons.chevronDown, isNotEmpty);
  });
}
