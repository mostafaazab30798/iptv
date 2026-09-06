import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

/// Latest logical viewport size. Updated by [FormFactorBinder] (no visual effect).
///
/// Falls back to the platform view metrics before the first binder frame so
/// early `ref.read(formFactorProvider)` callers are not stuck on zero.
final viewportSizeProvider = StateProvider<Size>((ref) {
  final views = WidgetsBinding.instance.platformDispatcher.views;
  if (views.isEmpty) return const Size(400, 800);
  final view = views.first;
  final dpr = view.devicePixelRatio;
  if (dpr <= 0) return const Size(400, 800);
  return view.physicalSize / dpr;
});

/// Whether [PlatformService] classified this host as Android TV.
///
/// Safe to read after bootstrap awaits [PlatformService.initialize] before
/// `runApp`.
final isAndroidTvProvider = Provider<bool>(
  (_) => PlatformService.instance.isAndroidTv,
);

/// Reactive form factor from viewport size + Android TV detection.
final formFactorProvider = Provider<FormFactor>((ref) {
  final size = ref.watch(viewportSizeProvider);
  final isTv = ref.watch(isAndroidTvProvider);
  return FormFactorResolver.resolve(size: size, isAndroidTv: isTv);
});

/// Chrome budgets for the current [formFactorProvider] value.
final chromeHeightsProvider = Provider<ChromeHeights>((ref) {
  return ChromeHeights.forFactor(ref.watch(formFactorProvider));
});

/// Keeps [viewportSizeProvider] in sync with [MediaQuery] without changing UI.
///
/// Place once under [MaterialApp] (e.g. in `builder`) so Riverpod consumers
/// rebuild when the window is resized or rotated.
class FormFactorBinder extends ConsumerWidget {
  const FormFactorBinder({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final current = ref.read(viewportSizeProvider);
    if (current != size) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(viewportSizeProvider) != size) {
          ref.read(viewportSizeProvider.notifier).state = size;
        }
      });
    }
    return child;
  }
}
