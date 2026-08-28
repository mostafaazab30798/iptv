import 'package:flutter/material.dart';
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
import 'package:iptv/features/onboarding/widgets/m3u_converter_dialog.dart';
import 'package:iptv/features/onboarding/widgets/server_gateway_picker_dialog.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';

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
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await ref.read(secureStorageProvider).loadCredentials();
    if (saved != null && mounted) {
      setState(() {
        final matchingPreset = ServerPresets.presets.firstWhere(
          (p) =>
              p.url.trim().toLowerCase() ==
              saved.serverUrl.trim().toLowerCase(),
          orElse: () => ServerPresets.customPreset,
        );
        _selectedPreset = matchingPreset;
        _isCustomServer = matchingPreset.id == ServerPresets.customServerId;
        _urlController.text = saved.serverUrl;
        _userController.text = saved.username;
        _passController.text = saved.password;
      });
    }
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
      builder: (ctx) => ServerGatewayPickerDialog(
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
      builder: (ctx) => M3uConverterDialog(
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

    final serverUrl = _isCustomServer
        ? _urlController.text.trim()
        : _selectedPreset.url;

    final res = await ref
        .read(authControllerProvider.notifier)
        .login(
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

    final allPresets = [...ServerPresets.presets, ServerPresets.customPreset];

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
                final isWide =
                    constraints.maxWidth >= 960 && constraints.maxHeight >= 520;
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
                    child: _buildCompactLayout(
                      allPresets,
                      isLoading,
                      isMedium || isWide,
                    ),
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

  /// Compact single-column layout for Mobile & Small Tablets.
  Widget _buildCompactLayout(
    List<ServerPreset> allPresets,
    bool isLoading,
    bool isMedium,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isMedium ? 560 : 440),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCompactHeader(),
          const SizedBox(height: AppSpacing.lg),
          _buildGlassCard(child: _buildLoginForm(allPresets, isLoading)),
        ],
      ),
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
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HOPE',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.5,
                height: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'IPTV',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 6.0,
                shadows: [Shadow(color: Color(0x7A00E5FF), blurRadius: 8)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.onboardingClientSubtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Frosted glass card wrapper with glowing hairline border.
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AdaptiveGlass(
        sigma: 20,
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
              onTap: isLoading
                  ? null
                  : () => _openServerPickerDialog(allPresets),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bg1,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border, width: 1),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCustom
                                      ? AppColors.warning.withValues(
                                          alpha: 0.15,
                                        )
                                      : AppColors.success.withValues(
                                          alpha: 0.15,
                                        ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCustom
                                      ? context.l10n.onboardingManual
                                      : context.l10n.onboardingOnline,
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
                                ? context.l10n.onboardingCustomConfig
                                : (_selectedPreset.description ??
                                      _selectedPreset.url),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
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
                  final trimmed = v.trim();
                  final uri = Uri.tryParse(trimmed);
                  final hasHttpScheme =
                      trimmed.startsWith('http://') ||
                      trimmed.startsWith('https://');
                  if (!hasHttpScheme ||
                      uri == null ||
                      uri.host.isEmpty ||
                      (uri.scheme != 'http' && uri.scheme != 'https')) {
                    return context.l10n.validationUrlInvalid;
                  }
                  return null;
                },
              ),
            ),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
            validator: (v) => (v == null || v.trim().isEmpty)
                ? context.l10n.validationUsernameRequired
                : null,
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
            validator: (v) => (v == null || v.isEmpty)
                ? context.l10n.validationPasswordRequired
                : null,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
                              icon:
                                  Directionality.of(context) ==
                                      TextDirection.rtl
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
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: isLoading ? null : _openM3uConverterDialog,
            icon: const HugeIcon(
              icon: AppIcons.swap,
              color: AppColors.accent,
              size: 18,
            ),
            label: Text(context.l10n.onboardingHaveM3u),
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
        child: HugeIcon(
          icon: icon as List<List<dynamic>>,
          color: AppColors.textSecondary,
          size: 20,
        ),
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

/// Restrained, static header wash behind the connection workflow.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10242D), AppColors.bg0, AppColors.bg0],
          stops: [0, 0.34, 1],
        ),
      ),
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
