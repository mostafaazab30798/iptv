# Hope TV — Codebase Audit & Improvement Roadmap

_Audit date: 2026-09-06 · Version 1.0.4+22 · 267 Dart files, ~72k lines in `lib/`_

## TL;DR

The app has a real design system and a real clean-architecture skeleton — but both are **bypassed wherever convenient**, and the TV experience is the phone layout rendered 1:1 on a ~960×540 logical canvas with zero responsive adaptation.

- **Why Android TV looks "zoomed in":** every size is a fixed logical pixel tuned for a ~400dp phone (hero 420px, rows 215/135px, posters 120×175, header 70px). On TV those same numbers eat 78% of a 540px-tall viewport. There is **no textScaler clamp and no form-factor layout anywhere** — `PlatformService.isAndroidTv` is used only for capabilities (blur, PiP, orientation), never layout. A central responsive toolkit (`AppBreakpoints`, `AdaptiveScaffold`, `ResponsiveBuilder`) exists in `lib/shared/layouts/` but is **dead code**.
- **Why "full of flex errors":** two deterministic patterns — (a) `Row`s whose children are all fixed/intrinsic with no `Flexible` (the shell nav header, player bottom bar, section headers) and (b) width-responsive grid cells (`maxCrossAxisExtent`) whose *contents* have fixed pixel heights. Both trigger at TV geometry and at any user font scale.
- **Cleanliness:** 3 copy-pasted catalog controllers, 4 copies of the poster card, 121 empty `catch (_)` blocks that turn network failures into silently empty screens, a dead 9k-line DB schema (5 of 7 tables unused), and ~12 orphaned files including the entire dead responsive toolkit.
- **Speed:** mostly fine — JSON parsing is already on isolates, images are cache-capped, rebuilds use `select()`. The few hot spots are the history-prune-per-position-save and keep-alive providers holding full catalogs.

Full findings with file:line evidence below, followed by a phased roadmap.

---

## 1. Responsiveness & Android TV (P0 — the reported problem)

### 1.1 Root cause of the "zoomed in" report

| Evidence | Location |
|---|---|
| No `textScaler`/`MediaQuery` normalization anywhere in the app | `lib/app/app.dart:151-223` (builder wraps only `CallbackShortcuts > RemoteFocusScope > Dpad > CompanionPointerOverlay`) |
| Hero banner takes 420px of a 540px TV viewport (`size.width > 900 ? 420 : 380`) | `lib/features/home/widgets/home_hero_banner.dart:53-65` |
| Landscape shell header is a fixed 70px + hero 420px → ~490 of 540px used before any content | `lib/shared/navigation/app_shell.dart:363` |
| All home rows are fixed-pixel: `height: 215/135`, `itemWidth: 120/148`; posters fixed `120×175`, channels `148×124` | `lib/features/home/home_screen.dart:365-540`, `movie_card.dart:13-14`, `channel_card.dart:17-18` |
| `isAndroidTv` consumed only for capabilities, zero layout branching | `lib/core/platform/platform_service.dart:67` + consumers: `adaptive_glass.dart:35`, `bootstrap.dart:33`, `player_capability_service.dart:27` |
| TV detection runs **after first frame** and is non-reactive — any layout reading it at startup sees `false` forever | `lib/app/bootstrap.dart:21-25` |
| Dead responsive toolkit (only self-references) | `lib/shared/layouts/adaptive_scaffold.dart`, `app_breakpoints.dart`, `responsive_builder.dart` (used once, in `home_screen.dart:213`, result discarded) |

### 1.2 Root cause of the flex overflow errors

**Pattern A — Rows with all-fixed children (overflow stripes at TV width):**

