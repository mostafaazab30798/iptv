/**
 * Account deletion workflow helpers.
 */

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { AppError } from "./errors.ts";
import { appendAudit } from "./audit.ts";

export const DELETION_CONFIRM_PHRASE = "DELETE_MY_ACCOUNT";
export const DEFAULT_GRACE_DAYS = 14;

export type DeletionRequestResult = {
  requestId: string;
  status: string;
  scheduledFor: string;
  hasActiveSubscription: boolean;
  graceDays: number;
};

export function graceDaysFromEnv(): number {
  const raw = Number(Deno.env.get("DELETION_GRACE_DAYS") ?? String(DEFAULT_GRACE_DAYS));
  if (!Number.isFinite(raw) || raw < 1 || raw > 90) {
    return DEFAULT_GRACE_DAYS;
  }
  return Math.floor(raw);
}

export function assertDeletionConfirmation(
  confirmation: string | undefined,
): void {
  if (confirmation !== DELETION_CONFIRM_PHRASE) {
    throw new AppError(
      "confirmation_required",
      "Type DELETE_MY_ACCOUNT to confirm account deletion.",
      400,
    );
  }
}

export async function hasActivePaidSubscription(
  client: SupabaseClient,
  userId: string,
): Promise<boolean> {
  const { data, error } = await client
    .from("subscriptions")
    .select("id, status, current_period_end")
    .eq("user_id", userId)
    .in("status", ["active", "trialing", "grace_period", "canceling_at_period_end", "past_due"])
    .limit(1);

  if (error) {
    throw new AppError(
      "subscription_check_failed",
      "Unable to verify subscription status.",
      500,
    );
  }

  if (!data?.length) return false;

  const row = data[0] as { current_period_end: string | null };
  if (!row.current_period_end) return true;
  return new Date(row.current_period_end) > new Date();
}

export async function requestAccountDeletion(params: {
  admin: SupabaseClient;
  userId: string;
  correlationId: string;
  idempotencyKey?: string;
  acknowledgeSubscriptionLoss?: boolean;
}): Promise<DeletionRequestResult> {
  const graceDays = graceDaysFromEnv();
  const scheduledFor = new Date(Date.now() + graceDays * 86_400_000).toISOString();

  const { data: profile, error: profileErr } = await params.admin
    .from("profiles")
    .select("status")
    .eq("id", params.userId)
    .maybeSingle();

  if (profileErr || !profile) {
    throw new AppError("profile_missing", "Profile not found.", 404);
  }

  if (profile.status === "deleted") {
    throw new AppError("already_deleted", "This account is already deleted.", 410);
  }

  if (profile.status === "deletion_pending") {
    const { data: existing } = await params.admin
      .from("account_deletion_requests")
      .select("id, status, scheduled_for, has_active_subscription")
      .eq("user_id", params.userId)
      .in("status", ["pending", "processing"])
      .order("requested_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existing) {
      return {
        requestId: existing.id,
        status: existing.status,
        scheduledFor: existing.scheduled_for,
        hasActiveSubscription: existing.has_active_subscription,
        graceDays,
      };
    }
  }

  const hasActiveSubscription = await hasActivePaidSubscription(
    params.admin,
    params.userId,
  );

  if (hasActiveSubscription && !params.acknowledgeSubscriptionLoss) {
    throw new AppError(
      "active_subscription",
      "Cancel your subscription or acknowledge that renewal will stop before deleting your account.",
      409,
      { hasActiveSubscription: true },
    );
  }

  const { data: request, error: insertErr } = await params.admin
    .from("account_deletion_requests")
    .insert({
      user_id: params.userId,
      status: "pending",
      scheduled_for: scheduledFor,
      idempotency_key: params.idempotencyKey ?? null,
      has_active_subscription: hasActiveSubscription,
      correlation_id: params.correlationId,
      notes: hasActiveSubscription
        ? "User acknowledged active subscription at request time."
        : null,
    })
    .select("id, status, scheduled_for, has_active_subscription")
    .single();

  if (insertErr || !request) {
    if (insertErr?.code === "23505") {
      throw new AppError(
        "deletion_already_pending",
        "A deletion request is already in progress.",
        409,
      );
    }
    throw new AppError(
      "deletion_request_failed",
      "Unable to create deletion request.",
      500,
    );
  }

  await params.admin
    .from("profiles")
    .update({ status: "deletion_pending", updated_at: new Date().toISOString() })
    .eq("id", params.userId);

  const now = new Date().toISOString();
  await params.admin
    .from("devices")
    .update({ revoked_at: now })
    .eq("user_id", params.userId)
    .is("revoked_at", null);

  await params.admin
    .schema("analytics")
    .from("app_sessions")
    .update({ ended_at: now })
    .eq("user_id", params.userId)
    .is("ended_at", null);

  await appendAudit({
    actor: params.userId,
    action: "account.deletion.requested",
    targetType: "profile",
    targetId: params.userId,
    reason: "User requested account deletion.",
    afterState: {
      status: "deletion_pending",
      scheduledFor,
      hasActiveSubscription,
    },
    correlationId: params.correlationId,
  });

  return {
    requestId: request.id,
    status: request.status,
    scheduledFor: request.scheduled_for,
    hasActiveSubscription: request.has_active_subscription,
    graceDays,
  };
}

export async function cancelAccountDeletion(params: {
  admin: SupabaseClient;
  userId: string;
  correlationId: string;
}): Promise<{ canceled: boolean; requestId: string }> {
  const { data: request, error } = await params.admin
    .from("account_deletion_requests")
    .select("id, status")
    .eq("user_id", params.userId)
    .eq("status", "pending")
    .order("requested_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    throw new AppError("deletion_cancel_failed", "Unable to load deletion request.", 500);
  }

  if (!request) {
    throw new AppError(
      "no_pending_deletion",
      "No pending deletion request to cancel.",
      404,
    );
  }

  const canceledAt = new Date().toISOString();
  await params.admin
    .from("account_deletion_requests")
    .update({ status: "canceled", canceled_at: canceledAt })
    .eq("id", request.id);

  await params.admin
    .from("profiles")
    .update({ status: "active", updated_at: canceledAt })
    .eq("id", params.userId)
    .eq("status", "deletion_pending");

  await appendAudit({
    actor: params.userId,
    action: "account.deletion.canceled",
    targetType: "profile",
    targetId: params.userId,
    reason: "User canceled account deletion.",
    afterState: { status: "active" },
    correlationId: params.correlationId,
  });

  return { canceled: true, requestId: request.id };
}

export async function revokeAllAuthSessions(
  admin: SupabaseClient,
  userId: string,
): Promise<void> {
  const { error } = await admin.auth.admin.signOut(userId, "global");
  if (error) {
    throw new AppError(
      "session_revoke_failed",
      "Unable to revoke active sessions.",
      500,
    );
  }
}
