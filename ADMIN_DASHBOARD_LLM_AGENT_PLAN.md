# HOPE TV Owner Dashboard — Detailed LLM Agent Implementation Instructions

**Project:** HOPE TV direct-distribution IPTV player  
**Repository:** `D:\PROJECTS\iptv`  
**Related master plan:** `MASTER_SUBSCRIPTION_ANALYTICS_AGENT_PLAN.md`  
**Dashboard purpose:** A small private web dashboard operated by the product owner to monitor customers, trials, subscriptions, downloads, installations, active users, releases, and audited support actions.  
**Chosen frontend:** React + TypeScript + Vite + ordinary CSS/CSS Modules  
**Hosting:** Cloudflare Pages  
**Backend:** Supabase Auth + PostgreSQL + Edge Functions  
**Release storage:** Private Cloudflare R2 through the separate protected download gateway  
**Document audience:** LLM coding agents implementing the owner dashboard and its protected administrative API.

---

## 1. Objective

Create a focused private dashboard that allows the owner to:

1. See how many Android APK and Windows installer downloads were requested.
2. Distinguish download requests, completed transfers, installations, registered accounts, activated accounts, active users, online users, trial users, and paying users.
3. View daily, weekly, and monthly activity.
4. Understand the funnel from download to paid subscription.
5. Search for a customer and inspect their account, devices, trial, entitlement, and subscription.
6. Perform a small set of safe, audited support actions.
7. View monthly versus yearly plans and subscription lifecycle states.
8. See failed payments, cancellations, grace periods, expirations, refunds, and disputes.
9. Manage dynamic public configuration through a reviewed publish flow.
10. View releases and download statistics without exposing private R2 objects.
11. Review a tamper-resistant audit trail of owner and system actions.
12. Monitor backend health and data freshness.

This dashboard is not a general-purpose CRM, accounting system, payment terminal, or IPTV content-management system.

---

## 2. Authoritative Architecture

```text
Owner browser
    |
    v
Cloudflare Pages
React + TypeScript dashboard
    |
    +-- Supabase Auth login + MFA
    |
    v
Supabase Edge Function: admin-api
    |
    +-- Verify Supabase JWT
    +-- Require approved admin role
    +-- Require AAL2/MFA for mutations
    +-- Validate request schema
    +-- Apply rate limit
    +-- Execute protected PostgreSQL functions/queries
    +-- Append audit record for mutations
    |
    v
Supabase PostgreSQL
    +-- Accounts and devices
    +-- Trials and entitlements
    +-- Subscriptions and webhook state
    +-- Download/release metadata
    +-- Active sessions and analytics
    +-- Remote configuration
    +-- Audit logs

Private Cloudflare R2
    ^
    |
Cloudflare download gateway
    +-- Dashboard sees metadata only
    +-- Dashboard never receives R2 credentials
```

### Hard separation rules

- The dashboard browser never receives the Supabase service-role key.
- The dashboard browser never receives payment-provider secret keys.
- The dashboard browser never receives R2 access credentials.
- The dashboard browser never queries service-only tables directly.
- Administrative business operations go through the authenticated `admin-api` Edge Function.
- The existing IPTV reverse proxy remains separate and receives no dashboard or billing secrets.
- IPTV provider credentials, server URLs, playlists, stream URLs, and content titles must never appear in the dashboard.

---

## 3. Why TypeScript, React, JavaScript, and CSS

Use TypeScript rather than untyped JavaScript because this dashboard handles subscription and entitlement state where silent shape errors are dangerous.

Use React because the dashboard requires:

- Authenticated routing.
- Shared date and platform filters.
- Tables with loading, error, empty, and pagination states.
- Charts.
- Confirmed administrative actions.
- Cache invalidation after mutations.
- Reusable status badges and detail panels.

Use Vite for a small static frontend deployable to Cloudflare Pages.

Use ordinary CSS with CSS Modules or a small structured CSS layer. Do not introduce Tailwind or a large component framework unless the owner explicitly requests it. The dashboard should remain understandable to an LLM and maintainable without generated class noise.

### Approved initial frontend dependencies

Keep dependencies small and pin versions through the lockfile:

```text
react
react-dom
react-router-dom
@supabase/supabase-js
@tanstack/react-query
zod
recharts
date-fns
```

Testing/development:

```text
typescript
vite
vitest
@testing-library/react
@testing-library/user-event
playwright
eslint
```

Do not add Redux. TanStack Query owns remote server state; local component state and a small auth context are sufficient.

---

## 4. Repository Layout

Create a separate dashboard application rather than mixing owner-only code into the public customer portal:

