CREATE OR REPLACE FUNCTION public.admin_has_capability(p_user_id uuid, p_capability text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'private', 'public'
AS $function$
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
    when 'publish_config' then v_role = 'owner'
    when 'publish_release' then v_role in ('owner', 'release_manager')
    when 'view_audit' then v_role in ('owner', 'analyst')
    when 'manage_admins' then v_role = 'owner'
    else false
  end;
end;
$function$;;
