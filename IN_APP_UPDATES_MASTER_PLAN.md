# HOPE TV In-App Updates — LLM Agent Master Plan

**Owner perspective:** Senior Flutter engineer  
**Target platforms:** Android / Android TV (`arm64-v8a`) and Windows (`x64`)  
**Distribution:** GitHub Releases  
**Control plane:** Supabase PostgreSQL + Edge Functions  
**Implementation goal:** Ship the smallest reliable update flow quickly, using the update code already in this repository.

## 1. Definition of done

When HOPE TV starts, resumes, or the user taps **Check for updates**:

1. The app reads its installed version and build number from the built package.
2. It asks the public Supabase `version` Edge Function for the latest stable release matching its platform and architecture.
3. Supabase returns a signed manifest only when a newer, published, non-revoked release exists.
4. Flutter verifies the manifest signature before showing update details.
5. The user taps **Download update**.
6. For a public GitHub repository, the authenticated Supabase `downloads` function returns the permanent GitHub Release asset URL and records the authorization event.
7. Flutter opens that URL with the operating system. Android downloads/installs the APK through the native package installer; Windows downloads/runs the signed installer.
8. A mandatory update cannot be dismissed or bypassed while the old build remains installed.

This is an **update prompt and OS hand-off**, not a silent or background installer. Do not add an APK installer plugin, Windows self-updater, delta patches, Supabase Storage, Cloudflare R2, or a custom download proxy in v1.

## 2. Existing implementation to preserve

The repository already has most of the intended architecture:

- `.github/workflows/release.yml` builds Android and Windows, publishes GitHub Release assets, calculates SHA-256 values, and attempts to register release rows in Supabase.
- `public.release_versions` is already the update catalog.
- `supabase/functions/version/index.ts` looks up the newest release and builds/signs a manifest.
- `supabase/functions/downloads/index.ts` validates a release, returns its GitHub URL, and writes a download event.
- `lib/core/releases/` already models and verifies release manifests.
- `lib/features/updates/` already contains Riverpod state and update UI.
- `lib/app/app.dart` already performs a check after sign-in.
- `docs/commercial/adr/0008-github-releases.md` already makes GitHub Releases the canonical binary store.

Extend these files. Do not create a second update subsystem.

## 3. Confirmed blockers in the audited repository snapshot

These blockers were confirmed when this plan was written, but the repository may change before implementation begins. **Before editing any code, the implementing agent must re-check every blocker against the current branch and working tree.** For each blocker, record one of: `still present`, `partially solved`, `already solved`, or `not applicable`, with file/line or test evidence.

If a blocker is already solved, do not reimplement, revert, duplicate, or replace the working solution merely to match this plan. Verify it satisfies the corresponding acceptance gate, preserve it, and continue with only the remaining work. If it is partially solved, identify the exact gap and make the smallest compatible change.

The implementing agent must fix these before calling the feature complete:

### P0 — Release lookup never matches the produced binaries

CI writes Android rows as `arm64-v8a` and Windows rows as `x64`. `UpdateService` sends no `architecture`, so `version` defaults to `universal`. The SQL function requires an exact architecture match. Current production releases therefore return no update.

### P0 — Installed build metadata is hard-coded

`AppConstants.appVersion` is `0.1.0` and `appBuildNumber` is `1`. CI reads `pubspec.yaml`, while the running app reads unrelated constants. These values will drift and break comparisons.

### P0 — Release signature configuration is absent from CI

Flutter verifies with `RELEASE_PUBLIC_KEYS_JSON`, but the release builds currently inject only `SUPABASE_URL` and `SUPABASE_ANON_KEY`. A correctly signed server manifest cannot be verified unless the matching public key is compiled into the app.

### P0 — Android production signing is not configured

The Android release build still uses the debug key and the placeholder `com.example.iptv` application ID. Android will reject future updates if the signing identity changes. Production identity and signing must be fixed before the first customer APK.

### P0 — The release workflow runs on every push to `main`

It can repeatedly publish the same `v0.1.0` tag, race the Android and Windows jobs against the same release, and register duplicate metadata. Releases must be explicit, versioned operations.

### P1 — Supabase registration can fail silently

The workflow's `curl -s` does not fail the job for HTTP errors. Its upsert does not explicitly name the composite conflict target. A GitHub Release can succeed while Supabase remains stale.

### P1 — Mandatory updates are not actually blocking

The current dialog closes after opening the download URL. Returning to the still-old app leaves the user inside the product. The app must re-check on resume and keep a mandatory blocking surface active until the installed build meets the requirement.

