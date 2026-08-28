# HOPE IPTV Flutter Full Audit

Audit date: 2026-08-28  
Repository: `D:\PROJECTS\iptv`  
Audit method: source inspection and repository asset/configuration inspection. Real-device profile metrics are not available in this environment. Four concurrent Flutter tool invocations (`flutter --version`, `flutter analyze`, `flutter test`, and `dart fix --dry-run`) produced no output and remained blocked until cancelled; an older Dart process was already present. Do not treat any projected improvement below as measured.

## Executive Summary

The codebase is materially stronger than the generic baseline assumed by the master prompt. It already uses Riverpod, builder-based large lists, isolate-backed parsing/search, cached network images, bundled fonts, a unified icon family, skeleton states, responsive navigation, and disposed controllers/timers in the inspected lifecycle code. The highest risks are retained duplicate catalogs, first-frame startup blocking, broad screen rebuild subscriptions, release configuration, duplicate assets, and an inconsistent design layer that bypasses its own tokens.

Project facts:

- App name: HOPE IPTV (`MaterialApp.title` and platform labels); package name remains `iptv`.
- Dart constraint: `^3.10.7`; installed Flutter version could not be read because the local tool process blocked.
- State management: Flutter Riverpod 2.6.1 using `StateNotifierProvider`.
- Targets present: Android/Android TV, iOS, Web, and Windows.
- Minimum tier: low-RAM behavior is explicitly supported, but no numeric RAM/device floor is documented.

| Severity | Performance | Design | Total |
|---|---:|---:|---:|
| Critical | 0 | 0 | 0 |
| High | 3 | 1 | 4 |
| Medium | 4 | 3 | 7 |
| Low | 2 | 1 | 3 |
| Total | 9 | 5 | 14 |

| Category | Count |
|---|---:|
| Rendering | 2 |
| State | 2 |
| Memory | 2 |
| Startup | 2 |
| Lists | 1 |
| Design-Layout | 2 |
| Design-Visual | 2 |
| Design-Motion | 1 |

Top five fixes by severity-to-effort ratio:

1. P-01: remove permanent retention of full live/movie/series catalogs.
2. P-02: stop global search from holding second full catalog copies.
3. P-03: render the first frame before nonessential platform initialization.
4. P-04: scope Movies and Series Riverpod subscriptions to visible fields.
5. D-01: consolidate the fragmented visual values into enforceable design tokens.

Expected direction, not a measured promise: P-01 and P-02 can remove several complete list-reference graphs from long-lived state; P-03 should reduce time-to-first-frame by the duration of platform/preferences/orientation awaits; P-04 should reduce full-screen rebuild frequency during loading/search; P-08 removes 665,487 source bytes before build compression. Frame time, memory, startup, and package-size deltas must be measured in Phase 8.

Open questions:

- Which physical device defines the lowest supported tier? answer : samsung galaxy a51
- Is iOS a shipping target? The `pubspec.yaml` description names Android, Android TV, Windows, and Web, while an iOS project exists. answer : it was but not anymore
- Must IPTV servers using plain HTTP remain supported? Android currently permits cleartext globally.
- What are the production Android application ID, signing keystore, and release channel requirements? answer : i don't have them yet
- Which user flow is currently reported as worst: initial catalog load, category browsing, search, or playback overlay interaction? answer : moving between tabs , player is laggy 

## Full Findings List (Performance)

### Finding P-01: Permanently Retained Full Catalog Controllers
- **Category:** Memory
- **Severity:** High
- **File(s):** `lib/features/live/live_controller.dart`, `lib/features/movies/movies_controller.dart`, `lib/features/series/series_controller.dart`
- **Line(s):** `liveControllerProvider` lines 241-246; `moviesControllerProvider` lines 241-246; `seriesControllerProvider` lines 241-246
- **Evidence:** Each provider calls `ref.keepAlive()` and each controller owns a full `_catalog` list. Once opened, all three catalogs remain reachable for the entire `ProviderScope` lifetime, including on low-RAM devices.
- **Root Cause:** Feature data is treated as application-lifetime state rather than route-lifetime state, despite repositories and disk cache already providing reload paths.
- **Impact:** Memory cannot be reclaimed after leaving Live, Movies, or Series; opening all three features can retain all catalog object graphs concurrently and increase GC pressure or low-memory termination risk.
- **Fix — Exact Steps:**
  1. Remove `ref.keepAlive()` from all three provider factories.
  2. Convert each provider to `StateNotifierProvider.autoDispose`.
  3. Do not change controller constructors, repository APIs, or disk caching.
  4. Add a provider lifecycle test that listens, closes the subscription, pumps one event loop, and verifies controller disposal cancels its debounce timer.
- **Before Code:**
  ```dart
  final liveControllerProvider =
      StateNotifierProvider<LiveController, LiveState>((ref) {
    ref.keepAlive();
    final repo = ref.watch(liveRepositoryProvider);
    return LiveController(repo);
  });
  ```
- **After Code:**
  ```dart
  final liveControllerProvider =
      StateNotifierProvider.autoDispose<LiveController, LiveState>((ref) {
    final repo = ref.watch(liveRepositoryProvider);
    return LiveController(repo);
  });
  ```
- **Validation Step:** Run `flutter test`; then profile a session that opens Live, Movies, and Series and returns Home. In DevTools Memory, force GC and confirm the three controller instances and their `_catalog` lists are no longer retained when their routes are absent.
- **Rollback Plan:** Restore the three original non-auto-dispose provider declarations and `ref.keepAlive()` calls.
- **Dependencies:** Complete P-02 first or in the same phase so Search does not remain a second catalog owner.

