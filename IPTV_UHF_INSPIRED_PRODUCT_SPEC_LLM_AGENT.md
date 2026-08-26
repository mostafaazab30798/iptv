# IPTV App — UHF-Inspired Product, UI/UX & Feature Instructions

## Mission

Act as the lead Flutter product engineer, IPTV architect, UI/UX designer, and performance engineer.

Build a premium IPTV client for:

- Android Phone
- Android TV / Google TV
- Windows
- Web

Use UHF as a **product-quality reference**, not as a visual clone. Recreate useful product ideas and interaction principles while creating an original brand, layout, design system, copy, and visual identity.

The app is a legitimate media player for content the user is authorized to access.

---

## 1. Product Vision

The product should feel:

```text
FAST + CLEAN + CINEMATIC + TV-FIRST + CROSS-PLATFORM + RELIABLE
```

It must not feel like:

- A generic Flutter CRUD app.
- A mobile app stretched onto TV.
- A simple M3U list viewer.
- A pixel-perfect clone of another product.

Core promise:

> Get from opening the app to watching content with as little friction and waiting as possible.

---

## 2. Target Platforms

Primary targets:

```text
Android Phone
Android TV / Google TV
Windows
Web
```

The experience is landscape-first.

Do not design portrait first and rotate it later.

---

## 3. Product Principles

### Speed First

Prioritize:

- Cached metadata.
- Lazy lists.
- Image caching.
- Background parsing.
- Local search.
- Reusable player.
- Minimal rebuilds.
- Lightweight animations.

### Content First

Primary navigation:

```text
Home
Live
Movies
Series
Guide
Favorites
Search
Settings
```

### TV First

Android TV must be a real TV experience:

- Large focus targets.
- D-pad navigation.
- Strong focus states.
- Predictable Back behavior.
- Remote-friendly overlays.
- Large typography.

### Cinematic

Use:

- Backdrops.
- Posters.
- Channel logos.
- Hero content.
- Subtle gradients.
- Dark surfaces.
- High contrast.

### Minimal

Do not show every feature at once. Reveal controls contextually.

---

## 4. Original Visual Identity

Do NOT copy:

- UHF logo.
- UHF name.
- UHF exact colors.
- UHF exact typography.
- UHF exact card design.
- UHF exact screen layout.
- UHF exact illustrations.
- UHF marketing copy.

Create a new identity.

Recommended direction:

```text
Dark-first
Cinematic
Premium
Minimal
Soft surfaces
Large imagery
Subtle glass/blur
Strong focus states
Smooth horizontal navigation
```

---

## 5. Design System

Create semantic design tokens instead of hardcoding values.

### Colors

```text
AppColors
├── background
├── backgroundElevated
├── surface
├── surfaceElevated
├── border
├── textPrimary
├── textSecondary
├── textMuted
├── accent
├── accentSoft
├── success
├── warning
├── error
└── live
```

### Typography

```text
Display
Headline
Title
Body
BodySmall
Label
Caption
Numeric
```

Arabic and English must be first-class.

### Spacing

```text
xs
sm
md
lg
xl
xxl
```

### Radius

```text
small
medium
large
card
pill
```

Do not scatter arbitrary numbers throughout widgets.

---

## 6. Motion

Animations should be:

- Short.
- Purposeful.
- Interruptible.
- Low-cost.

Use motion for:

- Navigation transitions.
- Card focus.
- Overlay appearance.
- Hero transitions.
- Player controls.

Avoid animating everything.

---

## 7. Navigation

### Android TV

Use a left navigation rail or compact side navigation.

Example:

```text
┌──────┬──────────────────────────────────────┐
│ HOME │                                      │
│ LIVE │               CONTENT                │
│ MOV  │                                      │
│ SER  │                                      │
│ GUIDE│                                      │
│ FAV  │                                      │
│ SEARCH                                      │
│ ⚙    │                                      │
└──────┴──────────────────────────────────────┘
```

Focus must never get lost.

### Windows

Use:

```text
Sidebar + Content
```

Allow sidebar collapse.

### Web

Use responsive desktop navigation and adapt for narrower browser sizes.

---

## 8. Home Screen

Recommended sections:

```text
Hero
Continue Watching
Live Now
Favorites
Recently Added
Movies
Series
Sports
News
Custom Collections
```

