import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import {
  getServiceRoleKey,
  getSupabaseUrl,
  requireUser,
} from "../_shared/auth.ts";
import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import { InMemoryRateLimiter, optionalString, readJsonObject } from "../_shared/validation.ts";

const limiter = new InMemoryRateLimiter();

Deno.serve(async (req) => {
  const correlationId = correlationIdFrom(req);
  const headers = corsHeaders(req.headers.get("Origin"));

  try {
    const preflight = handleOptions(req);
    if (preflight) return preflight;

    if (req.method !== "POST") {
      throw new AppError("method_not_allowed", "Use POST.", 405);
    }

    const user = await requireUser(req);
    await limiter.check(`heartbeat:${user.id}`, 40, 60_000);

    const body = await readJsonObject(req);
    const deviceId = optionalString(body, "deviceId");
    const sessionId = optionalString(body, "sessionId");
    const platform = optionalString(body, "platform");
    const appVersion = optionalString(body, "appVersion");
    const installationIdHash = optionalString(body, "installationIdHash");
    const meaningful = body.meaningful === true;

    if (!deviceId) {
      throw new AppError("validation_error", "deviceId is required.", 400);
    }

    const admin = createClient(getSupabaseUrl(), getServiceRoleKey(), {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: device } = await admin
      .from("devices")
      .select("id, revoked_at, installation_id")
      .eq("id", deviceId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (!device || device.revoked_at) {
      throw new AppError("device_not_found", "Device not found or revoked.", 404);
    }

    const now = new Date().toISOString();
    let activeSessionId = sessionId;

    if (sessionId) {
      await admin
        .schema("analytics")
        .from("app_sessions")
        .update({ last_heartbeat_at: now })
        .eq("id", sessionId)
        .eq("user_id", user.id);
    } else {
      const { data: created } = await admin
        .schema("analytics")
        .from("app_sessions")
        .insert({
          user_id: user.id,
          device_id: deviceId,
          installation_id: device.installation_id,
          platform: platform ?? null,
          app_version: appVersion ?? null,
          started_at: now,
          last_heartbeat_at: now,
        })
        .select("id")
        .single();
      activeSessionId = created?.id;
    }

    await admin
      .from("devices")
      .update({ last_seen_at: now })
      .eq("id", deviceId);

    if (meaningful) {
      await admin
        .schema("analytics")
        .from("analytics_events")
        .upsert({
          event_id: crypto.randomUUID(),
          event_name: "session_heartbeat",
          schema_version: 1,
          occurred_at: now,
          user_id: user.id,
          installation_id_hash: installationIdHash ?? null,
          platform: platform ?? null,
          app_version: appVersion ?? null,
          properties: { foreground: true },
        }, { onConflict: "event_id", ignoreDuplicates: true });
    }

    logInfo(correlationId, "session_heartbeat", { deviceId, meaningful });

    return jsonOk(
      {
        schemaVersion: 1,
        sessionId: activeSessionId,
        receivedAt: now,
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
