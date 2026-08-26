import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// Ultra-modern Channel Card inspired by Dribbble & Apple TV OTT standards.
class ChannelCard extends StatelessWidget {
  const ChannelCard({
    super.key,
    required this.channel,
    required this.onTap,
    this.width = 148,
    this.height = 124,
    this.showBadge = true,
    this.isPlaying = false,
    this.categoryName,
  });

  final Channel channel;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool showBadge;
  final bool isPlaying;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FocusableCard(
        onTap: onTap,
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(14),
        backgroundColor: isPlaying
            ? AppColors.accent.withAlpha(30)
            : const Color(0xFF10131B),
        borderColor: isPlaying
            ? AppColors.accent.withAlpha(180)
            : Colors.white.withAlpha(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Maximized Logo Showcase Stage
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isPlaying
                        ? [
                            AppColors.accent.withAlpha(35),
                            const Color(0xFF090D17),
                          ]
                        : [
                            const Color(0xFF141926),
                            const Color(0xFF0A0C13),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPlaying
                        ? AppColors.accent.withAlpha(120)
                        : Colors.white.withAlpha(15),
                    width: 0.9,
                  ),
                ),
                child: Stack(
                  children: [
                    // Centered full-scale logo
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Center(
                          child: SmartChannelLogo(
                            channel: channel,
                            fit: BoxFit.contain,
                            fallbackIcon: isPlaying ? AppIcons.play : AppIcons.live,
                          ),
                        ),
                      ),
                    ),

                    // Top-Right: Playing or Live micro-badge
                    if (isPlaying)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, Color(0xFF0088FF)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withAlpha(120),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(icon: AppIcons.waveform, color: Colors.black, size: 9),
                              SizedBox(width: 2),
                              Text(
                                'PLAYING',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (showBadge)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF87).withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFF00FF87).withAlpha(120),
                              width: 0.7,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF00FF87),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF00FF87),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFF00FF87),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),

            // 2. Compact Channel Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                channel.name,
                style: TextStyle(
                  color: isPlaying ? AppColors.accent : Colors.white,
                  fontSize: 11.5,
                  fontWeight: isPlaying ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.1,
                  shadows: isPlaying
                      ? [
                          Shadow(
                            color: AppColors.accent.withAlpha(150),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