Only render sections that contain content.

Never show empty carousels.

---

## 9. Hero

Hero should contain:

```text
Backdrop
Logo/poster
Title
Metadata
Description
Current status
Primary action
Secondary action
```

Example:

```text
┌──────────────────────────────────────────────────┐
│                                                  │
│              HERO BACKDROP                       │
│                                                  │
│       Channel / Movie Title                     │
│       LIVE • Sports                             │
│                                                  │
│       Description...                            │
│                                                  │
│       [ WATCH NOW ] [ GUIDE ]                   │
└──────────────────────────────────────────────────┘
```

Do not make the hero consume the entire screen.

---

## 10. Continue Watching

Show only if history exists.

For VOD:

```text
Poster
Title
Progress
Remaining
```

For Live:

```text
Channel logo
Channel
Current program
```

Use local history without unnecessary network calls.

---

## 11. Content Cards

Create reusable foundations:

```text
ContentCard
ChannelCard
MovieCard
SeriesCard
EpisodeCard
ProgramCard
```

States:

```text
normal
focused
hovered
pressed
selected
disabled
```

TV focus should be obvious but subtle.

---

## 12. Live TV

Recommended layout:

```text
┌──────────────┬────────────────────────────────────┐
│ Categories   │ Channels                           │
│              │                                    │
│ Sports       │ [1] [2] [3] [4]                    │
│ News         │ [5] [6] [7] [8]                    │
│ Movies       │ [9] [10][11][12]                   │
│ Kids         │                                    │
└──────────────┴────────────────────────────────────┘
```

Channel item:

```text
Logo
Number
Name
Current program
Favorite
```

Use lazy rendering for large channel lists.

---

## 13. Player

The player architecture is defined in the separate player instructions file.

The player UI should be:

```text
┌──────────────────────────────────────────────────┐
│                                                  │
│                    VIDEO                         │
│                                                  │
│                                                  │
│ Logo  Channel Name                         LIVE  │
│ Current Program                                  │
│──────────────────────────────────────────────────│
│ Prev  Play  Next  Audio  Subs  Guide  Fullscreen│
└──────────────────────────────────────────────────┘
```

Rules:

- Controls auto-hide.
- Hiding controls must not recreate the player.
- Overlay must be lightweight.
- Player remains landscape-first.
- Channel switching must feel immediate.

---

## 14. Android TV Player Controls

When overlay is hidden:

```text
Up    → previous channel
Down  → next channel
OK    → show controls
```

When overlay is visible:

```text
D-pad → navigate controls
OK    → activate
Back  → close overlay
```

For VOD/catch-up:

```text
Left  → rewind
Right → forward
```

Behavior must be context-aware.

---

## 15. EPG / Guide

EPG is a flagship feature.

Create a modern TV grid:

```text
             NOW          NEXT          LATER

Channel A   Program 1    Program 2     Program 3
            ████████

Channel B   Program A    Program B     Program C
            █████

Channel C   Program X    Program Y     Program Z
            █████████
```

Support:

- Horizontal time navigation.
- Vertical channel navigation.
- Current-time indicator.
- Program progress.
- Current-program highlight.
- Channel logos.
- Program details.
- Play.
- Catch-up where supported.

Use lazy/virtualized rendering for large EPG datasets.

---

## 16. Program Details

Show:

```text
Title
Channel
Start/end
Description
Genre
Progress
Watch
Catch-up if available
Favorite/reminder if supported
```

Use a bottom sheet or side panel depending on platform.

---

## 17. Search

Global search across:

```text
Channels
Movies
Series
Episodes
Programs
Categories
Favorites
```

Do not hit the server for every keypress.

Prefer:

```text
Local index
+
Debounced remote search where required
```

Results should be grouped:

```text
LIVE CHANNELS
MOVIES
SERIES
PROGRAMS
```

---

## 18. Favorites

Allow favorite from:

- Content card.
- Details.
- Player.
- EPG.

Store locally first.

Do not duplicate complete media objects; store IDs/references.

---

## 19. Content Management

Allow local presentation customization:

```text
Rename
Reorder
Favorite
Hide
Merge categories
Create custom groups
```

Never modify the user's original IPTV server data unless explicitly designed for that provider.

---

## 20. Custom Groups

Examples:

