import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { validateAndSanitizeEvent } from "../_shared/analytics.ts";
import {
  getServiceRoleKey,
  getSupabaseUrl,
  requireUser,
} from "../_shared/auth.ts";
import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import { InMemoryRateLimiter, readJsonObject } from "../_shared/validation.ts";

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

    await limiter.check(`analytics-batch:${req.headers.get("x-forwarded-for") ?? "local"}`, 60, 60_000);

    const body = await readJsonObject(req);
    const eventsRaw = body.events;
    if (!Array.isArray(eventsRaw) || eventsRaw.length === 0) {
      throw new AppError("validation_error", "events array is required.", 400);
    }
    if (eventsRaw.length > 50) {
      throw new AppError("validation_error", "Maximum 50 events per batch.", 400);
    }

    let userId: string | null = null;
    try {
      const user = await requireUser(req);
      userId = user.id;
    } catch {
      // Anonymous events allowed for pre-auth funnel (installation, first open).
    }

    const admin = createClient(getSupabaseUrl(), getServiceRoleKey(), {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const rows = [];
    let rejected = 0;

    for (const raw of eventsRaw) {
      if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
        rejected++;
        continue;
      }
      try {
        const event = validateAndSanitizeEvent(raw as Record<string, unknown>);
        rows.push({
          event_id: event.eventId,
          event_name: event.eventName,
          schema_version: event.schemaVersion ?? 1,
          occurred_at: event.occurredAt,
          user_id: userId,
          installation_id_hash: event.installationIdHash ?? null,
          platform: event.platform ?? null,
          app_version: event.appVersion ?? null,
          properties: event.properties ?? {},
        });
      } catch {
        rejected++;
      }
    }

    if (rows.length === 0) {
      throw new AppError("validation_error", "No valid events in batch.", 400);
    }

    const { error } = await admin
      .schema("analytics")
      .from("analytics_events")
      .upsert(rows, { onConflict: "event_id", ignoreDuplicates: true });

    if (error) {
      throw new AppError("ingest_failed", "Failed to ingest analytics batch.", 500);
    }

    logInfo(correlationId, "analytics_batch_ingested", {
      accepted: rows.length,
      rejected,
    });

    return jsonOk(
      { schemaVersion: 1, accepted: rows.length, rejected },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
