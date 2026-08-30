# Release signing and distribution (Phase 6)

HOPE TV distributes Android APK and Windows installer binaries through **GitHub Releases**. GitHub Actions publishes each artifact and registers its URL, size, and SHA-256 digest in Supabase.

## Architecture

```text
GitHub Actions builds binary -> GitHub Releases
GitHub Actions registers URL + metadata -> Supabase release_versions
App checks version -> Supabase version Edge Function (signed manifest)
User requests download -> Supabase downloads Edge Function
App downloads public GitHub asset (or temporary GitHub CDN URL for a private repo)
```

## Signing

| Asset | Dev (local) | Production |
|---|---|---|
| Update manifests | `RELEASE_SIGNING_HMAC_SECRET` | Ed25519 (`RELEASE_SIGNING_ALG=ed25519`) |
| Entitlement leases | `ENTITLEMENT_SIGNING_HMAC_SECRET` | Separate Ed25519 keys |

Never reuse entitlement keys for release manifests.

Flutter verifies manifests with:

- `RELEASE_PUBLIC_KEYS_JSON` (production)
- `RELEASE_HMAC_VERIFY_SECRET` (local dev only)

## Production Ed25519 setup (one-time)

```powershell
# From repository root — generates keys under secrets/release-signing/ (gitignored)
powershell -ExecutionPolicy Bypass -File scripts/release/create_release_signing_keys.ps1 -UploadSecrets

# Deploy signing-aware Edge Functions
supabase functions deploy version downloads --project-ref otmovtxevvuxbsrmurkb

# Verify secrets, signed manifest, and unit tests
powershell -ExecutionPolicy Bypass -File scripts/release/verify_production_readiness.ps1
```

Supabase Edge Function secrets (production):

| Secret | Value |
|---|---|
| `RELEASE_SIGNING_ALG` | `ed25519` |
| `RELEASE_SIGNING_KEY_ID` | e.g. `release-prod-2026-08-30-01` |
| `RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64` | PKCS#8 private key (server only) |

GitHub Actions secret:

| Secret | Value |
|---|---|
| `RELEASE_PUBLIC_KEYS_JSON` | `{"release-prod-YYYY-MM-DD-01":"<64-char-hex-public-key>"}` |

**Key rotation:** ship a client trusting old+new public keys, switch server signing to the new private key, wait for adoption, then remove the old public key in a later release.

Never put `RELEASE_HMAC_VERIFY_SECRET` in production client builds.

## Android production checklist

- Confirm permanent application ID before first customer build (see ADR 0007).
- Generate a protected release keystore with `scripts/android/create_release_keystore.ps1`.
- Upload signing secrets (`ANDROID_KEYSTORE_*`) before running the release workflow.
- Build release APK/AAB only; publish SHA-256 in `release_versions.sha256`.
- Keep the same signing identity for all updates.

### Generate / upload Android keystore

```powershell
# From repository root
powershell -ExecutionPolicy Bypass -File scripts/android/create_release_keystore.ps1 -UploadSecrets
```

Creates (gitignored):

- `android/keystore/hope-tv-release.jks`
- `android/key.properties`
- `android/keystore/hope-tv-release.passwords.txt` (offline backup)

Gradle reads `android/key.properties` when present; otherwise release builds fall back to the debug key for local convenience only. CI refuses to build without the keystore secrets.

### Flutter dart-defines for production builds

| Define | Source |
|---|---|
| `SUPABASE_URL` | GitHub secret |
| `SUPABASE_ANON_KEY` | GitHub secret |
| `PORTAL_ORIGIN` | GitHub secret (default `https://admin.hope-tv.site`) |
| `ENTITLEMENT_PUBLIC_KEYS_JSON` | GitHub secret (prod key from OWNER_CONFIG) |
| `RELEASE_PUBLIC_KEYS_JSON` | GitHub secret — required for in-app update verification once Edge Functions use Ed25519 |

Never put `ENTITLEMENT_HMAC_VERIFY_SECRET` or `RELEASE_HMAC_VERIFY_SECRET` in production client builds.

## Windows production checklist

- Ship a signed installer (Authenticode), not a loose `.exe`.
- Timestamp signatures; verify after packaging.
- Publish SHA-256 digest in PostgreSQL metadata.
- Test SmartScreen on a clean machine.

## Owner operations

1. Trigger the GitHub release workflow from `main` with the intended channel.
2. Verify the Android and Windows assets, checksums, and generated tag.
3. Verify the workflow inserted the matching `release_versions` rows in Supabase.
4. Revoke compromised releases from the dashboard (`revoked_at`) and remove or replace the GitHub asset.

Signing never happens in the browser — only on the server during publish.

## Local development

See [LOCAL_DEV.md](./LOCAL_DEV.md). The legacy `services/download_gateway` R2 scaffold is not deployed.
