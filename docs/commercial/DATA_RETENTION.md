# HOPE TV data retention schedule (Phase 7)

This document defines default retention for the commercial control plane. Values are stored in `private.data_retention_policies` and enforced by `analytics.purge_expired_raw_data_v1()`.

| Policy key | Default retention | Data covered | Notes |
|---|---:|---|---|
| `analytics_raw_events` | 90 days | `analytics.analytics_events` | User linkage anonymized on account deletion |
| `app_sessions` | 30 days | `analytics.app_sessions` | Online presence heartbeats |
| `download_events` | 365 days | `analytics.download_events` | Funnel metrics; user_id nulled on deletion |
| `audit_logs` | 7 years | `private.audit_logs` | Append-only; non-identifying deletion records |
| `webhook_events` | 2 years | `private.webhook_events` | Billing reconciliation |
| `financial_records` | 7 years | `subscriptions`, `private.billing_customers` | Provider IDs redacted on deletion; rows retained |

## Account deletion

1. User requests deletion via `account-deletion` Edge Function with confirmation phrase `DELETE_MY_ACCOUNT`.
2. Profile moves to `deletion_pending`; devices and sessions are revoked immediately.
3. After `DELETION_GRACE_DAYS` (default 14), `account-deletion-processor` finalizes deletion:
   - Anonymizes analytics and download events
   - Redacts profile email and billing customer linkage
   - Deletes the Supabase Auth user
   - Appends a non-identifying audit record

## Scheduled jobs

Configure Supabase cron or an external scheduler to call:

```http
POST /functions/v1/account-deletion-processor
X-Cron-Secret: <CRON_SECRET>
```

Recommended schedule: daily at 03:00 UTC.

## Owner changes

Update retention days only through a reviewed migration or audited admin procedure. Do not edit production rows ad hoc without recording the change.
