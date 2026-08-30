import { serviceClient } from "../_shared/auth.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";

function assertCronAuth(req: Request): void {
  const secret = Deno.env.get("CRON_SECRET");
  if (!secret) {
    throw new AppError(
      "misconfigured",
      "CRON_SECRET is not configured for the deletion processor.",
      500,
    );
  }
  const provided = req.headers.get("X-Cron-Secret");
  if (!provided || provided !== secret) {
    throw new AppError("forbidden", "Invalid cron authorization.", 403);
  }
}

Deno.serve(async (req) => {
  const correlationId = correlationIdFrom(req);
  const headers = { "Content-Type": "application/json" };

  try {
    if (req.method !== "POST") {
      throw new AppError("method_not_allowed", "Use POST.", 405);
    }

    assertCronAuth(req);
    const admin = serviceClient();
    const url = new URL(req.url);
    const limit = Number(url.searchParams.get("limit") ?? "25");

    const { data: retention, error: retentionErr } = await admin.rpc(
      "purge_expired_raw_data_v1",
    );
    if (retentionErr) {
      throw new AppError(
        "retention_purge_failed",
        "Retention purge failed.",
        500,
      );
    }

    const { data: due, error: dueErr } = await admin.rpc(
      "list_due_account_deletions_v1",
      { p_limit: limit },
    );
    if (dueErr) {
      throw new AppError(
        "deletion_list_failed",
        "Unable to list due deletions.",
        500,
      );
    }

    const processed: Array<Record<string, unknown>> = [];
    const failures: Array<Record<string, unknown>> = [];

    for (const row of due ?? []) {
      const userId = row.user_id as string;
      const requestId = row.request_id as string;
      try {
        const { data: finalized, error: finalizeErr } = await admin.rpc(
          "finalize_account_deletion_v1",
          {
            p_user_id: userId,
            p_correlation_id: correlationId,
          },
        );
        if (finalizeErr) {
          throw finalizeErr;
        }

        const { error: authDeleteErr } = await admin.auth.admin.deleteUser(userId);
        if (authDeleteErr) {
          throw authDeleteErr;
        }

        processed.push({
          requestId,
          userId,
          finalized,
        });
        logInfo(correlationId, "deletion_processed", { userId, requestId });
      } catch (error) {
        const message = error instanceof Error ? error.message : "unknown";
        failures.push({ requestId, userId, message });
        logInfo(correlationId, "deletion_process_failed", {
          userId,
          requestId,
          message,
        });
      }
    }

    return jsonOk(
      {
        schemaVersion: 1,
        retention,
        dueCount: due?.length ?? 0,
        processedCount: processed.length,
        failureCount: failures.length,
        processed,
        failures,
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
