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
import { optionalString, readJsonObject, requireString } from "../_shared/validation.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const TRIAL_DAYS = Number(Deno.env.get("TRIAL_DURATION_DAYS") ?? "7");

function serviceClient() {
  return createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function userClient(req: Request) {
  return createClient(getSupabaseUrl(), getAnonKey(), {
    global: { headers: { Authorization: `Bearer ${bearerToken(req)}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

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
    const body = await readJsonObject(req);
    const idempotencyKey = requireString(body, "idempotencyKey");
    const deviceId = requireString(body, "deviceId");
    const platform = optionalString(body, "platform") ?? "unknown";
    // Credential-free signal only — never accept IPTV URLs/passwords.
    const event = optionalString(body, "event") ?? "iptv_connection_succeeded";
    if (event !== "iptv_connection_succeeded") {
      throw new AppError("validation_error", "Unsupported activation event.", 400);
    }

    const admin = serviceClient();

    // Idempotency
    const { data: existingKey } = await admin
      .schema("private")
      .from("idempotency_keys")
      .select("id, response_hash")
      .eq("scope", "trial_activate")
      .eq("idempotency_key", idempotencyKey)
      .maybeSingle();

    if (existingKey?.response_hash) {
      try {
        const cached = JSON.parse(existingKey.response_hash);
        return jsonOk(cached, correlationId, 200, headers);
      } catch {
        // fall through and recompute
      }
    }

    // Verify device belongs to user and is active
    const userDb = userClient(req);
    const { data: device, error: deviceErr } = await userDb
      .from("devices")
      .select("id, revoked_at")
      .eq("id", deviceId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (deviceErr || !device || device.revoked_at) {
      throw new AppError("device_invalid", "Active device required for trial.", 403);
    }

    const { data: profile } = await admin
      .from("profiles")
      .select("status")
      .eq("id", user.id)
      .maybeSingle();

    if (!profile || profile.status !== "active") {
      throw new AppError("account_inactive", "Account cannot activate a trial.", 403);
    }

    const { data: existingTrial } = await admin
      .from("trials")
      .select("id, status, started_at, ends_at, duration_days_snapshot")
      .eq("user_id", user.id)
      .maybeSingle();

    const now = new Date();
    let trialRow = existingTrial;

    if (!existingTrial) {
      const ends = new Date(now.getTime() + TRIAL_DAYS * 86400000);
      const { data: created, error } = await admin
        .from("trials")
        .insert({
          user_id: user.id,
          status: "active",
          started_at: now.toISOString(),
          ends_at: ends.toISOString(),
          duration_days_snapshot: TRIAL_DAYS,
          activation_platform: platform,
          activated_by_event_id: idempotencyKey,
        })
        .select("id, status, started_at, ends_at, duration_days_snapshot")
        .single();

      if (error || !created) {
        // Unique race: load existing
        const { data: raced } = await admin
          .from("trials")
          .select("id, status, started_at, ends_at, duration_days_snapshot")
          .eq("user_id", user.id)
          .maybeSingle();
        if (!raced) {
          throw new AppError("trial_create_failed", "Unable to activate trial.", 500);
        }
        trialRow = raced;
      } else {
        trialRow = created;
      }
    } else if (existingTrial.status === "pending") {
      const ends = new Date(now.getTime() + TRIAL_DAYS * 86400000);
      const { data: updated, error } = await admin
        .from("trials")
        .update({
          status: "active",
          started_at: now.toISOString(),
          ends_at: ends.toISOString(),
          duration_days_snapshot: TRIAL_DAYS,
          activation_platform: platform,
          activated_by_event_id: idempotencyKey,
          updated_at: now.toISOString(),
        })
        .eq("user_id", user.id)
        .select("id, status, started_at, ends_at, duration_days_snapshot")
        .single();
      if (error || !updated) {
        throw new AppError("trial_activate_failed", "Unable to activate trial.", 500);
      }
      trialRow = updated;
    }
    // If already active/expired/revoked: do not extend or reset.

    const responseBody = {
      schemaVersion: 1,
      created: !existingTrial || existingTrial.status === "pending",
      trial: {
        status: trialRow!.status,
        startedAt: trialRow!.started_at,
        endsAt: trialRow!.ends_at,
        durationDays: trialRow!.duration_days_snapshot,
      },
    };

    await admin.schema("private").from("idempotency_keys").upsert(
      {
        scope: "trial_activate",
        idempotency_key: idempotencyKey,
        user_id: user.id,
        response_hash: JSON.stringify(responseBody),
      },
      { onConflict: "scope,idempotency_key" },
    );

    logInfo(correlationId, "trial_activate", {
      userId: user.id,
      created: responseBody.created,
    });

    return jsonOk(responseBody, correlationId, 200, headers);
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
