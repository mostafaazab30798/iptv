/// Playback profile determining buffer, latency, and seeking behaviors.
enum PlaybackProfile {
  live,
  vod,
  catchUp,
  preview;

  bool get isLive => this == PlaybackProfile.live;
  bool get isVod => this == PlaybackProfile.vod;
  bool get isCatchUp => this == PlaybackProfile.catchUp;
  bool get isPreview => this == PlaybackProfile.preview;
}
