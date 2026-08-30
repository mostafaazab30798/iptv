# HOPE TV privacy and account lifecycle (Phase 7)

## Customer-facing surfaces

| Surface | Capability |
|---|---|
| Flutter app (Account screen) | Request deletion, view pending status, cancel during grace period |
| Customer portal (Phase 4+) | Same deletion API via `account-deletion` Edge Function |
| IPTV credentials | Remain in local secure storage until user disconnects in Settings |

## Deletion workflow

```mermaid
sequenceDiagram
  participant User
  participant App
  participant EF as account-deletion
  participant DB as PostgreSQL
  participant Proc as account-deletion-processor
  participant Auth as Supabase Auth

  User->>App: Confirm DELETE_MY_ACCOUNT
  App->>EF: POST action=request
  EF->>DB: deletion_pending + request row
  EF->>Auth: signOut global
  EF-->>App: scheduledFor + graceDays
  Note over Proc: After grace period (cron)
  Proc->>DB: finalize_account_deletion_v1
  Proc->>Auth: deleteUser
```

## Legal and policy artifacts (owner-authored)

Before production launch, publish:

- Privacy policy
- Terms of service
- Subscription, renewal, cancellation, and refund terms
- Acceptable-use policy
- Copyright/takedown policy
- Support contact and process

This repository documents **technical** retention and deletion behavior only. Legal text is not generated here.

## Processor integrations

When billing is configured, the deletion request path should:

1. Direct users to cancel renewal via the approved customer portal flow, or
2. Require `acknowledgeSubscriptionLoss: true` if an active subscription remains.

Processor deletion requests (payment provider, email vendor) are manual or scripted follow-ups documented in the operations runbook.

## Audit trail

Deletion events append to `private.audit_logs` with actions:

- `account.deletion.requested`
- `account.deletion.canceled`
- `account.deletion.completed` (non-identifying hash prefix only)
