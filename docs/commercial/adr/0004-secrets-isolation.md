# ADR 0004: Control-plane secrets isolation from IPTV proxy

## Status

Accepted

## Context

The repository already deploys a public IPTV/static Cloudflare Worker. Adding Supabase service-role keys, billing secrets, or release-signing material there would expand blast radius and couple unrelated systems.

## Decision

- Do not add commercial API routes or secrets to root `worker.js` / root `wrangler.toml`.
- Supabase Edge Functions and `services/download_gateway` own commercial secrets for their respective responsibilities.
- IPTV credentials remain local to the Flutter secure-storage path and never enter the commercial control plane.

## Consequences

- Two Workers (or Worker + Edge Functions) must be operated separately.
- Operational docs must never instruct developers to paste service-role keys into the IPTV Worker.