### P1 — Update checks are tied to signed-in analytics startup

The `version` function is intentionally public, but automatic checks only happen for signed-in users. Every install must be able to discover critical updates. Download authorization may remain authenticated for v1 because the product already expects an app account.

### P1 — No update-specific tests exist

There are no focused unit/widget/Edge Function tests for platform selection, build comparison, signature failure, dialog behavior, or revoked releases.

## 4. Target architecture

```text
Owner dispatches versioned GitHub workflow
                |
                v
    Android APK + Windows installer
                |
                v
       one GitHub Release/tag
                |
                v
 workflow upserts two metadata rows in Supabase
                |
                v
 Flutter --GET--> public Supabase version function
                |
                v
       signed release manifest
                |
      Flutter verifies Ed25519
                |
 user clicks update (authenticated)
                |
 Flutter --POST--> Supabase downloads function
                |
                v
      public GitHub Release asset URL
                |
                v
      OS browser / native installer
```

Supabase decides **which release is valid**. GitHub stores and serves **the binary**. Flutter decides **whether the response is trusted and how to present it**.

## 5. Fixed v1 decisions

The agent should implement these decisions without adding alternative architectures:

- Stable channel first. Keep beta/internal fields, but do not build channel-selection UI.
- One Android artifact: `arm64-v8a` APK.
- One Windows artifact: `x64` Inno Setup installer.
- Public GitHub Release asset URLs in `release_versions.object_key`.
- External OS installation via `url_launcher`.
- Integer `build_number` is the only update ordering key. Semantic version is display metadata.
- Ed25519 signs manifests. HMAC stays local-development-only.
- Supabase service-role credentials exist only in GitHub Actions and Supabase server code, never in Flutter.
- A release is visible only when `published_at IS NOT NULL` and `revoked_at IS NULL`.
- A network or server failure never blocks an optional update. A previously verified mandatory policy may continue blocking according to the caching rules below.

## 6. Implementation sequence

The agent must complete phases in order and keep the project buildable after every phase.

### Phase 0 — Establish release invariants

Files:

- `pubspec.yaml`
- `android/app/build.gradle.kts`
- Android signing properties/files referenced by Gradle (secrets must remain untracked)
- `installer/windows/hope_iptv.iss`
- `.gitignore`

Tasks:

1. Change `pubspec.yaml` to a real monotonically ordered value using `major.minor.patch+build`, for example `0.1.0+1`.
2. Choose and permanently set the production Android `applicationId`. Do not ship `com.example.iptv`.
3. Configure a release keystore through CI secrets. Commit only the Gradle wiring and safe templates; never commit the keystore, passwords, or generated `key.properties`.
4. Verify Android upgrade compatibility by installing build `N`, then installing build `N+1` over it without uninstalling.
5. Keep the Inno Setup `AppId` stable forever. Make installer version/build metadata come from the workflow.
6. Add Authenticode signing as a production gate if a certificate is available. If not available, mark Windows signing as an explicit owner blocker; do not pretend the installer is trusted.

Acceptance gate:

- Android release is signed with the permanent production key.
- `flutter build apk --release --target-platform android-arm64` produces an installable upgrade.
- The Windows installer upgrades the same `AppId` in place.

### Phase 1 — Use one runtime source of truth for version/build

Files:

- `pubspec.yaml`
- `lib/core/releases/update_service.dart`
- `lib/core/constants/app_constants.dart`
- optionally a small `lib/core/releases/installed_app_info.dart`
- tests under `test/updates/`

Tasks:

1. Add `package_info_plus` with the newest version compatible with the repo's Flutter SDK.
2. Read `PackageInfo.version` and `PackageInfo.buildNumber` at runtime. Parse build number strictly as a positive integer; log and fail the update check safely if invalid.
3. Inject an `InstalledAppInfo` abstraction into `UpdateService` so tests do not invoke platform channels.
4. Remove update comparisons from the hard-coded `AppConstants` values. Constants may remain temporarily for unrelated display text, but update logic must not use them.
5. Send all four query values: `platform`, `architecture`, `buildNumber`, and `channel`.
6. Map supported targets explicitly:
   - Android / Android TV -> platform `android`, architecture `arm64-v8a`
   - Windows -> platform `windows`, architecture `x64`
   - Web and unsupported platforms -> skip native update checks

Acceptance gate:

- A fake installed build `1` finds server build `2`.
- Build `2` does not find build `2`.
- Android and Windows request the exact architecture stored by CI.
- Web performs no native update request.

### Phase 2 — Make the Supabase release query deterministic