```text
My Sports
My News
Kids
Weekend
Favorites
```

Use references/IDs rather than duplicating media models.

---

## 21. Playlist Architecture

Support legitimate user sources.

Use provider abstractions:

```text
PlaylistProvider
├── XtreamProvider
├── M3UProvider
└── FutureProvider
```

The UI must depend on normalized application models, not provider-specific response models.

Bad:

```text
Widget → XtreamResponse
```

Good:

```text
Widget → Channel
```

---

## 22. Xtream Integration

Create separate services/repositories as needed:

```text
XtreamAuthService
XtreamLiveService
XtreamVodService
XtreamSeriesService
XtreamEpgService
```

Screens must not call raw endpoints.

Map provider responses into domain models.

---

## 23. M3U Integration

Parser responsibilities:

- Entries.
- Group/category.
- Logo.
- EPG identifier.
- Stream URL.
- Stream type.

Large files must not block the UI isolate.

---

## 24. Caching

Cache:

```text
Playlist metadata
Categories
Channels
Movies
Series
EPG
Images
Favorites
History
Preferences
```

Do not unnecessarily cache raw secrets.

Preferred refresh behavior:

```text
Open app
 ↓
Show cached content
 ↓
Refresh in background
 ↓
Update UI
```

---

## 25. Offline Behavior

When the network is unavailable, cached UI should remain useful.

Show cached:

- Categories.
- Favorites.
- Recently watched.
- Metadata.

Do not claim streams work offline unless a legitimate download system exists.

---

## 26. Smart Reconnect

The player should recover temporary stream interruptions.

Preferred UX:

```text
Interruption
 ↓
Silent reconnect
 ↓
Playback restored
```

If visible:

```text
↻ Reconnecting...
```

Never create infinite retry loops.

---

## 27. Audio and Subtitles

Only show selectors when tracks exist.

Example:

```text
Audio
├── Arabic
├── English
└── Original
```

```text
Subtitles
├── Off
├── Arabic
├── English
└── ...
```

Remember preferences where practical.

---

## 28. Catch-up / Timeshift

Treat these as playback modes:

```text
Live
Catch-up
VOD
```

EPG program:

```text
Program
 ↓
Catch-up
 ↓
Player
```

Do not show catch-up controls when unsupported.

---

## 29. Multi-View

Future feature:

```text
┌─────────────┬─────────────┐
│ Stream 1    │ Stream 2    │
├─────────────┼─────────────┤
│ Stream 3    │ Stream 4    │
└─────────────┴─────────────┘
```

Do not sacrifice single-player performance to prepare for multiview.

---

## 30. Settings

Organize:

```text
Playback
Interface
Language
Content
EPG
Parental Controls
Network
Diagnostics
About
```

Do not build one giant settings page.

---

## 31. Playback Settings

Potential settings:

```text
Auto play
Resume last channel
Auto fullscreen
Preferred audio language
Preferred subtitle language
Buffering profile
Aspect ratio
```

Only expose settings supported by the current platform/backend.

---

## 32. Language / RTL

Support:

```text
English
Arabic
```

Arabic must be true RTL.

Test carefully:

- Navigation.
- Player controls.
- EPG.
- Search.
- Mixed Arabic/English titles.
- Numbers.
- Times.
- Progress indicators.

Do not blindly mirror everything.

---

## 33. Parental Controls

If implemented:

```text
PIN
Locked categories
Hidden channels
Hidden content
```

Never store PINs as plain text.

Locked content must also disappear from search results where appropriate.

---

## 34. Diagnostics

Create:

```text
Settings → Diagnostics
```

Debug information can include:

```text
API status
Playlist status
EPG status
Player status
Stream type
First frame time
Channel switch time
Buffering count
Last error
```

Never expose credentials or authenticated URLs.

---

## 35. Error UX

Never show raw exceptions such as:

```text
DioException
SocketException
FormatException
```

User-facing example:

```text
We couldn't load this content.

Check your connection or try again.

[ Retry ]
```

Technical information belongs in diagnostics.

---

## 36. Empty States

Every empty section needs intentional UX.

Examples:

```text
No favorites yet.
Add channels or shows to access them quickly.
```

```text
No EPG data available.
```

```text
No results.
Try another title or channel.
```

Never leave unexplained blank areas.

---

## 37. Loading States

