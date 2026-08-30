# HOPE TV operations runbook (Phase 7)

Operational procedures for backups, restoration, alerts, and account lifecycle. Production values (domains, project IDs, alert destinations) are owner-controlled placeholders until launch.

## 1. Backups

### Supabase PostgreSQL

- **Requirement:** Paid Supabase plan with daily automated backups before accepting paying customers.
- **Evaluate:** Point-in-time recovery (PITR) against the recovery point objective (RPO).
- **Supplement:** Weekly encrypted logical `pg_dump` to an owner-controlled location separate from the Supabase project.

Example export (run from a secure operator workstation with database URL):

```bash
pg_dump "$SUPABASE_DB_URL" --format=custom --file="hope-tv-$(date -u +%Y%m%d).dump"
gpg --symmetric --cipher-algo AES256 "hope-tv-$(date -u +%Y%m%d).dump"
```

Store ciphertext off-project (encrypted object storage or password manager vault attachment).

### Release artifacts (R2)

- Enable object versioning or lifecycle rules on the private R2 bucket.
- Retain at least the last three published stable builds per platform.
- Never expose public object URLs; downloads flow through the download gateway.

## 2. Restore drill (required before production launch)

1. Create a **non-production** Supabase project.
2. Restore the latest encrypted dump into that project.
3. Run migrations if restoring to an empty database instead of a full dump.
4. Verify:
   - RLS isolation tests pass
   - Admin health endpoint returns expected freshness fields
   - A test user can sign in and read entitlement (staging keys only)
5. Record **RTO** (time to usable control plane) and **RPO** (data age at restore).
6. File results in the owner operations log.

## 3. Account deletion processor

**Trigger:** `POST /functions/v1/account-deletion-processor` with header `X-Cron-Secret`.

**Success criteria:**

- `processedCount` matches due requests
- `failureCount` is zero
- `retention` object reports purge counts without error

**On failure:**

1. Check Edge Function logs for `deletion_process_failed`.
2. Inspect `account_deletion_requests` for rows stuck in `processing`.
3. Do not manually delete `auth.users` without completing `finalize_account_deletion_v1`.
4. Re-run processor after fixing root cause.

## 4. Alerts and runbooks

| Alert | Threshold (starting point) | Runbook action |
|---|---|---|
| API 5xx rate | > 1% for 5 min | Check Supabase status, Edge Function logs, recent migrations |
| Auth failure spike | 3× baseline for 10 min | Review SMTP/Auth settings, rate limits, abuse |
| Webhook backlog | `pendingWebhooks` > 50 | Inspect `private.webhook_events`, replay failed events |
| Due deletions | `dueDeletions` > 0 for 24h | Run deletion processor manually; verify `CRON_SECRET` |
| Entitlement denials | Spike by app version | Check release regression, clock skew, signing keys |
| Download auth abuse | Token failures > 100/hr | Review gateway logs, revoke abusive accounts |
| Analytics rejection rate | > 5% ingest failures | Validate client schema version, property allowlist |

Wire alerts to the owner on-call channel before general availability.

## 5. Security hardening checklist

- [ ] Admin dashboard deployed with `public/_headers` (CSP, HSTS, frame denial)
- [ ] Optional Cloudflare Access on admin origin (owner approval)
- [ ] `CRON_SECRET` rotated and stored in Supabase secrets only
- [ ] Dependency audit: `npm audit`, `dart pub outdated`, Deno lock review
- [ ] No service-role key in Flutter, portal, or dashboard artifacts
- [ ] Threat model reviewed after Phase 7 changes

## 6. Rollback

1. Revert the last dashboard Pages deployment to the previous build.
2. Redeploy prior Edge Function bundle if a function regression is suspected.
3. For schema issues, **do not** run destructive down migrations in production without owner approval; prefer forward-fix migrations.

## 7. Load testing (pre-launch)

Exercise with staging credentials only:

- Auth OTP request/verify (rate-limited)
- `entitlement`, `trial-activate`, `analytics-batch`
- `downloads` + download gateway authorize
- Billing webhook replay (when provider configured)

Record p95 latency and error rates; block launch if any critical path exceeds agreed SLOs.
