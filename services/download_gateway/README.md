# HOPE TV download gateway

Isolated Cloudflare Worker that streams **private R2** release objects after verifying a short-lived download token.

This service is intentionally separate from the repository root IPTV proxy (`worker.js` / root `wrangler.toml`). Do not add Supabase service-role keys, billing secrets, or IPTV credentials here.

## Status

Phase 6: authorized R2 streaming, single-use download tokens, signed update manifests, and Flutter update UX.

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
- R2 binding `RELEASES` — private bucket name from `OWNER_CONFIG` placeholders
