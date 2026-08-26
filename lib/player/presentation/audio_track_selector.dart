import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/domain/entities/player_track.dart';

/// Modal dialog / bottom sheet to select an audio track.
class AudioTrackSelectorModal extends StatelessWidget {
  const AudioTrackSelectorModal({
    super.key,
    required this.tracks,
    required this.currentTrack,
    required this.onSelect,
  });

  final List<PlayerAudioTrack> tracks;
  final PlayerAudioTrack? currentTrack;
  final ValueChanged<PlayerAudioTrack> onSelect;

  static Future<void> show(
    BuildContext context, {
    required List<PlayerAudioTrack> tracks,
    required PlayerAudioTrack? currentTrack,
    required ValueChanged<PlayerAudioTrack> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AudioTrackSelectorModal(
        tracks: tracks,
        currentTrack: currentTrack,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Audio Tracks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white12),
            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No alternative audio tracks found', style: TextStyle(color: Colors.white70)),
              )
            else
              ...tracks.map((track) {
                final isSelected = currentTrack?.id == track.id;
                return ListTile(
                  leading: HugeIcon(
                    icon: AppIcons.audioTrack,
                    color: isSelected ? AppColors.accent : Colors.white70,
                    size: 22,
                  ),
                  title: Text(
                    track.title,
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: track.language != null
                      ? Text(track.language!.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 12))
                      : null,
                  trailing: isSelected ? const HugeIcon(icon: AppIcons.checkSimple, color: AppColors.accent, size: 20) : null,
                  onTap: () {
                    onSelect(track);
                    Navigator.of(context).pop();
                  },
                );
              }),
          ],
        ),
      ),
    );
  }
}
