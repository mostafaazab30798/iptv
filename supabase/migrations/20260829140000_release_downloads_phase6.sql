-- Phase 6: Direct downloads and secure updates
-- Atomic download-token consumption and release lookup helpers.

create or replace function private.consume_download_token(p_token_id uuid)
returns table (
  ok boolean,
  error_code text,
  object_key text,
  release_id uuid,
  user_id uuid
)
language plpgsql
security definer
set search_path = private, public
as $$
declare
  v_row private.download_tokens%rowtype;
begin
  select * into v_row
  from private.download_tokens
  where id = p_token_id
  for update;

  if not found then
    return query select false, 'token_not_found', null::text, null::uuid, null::uuid;
    return;
  end if;

  if v_row.consumed_at is not null or v_row.use_count >= v_row.max_uses then
    return query select false, 'token_already_used', null::text, null::uuid, null::uuid;
    return;
  end if;

  if v_row.expires_at <= timezone('utc', now()) then
    return query select false, 'token_expired', null::text, null::uuid, null::uuid;
    return;
  end if;

  if not exists (
    select 1 from public.release_versions rv
    where rv.id = v_row.release_id
      and rv.published_at is not null
      and rv.revoked_at is null
  ) then
    return query select false, 'release_unavailable', null::text, null::uuid, null::uuid;
    return;
  end if;

  update private.download_tokens
  set
    use_count = use_count + 1,
    consumed_at = case
      when use_count + 1 >= max_uses then timezone('utc', now())
      else consumed_at
    end
  where id = p_token_id;

  return query
  select
    true,
    null::text,
    rv.object_key,
    v_row.release_id,
    v_row.user_id
  from public.release_versions rv
  where rv.id = v_row.release_id
    and rv.published_at is not null
    and rv.revoked_at is null;
end;
$$;

create or replace function public.latest_release_for_platform(
  p_platform text,
  p_channel text default 'stable',
  p_architecture text default 'universal'
)
returns setof public.release_versions
language sql
stable
security definer
set search_path = public
as $$
  select *
  from public.release_versions rv
  where rv.platform = p_platform
    and rv.channel = p_channel
    and rv.architecture = p_architecture
    and rv.published_at is not null
    and rv.revoked_at is null
  order by rv.build_number desc, rv.published_at desc
  limit 1;
$$;

revoke all on function private.consume_download_token(uuid) from public, anon, authenticated;
revoke all on function public.latest_release_for_platform(text, text, text) from public, anon, authenticated;

grant execute on function private.consume_download_token(uuid) to service_role;
grant execute on function public.latest_release_for_platform(text, text, text) to service_role, anon, authenticated;

-- PostgREST-exposed wrapper for gateway consumption
create or replace function public.consume_download_token(p_token_id uuid)
returns table (
  ok boolean,
  error_code text,
  object_key text,
  release_id uuid,
  user_id uuid
)
language sql
security definer
set search_path = private, public
as $$
  select * from private.consume_download_token(p_token_id);
$$;

revoke all on function public.consume_download_token(uuid) from public, anon, authenticated;
grant execute on function public.consume_download_token(uuid) to service_role;
