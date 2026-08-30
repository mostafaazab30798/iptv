CREATE OR REPLACE FUNCTION public.admin_audit_list_v1(
  p_limit integer DEFAULT 100,
  p_cursor timestamptz DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'private', 'public'
AS $$
DECLARE
  v_items jsonb;
  v_total integer;
BEGIN
  SELECT count(*)::integer INTO v_total FROM private.audit_logs;

  SELECT coalesce(
    jsonb_agg(to_jsonb(t) ORDER BY t.created_at DESC),
    '[]'::jsonb
  )
  INTO v_items
  FROM (
    SELECT
      id,
      actor,
      action,
      target_type,
      target_id,
      reason,
      created_at,
      correlation_id
    FROM private.audit_logs
    WHERE p_cursor IS NULL OR created_at < p_cursor
    ORDER BY created_at DESC
    LIMIT greatest(1, least(coalesce(p_limit, 100), 100))
  ) t;

  RETURN jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'total', coalesce(v_total, 0),
    'cursor', null
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_audit_list_v1(integer, timestamptz) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_audit_list_v1(integer, timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_audit_list_v1(integer, timestamptz) TO anon;;
