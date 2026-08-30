# Master Implementation Plan for an LLM Agent

## Direct Distribution, Download Analytics, Active Users, Free Trial, and External Subscriptions

**Product:** HOPE TV  
**Project:** Flutter IPTV player plus commercial web control plane  
**Repository:** `D:\PROJECTS\iptv`  
**Target platforms:** Android APK and Windows installer/EXE  
**Distribution:** Direct distribution from an owner-controlled website; no Google Play or Apple App Store  
**Payment rule:** No payment form, card collection, or completed purchase inside the Flutter application  
**Trial:** One server-controlled seven-day free trial per verified app account  
**Document purpose:** This is the authoritative implementation plan for an LLM coding agent. Execute it in phases and do not silently broaden scope.

---

## 0. Approved Direction and Current Decision Status

The owner has selected the following implementation path:

- Product working/public name: **HOPE TV**.
- Distribution: direct Android APK and Windows installer; no Google Play or Apple App Store.
- Customer payments: hosted external website checkout only.
- Commercial identity: Supabase Auth.
- Authoritative database: Supabase PostgreSQL.
- Business APIs: Supabase Edge Functions.
- Authorization: PostgreSQL Row Level Security plus protected server-side functions.
- Customer portal hosting: Cloudflare Pages.
- Release storage: private Cloudflare R2.
- Protected downloads: separate Cloudflare download Worker.
- Owner dashboard: separate React + TypeScript + Vite application using CSS/CSS Modules, deployed to Cloudflare Pages.
- Owner dashboard backend: protected `admin-api` Supabase Edge Function; no service-role credentials in the browser.
- Initial analytics: PostgreSQL event ingestion, daily aggregates, active-session heartbeats, and dashboard reporting.
- Existing IPTV proxy: preserved as a separate Cloudflare Worker with no commercial secrets.

Free provider URLs may be used for development and staging:

```text
Customer portal: <available-name>.pages.dev
Owner dashboard: hope-tv-admin.pages.dev or another available Pages name
Download gateway: <worker-name>.<account>.workers.dev
Supabase API: https://<project-ref>.supabase.co
```

These are development/staging endpoints, not permanent production identity. Before accepting paying customers, use a production Supabase plan with backups and obtain an owner-controlled custom domain. The product name must also complete legal/trademark validation before commercial launch because implementation approval does not establish name availability.

Proposed Android identity is `com.hopetv.iptvplayer`, but it remains **unconfirmed** until the owner explicitly approves it. Do not change Android namespace/application ID in code based only on this proposal.

---

## 1. Objective

Build a secure commercial control plane around the existing IPTV player so the owner can:

1. Count APK and Windows installer download requests.
2. Distinguish downloads, installations, accounts, active users, online users, trial users, and paying users.
3. Provide a seven-day free trial that cannot be reset merely by reinstalling the app or changing the device clock.
4. Sell monthly and yearly subscriptions through an external owner-controlled website.
5. Activate and revoke app access from verified payment-provider webhooks.
6. Change plans, prices, trial policy for future trials, device limits, feature flags, and supported app versions without releasing a new app.
7. Distribute signed APK and Windows releases securely.
8. Deliver secure application updates.
9. Keep all IPTV provider credentials and stream data private and separate from billing and analytics.

The implementation is complete only when all acceptance criteria in this document pass.

---

## 2. Non-Negotiable Product Rules

The LLM agent must preserve these rules throughout implementation:

- The Flutter app may show subscription status and a **Subscribe on our website** button.
- The button must open the operating system's default external browser.
- Do not embed checkout in a WebView.
- Do not collect card data in Flutter or in the project backend.
- Use a hosted checkout supplied by the selected payment provider.
- Do not grant access from a browser success redirect.
- Grant, change, or revoke paid access only after processing an authenticated payment-provider webhook.
- Trial start and end timestamps are server-authoritative UTC timestamps.
- Do not store a client-controlled `isPremium` flag as the source of truth.
- Do not send IPTV server URLs, usernames, passwords, authenticated stream URLs, channel names, playlists, or viewing history to the subscription backend.
- Preserve the existing local secure-storage behavior for IPTV credentials.
- The app subscription is a license for the player software. It must not represent the sale of television channels or unlicensed content.
- Do not ship debug APKs or unsigned Windows executables to customers.
- Do not place API keys, signing keys, webhook secrets, or email credentials in Git.

---

## 3. Current Repository Assessment

Before changing code, the agent must verify these observations against the current repository:

- `pubspec.yaml` identifies a Flutter IPTV application and currently has no first-party account, commercial entitlement, payment, or product analytics dependency.
- `lib/app/router.dart` currently gates navigation using the IPTV `sessionProvider` only.
- `lib/app/providers.dart` currently treats a saved `ServerConfig` as the application session.
- `lib/features/onboarding/onboarding_screen.dart` authenticates a customer with their IPTV provider.
- `lib/core/storage/secure_storage.dart` stores IPTV server credentials locally.
- `worker.js` and `web/_worker.js` implement the Flutter web/static deployment and IPTV reverse proxy.
- `wrangler.toml` currently deploys that worker and contains no Supabase integration or protected R2 release-delivery bindings.
- `android/app/build.gradle.kts` still uses the placeholder Android application ID `com.example.iptv` unless it has been changed after this document was written.
- The application supports English and Arabic through `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`.

### Required architectural correction

The existing IPTV provider login is not the new first-party application account. Introduce two explicitly separate concepts:

1. **App account session:** identity, trial, devices, subscription, and entitlement.
2. **IPTV provider session:** the existing `ServerConfig` and provider credentials used to load streams.

Never rename the IPTV provider session to make it appear to be the commercial account. Model both sessions independently.

---

## 4. Scope

### 4.1 In scope

- First-party account authentication.
- Supabase Auth with passwordless email OTP or magic-link verification.
- TV-friendly device-code pairing if Android TV remains supported.
- Server-authoritative trial lifecycle.
- Monthly and yearly externally purchased subscriptions.
- Payment webhook ingestion.
- Entitlement evaluation and offline entitlement lease.
- Device registration, limits, listing, and revocation.
- Product analytics and active-session heartbeats.
- Direct-download tracking.
- Private owner dashboard implemented as React + TypeScript + Vite with CSS/CSS Modules, backed by a protected Supabase `admin-api` Edge Function.
- Dynamic remote configuration.
- Signed Android and Windows releases.
- Secure update manifests and verified downloads.
- English and Arabic UI.
- Account deletion and data-retention workflows.
- Automated tests and operational documentation.

### 4.2 Explicitly out of scope for the first release

- Google Play Billing.
- Apple In-App Purchase.
- App Store or Google Play submission.
- Cryptocurrency payments.
- Reseller or affiliate commissions.
- Family plans.
- Concurrent stream enforcement at the IPTV provider level.
- Collecting or synchronizing viewing history.
- Advertising analytics.
- Machine fingerprinting intended to identify people across reinstallations.
- Building a custom card-entry or invoice system.
- Obfuscation being treated as a substitute for server-side authorization.

---

## 5. Decision Register and Remaining Production Inputs

The agent may scaffold interfaces and use sandbox credentials, but must respect the status below and must not invent unresolved production values:

| Decision | Current direction/value | Status |
|---|---|---|
| Product/business name | HOPE TV | Owner confirmed; trademark/legal validation still required before commercial launch |
| Customer portal frontend | Small web app on Cloudflare Pages | Confirmed |
| Owner dashboard frontend | React + TypeScript + Vite + CSS/CSS Modules | Confirmed |
| Owner dashboard plan | `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md` | Confirmed and authoritative for dashboard work |
| Commercial backend | Supabase Auth + PostgreSQL + Edge Functions | Confirmed |
| Release storage/delivery | Private Cloudflare R2 + isolated download Worker | Confirmed |
| Temporary customer website | Available `*.pages.dev` project name | Free development/staging path; exact name unresolved |
| Temporary owner dashboard | Suggested `hope-tv-admin.pages.dev`, subject to availability | Free development/staging path |
| Temporary download endpoint | Generated `*.workers.dev` endpoint | Free development/staging path |
| Temporary API endpoint | Generated `https://<project-ref>.supabase.co` | Free development/staging path |
| Production website domain | Owner-controlled HTTPS custom domain | Required before paid production; unresolved |
| Production API/custom domain | Custom API domain optional; Supabase endpoint remains valid | Unresolved |
| Android application ID | Proposed `com.hopetv.iptvplayer` | Owner confirmation required before code change |
| Windows publisher identity | Must match code-signing certificate | Unresolved |
| Merchant country/entity | Legal entity receiving payments | Unresolved |
| Payment provider | Must support hosted recurring payments for the merchant | Unresolved |
| Monthly price | Amount and supported currencies | Unresolved |
| Yearly price | Amount and supported currencies | Unresolved |
| Tax handling | Provider-managed, merchant-managed, or merchant of record | Unresolved |
| Refund policy | Written and approved | Unresolved |
| Device limit | Recommended initial value: 3 | Owner confirmation required |
| Failed-payment grace period | Recommended: 72 hours | Owner confirmation required |
| Offline entitlement lease | Recommended: 24 hours | Owner confirmation required |
| Email delivery provider | For Supabase login codes and account notices | Unresolved |
| Support contact | Email and website URL | Unresolved |
| Supabase region | Region selected for customer latency and data-residency needs | Unresolved |
| Supabase environments | Separate development, staging, and production projects | Confirmed architecture; actual project refs unresolved |
| Production Supabase plan | Paid plan with backups before accepting paying users | Required production gate |

Record confirmed values in a versioned, non-secret decision/configuration document. Put secrets only in Supabase or Cloudflare environment-specific secret storage.

---

## 6. Target Architecture

```text
Customer
  |
  +-- Website / Account Portal
  |     +-- Register and sign in
  |     +-- View monthly/yearly plans
  |     +-- Open hosted checkout
  |     +-- Manage subscription
  |     +-- Manage devices
  |     +-- Download signed releases
  |
  +-- Flutter App (Android / Windows)
        +-- App account session
        +-- Entitlement check and offline lease
        +-- Trial/subscription UI
        +-- Active-session heartbeat
        +-- External-browser subscription link
        +-- Existing local IPTV provider session
                  |
                  v
        Supabase Control Plane
          +-- Supabase Auth
          +-- PostgreSQL + Row Level Security
          +-- Edge Functions
          |     +-- Trial and entitlement service
          |     +-- Device service
          |     +-- Analytics ingestion
          |     +-- Payment webhooks
          |     +-- Remote configuration
          |
          +-------------+---------------------+
                        |                     |
                        v                     v
              Hosted Billing Provider   Cloudflare Download Worker
              checkout/customer portal       |
                                               v
                                       Private Cloudflare R2
                                       APK/installer releases
```

### 6.1 Service separation

Do not add commercial API routes and secrets to the public IPTV proxy in `worker.js`.

Use Supabase as the authoritative commercial control plane. Create database migrations and Edge Functions using the standard Supabase project layout:

```text
supabase/
  config.toml
  migrations/
  seed.sql
  functions/
    _shared/
      auth.ts
      cors.ts
      errors.ts
      logging.ts
      billing_provider.ts
      entitlement.ts
      validation.ts
    entitlement/
    trial-activate/
    devices/
    device-pairing/
    analytics-batch/
    session-heartbeat/
    billing-checkout/
    billing-portal/
    billing-webhook/
    remote-config/
    account-delete/
    admin-api/
  tests/

services/
  download_gateway/
    src/
    test/
    package.json
    tsconfig.json
    wrangler.toml
    README.md

admin-dashboard/
  src/
  e2e/
  public/
  package.json
  tsconfig.json
  vite.config.ts
  README.md
```

The Cloudflare download gateway has one narrow responsibility: verify an authenticated Supabase identity or a short-lived download authorization, log the download request, and stream an approved private R2 object. It is not the subscription database or authentication authority.

The current root `worker.js` remains the IPTV stream/static worker unless a later, explicit migration is approved. Do not place Supabase service-role keys, billing secrets, or release-signing secrets in that public proxy.

### 6.2 Customer portal

Create a separate portal rather than embedding commerce in Flutter:

```text
portal/
  src/
  public/
  test/
  package.json
  README.md
```

Deploy the portal through Cloudflare Pages. The exact web framework may be selected during Phase 0. Prefer a small, maintained framework compatible with Cloudflare Pages. Use the same Supabase Auth account as Flutter. Do not duplicate billing business rules in the browser; commercial mutations must call authenticated Supabase Edge Functions.

### 6.3 Authoritative technology decision

Unless the owner explicitly approves a later architecture decision record, use this stack:

| Capability | Authoritative technology |
|---|---|
| App and portal identity | Supabase Auth |
| Relational business database | Supabase PostgreSQL |
| Customer data authorization | PostgreSQL Row Level Security |
| Trial, entitlement, billing, analytics, and deletion APIs | Supabase Edge Functions |
| Customer portal hosting | Cloudflare Pages |
| Owner dashboard frontend | React + TypeScript + Vite + CSS/CSS Modules on Cloudflare Pages |
| Owner dashboard API | Protected Supabase `admin-api` Edge Function with MFA, roles, and append-only audit |
| APK/installer object storage | Private Cloudflare R2 |
| Protected release delivery | Dedicated Cloudflare download Worker |
| External payment | Approved hosted recurring-payment provider |
| Existing IPTV proxy | Existing root Cloudflare Worker, isolated from commercial secrets |

PostgreSQL is the source of truth for accounts, trials, devices, subscriptions, entitlements, releases, download authorization, and initial analytics. R2 stores binary release files only. Local Drift remains an app cache and is never authoritative for commercial access.

The private owner dashboard has its own detailed implementation brief in `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md`. That companion document is authoritative for dashboard frontend structure, admin roles, reporting definitions, safe owner actions, API DTOs, CSS, tests, and deployment. Agents implementing dashboard UI, administrative roles, reporting queries, owner actions, or dashboard deployment must read it completely in addition to this master plan. If the two documents conflict, preserve the security and commercial authority rules in this master plan and stop for an explicit decision rather than choosing silently.

---

## 7. Domain Model

### 7.1 App account

Minimum fields:

- `id`: opaque random identifier.
- `email_normalized`: normalized verified email.
- `email_verified_at`.
- `status`: `active`, `suspended`, `deletion_pending`, or `deleted`.
- `created_at`, `updated_at`.
- `last_login_at`.

Never expose sequential database identifiers.

### 7.2 Installation and device

Generate a random `installation_id` at first launch. Store it in platform secure storage.

- The installation ID identifies an app installation, not a human.
- Reinstalling may create another installation ID.
- Trial uniqueness is enforced by verified account, not installation ID.
- A device record belongs to an account after login.
- Allow the user to revoke old devices from the website and app.
- When the device limit is reached, require the user to remove an old device; do not silently evict one.

Suggested fields:

- Device ID and user ID.
- Installation ID hash.
- Platform: `android` or `windows`.
- User-assigned or sanitized display name.
- App version.
- OS version category.
- First seen, last seen, revoked at.
- Last entitlement refresh.

