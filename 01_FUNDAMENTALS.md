# IPTV Flutter App — Fundamentals Instructions for LLM Agent

## 1. Role

Act as a senior Flutter architect, media application engineer, performance engineer, and cross-platform UX engineer.

Your job in this phase is to build the **foundation only** for a premium IPTV client.

Target platforms:

- Android Phone / Tablet
- Android TV / Google TV
- Windows
- Web

The application is **landscape / horizontal-first on every platform**.

Do not implement the full feature set in this phase. Build a stable foundation that the next agent can use to implement features without restructuring the project.

---

# 2. Product Goal

Build a lightweight, fast, premium IPTV client.

Core principles:

1. Fast startup.
2. Fast perceived response.
3. Local-first metadata.
4. Reliable playback architecture.
5. Excellent horizontal UX.
6. Excellent D-pad navigation.
7. Excellent keyboard/mouse navigation.
8. Excellent touch navigation.
9. Arabic + English.
10. Proper RTL/LTR.
11. Clean and scalable Flutter architecture.
12. No unnecessary complexity.

The application must feel like a modern OTT/media-center product, not a generic IPTV utility.

Use established IPTV/OTT patterns as inspiration, but create an original UI.

---

# 3. Hard Requirements

## 3.1 Landscape

The app is horizontal-first.

Do not build a portrait-first interface.

For Android:

- Prefer landscape orientation.
- Support both landscape directions where practical.
- Do not create a full portrait application.

For Web/Windows:

- Optimize for horizontal windows.
- If the viewport is extremely narrow, show a lightweight "expand window / rotate device" state instead of building a second complete portrait UI.

---

# 4. Architecture

Use feature-first architecture with clear boundaries.

Recommended structure:

```text
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── logging/
│   ├── network/
│   ├── platform/
│   ├── localization/
│   ├── storage/
│   ├── cache/
│   └── utils/
│
├── data/
│   ├── api/
│   ├── datasources/
│   ├── models/
│   ├── mappers/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── player/
│   ├── player.dart
│   ├── player_controller.dart
│   ├── player_state.dart
│   ├── player_source.dart
│   ├── player_error.dart
│   └── platform/
│
├── shared/
│   ├── widgets/
│   ├── layouts/
│   ├── focus/
│   ├── navigation/
│   └── extensions/
│
└── features/
    └── ...
```

Do not put business logic inside widgets.

Do not create one giant `utils.dart`.

Do not create one giant `services.dart`.

---

# 5. State Management

Use Riverpod or the project's already-selected equivalent.

Rules:

- Widgets consume state.
- Controllers/Notifiers perform actions.
- Repositories handle data access.
- Use cases handle domain operations.
- API clients handle HTTP.
- Database layer handles persistence.

Conceptual flow:

```text
Widget
  ↓
Controller / Notifier
  ↓
Use Case
  ↓
Repository
  ↓
Local DB / API
```

Player flow:

```text
Player UI
  ↓
Player Controller
  ↓
Player Adapter
  ↓
Platform Media Engine
```

Never put raw HTTP requests directly inside UI widgets.

---

# 6. Routing

Use declarative routing.

Create route infrastructure now even if many screens are placeholders.

Minimum route model:

```text
/onboarding
/login
/home
/live
/guide
/movies
/series
/search
/favorites
/history
/settings
/player
```

Do not create platform-specific navigation trees.

Use one application navigation model with platform-specific interaction behavior.

---

# 7. Platform Detection

Create a clean platform abstraction.

The application must be able to determine:

```text
Android
Android TV
Windows
Web
```

Do not scatter:

```dart
if (Platform.isWindows)
```

throughout the codebase.

Create platform capabilities/abstractions.

Examples:

```text
PlatformType
isTv
supportsHardwareBack
supportsKeyboard
supportsRemote
supportsFullscreen
supportsPip
supportsNativePlayer
```

The exact API can be designed according to the chosen packages and Flutter version.

---

# 8. Responsive / Adaptive Layout