### Finding P-02: Search Duplicates Full Catalog Ownership
- **Category:** Memory
- **Severity:** High
- **File(s):** `lib/features/search/search_controller.dart`, `lib/core/cache/local_catalog_cache.dart`
- **Line(s):** `_channelCache`, `_movieCache`, `_seriesCache` lines 72-75; `_fetchChannels` lines 154-169; `_fetchMovies` lines 171-185; `_fetchSeriesList` lines 187-201
- **Evidence:** Search stores three complete in-memory catalog lists in `_CatalogCache` even though the repositories and `LocalCatalogCache` already cache catalog data. The Search screen only needs those lists during an active query.
- **Root Cause:** A route-scoped search accelerator became an additional cache layer without an ownership or eviction contract.
- **Impact:** Search can retain channels, movies, and series simultaneously, duplicating long-lived references and increasing peak memory during isolate message serialization.
- **Fix — Exact Steps:**
  1. Delete the three `_CatalogCache` fields and `invalidateCaches()`.
  2. Make `searchControllerProvider` auto-dispose.
  3. Load each catalog into local variables inside the debounced search operation; do not assign the lists to controller fields.
  4. Keep `LocalCatalogCache` as the only disk fallback and repository caches as the only in-memory catalog owners.
- **Before Code:**
  ```dart
  final _channelCache = _CatalogCache<Channel>();
  final _movieCache = _CatalogCache<Movie>();
  final _seriesCache = _CatalogCache<Series>();

  Future<List<Channel>> _fetchChannels() async {
    if (_channelCache.isValid) return _channelCache.data!;
    final disk = await LocalCatalogCache.instance.loadChannels();
    if (disk != null && disk.isNotEmpty) {
      _channelCache.set(disk);
      return disk;
    }
    final res = await (_liveRepo?.getChannels() ??
        Future.value(const Err<List<Channel>>(AppResultError('No repo'))));
    final list = res.when(ok: (l) => l, err: (_) => <Channel>[]);
    if (list.isNotEmpty) _channelCache.set(list);
    return list;
  }
  ```
- **After Code:**
  ```dart
  Future<List<Channel>> _fetchChannels() async {
    final disk = await LocalCatalogCache.instance.loadChannels();
    if (disk != null && disk.isNotEmpty) return disk;

    final result = await (_liveRepo?.getChannels() ??
        Future.value(const Err<List<Channel>>(AppResultError('No repo'))));
    return result.when(ok: (items) => items, err: (_) => <Channel>[]);
  }

  final searchControllerProvider =
      StateNotifierProvider.autoDispose<SearchController, SearchState>((ref) {
    return SearchController(
      ref.watch(liveRepositoryProvider),
      ref.watch(vodRepositoryProvider),
      ref.watch(seriesRepositoryProvider),
    );
  });
  ```
- **Validation Step:** Search for the same term twice and confirm identical results; close Search, force GC in DevTools, and confirm `SearchController` and its result lists are released.
- **Rollback Plan:** Restore `_CatalogCache` fields, fetch methods, `invalidateCaches()`, and the original provider declaration.
- **Dependencies:** None.

### Finding P-03: Startup Blocks the First Flutter Frame
- **Category:** Startup
- **Severity:** High
- **File(s):** `lib/app/bootstrap.dart`
- **Line(s):** `bootstrap()` lines 20-76
- **Evidence:** `runApp` occurs only after awaiting `PlatformService.initialize`, `PreferencesStorage.initialize`, Android orientation changes, and system UI mode changes. Database construction also occurs before `runApp`.
- **Root Cause:** Essential and nonessential initialization are serialized into a single pre-frame bootstrap path.
- **Impact:** Users see the native launch screen longer; slow plugin/channel initialization directly increases cold-start time.
- **Fix — Exact Steps:**
  1. Keep only `WidgetsFlutterBinding.ensureInitialized()`, `MediaKit.ensureInitialized()`, logging setup, image-cache limits, database construction, and `runApp` in the synchronous bootstrap path.
  2. Move platform, preferences, orientation, and system-UI initialization into a `Future<void> initializeAfterFirstFrame()` method.
  3. Invoke that method from `App.initState` through `WidgetsBinding.instance.addPostFrameCallback`.
  4. Keep Splash responsible for session routing until preferences/session initialization completes.
- **Before Code:**
  ```dart
  await PlatformService.instance.initialize();
  await PreferencesStorage.initialize();
  if (PlatformService.instance.isAndroid) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  runApp(ProviderScope(overrides: [
    _dbProvider.overrideWithValue(db),
  ], child: const App()));
  ```
- **After Code:**
  ```dart
  Future<void> initializeAfterFirstFrame() async {
    await Future.wait<void>([
      PlatformService.instance.initialize(),
      PreferencesStorage.initialize(),
    ]);
    if (PlatformService.instance.isAndroid) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  Future<void> bootstrap() async {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    AppLogger.initialize(verbose: kDebugMode);
    final db = AppDatabase();
    runApp(ProviderScope(
      overrides: [_dbProvider.overrideWithValue(db)],
      child: const App(),
    ));
  }
  ```
- **Validation Step:** On the target low-tier device, collect five cold starts before and after with `adb shell am force-stop <production-id>` and Flutter DevTools startup tracing; compare median time to first rasterized Flutter frame.
- **Rollback Plan:** Restore the original serialized `bootstrap()` and remove the post-frame initializer call.
- **Dependencies:** Phase 0 must add a splash/session routing smoke test.

