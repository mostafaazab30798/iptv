import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/commercial/supabase_client_factory.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/player/handoff/application/audio_handoff_server_controller.dart';
import 'package:iptv/player/handoff/application/companion_audio_controller.dart';
import 'package:iptv/player/handoff/application/companion_scanner_actions.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/handoff/infrastructure/audio_handoff_discovery.dart';
import 'package:iptv/player/handoff/presentation/companion_remote_sheet.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

part 'companion_auth_transfer_sheet.dart';

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
    _cameraController?.dispose();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
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

    // 1. Check if the scanned QR code is an Auth Handoff (Device Sign-In)
    final authInfo = CompanionAuthHandoffInfo.fromQrPayload(raw);
    if (authInfo != null) {
      await _handleAuthHandoffQr(authInfo);
      return;
    }

    // 2. Audio/Player Handoff
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

  Future<void> _handleAuthHandoffQr(CompanionAuthHandoffInfo authInfo) async {
    _stopCamera();
    unawaited(HapticFeedback.mediumImpact());

    // Check if the current device is signed into IPTV
    final creds = await ref.read(secureStorageProvider).loadCredentials();
    if (creds == null || creds.serverUrl.isEmpty || creds.username.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _errorMessage = context.l10n.companionPhoneNotSignedIn;
      });
      return;
    }

    // Get current App Account info (if available)
    final appAccount = ref.read(appAccountSessionProvider).account;
    final session = SupabaseClientFactory.isInitialized
        ? SupabaseClientFactory.client.auth.currentSession
        : null;
    final email = appAccount?.email ?? session?.user.email;
    final refreshToken = session?.refreshToken;

    if (!mounted) return;

    // Show Confirmation Bottom Sheet
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AuthTransferConfirmationSheet(
        authInfo: authInfo,
        serverUrl: creds.serverUrl,
        username: creds.username,
        email: email,
      ),
    );

    if (confirmed != true) {
      if (mounted) {
        setState(() => _isConnecting = false);
        if (_mode == _ScannerMode.camera) {
          _startCamera();
        }
      }
      return;
    }

    // User confirmed: Send payload to target screen
    try {
      final payload = CompanionAuthCredentialsPayload(
        token: authInfo.sessionToken,
        pin: authInfo.pinCode,
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
        email: email,
        refreshToken: refreshToken,
        companionDeviceName: CompanionScannerActions.companionDeviceName(),
      );

      final ok = await CompanionScannerActions.transferAuthCredentials(
        authInfo: authInfo,
        payload: payload,
      );

      if (!mounted) return;

      if (ok) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.companionTransferSuccess(
                      authInfo.targetDeviceName,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        throw Exception('Transfer rejected');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _errorMessage = context.l10n.companionTransferFailed(e.toString());
      });
      if (_mode == _ScannerMode.camera) {
        _startCamera();
      }
    }
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
    final supportsCameraScan = !PlatformService.instance.isWindows &&
        !PlatformService.instance.isWeb &&
        !PlatformService.instance.isAndroidTv;
    if (!supportsCameraScan && _mode == _ScannerMode.camera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _switchToMode(_ScannerMode.autoDetect);
      });
    }
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

              // Segmented Mode Switcher — camera QR only when a camera is available
              if (supportsCameraScan) ...[
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
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
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
                      CompanionScannerActions.deviceIconForName(s.serverDeviceName),
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
                  errorBuilder: (context, error, child) {
                    final isPermDenied =
                        error.errorCode == MobileScannerErrorCode.permissionDenied;
                    return Container(
                      color: const Color(0xFF131C2E),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPermDenied
                                  ? Icons.no_photography_rounded
                                  : Icons.error_outline_rounded,
                              color: Colors.amber,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPermDenied
                                  ? 'Camera permission is required to scan the TV QR code.'
                                  : 'Could not start camera (${error.errorCode.name}).',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                              ),
                              onPressed: _startCamera,
                              child: const Text(
                                'Retry Camera',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final raw = barcode.rawValue;
                      if (raw != null && raw.isNotEmpty && !_isConnecting) {
                        unawaited(HapticFeedback.mediumImpact());
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
        const SizedBox(height: 10),
        // Fallback option: Manual pairing code
        TextButton.icon(
          onPressed: _showManualPairingDialog,
          icon: const Icon(Icons.dialpad_rounded, size: 16, color: AppColors.accent),
          label: const Text(
            'Enter TV IP & PIN Manually',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showManualPairingDialog() async {
    final ipController = TextEditingController();
    final pinController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF131C2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.dialpad_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 10),
            Text(
              context.l10n.companionEnterPairingCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.companionPairingDialogBody,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ipController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                labelText: context.l10n.companionDirectIpAddress,
                hintText: context.l10n.companionIpHintExample,
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12.5),
                prefixIcon: const Icon(Icons.lan_outlined, size: 18, color: AppColors.accent),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.companionPinCodeLabel,
                hintText: '0000',
                counterText: '',
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12.5),
                prefixIcon: const Icon(Icons.password_rounded, size: 18, color: AppColors.accent),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              context.l10n.actionCancel,
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              context.l10n.handoffConnect,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final rawHost = ipController.text.trim();
    final pin = pinController.text.trim();
    if (rawHost.isEmpty || pin.isEmpty) return;

    final endpoint = CompanionScannerActions.normalizeManualHost(rawHost);
    final host = endpoint.host;
    final port = endpoint.port;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final data = await CompanionScannerActions.fetchAuthHandoffInfo(
        host: host,
        port: port,
      );
      final serverPin = data['pin']?.toString() ?? '';
      final token = data['tok']?.toString() ?? '';
      final dev = data['dev']?.toString() ?? 'HOPE IPTV Screen';

      if (serverPin.isNotEmpty && serverPin != pin) {
        throw Exception('Incorrect PIN code entered');
      }

      final info = CompanionAuthHandoffInfo(
        hostIp: host,
        port: port,
        sessionToken: token,
        pinCode: pin,
        targetDeviceName: dev,
      );

      await _handleAuthHandoffQr(info);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Could not connect to TV at $host:$port: $e';
      });
    }
  }

}
