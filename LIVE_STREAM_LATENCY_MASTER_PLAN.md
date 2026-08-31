# Hope TV Live-Stream Latency Master Plan

**Created:** 2026-08-31  
**Scope:** Android, Android TV, Windows, iOS, and Web live playback  
**Primary stack:** Flutter + `media_kit` 1.2.6 / libmpv  
**Goal:** Minimize the delay between an event happening in the source broadcast and the same event appearing in Hope TV, without making playback unusably fragile.

## 1. Executive decision

The reported example is **77 seconds behind** (Hope TV at 15:10 while the comparison feed is at 16:27). The application cannot safely fix that by merely reducing `cache-secs` from 10 to 2.

Latency must be separated into three components:

```text
event at venue
  -> broadcaster/encoder/provider delay     (upstream latency)
  -> newest media available at IPTV URL     (provider edge)
  -> Hope TV buffering/decode/render delay  (client-added latency)
  -> viewer sees event
```

The first milestone is therefore measurement, not tuning. If a fresh `ffplay` or mpv session against the exact IPTV URL is also about 77 seconds late, almost all delay is upstream and no client player can recover media that the provider has not published yet. If an external player is close to live but Hope TV is late, the defect is in our player configuration or drift recovery. If Hope TV starts close and falls behind over time, the defect is accumulated buffering after stalls.

The correct product strategy is:

1. Measure provider-edge and client-added delay separately.
2. Detect the real transport rather than applying one mpv profile to every URL.
3. Start every live source at its newest safe edge.
4. Continuously measure drift and catch up or hard-reset when it exceeds policy.
5. Offer a sports-focused latency policy with an explicit stability tradeoff.
6. Escalate to the IPTV provider or change delivery technology when the delay is already present at the provider edge.

## 2. What the repository does today

### Confirmed architecture

- Live Xtream URLs are built by `XtreamRemoteDataSource.buildLiveStreamUrl`, whose default extension is `.ts`. The normal Live TV screen does not override it. The main production path is therefore **progressive HTTP MPEG-TS**, even though some older tests and documentation emphasize HLS.
- `PlayerSource.live` usually receives `StreamType.auto`; production callers do not consistently run `StreamTypeDetector`. Protocol-specific behavior is consequently unavailable at engine-open time.
- The shared `MediaKitPlayerEngine` applies the same cache and demuxer settings to all live, VOD, TS, HLS, RTSP, and other sources.
- The engine starts in `PlaybackBufferMode.balanced` unless a caller overrides it.
- Balanced mode requests `cache-secs=10`; the existing low-latency mode still requests `cache-secs=8` and six seconds of demuxer read-ahead.
- `cache-pause-initial=yes` and `cache-pause-wait=1.0` intentionally delay initial playback for stability.
- Telemetry already captures cache duration, cache buffering state, frame drops, decoder drops, and hardware decoder state. This is a strong foundation, but it does not measure distance from the live edge.
- Error recovery reopens live media and therefore tends to return to the current provider edge, but there is no proactive drift controller when playback remains technically healthy while far behind.
- `hls-bitrate=max` always selects the highest advertised HLS rendition. This is a quality preference, not adaptive bitrate logic, and can increase stalls on constrained links.
- The current `PlayerConfiguration.bufferSize` is set only when the player is created. Runtime buffer-mode changes update mpv cache properties but do not recreate this app-level buffer.
- Web playback can add a Cloudflare proxy hop. Native Android/Windows playback goes directly to the provider.

### Likely causes of a 77-second gap, in priority order

| Cause | How to prove it | Expected ownership |
|---|---|---|
| Provider restream/transcode is already delayed | Fresh external player and Hope TV show the same event time | Provider/source |
| Existing player session accumulated delay after stalls | Reopening the channel jumps substantially forward | Hope TV drift recovery |
| Endpoint is a delayed HLS/DVR rendition despite its suffix, or redirects to one | Inspect final response, content type, and playlist | Provider + Hope TV detection |
| Excessive local buffering | External player is close; Hope TV clean-start delay tracks its cache | Hope TV tuning |
| Web proxy buffers or serves stale manifests/segments | Native is current while Web is late; inspect Age/cache headers | Hope TV web gateway |
| Device cannot decode in real time | Cache remains healthy while frame drops and software decode rise | Device/player adaptation |