Do not collect hardware serial numbers, IMEI, MAC address, or invasive fingerprints.

### 7.3 Trial

A trial record is immutable after activation except for explicit administrative correction recorded in the audit log.

- `user_id` unique.
- `status`: `pending`, `active`, `expired`, `revoked`.
- `started_at` from server time.
- `ends_at` from server time.
- `duration_days_snapshot` so later configuration changes do not alter existing trials.
- `activation_platform`.
- `activated_by_event_id` for idempotency.

Recommended activation condition:

1. App account is verified.
2. User is signed in on an allowed device.
3. Existing IPTV provider authentication succeeds.
4. Flutter sends only an idempotent `iptv_connection_succeeded` activation request without credentials or server URL.
5. Backend creates the trial once.

### 7.4 Subscription

Subscription state is synchronized from the payment provider:

- `trialing`: reserved if the billing provider itself operates a trial; normally app trials remain separate.
- `active`.
- `past_due`.
- `grace_period`.
- `canceling_at_period_end`.
- `expired`.
- `refunded`.
- `disputed`.
- `suspended`.

Store provider identifiers and timestamps, never card data.

### 7.5 Entitlement

The entitlement service combines:

- Account status.
- Active app trial.
- Paid subscription state.
- Grace-period policy.
- Device status and device limit.
- Feature configuration.
- Minimum supported version.

The entitlement result must be deterministic and tested as a pure domain function before wiring it to HTTP handlers.

---

## 8. Supabase PostgreSQL Schema

Supabase PostgreSQL is the authoritative database. Manage all schema changes as versioned SQL migrations under `supabase/migrations`; do not make undocumented production-only changes through the dashboard.

Supabase Auth owns `auth.users`, identities, passwordless verification, and authentication sessions. Application-specific account data belongs in `public.profiles` keyed by `auth.users.id`. Do not create a second password or authentication table.

Use separate schemas where helpful:

- `public`: carefully exposed account-facing tables protected by Row Level Security.
- `private`: billing mappings, webhook records, entitlement overrides, idempotency, audit records, and other service-only data.
- `analytics`: raw events, active sessions, and aggregates; expose only safe views or Edge Functions.

The following logical tables are required:

```text
auth.users                     -- managed by Supabase Auth
public.profiles
installations
devices
device_pairing_codes
trials
plans
plan_prices
billing_customers
subscriptions
entitlements or entitlement_overrides
webhook_events
download_tokens
download_events
app_sessions
analytics_events
daily_metrics
release_versions
remote_config_versions
audit_logs
account_deletion_requests
```

### 8.1 Row Level Security policy matrix

Enable Row Level Security on every exposed `public` or `analytics` table. The default is deny.

| Data | Authenticated customer | Supabase Edge Function/service role | Admin |
|---|---|---|---|
| Own profile | Read/update approved fields | Read/update | Read/update |
| Own devices | Read; request revoke through controlled API | Create/update/revoke | Read/update |
| Own trial | Read summary only | Create/update through trial service | Read/correct with audit |
| Own subscription | Read safe summary only | Webhook-controlled writes | Read/support actions |
| Plans/public config | Read enabled public fields | Manage through deployment/admin path | Manage |
| Webhook events | No access | Insert/process | Read redacted status |
| Billing customer IDs | No direct access | Read/write | Read redacted values |
| Analytics raw events | No direct reads | Insert validated batches | Aggregated access |
| Audit logs | No access | Append | Read |

The Supabase anonymous key may be embedded in Flutter because RLS is the authorization boundary. The Supabase service-role key bypasses RLS and must never appear in Flutter, the portal bundle, logs, or Git.

### 8.2 Required constraints

- Account/profile ID is a foreign key to `auth.users.id`.
- Email identity and verification remain managed by Supabase Auth.
- One trial per user.
- Unique provider webhook event ID.
- Unique provider subscription ID.
- Unique installation ID hash.
- Unique active device association where appropriate.
- PostgreSQL foreign keys and check constraints enabled.
- Use `timestamptz` in UTC for authoritative state timestamps.
- No destructive cascade that can accidentally remove required financial audit records.
- Idempotency key table or unique constraints for mutating API operations.

### 8.3 Indexes

At minimum, index:

- Profiles by account status and creation date; use Supabase Auth for email lookup.
- Devices by user and last-seen time.
- Trials by user and status.
- Subscriptions by user, provider customer ID, provider subscription ID, status, and period end.
- Webhook events by provider event ID and processing state.
- App sessions by user and latest heartbeat.
- Analytics by occurred date, event name, platform, and app version.
- Downloads by account, release ID, platform, and timestamp.
- Releases by platform, channel, version, and publish status.

---

## 9. Authentication Design

### 9.1 Recommended initial method

Use Supabase Auth passwordless email OTP or magic links:

1. User enters email.
2. Flutter or the portal calls the Supabase Auth SDK.
3. Supabase Auth normalizes and processes the identity and challenge.
4. Supabase sends the OTP/link through the configured production SMTP provider.
5. Supabase Auth applies its authentication protections; add owner-controlled rate limits and bot protection to exposed portal flows where needed.
6. On successful verification, Supabase issues the authenticated session.
7. A database trigger or idempotent post-login function creates `public.profiles` without overwriting an existing profile.

### 9.2 Token policy

- Use Supabase Auth access and refresh sessions; do not implement a second token system.
- Configure appropriate Supabase JWT/session lifetimes and refresh behavior for native apps.
- Verify Supabase JWTs in every Edge Function and in the Cloudflare download gateway using the project's published verification keys/JWKS.
- Bind sessions to the registered device record.
- Allow explicit logout from current device and logout from all devices.
- Configure `supabase_flutter` with a custom native session storage adapter backed by this project's secure storage rather than plain SharedPreferences.
- Never send a Supabase service-role key to the client.
- Never place access or refresh tokens in URLs or analytics.

### 9.3 TV pairing

If Android TV is supported:

1. TV requests a short-lived device code.
2. TV displays a QR code and human-readable code.
3. Signed-in portal user approves the code.
4. TV polls with backoff.
5. The pairing Edge Function completes a Supabase-compatible, single-use handoff only for the requesting installation; do not invent or persist a parallel long-lived identity token.
6. Pairing code is single-use and expires within 5–10 minutes.

---

## 10. API Contract

The paths below are logical versioned contracts. Implement commercial business mutations as Supabase Edge Functions, normally exposed under `/functions/v1/<function-name>`. Keep request/response schemas explicitly versioned even when the deployment URL already contains `v1`. Customer-safe reads may use Supabase's generated API only when RLS is proven by tests; trials, entitlements, billing, releases, deletion, and administration must go through controlled functions.

### 10.1 Authentication

```text
Supabase Auth SDK: request email OTP/magic link
Supabase Auth SDK: verify OTP/exchange link
Supabase Auth SDK: refresh session
Supabase Auth SDK: sign out current session
Controlled Edge Function: revoke all account/device sessions when required
```

Do not recreate these endpoints inside a custom Worker. The portal and Flutter share the same Supabase Auth project and user identity.

### 10.2 User and devices

```text
GET    /v1/me
GET    /v1/devices
PATCH  /v1/devices/{deviceId}
DELETE /v1/devices/{deviceId}
POST   /v1/me/deletion-request
POST   /v1/me/deletion-cancel
```

### 10.3 Device pairing

```text
POST /v1/device-codes
GET  /v1/device-codes/{code}/status
POST /v1/device-codes/{code}/approve
```

### 10.4 Trial and entitlement

