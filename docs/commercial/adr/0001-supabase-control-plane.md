# ADR 0001: Supabase as commercial control plane

## Status

Accepted

## Context

HOPE TV needs a first-party account, trial, entitlement, device, analytics, and (later) billing control plane separate from the existing IPTV provider login and root Cloudflare IPTV proxy.

## Decision

Use **Supabase Auth**, **PostgreSQL with Row Level Security**, and **Edge Functions** as the authoritative commercial control plane.

- Application account data lives in `public.profiles` keyed by `auth.users.id`.
- Commercial mutations go through Edge Functions, not direct client writes to authority tables.
- Local Drift remains an app cache only; it is never authoritative for commercial access.

## Consequences

- Flutter and a future portal share one Supabase Auth identity.
- The anonymous/publishable key may ship in clients only when RLS is correct.
- The service-role key never appears in Flutter, portal bundles, or the IPTV Worker.
