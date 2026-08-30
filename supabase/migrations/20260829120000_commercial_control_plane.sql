-- HOPE TV Phase 1: commercial control-plane schema
-- Deny-by-default RLS on exposed tables. Authority writes via service role / Edge Functions.

create extension if not exists pgcrypto;
create schema if not exists private;
create schema if not exists analytics;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to postgres, service_role;
grant usage on schema analytics to postgres, service_role, authenticated, anon;
-- ---------------------------------------------------------------------------
-- Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete restrict,
  email_normalized text,
  status text not null default 'active'
    check (status in ('active', 'suspended', 'deletion_pending', 'deleted')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  last_login_at timestamptz
);
create index profiles_status_created_idx
  on public.profiles (status, created_at);
-- ---------------------------------------------------------------------------
-- Installations & devices
-- ---------------------------------------------------------------------------
create table public.installations (
  id uuid primary key default gen_random_uuid(),
  installation_id_hash text not null unique,
  platform text not null check (platform in ('android', 'windows', 'web', 'unknown')),
  app_version text,
  os_version_category text,
  first_seen_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now())
);
create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  installation_id uuid references public.installations (id) on delete set null,
  display_name text,
  platform text not null check (platform in ('android', 'windows', 'web', 'unknown')),
  app_version text,
  os_version_category text,
  first_seen_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now()),
  revoked_at timestamptz,
  last_entitlement_refresh_at timestamptz
);
create index devices_user_last_seen_idx on public.devices (user_id, last_seen_at desc);
create index devices_user_active_idx on public.devices (user_id) where revoked_at is null;
create table public.device_pairing_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  installation_id uuid not null references public.installations (id) on delete cascade,
  user_id uuid references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'expired', 'consumed', 'denied')),
  expires_at timestamptz not null,
  approved_at timestamptz,
  consumed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);
-- ---------------------------------------------------------------------------
-- Trials
-- ---------------------------------------------------------------------------
create table public.trials (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending', 'active', 'expired', 'revoked')),
  started_at timestamptz,
  ends_at timestamptz,
  duration_days_snapshot integer not null default 7 check (duration_days_snapshot > 0),
  activation_platform text,
  activated_by_event_id text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint trials_active_window_chk check (
    (status <> 'active') or (started_at is not null and ends_at is not null and ends_at > started_at)
  )
);
create index trials_user_status_idx on public.trials (user_id, status);
-- ---------------------------------------------------------------------------
-- Plans (display / config; not billable until provider configured)
-- ---------------------------------------------------------------------------
create table public.plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  interval text not null check (interval in ('month', 'year')),
  enabled boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);
create table public.plan_prices (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans (id) on delete restrict,
  currency text not null,
  amount_minor integer not null check (amount_minor >= 0),
  display_amount text not null,
  provider_price_id text,
  enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  unique (plan_id, currency)
);
-- ---------------------------------------------------------------------------
-- Billing / subscriptions (provider deferred)
-- ---------------------------------------------------------------------------
create table private.billing_customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles (id) on delete restrict,
  provider text not null default 'none',
  provider_customer_id text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (provider, provider_customer_id)
);
create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  plan_id uuid references public.plans (id) on delete restrict,
  provider text not null default 'none',
  provider_subscription_id text,
  status text not null
    check (status in (
      'trialing', 'active', 'past_due', 'grace_period',
      'canceling_at_period_end', 'expired', 'refunded', 'disputed', 'suspended'
    )),
  current_period_end timestamptz,
  grace_period_ends_at timestamptz,
  cancel_at_period_end boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (provider, provider_subscription_id)
);
create index subscriptions_user_status_idx on public.subscriptions (user_id, status);
create index subscriptions_period_end_idx on public.subscriptions (current_period_end);
create table private.entitlement_overrides (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  access_granted boolean not null,
  ends_at timestamptz,
  reason text not null,
  created_by text not null,
  created_at timestamptz not null default timezone('utc', now())
);
create table private.webhook_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  provider_event_id text not null,
  event_type text not null,
  processing_status text not null default 'received'
    check (processing_status in ('received', 'processed', 'ignored', 'failed')),
  occurred_at timestamptz,
  processed_at timestamptz,
  error_summary text,
  created_at timestamptz not null default timezone('utc', now()),
  unique (provider, provider_event_id)
);
create index webhook_events_status_idx
  on private.webhook_events (processing_status, created_at);