## 3. Latency definitions and service-level objectives

Do not use one number called “latency.” Record these separately:

- **Upstream latency:** event-to-provider-edge delay.
- **Client-added latency:** provider-edge-to-screen delay.
- **Glass-to-glass latency:** event-to-screen total.
- **Startup latency:** press channel to first decoded frame.
- **Drift:** increase in client-added latency during a session.

### Initial acceptance targets

These are engineering targets to validate on a stable network, not promises about a third-party IPTV provider.

| Delivery type | Client-added clean-start target | 90-minute drift target | Total-latency reality |
|---|---:|---:|---|
| Progressive HTTP MPEG-TS | p50 <= 2.5 s, p95 <= 5 s | <= 2 s above clean-start baseline | Provider delay remains unavoidable |
| Conventional HLS | <= 1.5 media segments behind newest playable segment | <= 1 segment | Often 2-3 segment durations plus encoder/provider delay |
| LL-HLS with parts | p50 <= 4 s, p95 <= 7 s | <= 2 s | Requires server and client LL-HLS support |
| Web through proxy | Native target + <= 1 s | No stale manifest/segment responses | Proxy must stream and bypass cache for live media |

For the reported 77-second case, the first release gate is more practical: **Hope TV must not add more than five seconds beyond the best direct player using the same URL and device/network.**

## 4. Phase 0 — Build a trustworthy latency lab

**Priority:** P0  
**Duration:** 2-3 engineering days  
**Reason:** Every later optimization is unsafe without knowing where the delay originates.

### 4.1 Create a repeatable comparison harness

Add `tool/stream_latency_probe/` with a credential-safe command that accepts a URL at runtime and never writes it to logs. It should:

- resolve redirects and record final host, HTTP version, response content type, and time to first byte;
- sample the first media bytes to distinguish MPEG-TS from HLS even when extensions lie;
- for HLS, parse `EXT-X-TARGETDURATION`, media sequence, segment durations, `EXT-X-PROGRAM-DATE-TIME`, `EXT-X-PART`, `EXT-X-SERVER-CONTROL`, `PART-HOLD-BACK`, and `HOLD-BACK`;
- record whether the playlist is live, event, or VOD and whether it exposes a DVR window;
- use `ffprobe` to record codecs, frame rate, GOP/keyframe interval, first packet PTS, and actual container;
- emit sanitized JSON keyed by a hash of channel/server, never credentials or full URLs.

### 4.2 Run the four-way test

For each affected sports channel, simultaneously record:

1. trusted official/live reference;
2. standalone mpv or `ffplay` with normal defaults;
3. standalone player with an aggressive low-latency profile;
4. Hope TV debug build.

Use a visible event such as scoreboard clock, referee whistle, goal, or replay transition. Perform:

- cold start;
- immediate channel reopen after five minutes;
- 30-minute continuous playback;
- 90-minute continuous playback;
- one induced 3-5 second network impairment;
- strong network and constrained network trials;
- native platform and Web trials separately.

### 4.3 Required output

Produce a row per trial containing:

```text
channel_hash, platform, transport, endpoint_variant, test_time,
reference_delay_ms, direct_player_delay_ms, app_delay_ms,
startup_ms, cache_ms, stalls, stall_ms, reopen_jump_ms,
hwdec, dropped_frames, bitrate, fps, proxy_used
```

### Phase 0 exit criteria

- At least three sports channels and one normal channel tested.
- The 77-second example classified as primarily upstream, clean-start client delay, or accumulated drift.
- Direct `.ts` and `.m3u8` variants tested when both endpoints are accepted by the provider.
- No credentials appear in console output, analytics, screenshots, or artifacts.

## 5. Phase 1 — Make transport identity explicit