1. **[CRITICAL] Shell nav header** — `app_shell.dart:370-455`: brand logo (~150px) + 5 intrinsic-width nav items (≈500-650px in Arabic) + KidsModeNavButton + a 200px action capsule of fixed 34px buttons. No `Flexible`/`Expanded`/`Wrap` anywhere. Overflows on every non-home landscape screen at TV width.
2. **[HIGH] Section headers in every home row** — `home_section_row.dart:52-108`: `Row[icon, Text (no Expanded, no ellipsis), badge, Spacer, see-all]`. Localized titles + badge overflow at TV height-derived widths and at fontScale >1.2.
3. **[HIGH] Player bottom bar** — `player_controls.dart:328-489`: LIVE chip + 5×32px buttons + mute + 75px slider + fullscreen with a single `Spacer`; only gated on `isNarrow < 600`. Overflows on resized Windows windows and with all track/subtitle caps present.
4. **[MEDIUM] Portrait shell header** — `app_shell.dart:276-344`: fixed 200px action capsule + KidsMode + title; clipped on ≤360px phones.
5. **[MEDIUM] Live preview panel** — `live_screen.dart:446-500`: fixed `SizedBox(width: 360)` preview; magic 750px breakpoint unrelated to `AppBreakpoints`.

**Pattern B — Responsive grid cells with fixed-pixel content:**

6. **[HIGH] Favorites grid** — `favorites_screen.dart:385-400`: `maxCrossAxisExtent: 180, childAspectRatio: 0.82` wrapping a card with fixed ~199px internal height → Column overflow at cell width ≤160.
7. **[HIGH] Search grids** — `search_screen.dart:749-796`: `mainAxisExtent: 220` + fixed 175px `MovieCard` + text → overflow at fontScale >1.0; also hardcodes phone-scale art.
8. **[HIGH] Hero `MatchPosterCard`** — `home_hero_banner.dart:1218-1298`: hand-computed pixel budget (`extraHeightForGoals = 12 + rows*22`, clamped logo sizes) tuned for 1200/1600px widths; any drift → overflow inside the marquee TV surface.

### 1.3 Focus / D-pad gaps (TV navigability)

- **Good:** `dpad` package wired app-wide, `DpadRegion`s per screen, `TvFocusable`/`FocusableCard` primitives, player key handling complete.
- **[MEDIUM] Quick-settings sheet uses plain `InkWell`/`IconButton`** → no visible focus indicator on the most-used TV surface (`player_quick_settings_sheet.dart:172, 502-536, 553, 613`).
- **[MEDIUM] History delete is swipe-only** (`history_screen.dart:233-256`, `Dismissible`) — unnavigable by remote.
- **[LOW] Series details is a `DraggableScrollableSheet`** with no TV ordering or overscan padding (`series_screen.dart:426-434`).
- **[LOW] Camera QR mode offered on camera-less TV** (`companion_scanner_modal.dart:303-306`).
- **[LOW] Search double-autofocus** (`search_screen.dart:231-233` + `279-282`).

### 1.4 Other platform gaps

- **[HIGH] No TV overscan compensation**: `MediaQuery.padding` is 0 on TV; shell header, player bars, and hero dots sit at the absolute screen edge — cut off on TVs with ~5% overscan.
- **[HIGH] Windows has no minimum window size** (`setMinimumSize` never called; `platform_io.dart:22-28`) and boots forced-fullscreen (`windows/runner/main.cpp:29-32`). Exit fullscreen → resizable to any size → phone-tuned fixed layouts overflow.
- **[HIGH] Zero text-scale protection** — combined with `configChanges: fontScale|density` in the manifest (no restart), large system fonts deterministically overflow the fixed-height chrome.
- **[MEDIUM] Web is the phone layout verbatim** (no responsive difference).

---

## 2. Design system (P1)

### 2.1 State of the system

The token layer in `lib/app/theme/` is genuinely good: `AppColors` (8pt-adjacent surfaces bg0-bg4, semantic live/success/warning), `AppSpacing` (8pt scale), `AppRadius` (semantic card=12/button=8/dialog=16/chip=20), locale-aware `AppTypography` (NotoSans/Cairo), `AppShadows`, `AppMotion` with a reduce-motion policy, `AppIcons`. Adoption: **81 of 84 UI files import it** — but only superficially:

| Token | Usages | Bypassed by |
|---|---|---|
| `AppColors` | 916 | 259 raw `Color(0x…)` literals + 606 raw `Colors.*` |
| `AppSpacing` | 271 | 420 literal `SizedBox` gaps, 324 `EdgeInsets` literals |
| `AppRadius` | 111 | **23 distinct literal radii** (tokens define 9) |
| `AppTypography` | **1** | **368 raw `TextStyle(`, 324 `fontSize:` literals (40+ sizes incl. 7.5, 11.5, 13.5)** |
| `AppShadows` | 1 | inline `BoxShadow`s |
| `.colorScheme` | 3 | everything |

`lib/core/design_system/tokens.dart` is dead (0 usages) **and contradicts** `AppColors` (different `warning`/`error` values) — a trap for future contributors.

### 2.2 Top user-visible flaws

1. **Poster cards quadruplicated with divergent visuals** — the core content of an IPTV app:
   - `features/home/widgets/cards/movie_card.dart:35` radius **16** (and near-identical `series_card.dart`)
   - `movies_screen.dart:427-437` `_MovieGridCard` radius **12**, heart 22, cache 170×255
   - `series_screen.dart:944+` `_SeriesPosterCard` (again)
   - `favorites_screen.dart:477` `_buildListCard` (hand-rolled 4th list tile)
   Same poster renders with different corner radii on Home vs Movies grid today.
2. **Accent color redeclared 11×** as `Color(0xFF00C2FF)` (`home_section_row.dart:153`, `search_screen.dart:274,288,433,437,490`, `kids_pin_dialog.dart:549,552`, `kids_mode_card.dart:284`, `remote_focus.dart:117,123`) plus 6 off-palette sibling blues (`00F0FF/0077FF/0072FF/0066FF/00E5FF/00B0FF/00A8DE`).
3. **"Live green" is three different greens** — `0xFF00FF87` (`channel_card.dart:100-102`), `0xFF10B981` (8× in `home_tv_discovery_badge.dart`), `0xFF00E676` (`category_card.dart:342-348`) vs the token `AppColors.live`.
4. **Dark-only, with a dead theme preference** — `app.dart:209-212` hardwires `ThemeMode.dark`; `preferences_storage.dart:102` exposes a `themeMode` setting nothing reads. Light mode today = rewrite.
5. **Hardcoded English in Arabic-first UI** — companion scanner `'TV IP Address'/'Cancel'/'Connect'` (`companion_scanner_modal.dart:1017-1069`), `'PLAYING'/'LIVE'` badges over Arabic channel names (`channel_card.dart:89,99`), `'Copy'` (`update_dialog.dart:1232`), `'All ($total)'` (`search_screen.dart:377`). ~63 strings bypass the 567-key ARB.
6. **RTL leaks** — 7 `EdgeInsets.only(left/right:)` (e.g. `history_screen.dart:238` swipe rail, `app_shell.dart:380`), 40 directional `Alignment.centerLeft/right`, 14 `TextDirection.ltr` hardcodes including a non-numeric history row (`history_screen.dart:301`); hero copy anchors to the wrong side in RTL (`home_hero_banner.dart:1839,1896`).
7. **`_ActionButton` in the update dialog re-implements the themed button** with its own focus/keys and idle color `0xFF00A8DE` (`update_dialog.dart:800-851`).
8. **`category_card.dart` (a *shared* widget) violates the system** — 18 raw colors and a private palette switch (`:338-348`); every category chip inherits the drift.
9. **Skeleton flash** — `skeleton_loaders.dart:290` hardcodes `0xFF10131B` instead of `AppColors.bg1/bg2` → visible color jump when content loads; same color duplicated in `channel_card.dart:43`, `channel_list_tile.dart:53`.
10. **Icons: two systems** — 162 `HugeIcon` vs 78 raw Material `Icons.*` (account, handoff, kids, settings), 20+ ad-hoc icon sizes (11.5, 13.5, 19, 92).
11. **Language picker implemented 3×** — `settings_screen.dart:708-751`, `onboarding_screen.dart:275-281`, `auth_language_switcher.dart:43-48`, each styled differently.
12. **Error presentation inconsistent by construction** — `shared/widgets/error_view.dart` has exactly one consumer; features show failures through `EmptyState` or ad-hoc layouts.