### Finding P-04: Movies and Series Rebuild Entire Screens for Every State Field
- **Category:** State
- **Severity:** Medium
- **File(s):** `lib/features/movies/movies_screen.dart`, `lib/features/series/series_screen.dart`
- **Line(s):** Movies `build()` line 102; Series `build()` line 84
- **Evidence:** Both root screens use `ref.watch(controllerProvider)` and pass the full state through the complete category/grid subtree. Search text, loading flags, category maps, and result-list changes all invalidate the entire screen.
- **Root Cause:** Provider subscription scope is at the route root instead of the smallest independently changing subtree.
- **Impact:** Search and progressive loading rebuild headers, category hubs, grid scaffolding, and animation wrappers unnecessarily.
- **Fix — Exact Steps:**
  1. Extract the category hub and selected-category content into separate `ConsumerWidget` classes.
  2. In each widget, use `.select` for only the fields it renders.
  3. Keep local navigation flags in the existing `State` object.
  4. Add a widget test using a build counter around the category header and verify result-list changes do not rebuild it.
- **Before Code:**
  ```dart
  @override
  Widget build(BuildContext context) {
    final moviesState = ref.watch(moviesControllerProvider);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: isCategorySelected
            ? _buildMoviesGridView(moviesState)
            : _buildCategoriesHub(moviesState),
      ),
    );
  }
  ```
- **After Code:**
  ```dart
  class _MovieGridBody extends ConsumerWidget {
    const _MovieGridBody({required this.onMovieTap});

    final ValueChanged<Movie> onMovieTap;

    @override
    Widget build(BuildContext context, WidgetRef ref) {
      final isLoading = ref.watch(
        moviesControllerProvider.select((state) => state.isLoading),
      );
      final movies = ref.watch(
        moviesControllerProvider.select((state) => state.filteredMovies),
      );
      if (isLoading) return const PosterGridSkeleton();
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        cacheExtent: 350,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) => _MovieGridCard(
          key: ValueKey(movies[index].streamId),
          movie: movies[index],
          onTap: () => onMovieTap(movies[index]),
        ),
      );
    }
  }
  ```
- **Validation Step:** Enable DevTools Track Widget Builds, type a five-character Movies search, and confirm the route header/category navigation does not rebuild for each result state update; repeat for Series.
- **Rollback Plan:** Inline the extracted widgets and restore the full-state `ref.watch` calls.
- **Dependencies:** None.

### Finding P-05: Home Uses an Eager Vertical List of All Sections
- **Category:** Lists
- **Severity:** Medium
- **File(s):** `lib/features/home/home_screen.dart`
- **Line(s):** `_HomeContent.build` lines 118-248
- **Evidence:** The vertical `ListView(children: [...])` eagerly constructs the hero and every non-empty section. Each section then owns a horizontal lazy list. The current maximum is bounded, but all row headers/list viewports are created at once.
- **Root Cause:** The screen uses a static children list instead of lazy vertical slivers.
- **Impact:** Home has higher initial widget/layout cost as sections grow and less control over section-level repaint isolation.
- **Fix — Exact Steps:**
  1. Replace the vertical `ListView` with `CustomScrollView`.
  2. Wrap the hero and each content row in separate `SliverToBoxAdapter` widgets.
  3. Wrap each horizontal `HomeSectionRow` in `RepaintBoundary` with a stable `ValueKey`.
  4. Preserve existing section order and visibility conditions exactly.
- **Before Code:**
  ```dart
  child: ListView(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
    cacheExtent: 350,
    children: [
      if (homeState.heroItem != null) HomeHeroBanner(item: homeState.heroItem!),
      Padding(child: Column(children: sectionWidgets)),
    ],
  )
  ```
- **After Code:**
  ```dart
  child: CustomScrollView(
    cacheExtent: 350,
    slivers: [
      if (homeState.heroItem != null)
        SliverToBoxAdapter(
          child: RepaintBoundary(
            key: const ValueKey('home-hero'),
            child: HomeHeroBanner(
              item: homeState.heroItem!,
              onPlay: () => _playHero(context, ref, homeState.heroItem!),
              onSecondaryAction: () =>
                  _handleHeroSecondary(context, homeState.heroItem!),
              secondaryActionLabel: homeState.heroItem!.type == HeroItemType.live
                  ? context.l10n.homeTvGuide
                  : context.l10n.homeAllMovies,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        sliver: SliverList.list(children: sectionWidgets),
      ),
    ],
  )
  ```
- **Validation Step:** Record Home entry in profile mode before and after; compare first-frame build time and verify horizontal scrolling does not repaint unrelated rows using DevTools Highlight Repaints.
- **Rollback Plan:** Restore the original `ListView` and `Padding(Column(...))` structure.
- **Dependencies:** Apply after D-02 because the Home layout will be touched there.

### Finding P-06: Shimmer Applies an Animated Shader to Whole Skeleton Subtrees
- **Category:** Rendering
- **Severity:** Medium
- **File(s):** `lib/shared/widgets/shimmer.dart`, `lib/shared/widgets/skeleton_loaders.dart`
- **Line(s):** `Shimmer.build` lines 44-68; all skeleton compositions using `Shimmer`
- **Evidence:** One repeating `AnimationController` drives `ShaderMask` over the entire supplied child. Large home/list/grid skeleton trees are composited continuously while loading.
- **Root Cause:** Loading animation is implemented as a full-subtree shader rather than bounded placeholders or a reduced-motion/static mode.
- **Impact:** Raster cost can spike on low-end GPUs precisely during network/loading work; accessibility users cannot disable the animation.
- **Fix — Exact Steps:**
  1. Read `MediaQuery.disableAnimationsOf(context)` and `DeviceMemory.isLowRamDevice` in `Shimmer.build`.
  2. Return the unanimated child when either flag is true.
  3. Wrap the animated `ShaderMask` in `RepaintBoundary`.
  4. Do not add an external shimmer package.
