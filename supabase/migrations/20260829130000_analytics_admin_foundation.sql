-- Phase 5: Analytics foundation and owner admin dashboard
-- Admin roles, reporting functions, daily aggregates, audit helpers.

-- ---------------------------------------------------------------------------
-- Admin users (service-only; no customer access)
-- ---------------------------------------------------------------------------
create table private.admin_users (
  user_id uuid primary key references auth.users (id) on delete cascade,
  role text not null
    check (role in ('owner', 'analyst', 'support', 'release_manager')),
  status text not null default 'active'
    check (status in ('active', 'disabled')),
  created_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users (id) on delete set null,
  last_reviewed_at timestamptz
);
create index admin_users_status_idx on private.admin_users (status, role);
revoke all on private.admin_users from public, anon, authenticated;
-- ---------------------------------------------------------------------------
-- Config drafts (reviewed publish workflow)
-- ---------------------------------------------------------------------------
create table private.config_drafts (
  id uuid primary key default gen_random_uuid(),
  version integer not null,
  payload jsonb not null,
  status text not null default 'draft'
    check (status in ('draft', 'validated', 'published', 'discarded')),
  created_by uuid not null references auth.users (id) on delete restrict,
  created_at timestamptz not null default timezone('utc', now()),
  validated_at timestamptz,
  published_at timestamptz,
  validation_errors jsonb,
  unique (version)
);
revoke all on private.config_drafts from public, anon, authenticated;
-- ---------------------------------------------------------------------------
-- Daily aggregate tables (pre-computed reporting)
-- ---------------------------------------------------------------------------
create table analytics.daily_account_activity (
  metric_date date not null,
  platform text not null default 'all',
  dau integer not null default 0,
  wau integer not null default 0,
  mau integer not null default 0,
  waea integer not null default 0,
  new_registrations integer not null default 0,
  new_activations integer not null default 0,
  active_trials integer not null default 0,
  paying_subscribers integer not null default 0,
  online_peak integer not null default 0,
  computed_at timestamptz not null default timezone('utc', now()),
  primary key (metric_date, platform)
);
create table analytics.daily_download_metrics (
  metric_date date not null,
  platform text not null default 'all',
  download_authorized integer not null default 0,
  download_requested integer not null default 0,
  completed_transfer integer not null default 0,
  new_installations integer not null default 0,
  computed_at timestamptz not null default timezone('utc', now()),
  primary key (metric_date, platform)
);
create table analytics.daily_subscription_metrics (
  metric_date date not null,
  active_paid integer not null default 0,
  monthly_active integer not null default 0,
  yearly_active integer not null default 0,
  canceling_at_period_end integer not null default 0,
  past_due integer not null default 0,
  in_grace_period integer not null default 0,
  expired_in_range integer not null default 0,
  payment_failures integer not null default 0,
  trial_to_paid_conversion numeric not null default 0,
  computed_at timestamptz not null default timezone('utc', now()),
  primary key (metric_date)
);
create table analytics.daily_funnel_metrics (
  metric_date date not null,
  platform text not null default 'all',
  download_requested integer not null default 0,
  first_installation integer not null default 0,
  account_verified integer not null default 0,
  iptv_connected integer not null default 0,
  trial_started integer not null default 0,
  returned_during_trial integer not null default 0,
  checkout_started integer not null default 0,
  paid_activated integer not null default 0,
  first_renewal integer not null default 0,
  computed_at timestamptz not null default timezone('utc', now()),
  primary key (metric_date, platform)
);
create table analytics.weekly_retention_metrics (
  cohort_week date not null,
  platform text not null default 'all',
  cohort_size integer not null default 0,
  retained_w0 integer not null default 0,
  retained_w1 integer not null default 0,
  retained_w2 integer not null default 0,
  retained_w3 integer not null default 0,
  retained_w4 integer not null default 0,
  computed_at timestamptz not null default timezone('utc', now()),
  primary key (cohort_week, platform)
);
alter table analytics.daily_account_activity enable row level security;
alter table analytics.daily_download_metrics enable row level security;
alter table analytics.daily_subscription_metrics enable row level security;
alter table analytics.daily_funnel_metrics enable row level security;
alter table analytics.weekly_retention_metrics enable row level security;
-- ---------------------------------------------------------------------------
-- Admin capability helpers
-- ---------------------------------------------------------------------------
create or replace function public.admin_resolve_role(p_user_id uuid)
returns table (role text, status text)
language sql
stable
security definer
set search_path = private, public
as $$
  select au.role, au.status
  from private.admin_users au
  where au.user_id = p_user_id
    and au.status = 'active';