Build a central responsive system.

Suggested breakpoints:

```text
Compact Landscape: < 900
Standard Landscape: 900–1400
Wide Desktop: > 1400
```

Do not use dozens of arbitrary breakpoints.

Create reusable concepts:

```text
AppBreakpoints
AppLayout
AdaptiveScaffold
ResponsiveBuilder
```

The same design system should work across:

- Android phone landscape.
- Android TV.
- Windows.
- Web.

---

# 9. Navigation Inputs

Create a unified input layer.

Inputs:

```text
Touch
Mouse
Keyboard
D-pad
Remote
Controller
```

Create abstractions for navigation intent.

Examples:

```text
moveFocusUp
moveFocusDown
moveFocusLeft
moveFocusRight
select
back
playPause
nextChannel
previousChannel
openGuide
openSearch
toggleFullscreen
```

Do not hardcode remote logic into individual screens.

---

# 10. Android TV Focus System

Build a reusable focus system.

Requirements:

- Visible focused state.
- Predictable directional navigation.
- No focus traps.
- No dead ends.
- Back behavior is predictable.
- Dialogs manage focus correctly.
- Lists restore previous focus where practical.

Create reusable widgets such as:

```text
FocusableCard
FocusableListItem
FocusableButton
FocusGroup
```

The focus effect should be part of the design system.

Do not use giant scale animations.

---

# 11. Design System

Create a centralized design system.

Suggested files:

```text
app/theme/
├── app_theme.dart
├── app_colors.dart
├── app_typography.dart
├── app_spacing.dart
├── app_radius.dart
├── app_shadows.dart
└── app_motion.dart
```

Visual direction:

- Premium dark media-center UI.
- Minimal.
- Clean.
- High contrast.
- One main accent color.
- Subtle borders.
- Moderate corner radius.
- No excessive gradients.
- No excessive glassmorphism.
- No noisy animations.

Suggested spacing system:

```text
4
8
12
16
20
24
32
40
48
64
```

Use the system consistently.

---

# 12. Localization

Support:

```text
Arabic
English
```

from the beginning.

Requirements:

- Full RTL support.
- Full LTR support.
- No hardcoded user-facing strings.
- Layouts must survive long translations.
- Mixed Arabic/English text must be handled correctly.
- EPG/channel metadata may contain mixed scripts.

Use Flutter's official localization approach or the project's established localization solution.

Suggested:

```text
lib/l10n/
├── app_en.arb
└── app_ar.arb
```

Do not use manual string maps scattered around the application.

---

# 13. Typography

Choose a font that supports Arabic and Latin well.

The typography system must define:

```text
Display
Heading
Title
Body
Label
Caption
```

Do not hardcode font sizes randomly.

The UI should remain readable on:

- 6–8 inch landscape Android screens.
- TV from typical viewing distances.
- Windows monitors.
- Web browsers.

---

# 14. Networking Foundation

Use a robust HTTP client such as Dio or the project's approved equivalent.

Create:

```text
ApiClient
ApiConfig
ApiResult
ApiException
NetworkStatus
RequestInterceptor
```

Requirements:

- Timeouts.
- Retry only where safe.
- Structured errors.
- Logging in debug mode.
- No sensitive credentials in logs.
- Request cancellation where useful.

Never retry endlessly.

Do not log:

- Passwords.
- Tokens.
- Full authenticated URLs.
- Sensitive account data.

---

# 15. IPTV API Abstraction

Do not tie the entire app to one server implementation.

Create interfaces around IPTV data.

Example concepts:

```text
IptvRepository
AuthRepository
LiveRepository
EpgRepository
VodRepository
SeriesRepository
```

The implementation can initially target the server's supported IPTV API, such as Xtream-style APIs and M3U/XMLTV sources.

The UI must not know whether data came from:

- Xtream API.
- M3U.
- XMLTV.
- Local database.

---

# 16. Data Models

Create clean domain entities.

At minimum prepare models/entities for:

