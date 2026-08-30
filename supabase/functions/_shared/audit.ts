/**
 * Append-only admin audit logging.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { getServiceRoleKey, getSupabaseUrl } from "./auth.ts";
import { logInfo } from "./logging.ts";

export async function appendAudit(params: {
  actor: string;
  action: string;
  targetType?: string;
  targetId?: string;
  reason?: string;
  beforeState?: Record<string, unknown>;
  afterState?: Record<string, unknown>;
  correlationId: string;
}): Promise<void> {
  const client = createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error } = await client.rpc("admin_append_audit", {
    p_actor: params.actor,
    p_action: params.action,
    p_target_type: params.targetType ?? null,
    p_target_id: params.targetId ?? null,
    p_reason: params.reason ?? null,
    p_before_state: params.beforeState ?? null,
    p_after_state: params.afterState ?? null,
    p_correlation_id: params.correlationId,
  });

  if (error) {
    logInfo(params.correlationId, "audit_append_failed", {
      action: params.action,
      message: error.message,
    });
  }
}
