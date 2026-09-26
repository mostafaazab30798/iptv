/// The platform-specific meaning of the player fullscreen control.
enum PlayerFullscreenAction {
  leaveTvPlayer,
  enterLandscape,
  exitLandscape,
  enterDesktopFullscreen,
  exitDesktopFullscreen,
}

PlayerFullscreenAction resolvePlayerFullscreenAction({
  required bool isAndroidTv,
  required bool isAndroid,
  required bool isLandscape,
  required bool isPlatformFullscreen,
}) {
  if (isAndroidTv) return PlayerFullscreenAction.leaveTvPlayer;
  if (isAndroid) {
    return isLandscape
        ? PlayerFullscreenAction.exitLandscape
        : PlayerFullscreenAction.enterLandscape;
  }
  return isPlatformFullscreen
      ? PlayerFullscreenAction.exitDesktopFullscreen
      : PlayerFullscreenAction.enterDesktopFullscreen;
}