```text
admin-dashboard/
  package.json
  package-lock.json
  tsconfig.json
  tsconfig.app.json
  vite.config.ts
  eslint.config.js
  index.html
  public/
    favicon.svg
  src/
    main.tsx
    app/
      App.tsx
      routes.tsx
      queryClient.ts
    auth/
      AuthProvider.tsx
      AdminGuard.tsx
      RequireMfa.tsx
      authApi.ts
      authTypes.ts
    api/
      adminClient.ts
      contracts.ts
      schemas.ts
      queryKeys.ts
    components/
      AppShell.tsx
      Sidebar.tsx
      TopBar.tsx
      DateRangePicker.tsx
      PlatformFilter.tsx
      MetricCard.tsx
      StatusBadge.tsx
      DataTable.tsx
      EmptyState.tsx
      ErrorState.tsx
      LoadingSkeleton.tsx
      ConfirmDialog.tsx
      ReasonDialog.tsx
      Pagination.tsx
      FreshnessIndicator.tsx
    charts/
      TimeSeriesChart.tsx
      FunnelChart.tsx
      BreakdownChart.tsx
      RetentionTable.tsx
    pages/
      LoginPage.tsx
      MfaPage.tsx
      OverviewPage.tsx
      UsersPage.tsx
      UserDetailPage.tsx
      SubscriptionsPage.tsx
      DownloadsPage.tsx
      ActivityPage.tsx
      PlansConfigPage.tsx
      ReleasesPage.tsx
      AuditLogPage.tsx
      SystemHealthPage.tsx
      NotFoundPage.tsx
    styles/
      tokens.css
      global.css
      layout.module.css
      components.module.css
      utilities.css
    test/
      fixtures.ts
      server.ts
      setup.ts
  e2e/
    auth.spec.ts
    overview.spec.ts
    users.spec.ts
    subscriptions.spec.ts
    config.spec.ts
  .env.example
  README.md
```

Backend additions:

```text
supabase/
  migrations/
    <timestamp>_admin_roles.sql
    <timestamp>_admin_reporting.sql
    <timestamp>_admin_audit.sql
  functions/
    _shared/
      admin_auth.ts
      admin_errors.ts
      admin_validation.ts
      audit.ts
      pagination.ts
    admin-api/
      index.ts
      routes/
        overview.ts
        users.ts
        subscriptions.ts
        downloads.ts
        activity.ts
        plans.ts
        releases.ts
        audit.ts
        health.ts
      test/
```

Do not create this structure until the master plan's Supabase foundation and migrations exist, or implement it in a feature branch that explicitly mocks missing contracts.

---

## 5. Authentication and Authorization

### 5.1 Owner login

Use Supabase Auth. The initial login method should be email OTP or magic link. The owner account must also enroll in TOTP MFA before production administrative access is enabled.

Authentication states:

```text
No Supabase session
  -> Login page

Authenticated but not in admin role table
  -> Access denied; sign out option

Authenticated admin without required MFA assurance
  -> MFA challenge page

Authenticated admin with valid role and MFA
  -> Dashboard
```

### 5.2 Admin roles

Create a service-only table such as `private.admin_users`:

```text
private.admin_users
  user_id uuid primary key references auth.users(id)
  role text check in ('owner', 'analyst', 'support', 'release_manager')
  status text check in ('active', 'disabled')
  created_at timestamptz
  created_by uuid
  last_reviewed_at timestamptz
```

Initial capabilities:

| Capability | Owner | Analyst | Support | Release manager |
|---|---:|---:|---:|---:|
| View overview metrics | Yes | Yes | Yes | Yes |
| View users/subscriptions | Yes | Yes | Yes | Limited |
| View download/activity analytics | Yes | Yes | Yes | Yes |
| Revoke customer device | Yes | No | Yes | No |
| Suspend/reactivate account | Yes | No | No | No |
| Grant/revoke entitlement override | Yes | No | No | No |
| Request billing-provider sync | Yes | No | Yes | No |
| Publish dynamic configuration | Yes | No | No | No |
| Publish/revoke release metadata | Yes | No | No | Yes |
| View audit log | Yes | Read-only | Limited | Limited |
| Manage admins | Yes | No | No | No |

For the first release, only create the owner role if one person operates the dashboard. Keep the role model so later staff access does not require redesign.

### 5.3 Edge Function enforcement

Every `admin-api` request must:

1. Require `Authorization: Bearer <Supabase access token>`.
2. Verify the JWT with Supabase's supported server mechanism.
3. Resolve the user ID from verified claims, never a request body.
4. Query the private admin role through a service-side PostgreSQL function.
5. Check account is active.
6. Require the necessary role/capability.
7. Require the appropriate MFA assurance level for mutations.
8. Apply route-specific rate limits.
9. Validate body, query, and path parameters using explicit schemas.
10. Execute the operation.
11. Append an audit record for every mutation and sensitive export.

Frontend guards improve UX but are not security boundaries. The Edge Function must independently enforce every permission.

### 5.4 Optional defense in depth

For production, place the Cloudflare Pages admin hostname behind Cloudflare Access in addition to Supabase authentication. Do not treat Cloudflare Access alone as authorization for business actions.

---

## 6. Dashboard Information Architecture

Use a desktop-first application shell:

```text
Sidebar
  Overview
  Users
  Subscriptions
  Downloads
  Activity
  Plans & Config
  Releases
  Audit Log
  System Health

Top bar
  Date range
  Platform filter
  Data freshness
  Owner identity
  Sign out
```

The top-level date range and platform filter apply to analytics pages but not to individual user details or configuration.

Default timezone for display: `Asia/Riyadh`. Store and query authoritative timestamps as UTC. Display the timezone visibly in date filters and exports.

---

## 7. Overview Page

The overview should answer, within ten seconds:

- How many people are using the app?
- How many are online now?
- How many trials and paying subscribers exist?
- Are subscriptions growing or declining?
- Are downloads becoming installations and paid customers?
- Is data current and are services healthy?

### 7.1 KPI cards

Show current value, comparison-period value, absolute change, percentage change where meaningful, and an exact tooltip definition.

Required cards:

- Download requests.
- New installations.
- Registered accounts.
- Activated accounts.
- Daily active users.
- Weekly active users.
- Monthly active users.
- Online users now.
- Active trials.
- Paying subscribers.
- Trial-to-paid conversion.
- Subscription cancellations.
- Payment failures.

Do not show revenue until the billing provider and tax/refund definitions are finalized. When introduced, label gross recurring amount separately from net revenue and cash received.

### 7.2 Charts

Required initial charts:

1. **Users over time:** DAU plus new activations.
2. **Subscriber state:** active, trialing, grace, canceling, expired.
3. **Platform split:** Android versus Windows for active users and downloads.
4. **Acquisition funnel:** download requested -> first launch -> account verified -> trial started -> paid subscription.
5. **Plan split:** monthly versus yearly active subscribers.

### 7.3 Alerts panel

Show actionable exceptions only:

- Webhook backlog.
- Elevated failed-payment rate.
- Entitlement denial spike.
- Analytics data stale.
- Download gateway errors.
- No heartbeat data for an unexpected interval.
- Release marked mandatory but missing a valid object/checksum.

Do not build a generic notification center in the first release.

---

## 8. Canonical Metric Definitions

These definitions are mandatory. Do not rename or reinterpret a metric in UI code.

### 8.1 Acquisition

| Metric | Definition |
|---|---|
| Download authorized | A verified account was issued a valid release download authorization |
| Download requested | The download gateway received and accepted a valid download request |
| Completed transfer | The complete artifact transfer is supported by gateway/CDN byte-delivery evidence |
| Installation | A unique generated installation ID was first observed by the commercial backend |
| Registered account | A verified Supabase Auth account with a provisioned profile |
| Activated account | An account that successfully connected an IPTV provider and activated its one-time app trial |

Never label `download authorized` as a download or completed transfer.

### 8.2 Engagement

| Metric | Definition |
|---|---|
| DAU | Distinct non-deleted accounts with at least one meaningful foreground session on a UTC day |
| WAU | Distinct active accounts in the trailing seven days |
| MAU | Distinct active accounts in the trailing 30 days |
| Online users now | Distinct non-revoked accounts with a heartbeat in the preceding five minutes |
| Online devices now | Distinct non-revoked device sessions with a heartbeat in the preceding five minutes |
| Stickiness | DAU divided by MAU, with denominator and date visible |

A heartbeat alone from an idle background process must not create DAU. A meaningful foreground session or approved engagement event is required.

### 8.3 Monetization/access

| Metric | Definition |
|---|---|
| Active trial | Server time is before immutable trial end and account/device are eligible |
| Paying subscriber | Account with a paid entitlement valid at query time |
| Monthly subscriber | Paying subscriber on an enabled monthly plan |
| Yearly subscriber | Paying subscriber on an enabled yearly plan |
| Trial-to-paid conversion | Accounts that started a trial and became paid within the selected attribution window divided by eligible trial starters |
| Churned subscription | Previously paid subscription whose access ended and was not replaced by another active paid entitlement |
| Payment failure | Authenticated provider event indicating a failed recurring payment attempt |

The default trial conversion attribution window is 14 days after trial end. Make the window visible and server-configurable.

### 8.4 North-star metric

Use **Weekly Active Entitled Accounts (WAEA)** as the initial north-star metric:

> Distinct accounts with a valid trial or paid entitlement that had meaningful foreground activity on at least two different days during the trailing seven days.

This prevents a single accidental launch from being treated as sustained value.

---

## 9. Funnel and Retention

### 9.1 Canonical conversion funnel

```text
Download requested
  -> First installation observed
  -> Account verified
  -> IPTV connection succeeded
  -> Trial started
  -> Returned on another day during trial
  -> Checkout started
  -> Paid subscription activated
  -> First renewal succeeded
```

The dashboard must show:

- Unique accounts/installations at each step.
- Conversion from previous step.
- Conversion from first step.
- Median elapsed time between steps.
- Platform breakdown.
- Date and attribution-window definitions.

Do not join unrelated anonymous installations to accounts using invasive fingerprinting. Link only when an installation later authenticates to an account.

### 9.2 Retention

Add weekly cohort retention after the initial overview is stable:

- Cohort by trial-start week.
- Retained if the account has meaningful activity in week N.
- Show W0, W1, W2, W3, W4 initially.
- Provide Android and Windows filters.
- Exclude deleted accounts from identifiable drill-down but preserve anonymous aggregates.

Do not invent external industry benchmarks. Show HOPE TV's historical comparison only.

---

## 10. Users Page

### 10.1 Search and filters

Allow search by:

- Exact normalized email, only for authorized support/owner roles.
- Internal user ID.
- Device ID.
- Payment-provider customer ID through a protected exact lookup.

Filters:

- Account status.
- Access status.
- Trial or paid.
- Monthly or yearly.
- Platform.
- Last active range.
- Created range.

Do not implement broad wildcard email enumeration. Require at least three characters for prefix search, rate limit it, and audit sensitive searches where appropriate.

### 10.2 Table columns

- Masked email.
- Account status.
- Access status.
- Plan.
- Trial/subscription end.
- Active devices versus limit.
- Platform presence.
- Last active.
- Created date.

Use cursor pagination. Default page size 25; allowed sizes 25, 50, and 100.

### 10.3 User detail

Sections:

1. **Account:** ID, masked/full email based on role, status, created date, last login, deletion status.
2. **Entitlement:** source, status, features, valid-until, grace end, last evaluation.
3. **Trial:** start, end, duration snapshot, status, activation platform.
4. **Subscription:** provider, safe customer/subscription IDs, plan, state, current period, cancel-at-period-end, last provider sync.
5. **Devices:** device name, platform, app version, first/last seen, revoked state.
6. **Activity summary:** last seven/30-day meaningful sessions, not IPTV content history.
7. **Support actions:** restricted actions listed below.
8. **Audit history:** actions affecting this account.

### 10.4 Safe support actions

Initial supported actions:

- Revoke a device.
- Suspend an account.
- Reactivate a suspended account.
- Grant a time-bounded complimentary entitlement override.
- Revoke an entitlement override.
- Request authoritative subscription resynchronization from the payment provider.
- Resend an approved account email through a rate-limited backend action.

Every action must require:

- Confirmation dialog.
- Human-readable reason.
- Owner role or the specific permitted support role.
- MFA assurance for high-impact actions.
- Idempotency key.
- Audit record.
- UI refresh from server after success.

Do not allow the dashboard to directly edit raw trial timestamps or subscription status. Do not grant permanent overrides; require an expiration.

---

## 11. Subscriptions Page

### 11.1 Summary

Cards:

- Active paid subscriptions.
- Monthly active.
- Yearly active.
- Canceling at period end.
- Past due.
- In grace period.
- Expired in selected range.
- Payment failures in selected range.

### 11.2 Table

Columns:

- Masked customer.
- Plan.
- Provider state.
- Effective entitlement state.
- Current-period end.
- Cancel-at-period-end.
- Grace end.
- Last payment event.
- Last synchronized.

Filters:

- Plan.
- Provider status.
- Effective access status.
- Renewal-period end range.
- Payment failure presence.
- Platform presence.

### 11.3 State rules

Display provider state and effective entitlement state separately. Example:

```text
Provider: past_due
Effective access: grace_period until 2026-09-03 14:00 Asia/Riyadh
```

Never imply that the dashboard can settle payment. Payment actions remain in the hosted payment provider/customer portal.

### 11.4 Allowed owner actions

- Open the safe provider-dashboard record URL generated server-side from known provider IDs.
- Request a provider sync.
- Suspend app access independently with a reason.
- Grant temporary complimentary access.

Refunds, plan mutations, and cancellations should initially be performed through the payment provider's own dashboard or approved API flow, not by editing PostgreSQL.

---

## 12. Downloads Page

### 12.1 Required metrics

- Download authorizations.
- Accepted download requests.
- Completed transfers when measurable.
- Unique downloading accounts.
- Downloads per account.
- Android versus Windows.
- Release-version distribution.
- Download-to-install conversion.
- Download failures.
- Token expiry/reuse rejection count.

### 12.2 Charts and tables

- Daily download requests by platform.
- Download requests by release version.
- Download-to-install funnel.
- Latest releases with request/completion totals.
- Abnormal repeated-download accounts/IP risk buckets, without exposing full IP addresses by default.

### 12.3 Privacy

- Store only the coarse country/region and a protected risk hash if operationally necessary.
- Do not show raw IP addresses in ordinary dashboard views.
- Do not expose signed R2 URLs after they expire.
- Do not provide direct public R2 object links.

---

## 13. Activity Page

Show engagement, not IPTV content history.

Required views:

- DAU/WAU/MAU time series.
- WAEA north-star trend.
- Online accounts and devices now.
- Active users by Android/Windows.
- App-version distribution.
- New versus returning active accounts.
- Trial engagement versus paying-customer engagement.
- Playback-start and playback-failure aggregate rates without content identifiers.
- Weekly retention cohorts after enough data exists.

The “online now” panel should display its five-minute heartbeat definition and last refresh time. Poll no more frequently than every 30 seconds unless a more efficient realtime design is deliberately approved.

---

## 14. Plans and Configuration Page

### 14.1 Configuration sections

- Trial duration for future trials.
- Default device limit.
- Offline entitlement lease duration within server maximum.
- Failed-payment grace duration.
- Enabled monthly/yearly plans.
- Public display price and currency.
- Provider price mapping status, with secret/provider IDs masked.
- Customer portal URL.
- Support URL/email.
- Analytics kill switch and sampling policy.
- Minimum supported app versions.
- Maintenance mode.

### 14.2 Draft and publish flow

Do not edit live configuration field-by-field.

Use:

1. Load active version.
2. Create editable draft.
3. Validate draft server-side.
4. Show exact diff.
5. Require reason and confirmation.
6. Publish atomically as a new immutable config version.
7. Preserve rollback target.
8. Write audit record.

