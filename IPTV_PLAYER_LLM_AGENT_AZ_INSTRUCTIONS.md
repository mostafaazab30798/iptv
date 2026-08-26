# IPTV Flutter Player System — A–Z LLM Agent Instructions

## Mission

Act as a senior Flutter media-engineer, IPTV architect, performance engineer, and cross-platform playback specialist.

Implement a production-grade IPTV playback subsystem for:

- Android Phone / Tablet
- Android TV / Google TV
- Windows
- Web

The app is a legitimate IPTV client for content the user/server is authorized to access.

The player must be a standalone subsystem, not tightly coupled to individual screens.

Primary backend:

- `media_kit`
- `media_kit_video`

The architecture must isolate platform-specific behavior and allow the playback backend to be replaced later.

---

## 1. Non-Negotiable Requirements

The player MUST:

- Support Android.
- Support Android TV.
- Support Windows.
- Support Web where browser/media capabilities permit.
- Be landscape-first.
- Support touch, mouse, keyboard, and D-pad/remote.
- Use hardware acceleration where supported.
- Support live IPTV streams.
- Support the server's `m3u8` and `ts` outputs.
- Handle buffering.
- Handle temporary network failures.
- Handle stream failures.
- Handle fast channel switching.
- Support fullscreen.
- Support volume and mute.
- Support audio tracks where available.
- Support subtitles where available.
- Expose platform capabilities.
- Avoid unnecessary rebuilds.
- Dispose all media resources correctly.
- Never expose credentials in logs.
- Never bypass authentication, DRM, or access restrictions.

---

## 2. Player Architecture

Do NOT let feature screens directly use `media_kit`.

Bad:

```text
LiveTVScreen
  ↓
media_kit
```

Required:

```text
Feature UI
  ↓
PlayerController
  ↓
PlayerService / SmartPlaybackEngine
  ↓
PlayerEngine interface
  ↓
MediaKitPlayerEngine
  ↓
media_kit
```

The rest of the application should depend on the application's player abstraction, not on `media_kit`.

---

## 3. Recommended Structure

Use the existing project structure if it is already clean. Otherwise:

```text
lib/player/
├── player.dart
├── domain/
│   ├── entities/
│   │   ├── player_source.dart
│   │   ├── player_position.dart
│   │   └── player_capabilities.dart
│   ├── enums/
│   │   ├── player_status.dart
│   │   ├── player_error_type.dart
│   │   └── playback_profile.dart
│   └── interfaces/
│       └── player_engine.dart
├── application/
│   ├── player_controller.dart
│   ├── player_state.dart
│   ├── playback_coordinator.dart
│   ├── channel_switch_controller.dart
│   └── player_capability_service.dart
├── infrastructure/
│   ├── media_kit_player_engine.dart
│   ├── stream_resolver.dart
│   ├── playback_retry_manager.dart
│   └── platform_player_adapter.dart
├── presentation/
│   ├── player_view.dart
│   ├── player_overlay.dart
│   ├── player_controls.dart
│   ├── buffering_indicator.dart
│   ├── player_error_view.dart
│   ├── channel_overlay.dart
│   ├── audio_track_selector.dart
│   ├── subtitle_selector.dart
│   └── fullscreen_player.dart
└── utils/
    ├── stream_type_detector.dart
    ├── playback_metrics.dart
    └── player_logger.dart
```

---

## 4. Dependencies

Before adding packages:

1. Inspect `pubspec.yaml`.
2. Inspect Flutter/Dart versions.
3. Check package compatibility.
4. Use the latest stable compatible versions.
5. Run dependency resolution.
6. Run analyzer/tests.

Do not add unnecessary player packages.

Primary dependencies:

```yaml
media_kit: <compatible-version>
media_kit_video: <compatible-version>
```

If platform-specific setup is required by the current package version, follow the package's official documentation rather than guessing.

---

## 5. Domain Layer

The domain layer must not import `media_kit`.

Create platform-independent concepts.

### PlayerSource

