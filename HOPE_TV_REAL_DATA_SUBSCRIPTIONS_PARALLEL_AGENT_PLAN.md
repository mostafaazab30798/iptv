# HOPE TV Real Data and Subscription Control — Parallel LLM Agent Execution Plan

**Product:** HOPE TV  
**Primary workspace:** `D:\PROJECTS\iptv`  
**Canonical dashboard:** `D:\PROJECTS\iptv\hope-tv-insights`  
**Production Supabase project:** `otmovtxevvuxbsrmurkb` (`ap-southeast-1`)  
**Dashboard origin:** `https://hope-tv.mostafaazab3024.workers.dev`  
**Audience:** An LLM coding agent with simultaneous access to the Flutter/backend repository and the dashboard repository  
**Objective:** Make Android and Windows usage, download, installation, trial, entitlement, and subscription data trustworthy and operable from the owner dashboard without exposing privileged credentials or creating in-app purchases.

---

## 1. Agent operating contract

Execute this document phase by phase. Do not skip a gate because a page looks complete.

### 1.1 Repository map

| Lane | Path | Authority |
|---|---|---|
| Flutter application | `D:\PROJECTS\iptv\lib`, `android`, `windows` | Emits app telemetry, registers devices, requests entitlements, enforces access |
| Canonical backend | `D:\PROJECTS\iptv\supabase` | Database migrations and all production Edge Functions |
| Download gateway | `D:\PROJECTS\iptv\services\download_gateway` | Protects private release files and records accepted download requests |
| Canonical owner dashboard | `D:\PROJECTS\iptv\hope-tv-insights` | Displays server-authoritative metrics and submits audited owner actions |
| Legacy dashboard prototype | `D:\PROJECTS\iptv\admin-dashboard` | Reference only; do not implement new production work here |

`hope-tv-insights` is a nested, separate Git repository connected to Lovable. Read and obey `hope-tv-insights/AGENTS.md`. Never force-push, rebase, amend, squash, or otherwise rewrite published history.

The only production backend is the root `supabase/` directory. Do **not** deploy `hope-tv-insights/supabase/functions/`; it is a dashboard-side copy/reference and can drift.

### 1.2 Change discipline

1. Run `git status --short` independently in both repositories before every phase.
2. Preserve all pre-existing changes. Never reset, discard, or overwrite unrelated work.
3. Define contracts in the canonical backend first, then update Flutter and dashboard consumers.
4. Keep backend, Flutter, and dashboard changes logically separable.
5. Do not commit, push, deploy, rotate secrets, create users, charge customers, or modify production data unless the owner explicitly authorizes that action.
6. Never put service-role keys, database passwords, signing private keys, payment secrets, webhook secrets, R2 credentials, OTPs, or session tokens in source, logs, screenshots, prompts, or `VITE_*`/Flutter defines.
7. The Supabase publishable/anon key may be embedded in clients, but authorization must still be enforced by RLS and Edge Functions.
8. Use UTC for storage and metric boundaries. Display `Asia/Riyadh` explicitly in the dashboard.
9. Do not collect IPTV credentials, provider URLs, playlists, stream URLs, content titles, search text, full IP addresses, or customer email in analytics properties.
10. No payment form or checkout WebView is permitted inside Android or Windows. Open external hosted checkout/customer-portal URLs in the system browser.

### 1.3 Required status report after every phase

Report:

- Files changed in each repository.
- Database/API contract changes.
- Tests and commands run, with results.
- Production actions performed, if authorized.
- Remaining risks and blockers.
- Gate result: `PASS`, `FAIL`, or `BLOCKED`.

Do not begin the next phase when the current gate is `FAIL`.

---

## 2. Current-state baseline

Treat this as a hypothesis and verify it before editing.

### 2.1 Known deployed backend

The following functions were active at the last inspection:

- `admin-api`
- `analytics-batch`
- `devices`
- `entitlement`
- `health`
- `me`
- `session-heartbeat`
- `trial-activate`
- `version`

The following functions exist locally but were not in the deployed inventory:

- `downloads`
- `download-consume`
- `account-deletion`
- `account-deletion-processor`

Local migrations include:

- `20260829120000_commercial_control_plane.sql`
- `20260829130000_analytics_admin_foundation.sql`
- `20260829140000_release_downloads_phase6.sql`
- `20260829150000_privacy_deletion_phase7.sql`

Verify local and remote migration histories before proposing any deployment.

### 2.2 Known data-quality gaps

- Flutter queues analytics and flushes every 30 seconds.
- Flutter attempts a foreground heartbeat every 120 seconds.
- Analytics starts only for a signed-in HOPE TV account.
- Device-registration/auth timing may start analytics before a device ID is available, preventing heartbeats for that process lifetime.
- `app_first_open` is currently emitted when the analytics client starts; it is not proven to be once per installation.
- Most allowlisted event names have no real Flutter call site.
- Daily aggregation SQL exists, but no scheduled invocation was found.
- The canonical dashboard contains fixed synthetic ratios such as 68/32 platform splits and 38/62 trial/paid splits.
- Dashboard mock data exists and must never be used in production mode.
- The subscription page can read subscriptions but does not control real recurring billing.
- The backend subscription sync route currently returns a deferred placeholder.
- No billing provider is selected; the provider implementation fails closed.
- Directly sending an APK/EXE attachment cannot produce reliable download telemetry.

### 2.3 Measurement Readiness and Signal Quality Index

Initial estimate: **60/100 — Unreliable**.

| Category | Weight | Initial score | Primary reason |
|---|---:|---:|---|
| Decision alignment | 25 | 20 | Core owner decisions are documented |
| Event model clarity | 20 | 15 | Names exist, but several triggers/counting rules are incomplete |
| Data accuracy and integrity | 20 | 9 | First-open semantics, heartbeat timing, aggregation, and synthetic UI values are unresolved |
| Conversion definition quality | 15 | 6 | Billing conversions cannot be authoritative without provider webhooks |
| Attribution and context | 10 | 2 | Controlled download acquisition and source attribution are incomplete |
| Governance and maintenance | 10 | 8 | Plans and allowlists exist, but runtime freshness/quality monitoring is incomplete |
| **Total** | **100** | **60** | **Do not use current charts for commercial decisions** |

Recalculate the score at the end. Production acceptance requires at least **85/100** and no known fabricated or mislabeled metric.

---

## 3. Canonical measurement contract

Implement only signals that support an owner decision.

### 3.1 Tracking plan

| Event | Meaning and counting | Allowed properties | Trigger | Decision supported |
|---|---|---|---|---|
| `app_first_open` | Once per generated installation identity | `platform`, `app_version`, installation hash | First successful backend observation of an installation | Observed installations by platform/version |
| `app_updated` | Once per installation per newly observed version | `platform`, `app_version`, `previous_version` | Stored version differs from current version | Upgrade adoption and minimum-version policy |
| `session_started` | Once per meaningful foreground session | `platform`, `app_version` | Authenticated app enters foreground and has a registered non-revoked device | DAU/WAU/MAU |
| `session_heartbeat` | At most once per heartbeat interval | `platform`, `app_version`, `foreground` | Meaningful foreground session remains active | Online accounts/devices |
| `session_ended` | Best-effort, once per session | `platform`, `app_version` | App backgrounds, signs out, or closes when observable | Session quality only; never required for active-user truth |
| `account_created` | Once per Supabase account | `platform` | Auth account/profile provisioned | Registration funnel |
| `account_signed_in` | Once per successful sign-in session | `platform`, `method` from allowlist | Auth succeeds | Authentication health |
| `device_registered` | Once per account/device association | `platform`, `app_version` | Server accepts device registration | Device-limit operations |
| `iptv_connection_succeeded` | Once per successful onboarding activation attempt | `platform` | Credentials validated without recording credentials/content | Activated accounts and trial eligibility |
| `trial_started` | Once per account | `platform`, `duration_days` | Server commits immutable trial start | Trial funnel |
| `subscription_page_opened` | Once per page exposure/session | `platform`, `source` from allowlist | External-subscription screen displayed | Subscription intent |
| `entitlement_refreshed` | Once per material refresh result, sampled if necessary | `platform`, `access_status`, `reason_code` | Server entitlement response accepted | Access health |
| `entitlement_denied` | Once per denial transition | `platform`, `reason_code` | Premium access denied | Support and churn risk |
| `playback_started` | Aggregate counter without content identity | `platform`, `media_type` from allowlist | Playback actually begins | Meaningful product usage |
| `playback_failed` | Aggregate counter without URL/title | `platform`, `failure_category` | Playback fails | Reliability investment |
| `download_authorized` | A verified account receives a valid short-lived token | `platform`, `release_id` | Supabase download function issues token | Distribution authorization |
| `release_download_requested` | Gateway accepts a valid token and requests the R2 object | `platform`, `release_id` | Gateway consumes token | Actual accepted requests |
| `completed_transfer` | Only when trustworthy byte-delivery evidence exists | `platform`, `release_id`, `size_bucket` | Gateway/CDN confirms completion | Delivery completion; omit if unprovable |