- **Before Code:**
  ```dart
  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        colors: const [Color(0xFF1B1F28), Color(0xFF303746), Color(0xFF1B1F28)],
        transform: _SlidingGradientTransform(_controller.value),
      ).createShader(bounds),
      child: child,
    ),
    child: widget.child,
  );
  ```
- **After Code:**
  ```dart
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  if (!widget.enabled || reduceMotion || DeviceMemory.isLowRamDevice) {
    return widget.child;
  }
  return RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: const [
            Color(0xFF1B1F28),
            Color(0xFF303746),
            Color(0xFF1B1F28),
          ],
          transform: _SlidingGradientTransform(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
    ),
  );
  ```
- **Validation Step:** Toggle Android “Remove animations” and verify skeletons remain static; on the low-tier device compare raster time during HomeSkeleton display.
- **Rollback Plan:** Remove the low-RAM/reduced-motion branch and `RepaintBoundary`.
- **Dependencies:** None.

### Finding P-07: Android Release Build Is Not Production-Hardened
- **Category:** Startup
- **Severity:** Medium
- **File(s):** `android/app/build.gradle.kts`
- **Line(s):** `defaultConfig` lines 22-31; `buildTypes.release` lines 33-38
- **Evidence:** The application ID is `com.example.iptv`; release explicitly uses debug signing; no explicit `isMinifyEnabled` or `isShrinkResources` setting is present.
- **Root Cause:** The generated development configuration was retained for release.
- **Impact:** Production identity/signing is invalid, release artifacts may be larger than necessary, and store upgrade continuity cannot be guaranteed.
- **Fix — Exact Steps:**
  1. Obtain the production application ID and keystore details; do not invent them.
  2. Add a release signing config backed by `key.properties` excluded from version control.
  3. Set `isMinifyEnabled = true` and `isShrinkResources = true` for release.
  4. Build and smoke-test media playback, Drift, secure storage, and HugeIcons in release mode before adding keep rules.
- **Before Code:**
  ```kotlin
  release {
      signingConfig = signingConfigs.getByName("debug")
  }
  ```
- **After Code:**
  ```kotlin
  release {
      signingConfig = signingConfigs.getByName("release")
      isMinifyEnabled = true
      isShrinkResources = true
      proguardFiles(
          getDefaultProguardFile("proguard-android-optimize.txt"),
          "proguard-rules.pro",
      )
  }
  ```
- **Validation Step:** Run `flutter build apk --release --analyze-size --target-platform android-arm64`; install the APK and complete authentication, catalog load, database write, and playback smoke tests.
- **Rollback Plan:** Disable minification/resource shrinking and restore the previous signing config only for local development artifacts.
- **Dependencies:** Blocked on production application ID and signing information.

### Finding P-08: Duplicate 665 KB Logo Asset
- **Category:** Rendering
- **Severity:** Low
- **File(s):** `assets/icons/app_logo.png`, `assets/images/app_logo.png`, `pubspec.yaml`, `lib/core/constants/app_constants.dart`
- **Line(s):** asset directories in `pubspec.yaml`; `AppConstants.appLogo` line 6
- **Evidence:** The two files are each 665,487 bytes. All located call sites use `assets/icons/app_logo.png`; no Dart source references the image-directory copy.
- **Root Cause:** Both asset directories are bundled wholesale after the logo was duplicated.
- **Impact:** Avoidable source and bundle payload; future branding updates can diverge between copies.
- **Fix — Exact Steps:**
  1. Verify hashes are identical with `Get-FileHash`.
  2. Delete only `assets/images/app_logo.png`.
  3. If `assets/images` becomes empty, remove `- assets/images/` from `pubspec.yaml`.
  4. Keep `AppConstants.appLogo` unchanged.
- **Before Code:**
  ```yaml
  assets:
    - assets/images/
    - assets/icons/
  ```
- **After Code:**
  ```yaml
  assets:
    - assets/icons/
  ```
- **Validation Step:** Run `flutter test` and launch Splash, Onboarding, Settings, and the app shell; confirm the logo renders in all four locations. Compare analyze-size asset tables.
- **Rollback Plan:** Restore `assets/images/app_logo.png` and its pubspec entry.
- **Dependencies:** None.

### Finding P-09: Static Analysis Baseline Is Not Reproducible
- **Category:** State
- **Severity:** Low
- **File(s):** repository/toolchain environment
- **Line(s):** N/A
- **Evidence:** `flutter --version`, `flutter analyze`, `flutter test`, and `dart fix --dry-run` all remained running with no output and were cancelled. An existing Dart process predated the audit.
- **Root Cause:** The local Flutter SDK/cache lock or resident process state is unhealthy or inaccessible from the managed environment.
- **Impact:** No trustworthy analyzer/test baseline exists for this audit, and downstream changes cannot meet the required per-finding validation rules until fixed.
- **Fix — Exact Steps:**
  1. Close IDE Flutter debug sessions and resident `flutter run` processes.
  2. Run `flutter doctor -v` in a fresh terminal.
  3. Run `flutter pub get`, `flutter analyze`, `dart fix --dry-run`, and `flutter test` sequentially, not concurrently.
  4. Save all command output as Phase 0 evidence.
