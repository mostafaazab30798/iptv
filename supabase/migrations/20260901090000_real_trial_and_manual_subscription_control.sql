-- Real customer access control: combined trial/subscription reporting and
-- audited manual paid-access grants. Payment-provider subscriptions remain
-- webhook-authoritative; provider='manual' means the owner recorded payment
-- outside the app and deliberately granted a fixed access period.

insert into public.plans (code, name, interval, enabled, sort_order)
values
  ('monthly', 'HOPE TV Monthly', 'month', true, 1),
  ('yearly', 'HOPE TV Yearly', 'year', true, 2)
on conflict (code) do nothing;

create unique index if not exists subscriptions_one_manual_per_user_idx
  on public.subscriptions (user_id)
  where provider = 'manual';

create or replace function public.admin_grant_manual_subscription_v1(
  p_user_id uuid,
  p_plan_code text,
  p_duration_days integer
)
returns jsonb
language plpgsql
security definer
set search_path = public, private, pg_temp
as $$
declare
  v_plan public.plans%rowtype;
  v_existing public.subscriptions%rowtype;
  v_result public.subscriptions%rowtype;
  v_base timestamptz;
begin
  if p_duration_days is null or p_duration_days < 1 or p_duration_days > 1825 then
    raise exception 'duration_days must be between 1 and 1825';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_user_id and status = 'active'
  ) then
    raise exception 'active account not found';
  end if;

  select * into v_plan
  from public.plans
  where code = p_plan_code and enabled = true
  limit 1;

  if v_plan.id is null then
    raise exception 'enabled plan not found';
  end if;

  select * into v_existing
  from public.subscriptions
  where user_id = p_user_id and provider = 'manual'
  for update;

  v_base := greatest(
    now(),
    coalesce(v_existing.current_period_end, now())
  );

  insert into public.subscriptions (
    user_id,
    plan_id,
    provider,
    provider_subscription_id,
    status,
    current_period_end,
    grace_period_ends_at,
    cancel_at_period_end,
    updated_at
  ) values (
    p_user_id,
    v_plan.id,
    'manual',
    'manual:' || p_user_id::text,
    'active',
    v_base + make_interval(days => p_duration_days),
    null,
    false,
    now()
  )
  on conflict (user_id) where provider = 'manual'
  do update set
    plan_id = excluded.plan_id,
    status = 'active',
    current_period_end = excluded.current_period_end,
    grace_period_ends_at = null,
    cancel_at_period_end = false,
    updated_at = now()
  returning * into v_result;

  return jsonb_build_object(
    'id', v_result.id,
    'user_id', v_result.user_id,
    'plan_code', v_plan.code,
    'provider', v_result.provider,
    'status', v_result.status,
    'current_period_end', v_result.current_period_end,
    'updated_at', v_result.updated_at
  );
end;
$$;