### 3.2 Conversions

| Conversion | Source of truth | Counting | Used by |
|---|---|---|---|
| Account activated | Server trial activation after IPTV connection succeeds | Once per account | Activation funnel |
| Paid subscription activated | Verified payment-provider webhook | Once per provider subscription activation transition | Trial-to-paid conversion |
| First renewal succeeded | Verified payment-provider webhook | Once per subscription first renewal | Retention |
| Subscription canceled | Verified provider state/webhook | Once per cancellation transition | Churn |

Client events such as checkout clicks are intent signals, not paid conversions.

### 3.3 Metric definitions

- **Observed installation:** distinct generated installation identity first accepted by the backend. Label it “observed installation,” not total installs from all distribution channels.
- **Online account:** distinct authenticated, active account with a meaningful foreground heartbeat in the preceding five minutes.
- **Online device:** distinct non-revoked device with a meaningful foreground heartbeat in the preceding five minutes.
- **DAU:** distinct non-deleted authenticated accounts with a meaningful foreground session on a UTC day.
- **WAEA:** distinct entitled accounts with meaningful activity on at least two separate days in the trailing seven days.
- **Paying subscriber:** account with provider-authoritative paid entitlement valid at query time. Manual complimentary access is not a paying subscriber.
- **Download authorized**, **download requested**, and **completed transfer** are separate metrics and must never be relabeled as each other.

---

## 4. Parallel execution map

After Phase 1 freezes the contract, use three coordinated lanes:

| Lane A — Flutter | Lane B — Backend/gateway | Lane C — Dashboard |
|---|---|---|
| Build configuration | API/event schema | API schemas/types |
| Installation/session lifecycle | Ingestion validation/idempotency | Remove mock/synthetic fallbacks |
| Device/heartbeat timing | Aggregation and freshness | Real empty/error/freshness states |
| Meaningful event call sites | Download authorization/gateway | Real platform/status series |
| Entitlement refresh/enforcement | Billing provider/webhooks later | Manual override/provider controls |

Synchronization gates:

1. No consumer implementation before the event/API contract is frozen.
2. No dashboard metric is enabled before its backend query returns validated real data.
3. No billing control is enabled before provider webhook idempotency tests pass.
4. No release is distributed before Flutter production configuration and entitlement public keys are verified.

---

## 5. Phase 0 — Inventory, safety, and evidence baseline

### Tasks

1. Read both repository instructions and status.
2. Inventory deployed Supabase functions and migration history without printing secrets.
3. Identify every Flutter analytics event call site and compare it with the allowlist.
4. Identify every dashboard field derived from mock data, constants, fixed ratios, or client-side guesses.
5. Confirm dashboard environment variables use:

   ```env
   VITE_SUPABASE_URL=https://otmovtxevvuxbsrmurkb.supabase.co
   VITE_ADMIN_API_URL=https://otmovtxevvuxbsrmurkb.supabase.co/functions/v1/admin-api
   ```

   The Supabase URL must not include `/rest/v1/`.

6. Confirm `PORTAL_ORIGIN` and `CORS_ALLOWLIST` use the exact origin without a trailing slash.
7. Record current raw-data and aggregate-data freshness through the protected `admin-api`; do not retrieve service-role credentials into the agent context.
8. Establish test accounts/devices clearly marked as synthetic operational tests, not production customers.

### Gate 0