```text
POST /v1/trials/activate
GET  /v1/entitlement
POST /v1/entitlement/refresh
GET  /v1/config
```

`POST /v1/trials/activate` must require an idempotency key.

Example entitlement response:

```json
{
  "schemaVersion": 1,
  "accountStatus": "active",
  "accessStatus": "trialing",
  "planCode": "premium",
  "validUntil": "2026-09-05T12:00:00Z",
  "serverTime": "2026-08-29T12:00:00Z",
  "refreshAfterSeconds": 3600,
  "deviceLimit": 3,
  "features": {
    "liveTv": true,
    "movies": true,
    "series": true,
    "favorites": true,
    "history": true
  },
  "minimumSupportedVersion": "1.0.0",
  "lease": {
    "payload": "base64url-canonical-json",
    "signature": "base64url-ed25519-signature",
    "keyId": "entitlement-2026-01"
  }
}
```

### 10.5 Billing website only

```text
GET  /v1/billing/plans
POST /v1/billing/checkout-session
POST /v1/billing/portal-session
POST /v1/webhooks/billing/{provider}
```

The checkout and portal endpoints require an authenticated website session. Never accept a client-supplied provider customer ID, price amount, currency amount, or arbitrary success URL.

### 10.6 Analytics and online status

```text
POST /v1/analytics/batch
POST /v1/sessions/start
POST /v1/sessions/heartbeat
POST /v1/sessions/end
```

### 10.7 Downloads and releases

```text
GET  /v1/releases/latest?platform=android&channel=stable
POST /v1/downloads/authorize
GET  /v1/downloads/{shortLivedToken}
GET  /v1/updates/manifest?platform=windows&channel=stable
```

The release lookup and authorization decision are backed by Supabase/PostgreSQL. The final `GET /v1/downloads/{shortLivedToken}` is handled by the separate Cloudflare download gateway with a private R2 binding.

### 10.8 Administrative endpoints

Implement a single protected Supabase `admin-api` Edge Function with internal versioned route dispatch. Place it behind Supabase authentication, an active private admin-role record, capability checks, mutation-specific MFA/AAL2 requirements, rate limits, validation, and append-only auditing.

```text
GET  /admin-api/v1/session
GET  /admin-api/v1/overview
GET  /admin-api/v1/users
GET  /admin-api/v1/users/{userId}
GET  /admin-api/v1/subscriptions
GET  /admin-api/v1/downloads
GET  /admin-api/v1/activity
GET  /admin-api/v1/config
GET  /admin-api/v1/releases
GET  /admin-api/v1/audit
GET  /admin-api/v1/health

POST   /admin-api/v1/users/{userId}/suspend
POST   /admin-api/v1/users/{userId}/reactivate
POST   /admin-api/v1/devices/{deviceId}/revoke
POST   /admin-api/v1/users/{userId}/entitlement-overrides
DELETE /admin-api/v1/entitlement-overrides/{overrideId}
POST   /admin-api/v1/subscriptions/{subscriptionId}/sync
POST   /admin-api/v1/config/drafts
POST   /admin-api/v1/config/drafts/{draftId}/validate
POST   /admin-api/v1/config/drafts/{draftId}/publish
POST   /admin-api/v1/releases/{releaseId}/publish
POST   /admin-api/v1/releases/{releaseId}/revoke
```

Every administrative mutation requires an idempotency key, human-readable reason, server-side permission check, confirmation in the UI, and an audit record containing actor, role, target, sanitized before state, sanitized after state, result, timestamp, and request correlation ID.

The browser may never directly edit raw trial timestamps or subscription status. Billing-provider state remains webhook/provider authoritative. Initial owner actions are limited to device revocation, account suspension/reactivation, time-bounded complimentary entitlement overrides, provider resynchronization, immutable configuration publishing, and release metadata publishing/revocation as defined by the dashboard companion plan.

---

## 11. Payment and Subscription Processing

### 11.1 Provider abstraction

Implement a small server-side interface so core entitlement logic is not tied to one vendor:

```text
BillingProvider
  createCheckoutSession(...)
  createCustomerPortalSession(...)
  verifyAndParseWebhook(rawBody, headers)
  retrieveSubscription(providerSubscriptionId)
```

Only implement the approved production provider. Do not build speculative adapters.

### 11.2 Checkout rules

- The browser user must already be signed into the first-party app account.
- The backend creates or retrieves the provider customer mapping.
- Plan code is mapped to an enabled server-side immutable price ID.
- The browser never submits the actual charge amount.
- Use provider-hosted checkout.
- Associate checkout metadata with the internal user ID using non-sensitive identifiers.
- Restrict success and cancel redirects to allowlisted owner-controlled HTTPS URLs.

### 11.3 Webhook rules

Webhook processing must:

1. Read the exact raw request body.
2. Verify the provider signature and timestamp tolerance.
3. Reject invalid signatures before parsing business fields.
4. Insert the provider event ID under a unique constraint.
5. Return success for previously processed events without applying them twice.
6. Store a safe minimal event record and processing status.
7. Process out-of-order events by comparing authoritative provider state and event timestamps.
8. Update subscription state in one transaction where supported.
9. Recompute entitlement.
10. Write an audit entry.
11. Emit internal analytics without copying sensitive provider payloads.

Handle at least:

- Checkout completed.
- Subscription created.
- Subscription updated.
- Subscription canceled/deleted.
- Invoice or recurring payment succeeded.
- Payment failed.
- Refund completed.
- Dispute opened and resolved.

### 11.4 Access policy

- `active`: access through `current_period_end`.
- `canceling_at_period_end`: access remains until period end.
- `past_due`: enter configured grace period.
- Grace expired: deny premium access.
- Refunded/disputed: apply the approved business policy; do not invent it.
- Administrative override: time-bounded, reason required, and audited.

---

## 12. Trial and Entitlement Security

### 12.1 Server authority

The server calculates trial and paid access from its own clock. Client timestamps are informational only.

### 12.2 Offline lease

Return a signed entitlement lease for limited offline use:

- Recommended lifetime: 24 hours.
- Payload includes account ID hash/subject, device ID, access state, features, issued-at, expiration, key ID, and app audience.
- Sign canonical bytes using an asymmetric key such as Ed25519.
- Keep the private key only in backend secret storage.
- Embed only the public verification key in Flutter.
- Support key rotation through `keyId` and overlapping public keys.
- Cache the signed lease in secure storage.
- Reject expired, malformed, wrong-device, wrong-audience, or invalid-signature leases.

An online entitlement denial overrides a cached lease. Clear the cache on logout or device revocation.

### 12.3 Clock manipulation

Maintain `lastTrustedServerTime` and monotonic elapsed duration where available. A device clock moving backward must never extend the lease. If time integrity cannot be established after lease expiration, require connectivity.

### 12.4 Realistic security boundary

Directly distributed client binaries can be patched. The goal is to make normal abuse and local-state manipulation ineffective, not to claim unbreakable DRM. Keep commercially important authority on the server and rotate compromised keys/tokens.

---

## 13. Analytics Specification

### 13.1 Metric definitions

Do not use these terms interchangeably:

| Metric | Definition |
|---|---|
| Download authorization | A verified account was issued a valid release download authorization |
| Download request | The download gateway accepted a valid request and began serving an approved release |
| Completed transfer | Full file delivery confirmed by CDN/storage telemetry when available |
| Installation | Unique random installation ID first observed by the API |
| Registered user | Verified first-party app account |
| Activated user | Verified account whose IPTV connection succeeded and whose trial was activated |
| DAU | Distinct accounts with meaningful foreground activity on one UTC day |
| WAU | Distinct active accounts in the trailing seven days |
| MAU | Distinct active accounts in the trailing 30 days |
| Online now | Non-revoked account/device heartbeat received within the last five minutes |
| Trial user | Account with currently valid trial entitlement |
| Paying user | Account with valid paid entitlement |
| Concurrent app sessions | Distinct active device sessions within the online threshold |
| WAEA | Weekly Active Entitled Accounts: valid trial/paid accounts with meaningful activity on at least two different days in the trailing seven days |

