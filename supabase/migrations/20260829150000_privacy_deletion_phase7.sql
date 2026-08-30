-- Phase 7: Privacy, account deletion, retention, and operational hardening.

-- ---------------------------------------------------------------------------
-- Deletion request extensions
-- ---------------------------------------------------------------------------
alter table public.account_deletion_requests
  add column if not exists scheduled_for timestamptz,
  add column if not exists idempotency_key text,
  add column if not exists has_active_subscription boolean not null default false,
  add column if not exists correlation_id text;

create unique index if not exists account_deletion_idempotency_uidx
  on public.account_deletion_requests (user_id, idempotency_key)
  where idempotency_key is not null;

create unique index if not exists account_deletion_active_uidx
  on public.account_deletion_requests (user_id)
  where status in ('pending', 'processing');

-- ---------------------------------------------------------------------------
-- Retention policy registry (documented defaults; service role only)
-- ---------------------------------------------------------------------------
create table private.data_retention_policies (
  policy_key text primary key,
  description text not null,
  retention_days integer not null check (retention_days > 0),
  updated_at timestamptz not null default timezone('utc', now())
);

revoke all on private.data_retention_policies from public, anon, authenticated;

insert into private.data_retention_policies (policy_key, description, retention_days)
values
  ('analytics_raw_events', 'Raw analytics events with user linkage', 90),
  ('app_sessions', 'Session heartbeats and online presence rows', 30),
  ('download_events', 'Per-user download funnel events', 365),
  ('audit_logs', 'Administrative and lifecycle audit records', 2555),
  ('webhook_events', 'Billing webhook processing records', 730),
  ('financial_records', 'Subscription and billing customer linkage', 2555)
on conflict (policy_key) do nothing;