- **Before Code:**
  ```text
  Baseline: unavailable; commands blocked without output.
  ```
- **After Code:**
  ```text
  Baseline: flutter doctor, analyze, dry-run fixes, and tests complete with recorded exit codes.
  ```
- **Validation Step:** All four commands must exit normally; `flutter analyze` must have zero errors and `flutter test` must pass before Phase 1.
- **Rollback Plan:** No code rollback; restore the prior SDK only if toolchain repair changes SDK version and causes incompatibility.
- **Dependencies:** Must be completed in Phase 0 before every implementation finding.

## Full Findings List (Design)

### Finding D-01: Design Tokens Exist but Are Routinely Bypassed
- **Category:** Design-Visual
- **Severity:** High
- **File(s):** `lib/app/theme/app_colors.dart`, `app_spacing.dart`, `app_radius.dart`, `app_typography.dart`, `app_shadows.dart`, `app_motion.dart`; `lib/shared/navigation/app_shell.dart`; `lib/features/onboarding/onboarding_screen.dart`; `lib/features/home/widgets/*.dart`
- **Line(s):** `app_shell.dart` lines 148-798; `onboarding_screen.dart` lines 236-2097; Home widget hard-coded colors/radii/letter spacing reported by `rg`
- **Evidence:** A token layer exists, but screens define many raw radii (14, 16, 20, 26), alpha colors, gradients, shadows, durations, font sizes, and positive/negative letter spacing. This defeats global consistency and conflicts with the product rule that letter spacing be zero.
- **Root Cause:** Tokens were added after component styling and are not the required dependency for visual values.
- **Impact:** The app looks assembled from multiple design passes; dark surfaces, focus states, typography, and motion cannot be tuned coherently.
- **Fix — Exact Steps:**
  1. Create `lib/core/design_system/tokens.dart` as a compatibility facade over the existing token classes.
  2. Add missing accent, neutral, semantic info, glass, shadow, and motion values shown below.
  3. Replace raw visual values screen-by-screen only during Phase 6; do not perform a global search-and-replace.
  4. Set all component letter spacing to `0` except verified logotype artwork; render the HOPE/IPTV wordmark as an image if tracking is brand-critical.
- **Before Code:**
  ```dart
  borderRadius: BorderRadius.circular(26),
  boxShadow: [
    BoxShadow(color: Colors.black.withAlpha(130), blurRadius: 20),
  ],
  duration: const Duration(milliseconds: 220),
  ```
- **After Code:**
  ```dart
  import 'package:flutter/material.dart';

  abstract final class DesignTokens {
    static const Color primary = Color(0xFF00C2FF);
    static const Color accentWarm = Color(0xFFFFB547);
    static const Color accentCool = Color(0xFF6FE7C8);
    static const Color neutral0 = Color(0xFF08090B);
    static const Color neutral10 = Color(0xFF0E1014);
    static const Color neutral20 = Color(0xFF14171D);
    static const Color neutral30 = Color(0xFF1B1F28);
    static const Color neutral40 = Color(0xFF242938);
    static const Color neutral50 = Color(0xFF4A5060);
    static const Color neutral70 = Color(0xFF8E96A8);
    static const Color neutral95 = Color(0xFFF0F2F5);
    static const Color success = Color(0xFF2ECC71);
    static const Color warning = Color(0xFFF3B33D);
    static const Color error = Color(0xFFE75A5A);
    static const Color info = Color(0xFF64B5F6);
    static const Color glassFill = Color(0xD90E1014);
    static const Color glassBorder = Color(0x24FFFFFF);

    static const double space4 = 4;
    static const double space8 = 8;
    static const double space12 = 12;
    static const double space16 = 16;
    static const double space24 = 24;
    static const double space32 = 32;
    static const double radius4 = 4;
    static const double radius8 = 8;

    static const Duration motionFast = Duration(milliseconds: 120);
    static const Duration motionStandard = Duration(milliseconds: 200);
    static const Duration motionSlow = Duration(milliseconds: 320);
    static const Curve motionCurve = Curves.easeOutCubic;

    static const List<BoxShadow> surfaceShadow = [
      BoxShadow(
        color: Color(0x40001624),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ];
  }
  ```
- **Validation Step:** Run `rg -n "letterSpacing: (?!0)|BorderRadius.circular\([0-9]|Duration\(milliseconds" lib/features lib/shared` with a regex-capable shell and review every remaining exception; run golden tests for Home, Onboarding, Live, Movies, Series, Search, Favorites, History, Guide, and Settings.
- **Rollback Plan:** Revert the token facade and each screen migration commit independently; existing `App*` token files remain available throughout.
- **Dependencies:** Must precede D-02 through D-05.

### Finding D-02: Home Hierarchy Is a Uniform Streaming Feed, Not a Priority Dashboard
- **Category:** Design-Layout
- **Severity:** Medium
- **File(s):** `lib/features/home/home_screen.dart`
- **Line(s):** `_HomeContent.build` lines 118-248
- **Evidence:** After one full-width hero, all content uses identical horizontal section rows with the same title/icon/see-all rhythm. Importance is expressed mainly by order and row height.
- **Root Cause:** A reusable carousel pattern is used for every content class.
- **Impact:** The Home screen is competent but generic; live urgency, resume actions, and discovery have insufficiently distinct hierarchy.
- **Fix — Exact Steps:**
  1. Keep the full-width hero.
  2. Replace the first two rows with an asymmetric bento band: Continue Watching 2x2, Live Now 1x2, Favorites 1x1, Guide 1x1.
  3. Keep Movies, Series, Sports, and News as editorial horizontal rails below the bento band.
  4. On widths below 600 px, stack Continue Watching full width, then a two-column grid for the three smaller tiles.