Changing trial duration affects only future trials. The dashboard must explicitly state this.

The dashboard display price is not the charge authority. Payment amounts come from the server-side approved provider price mapping.

---

## 15. Releases Page

### 15.1 Release list

Columns:

- Platform.
- Architecture.
- Channel.
- Version/build.
- File size.
- SHA-256 verification state.
- Signature verification state.
- Published/revoked state.
- Mandatory flag.
- Download requests.
- Installations observed.
- Published date.

### 15.2 Initial release operations

The first dashboard release should support:

- View metadata.
- Publish already uploaded and cryptographically verified metadata.
- Mark release revoked.
- Change mandatory-update policy through a new signed manifest/config publish.
- View download/install adoption.

Do not build browser-based signing. Android keystores, Windows code-signing private keys, entitlement keys, and release-manifest private keys must never enter the browser.

If direct artifact upload is added later:

1. Edge Function creates a short-lived upload authorization.
2. Browser uploads only to a staging R2 prefix.
3. Backend verifies file size and SHA-256.
4. Offline/CI signing verification runs.
5. Release manager reviews metadata.
6. Owner/release manager publishes.

---

## 16. Audit Log Page

### 16.1 Audit record

Every sensitive action records:

- Audit ID.
- Actor user ID.
- Actor role.
- Action name.
- Target type and ID.
- Reason.
- Sanitized before state.
- Sanitized after state.
- Result: succeeded or failed.
- Request correlation ID.
- Idempotency key.
- UTC timestamp.
- Coarse source metadata suitable for security review.

### 16.2 Audit behavior

- Append-only through protected functions.
- No dashboard delete/edit capability.
- Secrets, tokens, full webhook payloads, and IPTV data prohibited.
- Cursor pagination.
- Filters by actor, action, target, result, and time.
- Export restricted to owner and audited as an export action.

---

## 17. System Health Page

Show operational indicators:

- Supabase Auth availability check.
- PostgreSQL/Edge Function health.
- Payment webhook last received and last successfully processed.
- Webhook backlog count and oldest age.
- Analytics last event and last daily aggregation.
- Heartbeat last received.
- Download gateway health.
- R2 release metadata/object consistency.
- Current app configuration version.
- Current latest Android/Windows release.
- Dashboard build/version.

Do not expose secret environment values, stack traces, database connection strings, or raw provider payloads.

---

## 18. Backend Reporting Design

### 18.1 Do not calculate business metrics in React

React renders metric DTOs. PostgreSQL views/functions or Edge Functions calculate definitions so exports and dashboard cards cannot disagree.

Recommended reporting objects:

```text
analytics.daily_account_activity
analytics.daily_download_metrics
analytics.daily_subscription_metrics
analytics.daily_funnel_metrics
analytics.weekly_retention_metrics
private.admin_overview_v1(...)
private.admin_user_search_v1(...)
private.admin_user_detail_v1(...)
private.admin_subscription_list_v1(...)
private.admin_download_report_v1(...)
private.admin_activity_report_v1(...)
```

Prefer pre-aggregated daily tables for long ranges. Use live transactional queries only for online-now, current subscription state, and individual user details.

### 18.2 Data freshness