```text
PlayerSource
├── url
├── streamType
├── headers
├── title
├── channelId
├── categoryId
├── logoUrl
├── epgProgramId
└── metadata
```

Never store production secrets unnecessarily inside the source.

---

## 6. Stream Types

Normalize stream types:

```text
auto
hls
mpegTs
dash
file
unknown
```

The current IPTV server provides:

```text
m3u8
ts
```

Do not assume all servers use the same format.

---

## 7. Playback Profiles

Create:

```text
live
vod
catchUp
preview
```

### Live

Optimize for:

- Fast startup.
- Reasonable latency.
- Stable playback.
- Fast recovery.

### VOD

Optimize for:

- Stable buffering.
- Accurate seeking.
- Smooth scrubbing.
- Resume.

### Catch-up

Optimize for:

- Seeking.
- Resume.
- Timeline accuracy.

---

## 8. Player Status

Use one canonical player state:

```text
idle
initializing
loading
buffering
playing
paused
stopped
completed
error
disposed
```

Do not scatter unrelated booleans across widgets.

---

## 9. Player State

Expose:

```text
status
source
position
duration
bufferedPosition
volume
muted
isFullscreen
error
currentAudioTrack
currentSubtitleTrack
availableAudioTracks
availableSubtitleTracks
capabilities
metrics
```

Prefer immutable state.

---

## 10. Player Capabilities

Expose capabilities explicitly:

```text
playPause
seek
volume
fullscreen
audioTracks
subtitles
aspectRatio
pictureInPicture
liveSeek
retry
hardwareAcceleration
```

Web may support fewer capabilities than native platforms.

The UI must hide unsupported actions.

---

## 11. PlayerEngine Interface

Create a small interface, conceptually:

```dart
abstract interface class PlayerEngine {
  Future<void> initialize();
  Future<void> open(PlayerSource source);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> setMuted(bool muted);
  Future<void> retry();
  Future<void> dispose();
}
```

Add only methods actually needed by the application.

---

## 12. MediaKit Adapter

Implement:

```text
MediaKitPlayerEngine
```

Responsibilities:

- Create/configure the media_kit player.
- Open sources.
- Play/pause/stop.
- Seek.
- Volume/mute.
- Track selection.
- Dispose.
- Translate backend events into application state.

Keep raw media_kit types out of the domain layer.

---

## 13. Initialization and Lifecycle

Initialize the media framework once during app bootstrap according to the current package requirements.

Do not initialize the media framework for every channel.

Preferred lifecycle:

```text
App bootstrap
 ↓
Media subsystem initialized
 ↓
Player created
 ↓
Source opened
 ↓
Playing
 ↓
Source replaced / stopped
 ↓
Player disposed when no longer needed
```

Track and dispose:

- Player.
- Video controller.
- Event subscriptions.
- Timers.
- Focus nodes.
- Animation controllers.

---

## 14. Channel Switching

Channel switching is a flagship performance feature.

Prefer reusing the active player when safe:

```text
User selects channel
 ↓
Resolve source
 ↓
Open/replace source
 ↓
Reset required state
 ↓
Play
```

Do not destroy and recreate the entire player for every channel switch unless the backend requires it.

Do not aggressively preload multiple live channels unless measurements justify the bandwidth and server cost.

---

## 15. SmartPlaybackEngine

Create:

```text
SmartPlaybackEngine
```

Responsibilities:

1. Receive normalized channel/source data.
2. Resolve stream URL.
3. Detect stream type.
4. Inspect platform capabilities.
5. Select the appropriate source.
6. Apply playback profile.
7. Apply legitimate headers/options.
8. Start playback.
9. Monitor errors.
10. Trigger bounded recovery.

Flow:

```text
Channel
 ↓
StreamResolver
 ↓
SmartPlaybackEngine
 ↓
Capability check
 ↓
PlayerEngine
 ↓
Playback
```

---

## 16. Stream Resolver

IPTV-specific URL construction belongs here.

Input may include:

```text
server
username
password
channelId
stream format
```

Output:

```text
PlayerSource
```

