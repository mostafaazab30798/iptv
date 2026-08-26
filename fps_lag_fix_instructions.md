# Agent Task: Fix Dropped FPS & Laggy Stream Playback

## Context

Root cause analysis found three concrete contributors to dropped frames and stream
lag in the `media_kit`-based IPTV player:

1. **Telemetry polling blocks the render path.** `MediaKitPlayerEngine` polls 9 mpv
   properties **sequentially** (9 awaited platform-channel round trips) every second,
   competing with video decode/render on constrained devices.
2. **No adaptive reaction to network stress.** A software-decode escalation system
   already exists (`SmartPlaybackEngine`), but nothing reacts when frames drop or
   buffering occurs due to *network* stress rather than CPU decode — the buffer mode
   just stays wherever it was set.
3. **Full-state rebuild storm during playback.** `player_screen.dart` watches the
   entire `PlayerState` object at the top of `build()`. Since `position` updates
   several times/sec and `metrics` updates every second, this rebuilds the whole
   widget tree — including the video surface widget itself — on every tick, adding
   CPU/build cost that competes with frame rendering.

Apply the three fixes below, in order. Each is self-contained and independently
verifiable — run `flutter analyze` after each one before moving to the next.

---

## Fix 1 — Parallelize and slow down telemetry polling

**File:** `lib/player/infrastructure/media_kit_player_engine.dart`

**Why:** `_pollMpvTelemetry()` currently does 9 `await platform.getProperty(...)`
calls one after another every second. This data only feeds the debug-only
`DiagnosticsOverlay` and the escalation loops in `SmartPlaybackEngine` — neither
needs sub-second resolution. Firing the calls concurrently and slowing the poll
interval removes repeated per-second stalls on the platform channel.

**Change 1a** — replace the timer interval:

```dart
// BEFORE
void _startTelemetryPolling() {
  _telemetryTimer?.cancel();
  _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollMpvTelemetry());
}
```

```dart
// AFTER
/// Telemetry poll cadence. Kept slower than 1s since this data only feeds the
/// debug-only DiagnosticsOverlay and the adaptive escalation loops — while every
/// tick costs up to 9 platform-channel round trips that can contend with the
/// video render/decode pipeline on constrained devices (Android TV / STBs).
static const _telemetryInterval = Duration(seconds: 2);

void _startTelemetryPolling() {
  _telemetryTimer?.cancel();
  _telemetryTimer = Timer.periodic(_telemetryInterval, (_) => _pollMpvTelemetry());
}
```

**Change 1b** — replace the sequential awaits inside `_pollMpvTelemetry()` with a
single `Future.wait`:

```dart
// BEFORE
final platform = _player?.platform;
if (platform == null) return;

final fpsStr = await (platform as dynamic).getProperty('estimated-vf-fps');
final bitrateStr = await (platform as dynamic).getProperty('video-bitrate');
final cacheDurStr = await (platform as dynamic).getProperty('demuxer-cache-duration');
final cacheStateStr = await (platform as dynamic).getProperty('cache-buffering-state');
final frameDropStr = await (platform as dynamic).getProperty('frame-drop-count');
final decoderDropStr = await (platform as dynamic).getProperty('decoder-frame-drop-count');
final hwdecCurrentStr = await (platform as dynamic).getProperty('hwdec-current');
final videoCodecStr = await (platform as dynamic).getProperty('video-codec');
final pixelFormatStr = await (platform as dynamic).getProperty('video-params/pixelformat');
```

```dart
// AFTER
final platform = _player?.platform;
if (platform == null) return;
final p = platform as dynamic;

// Fire all property reads concurrently instead of one at a time — this was
// previously 9 sequential platform-channel round trips per tick.
final results = await Future.wait<dynamic>([
  p.getProperty('estimated-vf-fps'),
  p.getProperty('video-bitrate'),
  p.getProperty('demuxer-cache-duration'),
  p.getProperty('cache-buffering-state'),
  p.getProperty('frame-drop-count'),
  p.getProperty('decoder-frame-drop-count'),
  p.getProperty('hwdec-current'),
  p.getProperty('video-codec'),
  p.getProperty('video-params/pixelformat'),
]);

final fpsStr = results[0];
final bitrateStr = results[1];
final cacheDurStr = results[2];
final cacheStateStr = results[3];
final frameDropStr = results[4];
final decoderDropStr = results[5];
final hwdecCurrentStr = results[6];
final videoCodecStr = results[7];
final pixelFormatStr = results[8];
```