Use:

- Skeletons for content.
- Lightweight loading indicators.
- Dedicated buffering UI for video.

Do not use generic spinners everywhere.

---

## 38. Image Loading

Cache:

```text
Channel logos
Posters
Backdrops
```

Images must never block playback.

On failure:

```text
Fallback icon / placeholder
```

Do not retry forever.

---

## 39. Responsive Layout

Create semantic breakpoints:

```text
compact
medium
large
tv
```

### Compact

- Smaller navigation.
- Fewer columns.

### Large

- Sidebar.
- More columns.
- Larger hero.

### TV

- Large typography.
- Large focus targets.
- D-pad navigation.
- Wide spacing.

Do not write dozens of arbitrary width conditions.

---

## 40. Accessibility

Every interactive element needs:

- Semantic label.
- Focus support.
- Keyboard support where relevant.
- Adequate target size.
- Clear focus state.

Examples:

```text
Play
Pause
Mute
Next channel
Previous channel
Open guide
Search
Favorite
Fullscreen
```

---

## 41. State Management

Use the existing project's state management solution if it is already established.

Separate:

```text
UI state
Content state
Player state
Network state
Settings state
```

Do not create one giant global controller.

---

## 42. Architecture Boundary

Preferred:

```text
Presentation
    ↓
Application
    ↓
Domain
    ↓
Infrastructure
```

Examples:

```text
LiveScreen
 ↓
LiveController
 ↓
LiveRepository
 ↓
XtreamProvider
```

Player:

```text
PlayerView
 ↓
PlayerController
 ↓
PlayerEngine
 ↓
media_kit
```

---

## 43. Performance

Measure:

```text
App startup
First content render
Search latency
EPG scroll performance
Channel switch latency
Player first frame
Memory
```

Never optimize based only on assumptions.

---

## 44. Rendering Rules

Never:

- Put API calls in `build()`.
- Parse playlists in `build()`.
- Query databases in `build()`.
- Create controllers in `build()`.
- Recreate the player because an overlay changed.
- Rebuild the whole home screen because one card changed.

Use granular rebuild boundaries.

---

## 45. Focus System

Create reusable focus behavior.

Support:

```text
FocusScope
FocusNode
Directional navigation
Selected state
Hover state
Pressed state
```

Test:

```text
Up
Down
Left
Right
OK
Back
```

Focus must never become trapped unintentionally.

---

## 46. Back Button

Suggested behavior:

```text
Player controls visible
 ↓ Back
Hide controls

Controls hidden
 ↓ Back
Exit player

Modal open
 ↓ Back
Close modal

Search active
 ↓ Back
Close search

Home
 ↓ Back
Platform default
```

Adapt to platform conventions.

---

## 47. Search Ranking

Normalize and index content.

Rank:

1. Exact title.
2. Prefix.
3. Token match.
4. Fuzzy match.

Keep the initial implementation simple and fast.

---

## 48. Personalization

Future sections:

```text
Continue Watching
Recently Watched
Favorites
Because You Watch
Live Now
Recommended
```

Do not add AI recommendations until meaningful user behavior data exists.

---

## 49. Feature Roadmap

### Phase 1 — Core

```text
Home
Live TV
Player
EPG
Search
Favorites
Settings
```

### Phase 2 — Content

```text
Movies
Series
Details
Continue Watching
History
Content Management
```

### Phase 3 — Advanced

```text
Catch-up
Timeshift
Multi-audio
Subtitles
Smart Reconnect
Custom Groups
```

### Phase 4 — Premium

```text
Multi-view
Casting
Cross-device sync
DVR
Advanced personalization
```

Do not start Phase 4 before Phase 1 is stable.

---

## 50. Agent Workflow

Before coding:

1. Inspect repository.
2. Inspect Flutter/Dart versions.
3. Inspect existing architecture.
4. Inspect IPTV API layer.
5. Inspect existing models.
6. Inspect navigation.
7. Inspect state management.
8. Identify reusable components.
9. Identify duplicate functionality.
10. Create implementation plan.

Then implement:

```text
Design tokens
 ↓
Primitives
 ↓
Reusable components
 ↓
Navigation
 ↓
Home
 ↓
Live TV
 ↓
Player integration
 ↓
EPG
 ↓
Search
 ↓
Favorites
 ↓
Movies/Series
 ↓
Settings
 ↓
Advanced features
```

