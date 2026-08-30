import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import {
  bearerToken,
  getAnonKey,
  getServiceRoleKey,
  getSupabaseUrl,
  requireUser,
} from "../_shared/auth.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import {
  optionalString,
  readJsonObject,
  requireString,
} from "../_shared/validation.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const DEVICE_LIMIT = Number(Deno.env.get("DEVICE_LIMIT") ?? "3");

function userClient(req: Request) {
  return createClient(getSupabaseUrl(), getAnonKey(), {
    global: { headers: { Authorization: `Bearer ${bearerToken(req)}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function serviceClient() {
  return createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

Deno.serve(async (req) => {
  const correlationId = correlationIdFrom(req);
  const headers = corsHeaders(req.headers.get("Origin"));

  try {
    const preflight = handleOptions(req);
    if (preflight) return preflight;

    const user = await requireUser(req);

    if (req.method === "GET") {
      const client = userClient(req);
      const { data, error } = await client
        .from("devices")
        .select(
          "id, display_name, platform, app_version, os_version_category, first_seen_at, last_seen_at, revoked_at",
        )
        .eq("user_id", user.id)
        .order("last_seen_at", { ascending: false });

      if (error) {
        throw new AppError("devices_read_failed", "Unable to list devices.", 500);
      }

      return jsonOk(
        {
          schemaVersion: 1,
          deviceLimit: DEVICE_LIMIT,
          devices: (data ?? []).map(mapDevice),
        },
        correlationId,
        200,
        headers,
      );
    }

    if (req.method === "POST") {
      const body = await readJsonObject(req);
      const action = optionalString(body, "action") ?? "register";

      if (action === "revoke") {
        const deviceId = requireString(body, "deviceId");
        const client = userClient(req);
        const { data, error } = await client
          .from("devices")
          .update({ revoked_at: new Date().toISOString() })
          .eq("id", deviceId)
          .eq("user_id", user.id)
          .is("revoked_at", null)
          .select("id")
          .maybeSingle();

        if (error) {
          throw new AppError("device_revoke_failed", "Unable to revoke device.", 500);
        }
        if (!data) {
          throw new AppError("device_not_found", "Device not found.", 404);
        }

        logInfo(correlationId, "device_revoked", { userId: user.id });
        return jsonOk(
          { schemaVersion: 1, revoked: true, deviceId },
          correlationId,
          200,
          headers,
        );
      }

      if (action === "rename") {
        const deviceId = requireString(body, "deviceId");
        const displayName = requireString(body, "displayName");
        const client = userClient(req);
        const { data, error } = await client
          .from("devices")
          .update({ display_name: displayName })
          .eq("id", deviceId)
          .eq("user_id", user.id)
          .select("id, display_name")
          .maybeSingle();

        if (error) {
          throw new AppError("device_update_failed", "Unable to update device.", 500);
        }
        if (!data) {
          throw new AppError("device_not_found", "Device not found.", 404);
        }

        return jsonOk(
          {
            schemaVersion: 1,
            device: { id: data.id, displayName: data.display_name },
          },
          correlationId,
          200,
          headers,
        );
      }

      // register (default)
      const installationIdHash = requireString(body, "installationIdHash");
      const platform = requireString(body, "platform");
      if (!["android", "windows", "web", "unknown"].includes(platform)) {
        throw new AppError("validation_error", "Invalid platform.", 400);
      }
      const displayName = optionalString(body, "displayName") ?? `${platform} device`;
      const appVersion = optionalString(body, "appVersion");
      const osVersionCategory = optionalString(body, "osVersionCategory");

      const admin = serviceClient();

      const { data: installation, error: instErr } = await admin
        .from("installations")
        .upsert(
          {
            installation_id_hash: installationIdHash,
            platform,
            app_version: appVersion,
            os_version_category: osVersionCategory,
            last_seen_at: new Date().toISOString(),
          },
          { onConflict: "installation_id_hash" },
        )
        .select("id")
        .single();

      if (instErr || !installation) {
        throw new AppError(
          "installation_upsert_failed",
          "Unable to register installation.",
          500,
        );
      }

      const { data: existing } = await admin
        .from("devices")
        .select("id, revoked_at")
        .eq("user_id", user.id)
        .eq("installation_id", installation.id)
        .maybeSingle();

      if (existing && !existing.revoked_at) {
        await admin
          .from("devices")
          .update({
            display_name: displayName,
            app_version: appVersion,
            os_version_category: osVersionCategory,
            last_seen_at: new Date().toISOString(),
          })
          .eq("id", existing.id);

        logInfo(correlationId, "device_refreshed", { userId: user.id });
        return jsonOk(
          { schemaVersion: 1, deviceId: existing.id, created: false },
          correlationId,
          200,
          headers,
        );
      }

      const { count, error: countErr } = await admin
        .from("devices")
        .select("id", { count: "exact", head: true })
        .eq("user_id", user.id)
        .is("revoked_at", null);

      if (countErr) {
        throw new AppError(
          "device_limit_check_failed",
          "Unable to check device limit.",
          500,
        );
      }
      if ((count ?? 0) >= DEVICE_LIMIT) {
        throw new AppError(
          "device_limit_reached",
          "Device limit reached. Revoke an old device to continue.",
          409,
          { deviceLimit: DEVICE_LIMIT },
        );
      }

      const { data: created, error: createErr } = await admin
        .from("devices")
        .insert({
          user_id: user.id,
          installation_id: installation.id,
          display_name: displayName,
          platform,
          app_version: appVersion,
          os_version_category: osVersionCategory,
        })
        .select("id")
        .single();

      if (createErr || !created) {
        throw new AppError("device_create_failed", "Unable to register device.", 500);
      }

      logInfo(correlationId, "device_registered", { userId: user.id });
      return jsonOk(
        { schemaVersion: 1, deviceId: created.id, created: true },
        correlationId,
        201,
        headers,
      );
    }

    throw new AppError("method_not_allowed", "Use GET or POST.", 405);
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});

function mapDevice(row: Record<string, unknown>) {
  return {
    id: row.id,
    displayName: row.display_name,
    platform: row.platform,
    appVersion: row.app_version,
    osVersionCategory: row.os_version_category,
    firstSeenAt: row.first_seen_at,
    lastSeenAt: row.last_seen_at,
    revokedAt: row.revoked_at,
  };
}