Everything below that block (parsing `fpsStr`, `bitrateStr`, etc.) is unchanged —
the local variable names are identical, only how they're populated changes.

**Verify:** the rest of `_pollMpvTelemetry()` still compiles unmodified; no other
call sites reference the old sequential variables.

---

## Fix 2 — Adaptive network buffer-mode escalation

**File:** `lib/player/application/smart_playback_engine.dart`

**Why:** `SmartPlaybackEngine` already has a two-tier software-decode escalation
system (`_tickEscalation`) that reacts to CPU-bound frame drops, but it explicitly
skips its logic whenever hardware decoding is active
(`if (m.hwdecCurrent == null || m.isHardwareDecodingActive) return;`). That means
the most common real-world cause of IPTV lag — network/server-side throughput
issues causing buffer underruns even with hardware decode fully engaged — has
*no* automatic response. `PlayerMetrics` already exposes `isNetworkBottleneck` and
`bufferingCount`; nothing currently acts on them. This fix adds a second,
independent escalation state machine (same hysteresis pattern as the existing
one) that walks `PlaybackBufferMode` up under sustained network stress and steps
back down after sustained health.

**Change 2a** — add new state fields, placed directly after the existing
`_escalationTimer` field declaration:

```dart
  Timer? _escalationTimer;

  // ── Adaptive network buffer escalation ──────────────────────────────────────
  //
  // The SW-decode tiers above only fire when mpv confirms software decoding is
  // active. Most real-world "laggy stream / dropped frames" complaints on IPTV
  // are actually network-side: the read-ahead buffer empties faster than the
  // stream downloads (slow/variable Wi-Fi, congested ISP link, overloaded
  // Xtream panel), which shows up as `isNetworkBottleneck` / rising
  // `bufferingCount` even with hardware decode fully active. Nothing previously
  // reacted to that signal — buffer mode stayed wherever the user last set it.
  //
  // This mirrors the same escalate/de-escalate-with-hysteresis pattern as the
  // SW-decode tiers, but walks PlaybackBufferMode lowLatency → balanced →
  // stability under sustained stress, and steps back down (only as far as
  // `balanced`, never back to `lowLatency` automatically) after a long enough
  // healthy window, to avoid oscillating back into the mode that caused the
  // stress in the first place.

  PlaybackBufferMode _currentBufferMode = PlaybackBufferMode.balanced;
  int _networkStressConsecutiveSeconds = 0;
  int _networkHealthyConsecutiveSeconds = 0;
  int _lastBufferingCount = 0;

  /// Consecutive seconds of sustained network stress before escalating buffer mode.
  static const _networkEscalateWindow = 4;

  /// Consecutive seconds of sustained health before stepping buffer mode back down.
  static const _networkDeEscalateWindow = 20;

  PlaybackBufferMode get currentBufferMode => _currentBufferMode;
```

**Change 2b** — reset the new state in `open()`, alongside the existing
escalation reset block:

```dart
// BEFORE
_stopEscalationMonitor();
await _applyEscalationTier(SoftwareDecodeFallbackTier.none);
_lastTotalDrops = 0;
_tier2ConsecutiveSeconds = 0;
_deEscalateConsecutiveSeconds = 0;
```

```dart
// AFTER
_stopEscalationMonitor();
await _applyEscalationTier(SoftwareDecodeFallbackTier.none);
_lastTotalDrops = 0;
_tier2ConsecutiveSeconds = 0;
_deEscalateConsecutiveSeconds = 0;
_networkStressConsecutiveSeconds = 0;
_networkHealthyConsecutiveSeconds = 0;
_lastBufferingCount = 0;
```

**Change 2c** — call the new tick function from the existing per-second timer in
`_startEscalationMonitor()`:

```dart
// BEFORE
_escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
  _tickEscalation(_latestMetrics);
});
```

```dart
// AFTER
_escalationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
  _tickEscalation(_latestMetrics);
  _tickNetworkAdaptation(_latestMetrics);
});
```

**Change 2d** — add the new tick method and its helpers, placed directly after
the existing `_applyEscalationTier` method:

```dart
  Future<void> _applyEscalationTier(SoftwareDecodeFallbackTier tier) async {
    if (_currentTier == tier) return;
    _currentTier = tier;
    await _engine.applySoftwareDecodeEscalation(tier);
  }

  // ── Adaptive network buffer escalation ──────────────────────────────────────

  /// Called every second alongside [_tickEscalation]. Drives buffer-mode
  /// escalation/de-escalation based on network-side stress signals.
  void _tickNetworkAdaptation(PlayerMetrics m) {
    final bufferingDelta = (m.bufferingCount - _lastBufferingCount).clamp(0, 1 << 30);
    _lastBufferingCount = m.bufferingCount;

    final stressedNow = m.isNetworkBottleneck || bufferingDelta > 0;

    if (stressedNow) {
      _networkStressConsecutiveSeconds++;
      _networkHealthyConsecutiveSeconds = 0;
      if (_networkStressConsecutiveSeconds >= _networkEscalateWindow) {
        _escalateBufferMode();
        _networkStressConsecutiveSeconds = 0;
      }
    } else {
      _networkHealthyConsecutiveSeconds++;
      _networkStressConsecutiveSeconds = 0;
      if (_networkHealthyConsecutiveSeconds >= _networkDeEscalateWindow) {
        _deEscalateBufferMode();
        _networkHealthyConsecutiveSeconds = 0;
      }
    }
  }

  Future<void> _escalateBufferMode() async {
    final next = switch (_currentBufferMode) {
      PlaybackBufferMode.lowLatency => PlaybackBufferMode.balanced,
      PlaybackBufferMode.balanced => PlaybackBufferMode.stability,
      PlaybackBufferMode.stability => PlaybackBufferMode.stability,
    };
    if (next == _currentBufferMode) return;
    PlayerLogger.note(
      '[buffer-adapt] Escalating buffer mode ${_currentBufferMode.displayName} -> '
      '${next.displayName} (sustained network stress for $_networkEscalateWindow s)',
    );
    _currentBufferMode = next;
    await _engine.setBufferMode(next);
  }

  Future<void> _deEscalateBufferMode() async {
    // Only ever step back down to `balanced`, never automatically back to
    // `lowLatency` — that's the mode most likely to have caused the stress,
    // and re-entering it would just restart the escalate/de-escalate cycle.
    // Returning to low-latency requires an explicit user choice.
    if (_currentBufferMode == PlaybackBufferMode.stability) {
      _currentBufferMode = PlaybackBufferMode.balanced;
      PlayerLogger.note(
        '[buffer-adapt] De-escalating buffer mode stability -> balanced '
        '(network stable for $_networkDeEscalateWindow s)',
      );
      await _engine.setBufferMode(_currentBufferMode);
    }
  }
```

**Change 2e — keep manual user buffer-mode changes in sync.** The public
`setBufferMode` passthrough must update `_currentBufferMode` too, otherwise a
manual selection made via the UI settings sheet will be silently overwritten by
the next automatic tick, or the auto-escalation baseline will be wrong:

```dart
// BEFORE
Future<void> setBufferMode(PlaybackBufferMode mode) => _engine.setBufferMode(mode);
```

```dart
// AFTER
Future<void> setBufferMode(PlaybackBufferMode mode) {
  _currentBufferMode = mode;
  return _engine.setBufferMode(mode);
}
```

**Verify:** `PlaybackBufferMode`, `PlayerMetrics.isNetworkBottleneck`, and
`PlayerLogger.note` already exist and are imported in this file — no new imports
needed. Confirm `_engine.setBufferMode` remains the only mutator of the mpv-level
buffer properties.

---

## Fix 3 — Stop the video surface rebuilding on every position/metrics tick

**Files:** `lib/player/presentation/player_view.dart`,
`lib/features/player/player_screen.dart`

**Why:** `player_screen.dart` calls `ref.watch(playerControllerProvider)` once at
the top of `build()`, capturing the *entire* `PlayerState`. `position` changes
several times per second and `metrics` changes every second (see Fix 1), so the
whole subtree — including `PlayerView`, which hosts the actual video texture —
rebuilds every tick regardless of whether anything relevant to it changed.
`PlayerView` only ever reads `playerState.aspectRatioIndex`; `platformHandle`
already comes from `controller.engine.platformHandle`, not from state. Scoping
this one dependency with `.select()` removes the video surface from the
rebuild storm entirely.

**Change 3a** — change `PlayerView` to take `aspectRatioIndex` directly instead
of the whole `PlayerState`:

```dart
// BEFORE
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.playerState,
    required this.platformHandle,
  });

  final PlayerState playerState;
  final dynamic platformHandle;

  @override
  Widget build(BuildContext context) {
    if (platformHandle is mkv.VideoController) {
      final videoController = platformHandle as mkv.VideoController;

      BoxFit fit = BoxFit.contain; // 0: Fit
      double? forcedAspectRatio;

      switch (playerState.aspectRatioIndex) {
```

```dart
// AFTER
class PlayerView extends StatelessWidget {
  const PlayerView({
    super.key,
    required this.aspectRatioIndex,
    required this.platformHandle,
  });

  final int aspectRatioIndex;
  final dynamic platformHandle;

  @override
  Widget build(BuildContext context) {
    if (platformHandle is mkv.VideoController) {
      final videoController = platformHandle as mkv.VideoController;

      BoxFit fit = BoxFit.contain; // 0: Fit
      double? forcedAspectRatio;

      switch (aspectRatioIndex) {
```

The rest of the `switch` body and file is unchanged. Remove the now-unused
`import 'package:iptv/player/application/player_state.dart';` from this file if
nothing else in it references `PlayerState`.

**Change 3b** — in `player_screen.dart`, wrap the video surface and the
buffering indicator in their own `Consumer`s scoped with `.select()`, so they
rebuild only on the specific fields they need instead of on every
`playerControllerProvider` change:

```dart
// BEFORE
body: Stack(
  fit: StackFit.expand,
  children: [
    // 1. Video Surface
    PlayerView(
      playerState: playerState,
      platformHandle: controller.engine.platformHandle,
    ),

    // 2. Debounced Buffering Indicator
    BufferingIndicator(
      isBuffering: playerState.isBuffering || playerState.isLoading,
    ),
```

```dart
// AFTER
body: Stack(
  fit: StackFit.expand,
  children: [
    // 1. Video Surface — isolated from position/metrics churn; only rebuilds
    // when the aspect-ratio setting actually changes.
    Consumer(
      builder: (context, ref, _) {
        final aspectRatioIndex = ref.watch(
          playerControllerProvider.select((s) => s.aspectRatioIndex),
        );
        return PlayerView(
          aspectRatioIndex: aspectRatioIndex,
          platformHandle: controller.engine.platformHandle,
        );
      },
    ),

    // 2. Debounced Buffering Indicator — isolated the same way.
    Consumer(
      builder: (context, ref, _) {
        final isBuffering = ref.watch(
          playerControllerProvider.select((s) => s.isBuffering || s.isLoading),
        );
        return BufferingIndicator(isBuffering: isBuffering);
      },
    ),
```

Leave `PlayerOverlay` and `PlayerErrorView` receiving the full `playerState` as
before — they're the interactive control layer and already conditionally render
much of their content; re-scoping them is a larger refactor (touches
`player_controls.dart`, ~750 lines) and out of scope for this fix. This change
alone removes the video texture widget from the rebuild path, which is the part
that actually matters for perceived frame smoothness.

**Verify:** `Consumer` is available via the existing `flutter_riverpod` import in
`player_screen.dart`. `controller` (from `ref.read(playerControllerProvider.notifier)`)
is still read once at the top of `build()` and captured by the closures — this is
safe since `controller` itself doesn't change identity across rebuilds.

---

## Post-change checklist for the agent

- [ ] `flutter analyze` passes with no new errors/warnings in the three touched files.
- [ ] `media_kit_player_engine.dart`: telemetry timer interval is `Duration(seconds: 2)`; `_pollMpvTelemetry` uses one `Future.wait`, not sequential awaits.
- [ ] `smart_playback_engine.dart`: `_tickNetworkAdaptation` is called from the same `Timer.periodic` as `_tickEscalation`; `setBufferMode` updates `_currentBufferMode` before delegating to `_engine`.
- [ ] `player_view.dart`: no remaining reference to `playerState` in the class; constructor takes `aspectRatioIndex`.
- [ ] `player_screen.dart`: `PlayerView` and `BufferingIndicator` call sites are wrapped in `Consumer` + `.select()`; no other call sites of `PlayerView(...)` exist elsewhere in the codebase that still pass `playerState:` (grep for `PlayerView(` to confirm).
- [ ] Manually test: start a stream, open the quick-settings sheet, manually switch buffer mode — confirm it isn't silently reverted a few seconds later by the adaptive logic.
- [ ] Manually test on a throttled/degraded network: confirm buffer mode escalates from balanced → stability after ~4s of sustained rebuffering, and steps back to balanced after ~20s of stable playback.
