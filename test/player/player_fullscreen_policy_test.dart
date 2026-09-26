import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/features/player/player_fullscreen_policy.dart';

void main() {
  group('resolvePlayerFullscreenAction', () {
    test('leaves the player route on Android TV', () {
      expect(
        resolvePlayerFullscreenAction(
          isAndroidTv: true,
          isAndroid: true,
          isLandscape: true,
          isPlatformFullscreen: true,
        ),
        PlayerFullscreenAction.leaveTvPlayer,
      );
    });

    test('toggles phone orientation', () {
      expect(
        resolvePlayerFullscreenAction(
          isAndroidTv: false,
          isAndroid: true,
          isLandscape: false,
          isPlatformFullscreen: false,
        ),
        PlayerFullscreenAction.enterLandscape,
      );
      expect(
        resolvePlayerFullscreenAction(
          isAndroidTv: false,
          isAndroid: true,
          isLandscape: true,
          isPlatformFullscreen: true,
        ),
        PlayerFullscreenAction.exitLandscape,
      );
    });

    test('uses the real desktop window state', () {
      expect(
        resolvePlayerFullscreenAction(
          isAndroidTv: false,
          isAndroid: false,
          isLandscape: true,
          isPlatformFullscreen: false,
        ),
        PlayerFullscreenAction.enterDesktopFullscreen,
      );
      expect(
        resolvePlayerFullscreenAction(
          isAndroidTv: false,
          isAndroid: false,
          isLandscape: true,
          isPlatformFullscreen: true,
        ),
        PlayerFullscreenAction.exitDesktopFullscreen,
      );
    });
  });
}
