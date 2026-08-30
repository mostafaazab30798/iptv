# ADR 0002: Cloudflare for portal and release delivery

## Status

Accepted

## Context

HOPE TV will eventually host a customer portal and deliver signed APK/installer binaries. The existing root Worker (`worker.js`) proxies IPTV/static assets and must not hold commercial secrets.

## Decision

- Host the future customer portal on **Cloudflare Pages**.
- Store release binaries in **private Cloudflare R2**.
- Serve authorized downloads through an **isolated download gateway Worker** under `services/download_gateway/`.
- Keep the root IPTV Worker unchanged for commercial concerns.

Until Phase 6 automation ships, distribution remains **manual**. The download gateway is scaffolded now so the boundary is clear.

## Consequences

- Commercial secrets stay in Supabase Vault / download-gateway secrets, never in `worker.js`.
- Download authorization decisions are owned by Supabase; the gateway only verifies and streams.