create table private.idempotency_keys (
  id uuid primary key default gen_random_uuid(),
  scope text not null,
  idempotency_key text not null,
  user_id uuid references public.profiles (id) on delete cascade,
  response_hash text,
  created_at timestamptz not null default timezone('utc', now()),
  unique (scope, idempotency_key)
);
-- ---------------------------------------------------------------------------
-- Releases / downloads
-- ---------------------------------------------------------------------------
create table public.release_versions (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('android', 'windows')),
  architecture text not null default 'universal',
  channel text not null default 'stable'
    check (channel in ('stable', 'beta', 'internal')),
  version text not null,
  build_number integer not null,
  object_key text not null,
  file_size_bytes bigint,
  sha256 text not null,
  manifest_signature text,
  minimum_supported_prior_version text,
  mandatory_update boolean not null default false,
  release_notes_en text,
  release_notes_ar text,
  published_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  unique (platform, channel, version, architecture)
);
create index release_versions_lookup_idx
  on public.release_versions (platform, channel, published_at desc);
create table private.download_tokens (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  user_id uuid not null references public.profiles (id) on delete cascade,
  release_id uuid not null references public.release_versions (id) on delete restrict,
  expires_at timestamptz not null,
  max_uses integer not null default 1 check (max_uses > 0),
  use_count integer not null default 0,
  consumed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);
create table analytics.download_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  release_id uuid references public.release_versions (id) on delete set null,
  platform text,
  event_name text not null
    check (event_name in ('download_authorized', 'release_download_requested', 'completed_transfer')),
  occurred_at timestamptz not null default timezone('utc', now()),
  metadata jsonb not null default '{}'::jsonb
);
create index download_events_occurred_idx
  on analytics.download_events (occurred_at desc);
-- ---------------------------------------------------------------------------
-- Sessions & analytics
-- ---------------------------------------------------------------------------
create table analytics.app_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  device_id uuid references public.devices (id) on delete set null,
  installation_id uuid references public.installations (id) on delete set null,
  platform text,
  app_version text,
  started_at timestamptz not null default timezone('utc', now()),
  last_heartbeat_at timestamptz not null default timezone('utc', now()),
  ended_at timestamptz
);
create index app_sessions_user_heartbeat_idx
  on analytics.app_sessions (user_id, last_heartbeat_at desc);
create table analytics.analytics_events (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null unique,
  event_name text not null,
  schema_version integer not null default 1,
  occurred_at timestamptz not null,
  received_at timestamptz not null default timezone('utc', now()),
  user_id uuid references public.profiles (id) on delete set null,
  installation_id_hash text,
  platform text,
  app_version text,
  properties jsonb not null default '{}'::jsonb
);
create index analytics_events_day_name_idx
  on analytics.analytics_events (occurred_at, event_name);
create index analytics_events_platform_version_idx
  on analytics.analytics_events (platform, app_version);
create table analytics.daily_metrics (
  metric_date date not null,
  metric_name text not null,
  metric_value numeric not null,
  dimensions jsonb not null default '{}'::jsonb,
  primary key (metric_date, metric_name, dimensions)
);
-- ---------------------------------------------------------------------------
-- Remote config, audit, deletion
-- ---------------------------------------------------------------------------
create table public.remote_config_versions (
  id uuid primary key default gen_random_uuid(),
  version integer not null unique,
  payload jsonb not null,
  published_at timestamptz not null default timezone('utc', now()),
  published_by text
);
create table private.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor text not null,
  action text not null,
  target_type text,
  target_id text,
  reason text,
  before_state jsonb,
  after_state jsonb,
  correlation_id text,
  created_at timestamptz not null default timezone('utc', now())
);
create table public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete restrict,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'canceled')),
  requested_at timestamptz not null default timezone('utc', now()),
  canceled_at timestamptz,
  completed_at timestamptz,
  notes text
);
create index account_deletion_user_idx
  on public.account_deletion_requests (user_id, requested_at desc);
