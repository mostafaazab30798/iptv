-- Deterministic metric fixtures for Phase 5 reporting.
-- Expected values (UTC day 2026-08-28, platform=all after aggregate_daily_metrics):
--   download_authorized = 2
--   download_requested = 1
--   completed_transfer = 0
--   new_installations (android+windows on that day) = 2
--   dau = 2 (users with meaningful session_started)
--   waea = 1 (user_a active on two days while entitled)
--
-- Run after migrations with service_role / postgres. Requires auth.users rows
-- or FK-compatible profile inserts in a full Supabase environment.

-- This file documents expected assertions for CI once auth users exist.
-- Lightweight structural checks below work without auth.users inserts.

begin;

do $$
begin
  if to_regclass('analytics.daily_account_activity') is null then
    raise exception 'daily_account_activity missing — run Phase 5 migration first';
  end if;
  if to_regclass('private.admin_users') is null then
    raise exception 'admin_users missing — run Phase 5 migration first';
  end if;
  if to_regprocedure('public.admin_overview_v1(date, date, text)') is null then
    raise exception 'admin_overview_v1 missing';
  end if;
  if to_regprocedure('public.admin_has_capability(uuid, text)') is null then
    raise exception 'admin_has_capability missing';
  end if;
end $$;

-- Capability matrix smoke (synthetic uuid, no admin row => false)
do $$
declare
  v_allowed boolean;
begin
  select public.admin_has_capability(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid,
    'view_metrics'
  ) into v_allowed;
  if v_allowed then
    raise exception 'non-admin must not have view_metrics';
  end if;
end $$;

select 'phase5_fixture_structure_ok' as status;

commit;