Never construct authenticated stream URLs in widgets.

Never log the final authenticated URL.

Prefer structured URL/query construction over string concatenation.

---

## 17. HLS / M3U8

For `.m3u8`:

- Detect HLS.
- Let the native media engine/browser handle playback.
- Do not manually parse HLS playlists unless explicitly required.
- Respect HTTP errors.
- Respect browser CORS/security rules.
- Respect codec/browser limitations.

Never attempt DRM circumvention.

---

## 18. MPEG-TS

For `.ts`:

- Detect MPEG-TS.
- Let the native backend handle it where supported.
- Do not assume browser support.
- If Web cannot play it natively, show a clear unsupported-stream state.

If Web needs backend transcoding/proxy infrastructure, treat that as a separate backend project rather than hiding it in Flutter.

---

## 19. HTTP Headers

Some legitimate servers may require:

```text
User-Agent
Referer
Authorization
Cookie
```

Support headers through `PlayerSource` or a dedicated header model.

Never log:

- Authorization headers.
- Cookies.
- Passwords.
- Tokens.

---

## 20. Buffering

Distinguish:

```text
loading
buffering
network failure
```

### Loading

Initial source opening.

### Buffering

Playback temporarily lacks enough data.

### Network failure

Playback cannot continue.

Use a subtle buffering indicator.

Debounce it to avoid flicker.

---

## 21. Retry and Recovery

Retries must be bounded.

Example:

```text
Attempt 1
 ↓
short delay
 ↓
Attempt 2
 ↓
longer delay
 ↓
Attempt 3
 ↓
show error
```

Do not retry forever.

Do not repeatedly retry authentication failures.

For temporary live-stream interruptions:

```text
Failure
 ↓
Reconnect
 ↓
Restore playback
```

For VOD, restore the previous position where supported.

---

## 22. Error Classification

Map backend errors to application errors:

```text
NetworkUnavailable
Timeout
ServerUnavailable
Unauthorized
InvalidSource
UnsupportedFormat
CodecError
PlaybackFailure
Unknown
```

Never display raw native exceptions to users.

---

## 23. Metrics

Measure internally:

```text
sourceResolveDuration
playerOpenDuration
firstFrameDuration
bufferingCount
bufferingDuration
channelSwitchDuration
playbackErrorCount
retryCount
```

For channel switching:

```text
T0 = user selects channel
T1 = source resolved
T2 = player open starts
T3 = first frame
```

Then:

```text
switchLatency = T3 - T0
```

Do not claim performance superiority without measurements.

---

## 24. Player UI

Create a reusable player surface.

Concept:

```text
Video
 ↓
Overlay
 ├── Channel information
 ├── Current program
 ├── Play/Pause
 ├── Volume
 ├── Audio
 ├── Subtitles
 ├── Guide
 ├── Favorite
 ├── Fullscreen
 └── More
```

Controls should auto-hide after inactivity.

Touch:

- Tap to show/hide.

Mouse:

- Move/click to reveal.

Keyboard:

- Shortcuts.

TV remote:

- OK toggles controls.
- D-pad navigates.
- Back closes overlays before leaving player.

---

## 25. Android TV UX

Android TV is a first-class target.

Focus must be:

- Visible.
- Large.
- Predictable.
- Fast.

User must be able to perform the full playback flow with a remote:

```text
Open player
 ↓
Change channel
 ↓
Open guide
 ↓
Favorite
 ↓
Audio/subtitle selection
 ↓
Close overlay
```

No touch should be required.

---

## 26. Android Phone Landscape

Prioritize:

```text
Video
Channel information
Quick controls
Channel list
```

Use comfortable touch targets.

Do not create tiny TV-style controls for phones.

---

## 27. Windows

Support:

```text
Mouse
Keyboard
Fullscreen
Escape
Space
Arrow keys
```

Suggested defaults:

```text
Space → Play/Pause
M → Mute
F → Fullscreen
G → Guide
S → Search
Up/Down → Channel navigation
Esc → Exit fullscreen / close overlay
```