Report users and devices separately.

The dashboard must use these canonical definitions and the expanded definitions in `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md`. It must not calculate alternative versions in React. PostgreSQL reporting functions or Edge Functions calculate metrics; the dashboard renders typed results and visible definitions.

### 13.2 Initial event catalog

Allowlist event names and property schemas server-side:

- `app_first_open`
- `app_updated`
- `session_started`
- `session_heartbeat`
- `session_ended`
- `account_created`
- `account_signed_in`
- `device_registered`
- `trial_started`
- `trial_expiring`
- `trial_expired`
- `subscription_page_opened`
- `subscription_activated`
- `subscription_renewed`
- `payment_failed`
- `subscription_canceled`
- `entitlement_refreshed`
- `entitlement_denied`
- `iptv_connection_succeeded`
- `playback_started`
- `playback_failed`
- `download_authorized`
- `release_download_requested`
- `update_available`
- `update_downloaded`

### 13.3 Forbidden analytics properties

Reject or strip:

- IPTV server hostname or URL.
- IPTV username or password.
- Playlist or stream URL.
- URL query strings.
- Channel/movie/series titles.
- Email address in ordinary event properties.
- Access or refresh tokens.
- Payment-provider payloads.
- Free-form exceptions that may contain credentials.

### 13.4 Client behavior

- Queue events locally with bounded storage.
- Batch events rather than one HTTP call per event.
- Give every event a UUID for deduplication.
- Include schema version, UTC occurrence time, platform, app version, installation ID, and authenticated account ID only when available.
- Flush on a safe interval and app backgrounding.
- Use exponential backoff with jitter.
- Drop low-value events when the queue reaches its limit.
- Never delay playback or navigation while sending analytics.
- Heartbeat every two minutes while the application is foregrounded and meaningfully active.
- Stop heartbeat when backgrounded, logged out, or closed.

### 13.5 Dashboard metrics

Build or expose data for:

- APK versus Windows download requests.
- Unique download accounts.
- Installation and activation counts.
- DAU, WAU, MAU.
- Weekly Active Entitled Accounts (WAEA) north-star metric.
- Online accounts and device sessions.
- Trial starts, active trials, and expirations.
- Trial-to-paid conversion.
- Monthly versus yearly subscribers.
- Active, past-due, canceling, and expired subscriptions.
- Recurring revenue as reported by the billing provider.
- Renewal, cancellation, and payment-failure rates.
- App version distribution.
- Playback-start and playback-failure rates without content identifiers.
- Download-to-install and install-to-activation conversion.

---

## 14. Download Distribution

### 14.1 Storage and authorization

Store releases in a private R2 bucket or equivalent object storage.

Download flow:

1. User signs into the portal.
2. Portal uses its Supabase Auth session to request authorization for an enabled release.
3. A Supabase Edge Function verifies the account/release and creates a short-lived, single-use download authorization stored in PostgreSQL.
4. Portal opens the Cloudflare download-gateway URL containing only the opaque authorization token.
5. The download gateway consumes the authorization, reads the approved object through its private R2 binding, and streams it to the customer.
6. The gateway records or queues the download request back to the protected Supabase service endpoint.
7. CDN/object-storage telemetry records bytes delivered when available.

Do not label a redirect or token creation as a completed download. Report `download_requested` and `completed_transfer` separately if completion evidence exists.

### 14.2 Release metadata

Each release record includes:

- Platform.
- Architecture.
- Release channel: `stable`, `beta`, or `internal`.
- Semantic version.
- Build number.
- Object key.
- File size.
- SHA-256 digest.
- Detached release-manifest signature.
- Minimum supported prior version.
- Mandatory-update flag.
- Release notes in English and Arabic.
- Published and revoked timestamps.

### 14.3 Abuse controls

- Short-lived tokens.
- Per-account and per-IP-risk-bucket rate limits.
- Maximum token uses.
- No permanent public R2 object URL.
- The download Worker verifies Supabase JWTs through published JWKS when a JWT-authenticated route is used; it never contains a browser-exposed service-role key.
- Ability to revoke a compromised release.
- Alert on abnormal repeated downloads.

---

## 15. Secure Release and Update Strategy

### 15.1 Android

- Replace `com.example.iptv` with the confirmed permanent application ID before the first customer release.
- Configure a protected release keystore.
- Keep the same signing identity for all updates.
- Keep keystore file and passwords outside Git.
- Build only release APKs for customers.
- Decide universal versus architecture-specific APKs and record the choice.
- Generate and publish SHA-256 checksums.
- Verify the final APK signature in CI.
- Preserve a secure, offline backup of signing materials.

### 15.2 Windows

- Prefer a signed installer package rather than a loose executable.
- Use Authenticode signing with a certificate matching the permanent publisher identity.
- Timestamp signatures.
- Verify signatures after packaging.
- Publish SHA-256 checksums.
- Ensure updates use the same trusted publisher.
- Test SmartScreen and clean-machine installation behavior.

### 15.3 Update manifest

Example signed manifest:

```json
{
  "schemaVersion": 1,
  "platform": "windows",
  "architecture": "x64",
  "channel": "stable",
  "version": "1.2.0",
  "buildNumber": 120,
  "minimumSupportedVersion": "1.0.0",
  "mandatory": false,
  "fileSize": 123456789,
  "sha256": "hex-digest",
  "downloadAuthorizationPath": "/v1/downloads/authorize",
  "publishedAt": "2026-08-29T12:00:00Z",
  "keyId": "release-2026-01",
  "signature": "base64url-signature"
}
```

The client must verify the manifest signature and downloaded file digest. It must not execute a file received from an arbitrary unsigned URL.

---

## 16. Flutter Integration Plan

Follow the repository's layered/feature-first design.

### 16.1 New core infrastructure

Recommended files:

```text
lib/core/commercial/
  supabase_client_factory.dart
  supabase_secure_auth_storage.dart
  commercial_edge_functions_client.dart
  commercial_api_config.dart
  commercial_models.dart

lib/core/identity/
  installation_identity.dart
  trusted_time_service.dart

lib/core/security/
  signed_payload_verifier.dart

lib/core/analytics/
  analytics_client.dart
  analytics_event.dart
  analytics_queue.dart
  analytics_policy.dart

lib/core/releases/
  release_manifest.dart
  release_verifier.dart
  update_service.dart
```

Add `supabase_flutter` only during the authentication phase and configure it with environment-provided non-secret project URL/anonymous key plus secure native auth-session storage. Do not reuse the IPTV `ApiClient` because it adds IPTV provider authentication and targets arbitrary provider servers. Supabase and commercial Edge Function traffic must use a dedicated fixed HTTPS origin.

### 16.2 New domain layer

```text
lib/domain/entities/app_account.dart
lib/domain/entities/app_device.dart
lib/domain/entities/app_entitlement.dart
lib/domain/entities/subscription_summary.dart
lib/domain/entities/release_info.dart

lib/domain/repositories/app_account_repository.dart
lib/domain/repositories/entitlement_repository.dart
lib/domain/repositories/device_repository.dart
lib/domain/repositories/analytics_repository.dart
lib/domain/repositories/release_repository.dart
```

