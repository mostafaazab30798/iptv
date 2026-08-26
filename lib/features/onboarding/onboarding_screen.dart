import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/core/constants/server_presets.dart';

import 'package:iptv/core/utils/m3u_converter.dart';
import 'package:iptv/features/auth/auth_controller.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _userFocusNode = FocusNode();
  final _passFocusNode = FocusNode();
  final _urlFocusNode = FocusNode();

  late ServerPreset _selectedPreset;
  bool _isCustomServer = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _m3uSuccessNotice;

  @override
  void initState() {
    super.initState();
    _selectedPreset = ServerPresets.presets.first;
    _urlController.text = _selectedPreset.url;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _userController.dispose();
    _passController.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _onPresetSelected(ServerPreset preset) {
    setState(() {
      _selectedPreset = preset;
      _isCustomServer = preset.id == ServerPresets.customServerId;
      _errorMessage = null;
      _m3uSuccessNotice = null;
      if (!_isCustomServer) {
        _urlController.text = preset.url;
      } else {
        _urlController.clear();
      }
    });
  }

  void _openServerPickerDialog(List<ServerPreset> allPresets) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ServerGatewayPickerDialog(
        allPresets: allPresets,
        selectedPreset: _selectedPreset,
        onSelected: _onPresetSelected,
      ),
    );
  }

  /// Automatically detects and converts M3U URLs typed or pasted into the custom server URL field.
  void _onCustomUrlChanged(String value) {
    if (!_isCustomServer) return;
    final trimmed = value.trim();
    if (M3uToXtreamConverter.isM3uLink(trimmed)) {
      final creds = M3uToXtreamConverter.tryConvert(trimmed);
      if (creds != null) {
        setState(() {
          _urlController.text = creds.serverUrl;
          _userController.text = creds.username;
          _passController.text = creds.password;
          _m3uSuccessNotice =
              '✨ M3U link detected & converted to Xtream Fast Stream mode!';
          _errorMessage = null;
        });
      }
    }
  }

  void _openM3uConverterDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _M3uConverterDialog(
        onConverted: (creds, autoConnect) {
          setState(() {
            _selectedPreset = ServerPresets.customPreset;
            _isCustomServer = true;
            _urlController.text = creds.serverUrl;
            _userController.text = creds.username;
            _passController.text = creds.password;
            _m3uSuccessNotice =
                '⚡ Converted from M3U (${creds.detectedType ?? 'Direct'}): High-Speed Xtream stream engine configured!';
            _errorMessage = null;
          });
          if (autoConnect) {
            _signIn();
          }
        },
      ),
    );
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _errorMessage = null);

    final serverUrl = _isCustomServer ? _urlController.text.trim() : _selectedPreset.url;

    final res = await ref.read(authControllerProvider.notifier).login(
      serverUrl: serverUrl,
      username: _userController.text.trim(),
      password: _passController.text,
    );

    res.when(
      ok: (_) {
        ref.read(homeControllerProvider.notifier).loadData();
        if (mounted) context.go(Routes.home);
      },
      err: (err) {
        if (mounted) {
          setState(() {
            _errorMessage = err.message;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    final allPresets = [
      ...ServerPresets.presets,
      ServerPresets.customPreset,
    ];

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Ambient dynamic background glow
          const _AmbientBackground(),

          // Main Responsive Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960 && constraints.maxHeight >= 520;
                final isMedium = constraints.maxWidth >= 600 && !isWide;

                return Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide
                          ? AppSpacing.xl
                          : (isMedium ? AppSpacing.xl : AppSpacing.md),
                      vertical: AppSpacing.md,
                    ),
                    child: isWide
                        ? _buildWidescreenLayout(allPresets, isLoading)
                        : _buildCompactLayout(allPresets, isLoading, isMedium),
                  ),
                );
              },
            ),
          ),

          // Top corner language switcher
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: _buildLanguageSwitcher(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    final currentLocale = ref.watch(localeProvider).languageCode;
    final isAr = currentLocale == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10141C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageSegmentButton(
            label: 'EN',
            isSelected: !isAr,
            onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
          ),
          const SizedBox(width: 4),
          _LanguageSegmentButton(
            label: 'العربية',
            isSelected: isAr,
            onTap: () => ref.read(localeProvider.notifier).setLocale('ar'),
          ),
        ],
      ),
    );
  }

  /// Wide 2-column layout for Desktop, TV, and large displays.
  Widget _buildWidescreenLayout(List<ServerPreset> allPresets, bool isLoading) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Brand & Showcase panel
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xxl),
              child: _buildShowcasePanel(),
            ),
          ),

          // Right: Glassmorphic Connection Card
          Expanded(
            flex: 5,
            child: _buildGlassCard(
              child: _buildLoginForm(allPresets, isLoading),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact single-column layout for Mobile & Small Tablets.
  Widget _buildCompactLayout(
    List<ServerPreset> allPresets,
    bool isLoading,
    bool isMedium,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isMedium ? 520 : 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompactHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildGlassCard(
            child: _buildLoginForm(allPresets, isLoading),
          ),
        ],
      ),
    );
  }

  /// Left panel showcase featuring highlights & status.
  Widget _buildShowcasePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Logo & Badge Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              AppConstants.appLogo,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.onboardingBadge,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Hero Title
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE2E8F0), AppColors.accent],
            stops: [0.0, 0.6, 1.0],
          ).createShader(bounds),
          child: Text(
            context.l10n.onboardingHeroTitle,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.l10n.onboardingHeroSubtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Feature Highlights
        _FeatureHighlightRow(
          icon: AppIcons.bolt,
          title: context.l10n.onboardingFeat1Title,
          subtitle: context.l10n.onboardingFeat1Subtitle,
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureHighlightRow(
          icon: AppIcons.swap,
          title: context.l10n.onboardingFeat2Title,
          subtitle: context.l10n.onboardingFeat2Subtitle,
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureHighlightRow(
          icon: AppIcons.hub,
          title: context.l10n.onboardingFeat3Title,
          subtitle: context.l10n.onboardingFeat3Subtitle,
        ),
        const SizedBox(height: AppSpacing.md),
        _FeatureHighlightRow(
          icon: AppIcons.live,
          title: context.l10n.onboardingFeat4Title,
          subtitle: context.l10n.onboardingFeat4Subtitle,
        ),
      ],
    );
  }

  /// Compact header for mobile view.
  Widget _buildCompactHeader() {
    return Column(
      children: [
        Image.asset(
          AppConstants.appLogo,
          width: 84,
          height: 84,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.onboardingClientTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.onboardingClientSubtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Frosted glass card wrapper with glowing hairline border.
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: const Color(0xFF10141C).withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.04),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// Login Form with modular gateway selector and prominent M3U converter card.
  Widget _buildLoginForm(List<ServerPreset> allPresets, bool isLoading) {
    final isCustom = _selectedPreset.id == ServerPresets.customServerId;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clean, Spacious Form Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: AppIcons.dns,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.authConnectServer,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.l10n.authSignInSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Prominent M3U Quick Converter Action Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : _openM3uConverterDialog,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.12),
                      const Color(0xFF0072FF).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: AppIcons.swap,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.l10n.onboardingHaveM3u,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const HugeIcon(
                                icon: AppIcons.bolt,
                                size: 14,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                          Text(
                            context.l10n.onboardingM3uConvertHint,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.l10n.actionConvert,
                        style: const TextStyle(
                          color: AppColors.textOnAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Modular Server Gateway Card Picker Trigger
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.onboardingActiveGateway,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                context.l10n.onboardingGatewaysAvailable(allPresets.length),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive Selected Server Tile (Opens Modular Picker Dialog)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : () => _openServerPickerDialog(allPresets),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg1,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: isCustom ? AppIcons.tune : AppIcons.dns,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _selectedPreset.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCustom
                                      ? AppColors.warning.withValues(alpha: 0.15)
                                      : AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCustom ? context.l10n.onboardingManual : context.l10n.onboardingOnline,
                                  style: TextStyle(
                                    color: isCustom ? AppColors.warning : AppColors.success,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCustom
                                ? context.l10n.onboardingCustomConfig
                                : (_selectedPreset.description ?? _selectedPreset.url),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.actionChange,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const HugeIcon(
                            icon: AppIcons.chevronDown,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // M3U Success Banner (when converted)
          if (_m3uSuccessNotice != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: AppIcons.checkCircle,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _m3uSuccessNotice!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Custom URL Input or Active Preset Information
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isCustomServer
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: TextFormField(
                controller: _urlController,
                focusNode: _urlFocusNode,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
                onChanged: _onCustomUrlChanged,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: _buildInputDecoration(
                  label: context.l10n.authServerUrl,
                  hint: context.l10n.onboardingUrlHint,
                  icon: AppIcons.link,
                ),
                validator: (v) {
                  if (!_isCustomServer) return null;
                  if (v == null || v.trim().isEmpty) {
                    return context.l10n.validationUrlRequired;
                  }
                  if (!v.trim().startsWith('http://') && !v.trim().startsWith('https://')) {
                    return context.l10n.validationUrlInvalid;
                  }
                  return null;
                },
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bg0.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const HugeIcon(
                      icon: AppIcons.lock,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedPreset.url,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        context.l10n.onboardingAutoConfig,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Username Field
          TextFormField(
            controller: _userController,
            focusNode: _userFocusNode,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: _buildInputDecoration(
              label: context.l10n.authUsername,
              hint: context.l10n.authUsername,
              icon: AppIcons.user,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? context.l10n.validationUsernameRequired : null,
          ),
          const SizedBox(height: AppSpacing.md),

          // Password Field
          TextFormField(
            controller: _passController,
            focusNode: _passFocusNode,
            textInputAction: TextInputAction.done,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onFieldSubmitted: (_) => _signIn(),
            decoration: _buildInputDecoration(
              label: context.l10n.authPassword,
              hint: '••••••••',
              icon: AppIcons.lock,
              suffix: IconButton(
                icon: HugeIcon(
                  icon: _obscurePassword
                      ? AppIcons.visibilityOff
                      : AppIcons.visibility,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? context.l10n.validationPasswordRequired : null,
          ),

          // Error Banner
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const HugeIcon(
                    icon: AppIcons.error,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Gradient Submit Button
          Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFF0077FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isLoading ? null : _signIn,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.l10n.actionConnectStream,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            HugeIcon(
                              icon: Directionality.of(context) == TextDirection.rtl
                                  ? AppIcons.arrowBack
                                  : AppIcons.arrowForward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required dynamic icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12.0),
        child: HugeIcon(icon: icon as List<List<dynamic>>, color: AppColors.textSecondary, size: 20),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bg0.withValues(alpha: 0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}

/// Modular Server Gateway Picker Dialog capable of scaling smoothly to 10, 20+ servers.
class _ServerGatewayPickerDialog extends StatefulWidget {
  final List<ServerPreset> allPresets;
  final ServerPreset selectedPreset;
  final ValueChanged<ServerPreset> onSelected;

  const _ServerGatewayPickerDialog({
    required this.allPresets,
    required this.selectedPreset,
    required this.onSelected,
  });

  @override
  State<_ServerGatewayPickerDialog> createState() =>
      _ServerGatewayPickerDialogState();
}

class _ServerGatewayPickerDialogState
    extends State<_ServerGatewayPickerDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'all'; // 'all', 'presets', 'custom'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allPresets.where((preset) {
      final isCustom = preset.id == ServerPresets.customServerId;

      // Category filter
      if (_filterCategory == 'presets' && isCustom) return false;
      if (_filterCategory == 'custom' && !isCustom) return false;

      // Search query filter
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final matchName = preset.name.toLowerCase().contains(q);
      final matchDesc = (preset.description ?? '').toLowerCase().contains(q);
      final matchUrl = preset.url.toLowerCase().contains(q);
      return matchName || matchDesc || matchUrl;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131A).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(AppRadius.dialog),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, Color(0xFF0072FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: AppIcons.dns,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.gatewayDialogTitle,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.l10n.gatewayDialogSubtitle(widget.allPresets.length),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const HugeIcon(icon: AppIcons.close, color: AppColors.textSecondary, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: context.l10n.gatewaySearchHint,
                      hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
                      prefixIcon: const HugeIcon(icon: AppIcons.search, color: AppColors.textSecondary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const HugeIcon(icon: AppIcons.close, size: 16, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.bg1,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: const BorderSide(color: AppColors.accent, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab('all', context.l10n.gatewayFilterAll(widget.allPresets.length)),
                        const SizedBox(width: 8),
                        _buildFilterTab(
                          'presets',
                          context.l10n.gatewayFilterOfficial(widget.allPresets.where((p) => p.id != ServerPresets.customServerId).length),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTab('custom', context.l10n.gatewayFilterCustom),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Server List
                  Flexible(
                    child: filtered.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 36),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(icon: AppIcons.searchOff, size: 36, color: AppColors.textDisabled),
                                const SizedBox(height: 8),
                                Text(
                                  context.l10n.gatewayNoMatches,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final preset = filtered[index];
                              final isSelected = widget.selectedPreset.id == preset.id;
                              final isCustom = preset.id == ServerPresets.customServerId;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onSelected(preset);
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.accent.withValues(alpha: 0.12)
                                          : AppColors.bg1,
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.accent
                                            : AppColors.border,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Status / Icon Indicator
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.accent.withValues(alpha: 0.2)
                                                : AppColors.bg2,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: HugeIcon(
                                              icon: isCustom ? AppIcons.tune : AppIcons.dns,
                                              size: 18,
                                              color: isSelected
                                                  ? AppColors.accent
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Server Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      preset.name,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? AppColors.textPrimary
                                                            : AppColors.textPrimary.withValues(alpha: 0.9),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isCustom
                                                          ? AppColors.warning.withValues(alpha: 0.15)
                                                          : AppColors.success.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      isCustom ? context.l10n.onboardingManual : context.l10n.onboardingOnline,
                                                      style: TextStyle(
                                                        color: isCustom
                                                            ? AppColors.warning
                                                            : AppColors.success,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isCustom
                                                    ? context.l10n.onboardingEnterCustomUrl
                                                    : (preset.description ?? preset.url),
                                                style: const TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (!isCustom && preset.url.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  preset.url,
                                                  style: TextStyle(
                                                    color: AppColors.textDisabled.withValues(alpha: 0.8),
                                                    fontSize: 10,
                                                    fontFamily: 'monospace',
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // Selection Radio Icon
                                        HugeIcon(
                                          icon: isSelected
                                              ? AppIcons.checkCircle
                                              : AppIcons.circle,
                                          color: isSelected
                                              ? AppColors.accent
                                              : AppColors.textDisabled,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(String category, String label) {
    final isCurrent = _filterCategory == category;
    return InkWell(
      onTap: () => setState(() => _filterCategory = category),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.accent.withValues(alpha: 0.15) : AppColors.bg1,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrent ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isCurrent ? AppColors.accent : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Dedicated dialog to paste and convert any M3U link or playlist content to Xtream.
class _M3uConverterDialog extends StatefulWidget {
  final void Function(M3uXtreamCredentials credentials, bool autoConnect) onConverted;

  const _M3uConverterDialog({required this.onConverted});

  @override
  State<_M3uConverterDialog> createState() => _M3uConverterDialogState();
}

class _M3uConverterDialogState extends State<_M3uConverterDialog> {
  final _inputController = TextEditingController();
  M3uXtreamCredentials? _previewCreds;
  String? _error;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onInputChanged(String text) {
    final creds = M3uToXtreamConverter.tryConvert(text);
    setState(() {
      _previewCreds = creds;
      if (text.trim().isNotEmpty && creds == null) {
        _error = context.l10n.m3uExtractError;
      } else {
        _error = null;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _inputController.text = data.text!;
      _onInputChanged(data.text!);
    }
  }

  void _apply(bool autoConnect) {
    if (_previewCreds != null) {
      Navigator.of(context).pop();
      widget.onConverted(_previewCreds!, autoConnect);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFF0F131A).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppRadius.dialog),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, Color(0xFF0072FF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: AppIcons.swap,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.m3uConverterTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                context.l10n.m3uConverterSubtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const HugeIcon(icon: AppIcons.close, color: AppColors.textSecondary, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // M3U Link Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.m3uPasteLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: _pasteFromClipboard,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const HugeIcon(icon: AppIcons.paste, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.actionPaste,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _inputController,
                      maxLines: 3,
                      onChanged: _onInputChanged,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      decoration: InputDecoration(
                        hintText: 'http://provider.com:8080/get.php?username=...&password=...',
                        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.bg1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Live Detection Preview Box (with overflow-safe layout)
                    if (_previewCreds != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const HugeIcon(icon: AppIcons.checkCircle, color: AppColors.accent, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    context.l10n.m3uExtractedSuccess,
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_previewCreds!.detectedType != null)
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _previewCreds!.detectedType!,
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 16),
                            _buildPreviewField(context.l10n.authServerUrl, _previewCreds!.serverUrl),
                            const SizedBox(height: 4),
                            _buildPreviewField(context.l10n.authUsername, _previewCreds!.username),
                            const SizedBox(height: 4),
                            _buildPreviewField(context.l10n.authPassword, '•••••••• (${_previewCreds!.password.length})'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Info / Advantage
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const HugeIcon(icon: AppIcons.info, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.m3uAdvantageHint,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previewCreds == null ? null : () => _apply(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: Text(context.l10n.actionApply, style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _previewCreds == null ? null : () => _apply(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.textOnAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                            ),
                            child: Text(
                              context.l10n.actionConvertAndConnect,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// Feature highlight row in the desktop/widescreen showcase.
class _FeatureHighlightRow extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;

  const _FeatureHighlightRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: HugeIcon(
              icon: icon as List<List<dynamic>>,
              color: AppColors.accent,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dynamic ambient light glows and depth gradient background.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        Container(
          color: AppColors.bg0,
        ),

        // Top Left Cyan Orb
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Bottom Right Deep Blue/Indigo Orb
        Positioned(
          bottom: -150,
          right: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF3B82F6).withValues(alpha: 0.14),
                  const Color(0xFF1E3A8A).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Center ambient depth
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageSegmentButton extends StatelessWidget {
  const _LanguageSegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const HugeIcon(
                  icon: AppIcons.language,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
