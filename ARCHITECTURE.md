# IPTV Flutter App — Architecture Documentation

This document outlines the core architectural decisions, data flow patterns, and structural boundaries of the IPTV client application foundation.

---

## 1. Architectural Patterns & Principles

### Feature-First & Layered Architecture
The application uses a hybrid feature-first and clean layered architecture:
```text
lib/
├── app/          # App bootstrap, router, and design system (theme, colors, typography)
├── core/         # Cross-cutting concerns (platform detection, networking, logging, errors, storage, database, cache)
├── data/         # API clients, DTOs, data mappers, datasources, concrete repository implementations
├── domain/       # Core business entities, repository interfaces, and use cases
├── player/       # Abstract media player interface, state models, and platform adapters
├── shared/       # Focus system, input/navigation intents, responsive layouts, and reusable widgets
└── features/     # Feature screens (Splash, Onboarding, Home, Live TV, Guide, Movies, Series, Search, Favorites, History, Settings, Player)
```

### Unidirectional Data Flow
```text
UI Widget (ConsumerWidget)
   ↓ calls
Controller / Notifier / Use Case
   ↓ queries / executes
Repository Interface (Domain)
   ↓ implements
Repository Implementation (Data)
   ↓ orchestrates
Remote DataSource (Dio / Xtream API) ⇄ Local Database (Drift SQLite / SecureStorage)
```

---

## 2. Key Foundation Subsystems

### 2.1 State Management (Riverpod)
- **Granular Reactivity**: Widgets consume state selectively via `ConsumerWidget` and `ref.watch`.
- **Decoupled Lifecycle**: State notifiers manage domain workflows independently of widget trees.

### 2.2 Routing (Declarative GoRouter)
- 12 top-level routes declared in `lib/app/router.dart` with custom fade/instant transitions.
- All route navigation utilizes typed path constants from `Routes`.

### 2.3 Media Player Abstraction (`IPlayer`)
- UI depends solely on `IPlayer`, `PlayerState`, and `PlayerSource`.
- Implementation uses [`VideoPlayerAdapter`](file:///d:/PROJECTS/iptv/lib/player/platform/video_player_adapter.dart) backed by `video_player` (Google ExoPlayer/Media3 for Android & Android TV, Windows Media Foundation via `video_player_win`, HTML5 video on Web).
- The player implementation is completely swappable without touching screen widgets.

### 2.4 Platform Capabilities Abstraction (`PlatformService`)
- No scattered `Platform.isX` checks.
- Capabilities (`isTv`, `supportsKeyboard`, `supportsRemote`, `supportsPip`, `supportsNativePlayer`) provide unified feature queries across Android, Android TV, Windows, and Web.

### 2.5 Local-First Persistence & Caching
- **Drift (SQLite)**: 12 strongly typed tables with optimized composite indexes for high-volume channels and EPG queries.
- **SecureStorage**: Credentials and tokens encrypted using platform keystores.
- **PreferencesStorage**: Fast non-sensitive settings (locale, theme, player volume).
- **CacheService**: Centralized invalidation coordinator for metadata and EPG lifecycles.

### 2.6 TV Focus & Input Abstraction
- Unified input mapping from Touch, Mouse, Keyboard, and TV D-pads to `NavigationIntent` actions.
- Reusable `FocusableCard` and `FocusableButton` provide accessible focus rings, glow effects, and select handlers.

### 2.7 Multi-Language & RTL/LTR
- Native Flutter gen-l10n via `.arb` files (`app_en.arb`, `app_ar.arb`).
- Full support for Arabic right-to-left layout and English left-to-right layout.