- Both worktrees are preserved.
- A written inventory maps every dashboard metric to its backend field/query.
- Every synthetic calculation is listed.
- No secret appears in output.
- Initial readiness score is recorded.

---

## 6. Phase 1 — Freeze shared contracts and production configuration

### Backend lane

1. Create/version a canonical analytics contract in the root backend.
2. Keep event names lowercase `object_action` and explicitly allow properties/types/limits.
3. Define response schemas for overview, activity, downloads, subscriptions, freshness, and user detail.
4. Include `schemaVersion`, `generatedAt`, `dataThrough`, and `timezone` in reports.
5. Define exact platform values: `android`, `windows`, `web`, `unknown`.
6. Decide how release IDs, installation hashes, event IDs, session IDs, and idempotency keys are generated.

### Flutter lane

1. Add a gitignored production define file or documented release command containing only public client configuration:

   - `SUPABASE_URL`
   - Supabase publishable/anon key
   - `ENTITLEMENT_PUBLIC_KEYS_JSON`

2. Never embed the service-role key or entitlement private key.
3. Add startup diagnostics that report configuration presence without printing values.
4. Fail the commercial release build when required public configuration is missing; do not silently ship placeholder mode.

### Dashboard lane

1. Validate `VITE_*` variables at startup using Zod.
2. Fail visibly when configuration is missing or malformed.
3. Remove hardcoded remote defaults from application source. Keep examples in `.env.example` only.
4. Consume the canonical backend schemas. Normalize only shape differences; never invent metric values.

### Gate 1

- Contract tests pass in backend, Flutter, and dashboard.
- A production Flutter build cannot succeed with placeholder commercial configuration.
- Dashboard cannot start in production mode with a malformed Supabase base URL.
- No API consumer relies on unversioned or guessed fields.

---

## 7. Phase 2 — Reliable Flutter installation, session, and activity telemetry

### Tasks

1. Fix device registration and analytics startup ordering:

   - Register/restore the current device first.
   - Pass the confirmed device ID into analytics.
   - If registration completes after analytics starts, explicitly update the analytics client and send the first heartbeat.
   - Do not let the `_started` guard permanently preserve a null device ID.

2. Implement durable one-time markers:

   - Installation first observed.
   - Last reported app version.
   - Current session identity.

3. Ensure `app_first_open` is once per installation, not once per process.
4. Emit `app_updated` once per newly observed version.
5. Define a meaningful foreground session and prevent background-only processes from creating DAU.
6. Start/stop/refresh heartbeat behavior across foreground, background, sign-in, sign-out, network loss, and device revocation.
7. Wire only meaningful event call sites from the tracking plan.
8. Ensure the queue is bounded, disk-safe, idempotent, and retries with backoff/jitter.
9. Preserve event IDs across retries so server upsert removes duplicates.
10. Add privacy tests proving forbidden keys and URL-like values are stripped/rejected.
11. Do not block playback or navigation while telemetry is offline.

### Required Flutter tests

- First launch emits one observed-installation event.
- Second launch does not emit another first-open event.
- Upgrade emits one version-change event.
- Sign-in registers device before heartbeat.
- Returning signed-in user with no cached device recovers and starts heartbeat.
- Background app does not create meaningful activity.
- Repeated retry does not change event ID.
- Queue limit and flush batching work.
- Android and Windows report correct platform values.
- Forbidden IPTV/PII properties never leave the client.

### Gate 2

- Android and Windows test builds generate real, deduplicated events.
- Online state appears within five minutes and expires after heartbeats stop.
- No content/provider secrets are present in captured request bodies.

---

## 8. Phase 3 — Harden ingestion, sessions, and data-quality monitoring

### Tasks

1. Keep all authoritative timestamps server-controlled where business state is affected.
2. Validate event ID, name, schema version, timestamp skew, platform, app version, property count, property size, and allowed property types.
3. Enforce unique event IDs and safe idempotent upserts.
4. Reject unknown events and forbidden properties; return accepted/rejected counts.
5. Define authentication policy explicitly:

   - MVP decision: dashboard customer/activity metrics use authenticated events.
   - Do not disable JWT verification merely to increase first-open counts.
   - If pre-auth installation telemetry is later required, design a separate abuse-resistant public endpoint and label the metric accordingly.