Do not override important OS/browser shortcuts unnecessarily.

---

## 28. Web

Respect:

- Browser autoplay policies.
- User gesture requirements.
- HTML video capabilities.
- Browser codec support.
- CORS.
- HTTPS.
- Mixed-content rules.

If autoplay is blocked:

```text
Click/tap to start playback
```

Do not bypass browser security.

If a stream is unsupported:

1. Detect where practical.
2. Show a useful error.
3. Do not fake success.
4. Document the limitation.

---

## 29. Fullscreen

Implement fullscreen through a platform abstraction.

Requirements:

- Enter fullscreen.
- Exit fullscreen.
- Preserve playback.
- Correct Back/Escape behavior.
- Hide unnecessary navigation.
- Restore previous UI state.

Do not recreate the player when toggling fullscreen.

---

## 30. Aspect Ratio

Support:

```text
fit
fill
original
16:9
```

Do not stretch video by default.

Prefer natural aspect ratio or a sensible fit.

---

## 31. Audio Tracks

Where supported:

- Detect tracks.
- Show a selector.
- Display human-readable names.
- Remember user preference where practical.

Hide the selector when there are no alternative tracks.

---

## 32. Subtitles

Where supported:

- Detect tracks.
- Enable/disable.
- Select language.
- Remember preference where practical.

Do not implement any protected-content circumvention.

---

## 33. Live vs VOD

### Live TV

Show:

- LIVE indicator.
- Current program.
- Progress.
- Guide.
- Channel navigation.

Seek only if supported by the source/server.

### VOD

Show:

- Timeline.
- Seek.
- Remaining time.
- Resume.

---

## 34. EPG Integration

The player should receive current program information from the application's EPG layer.

Do not make the player query the database directly.

Player overlay example:

```text
[LOGO] Channel Name
Current Program
████████████░░░
Next: Program Name
```

---

## 35. Channel Up/Down

Implement:

```text
nextChannel()
previousChannel()
```

The active channel sequence should respect the current context:

- Category.
- Favorites.
- Search.
- All channels.

Do not always navigate through every channel.

---

## 36. Last Channel

Store:

```text
lastChannelId
lastCategoryId
```

Allow:

```text
Resume last channel
```

For Web, respect autoplay restrictions.

---

## 37. Overlay State

Separate:

```text
PlaybackState
OverlayState
NavigationState
```

Opening/closing the overlay must never reinitialize playback.

---

## 38. Performance Rules

NEVER:

- Recreate the player on widget rebuild.
- Recreate video controller for overlay changes.
- Make network calls in `build()`.
- Query the database in `build()`.
- Rebuild the entire Live TV screen on position updates.
- Load every channel logo before playback.
- Create unlimited timers.
- Leave subscriptions alive after disposal.

Use granular state updates.

---

## 39. Memory

Default architecture:

```text
One active player
```

Do not keep multiple media players alive unless explicitly required.

Pay attention to:

- Video textures.
- Posters.
- Channel logos.
- EPG.
- Player listeners.

---

## 40. Player Diagnostics

Create a development-only diagnostics panel showing:

```text
Platform
Stream type
Status
Resolution
Position
Duration
Buffer
Audio track
Subtitle track
Last error
Retry count
First-frame time
Channel-switch time
```

Never expose this by default in production.

---

## 41. Logging

Use structured logs:

```text
[Player] open
[Player] first frame
[Player] buffering start
[Player] buffering end
[Player] switch
[Player] retry
[Player] error
[Player] dispose
```

Never include credentials or authenticated URLs.

---

## 42. Security

Never:

- Hardcode passwords.
- Commit credentials.
- Log credentials.
- Send credentials to analytics.
- Embed master API secrets.
- Bypass authentication.
- Bypass DRM.
- Circumvent access restrictions.

Prefer HTTPS.

If HTTP is unavoidable for a legitimate controlled server, isolate and document the platform security configuration instead of globally weakening security.

---

## 43. Testing

### Unit tests

Test:

- Stream type detection.
- Source construction.
- Header handling.
- Playback profile selection.
- Capability mapping.
- Retry policy.
- Error mapping.
- Channel switch logic.

### Widget tests

Test:

- Controls.
- Overlay.
- Loading.
- Buffering.
- Errors.
- Focus.
- Keyboard shortcuts.

### Integration

Use a fake player engine.

Test:

```text
Open channel
 ↓
Loading
 ↓
Playing
 ↓
Favorite
 ↓
Switch channel
 ↓
Error
 ↓
Retry
```

CI must not depend on a production IPTV server.

---

## 44. Fake Player

Create:

```text
FakePlayerEngine
```

It must simulate:

```text
loading
playing
buffering
error
completed
```

This allows deterministic UI tests without a real media engine.

---

## 45. Platform Test Matrix

Validate:

| Capability | Android | Android TV | Windows | Web |
|---|---:|---:|---:|---:|
| Live playback | ✓ | ✓ | ✓ | ✓* |
| HLS | ✓ | ✓ | ✓ | ✓* |
| MPEG-TS | ✓ | ✓ | ✓ | Platform-dependent |
| Fullscreen | ✓ | ✓ | ✓ | ✓ |
| Audio tracks | ✓* | ✓* | ✓* | ✓* |
| Subtitles | ✓* | ✓* | ✓* | ✓* |
| D-pad | ✓ | ✓ | Optional | Optional |
| Keyboard | ✓ | ✓ | ✓ | ✓ |
| Touch | ✓ | Optional | Optional | Optional |

`*` means dependent on backend/browser/stream capabilities.

---

## 46. Server URL Handling

The server may expose HTTP and HTTPS on different ports.

Do not assume defaults.

Represent:

```text
scheme
host
port
```

Example:

```text
http://host:80
https://host:8443
```

Construct URLs safely.

Do not put credentials into debug logs.

---

## 47. URL Construction

Prefer structured networking:

```text
base URL
+
path
+
query parameters
```

Avoid raw string concatenation for authenticated requests.

This prevents:

- Encoding bugs.
- Malformed URLs.
- Accidental credential leakage.

---

## 48. Do Not Overengineer

Do NOT build unless a measured requirement exists:

- Custom video codecs.
- Custom HLS parser.
- Custom renderer.
- Multiple simultaneous players.
- Aggressive predictive preloading.
- Complicated transcoding inside Flutter.

Start with the proven media backend.

---

## 49. Future-Proofing

The subsystem should allow later addition of:

- Catch-up.
- Timeshift.
- DVR.
- Picture-in-picture.
- Multiview.
- Casting.
- External player.
- Advanced subtitle styling.
- Playback statistics.

Do not implement these just to increase feature count.

---

## 50. Agent Workflow

Follow this order:

```text
1. Inspect repository.
2. Inspect Flutter/Dart versions.
3. Inspect existing architecture.
4. Inspect existing IPTV API.
5. Inspect existing models.
6. Inspect navigation/state management.
7. Add compatible media_kit dependencies.
8. Build player domain contracts.
9. Build MediaKit adapter.
10. Build PlayerController.
11. Build stream resolver.
12. Build error/retry system.
13. Build player UI.
14. Add channel switching.
15. Add TV controls.
16. Add Windows/Web controls.
17. Add diagnostics.
18. Add tests.
19. Run analyzer.
20. Test all targets.
21. Measure performance.
22. Optimize based on measurements.
```

Do not jump directly into UI implementation.

---

## 51. Definition of Done — Core