**Priority:** P0  
**Duration:** 2 engineering days

### Work

1. Introduce a `ResolvedLiveTransport`/`LiveStreamDescriptor` model containing:
   - requested URL type;
   - detected container/protocol;
   - final redirected URL type;
   - seekable/live-window capability;
   - standard HLS versus LL-HLS;
   - segment and part duration when known;
   - wall-clock timeline availability;
   - proxy involvement.
2. Update all live-source creation to use one resolver instead of constructing `PlayerSource.live` in many screens.
3. Detect by response/container, with extension only as an initial hint.
4. Pass the descriptor to the engine through typed fields, not an unstructured metadata convention.
5. Cache non-secret capability results per provider/channel with a short TTL and invalidate on redirects or playback errors.

### Principal files

- `lib/data/datasources/xtream_remote_datasource.dart`
- `lib/player/infrastructure/stream_resolver.dart`
- `lib/player/utils/stream_type_detector.dart`
- `lib/player/domain/entities/player_source.dart`
- every live source call site under `lib/features/`

### Exit criteria

- Engine logs show the actual detected transport for every live open.
- `.ts` endpoints that return playlists are treated as HLS.
- VOD configuration is no longer changed by live-only tuning.
- Unit tests cover misleading suffixes, redirects, content types, HLS tags, and raw TS.

## 6. Phase 2 — Add live-edge observability

**Priority:** P0  
**Duration:** 3-4 engineering days

Extend `PlayerMetrics` and the diagnostics overlay with:

- `transport` and endpoint variant;
- `targetLiveOffset`;
- `estimatedLiveOffset` and confidence (`exact`, `manifest`, `relative`, `unknown`);
- newest available HLS program date/time;
- current playback program date/time when calculable;
- live-window length and segment/part duration;
- `driftSinceOpen`;
- bytes/second or bitrate estimate;
- last stall duration;
- catch-up state, playback speed, hard-edge resets, and reason;
- provider-edge lag when a manifest supplies a trustworthy wall-clock mapping.

For standard/LL-HLS, calculate offset from `EXT-X-PROGRAM-DATE-TIME` plus segment/part position. For progressive TS without absolute timestamps, use a relative estimator: establish a clean-open baseline, monitor queued cache duration and stall accumulation, and use the forward jump observed after a controlled reopen as a calibration signal. Label this estimate honestly; it is not glass-to-glass latency.

Add an internal “Go Live” action that reports before/after offset in debug telemetry. It should be available to users only after the recovery behavior is proven.

### Exit criteria

- A tester can distinguish provider delay from app-added delay without reading raw mpv logs.
- Metrics continue updating in release builds at a low overhead.
- Telemetry is sampled and contains no stream credentials.

## 7. Phase 3 — Protocol-specific startup profiles

**Priority:** P0  
**Duration:** 3-5 engineering days plus device validation

Do not replace today’s values with guessed global constants. Run an A/B matrix and select the lowest stable profile per transport.

### 7.1 Progressive HTTP MPEG-TS sports profile

Experiment with:

- mpv’s built-in `low-latency` profile as a controlled baseline;
- `cache-secs` around 1-3 seconds instead of 8-10;
- `demuxer-readahead-secs` at or below the cache target;
- `cache-pause-initial=no`, or a much smaller initial wait where startup underflow data permits;
- FFmpeg `fflags=+nobuffer` in addition to the existing corruption/PTS policy;
- smaller probe/analyze values only when codec detection remains reliable;
- a byte-buffer ceiling appropriate to measured channel bitrates;
- direct live playback at rate 1.0 with AV sync retained.

Avoid `untimed` for normal sports streams with audio; mpv warns it can break playback timing. Do not treat `Connection: keep-alive` as a latency feature by itself—modern mpv/libcurl already negotiates supported HTTP versions and keep-alive.

### 7.2 Conventional HLS profile