- **Before Code:**
  ```text
  [ HERO HERO HERO HERO ]
  [ Continue Watching horizontal row ]
  [ Featured Movies horizontal row   ]
  [ Popular Series horizontal row    ]
  [ Sports horizontal row            ]
  [ News horizontal row              ]
  ```
- **After Code:**
  ```text
  [ HERO HERO HERO HERO ]
  [ CONTINUE  CONTINUE ][ LIVE ]
  [ CONTINUE  CONTINUE ][ FAV  ]
  [ GUIDE ][ GUIDE      ][ FAV  ]
  [ Featured Movies editorial rail   ]
  [ Popular Series editorial rail    ]
  [ Sports ][ News rails              ]
  ```
- **Validation Step:** Capture 360x800, 800x1280, 1280x720, and 1920x1080 goldens; verify no overflow, keyboard/remote focus order follows visual order, and the next section remains visible below the first viewport.
- **Rollback Plan:** Restore the original ordered `HomeSectionRow` list.
- **Dependencies:** D-01 before; P-05 after.

### Finding D-03: Onboarding Is Visually Overloaded and Monolithic
- **Category:** Design-Layout
- **Severity:** Medium
- **File(s):** `lib/features/onboarding/onboarding_screen.dart`
- **Line(s):** entire file, 2,097 lines; `_AmbientBackground` lines 1968-2036; `_buildShowcasePanel` and `_buildLoginForm`
- **Evidence:** The screen combines ambient radial decorations, shader text, glass cards, feature marketing, language controls, server presets, credential form, password controls, M3U conversion, and two large dialogs in one source file.
- **Root Cause:** Product onboarding, connection setup, and promotional storytelling were combined into one surface and one implementation unit.
- **Impact:** The primary task, connecting a service, competes with decorative content; maintenance and visual QA are difficult across mobile/TV/desktop.
- **Fix — Exact Steps:**
  1. Preserve a single-screen connection flow; do not add a marketing landing page.
  2. Use one restrained aurora header band only, with no discrete circular orbs.
  3. Move server picker and M3U converter widgets into separate files without changing their public behavior.
  4. Order the form as Provider -> Server URL -> Username -> Password -> Connect; place M3U import in an overflow/tools action.
  5. Keep language switching in the header and retain TV focus traversal.
- **Before Code:**
  ```text
  [ ambient orbs + showcase/feature copy ] [ glass login form ]
  [ provider picker + form + conversion + secondary information ]
  ```
- **After Code:**
  ```text
  [ HOPE IPTV                         EN | AR ]
  [ restrained multi-color header wash       ]
  [ Provider selector                         ]
  [ Server URL                                ]
  [ Username                                  ]
  [ Password                              eye ]
  [ Connect                               ->  ]
  [ tools: Import M3U                          ]
  ```
- **Validation Step:** Complete connection setup using touch, keyboard, and TV remote at compact and widescreen sizes; verify one primary action is visually dominant and no decorative layer repaints continuously.
- **Rollback Plan:** Restore the extracted widgets and original two-panel layout from the previous commit.
- **Dependencies:** D-01.

### Finding D-04: Empty and Error States Are Generic Icon Stacks
- **Category:** Design-Visual
- **Severity:** Medium
- **File(s):** `lib/shared/widgets/empty_state.dart`, `lib/shared/widgets/error_view.dart`
- **Line(s):** `EmptyState.build` lines 24-67; `ErrorView.build` lines 22-54
- **Evidence:** Both states center a default icon, title/message, and optional button. There is no domain imagery or structured contextual action; all screens inherit the same personality.
- **Root Cause:** State handling was centralized at the component level but not specialized at the content level.
- **Impact:** Empty playlists, no favorites, no history, search misses, and connection failures feel interchangeable and generic.
- **Fix — Exact Steps:**
  1. Extend both widgets with optional `illustration`, `eyebrow`, and `secondaryAction` slots while preserving existing constructor call compatibility.
  2. Create bitmap illustrations for playlist-empty, favorites-empty, history-empty, and connection-error states; use WebP with transparent backgrounds and display-size-aware decoding.
  3. Add localized, contextual copy for each screen; do not use “No data found.”
  4. Keep the generic icon fallback for uncustomized callers.
- **Before Code:**
  ```dart
  class EmptyState extends StatelessWidget {
    const EmptyState({
      super.key,
      required this.title,
      this.subtitle,
      this.icon = AppIcons.empty,
      this.actionLabel,
      this.onAction,
    });
  }
  ```
- **After Code:**
  ```dart
  class EmptyState extends StatelessWidget {
    const EmptyState({
      super.key,
      required this.title,
      this.subtitle,
      this.eyebrow,
      this.illustration,
      this.icon = AppIcons.empty,
      this.actionLabel,
      this.onAction,
      this.secondaryAction,
    });

    final String title;
    final String? subtitle;
    final String? eyebrow;
    final Widget? illustration;
    final dynamic icon;
    final String? actionLabel;
    final VoidCallback? onAction;
    final Widget? secondaryAction;
  }
  ```