```text
Account
ServerConfig
Category
Channel
EpgProgram
Movie
Series
Season
Episode
Favorite
WatchHistory
```

Keep API DTOs separate from domain entities.

Example:

```text
API DTO
  ↓
Mapper
  ↓
Domain Entity
```

Do not expose raw API JSON maps throughout the application.

---

# 17. Local Database

Use SQLite through Drift or another strongly typed SQLite layer.

Prepare the database foundation for:

```text
accounts
categories
channels
epg_programs
movies
series
seasons
episodes
favorites
watch_history
settings
sync_metadata
```

Add sensible indexes.

Do not preload massive datasets into memory.

The database must be able to handle thousands of channels and large EPG datasets.

---

# 18. Local-First Strategy

The application must be able to open with cached data.

Startup:

```text
App start
 ↓
Initialize minimum dependencies
 ↓
Open local database
 ↓
Load settings/account
 ↓
Render application shell
 ↓
Render cached data
 ↓
Start background sync
 ↓
Apply incremental updates
```

Do not make the splash screen wait for the entire IPTV server synchronization.

---

# 19. Cache Architecture

Create separate cache concepts:

```text
Metadata Cache
Image Cache
EPG Cache
Player/stream state
```

Metadata cache:

- Categories.
- Channels.
- Movies.
- Series.

Image cache:

- Channel logos.
- Movie posters.
- Series posters.

Do not download thousands of images at startup.

Use lazy loading and caching.

---

# 20. Image Strategy

Build a reusable image widget.

Requirements:

- Memory cache.
- Disk cache.
- Placeholder.
- Error state.
- Lazy loading.
- Avoid layout jumps.

Channel logos should have a consistent visual container.

Poster cards should preserve aspect ratio.

Do not repeatedly decode the same large image.

---

# 21. Logging

Create a structured logging abstraction.

Levels:

```text
debug
info
warning
error
```

Production logging must not expose credentials or sensitive URLs.

Add useful context:

```text
feature
operation
platform
error type
duration
```

Avoid logging every widget rebuild.

---

# 22. Error Handling

Create a unified error model.

Examples:

```text
NetworkError
AuthenticationError
ServerError
ParsingError
PlaybackError
TimeoutError
DatabaseError
UnsupportedPlatformError
```

UI should translate errors into user-friendly messages.

Do not expose raw stack traces to users.

For playback:

```text
Trying to connect...
Reconnecting...
Stream unavailable
```

rather than a generic crash.

---

# 23. Player Foundation

Do NOT implement a fake player.

Create a real abstraction.

Required conceptual API:

```text
initialize()
setSource()
play()
pause()
stop()
seek()
setVolume()
mute()
setFullscreen()
dispose()
retry()
```

State:

```text
idle
loading
buffering
playing
paused
completed
error
disposed
```

The player implementation must be platform-aware.

Important:

- Android can use a native/hardware-accelerated media engine.
- Windows requires a compatible desktop media implementation.
- Web must respect browser media capabilities.
- Do not assume all codecs/protocols work on every platform.

Keep player implementation replaceable.

---

# 24. Player Performance Rules

The player must:

- Prefer hardware acceleration where supported.
- Avoid rebuilding the entire screen on player state changes.
- Separate player state from page state.
- Recover from temporary network interruptions.
- Avoid unnecessary buffering indicators.
- Provide clear buffering status.
- Dispose resources correctly.

Never leave media controllers/listeners alive after a screen is disposed.

---

# 25. Performance Budget

Treat performance as a feature.

Measure:

- Cold startup.
- Warm startup.
- First cached content render.
- First channel list render.
- Search latency.
- EPG render latency.
- Player initialization.
- Channel switch latency.
- Memory usage.
- Frame rendering performance.

Avoid:

- Huge widget trees.
- Unbounded lists.
- Rebuilding the entire Home screen.
- Parsing giant payloads on UI isolate.
- Loading all images at once.
- Network calls during every build.

Use lazy lists and granular state updates.