- Start at the newest safe playable segment, not the beginning of a DVR playlist.
- Verify and benchmark FFmpeg HLS `live_start_index` support in the exact bundled libavformat version before shipping an option.
- Derive the target from segment duration; do not hardcode “three seconds” for six-second segments.
- Keep enough buffer for one network disturbance without silently moving the target farther from live.
- Do not force `hls-bitrate=max` on constrained links. Compare a bitrate ceiling or an Android-native ABR experiment.

### 7.3 LL-HLS profile

Enable it only after confirming all required server tags and that the bundled player consumes partial segments and blocking playlist reloads correctly. A playlist merely named `.m3u8` is not LL-HLS.

### 7.4 RTSP/RTP/UDP profile

Use transport-specific FFmpeg/mpv options and validate timeouts carefully. mpv documents special RTSP timeout caveats. Multicast permission and Android network locks belong in this branch only.

### Configuration redesign

Replace the current marketing-style four presets with policy plus transport implementation:

```text
User policy: Ultra Live | Low Latency | Balanced | Stability
                      +
Detected transport: HTTP-TS | HLS | LL-HLS | RTSP/RTP/UDP
                      =
validated mpv/native configuration
```

Make **Low Latency** the default for live TV after rollout validation; preserve Balanced for VOD. Consider **Ultra Live** an opt-in sports mode until its rebuffer rate passes acceptance testing.

### Exit criteria

- Clean-start client-added delay meets the transport targets in Section 3.
- Rebuffer ratio remains below 0.5% on the stable-network suite.
- No regression in audio/video sync, subtitles, hardware decode, channel switching, or VOD.
- Every mpv property set is checked and failures are observable instead of silently swallowed.

## 8. Phase 4 — Build a live-latency controller

**Priority:** P0  
**Duration:** 5-7 engineering days

Low startup latency is insufficient. A sports stream can fall behind after every stall and never recover. Add a small state machine:

```text
Unknown -> Measuring -> AtTarget
                       |       \
                       v        v
                    CatchingUp  HardResync
                       \       /
                        Cooldown
```

### Policy

- **At target:** play at 1.0x.
- **Soft catch-up:** when a trustworthy offset is modestly above target and the cache is healthy, temporarily use approximately 1.01x-1.03x. Apply hysteresis so speed does not oscillate. Verify audio pitch and lip sync.
- **Hard resync:** when drift is large, offset confidence is low but a reopen comparison proves lag, or catch-up would take too long:
  - progressive TS: stop, clear/drop buffered data, and reopen the socket;
  - HLS: seek to the current live/default edge when supported, otherwise clear buffers and reopen the latest playlist;
  - LL-HLS/native player: seek to configured live edge.
- **After a stall:** reassess offset immediately. Do not wait for a playback error if the player is continuing 30 seconds behind.
- **Cooldown:** prevent repeated resets during a bad network period; temporarily increase the target offset rather than loop.

Suggested initial thresholds for experimentation—not final constants:

- soft catch-up above target by 1.5-6 seconds;
- hard resync above target by 8-10 seconds;
- immediate hard resync above 20 seconds;
- 30-second cooldown after hard resync.

Make thresholds remotely configurable by platform/transport after they are guarded by safe bounds.

### mpv integration requirements

- Add a typed `command` operation to the engine abstraction for verified commands such as experimental `drop-buffers`, rather than abusing `setProperty`.
- Restore speed to exactly 1.0 on source switch, pause/resume, stop, errors, and exit from catch-up.
- Never run catch-up for VOD.
- Coordinate with the existing operation-epoch and retry code so a delayed resync cannot reopen an old channel.

### Exit criteria

- A 3-5 second induced stall returns to target offset automatically.
- A deliberately accumulated 20-second lag hard-resyncs once and returns near the edge.
- No reopen loops on a bandwidth-limited network.
- Channel switches cannot trigger a stale catch-up or reopen action.

## 9. Phase 5 — Provider endpoint selection

**Priority:** P1, but P0 if Phase 0 finds upstream delay  
**Duration:** 2-4 engineering days plus provider coordination

Test each provider-supported live endpoint:

- `.ts` progressive;
- standard `.m3u8`;
- any documented low-latency or direct-source endpoint;
- alternate region/edge hostname if officially provided.

Select per provider/channel using measured results, not a universal preference. Raw TS will often give the client fewer segment-boundary delays, while a well-produced LL-HLS feed can provide both a defined live edge and scalable low latency. Conventional HLS with long segments may be substantially later.

If every fresh direct player is about 77 seconds late:

- present the evidence to the provider, including sanitized test timestamps;
- ask whether the channel is transcoded/restreamed, whether a direct source exists, and what their encoder/GOP/segment latency is;
- do not add a Hope TV relay expecting it to create missing real-time media—a relay normally adds another hop;
- if Hope TV controls ingestion, evaluate SRT/RIST contribution followed by LL-HLS for scale, or WebRTC where sub-second interaction is truly required.

### Exit criteria

- The lowest-latency reliable endpoint is selected automatically or stored per provider.
- Unsupported variants fall back safely.
- Provider-imposed delay is surfaced in diagnostics and product/support documentation.

## 10. Phase 6 — Web proxy audit

**Priority:** P1  
**Duration:** 2-3 engineering days

The Cloudflare proxy must be validated independently:

- stream response bodies without reading/combining segment media into memory;
- apply `Cache-Control: no-store` or an equivalent safe policy to live manifests unless deliberate sub-second revalidation is implemented;
- never cache progressive TS;
- preserve required range, content-type, and redirect behavior;
- rewrite every HLS child manifest, key, map, part, preload hint, and segment URI correctly;
- record upstream `Age`, CDN cache status, and timing in debug response headers without exposing credentials;
- compare native versus Web provider-edge freshness.

There are currently two worker implementations and their HLS behavior should be unified and tested to prevent deployment-specific drift.

### Exit criteria

- Repeated manifest requests never return an older media sequence.
- Web adds no more than one second beyond native under the same provider/network conditions.
- LL-HLS playlists, if supported, pass a dedicated URI-rewrite and no-buffer test suite.

## 11. Phase 7 — Decide whether mpv remains the only engine

**Priority:** P2  
**Duration:** one-week spike, only if earlier phases miss targets

Keep mpv as the baseline because it supports the broad transport mix and already powers the app. Do not migrate blindly. Run an Android Media3/ExoPlayer spike for HLS/LL-HLS because Media3 exposes current live offset, target offset, default live position, and a proportional live-speed controller directly. Compare:

- same endpoint and device;
- startup and 90-minute drift;
- HLS and LL-HLS correctness;
- hardware decode and 50/60 fps sports performance;
- subtitles/audio tracks;
- failure recovery;
- maintenance cost.

On Apple platforms, perform a smaller AVPlayer spike if iOS becomes a release target with strong HLS requirements. AVPlayer exposes forward-buffer controls, but the server still determines whether real LL-HLS is possible.

Adopt a native engine only per platform/transport where it beats mpv materially and passes feature parity. Preserve the existing `PlayerEngine` abstraction to make this possible.

## 12. Testing and rollout gates

### Automated tests

- transport sniffing and descriptor tests;
- HLS fixture parser tests for standard, DVR, LL-HLS, discontinuities, missing PDT, variable segments, and redirects;
- latency-controller state-machine tests using a fake clock;
- soft catch-up hysteresis and reset tests;
- hard-resync cooldown tests;
- stale-operation/channel-switch race tests;
- proxy manifest rewriting tests, including LL-HLS tags;
- log redaction tests for username/password/query credentials;
- live policy must never affect VOD tests.

### Device matrix

- low-end Android TV box;
- current Android phone/tablet;
- Windows with hardware decode;
- Windows forced software decode;
- iOS if in active release scope;
- Chrome/Web through the production proxy.

### Network matrix

- stable network at >= 2x stream bitrate;
- 1.2x stream bitrate;
- jitter and 1% packet loss;
- short outage;
- bandwidth drop/recovery;
- Wi-Fi-to-mobile or interface transition where supported.

