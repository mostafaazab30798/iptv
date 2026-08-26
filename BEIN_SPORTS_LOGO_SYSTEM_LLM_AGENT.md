# BEIN SPORTS Logo System — LLM Agent Instructions

## Goal

Implement a small, isolated logo-resolution subsystem for the Flutter IPTV app that provides reliable **beIN SPORTS logos** even when the IPTV provider's logo URL is unavailable.

The implementation must work entirely from the Flutter application side. No IPTV server changes are required.

Use the `tv-logo/tv-logos` repository only as a development/source reference:

https://github.com/tv-logo/tv-logos

Do not make the production app depend on GitHub at runtime.

---

## 1. Safety and Licensing

This is an artwork fallback system, NOT a network-circumvention mechanism.

Never implement:

- VPN/proxy functionality.
- DNS or routing bypasses.
- Traffic tunneling.
- Government/network-block circumvention.
- Unauthorized scraping.
- Credential interception.
- Access-control bypass.

Before bundling any third-party beIN artwork:

1. Inspect the repository's current LICENSE.
2. Inspect its README and asset terms.
3. Verify whether redistribution in a commercial application is permitted.
4. Preserve required attribution/license notices.
5. If commercial redistribution is unclear, do not ship the asset until permission is confirmed.

Remember that trademark ownership and repository licensing are separate issues.

---

## 2. Scope

Initially support **only beIN SPORTS logos**.

Do not import the entire tv-logo repository.

Only include logos actually required by the IPTV source and legally permitted for redistribution.

---

## 3. First Inspect the Existing Project

Before changing code:

1. Inspect the Flutter project.
2. Inspect the existing Channel model.
3. Inspect Xtream/API integration.
4. Inspect existing image widgets.
5. Inspect existing image caching.
6. Inspect asset conventions.
7. Inspect localization.
8. Inspect existing tests.

Reuse existing architecture where possible.

Do not create duplicate models, caches, or image systems.

---

## 4. Inspect tv-logo/tv-logos

Do not guess filenames.

Inspect the repository and identify the exact current files for the required beIN SPORTS channels.

For every selected logo record:

```text
logical channel key
exact source path
source URL/repository
license
required attribution
local asset path
```

Only then import the asset.

Do not blindly scrape or copy the entire repository.

---

## 5. Local Asset Structure

Use a dedicated directory:

```text
assets/
└── logos/
    └── bein/
        ├── ...
```

Use application-owned deterministic names, for example:

```text
bein_sports_1.webp
bein_sports_2.webp
bein_sports_news.webp
```

Do not make runtime code depend on upstream filenames.

---

## 6. Asset Optimization

Where legally permitted:

```text
Verified source image
        ↓
Optimize
        ↓
WebP
        ↓
Flutter asset
```

Requirements:

- Preserve transparency.
- Preserve aspect ratio.
- Do not distort logos.
- Do not crop meaningful logo content.
- Avoid unnecessary compression.
- Do not upscale poor source artwork.

Use appropriate resolution for Android TV and desktop.

---

## 7. Mapping Strategy

Use this priority:

```text
1. Verified tvg-id mapping
2. Verified Xtream stream_id mapping
3. Verified normalized channel-name mapping
4. Cached provider logo
5. Provider logo URL
6. Generic fallback
```

Do not assume provider IDs are stable until verified from actual API responses.

---

## 8. Normalization

Create one reusable normalization function.

Example inputs:

```text
beIN Sports 1
BEIN SPORTS 1 HD
beIN Sports 1 FHD
BEIN SPORT 1
bein sports 1
beIN Sports 1 4K
```

should resolve to:

```text
bein_sports_1
```

Normalization should:

1. Lowercase.
2. Normalize whitespace.
3. Normalize punctuation.
4. Normalize `bein` variants.
5. Normalize `sport` / `sports` carefully.
6. Remove presentation-only suffixes such as `HD`, `FHD`, `UHD`, `4K` only when safe.
7. Preserve meaningful channel numbers.
8. Preserve meaningful service identifiers.

Do not blindly remove arbitrary words.

---

## 9. Arabic Aliases

The IPTV provider may return Arabic names.

Support verified aliases such as:

```text
بي إن سبورت 1
بي ان سبورت 1
بين سبورت 1
```

Do not assume every Arabic variation is equivalent.

Keep aliases in one catalog rather than spreading them across widgets.

---

## 10. Recommended Catalog

Create a dedicated JSON/Dart catalog.

Example:

```json
{
  "channels": [
    {
      "key": "bein_sports_1",
      "tvgIds": [],
      "streamIds": [],
      "aliases": [
        "bein sports 1",
        "bein sport 1"
      ],
      "asset": "assets/logos/bein/bein_sports_1.webp"
    }
  ]
}
```

Only populate `tvgIds` and `streamIds` after verifying them from the actual IPTV data.

Do not invent IDs.

---

## 11. LogoResolver

Create a single resolver abstraction:

```dart
class LogoResolver {
  Future<LogoResult> resolve(Channel channel);
}
```

Adapt it to the existing architecture if a resolver already exists.

Suggested result:

```dart
enum LogoSource {
  localCatalog,
  cachedProvider,
  provider,
  fallback,
}

class LogoResult {
  final String? assetPath;
  final String? remoteUrl;
  final LogoSource source;
}
```

Reuse existing project conventions if available.

---

## 12. Resolution Algorithm

Implement:

```text
Channel
   ↓
Is there an exact verified local mapping?
   │
   ├── YES → local asset
   │
   └── NO
        ↓
Existing cached provider logo?
        │
        ├── YES → cached image
        │
        └── NO
             ↓
Provider logo URL available?
             │
             ├── YES → attempt provider image
             │
             └── NO / failed
                    ↓
                 fallback
```

Local verified beIN artwork must take priority over the provider URL.

---

## 13. False-Positive Protection

Do not accidentally match:

```text
beIN Sports 1
```

with:

```text
beIN Sports 10
```

or:

```text
beIN Sports 1 Max
```

with:

```text
beIN Sports 1
```

Use token-aware matching.

Channel numbers must be compared as actual tokens.

Exact mapping must beat fuzzy matching.

---

## 14. SmartChannelLogo

Create/reuse one shared widget:

```dart
SmartChannelLogo(
  channel: channel,
)
```

Do not use raw:

```dart
Image.network(channel.logoUrl)
```

throughout the application.

The widget should support:

```text
channel
size
fit
borderRadius
fallback
semanticLabel
```

It must never throw a visible broken-image state.

---

## 15. Runtime Behavior

For a known beIN channel:

```text
Channel received
      ↓
Local catalog match
      ↓
Local logo
      ↓
Immediate display
```

No external request is required.

For unknown channels:

```text
Provider logo
      ↓
Fallback
```

A logo request must never block:

- Player startup.
- Channel switching.
- EPG rendering.
- Channel list interaction.

---

## 16. Flutter Assets

Register only the required beIN assets in `pubspec.yaml`.

Prefer a narrow asset declaration such as:

```yaml
flutter:
  assets:
    - assets/logos/bein/
```

Follow existing project conventions.

Then run:

```bash
flutter pub get
flutter analyze
```

---

## 17. No GitHub Runtime Dependency

Do NOT implement:

```text
Flutter → GitHub Raw URL → Logo
```

as the production solution.

Reasons:

- Runtime dependency.
- Latency.
- Availability.
- Rate limits.
- Repository changes.
- Licensing complexity.
- Network restrictions.

Use the repository during development/asset preparation only.

---

## 18. Optional Import Script

If useful, create:

```text
tooling/
└── import_bein_logos.py
```

The script may:

1. Read a manually verified manifest.
2. Download only explicitly listed source files.
3. Validate response.
4. Validate image.
5. Convert to WebP.
6. Preserve transparency.
7. Generate the local catalog.
8. Generate attribution metadata.

It must NOT blindly scrape every repository logo.

---

## 19. Manifest

Use a manifest like:

```json
{
  "source": "tv-logo/tv-logos",
  "license_verified": true,
  "logos": [
    {
      "key": "bein_sports_1",
      "source_path": "EXACT_VERIFIED_PATH",
      "asset_path": "assets/logos/bein/bein_sports_1.webp"
    }
  ]
}
```

Replace `EXACT_VERIFIED_PATH` only after inspecting the repository.

Never guess paths.

---

## 20. Third-Party Notices

If the verified license requires attribution, create:

```text
THIRD_PARTY_NOTICES.md
```

Include:

```text
Source
Repository
License
Required attribution
Modifications
Included assets
```

Do not remove upstream license information.

---

## 21. Platform Requirements

### Android

- Local logo loads without network.
- Provider logo failure does not affect channel rendering.
- Player does not wait for logo.

### Android TV

- Logos are crisp at TV sizes.
- Focus navigation remains smooth.
- Logo loading does not affect D-pad responsiveness.

### Windows

