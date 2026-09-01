-- The production admin API now uses v2, which implements all filters and
-- deterministic offset pagination. Remove the incomplete cursor-ignoring RPC.

drop function if exists public.admin_user_search_v1(text, text, integer, text);
