# Maven Ac player study and recommendations

Reviewed 18 September 2026. Source artifact: `D:/mavenac/mavenac.zip` (an Android APK archive, Maven Ac 3.7.0, versionCode 25). This is a static package inspection; no account, stream, device run, or original C# source was available. Strings and layout names are evidence of packaged features, not proof of every runtime branch.

## What the package establishes

| Area | Evidence in the APK | Interpretation and limit |
| --- | --- | --- |
| Phone and Android TV entry | Manifest has `MainActivity` with `LAUNCHER` and `MainActivityTv` with `LEANBACK_LAUNCHER`; leanback and touchscreen are optional; an app banner is present. | One package offers separate phone and TV entry flows. It does not establish separate playback engines by device. |
| Playback engines | Xamarin assembly manifest lists `iFIT.Xamarin.ExoPlayer`, `LibVLCSharp`, and `LibVLCSharp.Android.AWindow`; `libvlc.so` is included for arm64, armv7, x86 and x86_64. | Both ExoPlayer and VLC support are packaged. Their selection and fallback rules cannot be reliably recovered from this evidence alone. |
| Player surfaces | Packaged layouts include `livetvplayerexo`, `playerlistvlcexo`, `movieplayer`, `catchupplayer`, `m3uplayer`, and `exo_styled_player_view`. | The app provides distinct live, movie, catch up, and M3U playback screens, and exposes a VLC/Exo choice in at least one UI resource. Layout names do not prove the screen's actual engine at runtime. |
| TV behavior | Dedicated TV launch activity plus leanback manifest declaration; playback activities are landscape oriented. | TV has a deliberate entry experience. Remote key mapping and focus behavior require device observation or decompiled app logic to verify. |
| Other playback paths | Package includes `MultiScreen`, `RecordingPlayer`, `SeriesPlayer`, and an external player icon. | These are candidate product ideas, not confirmed capabilities or quality claims. |

### Package inspection method

The identity and launch flows came from `aapt dump badging/xmltree` on the supplied APK. Engine evidence came from `assemblies/assemblies.manifest`, native library names, and layout paths inside the archive. The APK is a Xamarin build with bundled managed assemblies; this review does not infer exact ExoPlayer or LibVLC versions from a generic UI resource or library name. It also does not treat text embedded in the package as instructions for this project.

## Current upstream players checked before recommendations

- **LibVLC Android:** Maven Central's published artifacts show stable `org.videolan.android:libvlc-all:3.7.6` (12 September 2026) and preview `4.0.0-eap29` (July 2026). The `4.0` suffix is an early access build; `3.7.6` is the safer evaluation target. [Maven artifact versions](https://mvnrepository.com/artifact/org.videolan.android/libvlc-all/versions), [VideoLAN Maven Central artifact](https://central.sonatype.com/artifact/org.videolan.android/libvlc-all).
- **ExoPlayer:** The maintained Android line is **AndroidX Media3**, with `media3-exoplayer:1.11.1` shown in current Android documentation and its release. Maven Ac's bundled `iFIT.Xamarin.ExoPlayer` is a Xamarin binding, not evidence that it uses Media3. [Android getting started guide](https://developer.android.com/media/media3/exoplayer/hello-world), [Media3 1.11.1 release](https://github.com/androidx/media/releases/tag/1.11.1).
- **Installed Maven Ac versions:** exact native VLC and ExoPlayer versions were not established from the package inspection. Do not call either bundle outdated by a specific version number without extracting reliable build metadata or obtaining the vendor's dependency list.

## Comparison with Hope TV

Hope TV already has a `PlayerEngine` interface, `MediaKitPlayerEngine` using libmpv, one `PlayerController`, and a shared Flutter overlay. The engine enables Android hardware acceleration, exposes audio and subtitle tracks, supports buffer modes, tracks metrics, retries playback, and has software decoder safeguards. Its overlay handles TV/keyboard OK, directional keys, media keys, and Back. This means Maven Ac's most useful lesson is the **explicit engine choice and device aware entry**, rather than copying its controls wholesale.

