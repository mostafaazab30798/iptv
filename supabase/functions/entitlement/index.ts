import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import {
  bearerToken,
  getAnonKey,
  getServiceRoleKey,
  getSupabaseUrl,
  requireUser,
} from "../_shared/auth.ts";
import { evaluateEntitlement } from "../_shared/entitlement.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { signLease } from "../_shared/lease.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import { optionalString, readJsonObject } from "../_shared/validation.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

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
    if (req.method !== "GET" && req.method !== "POST") {
      throw new AppError("method_not_allowed", "Use GET or POST.", 405);
    }

    const user = await requireUser(req);
    let deviceId: string | undefined;

    if (req.method === "POST") {
      const body = await readJsonObject(req);
      deviceId = optionalString(body, "deviceId");
    } else {
      deviceId = new URL(req.url).searchParams.get("deviceId") ?? undefined;
    }

    if (!deviceId) {
      throw new AppError("validation_error", "deviceId is required.", 400);
    }

    const client = userClient(req);
    const admin = serviceClient();

    const { data: device } = await client
      .from("devices")
      .select("id, revoked_at")
      .eq("id", deviceId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (!device) {
      throw new AppError("device_not_found", "Device not found.", 404);
    }

    const { data: profile } = await admin
      .from("profiles")
      .select("status")
      .eq("id", user.id)
      .single();

    const { data: trial } = await admin
      .from("trials")
      .select("status, ends_at")
      .eq("user_id", user.id)
      .maybeSingle();

    const { data: subscription } = await admin
      .from("subscriptions")
      .select("status, current_period_end, grace_period_ends_at, plan_id")
      .eq("user_id", user.id)
      .order("updated_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    const { data: override } = await admin
      .schema("private")
      .from("entitlement_overrides")
      .select("access_granted, ends_at")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    let planCode: string | null = null;
    if (subscription?.plan_id) {
      const { data: plan } = await admin
        .from("plans")
        .select("code")
        .eq("id", subscription.plan_id)
        .maybeSingle();
      planCode = plan?.code ?? null;
    }

    const { data: configRow } = await admin
      .from("remote_config_versions")
      .select("payload")
      .order("version", { ascending: false })
      .limit(1)
      .maybeSingle();

    const config = (configRow?.payload ?? {}) as Record<string, unknown>;
    const features =
      (config.features as Record<string, boolean> | undefined) ?? {
        liveTv: true,
        movies: true,
        series: true,
        favorites: true,
        history: true,
      };
    const deviceLimit = Number(config.deviceLimit ?? 3);
    const minimumSupportedVersion =
      (config.minimumSupportedVersion as string | undefined) ?? "0.1.0";

    const entitlement = evaluateEntitlement(
      {
        accountStatus: (profile?.status as "active") ?? "active",
        deviceRevoked: device.revoked_at != null,
        trial: trial
          ? {
            status: trial.status as "active",
            endsAt: trial.ends_at ? new Date(trial.ends_at) : null,
          }
          : null,
        subscription: subscription
          ? {
            status: subscription.status as "active",
            currentPeriodEnd: subscription.current_period_end
              ? new Date(subscription.current_period_end)
              : null,
            gracePeriodEndsAt: subscription.grace_period_ends_at
              ? new Date(subscription.grace_period_ends_at)
              : null,
          }
          : null,
        override: override
          ? {
            accessGranted: override.access_granted,
            endsAt: override.ends_at ? new Date(override.ends_at) : null,
          }
          : null,
        features,
        deviceLimit,
        minimumSupportedVersion,
        planCode,
      },
      { now: () => new Date() },
    );

    let lease = null;
    const accessOk =
      entitlement.accessStatus === "trialing" ||
      entitlement.accessStatus === "active" ||
      entitlement.accessStatus === "grace_period";

    if (accessOk) {
      try {
        lease = await signLease({
          userId: user.id,
          deviceId,
          entitlement,
        });
      } catch (e) {
        // Lease signing may be unconfigured in early local setups; still return entitlement.
        logInfo(correlationId, "lease_sign_skipped", {
          reason: e instanceof Error ? e.message : "unknown",
        });
      }
    }

    await admin
      .from("devices")
      .update({ last_entitlement_refresh_at: new Date().toISOString() })
      .eq("id", deviceId);

    logInfo(correlationId, "entitlement_evaluated", {
      accessStatus: entitlement.accessStatus,
      reason: entitlement.reason,
    });

    return jsonOk(
      {
        schemaVersion: 1,
        ...entitlement,
        refreshAfterSeconds: 3600,
        lease,
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