- **Validation Step:** Add goldens for Home empty playlist, Favorites empty, History empty, Search no results, and network error in English and Arabic; verify images have semantic labels or are excluded from semantics when decorative.
- **Rollback Plan:** Remove optional slots and restore icon-only call sites; retain localized copy changes only if independently approved.
- **Dependencies:** D-01; image assets require product approval.

### Finding D-05: Motion Is Inconsistent and Ignores a Global Reduced-Motion Policy
- **Category:** Design-Motion
- **Severity:** Low
- **File(s):** `lib/app/theme/app_motion.dart`, `lib/shared/navigation/app_shell.dart`, `lib/features/movies/movies_screen.dart`, `lib/features/series/series_screen.dart`, `lib/shared/widgets/shimmer.dart`
- **Line(s):** hard-coded durations throughout the listed files; `AppMotion` lines 1-20
- **Evidence:** `AppMotion` exists, while components use 160, 180, 200, 220, 250, and 700 ms directly. Shimmer and navigation animation do not share one reduced-motion decision.
- **Root Cause:** Motion was implemented per component instead of through a policy/token adapter.
- **Impact:** Interaction cadence varies and accessibility behavior is incomplete.
- **Fix — Exact Steps:**
  1. Add `MotionPolicy.of(context)` returning zero durations when `MediaQuery.disableAnimationsOf(context)` is true.
  2. Replace component durations with `AppMotion.fast`, `medium`, or `slow` through the policy.
  3. Use `Curves.easeOutCubic` for entrances and `Curves.easeInCubic` for exits; reserve elastic curves for explicit playful feedback, not navigation.
  4. Add scale-down press feedback and platform haptics only to primary commands, guarded by platform capability.
- **Before Code:**
  ```dart
  AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  )
  ```
- **After Code:**
  ```dart
  AnimatedContainer(
    duration: MotionPolicy.of(context).standard,
    curve: AppMotion.curveEnter,
  )
  ```
- **Validation Step:** With system animations enabled, verify consistent navigation/press cadence; with animations disabled, verify transitions and shimmer stop without changing layout or focus behavior.
- **Rollback Plan:** Restore component-local durations and remove `MotionPolicy` calls.
- **Dependencies:** D-01 and P-06.

Screen-by-screen hierarchy notes:

| Screen | Current hierarchy | Required hierarchy |
|---|---|---|
| Splash | Centered logo and fade | Keep; shorten only after startup measurement. |
| Onboarding | Showcase plus glass form and ambient orbs | Task-first connection form with one restrained header wash; see D-03. |
| Home | Hero plus uniform rails | Hero, priority bento band, then editorial rails; see D-02. |
| Live | Category hub, selected category/list-grid, mini preview | Keep operational split; make selected channel/Now Playing the strongest surface and keep filters compact. |
| Guide | Channel list with program rows | Keep dense schedule layout; add sticky time ruler and stronger current-program marker only after profile validation. |
| Movies | Category cards then poster grid | Keep poster grid; add one featured category band and compact filter/sort tools, not decorative cards. |
| Series | Category cards then poster grid/details | Match Movies hierarchy; preserve season/episode density and remote focus. |
| Search | Query field plus type result lists | Use tabs/segmented type filters and grouped results; keep keyboard focus in query on desktop. |
| Favorites | Filters plus list/grid | Keep utilitarian library layout; show type counts and contextual empty illustration. |
| History | Header plus chronological list | Group by Today/This week/Earlier and retain progress as the dominant secondary signal. |
| Settings | Single long list | Split into Account, Playback, Appearance, Storage/About sections with unframed section headers. |
| Player | Full-bleed video plus overlays | Keep full-bleed; do not add decorative framing. Apply reduced-motion policy and preserve minimal overlay density. |

## Prioritization Matrix

| Finding ID | Severity | Effort | User Impact | Priority Rank |
|---|---|---|---|---:|
| P-01 | High | S | Lower retained memory after browsing | 1 |
| P-02 | High | M | Lower search peak/retained memory | 2 |
| P-03 | High | M | Faster perceived cold start | 3 |
| P-04 | Medium | M | Smoother search/loading updates | 4 |
| D-01 | High | L | Coherent product identity and maintainability | 5 |
| P-08 | Low | S | Smaller asset payload | 6 |
| P-06 | Medium | S | Lower loading raster cost/accessibility | 7 |
| P-07 | Medium | M | Valid, smaller production release | 8 |
| D-02 | Medium | L | Stronger Home hierarchy | 9 |
| D-03 | Medium | L | Clearer connection workflow | 10 |
| D-04 | Medium | M | Distinctive contextual states | 11 |
| P-05 | Medium | M | Lower Home initial layout/repaint cost | 12 |
| D-05 | Low | M | Consistent accessible motion | 13 |
| P-09 | Low | S | Enables all verification | 0 (prerequisite) |

## Phased Execution Plan

### Phase 0 — Safety Net

Order: P-09, then capture baseline metrics.

Definition of Done:

- Create branch `audit/performance-design-overhaul`.
- Record `flutter doctor -v`, `flutter --version`, `dart --version`, `flutter analyze`, `dart fix --dry-run`, and `flutter test` outputs.
- Run `flutter run --profile` on the named lowest-tier physical device.
- Record Home load, Live category scroll, Movies search, Series details, and Player overlay flows.
- Capture average build/raster time, janky frame count/percentage, Home rebuild count, cold-start median, idle/peak memory, and analyze-size output.
- CI and the manual smoke checklist pass before modifications.

Do not touch application code, dependencies, SDK constraints, or generated files in this phase.

### Phase 1 — Critical Performance Fixes