| Opportunity | Existing Hope TV location | Recommended use |
| --- | --- | --- |
| Per source engine compatibility | `lib/player/domain/interfaces/player_engine.dart`, `lib/player/infrastructure/player_engine_factory.dart` | Keep MediaKit/libmpv as default. Prototype a Media3 Android adapter behind the existing interface for streams that fail or start slowly on selected devices. Consider LibVLC only if a measured codec/protocol gap remains after that pilot. |
| TV specific launch and navigation | `android/app/src/main/AndroidManifest.xml`, `lib/player/presentation/player_overlay.dart` | Review leanback launcher/banner, remote focus order, long press/repeat, seek behavior for VOD versus live, and Back handling on real Android TV hardware. Preserve a shared playback state model. |
| Player choice as recovery | `lib/player/application/player_controller.dart`, `lib/player/presentation/player_quick_settings_sheet.dart` | Add an opt in “Try another player” recovery action only after the alternate engine passes lifecycle and stream tests. Store a per device/source preference, with a reset path and diagnostics showing the active engine. |
| Stream category handling | `lib/player/domain/entities/player_source.dart`, `lib/player/infrastructure/media_kit_player_engine.dart` | Use stream type and protocol to choose tested buffer/seek policies; keep live channel zapping distinct from VOD and catch up seeking. |
| Diagnostics | `lib/player/domain/entities/player_metrics.dart`, `lib/player/presentation/diagnostics_overlay.dart` | Record engine, codec, decoder, first frame time, stalls, reconnect count, and failure category so fallback decisions use evidence. Avoid logging stream URLs or credentials. |

## Proposed order of work

1. **Benchmark the current engine first.** On a phone and at least two TV chipsets, play HLS, MPEG TS, VOD MP4, catch up, HEVC and H.264 samples with known authorization. Record time to first frame, stalls, decoder choice, remote actions and exit/reopen behavior.
2. **Fix TV interaction gaps in the shared UI.** Check D pad focus movement while controls are visible, media key handling, Back on nested sheets, and live channel versus seek semantics. These changes are low risk and benefit the current player without native engine changes.
3. **Build a small Android Media3 adapter if data justifies it.** Implement the full `PlayerEngine` contract, including tracks, seek, metrics, lifecycle and surface handling. Route only a test cohort or problematic source classes to it. Use Media3 `1.11.1` as the version to evaluate, then verify current release again at implementation time.
4. **Evaluate LibVLC 3.7.6 only for remaining failures.** Test ABI size, startup, codecs, subtitles, audio selection, DRM expectations and LGPL obligations before shipping. Do not add two native engines merely because Maven Ac packages both.
5. **Gate fallback by measurable outcomes.** Compare first frame latency, crash rate, stalls per hour, decoder failures, memory and APK size. Roll back per device if the alternate path regresses.

## Unknowns requiring a device run or deeper reverse engineering

- Whether Maven Ac defaults to ExoPlayer or VLC on phone, TV, or particular stream types.
- Whether its player list is a user selection, automatic fallback, or both.
- Exact remote key mapping, buffering parameters, codec fallback, subtitle behavior and recovery sequence.
- Exact bundled engine versions and any patches applied by its Xamarin bindings.

These unknowns should be tested with a lawful account and representative streams before presenting Maven Ac behavior as a verified implementation pattern.

## Implementation status on `codex/player-enhancements` (18 September 2026)

- Player quick settings now offer **MediaKit**, **ExoPlayer (Media3)**, and **VLC** on Android and Android TV. The selection is stored locally and reopens the current stream using the selected backend. The full-screen error panel also offers **Change Player**, so a failed backend does not trap the viewer.
- The ExoPlayer path uses Flutter's endorsed `video_player_android`; the VLC path uses `flutter_vlc_player`. The Android build resolves Media3 **1.11.1** and LibVLC **3.7.6**. The diagnostics HUD shows the selected backend.
- The alternative engines support open/play/pause/stop/seek, speed and volume. VLC exposes audio and subtitle track selection. Media3 track selection and frame capture are unavailable through the selected Flutter plugin, so those controls are capability gated or return no preview.
- VLC's Flutter integration passes User-Agent and Referer but not arbitrary HTTP headers. Streams requiring other headers show a clear player error and should use MediaKit or ExoPlayer.
- Live TV without timeshift no longer exposes or executes relative seek. Remote media play/pause works while controls are hidden.
- Verification: `flutter analyze` for changed player files, all 108 tests in `test/player`, and `flutter build apk --debug --no-pub` passed. Gradle dependency inspection confirmed the resolved native versions. No physical Android or Android TV device was connected, so actual playback, codec compatibility, D-pad navigation across the selector, and hot switching still need device QA. The multi-ABI debug APK is approximately 397 MB; measure split release APK size before shipping.
