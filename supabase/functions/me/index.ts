import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { requireUser } from "../_shared/auth.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { getAnonKey, getSupabaseUrl, bearerToken } from "../_shared/auth.ts";

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
    const client = createClient(getSupabaseUrl(), getAnonKey(), {
      global: { headers: { Authorization: `Bearer ${bearerToken(req)}` } },
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: profile, error } = await client
      .from("profiles")
      .select("id, status, created_at, updated_at, last_login_at")
      .eq("id", user.id)
      .maybeSingle();

    if (error) {
      throw new AppError("profile_read_failed", "Unable to load profile.", 500);
    }
    if (!profile) {
      throw new AppError("profile_missing", "Profile not found.", 404);
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
          lastLoginAt: profile.last_login_at,
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