### 16.3 New data layer

```text
lib/data/repositories/app_account_repository_impl.dart
lib/data/repositories/entitlement_repository_impl.dart
lib/data/repositories/device_repository_impl.dart
lib/data/repositories/analytics_repository_impl.dart
lib/data/repositories/release_repository_impl.dart
```

### 16.4 New features

```text
lib/features/account/
  account_controller.dart
  sign_in_screen.dart
  verify_code_screen.dart
  account_screen.dart
  devices_screen.dart

lib/features/subscription/
  entitlement_controller.dart
  trial_status_card.dart
  access_required_screen.dart
  subscription_status_screen.dart

lib/features/device_pairing/
  device_pairing_screen.dart

lib/features/updates/
  update_controller.dart
  update_dialog.dart
```

### 16.5 Provider changes

Add independent providers to `lib/app/providers.dart` or split the file if it becomes too large:

- `appAccountRepositoryProvider`.
- `appAccountSessionProvider`.
- `entitlementRepositoryProvider`.
- `entitlementProvider`.
- `deviceRepositoryProvider`.
- `analyticsProvider`.
- `releaseRepositoryProvider`.
- `updateProvider`.

Preserve the existing IPTV `sessionProvider`, but rename it to `iptvSessionProvider` only in a dedicated mechanical refactor with complete test coverage. Do not mix this rename into unrelated billing behavior if it makes review unsafe.

### 16.6 Router behavior

Update `lib/app/router.dart` to evaluate both independent states.

Suggested routing sequence:

```text
Application booting
  -> Splash

No first-party app account
  -> App account sign-in

App account exists, entitlement loading, valid cached lease exists
  -> Continue with cached entitlement while refreshing

App account exists, no IPTV provider session
  -> Existing onboarding

IPTV login succeeds and trial is pending
  -> Activate trial, then enter app

Valid trial or subscription plus IPTV session
  -> Main shell

Expired/denied entitlement
  -> Access-required screen
```

The access-required screen and account/settings routes remain accessible when premium access is denied. Playback routes and premium catalog routes must be gated.

### 16.7 Trial activation integration

After existing IPTV authentication succeeds:

1. Complete saving IPTV credentials locally as today.
2. Send a credential-free, idempotent trial activation request.
3. Refresh entitlement.
4. Navigate according to entitlement.

If trial activation cannot reach the server on first use, do not fabricate a local seven-day trial. Show a retryable connectivity message.

### 16.8 Subscribe action

- Obtain the owner-controlled portal URL from validated remote configuration.
- Allow only HTTPS and an allowlisted hostname.
- Open with the system external browser.
- Never append IPTV data or auth tokens to the URL.
- If implementing single sign-on to the portal later, use a one-time short-lived handoff code, not a long-lived bearer token in a query string.

### 16.9 Localization

