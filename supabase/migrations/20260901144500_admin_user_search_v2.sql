-- Real, filterable and pageable user directory for the owner dashboard.

create or replace function public.admin_user_search_v2(
  p_query text default null,
  p_account_status text default null,
  p_access text default null,
  p_plan text default null,
  p_limit integer default 25,
  p_offset integer default 0
)
returns jsonb
language sql
stable
security definer
set search_path = extensions, private, public, pg_temp
as $$
  with directory as (
    select
      p.id,
      case
        when length(coalesce(p.email_normalized, '')) > 3 then
          left(p.email_normalized, 2) || '***' ||
          substring(p.email_normalized from position('@' in p.email_normalized))
        else '***'
      end as email_normalized,
      p.status,
      p.created_at,
      p.updated_at,
      p.last_login_at,
      case when t.id is null then null else jsonb_build_object(
        'id', t.id,
        'status', t.status,
        'started_at', t.started_at,
        'ends_at', t.ends_at,
        'duration_days_snapshot', t.duration_days_snapshot,
        'activation_platform', t.activation_platform
      ) end as trial,
      case when s.id is null then null else jsonb_build_object(
        'id', s.id,
        'plan_id', s.plan_id,
        'plan_code', pl.code,
        'provider', s.provider,
        'provider_subscription_id', s.provider_subscription_id,
        'status', s.status,
        'current_period_end', s.current_period_end,
        'grace_period_ends_at', s.grace_period_ends_at,
        'cancel_at_period_end', s.cancel_at_period_end,
        'updated_at', s.updated_at
      ) end as subscription,
      coalesce(dev.devices, '[]'::jsonb) as devices,
      coalesce(ov.overrides, '[]'::jsonb) as overrides,
      pl.code as plan_code,
      case
        when p.status <> 'active' then 'expired'
        when ov.access_granted = true then 'complimentary'
        when s.status in ('active', 'canceling_at_period_end')
          and s.current_period_end > now() then 'paid'
        when s.status in ('past_due', 'grace_period')
          and s.grace_period_ends_at > now() then 'grace'
        when t.status = 'active' and t.ends_at > now() then 'trial'
        when t.id is null and s.id is null then 'none'
        else 'expired'
      end as access_status
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
      select
        bool_or(eo.access_granted) as access_granted,
        jsonb_agg(jsonb_build_object(
          'id', eo.id,
          'access_granted', eo.access_granted,
          'ends_at', eo.ends_at,
          'reason', eo.reason,
          'created_at', eo.created_at
        ) order by eo.created_at desc) as overrides
      from private.entitlement_overrides eo
      where eo.user_id = p.id
        and (eo.ends_at is null or eo.ends_at > now())
    ) ov on true
    left join lateral (
      select jsonb_agg(jsonb_build_object(
        'id', d.id,
        'display_name', d.display_name,
        'platform', d.platform,
        'app_version', d.app_version,
        'first_seen_at', d.first_seen_at,
        'last_seen_at', d.last_seen_at,
        'revoked_at', d.revoked_at
      ) order by d.last_seen_at desc) as devices
      from public.devices d
      where d.user_id = p.id
    ) dev on true
    where
      (p_query is null or p_query = '' or p.id::text = p_query
        or (length(p_query) >= 3 and p.email_normalized ilike p_query || '%'))
  ), filtered as (
    select * from directory
    where (coalesce(nullif(p_account_status, ''), 'all') = 'all'
        or status = p_account_status)
      and (coalesce(nullif(p_access, ''), 'all') = 'all'
        or access_status = p_access)
      and (coalesce(nullif(p_plan, ''), 'all') = 'all'
        or plan_code = p_plan)
  ), counted as (
    select count(*)::integer as total from filtered
  ), page as (
    select * from filtered
    order by created_at desc, id desc
    limit least(greatest(coalesce(p_limit, 25), 1), 100)
    offset greatest(coalesce(p_offset, 0), 0)
  )
  select jsonb_build_object(
    'users', coalesce((
      select jsonb_agg(
        to_jsonb(page) - 'access_status' - 'plan_code'
        order by created_at desc, id desc
      ) from page
    ), '[]'::jsonb),
    'total', (select total from counted),
    'nextCursor', case
      when greatest(coalesce(p_offset, 0), 0) +
        least(greatest(coalesce(p_limit, 25), 1), 100) < (select total from counted)
      then (greatest(coalesce(p_offset, 0), 0) +
        least(greatest(coalesce(p_limit, 25), 1), 100))::text
      else null
    end
  );
$$;

revoke all on function public.admin_user_search_v2(text, text, text, text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.admin_user_search_v2(text, text, text, text, integer, integer)
  to service_role;
