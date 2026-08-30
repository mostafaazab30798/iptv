# Release signing and distribution (Phase 6)

HOPE TV distributes Android APK and Windows installer binaries through **private Cloudflare R2**, authorized by Supabase, and streamed by the isolated `services/download_gateway/` Worker.

## Architecture

```text
Owner uploads binary -> private R2 (manual or CI)
Owner publishes metadata -> admin dashboard -> admin-api (signs manifest)
App checks version -> Supabase version Edge Function (signed manifest)
User requests download -> downloads Edge Function (single-use token)
Browser/app opens download gateway URL -> gateway consumes token -> streams R2 object
```

## Signing

| Asset | Dev (local) | Production |
|---|---|---|
| Update manifests | `RELEASE_SIGNING_HMAC_SECRET` | Ed25519 (`RELEASE_SIGNING_ALG=ed25519`) |
| Download tokens | `DOWNLOAD_TOKEN_HMAC_SECRET` | Same secret in Supabase + gateway |
| Entitlement leases | `ENTITLEMENT_SIGNING_HMAC_SECRET` | Separate Ed25519 keys |

Never reuse entitlement keys for release manifests.

Flutter verifies manifests with:

- `RELEASE_PUBLIC_KEYS_JSON` (production)
- `RELEASE_HMAC_VERIFY_SECRET` (local dev only)

## Android production checklist

- Confirm permanent application ID before first customer build (see ADR 0007).
- Use a protected release keystore outside Git.
- Build release APK/AAB only; publish SHA-256 in `release_versions.sha256`.
- Keep the same signing identity for all updates.

## Windows production checklist

- Ship a signed installer (Authenticode), not a loose `.exe`.
- Timestamp signatures; verify after packaging.
- Publish SHA-256 digest in PostgreSQL metadata.
- Test SmartScreen on a clean machine.

## Owner operations

1. Upload artifact to private R2 at `object_key` recorded in `release_versions`.
2. Insert or verify metadata row (platform, version, build_number, sha256).
3. Publish from admin dashboard (signs manifest, sets `published_at`).
4. Revoke compromised releases from dashboard (`revoked_at`).

Signing never happens in the browser — only on the server during publish.

## Local development

See [LOCAL_DEV.md](./LOCAL_DEV.md). Use placeholder bucket names until owner confirms R2 bucket IDs in `OWNER_CONFIG.md`.
