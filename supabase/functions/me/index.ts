import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { getServiceRoleKey, requireUser } from "../_shared/auth.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { getSupabaseUrl } from "../_shared/auth.ts";

const configuredTrialDays = Number(Deno.env.get("TRIAL_DURATION_DAYS") ?? "7");
const TRIAL_DAYS = Number.isInteger(configuredTrialDays) &&
    configuredTrialDays > 0 && configuredTrialDays <= 365
  ? configuredTrialDays
  : 7;

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
    if (req.method !== "GET") {
      throw new AppError("method_not_allowed", "Use GET.", 405);
    }

    const user = await requireUser(req);
    const admin = serviceClient();
    const now = new Date();

    // Self-heal accounts created while the profile trigger was missing or an
    // older migration was deployed. Never overwrite an existing status.
    const { error: profileProvisionError } = await admin.from("profiles")
      .upsert(
        {
          id: user.id,
          email_normalized: user.email?.trim().toLowerCase() ?? null,
          status: "active",
          last_login_at: now.toISOString(),
          updated_at: now.toISOString(),
        },
        { onConflict: "id", ignoreDuplicates: true },
      );
    if (profileProvisionError) {
      throw new AppError(
        "profile_provision_failed",
        "Unable to provision account profile.",
        500,
      );
    }

    const { data: profile, error } = await admin
      .from("profiles")
      .select("id, status, created_at, updated_at, last_login_at")
      .eq("id", user.id)
      .maybeSingle();

    if (error) {
      throw new AppError("profile_read_failed", "Unable to load profile.", 500);
    }
    if (!profile) {
      throw new AppError("profile_missing", "Profile not found.", 500);
    }

    // `me` is called only with a verified Supabase session. Provision the
    // immutable, one-time trial here so OTP verification is the activation
    // boundary. A repeated login/open can observe the same trial but can never
    // reset or extend it.
    const endsAt = new Date(now.getTime() + TRIAL_DAYS * 86_400_000);
    const { error: trialError } = await admin.from("trials").upsert(
      {
        user_id: user.id,
        status: "active",
        started_at: now.toISOString(),
        ends_at: endsAt.toISOString(),
        duration_days_snapshot: TRIAL_DAYS,
        activation_platform: "unknown",
        activated_by_event_id: `email_otp_verified:${user.id}`,
        updated_at: now.toISOString(),
      },
      { onConflict: "user_id", ignoreDuplicates: true },
    );
    if (trialError) {
      throw new AppError(
        "trial_provision_failed",
        "Unable to provision account trial.",
        500,
      );
    }

    await admin.from("profiles").update({
      last_login_at: now.toISOString(),
      updated_at: now.toISOString(),
    }).eq("id", user.id);

    const { data: trial, error: trialReadError } = await admin
      .from("trials")
      .select("status, started_at, ends_at, duration_days_snapshot")
      .eq("user_id", user.id)
      .maybeSingle();
    if (trialReadError || !trial) {
      throw new AppError(
        "trial_read_failed",
        "Unable to load account trial.",
        500,
      );
    }

    logInfo(correlationId, "me_ok", { userId: user.id });
    return jsonOk(
      {
        schemaVersion: 1,
        account: {
          id: profile.id,
          status: profile.status,
          createdAt: profile.created_at,
          updatedAt: profile.updated_at,
          lastLoginAt: now.toISOString(),
        },
        trial: {
          status: trial.status,
          startedAt: trial.started_at,
          endsAt: trial.ends_at,
          durationDays: trial.duration_days_snapshot,
        },
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
