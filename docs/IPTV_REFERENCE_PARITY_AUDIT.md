# IPTV reference-app parity audit

Reviewed 26 September 2026. The two supplied references are extracted Android
packages, not original source trees:

- `D:/maven_tv_10_0` — Flutter package `com.maveniptvac.maven`, version 10.0.0.
- `D:/mavenac/mavenac.zip` — Xamarin package `com.mavenac.mavenac`, version
  3.7.0 (versionCode 25).

The audit uses manifests, packaged assets, native libraries, assembly/resource
names, and recoverable Flutter strings. Those establish that a feature or
engine was packaged, but do not prove runtime quality, defaults, or every code
path. No proprietary implementation was copied.

## What the references do best

Both products separate live, movie, series, and catch-up experiences, expose
audio/subtitle controls, remember viewing state, and support more than one
playback engine. Maven TV 10 packages libmpv and LibVLC; Maven Ac packages
ExoPlayer and LibVLC. Maven Ac also exposes a particularly broad TV feature set:
full EPG, catch-up, recording, downloads, multi-screen, external playback,
network diagnostics, multiple provider users, parental categories, and TV
startup preferences.

Hope TV already has stronger shared foundations than either package can be
shown to have from static inspection: a single typed player contract, common
controls and diagnostics across backends, automatic reconnect, buffer profiles,
companion remote/auth/audio handoff, responsive phone/TV UI, and tests around
the player lifecycle.

## Parity matrix

| Capability | Maven TV 10 | Maven Ac | Hope TV status after this pass |
| --- | --- | --- | --- |
| Live TV, categories, EPG now/next | Packaged | Packaged | Implemented |
| Movies, series, episodes | Packaged | Packaged | Implemented |
| Search | Packaged | `MasterSearchActivity` | Implemented |
| Favorites and recent/resume | Packaged | Packaged | Implemented |
| Catch-up / TV archive | Packaged | Dedicated screens/player | **Implemented in this pass** |
| Audio and subtitle track selection | Packaged | Packaged | Implemented where backend supports it |
| Playback speed | Packaged | Packaged | Implemented |
| Aspect-ratio modes | Packaged | Aspect control resource | **Unified in this pass:** Best Fit, Fit, Fill, 16:9, 4:3 |
| Multiple playback engines | mpv, VLC, BetterPlayer evidence | ExoPlayer, VLC | MediaKit/mpv, Media3, VLC with explicit recovery selection |
| TV launcher/banner and D-pad UI | Leanback launcher | Dedicated TV activity | Implemented; real-device QA remains |
| Parental protection | Settings/assets evidence | Parental category activities | Implemented for kids/PIN paths; category-wide policy needs audit |
| Full EPG timeline/grid | EPG assets | `DownloadEpg`, full EPG resources | Partial: guide data and archive list exist, timeline grid does not |
| Multi-screen playback | Not established | `MultiScreen` | Not implemented |
| Recording and recording library | Not established | Recording/player activities | Not implemented |
| Content download/offline library | Not established | `ContentDownloader` | Not implemented |
| External-player handoff | Not established | External player resources | Not implemented |
| Network speed diagnostics | Not established | `NetSpeedActivity` | Partial: player metrics exist; guided speed test does not |
| Multiple IPTV provider profiles | Accounts evidence, exact behavior unknown | `UserList` and M3U flows | Partial: app account/device layer plus one active IPTV session |
| M3U/local/network media browser | M3U strings | Dedicated M3U/local media flows | Not implemented |
| Start on device boot | Boot receiver | Autoplay/start-on-boot strings | Not implemented |
| VPN profile management | Not established | `VPNAddProfile` | Deliberately deferred; prefer Android VPN-provider integration |
| Background media session | Player service | Package evidence inconclusive | Not implemented as a durable Android media session |

## Changes delivered in this pass

### Consistent aspect-ratio behavior

Aspect ratio is now a domain value instead of unrelated magic indices. The
choice persists across launches and has the same meaning on MediaKit, Media3,
VLC, and web:

- **Best Fit** preserves the source without cropping.
- **Fit** applies a small safe crop to reduce edge bars.
- **Fill** covers the viewport and may crop.
- **16:9** and **4:3** create explicit frames and stretch inside that selected
  frame, matching the conventional IPTV-player behavior.

Invalid legacy preference values recover to Best Fit. The modes and controller
behavior have regression tests.

### Catch-up TV

Channels advertised by Xtream as archive-enabled now expose Catch-up TV from
the list overflow menu and mini preview. The screen requests the channel's full
EPG, keeps completed programmes inside the provider's archive duration, sorts
newest first, supports remote focus, and builds a UTC Xtream timeshift URL.
Catch-up opens through the same player pipeline, so backend choice, retries,
tracks, aspect ratio, diagnostics, and history behavior stay consistent.

### Playback-engine modernization already present on this branch

The player offers MediaKit/libmpv, Android Media3, and LibVLC behind one engine
contract. Unsupported controls are capability-gated rather than failing at
runtime. The active engine is shown in diagnostics, and the recovery UI can
switch engines without duplicating the player screen. See
`docs/MAVEN_AC_PLAYER_FINDINGS.md` for the dependency and package evidence.

## Stability rules for the remaining work

1. Do not build separate player screens per engine or content type. Add
   capabilities to `PlayerEngine` and keep one controller/state model.
2. Add large features vertically and independently: domain model, repository,
   controller, TV-first screen, then tests. Catch-up follows this structure.
3. Never log or persist playable URLs containing provider credentials outside
   the existing secure session boundary.
4. Gate recording, downloads, and multi-screen by storage, decoder, and device
   capability. Four simultaneous decoders are not safe on every TV chipset.
5. Ship backend changes only after H.264, HEVC, MPEG-TS, HLS, MP4, subtitles,
   channel-zap, app-background, and exit/reopen tests on physical TV devices.

## Remaining delivery order

1. **TV reliability:** physical-device matrix, lifecycle/background recovery,
   remote long-press/repeat, release split-size measurement, crash telemetry.
2. **Full EPG:** horizontally virtualized timeline using the same guide data;
   open live or catch-up depending on programme time.
3. **External player and network diagnostics:** low-risk recovery tools with
   credential warnings and redacted telemetry.
4. **Recording/download library:** foreground service, storage-access framework,
   quota/cleanup, resumable jobs, and legal/provider capability messaging.
5. **Multi-screen:** decoder-capability probe, two-pane default, optional four
   panes, one audible pane, strict teardown tests.
6. **Provider profiles and M3U:** encrypted credentials, isolated caches/history,
   profile switch lifecycle, playlist/EPG validation.
7. **Boot/background options:** opt-in Android TV receiver and a proper Media3
   media session only after lifecycle tests pass.

This matrix is intentionally conservative: “packaged” is not treated as proof
that a reference feature is stable, and “partial” is not presented as parity.