$$;
create or replace function public.admin_has_capability(
  p_user_id uuid,
  p_capability text
)
returns boolean
language plpgsql
stable
security definer
set search_path = private, public
as $$
declare
  v_role text;
begin
  select role into v_role
  from private.admin_resolve_role(p_user_id);

  if v_role is null then
    return false;
  end if;

  return case p_capability
    when 'view_metrics' then v_role in ('owner', 'analyst', 'support', 'release_manager')
    when 'view_users' then v_role in ('owner', 'analyst', 'support')
    when 'view_subscriptions' then v_role in ('owner', 'analyst', 'support')
    when 'revoke_device' then v_role in ('owner', 'support')
    when 'suspend_account' then v_role = 'owner'
    when 'reactivate_account' then v_role = 'owner'
    when 'entitlement_override' then v_role = 'owner'
    when 'billing_sync' then v_role in ('owner', 'support')
    when 'publish_config' then v_role = 'owner'
    when 'publish_release' then v_role in ('owner', 'release_manager')
    when 'view_audit' then v_role in ('owner', 'analyst')
    when 'manage_admins' then v_role = 'owner'
    else false
  end;
end;
$$;
-- ---------------------------------------------------------------------------
-- Append-only audit helper
-- ---------------------------------------------------------------------------
create or replace function public.admin_append_audit(
  p_actor text,
  p_action text,
  p_target_type text default null,
  p_target_id text default null,
  p_reason text default null,
  p_before_state jsonb default null,
  p_after_state jsonb default null,
  p_correlation_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_id uuid;
begin
  insert into private.audit_logs (
    actor, action, target_type, target_id, reason,
    before_state, after_state, correlation_id
  )
  values (
    p_actor, p_action, p_target_type, p_target_id, p_reason,
    p_before_state, p_after_state, p_correlation_id
  )
  returning id into v_id;

  return v_id;
end;
$$;
-- Meaningful activity: foreground session events (not idle background heartbeat alone)
create or replace function analytics.is_meaningful_activity_event(p_event_name text)
returns boolean
language sql
immutable
as $$
  select p_event_name in (
    'session_started',
    'playback_started',
    'iptv_connection_succeeded',
    'subscription_page_opened',
    'subscription_activated',
    'trial_started',
    'entitlement_refreshed'
  );
$$;
-- ---------------------------------------------------------------------------
-- Live metric helpers
-- ---------------------------------------------------------------------------
create or replace function analytics.count_online_accounts(p_platform text default null)
returns integer
language sql
stable
security definer
set search_path = analytics, public
as $$
  select count(distinct s.user_id)::integer
  from analytics.app_sessions s
  join public.devices d on d.id = s.device_id
  where s.user_id is not null
    and s.ended_at is null
    and s.last_heartbeat_at >= timezone('utc', now()) - interval '5 minutes'
    and d.revoked_at is null
    and (p_platform is null or p_platform = 'all' or s.platform = p_platform);
$$;
create or replace function analytics.count_online_devices(p_platform text default null)
returns integer
language sql
stable
security definer
set search_path = analytics, public
as $$
  select count(distinct s.device_id)::integer
  from analytics.app_sessions s
  join public.devices d on d.id = s.device_id
  where s.device_id is not null
    and s.ended_at is null
    and s.last_heartbeat_at >= timezone('utc', now()) - interval '5 minutes'
    and d.revoked_at is null
    and (p_platform is null or p_platform = 'all' or s.platform = p_platform);
$$;
-- ---------------------------------------------------------------------------
-- Daily aggregation job
-- ---------------------------------------------------------------------------
create or replace function analytics.aggregate_daily_metrics(p_target_date date default null)
returns void
language plpgsql
security definer
set search_path = analytics, public, private
as $$
declare
  v_date date := coalesce(p_target_date, (timezone('utc', now()) - interval '1 day')::date);
  v_platform text;
  v_dau integer;
  v_waea integer;
begin
  foreach v_platform in array array['all', 'android', 'windows'] loop
    -- DAU: distinct accounts with meaningful activity on v_date
    select count(distinct e.user_id)::integer into v_dau
    from analytics.analytics_events e
    join public.profiles p on p.id = e.user_id
    where e.occurred_at::date = v_date
      and p.status not in ('deleted', 'deletion_pending')
      and analytics.is_meaningful_activity_event(e.event_name)
      and (v_platform = 'all' or e.platform = v_platform);

    -- WAEA: entitled accounts with meaningful activity on 2+ days in trailing 7
    select count(*)::integer into v_waea
    from (
      select e.user_id
      from analytics.analytics_events e
      join public.profiles p on p.id = e.user_id
      left join public.trials t on t.user_id = e.user_id and t.status = 'active'
      left join public.subscriptions s on s.user_id = e.user_id
        and s.status in ('active', 'trialing', 'grace_period', 'past_due', 'canceling_at_period_end')
      where e.occurred_at::date between v_date - 6 and v_date
        and p.status = 'active'
        and analytics.is_meaningful_activity_event(e.event_name)
        and (t.id is not null or s.id is not null)
        and (v_platform = 'all' or e.platform = v_platform)
      group by e.user_id
      having count(distinct e.occurred_at::date) >= 2
    ) entitled_active;

    insert into analytics.daily_account_activity (
      metric_date, platform, dau, waea,
      new_registrations, new_activations, active_trials, paying_subscribers,
      computed_at
    )
    values (
      v_date,
      v_platform,
      coalesce(v_dau, 0),
      coalesce(v_waea, 0),
      (
        select count(*)::integer from public.profiles p
        where p.created_at::date = v_date
          and p.status not in ('deleted')
      ),
      (
        select count(*)::integer from public.trials t
        where t.started_at::date = v_date and t.status in ('active', 'expired')
      ),
      (
        select count(*)::integer from public.trials t
        where t.status = 'active' and t.ends_at > timezone('utc', now())
      ),
      (
        select count(*)::integer from public.subscriptions s
        where s.status in ('active', 'grace_period', 'canceling_at_period_end')
          and (s.current_period_end is null or s.current_period_end > timezone('utc', now()))
      ),
      timezone('utc', now())
    )
    on conflict (metric_date, platform) do update set
      dau = excluded.dau,
      waea = excluded.waea,
      new_registrations = excluded.new_registrations,
      new_activations = excluded.new_activations,
      active_trials = excluded.active_trials,
      paying_subscribers = excluded.paying_subscribers,
      computed_at = excluded.computed_at;

    insert into analytics.daily_download_metrics (
      metric_date, platform,
      download_authorized, download_requested, completed_transfer, new_installations,
      computed_at
    )
    values (
      v_date,
      v_platform,
      (
        select count(*)::integer from analytics.download_events de
        where de.occurred_at::date = v_date
          and de.event_name = 'download_authorized'
          and (v_platform = 'all' or de.platform = v_platform)
      ),
      (
        select count(*)::integer from analytics.download_events de
        where de.occurred_at::date = v_date
          and de.event_name = 'release_download_requested'
          and (v_platform = 'all' or de.platform = v_platform)
      ),
      (
        select count(*)::integer from analytics.download_events de
        where de.occurred_at::date = v_date
          and de.event_name = 'completed_transfer'
          and (v_platform = 'all' or de.platform = v_platform)
      ),
      (
        select count(*)::integer from public.installations i
        where i.first_seen_at::date = v_date
          and (v_platform = 'all' or i.platform = v_platform)
      ),
      timezone('utc', now())
    )
    on conflict (metric_date, platform) do update set
      download_authorized = excluded.download_authorized,
      download_requested = excluded.download_requested,
      completed_transfer = excluded.completed_transfer,
      new_installations = excluded.new_installations,
      computed_at = excluded.computed_at;

    insert into analytics.daily_funnel_metrics (
      metric_date, platform,
      download_requested, first_installation, account_verified,
      iptv_connected, trial_started, checkout_started, paid_activated,
      computed_at
    )
    values (
      v_date,
      v_platform,
      (
        select count(distinct coalesce(de.user_id::text, de.id::text))
        from analytics.download_events de
        where de.occurred_at::date = v_date
          and de.event_name = 'release_download_requested'
          and (v_platform = 'all' or de.platform = v_platform)
      ),
      (
        select count(*)::integer from public.installations i
        where i.first_seen_at::date = v_date
          and (v_platform = 'all' or i.platform = v_platform)
      ),
      (
        select count(*)::integer from public.profiles p
        where p.created_at::date = v_date
      ),
      (
        select count(*)::integer from analytics.analytics_events e
        where e.occurred_at::date = v_date
          and e.event_name = 'iptv_connection_succeeded'
          and (v_platform = 'all' or e.platform = v_platform)
      ),
      (
        select count(*)::integer from public.trials t
        where t.started_at::date = v_date
      ),
      (
        select count(*)::integer from analytics.analytics_events e
        where e.occurred_at::date = v_date
          and e.event_name = 'subscription_page_opened'
          and (v_platform = 'all' or e.platform = v_platform)
      ),
      (
        select count(*)::integer from analytics.analytics_events e
        where e.occurred_at::date = v_date
          and e.event_name = 'subscription_activated'
          and (v_platform = 'all' or e.platform = v_platform)
      ),
      timezone('utc', now())
    )
    on conflict (metric_date, platform) do update set
      download_requested = excluded.download_requested,
      first_installation = excluded.first_installation,
      account_verified = excluded.account_verified,
      iptv_connected = excluded.iptv_connected,
      trial_started = excluded.trial_started,
      checkout_started = excluded.checkout_started,
      paid_activated = excluded.paid_activated,
      computed_at = excluded.computed_at;
  end loop;

  insert into analytics.daily_subscription_metrics (
    metric_date, active_paid, monthly_active, yearly_active,
    canceling_at_period_end, past_due, in_grace_period,
    computed_at
  )
  values (
    v_date,
    (select count(*)::integer from public.subscriptions where status = 'active'),
    (
      select count(*)::integer from public.subscriptions s
      join public.plans p on p.id = s.plan_id
      where s.status = 'active' and p.interval = 'month'
    ),
    (
      select count(*)::integer from public.subscriptions s
      join public.plans p on p.id = s.plan_id
      where s.status = 'active' and p.interval = 'year'
    ),
    (select count(*)::integer from public.subscriptions where status = 'canceling_at_period_end'),
    (select count(*)::integer from public.subscriptions where status = 'past_due'),
    (select count(*)::integer from public.subscriptions where status = 'grace_period'),
    timezone('utc', now())
  )
  on conflict (metric_date) do update set
    active_paid = excluded.active_paid,
    monthly_active = excluded.monthly_active,
    yearly_active = excluded.yearly_active,
    canceling_at_period_end = excluded.canceling_at_period_end,
    past_due = excluded.past_due,
    in_grace_period = excluded.in_grace_period,
    computed_at = excluded.computed_at;
end;
$$;
-- ---------------------------------------------------------------------------
-- Admin reporting functions (service-role / Edge Function only)
-- ---------------------------------------------------------------------------
create or replace function public.admin_overview_v1(
  p_start_date date,
  p_end_date date,
  p_platform text default 'all'
)
returns jsonb
language plpgsql
stable
security definer
set search_path = private, analytics, public
as $$
declare
  v_result jsonb;
  v_platform text := coalesce(nullif(p_platform, ''), 'all');
begin
  select jsonb_build_object(
    'downloadRequested', coalesce(sum(dm.download_requested), 0),
    'downloadAuthorized', coalesce(sum(dm.download_authorized), 0),
    'completedTransfer', coalesce(sum(dm.completed_transfer), 0),
    'newInstallations', coalesce(sum(dm.new_installations), 0),
    'registeredAccounts', coalesce(sum(da.new_registrations), 0),
    'activatedAccounts', coalesce(sum(da.new_activations), 0),
    'dau', coalesce(sum(da.dau), 0),
    'waea', coalesce(sum(da.waea), 0),
    'activeTrials', (
      select count(*)::integer from public.trials t
      where t.status = 'active' and t.ends_at > timezone('utc', now())
    ),
    'payingSubscribers', (
      select count(*)::integer from public.subscriptions s
      where s.status in ('active', 'grace_period', 'canceling_at_period_end')
        and (s.current_period_end is null or s.current_period_end > timezone('utc', now()))
    ),
    'onlineAccountsNow', analytics.count_online_accounts(v_platform),
    'onlineDevicesNow', analytics.count_online_devices(v_platform),
    'trialToPaidConversion', coalesce((
      select ds.trial_to_paid_conversion from analytics.daily_subscription_metrics ds
      where ds.metric_date = p_end_date
    ), 0),
    'paymentFailures', coalesce((
      select sum(ds.payment_failures) from analytics.daily_subscription_metrics ds
      where ds.metric_date between p_start_date and p_end_date
    ), 0),
    'cancellations', coalesce((
      select sum(ds.canceling_at_period_end) from analytics.daily_subscription_metrics ds
      where ds.metric_date between p_start_date and p_end_date
    ), 0)
  ) into v_result
  from analytics.daily_account_activity da
  full outer join analytics.daily_download_metrics dm
    on dm.metric_date = da.metric_date and dm.platform = da.platform
  where coalesce(da.metric_date, dm.metric_date) between p_start_date and p_end_date
    and coalesce(da.platform, dm.platform, v_platform) = v_platform;

  return coalesce(v_result, '{}'::jsonb);
end;
$$;
create or replace function public.admin_user_search_v1(
  p_query text default null,
  p_status text default null,
  p_limit integer default 25,
  p_cursor text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = private, public
as $$
declare
  v_limit integer := least(greatest(coalesce(p_limit, 25), 1), 100);
  v_items jsonb;
begin
  select coalesce(jsonb_agg(row_to_json(t)::jsonb), '[]'::jsonb) into v_items
  from (
    select
      p.id,
      case
        when length(coalesce(p.email_normalized, '')) > 3 then
          left(p.email_normalized, 2) || '***' || substring(p.email_normalized from position('@' in p.email_normalized))
        else '***'
      end as masked_email,
      p.status,
      p.created_at,
      p.last_login_at,
      (
        select t.status from public.trials t where t.user_id = p.id limit 1
      ) as trial_status,
      (
        select s.status from public.subscriptions s
        where s.user_id = p.id
        order by s.updated_at desc limit 1
      ) as subscription_status
    from public.profiles p
    where (p_status is null or p.status = p_status)
      and (
        p_query is null
        or p.id::text = p_query
        or (length(p_query) >= 3 and p.email_normalized ilike p_query || '%')
      )
    order by p.created_at desc
    limit v_limit
  ) t;

  return jsonb_build_object('items', v_items, 'nextCursor', null);
end;
$$;
create or replace function public.admin_user_detail_v1(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = private, public, analytics
as $$
declare
  v_profile record;
  v_result jsonb;
begin
  select * into v_profile from public.profiles where id = p_user_id;
  if not found then
    return null;
  end if;

  select jsonb_build_object(
    'account', jsonb_build_object(
      'id', v_profile.id,
      'email', v_profile.email_normalized,
      'status', v_profile.status,
      'createdAt', v_profile.created_at,
      'lastLoginAt', v_profile.last_login_at
    ),
    'trial', (
      select row_to_json(t) from (
        select status, started_at, ends_at, duration_days_snapshot, activation_platform
        from public.trials where user_id = p_user_id
      ) t
    ),
    'subscription', (
      select row_to_json(s) from (
        select id, status, current_period_end, grace_period_ends_at,
               cancel_at_period_end, provider, updated_at
        from public.subscriptions
        where user_id = p_user_id
        order by updated_at desc limit 1
      ) s
    ),
    'devices', (
      select coalesce(jsonb_agg(row_to_json(d)), '[]'::jsonb) from (
        select id, display_name, platform, app_version, first_seen_at,
               last_seen_at, revoked_at
        from public.devices where user_id = p_user_id
        order by last_seen_at desc
      ) d
    )
  ) into v_result;

  return v_result;
end;
$$;
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
    )
  );
$$;
revoke all on function public.admin_resolve_role(uuid) from public, anon, authenticated;
revoke all on function public.admin_has_capability(uuid, text) from public, anon, authenticated;
revoke all on function public.admin_append_audit(text, text, text, text, text, jsonb, jsonb, text) from public, anon, authenticated;
revoke all on function analytics.aggregate_daily_metrics(date) from public, anon, authenticated;
revoke all on function public.admin_overview_v1(date, date, text) from public, anon, authenticated;
revoke all on function public.admin_user_search_v1(text, text, integer, text) from public, anon, authenticated;
revoke all on function public.admin_user_detail_v1(uuid) from public, anon, authenticated;
revoke all on function public.admin_health_v1() from public, anon, authenticated;
grant execute on function public.admin_resolve_role(uuid) to service_role;
grant execute on function public.admin_has_capability(uuid, text) to service_role;
grant execute on function public.admin_append_audit(text, text, text, text, text, jsonb, jsonb, text) to service_role;
grant execute on function analytics.aggregate_daily_metrics(date) to service_role;
grant execute on function public.admin_overview_v1(date, date, text) to service_role;
grant execute on function public.admin_user_search_v1(text, text, integer, text) to service_role;
grant execute on function public.admin_user_detail_v1(uuid) to service_role;
grant execute on function public.admin_health_v1() to service_role;
grant execute on function analytics.count_online_accounts(text) to service_role;
grant execute on function analytics.count_online_devices(text) to service_role;