6. Ensure a device belongs to the authenticated user and is non-revoked before heartbeat acceptance.
7. Close or expire stale sessions by query semantics even when no `session_ended` event arrives.
8. Add health fields for last raw event, last heartbeat, rejection rate, duplicate rate, and clock-skew rejection rate.
9. Add retention/deletion behavior consistent with account deletion and privacy requirements.

### Gate 3

- Invalid, oversized, duplicate, cross-account, revoked-device, and stale/future events are tested.
- Ingestion failure never grants entitlement.
- Health API clearly distinguishes “no users” from “analytics pipeline stale.”

---

## 9. Phase 4 — Server-side aggregation and freshness

### Tasks

1. Review `analytics.aggregate_daily_metrics(date)` for the canonical metric definitions.
2. Add an idempotent scheduled aggregation mechanism using supported Supabase scheduling.
3. Recompute the current UTC day frequently enough for the dashboard freshness target; finalize the previous day after the boundary.
4. Never make the dashboard browser invoke privileged aggregation.
5. Produce real platform/status/plan dimensions in SQL instead of estimating splits in TypeScript.
6. Add aggregate reconciliation tests against raw-event fixtures.
7. Return freshness timestamps and visibly mark stale data.
8. Provide a safe owner-triggered recomputation endpoint only if operationally necessary; require owner role, MFA, bounds, idempotency, rate limits, and audit.

### Gate 4

- Re-running aggregation produces identical results.
- Raw distinct-account fixtures match DAU/WAU/MAU/WAEA outputs.
- Platform totals equal their all-platform total under documented rules.
- Dashboard data becomes current without manual SQL.

---

## 10. Phase 5 — Controlled APK/EXE distribution and download telemetry

Direct file attachments are unobservable. After this phase, distribute releases only through controlled links when download measurement is required.

### Backend/gateway tasks

1. Review and test migration `20260829140000_release_downloads_phase6.sql`.
2. Deploy only after dry-run/review and explicit owner approval.
3. Configure private R2 storage and the isolated Cloudflare download gateway.
4. Configure `DOWNLOAD_GATEWAY_BASE_URL`, gateway service authentication, and download-token signing without exposing secrets.
5. Deploy `downloads` and `download-consume` from the root backend only.
6. Require authenticated entitlement/release authorization before issuing a short-lived, single-use token.
7. Store only token hashes, never reusable plaintext tokens.
8. Enforce expiration, maximum uses, release status, platform, and revocation.
9. Record separately:

   - authorization issued;
   - valid gateway request accepted;
   - transfer completion only if technically provable.

10. Support HTTP range requests safely without double-counting a transfer.
11. Never expose R2 credentials or permanent object URLs.

### Dashboard tasks

1. Display the three download stages separately.
2. Show `—`/“not measured” for completed transfer when proof is unavailable; never estimate it.
3. Show release/platform/version breakdowns only from backend dimensions.
4. Remove fabricated risk, region, completion, and installation values.

### Gate 5

- Expired, replayed, revoked, wrong-platform, and tampered tokens fail.
- A valid test link records one accepted request.
- Direct R2 access remains private.
- Dashboard wording matches the evidence actually collected.

---

## 11. Phase 6 — Make `hope-tv-insights` real-data-only

### Mandatory removals

1. Remove production imports/usages of `src/lib/mock-data.ts`.
2. Remove fixed 68/32 Android/Windows splits.
3. Remove fixed 38/62 trial/paid splits.
4. Remove subscriber plan estimates, generated funnel stages, fabricated retention, fabricated release statistics, and hardcoded freshness dates.
5. Do not replace missing fields with plausible numbers.

### Dashboard tasks

1. Map every KPI/chart/table to a protected `admin-api` response.
2. Use server-returned platform, entitlement status, subscription status, plan, and date dimensions.
3. Render honest states:

   - Loading.
   - No records yet.
   - Metric not implemented.
   - Data stale.
   - Permission denied.
   - Backend error with correlation ID.

