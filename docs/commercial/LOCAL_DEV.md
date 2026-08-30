# HOPE TV commercial control plane — local development

Covers Phase 0–5 foundations. Billing remains deferred (Phase 4). Direct downloads/updates are Phase 6.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli)
- Docker (for local Postgres / Auth / Studio)
- Deno (for Edge Function shared unit tests)
- Node.js 22+ (for download gateway and admin dashboard)

## Supabase

```bash
# From repository root
cp supabase/.env.example supabase/.env   # placeholders only; fill locally
supabase start
supabase db reset                        # applies migrations + seed.sql
supabase functions serve health
supabase functions serve version
supabase functions serve trial-activate
supabase functions serve entitlement
supabase functions serve me
supabase functions serve devices
supabase functions serve analytics-batch
supabase functions serve session-heartbeat
supabase functions serve admin-api
```

Shared unit tests (no Docker required):

```bash
deno test --allow-env supabase/functions/_shared/
```

Metric fixture structural checks (after `db reset`):

```bash
psql "$DATABASE_URL" -f supabase/tests/analytics_metric_fixtures.sql
```

## App account (Phase 2) + entitlement (Phase 3) + analytics (Phase 5)

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon-from-supabase-status> \
  --dart-define=ENTITLEMENT_HMAC_VERIFY_SECRET=<same-as-edge-hmac-secret>
```

Until Supabase dart-defines replace placeholders, the app keeps the IPTV-only navigation gate.

App account and entitlement caches use secure storage keys separate from IPTV credentials.

Analytics batches and heartbeats never block playback. Forbidden IPTV/credential properties are stripped client-side and rejected server-side.

### Entitlement leases

Local HMAC signing (Edge Functions `.env`):

```bash
ENTITLEMENT_SIGNING_ALG=hmac
ENTITLEMENT_SIGNING_HMAC_SECRET=dev-only-secret
ENTITLEMENT_SIGNING_KEY_ID=entitlement-dev-1
```

Production must use Ed25519 (`ENTITLEMENT_SIGNING_ALG=ed25519`) and embed public keys via `ENTITLEMENT_PUBLIC_KEYS_JSON`.

## Owner admin dashboard (`hope-tv-insights`)

**Default:** remote Supabase only — open [https://hope-tv.mostafaazab3024.workers.dev](https://hope-tv.mostafaazab3024.workers.dev) from any browser, or run the UI locally while still using the cloud backend:

```bash
cd hope-tv-insights
cp .env.example .env
npm install
npm run dev
```

Ensure Supabase Edge Function secrets include `PORTAL_ORIGIN` and `CORS_ALLOWLIST` with your dashboard URL (see `hope-tv-insights/INTEGRATION.md`).

### Optional local Supabase stack

The older minimal scaffold remains for reference. New work should use `hope-tv-insights/`.

```bash
cd admin-dashboard
cp .env.example .env.local
npm install
npm run dev
```

Grant yourself admin access only via service role / SQL (never from the browser):

```sql
insert into private.admin_users (user_id, role, status)
values ('<your-auth-user-uuid>', 'owner', 'active');
```

See [admin-dashboard/README.md](../../admin-dashboard/README.md) and [adr/0006-owner-admin-dashboard.md](./adr/0006-owner-admin-dashboard.md).

## Download gateway (isolated)

```bash
cd services/download_gateway
cp .dev.vars.example .dev.vars
npm install
npm test
npx wrangler dev
```

Gateway secrets (Worker / `.dev.vars`, never in Git):

- `DOWNLOAD_TOKEN_HMAC_SECRET` — must match Supabase Edge Functions
- `GATEWAY_SERVICE_SECRET` — must match Supabase `download-consume`
- `DOWNLOAD_CONSUME_URL` — Supabase `download-consume` function URL

Supabase Edge Function secrets for Phase 6:

- `DOWNLOAD_GATEWAY_BASE_URL` — public gateway origin
- `RELEASE_SIGNING_HMAC_SECRET` / Ed25519 keys — manifest signing on publish

Serve functions:

```bash
supabase functions serve downloads
supabase functions serve download-consume
```

Flutter update check (optional dev verify secret):

```bash
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=<anon> \
  --dart-define=RELEASE_HMAC_VERIFY_SECRET=<same-as-server-release-secret>
```

See [RELEASE_SIGNING.md](./RELEASE_SIGNING.md).

Do **not** point this Worker at the root IPTV Worker configuration.

## What stays unchanged / deferred

- Root `worker.js` and root `wrangler.toml` (IPTV / static)
- Android application ID remains `com.example.iptv` until `com.hopetv.iptvplayer` is explicitly confirmed
- Production payment provider (`NotConfiguredBillingProvider`) — Phase 4
- Production Android keystore / Windows Authenticode certificates — owner-operated per RELEASE_SIGNING.md

See [OWNER_CONFIG.md](./OWNER_CONFIG.md).
