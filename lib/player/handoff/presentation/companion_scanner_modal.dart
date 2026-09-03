import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/player/handoff/application/audio_handoff_server_controller.dart';
import 'package:iptv/player/handoff/application/companion_audio_controller.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/handoff/infrastructure/audio_handoff_discovery.dart';
import 'package:iptv/player/handoff/presentation/companion_remote_sheet.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum _ScannerMode { autoDetect, camera }

/// Modal bottom sheet allowing mobile users to pair with the TV for Companion Remote
/// (Touchpad Mouse, Keyboard & Private Listening) via local discovery or QR camera scan.
class CompanionScannerModal extends ConsumerStatefulWidget {
  const CompanionScannerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: false,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        reverseDuration: Duration(milliseconds: 160),
      ),
      builder: (_) => const CompanionScannerModal(),
    );
  }

  @override
  ConsumerState<CompanionScannerModal> createState() =>
      _CompanionScannerModalState();
}

class _CompanionScannerModalState extends ConsumerState<CompanionScannerModal>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _cameraController;
  _ScannerMode _mode = _ScannerMode.autoDetect;
  bool _isConnecting = false;
  String? _errorMessage;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(discoveryScannerProvider).triggerProbe();
    });
  }

  @override
  void dispose() {
    _stopCamera();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCamera() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
    setState(() {
      _mode = _ScannerMode.camera;
      _errorMessage = null;
    });
  }

  void _stopCamera() {
    _cameraController?.dispose();
    _cameraController = null;
  }

  void _switchToMode(_ScannerMode mode) {
    if (_mode == mode) return;
    HapticFeedback.selectionClick();
    if (_mode == _ScannerMode.camera && mode != _ScannerMode.camera) {
      _stopCamera();
    } else if (mode == _ScannerMode.camera) {
      _startCamera();
      return;
    }
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  Future<void> _connectWithQrPayload(String raw) async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    final session = HandoffSessionInfo.fromQrPayload(raw);
    if (session == null) {
      setState(() {
        _isConnecting = false;
        _errorMessage = context.l10n.companionInvalidQr;
      });
      return;
    }

    await _executeConnect(session);
  }

  Future<void> _executeConnect(HandoffSessionInfo session) async {
    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(companionAudioProvider.notifier);
      final navigator = Navigator.of(context, rootNavigator: true);
      final success = await controller.connect(session);

      if (success && mounted) {
        _stopCamera();
        navigator.pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (navigator.context.mounted) {
            unawaited(CompanionRemoteSheet.show(navigator.context));
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _errorMessage = context.l10n.companionCouldNotReach(
              '${session.hostIp}:${session.port}',
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = 'Connection failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        !PlatformService.instance.isWindows && !PlatformService.instance.isWeb;
    final sessionsAsync = ref.watch(discoveredTvSessionsProvider);
    final rawSessions = sessionsAsync.valueOrNull ?? [];
    final sessionInfo = ref.watch(
      audioHandoffServerProvider.select((s) => s.sessionInfo),
    );
    final availableIps = ref.watch(
      audioHandoffServerProvider.select((s) => s.availableIps),
    );
    final ownIp = sessionInfo?.hostIp;
    final ownToken = sessionInfo?.sessionToken;

    final discoveredSessions = rawSessions.where((s) {
      final sToken = s.sessionInfo.sessionToken;
      final sIp = s.sessionInfo.hostIp;
      if (ownToken != null && sToken == ownToken) return false;
      if (ownIp != null && sIp == ownIp) return false;
      if (availableIps.contains(sIp)) return false;
      return true;
    }).toList();

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        bottomInset > 0
            ? bottomInset + 12
            : (bottomPadding > 0 ? bottomPadding + 8 : 16),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0B101B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clean Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Redesigned Modern Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.22),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: AppIcons.generalTv,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.companionScannerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.companionScannerSubtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.companionRescanWifi,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white70,
                      size: 21,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(discoveryScannerProvider).triggerSubnetScan();
                    },
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    tooltip: context.l10n.companionExit,
                    visualDensity: VisualDensity.compact,
                    icon: const HugeIcon(
                      icon: AppIcons.close,
                      color: Colors.white70,
                      size: 19,
                    ),
                    onPressed: () {
                      _stopCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              // Segmented Mode Switcher (Pill Style) — only needed when camera is available on mobile
              if (isMobile) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPillTab(
                        label: context.l10n.companionTabNearby,
                        icon: Icons.radar_rounded,
                        isSelected: _mode == _ScannerMode.autoDetect,
                        onTap: () => _switchToMode(_ScannerMode.autoDetect),
                      ),
                      _buildPillTab(
                        label: context.l10n.companionTabScanQr,
                        icon: Icons.qr_code_scanner_rounded,
                        isSelected: _mode == _ScannerMode.camera,
                        onTap: () => _switchToMode(_ScannerMode.camera),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Error feedback badge if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.redAccent,
                        size: 17,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Content Switcher
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: switch (_mode) {
                  _ScannerMode.autoDetect => _buildAutoDetectView(
                      discoveredSessions,
                    ),
                  _ScannerMode.camera => _buildCameraView(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8.5),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.black : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 1: Nearby Auto-Detect
  // ---------------------------------------------------------------------------
  Widget _buildAutoDetectView(List<DiscoveredTvSession> sessions) {
    if (sessions.isNotEmpty) {
      return Column(
        key: const ValueKey('sessions-list'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  context.l10n.companionAvailableScreens,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          ...sessions.map((item) {
            final s = item.sessionInfo;
            final isBusy = s.source.title.isNotEmpty && s.source.title != 'IPTV Screen';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _getDeviceIcon(s.serverDeviceName),
                      color: AppColors.accent,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.serverDeviceName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBusy
                              ? context.l10n.companionNowPlaying(s.source.title)
                              : context.l10n.companionReadyToConnect,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isConnecting ? null : () => _executeConnect(s),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            context.l10n.handoffConnect,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Elegant Minimalist Radar Animation State
    return Container(
      key: const ValueKey('radar-searching'),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final val = _pulseController.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse ring
                    Container(
                      width: 50 + (val * 30),
                      height: 50 + (val * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(
                            alpha: (1.0 - val).clamp(0.0, 0.45),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Inner pulse ring
                    Container(
                      width: 44 + ((val * 16) % 20),
                      height: 44 + ((val * 16) % 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withValues(
                            alpha: (0.7 - (val * 0.5)).clamp(0.0, 0.6),
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                    // Central TV Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: AppIcons.generalTv,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.companionScanningNearby,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.companionScanningHint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 2: Scan QR
  // ---------------------------------------------------------------------------
  Widget _buildCameraView() {
    if (_cameraController == null) {
      return const SizedBox(height: 200);
    }
    return Column(
      key: const ValueKey('camera-viewfinder'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 230,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && raw.isNotEmpty && !_isConnecting) {
                        _connectWithQrPayload(raw);
                        break;
                      }
                    }
                  },
                ),
                // Sleek Corner Brackets Target
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2,
                    ),
                  ),
                ),
                // Flash Toggle
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const HugeIcon(
                        icon: AppIcons.aspectRatio,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _cameraController?.toggleTorch(),
                    ),
                  ),
                ),
                // Connecting spinner
                if (_isConnecting)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static IconData _getDeviceIcon(String devName) {
    final lower = devName.toLowerCase();
    if (lower.contains('pc') ||
        lower.contains('windows') ||
        lower.contains('mac') ||
        lower.contains('linux') ||
        lower.contains('desktop') ||
        lower.contains('laptop')) {
      return Icons.laptop_chromebook;
    }
    if (lower.contains('tablet') || lower.contains('pad')) {
      return Icons.tablet_android;
    }
    if (lower.contains('phone') || lower.contains('mobile')) {
      return Icons.smartphone;
    }
    return Icons.tv;
  }
}
