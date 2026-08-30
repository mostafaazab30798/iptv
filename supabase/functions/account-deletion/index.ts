import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { requireUser, serviceClient } from "../_shared/auth.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import {
  assertDeletionConfirmation,
  cancelAccountDeletion,
  requestAccountDeletion,
  revokeAllAuthSessions,
} from "../_shared/account_deletion.ts";
import {
  optionalString,
  readJsonObject,
  requireString,
} from "../_shared/validation.ts";

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
    const action = optionalString(body, "action") ?? "request";

    if (action === "status") {
      const admin = serviceClient();
      const { data: request } = await admin
        .from("account_deletion_requests")
        .select("id, status, requested_at, scheduled_for, completed_at, canceled_at, has_active_subscription")
        .eq("user_id", user.id)
        .order("requested_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      const { data: profile } = await admin
        .from("profiles")
        .select("status")
        .eq("id", user.id)
        .maybeSingle();

      return jsonOk(
        {
          schemaVersion: 1,
          accountStatus: profile?.status ?? "unknown",
          deletionRequest: request
            ? {
              id: request.id,
              status: request.status,
              requestedAt: request.requested_at,
              scheduledFor: request.scheduled_for,
              completedAt: request.completed_at,
              canceledAt: request.canceled_at,
              hasActiveSubscription: request.has_active_subscription,
            }
            : null,
        },
        correlationId,
        200,
        headers,
      );
    }

    if (action === "cancel") {
      const admin = serviceClient();
      const result = await cancelAccountDeletion({
        admin,
        userId: user.id,
        correlationId,
      });
      logInfo(correlationId, "deletion_canceled", { userId: user.id });
      return jsonOk(
        { schemaVersion: 1, ...result },
        correlationId,
        200,
        headers,
      );
    }

    if (action === "request") {
      assertDeletionConfirmation(optionalString(body, "confirmation"));
      const idempotencyKey = optionalString(body, "idempotencyKey");
      const acknowledgeSubscriptionLoss = body.acknowledgeSubscriptionLoss === true;
      const admin = serviceClient();

      const result = await requestAccountDeletion({
        admin,
        userId: user.id,
        correlationId,
        idempotencyKey,
        acknowledgeSubscriptionLoss,
      });

      await revokeAllAuthSessions(admin, user.id);

      logInfo(correlationId, "deletion_requested", {
        userId: user.id,
        requestId: result.requestId,
      });

      return jsonOk(
        {
          schemaVersion: 1,
          deletionRequest: result,
          sessionsRevoked: true,
          message:
            "Account deletion scheduled. You have been signed out on all devices.",
        },
        correlationId,
        200,
        headers,
      );
    }

    throw new AppError("validation_error", "Unknown action.", 400);
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
