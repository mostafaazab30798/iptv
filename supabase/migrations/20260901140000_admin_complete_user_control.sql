-- Complete owner controls for customer lifecycle and manual access.
-- All RPCs are service-role only and every destructive mutation is audited.

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
  from public.admin_resolve_role(p_user_id);

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
    when 'delete_user' then v_role = 'owner'
    when 'publish_config' then v_role = 'owner'
    when 'publish_release' then v_role in ('owner', 'release_manager')
    when 'view_audit' then v_role in ('owner', 'analyst')
    when 'manage_admins' then v_role = 'owner'
    else false
  end;
end;
$$;

create or replace function public.admin_cancel_manual_subscription_v1(
  p_user_id uuid,
  p_immediate boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_subscription public.subscriptions%rowtype;
begin
  select * into v_subscription
  from public.subscriptions
  where user_id = p_user_id and provider = 'manual'
  for update;

  if v_subscription.id is null then
    raise exception 'manual_subscription_not_found';
  end if;

  if p_immediate then
    update public.subscriptions
    set
      status = 'expired',
      current_period_end = least(
        coalesce(current_period_end, timezone('utc', now())),
        timezone('utc', now())
      ),
      grace_period_ends_at = null,
      cancel_at_period_end = false,
      updated_at = timezone('utc', now())
    where id = v_subscription.id
    returning * into v_subscription;
  else
    update public.subscriptions
    set
      status = 'canceling_at_period_end',
      cancel_at_period_end = true,
      updated_at = timezone('utc', now())
    where id = v_subscription.id
    returning * into v_subscription;
  end if;

  return jsonb_build_object(
    'id', v_subscription.id,
    'user_id', v_subscription.user_id,
    'provider', v_subscription.provider,
    'status', v_subscription.status,
    'current_period_end', v_subscription.current_period_end,
    'cancel_at_period_end', v_subscription.cancel_at_period_end,
    'updated_at', v_subscription.updated_at
  );
end;
$$;

create or replace function public.admin_revoke_trial_v1(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_trial public.trials%rowtype;
begin
  update public.trials
  set status = 'revoked', updated_at = timezone('utc', now())
  where user_id = p_user_id and status <> 'revoked'
  returning * into v_trial;

  if v_trial.id is null then
    raise exception 'revocable_trial_not_found';
  end if;

  return jsonb_build_object(
    'id', v_trial.id,
    'user_id', v_trial.user_id,
    'status', v_trial.status,
    'started_at', v_trial.started_at,
    'ends_at', v_trial.ends_at,
    'updated_at', v_trial.updated_at
  );
end;
$$;

create or replace function public.admin_delete_user_v1(
  p_user_id uuid,
  p_actor_id uuid,
  p_reason text,
  p_correlation_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = analytics, private, public, auth
as $$
declare
  v_email text;
  v_target_hash text;
begin
  if p_actor_id = p_user_id then
    raise exception 'owner_cannot_delete_self';
  end if;

  if length(trim(coalesce(p_reason, ''))) < 10 then
    raise exception 'deletion_reason_too_short';
  end if;

  if exists (select 1 from private.admin_users where user_id = p_user_id) then
    raise exception 'admin_account_deletion_forbidden';
  end if;

  select email_normalized into v_email
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception 'user_not_found';
  end if;

  v_target_hash := left(
    encode(digest(p_user_id::text || ':' || coalesce(v_email, ''), 'sha256'), 'hex'),
    24
  );

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

  delete from private.download_tokens where user_id = p_user_id;
  delete from private.idempotency_keys where user_id = p_user_id;
  delete from private.entitlement_overrides where user_id = p_user_id;
  delete from public.device_pairing_codes where user_id = p_user_id;
  delete from public.account_deletion_requests where user_id = p_user_id;
  delete from public.subscriptions where user_id = p_user_id;
  delete from private.billing_customers where user_id = p_user_id;
  delete from public.trials where user_id = p_user_id;
  delete from public.devices where user_id = p_user_id;
  delete from public.profiles where id = p_user_id;
  delete from auth.users where id = p_user_id;

  perform public.admin_append_audit(
    p_actor_id::text,
    'user.delete.permanent',
    'profile_hash',
    v_target_hash,
    p_reason,
    jsonb_build_object('status', 'existing'),
    jsonb_build_object('status', 'deleted', 'piiRedacted', true),
    p_correlation_id
  );

  return jsonb_build_object(
    'deleted', true,
    'target_hash', v_target_hash,
    'deleted_at', timezone('utc', now())
  );
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
      'updatedAt', v_profile.updated_at,
      'lastLoginAt', v_profile.last_login_at
    ),
    'trial', (
      select row_to_json(t) from (
        select id, status, started_at, ends_at, duration_days_snapshot,
               activation_platform, updated_at
        from public.trials where user_id = p_user_id
      ) t
    ),
    'subscription', (
      select row_to_json(s) from (
        select s.id, s.plan_id, p.code as plan_code, s.status,
               s.current_period_end, s.grace_period_ends_at,
               s.cancel_at_period_end, s.provider,
               s.provider_subscription_id, s.updated_at
        from public.subscriptions s
        left join public.plans p on p.id = s.plan_id
        where s.user_id = p_user_id
        order by s.updated_at desc limit 1
      ) s
    ),
    'devices', (
      select coalesce(jsonb_agg(row_to_json(d)), '[]'::jsonb) from (
        select id, display_name, platform, app_version, first_seen_at,
               last_seen_at, revoked_at
        from public.devices where user_id = p_user_id
        order by last_seen_at desc
      ) d
    ),
    'overrides', (
      select coalesce(jsonb_agg(row_to_json(o)), '[]'::jsonb) from (
        select id, access_granted, ends_at, reason, created_at
        from private.entitlement_overrides
        where user_id = p_user_id
        order by created_at desc
        limit 20
      ) o
    ),
    'activity', jsonb_build_object(
      'sessions7d', (
        select count(*)::integer from analytics.app_sessions
        where user_id = p_user_id
          and started_at >= timezone('utc', now()) - interval '7 days'
      ),
      'sessions30d', (
        select count(*)::integer from analytics.app_sessions
        where user_id = p_user_id
          and started_at >= timezone('utc', now()) - interval '30 days'
      ),
      'activeDays7d', (
        select count(distinct started_at::date)::integer
        from analytics.app_sessions
        where user_id = p_user_id
          and started_at >= timezone('utc', now()) - interval '7 days'
      )
    ),
    'downloadsRequested', (
      select count(*)::integer from analytics.download_events
      where user_id = p_user_id
        and event_name in ('download_authorized', 'release_download_requested')
    )
  ) into v_result;

  return v_result;
end;
$$;

revoke all on function public.admin_has_capability(uuid, text) from public, anon, authenticated;
revoke all on function public.admin_cancel_manual_subscription_v1(uuid, boolean) from public, anon, authenticated;
revoke all on function public.admin_revoke_trial_v1(uuid) from public, anon, authenticated;
revoke all on function public.admin_delete_user_v1(uuid, uuid, text, text) from public, anon, authenticated;
revoke all on function public.admin_user_detail_v1(uuid) from public, anon, authenticated;

grant execute on function public.admin_has_capability(uuid, text) to service_role;
grant execute on function public.admin_cancel_manual_subscription_v1(uuid, boolean) to service_role;
grant execute on function public.admin_revoke_trial_v1(uuid) to service_role;
grant execute on function public.admin_delete_user_v1(uuid, uuid, text, text) to service_role;
grant execute on function public.admin_user_detail_v1(uuid) to service_role;
