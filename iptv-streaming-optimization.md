# IPTV Streaming Optimization Guide (Flutter + media_kit / libmpv)

## Context for the agent
This is a Flutter IPTV app using **media_kit** (a Dart wrapper around **libmpv**) to play
live streams from a remote IPTV server. Playback works, but the goals are:

1. Reduce startup/zap time and re-buffering, especially on **sports channels** (fast motion, high fps).
2. Maximize sustained **video quality** (resolution/bitrate) the network can support.
3. Keep **latency low** without sacrificing stability (drop frames rather than freeze).
4. Make this robust across stream types, since the exact server format may be **HLS (.m3u8)**
   or **raw MPEG-TS (UDP/RTP/RTSP)** — detect and branch accordingly.

Apply the changes below in order. Each section says *what* to change and *why*. Test after each
section on a live sports channel (fast camera pans, scoreboard graphics) before moving to the next.

---

## 0. Detect the actual stream format first

Before tuning, confirm what the server actually sends — the correct optimizations differ for
HLS vs raw MPEG-TS/RTP.

- Log the resolved playlist/stream URL and its scheme (`http(s)://...m3u8`, `udp://`, `rtp://`, `rtsp://`).
- If HLS: fetch the `.m3u8` and check for `#EXT-X-STREAM-INF` (multiple bitrates = ABR available)
  and `#EXT-X-PART`/`#EXT-X-SERVER-CONTROL` (Low-Latency HLS support).
- If MPEG-TS/UDP/RTP: there is no ABR — quality is fixed by the server, so optimization focuses
  entirely on network jitter buffering and decode speed, not bitrate switching.
- Add a debug overlay (see §7) so this is verifiable at runtime instead of guessed.

---

## 1. Core media_kit / libmpv player configuration

Create the `Player` with explicit low-latency-friendly options instead of relying on defaults.

```dart
import 'package:media_kit/media_kit.dart';

final player = Player(
  configuration: PlayerConfiguration(
    // Let mpv manage its own demuxer cache; more reliable for live TS/HLS than app-level buffering.
    bufferSize: 32 * 1024 * 1024, // 32MB read-ahead buffer, tune per §2
    logLevel: MPVLogLevel.warn,
  ),
);

// Apply low-level mpv properties for live playback behavior.
final platformPlayer = player.platform as NativePlayer;
await platformPlayer.setProperty('cache', 'yes');
await platformPlayer.setProperty('cache-pause', 'yes');
await platformPlayer.setProperty('cache-pause-initial', 'yes');

// Live-edge / low latency behavior
await platformPlayer.setProperty('untimed', 'no');
await platformPlayer.setProperty('video-sync', 'audio');     // resync to audio, avoids AV drift
await platformPlayer.setProperty('framedrop', 'vo');         // drop video frames, not audio, under load
await platformPlayer.setProperty('hr-seek-framedrop', 'yes');

// Hardware decoding — critical for sustaining high fps sports content
await platformPlayer.setProperty('hwdec', 'auto-safe');
await platformPlayer.setProperty('hwdec-codecs', 'all');

// Reduce initial black-screen/zap time
await platformPlayer.setProperty('demuxer-lavf-o', 'fflags=+nobuffer');
await platformPlayer.setProperty('demuxer-readahead-secs', '5');
```

**Why:** `framedrop=vo` lets mpv drop decoded video frames instead of stalling the whole pipeline
when the CPU/GPU can't keep up — this is what prevents sports content (high motion, high fps) from
visibly stuttering. `hwdec=auto-safe` offloads decode to the GPU, which is the single biggest lever
for sustaining 50/60fps HD content on mobile/TV hardware.

---

## 2. Buffer sizing: separate "live latency" from "stability"

Live latency and rebuffer-resistance are a **direct tradeoff**. Expose this as a user-facing
"Playback mode" instead of picking one value for everyone:

| Mode | demuxer-readahead-secs | cache-secs | Target latency | Use case |
|---|---|---|---|---|
| Low Latency | 2–3 | 4 | ~3–5s behind live | Good/stable networks, sports where sync matters |
| Balanced (default) | 5 | 10 | ~8–12s behind live | Typical mobile/Wi-Fi networks |
| Stability | 10–15 | 20–30 | ~20–30s behind live | Poor/variable networks |

```dart
await platformPlayer.setProperty('cache-secs', '10');
await platformPlayer.setProperty('demuxer-max-bytes', '64MiB');
await platformPlayer.setProperty('demuxer-max-back-bytes', '16MiB');
```

**Agent action:** implement this as a settings enum, not hardcoded constants, so it can be
switched at runtime and persisted per-channel (sports channels default to "Low Latency", movie/VOD
channels can default to "Balanced").

---

## 3. Network layer (biggest real-world impact for IPTV)

Most "quality/speed" complaints in IPTV apps are network-layer, not player-layer. Have the agent
implement:

1. **Persistent HTTP connections** — ensure mpv/libmpv is using keep-alive and HTTP/2 where the
   server supports it. For HLS segment fetching, avoid re-establishing TLS per segment:
   ```dart
   await platformPlayer.setProperty('http-header-fields', 'Connection: keep-alive');
   await platformPlayer.setProperty('tls-verify', 'yes'); // only disable for self-signed test servers
   ```