### Release gates

- No more than five seconds beyond the best direct player on the same URL/device/network at p95.
- No session drifts more than two seconds over its clean-start baseline during a stable 90-minute test.
- Automatic recovery from a short impairment returns within two seconds of the configured target within 30 seconds, or performs one safe hard resync.
- Rebuffer ratio and crash/error rate are not worse than the current release.
- A kill switch can restore the old profile and disable automatic correction.

Roll out in stages: internal diagnostics, 5% sports users, 25%, 50%, then 100%. Segment results by provider, transport, platform, device capability, and network class. Never aggregate away a provider that is consistently 60+ seconds late.

## 13. Concrete backlog

| ID | Priority | Work item | Main output |
|---|---|---|---|
| LAT-001 | P0 | Four-way baseline of reported channel | Root-cause classification |
| LAT-002 | P0 | Credential-safe stream probe | Sanitized protocol/edge report |
| LAT-003 | P0 | Centralized live-source resolver | Actual typed transport everywhere |
| LAT-004 | P0 | Live-edge metrics | Offset/drift in HUD and telemetry |
| LAT-005 | P0 | HTTP-TS low-latency A/B profile | Validated startup profile |
| LAT-006 | P0 | HLS/LL-HLS live-start profile | Segment-aware edge startup |
| LAT-007 | P0 | Latency controller | Soft catch-up and hard resync |
| LAT-008 | P0 | Recovery/race integration | No stale channel reopen |
| LAT-009 | P1 | Provider endpoint benchmark | Per-provider endpoint choice |
| LAT-010 | P1 | Web proxy freshness audit | No cached/stale live delivery |
| LAT-011 | P1 | Production dashboards and alerts | Provider/client separation |
| LAT-012 | P2 | Android Media3 comparison spike | Evidence-based engine decision |

## 14. Recommended first sprint

Do these in this order:

1. Reproduce the exact 77-second channel with the four-way comparison.
2. Determine whether reopening Hope TV jumps forward.
3. Probe both `.ts` and `.m3u8` variants if the account supports them.
4. Add detected transport and cache duration to a sanitized trial report.
5. A/B current Balanced versus a temporary HTTP-TS low-latency configuration.
6. Only after the data, implement the permanent descriptor and controller.

The sprint is successful even if it proves the provider supplies a stream already 70+ seconds late. That evidence prevents risky player changes from being shipped for a delay the client cannot remove.

## 15. Authoritative references

- [mpv reference manual: low-latency playback, cache, HLS bitrate, and live buffer behavior](https://mpv.io/manual/master/)
- [mpv source documentation for the low-latency profile and `drop-buffers`](https://github.com/mpv-player/mpv/blob/master/DOCS/man/mpv.rst)
- [FFmpeg `ffprobe` documentation](https://ffmpeg.org/ffprobe.html)
- [FFmpeg format documentation: HLS segmentation, program date/time, and low-latency formats](https://ffmpeg.org/ffmpeg-formats.html)
- [IETF RFC 8216: HTTP Live Streaming and program date/time mapping](https://datatracker.ietf.org/doc/html/rfc8216)
- [Apple: Enabling Low-Latency HLS](https://developer.apple.com/documentation/http-live-streaming/enabling-low-latency-http-live-streaming-hls)
- [Apple HLS authoring specification](https://developer.apple.com/documentation/http-live-streaming/hls-authoring-specification-for-apple-devices/)
- [Android Media3: live streaming and target live offset](https://developer.android.com/media/media3/exoplayer/live-streaming)
- [Android Media3 `DefaultLivePlaybackSpeedControl`](https://developer.android.com/reference/androidx/media3/exoplayer/DefaultLivePlaybackSpeedControl)

## 16. Final principle

Optimize for **distance from the provider's current edge**, continuously, and report the provider's own delay separately. A tiny buffer does not guarantee low latency; a player that starts close but never catches up after a stall will still become a minute late. The durable solution is measured live-edge startup plus active drift correction, backed by a provider path capable of delivering truly current media.