-- ---------------------------------------------------------------------------
-- Profile provisioning trigger
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email_normalized, last_login_at)
  values (
    new.id,
    lower(new.email),
    timezone('utc', now())
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
-- ---------------------------------------------------------------------------
-- RLS: enable and deny by default; selective customer policies
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.installations enable row level security;
alter table public.devices enable row level security;
alter table public.device_pairing_codes enable row level security;
alter table public.trials enable row level security;
alter table public.plans enable row level security;
alter table public.plan_prices enable row level security;
alter table public.subscriptions enable row level security;
alter table public.release_versions enable row level security;
alter table public.remote_config_versions enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table analytics.download_events enable row level security;
alter table analytics.app_sessions enable row level security;
alter table analytics.analytics_events enable row level security;
alter table analytics.daily_metrics enable row level security;
-- Profiles
create policy profiles_select_own on public.profiles
  for select to authenticated
  using (id = auth.uid());
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid())
  with check (
    id = auth.uid()
    and status = (select p.status from public.profiles p where p.id = auth.uid())
  );
-- Devices: customer read + request revoke (update revoked_at only via controlled path later;
-- for Phase 1 allow update of display_name / revoked_at on own rows)
create policy devices_select_own on public.devices
  for select to authenticated
  using (user_id = auth.uid());
create policy devices_update_own on public.devices
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
-- No insert/delete for authenticated on devices (Edge Functions / service role)

-- Trials: read summary only
create policy trials_select_own on public.trials
  for select to authenticated
  using (user_id = auth.uid());
-- Subscriptions: read safe summary only
create policy subscriptions_select_own on public.subscriptions
  for select to authenticated
  using (user_id = auth.uid());
-- Plans / prices: public read of enabled rows
create policy plans_select_enabled on public.plans
  for select to anon, authenticated
  using (enabled = true);
create policy plan_prices_select_enabled on public.plan_prices
  for select to anon, authenticated
  using (enabled = true);
-- Releases: authenticated may read published non-revoked metadata (not object bytes)
create policy release_versions_select_published on public.release_versions
  for select to authenticated
  using (published_at is not null and revoked_at is null);
-- Remote config: authenticated read latest published payloads
create policy remote_config_select on public.remote_config_versions
  for select to authenticated
  using (true);
-- Deletion requests: own rows read; insert own pending
create policy deletion_select_own on public.account_deletion_requests
  for select to authenticated
  using (user_id = auth.uid());
create policy deletion_insert_own on public.account_deletion_requests
  for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending');
-- Pairing codes: no broad customer access (Edge Functions)
-- Installations: no direct customer access
-- Analytics raw: no direct customer reads (deny by default; no policies)

-- Grants: authenticated can select where policies allow
grant usage on schema public to anon, authenticated;
grant select on public.plans to anon, authenticated;
grant select on public.plan_prices to anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, update on public.devices to authenticated;
grant select on public.trials to authenticated;
grant select on public.subscriptions to authenticated;
grant select on public.release_versions to authenticated;
grant select on public.remote_config_versions to authenticated;
grant select, insert on public.account_deletion_requests to authenticated;
-- Service role bypasses RLS by default in Supabase; ensure table privileges
grant all on all tables in schema public to postgres, service_role;
grant all on all tables in schema private to postgres, service_role;
grant all on all tables in schema analytics to postgres, service_role;
grant usage, select on all sequences in schema public to postgres, service_role;
grant usage, select on all sequences in schema private to postgres, service_role;
grant usage, select on all sequences in schema analytics to postgres, service_role;