Add all customer-facing strings to both:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_ar.arb`

Regenerate Flutter localization files. Cover sign-in, verification, trial countdown, expiration, subscription status, refresh access, device limit, revoke device, offline lease, update availability, and account deletion.

---

## 17. Remote Configuration

Serve signed or authenticated configuration from `/v1/config`.

Configurable values include:

- Trial duration for new trials.
- Device limit.
- Offline lease duration within a safe server-enforced maximum.
- Grace period.
- Enabled plan codes.
- Public display price and currency.
- Portal URL.
- Support URL and email.
- Feature entitlement map.
- Analytics sampling and kill switch.
- Minimum supported app version.
- Latest release information.
- Maintenance mode.

### Safety rules

- Existing trials retain snapshot duration.
- Do not let remote configuration provide arbitrary executable URLs.
- Do not trust display prices for billing amounts.
- Plan code must resolve to a server-side provider price ID.
- Validate configuration schema and keep the last known valid configuration.
- Provide conservative compiled defaults for non-commercial UI behavior only.

---

## 18. Security Requirements

### 18.1 API

- HTTPS only.
- Strict CORS limited to the customer portal origin; native clients do not require permissive browser CORS.
- Request size limits.
- JSON content-type enforcement.
- Schema validation for every request.
- Authentication and role middleware.
- Rate limiting for auth, pairing, trial activation, checkout, downloads, and analytics.
- Idempotency for mutating requests.
- Correlation IDs.
- Generic client errors; detailed redacted server logs.
- No secrets in exceptions.

### 18.2 Secrets

Use Supabase project secrets/Vault for Edge Functions and Cloudflare Worker secrets for the download gateway. Store each secret only in the service that needs it:

- Email-provider credentials.
- Billing API secret.
- Billing webhook secret.
- Entitlement signing private key.
- Release-manifest signing private key.
- Supabase service-role key, only in trusted server environments that genuinely require it.
- R2 access credentials if bindings cannot be used; prefer Worker R2 bindings.
- Administrative integration credentials.

Supabase Auth signing/session infrastructure is managed by Supabase; do not create a competing application JWT signer. Only the Supabase project URL, anonymous/publishable key, public verification keys, and other non-secret environment identifiers may be compiled into Flutter. The anonymous/publishable key is safe only when every exposed table has correct RLS.

### 18.3 Logging

Create a shared redaction layer. Redact:

- Authorization headers.
- Cookies.
- Email addresses where not operationally required.
- Tokens and codes.
- URLs with query strings.
- IPTV credentials and authenticated URLs.
- Payment payload fields beyond approved IDs and statuses.

### 18.4 Administration

- MFA required.
- Least-privilege roles.
- Separate admin origin where practical.
- No unaudited database editing for routine support.
- Time-bounded manual entitlement grants.
- Alert on repeated failed admin login and mass export attempts.

### 18.5 Backups and recovery

- Use a paid Supabase production plan with automatic daily PostgreSQL backups; evaluate point-in-time recovery against the required recovery-point objective.
- Produce periodic encrypted logical `pg_dump` backups to an owner-controlled location separate from the Supabase project.
- Test PostgreSQL restoration into a non-production project.
- Release object versioning or protected retention.
- Documented restore runbook.
- Test a restore before production launch.
- Record recovery time and recovery point objectives.

---

## 19. Privacy and Account Lifecycle

Before production, create:

- Privacy policy.
- Terms of service.
- Subscription, renewal, cancellation, and refund terms.
- Acceptable-use policy.
- Copyright/takedown policy.
- Data retention schedule.
- Support process.

### Account deletion

The portal and supported app surfaces must offer account deletion.

Deletion workflow:

1. Reauthenticate the user.
2. Explain what happens to an active subscription.
3. Cancel renewal or send the user through the approved billing cancellation flow.
4. Set deletion pending and revoke active sessions.
5. Delete or anonymize personal analytics data.
6. Revoke devices and tokens.
7. Request deletion from processors where applicable.
8. Retain only legally required financial/fraud records with documented retention.
9. Complete deletion asynchronously and notify the user.
10. Preserve a non-identifying audit record.

---

## 20. Testing Strategy

### 20.1 Backend unit tests

- Supabase-auth callback/profile provisioning idempotency.
- Edge Function JWT validation and rejection of anonymous requests where authentication is required.
- Device limit evaluation.
- Trial activation idempotency.
- Trial expiration boundary exactly at `ends_at`.
- Entitlement state for every trial/subscription combination.
- Grace-period start and expiration.
- Version comparison.
- Event schema allowlisting and redaction.
- Release manifest generation and verification.

### 20.2 Backend integration tests

- Supabase PostgreSQL migrations from an empty local/staging project.
- RLS tests proving one account cannot read or mutate another account's profile, devices, trial, subscription, events, or releases.
- Supabase Auth sign-in, refresh, logout, and profile provisioning.
- Device pairing success, expiry, reuse rejection, and denial.
- Duplicate trial activation.
- Checkout session authorization.
- Valid and invalid webhook signatures.
- Duplicate webhook delivery.
- Out-of-order subscription webhooks.
- Payment success, renewal, failure, cancellation, refund, and dispute.
- Download token expiry and reuse rules.
- Cloudflare download gateway JWT/authorization verification and private R2 access.
- Admin authorization and audit logging.

### 20.3 Flutter unit tests

- App-account and entitlement model parsing.
- Signed lease verification.
- Expired and wrong-device lease rejection.
- Trusted-time handling after device clock rollback.
- Analytics property filtering.
- Queue bounds and retry behavior.
- Remote configuration validation.
- Semantic version comparison.

### 20.4 Flutter widget/navigation tests

- Signed-out user reaches app-account sign-in.
- Signed-in user without IPTV session reaches existing onboarding.
- IPTV success activates trial without transmitting credentials.
- Valid trial reaches the main app.
- Expired trial reaches access-required screen.
- Valid paid entitlement restores access.
- Offline valid lease allows access.
- Offline expired lease denies access with a useful message.
- Subscribe button launches only the allowlisted HTTPS website.
- Device limit UI allows revocation and retry.
- English and Arabic layouts render without overflow.
- Keyboard and TV D-pad focus order works.

### 20.5 Security tests

- Reinstall does not create a second trial for the same account.
- Clearing local preferences does not reset trial.
- Changing device clock backward or forward does not extend entitlement.
- Modified signed lease is rejected.
- Modified update manifest is rejected.
- Modified installer/APK checksum is rejected.
- Expired or revoked Supabase session is rejected by Edge Functions and the download gateway.
- Supabase service-role access is absent from Flutter and portal build artifacts.
- RLS prevents direct client writes to trials, subscriptions, webhook events, entitlements, audit logs, and release signatures.
- Webhook replay does not duplicate access.
- Arbitrary checkout price ID is rejected.
- Open redirect attempts are rejected.
- IPTV credentials never appear in control-plane traffic or logs.
- Analytics rejects forbidden properties.
- Rate limits fail safely.

### 20.6 Release verification

- `flutter analyze` passes.
- `flutter test` passes.
- Backend lint, type checking, unit tests, and integration tests pass.
- Android release signature verifies.
- Windows Authenticode signature verifies.
- SHA-256 digests match uploaded objects.
- Clean Windows machine install/uninstall/update succeeds.
- Clean Android device install/update succeeds.
- Upgrade preserves account and IPTV secure storage.

---

## 21. Observability and Alerts

Instrument the control plane with metrics and alerts for:

- API availability and latency.
- Authentication failure spikes.
- Email delivery failures.
- Webhook signature failures.
- Webhook processing backlog.
- Supabase Auth, PostgreSQL, RLS, migration, and Edge Function errors.
- Cloudflare download gateway and R2 errors.
- Entitlement-denial spikes by app version.
- Payment failure rate.
- Download authorization abuse.
- Release manifest verification failures.
- Analytics ingestion rejection rate.
- Online session heartbeat volume.

Create a runbook for every production alert before launch.

---

## 22. Implementation Phases and Gates

The agent must work phase by phase. Do not start the next phase until the current phase gate passes and changes are reviewable.

### Phase 0: Confirm decisions and write architecture records

Tasks:

- Record the status of every value in Section 5 and obtain only the decisions required for the current phase; do not pretend unresolved production decisions are confirmed.
- Verify current repository structure.
- Create architecture decision records confirming Supabase Auth/PostgreSQL/Edge Functions, Cloudflare Pages/R2/download gateway, billing provider, control-plane separation, and entitlement signing.
- Produce a data-flow diagram and threat model.
- Define development, staging, and production environments.

Gate:

- The confirmed architecture and free development/staging endpoint strategy are recorded.
- Every unresolved production decision has an explicit owner and a latest-required phase.
- No unresolved decision blocks the immediate Phase 1 foundation work.
- No production secret exists in source.

### Phase 1: Supabase control-plane foundation

Tasks:

- Initialize the repository's `supabase/` project structure.
- Create separate development and staging Supabase projects/configuration without production data.
- Configure local Supabase development and versioned PostgreSQL migrations.
- Create schemas, roles, initial tables, constraints, indexes, and deny-by-default RLS policies.
- Scaffold shared Edge Function request validation, errors, correlation IDs, logging redaction, CORS, and rate-limit interfaces.
- Add health/version functions and migration/RLS tests.
- Scaffold `services/download_gateway` with no production secrets and no public R2 objects.
- Document Supabase CLI, Edge Function, and download-gateway local development.

Gate:

- PostgreSQL migrations, RLS tests, Edge Function type checking/tests, download-gateway tests, and staging deployments pass.
- Existing IPTV proxy behavior remains unchanged.

### Phase 2: Authentication and devices

Tasks:

- Integrate Supabase Auth email OTP/magic-link authentication and production SMTP configuration.
- Configure secure native Supabase session storage, refresh, logout, and revocation behavior.
- Implement installations and devices.
- Implement TV pairing if required.
- Add Flutter app-account session and sign-in UI.

Gate:

- A user can sign in on Android and Windows.
- Supabase sessions survive restart securely and refresh correctly.
- Logout and device revocation work.
- IPTV credentials remain separate and unchanged.

### Phase 3: Trial and entitlement engine

Tasks:

- Implement trial activation and pure entitlement evaluator.
- Implement signed offline leases and key rotation structure.
- Add Flutter entitlement repository/controller.
- Update routing and access gates.
- Connect credential-free trial activation after IPTV success.

Gate:

- Reinstall and clock manipulation tests pass.
- Online and offline entitlement tests pass.
- Trial expires at the exact server-authoritative boundary.

### Phase 4: Customer portal and billing sandbox

Tasks:

- Build portal authentication using the same Supabase Auth project and identity as Flutter.
- Display server-configured plans.
- Implement hosted checkout and customer portal session creation through authenticated Edge Functions.
- Implement signed, idempotent payment webhooks in a service-role Edge Function.
- Map all required billing states.
- Add subscription screen and external-browser action in Flutter.

Gate:

- Full sandbox lifecycle passes: subscribe, renew, fail, recover, cancel, expire, refund.
- Browser success redirect alone cannot grant access.

### Phase 5: Analytics foundation and owner dashboard

Tasks:

- Implement event schemas, batching, Edge Function ingestion, PostgreSQL deduplication, retention, and daily aggregation.
- Implement foreground session heartbeat.
- Freeze canonical metric definitions and deterministic SQL fixtures.
- Add private admin roles, capability checks, append-only audit functions, reporting views/functions, indexes, and RLS tests.
- Implement the protected Supabase `admin-api` Edge Function with safe typed DTOs, MFA/capability enforcement, pagination, validation, correlation IDs, and rate limits.
- Create the separate `admin-dashboard/` React + TypeScript + Vite application using CSS/CSS Modules and deploy staging through Cloudflare Pages.
- Implement dashboard overview, users, subscriptions, downloads, activity, plans/config, audit, and health foundations according to `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md`.
- Implement only the approved safe owner actions; never allow direct trial/subscription authority edits.
- Verify forbidden IPTV and personal fields are rejected.

Gate:

- Non-admins and insufficient roles cannot access protected reports/actions; MFA is required for production mutations.
- Downloads, completed transfers, installations, DAU, WAU, MAU, WAEA, online users, trials, and paying users are displayed as distinct metrics and match deterministic database fixtures.
- Every owner mutation requires reason/idempotency and produces an append-only audit record.
- The dashboard browser contains no Supabase service-role, billing, R2, webhook, SMTP, or signing secret.
- Analytics never blocks playback or startup.

### Phase 6: Direct downloads and secure updates

Tasks:

- Configure a private Cloudflare R2 release bucket.
- Implement PostgreSQL release metadata, Supabase authorization, and the isolated Cloudflare download gateway.
- Implement signed update manifests.
- Add Flutter update checks and safe UX.
- Configure Android and Windows production signing.
- Integrate the dashboard Releases page with verified PostgreSQL metadata and approved publish/revoke actions; never perform signing in the browser.

Gate:

- Expired download links fail.
- Tampered manifests and files fail verification.
- Clean-machine installation and upgrade tests pass.

### Phase 7: Privacy, deletion, operations, and hardening

Tasks:

- Implement account deletion.
- Complete policies and retention rules.
- Configure Supabase production backups, periodic encrypted logical PostgreSQL exports, R2 retention, restore tests, alerts, and runbooks.
- Perform threat-model review and dependency audit.
- Load test auth, entitlement, analytics, downloads, and webhook endpoints.
- Complete dashboard audit/health pages, Cloudflare Pages security headers, optional Cloudflare Access, accessibility testing, and end-to-end tests.

Gate:

- Restore drill passes.
- Deletion workflow passes.
- No high-severity unresolved security issue remains.

### Phase 8: Controlled production rollout

Tasks:

- Internal release.
- Small invited customer cohort.
- Monitor sign-in, trial activation, entitlement errors, payments, downloads, and updates.
- Increase rollout only after stability gates pass.

Suggested rollout:

1. Internal accounts.
2. 5–10 invited customers.
3. 25 customers.
4. 100 customers.
5. General direct distribution.

Gate:

- HOPE TV name/trademark validation is complete or the owner has approved a legally reviewed replacement before commercial launch.
- Permanent Android application ID, Windows publisher identity, production custom domain, merchant entity, payment provider, prices, tax/refund policy, email provider, and support contact are confirmed.
- Production uses the approved paid Supabase plan/backups rather than relying on a free development project.
- No systemic payment/entitlement mismatch.
- Support process can handle account, device, and billing requests.
- Owner dashboard authorization, MFA, audit, health, and production security-header gates pass.
- Rollback procedure is verified.

---

## 23. Agent Execution Protocol

Every LLM coding agent working from this plan must follow this protocol:

1. Read this entire document, `ARCHITECTURE.md`, `pubspec.yaml`, current router/providers, secure storage, authentication repository, Worker configuration, and any existing `supabase/` configuration before editing.
   When the task touches the owner dashboard, administrative reporting, admin roles, safe owner actions, or dashboard deployment, also read `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md` completely before editing.
2. Inspect for `AGENTS.md` and follow any applicable repository instructions.
3. Check `git status` and preserve unrelated user changes.
4. State the current phase and exact acceptance gate before implementation.
5. Do not implement more than one major phase in a single unreviewable change.
6. Add or update tests with each behavior change.
7. Use interfaces at external boundaries: billing, email, storage, analytics, and clock.
8. Inject a clock into trial and subscription logic; do not scatter direct current-time calls through domain code.
9. Use idempotency keys and unique database constraints for all replayable operations.
10. Never log secrets or IPTV credentials.
11. Never invent production domains, prices, provider IDs, certificates, or secret values.
12. Do not weaken existing secure IPTV credential storage.
13. Do not modify the public IPTV proxy to hold commercial secrets.
14. Run the narrowest relevant tests during development, then the full required suite before handoff.
15. Update documentation, migrations, example environment files containing placeholders only, and operational runbooks.
16. At phase completion, report:
    - Files changed.
    - Migrations added.
    - Tests run and exact results.
    - Security-sensitive decisions.
    - Remaining risks.
    - Whether the phase gate passed.
17. Stop and request owner input when a decision from Section 5 materially changes production behavior.

---

## 24. Definition of Done

The commercial system is complete only when all statements below are true:

- A verified account receives at most one normal seven-day trial.
- Trial timing is server-controlled.
- Reinstalling or clearing local data does not reset the account trial.
- Device clock changes do not extend trial or paid access.
- IPTV credentials never leave the existing IPTV client flow.
- The app has no embedded payment form or checkout WebView.
- The subscription action opens an allowlisted HTTPS website in the external browser.
- Paid access is granted only from authenticated provider state/webhooks.
- Duplicate and out-of-order webhooks are safe.
- Monthly and yearly plans are remotely configurable without trusting client-supplied prices.
- Cancellation preserves access only through the authorized paid period.
- Failed-payment grace behavior matches configuration.
- Offline access uses a short-lived, signed, device-bound lease.
- Users can list and revoke devices.
- Download requests are tracked separately from installations and active users.
- Download authorizations, accepted download requests, completed transfers, installations, and activations are reported separately.
- DAU, WAU, MAU, WAEA, online users, trial users, and paying users have documented definitions and match deterministic database fixtures.
- Analytics contains no IPTV credentials, URLs, or content-identifying data.
- The separate React + TypeScript owner dashboard is protected by Supabase Auth, private admin roles, and MFA for mutations.
- Dashboard permissions are enforced in the `admin-api` Edge Function rather than trusted from React.
- Safe owner actions require confirmation, reason, idempotency, server-side authorization, and append-only audit records.
- The dashboard offers no direct editing of raw trial timestamps or provider subscription state.
- The dashboard browser contains no Supabase service-role, payment, R2, webhook, SMTP, or signing secret.
- Dashboard overview, users, subscriptions, downloads, activity, plans/config, releases, audit, and health pages pass the companion plan's acceptance criteria.
- APK releases verify with the permanent release signing identity.
- Windows releases verify with the approved Authenticode publisher.
- Update manifests and release files are cryptographically verified.
- Account deletion and retention rules work as documented.
- Production secrets are absent from Git.
- Supabase RLS tests prove cross-account isolation and prevent clients from writing trial, subscription, entitlement, webhook, audit, or release-signature authority.
- Supabase service-role credentials are absent from Flutter, portal assets, and the public IPTV proxy.
- Backups, restoration, alerts, and rollback have been tested.
- English, Arabic, Android, Windows, and TV-relevant navigation tests pass.
- `flutter analyze`, `flutter test`, backend type checking, backend tests, signature verification, and release verification all pass.

---

## 25. Recommended First Agent Task

The first implementation task should be **Phase 0 plus the non-production portion of Phase 1 only**:

1. Verify repository observations.
2. Record the confirmed HOPE TV/Supabase/Cloudflare/React-TypeScript dashboard direction and gather only the unresolved production decisions in Section 5.
3. Write architecture decision records confirming Supabase as the control plane and Cloudflare as the portal/release-delivery edge.
4. Initialize the local `supabase/` project and scaffold shared Edge Function infrastructure.
5. Create initial PostgreSQL migrations, deny-by-default RLS policies, and migration/RLS tests.
6. Scaffold the isolated `services/download_gateway` Worker with a private R2 binding placeholder.
7. Add health, version, request validation, correlation ID, and redacted logging foundations.
8. Do not integrate a production billing provider or change Flutter routing until the Phase 1 gate passes.

This order makes Supabase PostgreSQL the commercial source of truth while keeping release delivery and the existing IPTV proxy isolated from authentication and billing authority.
> **Release delivery update:** GitHub Releases replaced the planned private-R2/download-gateway design. For current behavior, see `docs/commercial/adr/0008-github-releases.md`; R2 sections below are retained as historical planning context only.