4. Keep all privileged reads and mutations behind `admin-api`; never query private tables directly from the browser.
5. Validate responses with Zod and reject incompatible schema versions.
6. Use TanStack Query keys containing date range/platform filters.
7. Invalidate exact queries after mutations.
8. Test the production origin and CORS preflight.
9. Preserve Cloudflare/Lovable history and deploy configuration.

### Gate 6

- Searching for mock imports and fixed metric ratios finds no production path.
- With an empty database, every page shows an honest empty state with zero fabricated values.
- With seeded integration fixtures, every displayed value reconciles with backend output.
- `npm run lint` and `npm run build` pass.

---

## 12. Phase 7 — Manual access management before recurring billing

This phase enables owner-controlled access, not automatic paid subscriptions.

### Backend tasks

1. Keep subscription rows provider-authoritative; never add a generic dashboard endpoint that directly sets `subscriptions.status`.
2. Use the existing time-bounded entitlement override API for manual/complimentary access.
3. Require:

   - authenticated active owner;
   - required capability;
   - MFA/AAL2;
   - explicit expiration;
   - reason;
   - idempotency key;
   - rate limit;
   - append-only audit record.

4. Prevent overlapping/conflicting active overrides or define deterministic precedence.
5. Limit manual presets to owner-approved values such as 30 days and 365 days while still storing an exact UTC expiration.

### Dashboard tasks

1. Add controls on user detail, not a global unauthenticated form:

   - Grant 30-day access.
   - Grant 365-day access.
   - Choose custom expiration within allowed bounds.
   - Revoke an active override.

2. Label this access “Manual access” or “Complimentary override,” never “paid subscriber.”
3. Require confirmation and reason entry.
4. Show MFA requirement and guide the owner through AAL2.
5. Refresh user entitlement/audit data after success.

### Flutter tasks

1. Refresh entitlement at sign-in, app foreground, after trial activation, after returning from an external subscription page, and at a bounded periodic interval.
2. Enforce server result and signed offline lease.
3. Do not trust local clock or dashboard-generated data.

### Gate 7

- Owner can grant/revoke time-bounded access with MFA.
- Non-owner, no-MFA, expired-token, repeated-idempotency, and invalid-expiration tests fail safely.
- The app observes the access change on entitlement refresh.
- Audit log records actor, target, reason, timestamps, and before/after state without secrets.

---

## 13. Phase 8 — External monthly/yearly recurring billing

### Hard blocker gate

Stop and request owner decisions before implementation if any are unresolved:

- Merchant country/legal entity.
- Hosted recurring-payment provider.
- Monthly and yearly price/currency.
- Tax handling.
- Refund/cancellation policy.
- Customer portal/support URLs.

Do not invent a provider or use live credentials in a sandbox.

### Required architecture

```text
Customer app or website
  -> opens external hosted checkout in system browser
  -> provider processes payment
  -> signed provider webhook reaches Supabase
  -> idempotent webhook transaction updates billing/subscription state
  -> entitlement function evaluates provider-authoritative state
  -> Flutter refreshes access
  -> dashboard reads state through admin-api
```

### Backend tasks

1. Implement the approved provider behind the existing `BillingProvider` interface.
2. Add authenticated checkout-session creation using server-selected plan/price IDs.
3. Add authenticated customer-portal session creation.
4. Add a provider webhook with raw-body signature verification.
5. Persist provider event ID before processing and guarantee idempotency.
6. Handle duplicate and out-of-order events using provider timestamps/version rules.
7. Upsert billing-customer mappings and subscription state transactionally.
8. Define active, grace, past-due, canceled, expired, refunded, and disputed access behavior.
9. Implement provider resynchronization as a real queued/controlled operation.
10. Keep API keys and webhook secrets only in Supabase secrets.
11. Use provider sandbox first. Live mode requires a separate explicit approval.

### Flutter tasks

1. Display monthly/yearly plans from signed/server-controlled configuration.
2. Open checkout/customer portal externally; no WebView and no in-app purchase SDK.
3. Treat checkout return as “refresh status,” not proof of payment.
4. Never unlock access from a success URL or client event.

### Dashboard tasks

1. Display provider-authoritative subscription status and plan.
2. Provide “Open in provider,” “Request sync,” and audit history.
3. Keep cancellation/refund/payment-method operations in the hosted provider portal initially.
4. Do not expose raw webhook payloads or provider secrets.
5. Clearly distinguish manual override from paid entitlement.