Files:

- a new additive migration under `supabase/migrations/`
- `supabase/functions/version/index.ts`
- `supabase/functions/_shared/release_signing.ts`
- related Deno tests

Tasks:

1. Validate `platform`, `architecture`, `channel`, and `buildNumber`; reject unknown values instead of silently coercing them.
2. Update the SQL lookup function to order by `build_number DESC, published_at DESC` rather than publication time alone.
3. Keep exact architecture matching. Do not add a `universal` fallback unless a real universal binary is published.
4. Return no manifest when the latest eligible build is not greater than the installed build.
5. Ensure revoked and unpublished releases can never be selected.
6. Make signature failure a server error. Remove the current behavior that catches a signing error and returns an unsigned body which Flutter will inevitably reject.
7. Keep the public `version` function free of secret data and service-role output.
8. Include a stable machine-readable error code and correlation ID in errors.

Required Edge Function/SQL cases:

- exact Android architecture match
- exact Windows architecture match
- no architecture match
- newer build available
- same/older build unavailable
- newest release revoked -> next valid release selected
- unpublished release ignored
- signing secret missing -> `503 misconfigured`, never unsigned success

Acceptance gate:

- `version` returns a signed manifest for build `N+1` and `updateAvailable: false` for build `N+1`.
- The Flutter verifier accepts the configured key and rejects a one-byte manifest mutation.

### Phase 3 — Configure release trust end to end

Files:

- `.github/workflows/release.yml`
- `docs/commercial/RELEASE_SIGNING.md`
- `supabase/.env.example` using placeholders only

Tasks:

1. Generate one Ed25519 release keypair outside the repository.
2. Put only the private signing key in Supabase Edge Function secrets.
3. Put the public key and its non-secret key ID in GitHub Actions variables/secrets as appropriate.
4. Pass `RELEASE_PUBLIC_KEYS_JSON` to both Android and Windows Flutter builds using `--dart-define`.
5. Configure Supabase with matching `RELEASE_SIGNING_ALG`, key ID, and private key values expected by `_shared/release_signing.ts`.
6. Never use `RELEASE_HMAC_VERIFY_SECRET` in a production client build. A shared HMAC secret inside an APK/EXE is extractable and would allow manifest forgery.
7. Document rotation: ship a client that trusts old+new public keys, switch server signing to new, wait for adoption, then remove old in a later client.

Acceptance gate:

- A production-mode local/integration request yields a manifest accepted by Android and Windows release builds.
- Removing or changing the configured public key produces a visible, non-crashing update error and never shows a download button.

### Phase 4 — Make release publishing explicit and atomic enough

Files:

- `.github/workflows/release.yml`
- optional small checked-in scripts under `tool/release/` if they reduce duplicated shell

Tasks:

1. Remove the `push: branches: [main]` release trigger. Retain `workflow_dispatch`; optionally add a tag trigger only after the manual path is proven.
2. Require `pubspec.yaml` to contain `x.y.z+positiveBuild` and fail early otherwise. Do not fall back to `github.run_number`.
3. Use a unique immutable tag such as `v0.1.0+1` or `v0.1.0-build.1`; choose one format and document it.
4. Reject publishing when the tag already exists. Do not overwrite a shipped binary under an existing version/build.
5. Build and test Android and Windows in parallel, then use one final publish job to:
   - download both workflow artifacts;
   - create one GitHub Release with both assets;
   - compute/carry forward SHA-256 and file size;
   - upsert both Supabase rows in one request;
   - publish metadata only after both assets exist.
6. Build Android specifically for `android-arm64`; do not call the artifact universal.
7. Make every HTTP command fail on non-2xx (`curl --fail-with-body` or equivalent).
8. Upsert with the explicit conflict target `(platform, channel, version, architecture)` and request the inserted/updated rows back for verification.
9. Assert that Supabase returns exactly two rows matching tag, build, URL, digest, architecture, and channel.
10. Add release notes as workflow input or generate them from the GitHub release; populate both language fields only when supplied.
11. Use a GitHub `production` environment for release secrets and optional manual approval.