Run analyzer and tests after meaningful changes.

---

## 51. Do Not Rewrite Working Architecture

If the existing project already has a good:

- API layer.
- Repository layer.
- State management.
- Localization.
- Routing.
- Theme system.

reuse it.

Do not create duplicate systems.

If this specification conflicts with existing clean architecture, adapt the specification and document the deviation.

---

## 52. Do Not Clone UHF

Use UHF as research/reference for:

- Product hierarchy.
- Feature prioritization.
- EPG concepts.
- Content management.
- Search concepts.
- Reconnect behavior.
- Advanced playback ideas.

Create original:

- Branding.
- Colors.
- Typography.
- Layouts.
- Component styling.
- Animations.
- Copy.
- Navigation details.

The objective is:

```text
UHF-level product thinking
+
Original visual identity
+
Flutter cross-platform
+
Android TV first-class support
+
Excellent playback performance
```

---

## 53. Definition of Done — UI/UX

- [ ] Original design system.
- [ ] Dark theme.
- [ ] Semantic colors.
- [ ] Typography.
- [ ] Spacing.
- [ ] Reusable cards.
- [ ] Navigation.
- [ ] Home.
- [ ] Live TV.
- [ ] Player.
- [ ] EPG.
- [ ] Search.
- [ ] Favorites.
- [ ] Movies.
- [ ] Series.
- [ ] Settings.
- [ ] Arabic.
- [ ] English.
- [ ] RTL.
- [ ] Android TV focus.
- [ ] Windows keyboard.
- [ ] Web responsiveness.
- [ ] Loading states.
- [ ] Empty states.
- [ ] Error states.
- [ ] Accessibility labels.

---

## 54. Definition of Done — Performance

- [ ] Smooth scrolling.
- [ ] No unnecessary full-screen rebuilds.
- [ ] Image caching.
- [ ] Lazy content rendering.
- [ ] EPG virtualization/lazy loading.
- [ ] Background playlist parsing where required.
- [ ] Local search.
- [ ] Reused player for channel switching.
- [ ] Correct disposal.
- [ ] No obvious memory leaks.
- [ ] Channel-switch latency measured.
- [ ] First-frame latency measured.

---

## 55. Platform QA

### Android

- [ ] Real phone.
- [ ] Landscape.
- [ ] Back behavior.
- [ ] Network failure.
- [ ] Player.

### Android TV

- [ ] Real TV/device.
- [ ] D-pad.
- [ ] Focus traversal.
- [ ] Remote Back.
- [ ] Player.
- [ ] EPG.

### Windows

- [ ] Mouse.
- [ ] Keyboard.
- [ ] Fullscreen.
- [ ] Resize.
- [ ] Player.

### Web

- [ ] Chromium.
- [ ] Autoplay.
- [ ] HTTPS.
- [ ] CORS.
- [ ] Responsive layout.
- [ ] Unsupported-stream behavior.

---

## 56. Security

Never:

- Commit credentials.
- Log passwords.
- Log authenticated URLs.
- Send credentials to analytics.
- Put secrets in source code.
- Bypass authentication.
- Bypass DRM.
- Circumvent access controls.

The app is a player, not a content provider.

---

## 57. Final Product Standard

The user experience should be:

```text
Open app
   ↓
Content appears quickly
   ↓
Choose content
   ↓
Playback starts quickly
   ↓
Controls stay out of the way
   ↓
Channel switching feels fast
   ↓
EPG is intuitive
   ↓
Search feels immediate
   ↓
Favorites are one action away
   ↓
Temporary failures recover automatically
```

It should never feel like:

```text
Loading...
Loading...
Error...
Retry...
Loading...
```

---

## Final Instruction

Do not treat this document as a request to copy UHF.

Treat it as the product specification for an **original premium IPTV application inspired by proven modern IPTV UX patterns**.

Prioritize, in order:

1. Playback reliability.
2. Speed.
3. Android TV usability.
4. Content discovery.
5. EPG.
6. Search.
7. Favorites.
8. Cross-platform consistency.
9. Visual polish.
10. Advanced features.

Never sacrifice playback stability for visual effects.

Never sacrifice TV usability for mobile convenience.

Never sacrifice architecture for a quick demo.
