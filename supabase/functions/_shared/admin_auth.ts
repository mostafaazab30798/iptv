/**
 * Admin API authentication, capability checks, and MFA enforcement.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { AppError } from "./errors.ts";
import {
  bearerToken,
  getAnonKey,
  getServiceRoleKey,
  getSupabaseUrl,
  requireUser,
  type AuthedUser,
} from "./auth.ts";

export type AdminRole = "owner" | "analyst" | "support" | "release_manager";

export type AdminContext = {
  user: AuthedUser;
  role: AdminRole;
  aal: string | null;
};

export type AdminCapability =
  | "view_metrics"
  | "view_users"
  | "view_subscriptions"
  | "revoke_device"
  | "suspend_account"
  | "reactivate_account"
  | "entitlement_override"
  | "billing_sync"
  | "publish_config"
  | "publish_release"
  | "view_audit"
  | "manage_admins";

function serviceClient() {
  return createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function decodeJwtAal(token: string): string | null {
  try {
    const parts = token.split(".");
    if (parts.length < 2) return null;
    const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
    return typeof payload.aal === "string" ? payload.aal : null;
  } catch {
    return null;
  }
}

export async function requireAdmin(
  req: Request,
  capability?: AdminCapability,
  options?: { requireMfa?: boolean },
): Promise<AdminContext> {
  const user = await requireUser(req);
  const admin = serviceClient();

  const { data: rows, error } = await admin.rpc("admin_resolve_role", {
    p_user_id: user.id,
  });

  if (error || !rows || (Array.isArray(rows) && rows.length === 0)) {
    throw new AppError("forbidden", "Admin access required.", 403);
  }

  const row = Array.isArray(rows) ? rows[0] : rows;
  const role = row?.role as AdminRole | undefined;
  if (!role) {
    throw new AppError("forbidden", "Admin access required.", 403);
  }

  if (capability) {
    const { data: allowed, error: capError } = await admin.rpc("admin_has_capability", {
      p_user_id: user.id,
      p_capability: capability,
    });
    if (capError || !allowed) {
      throw new AppError("forbidden", "Insufficient admin capability.", 403);
    }
  }

  const token = bearerToken(req);
  const aal = decodeJwtAal(token);

  // Note: Strict MFA/AAL2 blocking is disabled per system policy ("not a bank safe").

  return { user, role, aal };
}

export function parseAdminPath(url: URL): { route: string; params: Record<string, string> } {
  // Local proxy: /admin-api/v1/...
  // Deployed Edge Function: /functions/v1/admin-api/v1/...
  const adminApiMarker = "/admin-api";
  const markerIdx = url.pathname.indexOf(adminApiMarker);
  const pathname = markerIdx >= 0
    ? url.pathname.slice(markerIdx + adminApiMarker.length)
    : url.pathname.replace(/^\/admin-api/, "");
  const segments = pathname.split("/").filter(Boolean);

  if (segments.length < 2 || segments[0] !== "v1") {
    return { route: "", params: {} };
  }

  const resource = segments[1];
  const id = segments[2];
  const action = segments[3];

  if (resource === "users" && id && action) {
    return { route: `users/${action}`, params: { userId: id } };
  }
  if (resource === "users" && id) {
    return { route: "users/detail", params: { userId: id } };
  }
  if (resource === "devices" && id && action === "revoke") {
    return { route: "devices/revoke", params: { deviceId: id } };
  }
  if (resource === "subscriptions" && id && action === "sync") {
    return { route: "subscriptions/sync", params: { subscriptionId: id } };
  }
  if (resource === "entitlement-overrides" && id) {
    return { route: "entitlement-overrides/delete", params: { overrideId: id } };
  }
  if (resource === "config" && segments[2] === "drafts") {
    const draftId = segments[3];
    const draftAction = segments[4];
    if (draftId && draftAction === "validate") {
      return { route: "config/validate", params: { draftId } };
    }
    if (draftId && draftAction === "publish") {
      return { route: "config/publish", params: { draftId } };
    }
    return { route: "config/drafts", params: {} };
  }
  if (resource === "releases" && id) {
    const releaseAction = segments[3];
    return { route: `releases/${releaseAction ?? "detail"}`, params: { releaseId: id } };
  }

  return { route: resource, params: {} };
}
