-- pgcrypto is installed in Supabase's extensions schema. Both deletion
-- functions hash identifiers for anonymized audit/analytics records, so keep
-- that trusted schema ahead of application schemas during function execution.

alter function public.finalize_account_deletion_v1(uuid, text)
  set search_path = extensions, analytics, private, public, pg_temp;

alter function public.admin_delete_user_v1(uuid, uuid, text, text)
  set search_path = extensions, analytics, private, public, auth, pg_temp;