### 2.3 The god files (biggest regression risk)

- `home_hero_banner.dart` — **2830 lines, 27 classes**: carousel Timer + 4 slide layouts + ~20 match subwidgets + 65 raw colors; also imports player/handoff (feature leak).
- `companion_scanner_modal.dart` — 1444 lines mixing `dart:io`, dio, Supabase, camera lifecycle, QR parsing, timers in one State.
- `update_dialog.dart` — 1257 lines, 10 classes (two full screens + 4 widgets).
- `settings_screen.dart` — 1232 lines, 10 classes including a hero server banner and system info card.
- `onboarding_screen.dart` — 1089 lines including URL-scheme validation logic inside paint code.
- `player_controls.dart` — 1123 lines; `series_screen.dart` — 1034; `app_shell.dart` — 968.

---

## 3. Architecture & code quality (P1/P2)

1. **[CRITICAL] Catalog triad is copy-paste³** — `live_controller.dart` (279), `movies_controller.dart` (285), `series_controller.dart` (281) are structurally identical (same state shape, same debounce field, same `loadData` flow, identical private `_filterNameIndexes` isolate entrypoints), and their screens repeat the same skeleton. Any fix must be applied 3-4×. A generic `CatalogController<T>` + parameterized screen deletes ~800 lines and one bug surface.
2. **[HIGH] Errors are structurally invisible** — **121** empty `catch (_)` blocks repo-wide; repositories' `Result.Err` values folded to `err: (_) => <Movie>[]` (27 occurrences) so controllers only set `error` on *thrown* exceptions. `movies_screen.dart` and `live_screen.dart` never read `state.error` — network-down renders as an empty catalog with no retry affordance. Only Home surfaces errors.
3. **[HIGH] Presentation is hard-coupled to the datasource** — 7 screens import `data/datasources/xtream_remote_datasource.dart` and call static URL builders directly (`home_screen.dart:580,601,625,660,678`, `live_screen.dart:111`, `movies_screen.dart:79`, etc.) instead of a domain service.
4. **[HIGH] Cross-feature imports everywhere** — screen→screen (`home_screen.dart:27` → `series_screen.dart`), widget→widget (`home_hero_banner.dart:19` → kids_mode), player/handoff → `features/auth` + `features/home`, bidirectional kids ↔ catalog_filter. No boundary rule or lint.
5. **[HIGH] `lib/app/providers.dart` is a 418-line god composition root** importing datasources, repo impls, domain, **and feature internals** (6 kids_mode files, account/entitlement/update controllers).
6. **[HIGH] Drift DB is ~90% dead** — 7 tables defined, 9,141 generated lines; only `watchHistory` and `favorites` are ever read/written. Catalog data actually lives in a parallel JSON disk cache (`local_catalog_cache.dart`). Misleading and heavy.
7. **[MEDIUM] Two Riverpod eras coexist** — 18 `StateNotifier` vs 17 `Notifier`, ~5 `autoDispose` total. Catalog controllers are keep-alive holding full catalogs (`HomeState` = 9 lists), recreated wholesale on session/kids transitions.
8. **[MEDIUM] Static mutable caches inside repo impls** (`series_repository_impl.dart:27-32`, same in live/vod) — survive session switches (server A's catalog can leak into server B's UI), invisible to Riverpod, uninvalidatable; background refetches end in `.catchError((_) {})`.
9. **[MEDIUM] `core/cache/local_catalog_cache.dart` imports `data/mappers`** — inverted dependency; mapping responsibility split across two layers.
10. **[MEDIUM] Duplicate favorites notifiers** — `favorite_ids.dart` (generic by `FavoriteType`) *and* `favorite_channel_ids.dart` (identical logic hardcoded to channel).
11. **[LOW-MEDIUM] 12 orphaned files** — including the dead responsive toolkit (`adaptive_scaffold.dart`, `app_layout.dart`), `focusable_button.dart`, `loading_indicator.dart`, `channel_overlay.dart`, `home_tv_discovery_badge.dart`, `api_result.dart`, `navigation_intent.dart`, `string_extensions.dart`, `cache_service.dart`. Plus repo-root junk: `lib.zip`, `lib (2).zip`, `flutter_01.log`.
12. **[LOW] `lib/repositories/matches_repository.dart`** sits outside the data layer importing datasources directly; referenced only by `app/providers.dart:153`. Merge into `data/repositories/`.
13. **[LOW] `lib/player/` vs `lib/features/player/`** — bridge, not duplication, but breaks the codebase's own convention; handoff modules reach back into features.

