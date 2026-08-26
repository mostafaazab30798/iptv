import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';
import 'package:iptv/player/utils/stream_type_detector.dart';

void main() {
  group('StreamTypeDetector', () {
    test('detects HLS from .m3u8 extension', () {
      final type = StreamTypeDetector.detect('http://example.com/live/stream.m3u8');
      expect(type, equals(StreamType.hls));
    });

    test('detects HLS from query parameter output=m3u8', () {
      final type = StreamTypeDetector.detect('http://example.com/live?username=u&output=m3u8');
      expect(type, equals(StreamType.hls));
    });

    test('detects MPEG-TS from .ts extension', () {
      final type = StreamTypeDetector.detect('http://example.com/live/stream.ts');
      expect(type, equals(StreamType.mpegTs));
    });

    test('detects MPEG-TS from query parameter output=ts', () {
      final type = StreamTypeDetector.detect('http://example.com/live?output=ts');
      expect(type, equals(StreamType.mpegTs));
    });

    test('detects DASH from .mpd extension', () {
      final type = StreamTypeDetector.detect('http://example.com/manifest.mpd');
      expect(type, equals(StreamType.dash));
    });

    test('detects File from .mp4 or .mkv extensions', () {
      expect(StreamTypeDetector.detect('http://example.com/movie.mp4'), equals(StreamType.file));
      expect(StreamTypeDetector.detect('http://example.com/movie.mkv'), equals(StreamType.file));
    });

    test('prioritizes explicit hint parameter', () {
      final type = StreamTypeDetector.detect('http://example.com/stream/1234', hint: 'm3u8');
      expect(type, equals(StreamType.hls));
    });

    test('detects UDP, RTP, and RTSP direct transport streams', () {
      expect(StreamTypeDetector.detect('udp://239.255.1.1:5000'), equals(StreamType.udp));
      expect(StreamTypeDetector.detect('rtp://239.255.1.2:5000'), equals(StreamType.rtp));
      expect(StreamTypeDetector.detect('rtsp://stream.server.com:554/live/sports'), equals(StreamType.rtsp));
    });

    test('detects UDP, RTP, and RTSP from hint parameter', () {
      expect(StreamTypeDetector.detect('http://example.com/stream/123', hint: 'udp'), equals(StreamType.udp));
      expect(StreamTypeDetector.detect('http://example.com/stream/123', hint: 'rtp'), equals(StreamType.rtp));
      expect(StreamTypeDetector.detect('http://example.com/stream/123', hint: 'rtsp'), equals(StreamType.rtsp));
    });
  });
}
