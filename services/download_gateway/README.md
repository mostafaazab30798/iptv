# HOPE TV download gateway

Legacy Cloudflare Worker scaffold for an abandoned private-R2 release design.

This service is intentionally separate from the repository root IPTV proxy (`worker.js` / root `wrangler.toml`). Do not add Supabase service-role keys, billing secrets, or IPTV credentials here.

## Status

**Deprecated / not deployed.** Production artifacts are published by GitHub Actions to GitHub Releases. Supabase `downloads` returns the GitHub release URL directly. See [`docs/commercial/adr/0008-github-releases.md`](../../docs/commercial/adr/0008-github-releases.md).

## Local development

```bash
cd services/download_gateway
cp .dev.vars.example .dev.vars
npm install
npm test
npx wrangler dev
```

## Routes

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness; reports `iptvProxyCoupled: false` |
| GET | `/v1/downloads/{token}` | Stream authorized private object |

## Secrets

Set only in Cloudflare / `.dev.vars` (gitignored):

- `DOWNLOAD_TOKEN_HMAC_SECRET` — HMAC for opaque download tokens
- R2 binding `RELEASES` — placeholder only; not used by production