2. **Segment prefetching for HLS** — mpv's demuxer already read-aheads, but confirm
   `demuxer-readahead-secs` (see §1) is actually being honored by checking `cache-buffering-state`
   via `mpv_observe_property` and logging it.
3. **DNS**: if the IPTV server is referenced by hostname and DNS is slow/flaky, resolve once and
   cache, or let the user pin an IP, to shave hundreds of ms off zap time.
4. **Reconnect/retry logic for drops** (common on live TS/UDP streams):
   ```dart
   player.stream.error.listen((error) async {
     await Future.delayed(const Duration(seconds: 2));
     await player.open(Media(currentUrl), play: true);
   });
   ```
   Use exponential backoff (2s, 4s, 8s, max 15s) and cap retries with a user-visible "reconnecting" state.
5. **Multicast (if server uses UDP/RTP multicast for sports)**: ensure the device network layer
   (Android `MulticastLock`, etc.) actually permits multicast — this is a common silent failure
   that looks like "bad quality" but is actually zero packets arriving.

---

## 4. Adaptive bitrate (only applies if the server provides multiple renditions via HLS)

If §0 confirmed multiple `#EXT-X-STREAM-INF` variants exist:

- Do **not** hardcode a single variant URL — point the player at the **master playlist** and let
  mpv's internal ABR (or a custom selector) switch. mpv doesn't do true ABR by bandwidth by default;
  implement a light bandwidth estimator:
  ```dart
  // Pseudocode for the agent to implement:
  // 1. Track bytes downloaded per segment / segment duration -> throughput estimate.
  // 2. Maintain a rolling average (last 5 segments) to avoid oscillation.
  // 3. Switch to next-lower variant only after 2 consecutive under-target samples (avoid flapping).
  // 4. Switch up only after 5 consecutive comfortably-above-target samples.
  await platformPlayer.setProperty('hls-bitrate', 'max'); // or a specific ceiling, tunable in settings
  ```
- For sports specifically: bias the switch-down threshold to be more conservative (prefer a
  slightly lower resolution over any rebuffer), since motion artifacts from bitrate are more
  tolerable to viewers than a freeze during play.

If the server is raw MPEG-TS/UDP with a single fixed bitrate, ABR is not possible — quality is
capped by what the server sends, and the only real levers are §1–3.

---

## 5. Rendering pipeline

- Ensure the Flutter `Video` widget is using the **texture/GPU rendering path**, not a software
  fallback — check `media_kit_video` is configured with hardware surface rendering enabled per
  platform (Android: `SurfaceView`/`TextureView` via ANGLE/OpenGL; not a `Widget`-composited bitmap path).
- Avoid wrapping the video widget in expensive parent widgets that force full repaints per frame
  (e.g., avoid `Opacity`/`ColorFiltered`/`BackdropFilter` directly over the video surface — these
  force offscreen compositing and can cap effective fps well below the decoder's output).
- Match the app's rendering pipeline to the display refresh rate where the platform allows it
  (e.g., Android `Surface.setFrameRate` hint) so 50/60fps sports content isn't judder-resampled
  to a 30fps/adaptive-sync mismatch.

---

## 6. EPG/UI shouldn't compete with the decoder

If the sports channel screen also polls an EPG API, loads channel logos, or updates a live
scoreboard overlay on a timer, make sure these run on a separate isolate or are rate-limited —
on lower-end Android/TV boxes, UI-thread work competing with video decode is a common cause of
frame drops that look like "network problems" but aren't.

---

## 7. Add a debug/diagnostics overlay (toggleable)

Have the agent add a hidden dev overlay showing, updated every second:
- Current resolution / fps / video bitrate (from mpv properties: `video-params`, `estimated-vf-fps`, `video-bitrate`)
- Cache/buffer state (`cache-buffering-state`, `demuxer-cache-duration`)
- Dropped frame count (`frame-drop-count`, `decoder-frame-drop-count`)
- Network throughput estimate (from §3.2/§4)

This turns "it feels slow" into measurable numbers, and should be used to validate every change
above on an actual sports channel before/after.

---

## 8. Rollout / testing checklist

- [ ] Confirm stream format (§0) and branch config accordingly
- [ ] Apply mpv low-latency properties (§1)
- [ ] Add Playback Mode setting with three presets (§2)
- [ ] Verify keep-alive / TLS reuse, add reconnect-with-backoff (§3)
- [ ] Implement bandwidth-aware ABR switching if server supports it (§4)
- [ ] Confirm hardware-accelerated rendering path, remove compositing overhead (§5)
- [ ] Isolate/rate-limit EPG and overlay work off the render path (§6)
- [ ] Add diagnostics overlay and benchmark before/after on a live sports channel (§7)

Test on: a fast-motion sports channel, on both strong Wi-Fi and throttled/weak network, on the
lowest-spec device the app needs to support (older Android TV box is usually the worst case).
