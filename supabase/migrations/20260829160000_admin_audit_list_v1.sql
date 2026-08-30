-- Audit log listing for admin-api (private.audit_logs is not PostgREST-exposed).

create or replace function public.admin_audit_list_v1(
  p_limit integer default 100,
  p_cursor timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = private, public
as $$
declare
  v_items jsonb;
  v_total integer;
  v_next_cursor timestamptz;
  v_limit integer := greatest(1, least(coalesce(p_limit, 100), 100));
begin
  select count(*)::integer into v_total from private.audit_logs;

  select coalesce(
    jsonb_agg(to_jsonb(t) order by t.created_at desc),
    '[]'::jsonb
  )
  into v_items
  from (
    select
      id,
      actor,
      action,
      target_type,
      target_id,
      reason,
      created_at,
      correlation_id
    from private.audit_logs
    where p_cursor is null or created_at < p_cursor
    order by created_at desc
    limit v_limit
  ) t;

  select min((row.created_at)::timestamptz)
  into v_next_cursor
  from jsonb_to_recordset(coalesce(v_items, '[]'::jsonb)) as row(created_at timestamptz);

  return jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'total', coalesce(v_total, 0),
    'cursor', case
      when jsonb_array_length(coalesce(v_items, '[]'::jsonb)) < v_limit then null
      else to_jsonb(v_next_cursor)
    end
  );
end;
$$;

revoke all on function public.admin_audit_list_v1(integer, timestamptz) from public, anon, authenticated;
grant execute on function public.admin_audit_list_v1(integer, timestamptz) to service_role;