### What's already good (keep it)

- 64 test files / 327 test cases (though zero on the catalog triad, `home_controller`, hero banner, cache, and DB — i.e., the riskiest code).
- Large-JSON parsing consistently on isolates via `compute()` in all repo impls.
- One disciplined `CachedImage` with `memCacheWidth/Height` caps + per-device-tier image cache budget in `bootstrap.dart:86-90`.
- `home_screen.dart` uses `ref.watch(provider.select(...))` per row — good rebuild discipline.
- `Result`/error typing, strict lint config, dispose hygiene in player/home is solid.

---

## 4. Performance (P2 — the app is mostly fast already)

1. **History prune runs on every position save** — `history_repository_impl.dart:143-160` does select-all → sublist → delete, invoked from `updatePosition()` which the player calls on a timer. Replace with a single `DELETE … WHERE id NOT IN (SELECT id … ORDER BY watchedAt DESC LIMIT n)` or prune on app start / interval.
2. **Keep-alive catalog providers re-fetch everything** on session/kids transitions (finding 3.7); pair with `autoDispose` or explicit invalidation.
3. **DB on UI isolate** — drift calls run on the main isolate's connection; the prune fix plus batched writes covers the realistic hot path.
4. **No other systemic issues found** — image caching, isolate parsing, and rebuild discipline are in good shape.

---

## Roadmap

Sequenced so each phase ships user-visible value and de-risks the next. Effort is rough (1 dev).

### Phase 0 — Quick wins (1–2 days)
1. `windowManager.setMinimumSize(Size(720, 480))` in `platform_io.dart:22`; start Windows windowed at 1280×720 (`main.cpp`).
2. Clamp `textScaler` globally in `app.dart` builder: `MediaQuery(data: mq.copyWith(textScaler: TextScaler.linear(Math.min(mq.textScaler.scale(16)/16, 1.4))))`.
3. Delete repo-root junk (`lib.zip`, `lib (2).zip`, `flutter_01.log`) and the 12 orphaned files (after one grep each).
4. Add the two missing tokens: move `0xFF10131B` and LIVE green into `AppColors`; delete `core/design_system/tokens.dart`.
5. Replace the 11 accent literals + 6 sibling blues with `AppColors.accent` (mechanical grep-replace).
6. Fix the two most-visible flex errors: wrap shell-nav items in `Flexible`/`Wrap` (`app_shell.dart:370-455`) and add `Expanded` + ellipsis to `home_section_row.dart` titles.