Required GitHub secrets/variables:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` (or current client-safe publishable equivalent when the app is migrated)
- `SUPABASE_SERVICE_ROLE_KEY` used only by the final metadata publish step
- Android keystore file encoded for CI plus alias/password secrets
- `RELEASE_PUBLIC_KEYS_JSON` (public material, but keep configuration centralized)
- optional Windows code-signing certificate/password

Do not add `GITHUB_PAT` for a public repository. The workflow's scoped `GITHUB_TOKEN` is enough to create releases, and the client uses public asset URLs.

Acceptance gate:

- One manual dispatch creates exactly one tag, one release, two assets, and two matching Supabase rows.
- Any failed build or failed Supabase registration leaves no release marked available to clients.
- Re-running the same version/build fails before publishing.

### Phase 5 — Complete Flutter update orchestration

Files:

- `lib/core/releases/release_manifest.dart`
- `lib/core/releases/update_service.dart`
- `lib/features/updates/update_controller.dart`
- `lib/features/updates/update_dialog.dart`
- `lib/app/app.dart`
- `lib/features/settings/settings_screen.dart`
- localization ARB/generated files
- tests under `test/updates/`

Tasks:

1. Make the app lifecycle-aware with `WidgetsBindingObserver` (or the existing app lifecycle abstraction):
   - check once after startup configuration is ready;
   - check again on `resumed` only when the last check is older than six hours;
   - always allow a manual settings check.
2. Run the public version check even when signed out. If download authorization remains authenticated, the button should route the user to sign in and then continue the pending download.
3. Add state fields that distinguish `idle`, `checking`, `available`, `downloading/launching`, `upToDate`, and `error`. Avoid one `checking` flag serving unrelated operations.
4. Deduplicate dialogs. A provider rebuild or repeated response must not stack multiple dialogs.
5. Localize all update copy in English and Arabic.
6. Optional update behavior:
   - show version, file size, and localized release notes;
   - **Later** dismisses it;
   - remember `skippedBuildNumber` locally so the same optional release is not shown on every launch;
   - manual check may show it again.
7. Mandatory update behavior:
   - use a full-screen blocking route or non-dismissible dialog;
   - no back navigation, barrier dismissal, or **Later** action;
   - after launching the installer, keep/recreate the block when the old app resumes;
   - re-check on resume; unblock only when installed build is no longer below the mandatory server build;
   - provide **Retry** for network failures and **Exit app** where platform conventions allow.
8. Use `launchUrl(uri, mode: LaunchMode.externalApplication)`. Validate HTTPS and allow only `github.com`, `objects.githubusercontent.com`, or other specifically documented GitHub asset CDN hosts returned by the server. The stored public URL itself should be `github.com/.../releases/download/...`.
9. Treat `canLaunchUrl == false` and `launchUrl == false` as user-visible failures. Keep a retry/copy-link fallback.
10. Do not download the whole installer into Dart memory. The current `verifyFileDigest(List<int>)` is not part of the external-browser MVP. SHA-256 remains release audit metadata; OS code signing is the executable trust boundary.
11. The Settings action must explicitly show one of: update available, up to date, unsupported platform, not configured, or error. Silent return is not acceptable for a manual check.

Acceptance gate:

- Startup and manual flows work on Android and Windows.
- Optional dismissal persists for only that build.
- Mandatory UI survives back, route navigation, and resume.
- Invalid signatures and non-HTTPS/unapproved URLs never produce an actionable update button.
- Screen-reader labels, keyboard/TV focus, and RTL layout are verified.

### Phase 6 — Tests and release rehearsal

Add the smallest useful automated suite:

#### Flutter unit tests

- runtime version/build parsing
- platform/architecture mapping
- request query construction
- valid Ed25519 manifest
- tampered manifest
- invalid/missing signature
- optional skip policy
- mandatory comparison/blocking policy
- URL allowlist

#### Flutter widget tests

- optional dialog has **Later** and **Download**
- mandatory surface has no dismissal path
- repeated provider emissions create one surface
- download launch failure shows retry
- English and Arabic release notes/fallbacks

#### Supabase tests

- deterministic latest-release SQL selection
- unpublished/revoked exclusion
- exact architecture matching
- strict input validation
- signing misconfiguration failure
- download release validation and analytics insert

#### CI/release smoke test

1. Publish an internal test release with build `N+1`.
2. Install build `N` on one Android arm64 device/TV and one clean Windows x64 VM.
3. Confirm both see `N+1`.
4. Confirm download clicks reach the correct assets.
5. Upgrade without uninstalling and confirm local app data remains.
6. Revoke the release in Supabase and confirm new checks no longer offer it.
7. Publish a higher mandatory test build and verify blocking/resume behavior.

Final commands:

```text
dart format <changed Dart files>
flutter analyze
flutter test
deno test supabase/functions
git diff --check
```

Use the repository's actual Deno/Supabase test command if it differs; do not skip a failing suite.

## 7. Release and rollback runbook

### Normal release

1. Merge tested code to `main`.
2. Increment both semantic version and integer build in `pubspec.yaml`.
3. Dispatch the release workflow with channel, release notes, and mandatory flag.
4. Wait for Android, Windows, GitHub Release, and Supabase registration gates.
5. Verify both assets from a clean device before announcing availability.

### Bad binary before broad adoption

1. Set `revoked_at` on both matching Supabase release rows immediately.
2. Keep evidence/audit metadata; do not delete the database row.
3. Remove or clearly mark the GitHub assets/release as withdrawn.
4. Fix the defect and publish a strictly higher build number under a new immutable tag.

### Compromised manifest signing key

1. Stop release publication.
2. Revoke affected release rows.
3. Rotate the Supabase private key.
4. Because old clients trust only the old public key, ship a client trusting the new key through the last trusted release path or a documented manual recovery path.
5. Never silently switch to unsigned manifests.

## 8. Caching and failure policy

- Cache the timestamp and result of the last successful check for six hours.
- Cache `skippedBuildNumber` only for optional releases.
- Cache a verified mandatory manifest through its reasonable validity window so a temporary outage does not trivially bypass an already-known mandatory update.
- Never convert a network error into `upToDate`.
- Never block a first-time user solely because Supabase is unreachable and no verified mandatory manifest has ever been received.
- Log correlation ID, installed build, target build, platform, architecture, and outcome; never log JWTs, service keys, signing secrets, or full signed CDN query strings.

## 9. Scope exclusions for v1

The agent must not expand the task into:

- Google Play in-app updates
- Microsoft Store/MSIX update APIs
- silent install or device-owner Android install
- background binary download manager
- binary patch/delta updates
- Supabase Storage for release binaries
- Cloudflare Worker/R2 download gateway
- private GitHub repository support
- download progress UI
- automatic rollback of an already installed application
- web app service-worker update work

These can be separate follow-up projects after the external-installer flow is proven.

## 10. LLM agent execution rules

1. Start with a blocker re-audit. Check every item in Section 3 against the current code, configuration, migrations, workflow, and tests. Produce a short evidence table before implementation: blocker, current status, evidence, and required action.
2. Treat this plan as desired outcomes, not permission to overwrite newer working solutions. When a blocker is already solved, run or add the smallest verification needed, mark its acceptance criterion satisfied, and skip its implementation tasks.
3. Inspect the listed existing files before editing; preserve unrelated dirty-worktree changes.
4. Implement one phase at a time and run targeted tests after every phase.
5. Re-check dependent blockers after each phase because one fix may resolve multiple findings. Do not perform redundant edits.
6. Use additive Supabase migrations. Never edit an already-applied migration.
7. Do not duplicate repositories, providers, Edge Functions, or release tables.
8. Do not put service-role keys, GitHub tokens, private signing keys, keystores, or certificate passwords in source, logs, examples, Flutter assets, or `--dart-define` values.
9. Do not weaken manifest verification just to make a test pass.
10. Do not claim Android production readiness while the debug signing key or placeholder application ID remains.
11. Do not claim Windows production trust without reporting Authenticode status.
12. Stop and ask the owner only for irreversible identity/secrets decisions: final Android application ID, production signing material, public/private GitHub repository choice, and code-signing certificate availability.
13. At handoff, report the final status of every original blocker—including those already solved before the agent started—plus changed files, migrations, required owner secrets, test commands/results, and the exact remaining manual release rehearsal.

## 11. Recommended delivery slices

### Slice A — Functional MVP

Phases 0–2 and 4–5, using local HMAC only for local testing if production Ed25519 material is not yet available. Do not ship that HMAC in a client.

### Slice B — Production trust

Phase 3, permanent Android signing, Windows Authenticode, and full clean-device rehearsal.

### Slice C — Operational hardening

Mandatory caching, key rotation rehearsal, richer analytics, and release environment approvals.

The feature is production-ready only after Slices A and B pass. Slice C may follow unless mandatory updates are a launch requirement.

## 12. Authoritative references

- GitHub Releases support up to 1,000 assets per release, each under 2 GiB, with no total release-size or bandwidth quota stated: <https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases>
- GitHub Actions secrets and least-privilege guidance: <https://docs.github.com/en/actions/reference/security/secure-use>
- Supabase Edge Function authorization headers and `verify_jwt`: <https://supabase.com/docs/guides/functions/auth-headers>
- Supabase Edge Function secret handling: <https://supabase.com/docs/guides/functions/secrets>
- Flutter package metadata through `PackageInfo.fromPlatform()`: <https://pub.dev/packages/package_info_plus>
