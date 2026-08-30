CREATE OR REPLACE FUNCTION public.admin_activity_v1(
  p_start_date date,
  p_end_date date,
  p_platform text DEFAULT 'all'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'analytics', 'public'
AS $$
DECLARE
  v_platform text := coalesce(nullif(p_platform, ''), 'all');
  v_items jsonb;
BEGIN
  SELECT coalesce(
    jsonb_agg(to_jsonb(t) ORDER BY t.metric_date, t.platform),
    '[]'::jsonb
  )
  INTO v_items
  FROM analytics.daily_account_activity t
  WHERE t.metric_date BETWEEN p_start_date AND p_end_date
    AND (v_platform = 'all' OR t.platform = v_platform);

  RETURN jsonb_build_object('items', coalesce(v_items, '[]'::jsonb));
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_downloads_v1(
  p_start_date date,
  p_end_date date,
  p_platform text DEFAULT 'all'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'analytics', 'public'
AS $$
DECLARE
  v_platform text := coalesce(nullif(p_platform, ''), 'all');
  v_items jsonb;
BEGIN
  SELECT coalesce(
    jsonb_agg(to_jsonb(t) ORDER BY t.metric_date, t.platform),
    '[]'::jsonb
  )
  INTO v_items
  FROM analytics.daily_download_metrics t
  WHERE t.metric_date BETWEEN p_start_date AND p_end_date
    AND (v_platform = 'all' OR t.platform = v_platform);

  RETURN jsonb_build_object('items', coalesce(v_items, '[]'::jsonb));
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_activity_v1(date, date, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.admin_downloads_v1(date, date, text) TO service_role;;