### Gate 8

- Valid sandbox checkout activates access only after a verified webhook.
- Duplicate and out-of-order webhook tests pass.
- Invalid signatures never change access.
- Cancellation, failure/grace, renewal, refund, and dispute fixtures produce the approved entitlement result.
- No browser or Flutter bundle contains privileged billing material.

---

## 14. Phase 9 — End-to-end validation, readiness score, and rollout

### Automated verification

Run relevant commands and add missing tests rather than relying only on manual UI review.

Root Flutter/backend:

```powershell
dart format <changed-dart-files>
flutter analyze
flutter test
deno test --allow-env supabase/functions/_shared
supabase db push --linked --dry-run
supabase migration list --linked
```

Dashboard:

```powershell
cd hope-tv-insights
npm run lint
npm run build
```

Download gateway:

```powershell
cd services/download_gateway
npm test
```

Do not deploy merely because local tests pass. Review remote migration/function diffs and request approval for production mutations.

### Required end-to-end journeys

1. New Android installation -> account -> device -> IPTV success -> trial -> heartbeat -> dashboard.
2. New Windows installation -> same flow with correct platform dimension.
3. Returning signed-in user with missing device cache recovers heartbeat.
4. Background/offline/reconnect does not inflate DAU or duplicate events.
5. Controlled release link -> token -> accepted request -> dashboard download metric.
6. Manual 30-day override -> entitlement refresh -> access -> audited revoke.
7. Billing sandbox monthly checkout -> webhook -> paid entitlement -> dashboard.
8. Billing sandbox yearly renewal/failure/cancellation -> correct state transitions.
9. Unauthorized dashboard user receives no privileged data.
10. Owner mutation without MFA is rejected.

### Recalculate readiness

Re-score all six Measurement Readiness categories with evidence. Release is blocked below 85/100 or when any dashboard metric is synthetic/mislabeled.

### Rollout order

1. Database migration review/dry run.
2. Backend functions and scheduled aggregation.
3. Download gateway.
4. Test Android/Windows builds.
5. Canonical dashboard.
6. Small internal cohort.
7. Monitor rejection rate, freshness, heartbeat health, entitlement denials, and webhook failures.
8. Broader distribution only after the observation window passes.

### Rollback principles

- Prefer additive migrations and backward-compatible contracts.
- Keep prior client schema versions accepted during rollout.
- Disable a bad feature through server configuration instead of destructive data edits.
- Never roll back by deleting customer, subscription, webhook, audit, or analytics authority records.

---

## 15. Final definition of done

The work is complete only when all statements are true:

- Android and Windows releases contain valid public Supabase configuration and entitlement verification keys.
- Unique observed installations are not inflated by relaunches.
- Authenticated, registered devices generate reliable foreground heartbeats.
- Raw events are validated, private, idempotent, and free of prohibited IPTV/PII fields.
- Aggregates refresh automatically and reconcile with raw fixtures.
- Download metrics originate from controlled distribution, not guessed attachment counts.
- `hope-tv-insights` contains no production mock data or fixed metric ratios.
- Every dashboard metric has an exact server-side definition and freshness timestamp.
- Manual access is clearly separated from paid subscriptions and is MFA/audit protected.
- Paid state is changed only by verified provider state/webhooks.
- Checkout and customer portal are external to the app.
- Duplicate/out-of-order webhooks cannot duplicate or incorrectly extend access.
- RLS and admin authorization prevent cross-account and non-admin access.
- Both repositories build and test successfully.
- Measurement Readiness is at least 85/100 with cited evidence.

---

## 16. Final agent handoff format

Return a final report containing:

1. Executive outcome.
2. Phase-by-phase gate results.
3. Exact files changed in the root repository.
4. Exact files changed in `hope-tv-insights`.
5. Migrations/functions created or deployed.
6. Test matrix and results.
7. Measurement Readiness score before and after.
8. Known data limitations and metric labels.
9. Security/privacy review.
10. Production configuration still required from the owner.
11. Safe next action.

Never claim completion when billing-provider selection, production secrets, deployment approval, or an acceptance gate remains unresolved.