- Local assets work without internet.
- Large channel grids remain smooth.

### Web

- Local assets avoid CORS/runtime image-host dependency.
- Logo loading does not block page rendering.

---

## 22. Caching

If the project already has image caching, reuse it.

If not, do not build an elaborate cache solely for this feature.

Local assets do not need a remote cache.

Provider logos may use the existing cache as fallback.

---

## 23. Fallback

If no local or provider logo is available:

```text
Generic channel icon
```

or generated initials:

```text
┌──────────────┐
│              │
│     BEIN     │
│              │
└──────────────┘
```

Never display a broken-image icon.

---

## 24. Testing

Create unit tests for:

### Exact

```text
beIN Sports 1
→ bein_sports_1
```

### Case

```text
BEIN SPORTS 1
→ bein_sports_1
```

### HD

```text
beIN Sports 1 HD
→ bein_sports_1
```

### Arabic

```text
بي إن سبورت 1
→ bein_sports_1
```

### Number safety

```text
beIN Sports 1
≠ bein_sports_10
```

### Unknown

```text
Random Channel
→ provider/fallback
```

---

## 25. Widget Tests

Verify:

```text
Local logo available
→ local asset displayed
```

```text
Local logo unavailable + provider available
→ provider logo displayed
```

```text
Both unavailable
→ fallback displayed
```

```text
Provider logo unavailable
→ UI remains stable
```

---

## 26. Performance Tests

Verify:

- Local logos require no network.
- Channel lists do not wait for remote logos.
- EPG does not block on images.
- Player startup is independent of logo loading.
- Channel switching is independent of logo loading.
- Scrolling remains smooth.

---

## 27. Logging

Never log:

- IPTV passwords.
- Authentication URLs.
- Full authenticated stream URLs.
- Sensitive API payloads.

Safe development logging:

```text
Logo resolved
source=localCatalog
key=bein_sports_1
```

Keep production logs minimal.

---

## 28. Integration Rules

Do not create a second Channel model.

Use the existing domain model.

Possible fields:

```text
id
streamId
name
tvgId
logoUrl
categoryId
```

Use only fields actually available.

Keep beIN-specific logic inside:

```text
LogoCatalog
LogoResolver
SmartChannelLogo
```

Do not spread beIN checks across screens.

---

## 29. Do Not Modify IPTV Server

The entire feature must work without:

- IPTV panel changes.
- API changes.
- Database changes.
- Provider changes.

The existing API remains the source of channel metadata.

---

## 30. Implementation Order

Follow this sequence:

```text
1. Inspect Flutter repository
2. Inspect Channel model
3. Inspect existing image system
4. Inspect existing cache
5. Inspect tv-logo/tv-logos
6. Verify license
7. Identify exact beIN assets
8. Create local assets
9. Optimize assets
10. Create catalog
11. Implement normalization
12. Implement LogoResolver
13. Implement SmartChannelLogo
14. Integrate into channel cards
15. Integrate into EPG
16. Integrate into player overlay
17. Add tests
18. Test Android
19. Test Android TV
20. Test Windows
21. Test Web
22. Run flutter analyze
23. Run tests
```

---

## 31. Definition of Done

- [ ] Only required beIN SPORTS logos are included.
- [ ] Exact source files were verified.
- [ ] License/redistribution was reviewed.
- [ ] Required attribution is included.
- [ ] No GitHub runtime dependency exists.
- [ ] Local logos load immediately.
- [ ] Provider logo is fallback.
- [ ] Generic fallback exists.
- [ ] Name normalization works.
- [ ] Arabic aliases work where verified.
- [ ] Number matching is safe.
- [ ] No false-positive mapping.
- [ ] Android tested.
- [ ] Android TV tested.
- [ ] Windows tested.
- [ ] Web tested.
- [ ] Unit tests pass.
- [ ] Widget tests pass.
- [ ] `flutter analyze` passes.
- [ ] No credentials are logged.
- [ ] Player performance is unaffected.

---

## Final Instruction to the Agent

Implement this as a **small isolated artwork subsystem**.

The rest of the application should simply ask:

```dart
LogoResolver.resolve(channel)
```

and receive the best available logo.

The desired result is:

```text
IPTV Channel
      ↓
Verified beIN identification
      ↓
Local logo
      ↓
Immediate rendering
      ↓
No dependency on provider-hosted logo
      ↓
Fast + stable + cross-platform
```

The player must remain completely independent from the logo subsystem.

A logo failure must never stop, delay, or destabilize video playback.
