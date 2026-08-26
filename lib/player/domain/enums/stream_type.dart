/// Supported IPTV stream delivery formats.
enum StreamType {
  auto,
  hls,
  mpegTs,
  dash,
  rtsp,
  rtp,
  udp,
  file,
  unknown;

  bool get isHls => this == StreamType.hls;
  bool get isMpegTs => this == StreamType.mpegTs;
  bool get isDash => this == StreamType.dash;
  bool get isTransportStream =>
      this == StreamType.mpegTs ||
      this == StreamType.rtsp ||
      this == StreamType.rtp ||
      this == StreamType.udp;
}