Each response includes:

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-08-29T12:00:00Z",
  "dataThrough": "2026-08-29T11:55:00Z",
  "timezone": "UTC",
  "data": {}
}
```

The UI displays `dataThrough` and warns when data exceeds the page-specific staleness threshold.

### 18.3 Date ranges

Support:

- Today.
- Yesterday.
- Last 7 days.
- Last 30 days.
- Last 90 days.
- Custom range up to 365 days.

For longer historical reports, use an explicit export workflow rather than an unbounded browser query.

### 18.4 Pagination

Use opaque cursor pagination for users, subscriptions, downloads, and audit logs. Do not use large offsets on growing tables.

---

## 19. Admin API Contract

Implement one small `admin-api` Edge Function with internal route dispatch. All responses use a consistent JSON envelope and typed error codes.

### 19.1 Read endpoints

```text
GET /admin-api/v1/session
GET /admin-api/v1/overview
GET /admin-api/v1/users
GET /admin-api/v1/users/{userId}
GET /admin-api/v1/subscriptions
GET /admin-api/v1/downloads
GET /admin-api/v1/activity
GET /admin-api/v1/config
GET /admin-api/v1/releases
GET /admin-api/v1/audit
GET /admin-api/v1/health
```

### 19.2 Mutation endpoints

```text
POST /admin-api/v1/users/{userId}/suspend
POST /admin-api/v1/users/{userId}/reactivate
POST /admin-api/v1/devices/{deviceId}/revoke
POST /admin-api/v1/users/{userId}/entitlement-overrides
DELETE /admin-api/v1/entitlement-overrides/{overrideId}
POST /admin-api/v1/subscriptions/{subscriptionId}/sync
POST /admin-api/v1/config/drafts
POST /admin-api/v1/config/drafts/{draftId}/validate
POST /admin-api/v1/config/drafts/{draftId}/publish
POST /admin-api/v1/releases/{releaseId}/publish
POST /admin-api/v1/releases/{releaseId}/revoke
```

### 19.3 Error envelope

```json
{
  "error": {
    "code": "ADMIN_MFA_REQUIRED",
    "message": "Additional authentication is required.",
    "correlationId": "opaque-id"
  }
}
```

Do not return raw database or provider errors.

### 19.4 Mutation requirements

Every mutation request includes:

- Idempotency key header.
- Reason with length limits.
- Expected current version for optimistic concurrency where applicable.
- Typed payload validated by Zod/server schema.

Return the fresh server representation after success.

---

## 20. Frontend API and State Rules

- Use one `adminClient` wrapper for all fetches.
- Attach the current Supabase access token in the authorization header.
- Never print tokens to the console.
- Parse every response using Zod before rendering.
- Use TanStack Query for loading, retry, caching, and invalidation.
- Do not automatically retry mutations.
- Retry safe reads only for transient failures with bounded exponential backoff.
- Cancel obsolete requests when filters change.
- Keep filters in the URL query string so views are shareable after authentication.
- Clear query cache on logout.
- Refetch affected user/subscription/overview queries after a mutation.
- Never use optimistic UI for suspension, entitlement grants, configuration publish, or release publish.

---

## 21. UI and CSS Requirements

### 21.1 Visual direction

Use a restrained operations-console design aligned with HOPE TV but optimized for clarity:

- Dark or neutral background consistent with the app.
- One accent color.
- Semantic success, warning, danger, and neutral colors.
- High-contrast text.
- Compact but readable density.
- No decorative glass effects that reduce table readability.
- No animation required beyond short state transitions.

### 21.2 CSS tokens

Define tokens in `tokens.css`:

```css
:root {
  --color-bg: ...;
  --color-surface: ...;
  --color-surface-raised: ...;
  --color-border: ...;
  --color-text: ...;
  --color-text-muted: ...;
  --color-accent: ...;
  --color-success: ...;
  --color-warning: ...;
  --color-danger: ...;
  --radius-sm: ...;
  --radius-md: ...;
  --space-1: ...;
  --space-2: ...;
  --space-3: ...;
  --space-4: ...;
  --font-sans: ...;
  --font-mono: ...;
}
```

Do not hardcode ad hoc colors across components.

### 21.3 Responsive behavior

- Primary target: desktop widths 1280px and above.
- Functional down to tablet width.
- On narrow screens, sidebar becomes a drawer and wide tables use intentional horizontal scrolling.
- Do not hide critical status columns without providing a detail view.

### 21.4 Accessibility

- Keyboard navigation for all controls.
- Visible focus states.
- Semantic headings and landmarks.
- Table headers associated with cells.
- Dialog focus trap and return focus.
- Charts include textual summaries or accessible tables.
- Color is not the only status indicator.
- Meet WCAG AA contrast for normal text.

---

## 22. Privacy and Data Minimization

The dashboard may show only the data needed for operations.

Prohibited:

- IPTV credentials.
- IPTV server URLs.
- Stream URLs.
- Playlist details.
- Channel/movie/series titles.
- Card numbers or payment methods beyond safe provider summaries.
- Authentication tokens.
- Raw webhook bodies.
- Full IP addresses in ordinary views.
- Secrets or private keys.

Mask emails in list views. Reveal full email only on an authorized user-detail page when operationally necessary.

Do not add session-recording or third-party behavior analytics to the owner dashboard without explicit approval; administrative screens may contain sensitive customer information.

---

## 23. Security Requirements

- Supabase Auth session required.
- Active `private.admin_users` record required.
- MFA/AAL2 required for mutations in production.
- Service-role key server-side only.
- Strict Cloudflare Pages security headers.
- Content Security Policy restricted to dashboard assets, Supabase endpoints, and explicitly approved chart/font assets.
- No `unsafe-eval` in production CSP.
- Frame ancestors denied.
- Referrer policy restrictive.
- HTTPS only.
- Same-origin portal assets where practical.
- Request body and response size limits.
- Search and export rate limits.
- Mutation idempotency.
- Optimistic concurrency for configuration/release publishing.
- Append-only audit log.
- Dependency and secret scanning in CI.
- Source maps private or disabled for production unless protected.
- No production secrets in `.env.example`, Vite variables, Git, build logs, or browser bundles.

Remember: every `VITE_*` value is public in the browser bundle. Only the Supabase URL and anonymous/publishable key belong there.

---

## 24. Testing Requirements

### 24.1 Database and RLS

- Non-admin account cannot access admin reporting objects.
- Analyst cannot execute owner mutations.
- Support cannot grant entitlement overrides.
- Release manager cannot suspend accounts.
- Disabled admin is rejected immediately.
- Customer cannot read another customer's data.
- Browser roles cannot read private billing/audit tables directly.
- Audit records cannot be updated/deleted through dashboard roles.
- Reporting queries return correct boundary values at UTC/Riyadh date changes.

### 24.2 Edge Function tests

- Missing/invalid/expired JWT rejected.
- Non-admin JWT rejected.
- MFA requirement enforced for mutations.
- Capability matrix enforced.
- Invalid filters rejected.
- Excessive date ranges rejected.
- Pagination cursor tampering rejected.
- Mutation without reason rejected.
- Duplicate idempotency key does not repeat action.
- Concurrent config publish detects version conflict.
- Every successful and failed sensitive mutation writes the correct audit status.
- Safe DTOs omit forbidden fields.

### 24.3 Frontend unit/component tests

- Auth and admin guards.
- MFA routing.
- Metric definition tooltips.
- Loading, empty, stale, error, and success states.
- Date/platform filter URL synchronization.
- Zod rejection of malformed server response.
- Permission-aware action visibility.
- Confirmation/reason dialogs.
- Mutation success and failure handling.
- Query invalidation.
- Email masking.
- Accessible table/chart labels.

### 24.4 End-to-end tests

- Owner login -> MFA -> overview.
- Non-admin login -> access denied.
- Search user -> inspect subscription/devices.
- Revoke device with reason -> audit record visible.
- Grant temporary entitlement -> effective status refreshes -> audit visible.
- Config draft -> validation -> diff -> publish -> new version visible.
- Downloads filters -> totals consistent with fixture data.
- Expired session -> redirected to login without leaking cached data.
- Logout clears cached customer data.

### 24.5 Metric fixture tests

Create deterministic fixtures covering:

- Same account with multiple devices.
- Multiple downloads by one account.
- Authorization without requested download.
- Download without completed-transfer evidence.
- Trial converted before end.
- Trial converted after end but inside attribution window.
- Past-due subscription still in grace.
- Canceling subscription still entitled until period end.
- Deleted/anonymized account included only in aggregate where allowed.
- Heartbeat inside and outside five-minute online window.
- Meaningful activity on one versus two days for WAEA.

Expected metric values must be asserted, not snapshot-only.

---

## 25. Performance Requirements

- Initial dashboard shell interactive on a normal broadband connection within a reasonable target agreed during implementation.
- Overview API should use aggregates and avoid scanning raw events for every request.
- Tables use cursor pagination.
- Search uses indexed exact/prefix paths with minimum input length.
- Charts limit point counts through daily/weekly aggregation.
- No request returns unbounded raw analytics.
- Cache safe aggregate reads briefly; never cache sensitive user detail across accounts.
- Online-now refresh interval defaults to 30 seconds.
- Other dashboard queries default to at least 60 seconds stale time unless mutation invalidates them.

Record actual query plans for the heaviest reporting functions before production.

---

## 26. Deployment

### 26.1 Environments

Use separate Supabase and Cloudflare environments:

- Development.
- Staging.
- Production.

Never point a local or preview dashboard build at production by default.

### 26.2 Cloudflare Pages

Suggested temporary project names:

```text
hope-tv-admin-dev.pages.dev
hope-tv-admin-staging.pages.dev
hope-tv-admin.pages.dev
```

Production should later use an owner-controlled custom domain such as `admin.<domain>` and Cloudflare Access.

### 26.3 Public environment variables

Example only:

```text
VITE_APP_ENV=development
VITE_SUPABASE_URL=https://project-ref.supabase.co
VITE_SUPABASE_PUBLISHABLE_KEY=public-key
VITE_ADMIN_API_URL=https://project-ref.supabase.co/functions/v1/admin-api
```

Do not place service-role, billing, R2, SMTP, signing, or webhook secrets in Vite variables.

### 26.4 CI gates

Before deployment:

```text
npm ci
npm run lint
npm run typecheck
npm run test
npm run build
playwright test against staging
Supabase migration tests
Edge Function tests
secret scan
dependency audit review
```

Production deploy requires owner approval after staging verification.

---

## 27. Implementation Phases

### Phase 0: Contract and metric freeze

Tasks:

- Read the master plan completely.
- Verify the existing Supabase schema and event taxonomy.
- Freeze metric definitions in Section 8.
- Confirm admin owner email/user ID through a secure out-of-band process.
- Confirm whether Cloudflare Access is available for staging/production.
- Produce dashboard wireframes and API DTOs.

Gate:

- Metric definitions, role model, mutation list, and DTOs are approved.
- No production secret or user ID is committed.

### Phase 1: Admin database foundation

Tasks:

- Add private admin role table.
- Add capability-check PostgreSQL functions.
- Add append-only audit table/functions.
- Add reporting views/functions and indexes.
- Add deterministic metric fixtures.
- Add RLS and permission tests.

Gate:

- Cross-account and non-admin access tests pass.
- Metric fixture expected values pass.
- Query plans show indexes for user/subscription searches.

### Phase 2: Admin API

Tasks:

- Scaffold `admin-api` Edge Function.
- Implement JWT/admin/MFA/capability middleware.
- Implement consistent DTO/error envelopes.
- Implement overview, users, subscriptions, downloads, activity, config, releases, audit, and health reads.
- Implement rate limiting and correlation IDs.
- Add Edge Function tests.

Gate:

- All read endpoints enforce permissions and return schema-valid safe DTOs.
- Forbidden fields are absent.

### Phase 3: Dashboard shell and overview

Tasks:

- Scaffold Vite React TypeScript app.
- Add Supabase Auth and MFA flow.
- Add AdminGuard and app shell.
- Add design tokens and accessible shared components.
- Add overview cards, charts, filters, freshness, and errors.

Gate:

- Owner can sign in and view correct fixture/staging metrics.
- Non-admin cannot access dashboard.
- Overview definitions match backend fixtures.

### Phase 4: Users and subscriptions

Tasks:

- Implement user search/list/detail.
- Implement subscription list and filters.
- Add device and entitlement detail.
- Add reason/confirmation components.
- Implement device revoke, suspension/reactivation, temporary override, and provider sync.
- Add audit integration.

Gate:

- Capability checks, MFA, idempotency, audit, and cache refresh work for every mutation.
- No raw subscription-state editing exists.

### Phase 5: Downloads and activity

Tasks:

- Implement download metrics and release breakdown.
- Implement DAU/WAU/MAU, WAEA, online-now, platform, version, and retention views.
- Add funnel chart and definitions.
- Add data freshness indicators.

Gate:

- Downloads, installations, accounts, active users, and paying users remain distinct.
- Dashboard totals match database fixture assertions.

### Phase 6: Plans/config and releases

Tasks:

- Implement config draft/validate/diff/publish workflow.
- Implement release metadata/list/publish/revoke workflow.
- Enforce optimistic concurrency.
- Add owner/release-manager permission tests.

Gate:

- Live configuration never changes without confirmed immutable version publish.
- Private signing keys never enter browser/backend dashboard paths.

### Phase 7: Audit, health, hardening, deployment

Tasks:

- Implement audit and health pages.
- Add CSP and security headers.
- Add Cloudflare Access if approved.
- Complete Playwright suite.
- Run accessibility audit.
- Run secret/dependency scans.
- Deploy staging, then production after owner approval.

Gate:

- No high-severity unresolved security/accessibility issue.
- Staging E2E tests pass.
- Production rollback procedure documented.

---

## 28. LLM Agent Execution Rules

The implementing LLM agent must:

1. Read this document and `MASTER_SUBSCRIPTION_ANALYTICS_AGENT_PLAN.md` completely before editing.
2. Inspect the actual Supabase migrations, Edge Functions, event schemas, and portal code; never assume they already exist.
3. Inspect `AGENTS.md` if present and obey applicable repository instructions.
4. Preserve unrelated user changes in a dirty worktree.
5. State the active implementation phase and gate before changing code.
6. Implement one reviewable phase or coherent vertical slice at a time.
7. Never invent production domains, owner IDs, provider IDs, prices, secrets, or signing values.
8. Never put Supabase service-role credentials in frontend code.
9. Never expose private schemas directly to the browser.
10. Never use frontend role checks as the authorization boundary.
11. Never edit subscription/trial authority directly from React.
12. Use typed DTOs plus runtime Zod validation.
13. Add tests for permission failure paths, not only successful owner paths.
14. Add deterministic metric fixtures and expected-value assertions.
15. Add a migration for every database change.
16. Update API contracts and dashboard documentation with behavior changes.
17. Run lint, typecheck, tests, build, database/RLS tests, and relevant E2E tests before handoff.
18. Report exact commands and results.
19. Report security-sensitive decisions and remaining risks.
20. Stop for owner input if a requested action would broaden financial authority, expose sensitive data, or weaken the master plan.

---

## 29. Definition of Done

The owner dashboard is complete when:

- Only an active approved admin can enter.
- MFA is enforced for production mutations.
- The browser contains no service-role, billing, R2, webhook, or signing secret.
- All admin permissions are enforced server-side.
- The overview clearly distinguishes every canonical metric.
- DAU, WAU, MAU, online users, WAEA, trial users, and paying users match deterministic fixtures.
- Download authorization, request, completed transfer, installation, and activation are distinct.
- Acquisition funnel and retention definitions are visible and consistent.
- Owner can search users and inspect safe account/device/trial/subscription details.
- Owner can revoke devices, suspend/reactivate accounts, grant/revoke time-bounded overrides, and request provider sync through audited operations.
- No direct raw subscription or trial timestamp editing exists.
- Plans/config use draft, validate, diff, publish, and rollback-ready immutable versions.
- Releases can be viewed and safely published/revoked without exposing signing keys.
- Every mutation requires confirmation, reason, idempotency, authorization, and audit.
- Audit records are append-only and omit secrets/IPTV data.
- Health and freshness are visible.
- Tables are paginated and indexed.
- Charts have accessible textual equivalents.
- Logout clears cached sensitive data.
- Database/RLS, Edge Function, component, and E2E tests pass.
- Production build, CSP, secret scan, dependency review, accessibility review, and staging verification pass.

---

## 30. Recommended First Agent Task

The first dashboard task is **Phase 0 and the read-only portion of Phase 1**:

1. Inspect the actual master-plan implementation state.
2. Confirm which Supabase tables/events already exist.
3. Write versioned TypeScript DTO schemas for overview/users/subscriptions/downloads/activity.
4. Create deterministic SQL fixture scenarios and expected metric values.
5. Create the private admin role/audit/reporting migration with deny-by-default access.
6. Add RLS and permission tests.
7. Do not create owner mutations or deploy the dashboard until read-only authorization and metrics pass their gate.

This order prevents the UI from defining business metrics independently and prevents administrative mutation capability from appearing before server-side authorization is proven.