### Phase 1 — TV & responsive foundations (1–2 weeks) ← *the reported problem*
1. **Make TV detection reactive and early**: call `PlatformService.initialize()` before `runApp`; expose form factor via Riverpod.
2. **One `FormFactor` enum** (`phone / tablet / desktop / tv`) derived from width + height + `isTv`, consumed by a revived `AppBreakpoints` — wire the dead toolkit in instead of deleting it.
3. **TV viewport strategy**: either (a) a `MediaQuery` design-size remap in `MaterialApp.builder` (design 400dp → render 960dp), or (b) TV-specific typography/spacing scale (~1.5×). Pick one; apply once in the builder.
4. **Chrome budgets by factor, not pixels**: hero = `h × 0.45` on TV; row heights from `MediaQuery`; header/dock from a single `ChromeHeights.of(context)`; add a constant ~28px overscan inset in shell + player.
5. **Fix Pattern-B grids**: one shared `PosterCard` that scales from cell size; drop fixed `mainAxisExtent`/fixed-height internals in favorites/search/live grids.
6. **Player bar compact mode** with `Flexible`-guarded layout below 600px.
7. **D-pad gaps**: TvFocusable on quick-settings sheet + onboarding controls; remote-accessible history delete (focused item + select = delete affordance); gate QR camera mode on `!isAndroidTv`; fix search double-autofocus.
8. **Acceptance test**: app on a 960×540 TV profile (Android Studio TV emulator at 1080p/tvdpi) shows zero overflow stripes, all screens navigable by arrows/select, no clipped edges under 5% overscan.

### Phase 2 — Design system consolidation (1–2 weeks, parallelizable with Phase 1)
1. **Unify the poster card**: add radius/heart/cache params to `MovieCard`/`SeriesCard`; delete `_MovieGridCard`, `_SeriesPosterCard`, favorites' `_buildListCard` (~400 duplicated lines gone, consistency restored).
2. **Build `AppButton`** (from `update_dialog._ActionButton` + hero `_GlassButton` + settings segments) and route through the themed `ElevatedButtonTheme`.
3. **Route text through the theme**: add the missing semantic styles to cover the 40+ ad-hoc sizes; sweep raw `TextStyle(` → `textTheme.*` per feature folder.
4. **One `LanguagePicker`**, one `SectionHeader` (extract from `HomeSectionRow`'s locale-baked logic), one shared error/retry state.
5. **RTL sweep**: `EdgeInsetsDirectional`, `AlignmentDirectional`, remove non-numeric `TextDirection.ltr` hardcodes.
6. **l10n completion**: move the ~63 hardcoded strings (companion scanner first — visible to Arabic users).
7. **Decide theme mode**: wire `preferences_storage.themeMode` to a real `AppTheme.light` (start from existing `ColorScheme.dark`) or delete the preference.

### Phase 3 — Architecture cleanup (2–3 weeks)
1. **Generic catalog**: `CatalogController<T>` + one parameterized catalog screen for live/movies/series (deletes ~800 lines; add tests here since none exist).
2. **Error visibility contract**: ban empty `catch (_)` in features/data (lint); map `Result.Err` to UI error states with retry on every catalog screen.
3. **`StreamUrlBuilder` domain service** to break the 7-screen datasource coupling.
4. **Feature boundaries**: move cross-feature imports behind providers/abstractions; split `providers.dart` into per-domain composition roots; enforce with `import_lint` (or a CI check).
5. **State modernization**: migrate catalog/home controllers to `Notifier` + `autoDispose` where sensible; replace static repo caches with Riverpod-owned cache.
6. **DB honesty**: either implement the 5 unused tables' flows or delete the schema + regenerate.

### Phase 4 — Decomposition of god files (ongoing, opportunistic)
- Split `home_hero_banner.dart` into `hero_carousel/` (timer + paging) + `slides/` + `match/` subwidgets; extract data shaping into a controller. Same treatment for `update_dialog`, `settings_screen`, `onboarding_screen`, `companion_scanner_modal` (its QR/Supabase/IO concerns belong in infrastructure).
- Rule of thumb going forward: one widget class per file, files < 400 lines, no `dart:io`/dio imports in presentation files.
- Add tests to each extracted unit (the current untested files are exactly the ones being split).

### Tracking suggestion
Create one GitHub issue per phase item; keep Phase 0 as a single PR. Phase 1 should land behind no flag (it's a fix, not a feature) but verify against the TV emulator profile before tagging the next release.
