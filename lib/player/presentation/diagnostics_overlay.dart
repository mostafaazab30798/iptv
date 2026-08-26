import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/application/player_state.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';

/// Development HUD diagnostics panel displaying live telemetry and playback metrics.
class DiagnosticsOverlay extends StatelessWidget {
  const DiagnosticsOverlay({
    super.key,
    required this.playerState,
    required this.onClose,
  });

  final PlayerState playerState;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    final m = playerState.metrics;
    final source = playerState.source;

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: 380,
        margin: const EdgeInsets.only(top: 60, right: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    HugeIcon(icon: AppIcons.speed, color: Colors.yellowAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Diagnostics HUD',
                      style: TextStyle(
                        color: Colors.yellowAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const HugeIcon(icon: AppIcons.close, color: Colors.white70, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClose,
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 16),
            _diagRow('Status', playerState.status.name),
            _diagRow('Stream Format', source?.streamType.name ?? 'unknown'),
            _diagRow('Buffer Mode', playerState.bufferMode.displayName, valueColor: Colors.lightGreenAccent),
            _diagRow(
              'Hardware Decode (hwdec)',
              m.hwdecCurrent != null
                  ? (m.isHardwareDecodingActive
                      ? '${m.hwdecCurrent} (Active GPU)'
                      : '${m.hwdecCurrent} (CPU Fallback / Software)')
                  : 'auto-safe (probing...)',
              valueColor: m.isHardwareDecodingActive
                  ? Colors.greenAccent
                  : (m.hwdecCurrent == 'no' || m.hwdecCurrent == 'disabled'
                      ? Colors.orangeAccent
                      : Colors.white70),
            ),
            if (m.videoParams != null)
              _diagRow('Video Params', m.videoParams!, valueColor: Colors.cyanAccent),
            _diagRow(
              'Resolution',
              m.videoWidth != null ? '${m.videoWidth}x${m.videoHeight}' : 'N/A',
            ),
            _diagRow(
              'Framerate',
              m.fps != null ? '${m.fps!.toStringAsFixed(1)} fps' : 'measuring...',
              valueColor: m.fps != null && m.fps! >= 50
                  ? Colors.greenAccent
                  : (m.fps != null && m.fps! < 25 ? Colors.orangeAccent : Colors.white),
            ),
            _diagRow(
              'Video Bitrate',
              m.videoBitrate != null
                  ? '${(m.videoBitrate! / 1000000).toStringAsFixed(2)} Mbps'
                  : 'N/A',
            ),
            _diagRow(
              'Demuxer Cache',
              '${m.cacheDuration != null ? (m.cacheDuration!.inMilliseconds / 1000).toStringAsFixed(1) : playerState.bufferedPosition.inSeconds}s${m.cacheBufferingState != null ? ' (${m.cacheBufferingState}%)' : ''}',
              valueColor: (m.cacheBufferingState != null && m.cacheBufferingState! < 30)
                  ? Colors.redAccent
                  : Colors.white,
            ),
            _diagRow(
              'Dropped Frames',
              m.frameDropCount != null || m.decoderFrameDropCount != null
                  ? '${m.frameDropCount ?? 0} (VO) / ${m.decoderFrameDropCount ?? 0} (Dec)'
                  : '0',
              valueColor: (m.frameDropCount ?? 0) > 10 ? Colors.orangeAccent : Colors.white70,
            ),
            _diagRow(
              'Bottleneck Analysis',
              m.isDecodeBottleneck
                  ? 'DECODE/CPU (Cache OK, Drops High)'
                  : (m.isNetworkBottleneck
                      ? 'NETWORK (Buffer Underrun)'
                      : 'HEALTHY PIPELINE'),
              valueColor: m.isDecodeBottleneck
                  ? Colors.orangeAccent
                  : (m.isNetworkBottleneck ? Colors.redAccent : Colors.greenAccent),
            ),
            _diagRow(
              'SW Decode Escalation',
              m.swDecodeTier.displayName,
              valueColor: switch (m.swDecodeTier) {
                SoftwareDecodeFallbackTier.none => Colors.greenAccent,
                SoftwareDecodeFallbackTier.loopFilterSkip => Colors.orangeAccent,
                SoftwareDecodeFallbackTier.frameSkip => Colors.redAccent,
              },
            ),
            _diagRow(
              'First Frame Latency',
              m.firstFrameDuration != null
                  ? '${m.firstFrameDuration!.inMilliseconds}ms'
                  : 'measuring...',
            ),
            _diagRow(
              'Switch Latency',
              m.switchLatency != null
                  ? '${m.switchLatency!.inMilliseconds}ms'
                  : 'N/A',
            ),
            _diagRow('Buffering Events', '${m.bufferingCount}'),
            _diagRow('Retries', '${m.retryCount}'),
            if (playerState.currentAudioTrack != null)
              _diagRow('Audio Track', playerState.currentAudioTrack!.title),
            if (playerState.currentSubtitleTrack != null)
              _diagRow('Subtitle', playerState.currentSubtitleTrack!.title),
            if (playerState.error != null)
              _diagRow('Last Error', playerState.error!.name, valueColor: Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _diagRow(String key, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