create or replace function public.admin_access_list_v1(
  p_status text default null,
  p_plan text default null,
  p_access text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language sql
stable
security definer
set search_path = public, private, pg_temp
as $$
  with access_rows as (
    select
      p.id as user_id,
      p.email_normalized,
      p.status as account_status,
      p.created_at,
      t.id as trial_id,
      t.status as trial_status,
      t.started_at as trial_started_at,
      t.ends_at as trial_ends_at,
      s.id,
      s.plan_id,
      s.provider,
      s.provider_subscription_id,
      s.status as subscription_status,
      s.current_period_end,
      s.grace_period_ends_at,
      s.cancel_at_period_end,
      s.updated_at,
      pl.code as plan_code,
      pl.interval as plan_interval,
      case
        when p.status <> 'active' then 'expired'
        when ov.access_granted = true then 'complimentary'
        when s.status in ('active', 'canceling_at_period_end')
          and s.current_period_end > now() then 'paid'
        when s.status = 'trialing'
          and s.current_period_end > now() then 'trial'
        when s.status in ('past_due', 'grace_period')
          and s.grace_period_ends_at > now() then 'grace'
        when t.status = 'active' and t.ends_at > now() then 'trial'
        else 'expired'
      end as access_status,
      case
        when s.id is not null then s.status
        when t.status = 'active' and t.ends_at > now() then 'trialing'
        when t.id is not null then 'expired'
        else 'none'
      end as provider_state
    from public.profiles p
    left join public.trials t on t.user_id = p.id
    left join lateral (
      select candidate.*
      from public.subscriptions candidate
      where candidate.user_id = p.id
      order by
        case when candidate.status in ('active', 'canceling_at_period_end', 'trialing') then 0 else 1 end,
        candidate.updated_at desc
      limit 1
    ) s on true
    left join public.plans pl on pl.id = s.plan_id
    left join lateral (
      select eo.access_granted
      from private.entitlement_overrides eo
      where eo.user_id = p.id
        and (eo.ends_at is null or eo.ends_at > now())
      order by eo.created_at desc
      limit 1
    ) ov on true
  ), filtered as (
    select * from access_rows
    where
      (coalesce(nullif(p_status, ''), 'all') = 'all'
        or provider_state = p_status
        or (p_status = 'canceling' and provider_state = 'canceling_at_period_end'))
      and (
        coalesce(nullif(p_plan, ''), 'all') = 'all'
        or (p_plan = 'monthly' and plan_interval = 'month')
        or (p_plan = 'yearly' and plan_interval = 'year')
        or plan_code = p_plan
      )
      and (
        coalesce(nullif(p_access, ''), 'all') = 'all'
        or access_status = p_access
      )
  ), counted as (
    select count(*)::integer as total from filtered
  ), page as (
    select * from filtered
    order by created_at desc, user_id desc
    limit least(greatest(coalesce(p_limit, 25), 1), 100)
    offset greatest(coalesce(p_offset, 0), 0)
  )
  select jsonb_build_object(
    'items', coalesce((select jsonb_agg(to_jsonb(page)) from page), '[]'::jsonb),
    'total', (select total from counted),
    'summary', jsonb_build_object(
      'activePaid', (
        select count(*)::integer from public.subscriptions s
        where s.status in ('active', 'canceling_at_period_end')
          and s.current_period_end > now()
      ),
      'monthlyActive', (
        select count(*)::integer
        from public.subscriptions s
        join public.plans pl on pl.id = s.plan_id
        where s.status in ('active', 'canceling_at_period_end')
          and s.current_period_end > now()
          and pl.interval = 'month'
      ),
      'yearlyActive', (
        select count(*)::integer
        from public.subscriptions s
        join public.plans pl on pl.id = s.plan_id
        where s.status in ('active', 'canceling_at_period_end')
          and s.current_period_end > now()
          and pl.interval = 'year'
      ),
      'cancelingAtPeriodEnd', (
        select count(*)::integer from public.subscriptions s
        where s.status = 'canceling_at_period_end' and s.current_period_end > now()
      ),
      'pastDue', (
        select count(*)::integer from public.subscriptions s
        where s.status = 'past_due'
      ),
      'inGrace', (
        select count(*)::integer from public.subscriptions s
        where s.status in ('past_due', 'grace_period')
          and s.grace_period_ends_at > now()
      )
    ),
    'nextCursor', case
      when greatest(coalesce(p_offset, 0), 0) + least(greatest(coalesce(p_limit, 25), 1), 100)
        < (select total from counted)
      then (greatest(coalesce(p_offset, 0), 0) + least(greatest(coalesce(p_limit, 25), 1), 100))::text
      else null
    end
  );
$$;

revoke all on function public.admin_grant_manual_subscription_v1(uuid, text, integer)
  from public, anon, authenticated;
revoke all on function public.admin_access_list_v1(text, text, text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.admin_grant_manual_subscription_v1(uuid, text, integer)
  to service_role;
grant execute on function public.admin_access_list_v1(text, text, text, integer, integer)
  to service_role;