Finding IDs: P-02, P-01. Apply in that order.

Definition of Done:

- Search and feature controllers are released after routes close.
- Search results remain correct for channels, movies, and series.
- Memory snapshots show no retained route controller after forced GC.
- All tests/analyzer checks pass after each finding.

Do not change repository response models, API endpoints, database schemas, player code, or screen designs.

### Phase 2 — Rendering & Rebuild Optimization

Finding IDs: P-04, P-06.

Definition of Done:

- Movies/Series headers do not rebuild for result-only changes.
- Reduced-motion and low-RAM modes render static skeletons.
- No visual or focus-order regression in goldens/manual checks.

Do not redesign layouts or add packages.

### Phase 3 — List/Network/Async Optimization

Finding IDs: P-05, but defer implementation until D-02 layout is finalized; profile repository/network behavior and add a finding before changing it if duplicate calls are observed.

Definition of Done:

- Home uses lazy vertical slivers and bounded repaint regions.
- Existing content order/data/actions remain correct.
- Profile evidence shows no regression in build or raster time.

Do not alter API caching, pagination contracts, parsing thresholds, or playback URLs without new measured evidence.

### Phase 4 — Startup & Size Optimization

Finding IDs: P-03, P-08, P-07.

Order: P-03, P-08, P-07.

Definition of Done:

- Median first Flutter frame is recorded before and after.
- Duplicate logo is absent and all logo call sites render.
- Production application ID/signing inputs are supplied.
- Release APK installs and passes authentication, storage, catalog, and playback smoke tests.
- Analyze-size output is archived.

Do not defer initialization required for the Splash routing decision without an explicit readiness state. Do not invent signing credentials.

### Phase 5 — Design System Foundation

Finding IDs: D-01.

Definition of Done:

- `lib/core/design_system/tokens.dart` compiles and has unit coverage for key constants.
- No public widget constructor changes occur.
- A documented exception list exists for any remaining raw visual values.
- English/Arabic type themes render correctly.

Do not redesign screens, replace icon packages, or add runtime font downloads.

### Phase 6 — Screen-by-Screen Redesign

Finding IDs: D-03, D-02, D-04. Apply Onboarding, then Home, then shared state components and call sites.

Definition of Done:

- Each screen is committed and validated independently.
- Goldens exist at 360x800, 800x1280, 1280x720, and 1920x1080 where supported.
- Touch, keyboard, and TV focus flows pass.
- Text does not overflow in English or Arabic.
- Home bento layout and diagrams match D-02 exactly.
- Empty/error content is contextual and localized.

Do not modify player rendering, repositories, authentication semantics, route paths, or public entity models.

### Phase 7 — Motion & Polish Pass

Finding IDs: D-05 and the motion portion of P-06.

Definition of Done:

- All animation durations use the policy/tokens or a documented exception.
- System reduced-motion disables nonessential animation.
- Primary press feedback does not cause layout shift.
- Hero/shared-element transitions are added only where source and destination show the same content entity and keys are stable.

Do not add stagger animation to lists until profile mode confirms it stays within the frame budget on the minimum device.

### Phase 8 — Final Regression Pass

Finding IDs: all completed findings.

Definition of Done:

- Re-run every Phase 0 command and user flow on the same device/build mode/data set.
- Populate the final metrics table with measured values.
- Janky frames are below 2% for each recorded flow.
- No analyzer errors, failing tests, visual overflows, focus traps, memory leaks, or release smoke failures remain.
- Side-by-side screenshots and DevTools traces are archived with commit hashes.

Do not make opportunistic fixes. Log newly discovered problems as separate findings with evidence.

## Agent Execution Rules

```text
RULES FOR THE EXECUTING AGENT:
1. Execute findings strictly in the phase and order given. Do not skip ahead.
2. Never modify a file beyond what the specific Finding's "Fix — Exact Steps" describes.
3. After each finding is applied, run its Validation Step before moving to the next.
4. If a Validation Step fails, execute the Rollback Plan immediately and flag the finding as BLOCKED — do not attempt improvisation.
5. Do not introduce new packages/dependencies unless explicitly listed in the fix.
6. Preserve all existing public APIs/widget constructors unless the finding explicitly instructs a signature change — if it does, update every call site (list them).
7. Commit after each completed finding with message format: `fix(FindingID): short description`.
8. Do not reformat/refactor code outside the scope of the current finding, even if it "looks messy."
9. If any instruction is ambiguous, STOP and request clarification rather than guessing.
```

## Final Metrics Report Template

Profiling protocol:

1. Run `flutter run --profile` on the named minimum-tier physical device.
2. In DevTools Performance, record the same flows and data set before and after.
3. Enable Track Widget Builds and Highlight Repaints for targeted passes.
4. Use the device refresh-rate budget: 16.67 ms at 60 Hz or 8.33 ms at 120 Hz.
5. Run `flutter build apk --release --analyze-size --target-platform android-arm64` and archive the size report.

| Metric | Before | After | Target |
|---|---:|---:|---:|
| Avg frame build time (ms) | | | <8 ms |
| Avg frame raster time (ms) | | | <8 ms |
| Janky frames per session | | | <2% |
| Cold start time, median of 5 (ms) | | | Set after baseline |
| APK/IPA size (MB) | | | No regression; document reduction |
| Memory footprint, idle (MB) | | | Set after baseline |
| Memory footprint, peak (MB) | | | Lower than baseline |
| Widget rebuild count, Home | | | Lower than baseline |
| Widget rebuild count, Movies search | | | Header unchanged per query update |