---

# 26. Security Basics

Even though this is a client application:

- Never commit server passwords.
- Never commit production tokens.
- Never put secrets in source control.
- Never print credentials in logs.
- Use secure storage where appropriate on native platforms.
- Treat Web storage as less secure than native secure storage.
- Never embed master server credentials in the application.

The client should only use credentials supplied/configured legitimately by the user.

---

# 27. Initial Screens

In the fundamentals phase, create polished but minimal shells for:

1. Splash/bootstrap.
2. Onboarding/login.
3. Home.
4. Live TV.
5. Guide.
6. Movies placeholder.
7. Series placeholder.
8. Search placeholder.
9. Favorites placeholder.
10. History placeholder.
11. Settings.
12. Player shell.

These are foundation screens, not the final feature implementations.

---

# 28. Home Shell

Home should establish the visual system.

Suggested layout:

```text
┌───────────────────────────────────────────────────────────────┐
│ LOGO   HOME   LIVE   MOVIES   SERIES   GUIDE   SEARCH   ⚙   │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│                     MAIN CONTENT                              │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│ Favorites     Continue Watching     Live Now     History      │
└───────────────────────────────────────────────────────────────┘
```

Use realistic mock/local data only for the foundation.

Do not hardcode mock data into production repositories.

---

# 29. Definition of Done — Fundamentals

Do not move to feature implementation until:

- [ ] Flutter project runs on Android.
- [ ] Flutter project runs on Android TV.
- [ ] Flutter project runs on Windows.
- [ ] Flutter project runs on Web.
- [ ] Landscape-first UX is established.
- [ ] Routing works.
- [ ] Localization works in Arabic and English.
- [ ] RTL/LTR switching works.
- [ ] Theme system exists.
- [ ] Responsive layout system exists.
- [ ] D-pad focus foundation works.
- [ ] Keyboard navigation foundation works.
- [ ] Mouse interaction works.
- [ ] Local database opens successfully.
- [ ] Network abstraction exists.
- [ ] IPTV data abstractions exist.
- [ ] Player abstraction exists.
- [ ] Cache foundation exists.
- [ ] Error handling foundation exists.
- [ ] Logging exists.
- [ ] No credentials are hardcoded.
- [ ] No major analyzer errors.
- [ ] No obvious memory leaks.
- [ ] No giant monolithic screen.
- [ ] No unnecessary platform-specific duplication.

---

# 30. Agent Working Rules

1. Inspect the existing repository before changing anything.
2. Do not delete working code without understanding it.
3. Reuse existing architecture if it is already better than the proposed one.
4. Keep commits/changes logically separated.
5. After each major architectural change, run analyzer/tests.
6. Do not continue after introducing unresolved compile errors.
7. Do not add dependencies unless they solve a real requirement.
8. Prefer stable, maintained Flutter packages.
9. Check platform support before adopting a package.
10. Do not use a package simply because it is popular on Android if it breaks Web/Windows.
11. Avoid overengineering.
12. Keep public interfaces small.
13. Write comments only where the reasoning is non-obvious.
14. Never place credentials in source code.
15. Never fabricate server/API behavior.
16. If a server-specific API behavior is unknown, isolate it behind an adapter and document the assumption.
17. Build the foundation so another agent can continue directly from it.

---

# 31. Deliverables

At the end of the fundamentals phase, provide:

1. Updated project structure.
2. Working cross-platform bootstrap.
3. Design system.
4. Localization system.
5. Routing system.
6. Platform abstraction.
7. Navigation/input foundation.
8. Database foundation.
9. Network/API foundation.
10. IPTV domain/data abstractions.
11. Cache foundation.
12. Player abstraction.
13. Initial screen shells.
14. Tests for important foundation components.
15. Short `ARCHITECTURE.md` documenting important decisions.
16. Short `SETUP.md` documenting how to run Android, Android TV, Windows, and Web.

Do not start implementing advanced IPTV features until the foundation passes the Definition of Done.