-- ---------------------------------------------------------------------------
-- Anonymize analytics properties (strip common PII keys)
-- ---------------------------------------------------------------------------
create or replace function analytics.strip_pii_properties(p_props jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce(p_props, '{}'::jsonb)
    - 'email'
    - 'email_normalized'
    - 'ip'
    - 'ip_address'
    - 'user_agent'
    - 'device_name'
    - 'display_name'
    - 'username'
    - 'password'
    - 'server_url'
    - 'iptv_url'
    - 'm3u_url';
$$;

-- ---------------------------------------------------------------------------
-- Purge expired raw analytics per retention policy
-- ---------------------------------------------------------------------------
create or replace function analytics.purge_expired_raw_data_v1()
returns jsonb
language plpgsql
security definer
set search_path = analytics, private, public
as $$
declare
  v_events_days integer;
  v_sessions_days integer;
  v_download_days integer;
  v_events_deleted integer := 0;
  v_sessions_deleted integer := 0;
  v_downloads_deleted integer := 0;
begin
  select retention_days into v_events_days
  from private.data_retention_policies where policy_key = 'analytics_raw_events';
  select retention_days into v_sessions_days
  from private.data_retention_policies where policy_key = 'app_sessions';
  select retention_days into v_download_days
  from private.data_retention_policies where policy_key = 'download_events';

  delete from analytics.analytics_events
  where received_at < timezone('utc', now()) - make_interval(days => v_events_days);
  get diagnostics v_events_deleted = row_count;

  delete from analytics.app_sessions
  where coalesce(ended_at, last_heartbeat_at) <
    timezone('utc', now()) - make_interval(days => v_sessions_days);
  get diagnostics v_sessions_deleted = row_count;

  delete from analytics.download_events
  where occurred_at < timezone('utc', now()) - make_interval(days => v_download_days);
  get diagnostics v_downloads_deleted = row_count;

  return jsonb_build_object(
    'analyticsEventsDeleted', v_events_deleted,
    'appSessionsDeleted', v_sessions_deleted,
    'downloadEventsDeleted', v_downloads_deleted,
    'purgedAt', timezone('utc', now())
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Finalize one account deletion (called by processor after grace period)
-- ---------------------------------------------------------------------------
create or replace function public.finalize_account_deletion_v1(
  p_user_id uuid,
  p_correlation_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = analytics, private, public
as $$
declare
  v_request_id uuid;
  v_anon_hash text;
begin
  select id into v_request_id
  from public.account_deletion_requests
  where user_id = p_user_id
    and status in ('pending', 'processing')
  order by requested_at desc
  limit 1
  for update;

  if v_request_id is null then
    raise exception 'no_active_deletion_request';
  end if;

  update public.account_deletion_requests
  set status = 'processing'
  where id = v_request_id
    and status = 'pending';

  v_anon_hash := encode(digest(p_user_id::text, 'sha256'), 'hex');

  -- Revoke devices and end sessions
  update public.devices
  set revoked_at = timezone('utc', now())
  where user_id = p_user_id
    and revoked_at is null;

  update analytics.app_sessions
  set ended_at = timezone('utc', now())
  where user_id = p_user_id
    and ended_at is null;

  delete from private.download_tokens where user_id = p_user_id;

  -- Anonymize analytics (preserve aggregates, remove identity)
  update analytics.analytics_events
  set
    user_id = null,
    installation_id_hash = null,
    properties = analytics.strip_pii_properties(properties)
  where user_id = p_user_id;

  update analytics.app_sessions
  set user_id = null, device_id = null, installation_id = null
  where user_id = p_user_id;

  update analytics.download_events
  set user_id = null
  where user_id = p_user_id;

  -- Redact profile PII; keep row for financial FK integrity
  update public.profiles
  set
    status = 'deleted',
    email_normalized = null,
    updated_at = timezone('utc', now())
  where id = p_user_id;

  -- Redact billing customer linkage; retain row for financial audit
  update private.billing_customers
  set
    provider_customer_id = null,
    updated_at = timezone('utc', now())
  where user_id = p_user_id;

  update public.account_deletion_requests
  set
    status = 'completed',
    completed_at = timezone('utc', now()),
    notes = coalesce(notes, '') || ' anonymized_hash=' || left(v_anon_hash, 16)
  where id = v_request_id;

  perform public.admin_append_audit(
    'system:deletion_processor',
    'account.deletion.completed',
    'profile',
    left(v_anon_hash, 16),
    'Account deletion finalized after grace period.',
    null,
    jsonb_build_object('status', 'deleted'),
    p_correlation_id
  );

  return jsonb_build_object(
    'userId', p_user_id,
    'requestId', v_request_id,
    'anonymizedHashPrefix', left(v_anon_hash, 16),
    'completedAt', timezone('utc', now())
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- List deletions due for processing
-- ---------------------------------------------------------------------------
create or replace function public.list_due_account_deletions_v1(p_limit integer default 25)
returns table (
  request_id uuid,
  user_id uuid,
  scheduled_for timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select id, user_id, scheduled_for
  from public.account_deletion_requests
  where status = 'pending'
    and scheduled_for <= timezone('utc', now())
  order by scheduled_for asc
  limit greatest(p_limit, 1);
$$;

-- ---------------------------------------------------------------------------
-- Health: deletion queue and retention visibility
-- ---------------------------------------------------------------------------
create or replace function public.admin_health_v1()
returns jsonb
language sql
stable
security definer
set search_path = analytics, public, private
as $$
  select jsonb_build_object(
    'database', 'ok',
    'lastAnalyticsEvent', (
      select max(received_at) from analytics.analytics_events
    ),
    'lastDailyAggregation', (
      select max(computed_at) from analytics.daily_account_activity
    ),
    'onlineAccounts', analytics.count_online_accounts('all'),
    'pendingWebhooks', (
      select count(*)::integer from private.webhook_events
      where processing_status in ('received', 'failed')
    ),
    'pendingDeletions', (
      select count(*)::integer from public.account_deletion_requests
      where status = 'pending'
    ),
    'dueDeletions', (
      select count(*)::integer from public.account_deletion_requests
      where status = 'pending'
        and scheduled_for <= timezone('utc', now())
    ),
    'retentionPolicies', (
      select coalesce(jsonb_object_agg(policy_key, retention_days), '{}'::jsonb)
      from private.data_retention_policies
    )
  );
$$;

revoke all on function analytics.purge_expired_raw_data_v1() from public, anon, authenticated;
revoke all on function public.finalize_account_deletion_v1(uuid, text) from public, anon, authenticated;
revoke all on function public.list_due_account_deletions_v1(integer) from public, anon, authenticated;

grant execute on function analytics.purge_expired_raw_data_v1() to service_role;
grant execute on function public.finalize_account_deletion_v1(uuid, text) to service_role;
grant execute on function public.list_due_account_deletions_v1(integer) to service_role;