- [ ] media_kit integrated.
- [ ] media_kit_video integrated.
- [ ] PlayerEngine abstraction exists.
- [ ] MediaKit adapter exists.
- [ ] PlayerController exists.
- [ ] PlayerState exists.
- [ ] PlayerCapabilities exists.
- [ ] Stream resolver exists.
- [ ] Stream type detection exists.
- [ ] Retry policy exists.
- [ ] Error mapping exists.
- [ ] Lifecycle/disposal is correct.
- [ ] Live stream opens.
- [ ] m3u8 works where supported.
- [ ] ts works where supported.
- [ ] Fullscreen works.
- [ ] Volume/mute works.
- [ ] Channel switching works.
- [ ] Buffering state works.
- [ ] Error state works.
- [ ] Android works.
- [ ] Android TV works.
- [ ] Windows works.
- [ ] Web works where browser capabilities permit.
- [ ] Credentials never appear in logs.
- [ ] Unit tests exist.
- [ ] Widget tests exist.
- [ ] Diagnostics exist in debug mode.

---

## 52. Production Readiness Gate

Before declaring the player production-ready:

- [ ] Real Android phone tested.
- [ ] Real Android TV/Google TV tested.
- [ ] Real Windows machine tested.
- [ ] Chromium-based browser tested.
- [ ] Slow network tested.
- [ ] Temporary disconnection tested.
- [ ] Server failure tested.
- [ ] Invalid stream tested.
- [ ] Missing logo tested.
- [ ] Missing EPG tested.
- [ ] Arabic tested.
- [ ] English tested.
- [ ] RTL tested.
- [ ] Keyboard tested.
- [ ] D-pad tested.
- [ ] Mouse tested.
- [ ] Touch tested.
- [ ] Fullscreen tested.
- [ ] Background/foreground tested.
- [ ] Disposal tested.
- [ ] Memory inspected.
- [ ] No player leaks.
- [ ] Analyzer passes.
- [ ] Tests pass.
- [ ] Release builds verified.

---

## 53. Coding Rules

1. Keep player classes small.
2. Prefer composition.
3. Keep media_kit imports isolated.
4. Keep domain platform-independent.
5. Avoid global mutable state.
6. Dispose everything.
7. Avoid duplicate controllers.
8. Avoid unnecessary streams.
9. Avoid unnecessary rebuilds.
10. Use immutable state where practical.
11. No network requests in widgets.
12. No DB queries in widgets.
13. No hardcoded server configuration.
14. No secret logging.
15. No unnecessary dependencies.
16. Test public player behavior.
17. Document platform limitations.
18. Never hide failures behind infinite retries.

---

## 54. Forbidden Shortcuts

Do not:

- Build a fake player.
- Use a WebView as the main player.
- Depend only on Android APIs.
- Assume Web behaves like Android.
- Hardcode one IPTV server.
- Hardcode credentials.
- Create a player per channel card.
- Start multiple live streams unnecessarily.
- Parse huge playlists on the UI isolate.
- Load the entire EPG into memory.
- Infinite-retry streams.
- Ignore CORS.
- Ignore Android network security.
- Claim universal codec support.
- Circumvent DRM or access controls.
- Rewrite the application architecture just for playback.

---

## 55. Final Architecture

```text
                         IPTV APP
                            │
                            ▼
                    PlayerController
                            │
                            ▼
                   SmartPlaybackEngine
                            │
              ┌─────────────┴─────────────┐
              │                           │
       StreamResolver              Capabilities
              │                           │
              └─────────────┬─────────────┘
                            │
                       PlayerEngine
                            │
                   MediaKit Adapter
                            │
              ┌─────────────┼─────────────┐
              │             │             │
           Android       Windows         Web
              │             │             │
         Native media   Native media   Browser media
              │             │             │
              └─────────────┴─────────────┘
                            │
                          VIDEO
```

Feature screens must only communicate with the player through the application player API.

---

## 56. Final Quality Standard

The goal is not simply:

> "The stream plays."

The goal is:

```text
Select channel
      ↓
Fast source resolution
      ↓
Fast first frame
      ↓
Stable playback
      ↓
Minimal unnecessary buffering
      ↓
Fast channel switching
      ↓
Predictable controls
      ↓
Excellent TV experience
      ↓
Excellent desktop experience
      ↓
Excellent mobile landscape experience
```

Measure before optimizing.

Use native/hardware capabilities where available.

Respect browser limitations.

Keep the player independent.

Never compromise the architecture for a quick demo.
