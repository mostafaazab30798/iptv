import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { parseAdminPath, requireAdmin } from "../_shared/admin_auth.ts";
import { appendAudit } from "../_shared/audit.ts";
import {
  buildManifestBody,
  signReleaseManifest,
} from "../_shared/release_signing.ts";
import { getServiceRoleKey, getSupabaseUrl } from "../_shared/auth.ts";
import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import {
  InMemoryRateLimiter,
  optionalString,
  readJsonObject,
} from "../_shared/validation.ts";

const limiter = new InMemoryRateLimiter();

function adminClient() {
  return createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function envelope(data: unknown, dataThrough?: string) {
  return {
    schemaVersion: 1,
    generatedAt: new Date().toISOString(),
    dataThrough: dataThrough ?? new Date().toISOString(),
    timezone: "UTC",
    data,
  };
}

function parseDateRange(
  url: URL,
): { start: string; end: string; platform: string } {
  const end = url.searchParams.get("endDate") ??
    new Date().toISOString().slice(0, 10);
  const start = url.searchParams.get("startDate") ??
    new Date(Date.now() - 7 * 86_400_000).toISOString().slice(0, 10);
  const platform = url.searchParams.get("platform") ?? "all";
  return { start, end, platform };
}

Deno.serve(async (req) => {
  const correlationId = correlationIdFrom(req);
  const headers = corsHeaders(req.headers.get("Origin"));

  try {
    const preflight = handleOptions(req);
    if (preflight) return preflight;

    const url = new URL(req.url);
    const { route, params } = parseAdminPath(url);
    const method = req.method;

    await limiter.check(`admin-api:${route}:${method}`, 120, 60_000);

    // Session
    if (route === "session" && method === "GET") {
      const ctx = await requireAdmin(req);
      return jsonOk(
        envelope({
          userId: ctx.user.id,
          email: ctx.user.email ?? null,
          role: ctx.role,
          aal: ctx.aal,
        }),
        correlationId,
        200,
        headers,
      );
    }

    // Overview
    if (route === "overview" && method === "GET") {
      await requireAdmin(req, "view_metrics");
      const { start, end, platform } = parseDateRange(url);
      const client = adminClient();
      const { data, error } = await client.rpc("admin_overview_v1", {
        p_start_date: start,
        p_end_date: end,
        p_platform: platform,
      });
      if (error) {
        throw new AppError("report_failed", "Overview query failed.", 500);
      }
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    // Users list
    if (route === "users" && method === "GET") {
      await requireAdmin(req, "view_users");
      const query = url.searchParams.get("q");
      const status = url.searchParams.get("status");
      const access = url.searchParams.get("access");
      const plan = url.searchParams.get("plan");
      const requestedLimit = Number(url.searchParams.get("limit") ?? "25");
      const limit = Number.isFinite(requestedLimit)
        ? Math.min(Math.max(requestedLimit, 1), 100)
        : 25;
      const requestedOffset = Number(url.searchParams.get("cursor") ?? "0");
      const offset = Number.isFinite(requestedOffset)
        ? Math.max(requestedOffset, 0)
        : 0;
      const client = adminClient();
      const { data, error } = await client.rpc("admin_user_search_v2", {
        p_query: query,
        p_account_status: status,
        p_access: access,
        p_plan: plan,
        p_limit: limit,
        p_offset: offset,
      });
      if (error) {
        throw new AppError("report_failed", "User search failed.", 500);
      }
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    // User detail
    if (route === "users/detail" && method === "GET") {
      await requireAdmin(req, "view_users");
      const client = adminClient();
      const { data, error } = await client.rpc("admin_user_detail_v1", {
        p_user_id: params.userId,
      });
      if (error) {
        throw new AppError("report_failed", "User detail failed.", 500);
      }
      if (!data) throw new AppError("not_found", "User not found.", 404);
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    // Subscriptions
    if (route === "subscriptions" && method === "GET") {
      await requireAdmin(req, "view_subscriptions");
      const status = url.searchParams.get("status");
      const plan = url.searchParams.get("plan");
      const access = url.searchParams.get("access");
      const requestedLimit = Number(url.searchParams.get("limit") ?? "25");
      const limit = Number.isFinite(requestedLimit)
        ? Math.min(Math.max(requestedLimit, 1), 100)
        : 25;
      const offset = Math.max(Number(url.searchParams.get("cursor") ?? "0"), 0);
      const client = adminClient();
      const { data, error } = await client.rpc("admin_access_list_v1", {
        p_status: status,
        p_plan: plan,
        p_access: access,
        p_limit: limit,
        p_offset: Number.isFinite(offset) ? offset : 0,
      });
      if (error) {
        throw new AppError("report_failed", "Subscriptions query failed.", 500);
      }
      return jsonOk(
        envelope(data ?? { items: [], total: 0, nextCursor: null }),
        correlationId,
        200,
        headers,
      );
    }

    // Downloads
    if (route === "downloads" && method === "GET") {
      await requireAdmin(req, "view_metrics");
      const { start, end, platform } = parseDateRange(url);
      const client = adminClient();
      let q = client
        .schema("analytics")
        .from("daily_download_metrics")
        .select("*")
        .gte("metric_date", start)
        .lte("metric_date", end);
      if (platform !== "all") q = q.eq("platform", platform);
      const { data, error } = await q.order("metric_date", { ascending: true });
      if (error) {
        throw new AppError("report_failed", "Downloads query failed.", 500);
      }
      return jsonOk(
        envelope({ items: data ?? [] }),
        correlationId,
        200,
        headers,
      );
    }

    // Activity
    if (route === "activity" && method === "GET") {
      await requireAdmin(req, "view_metrics");
      const { start, end, platform } = parseDateRange(url);
      const client = adminClient();
      let q = client
        .schema("analytics")
        .from("daily_account_activity")
        .select("*")
        .gte("metric_date", start)
        .lte("metric_date", end);
      if (platform !== "all") q = q.eq("platform", platform);
      const { data, error } = await q.order("metric_date", { ascending: true });
      if (error) {
        throw new AppError("report_failed", "Activity query failed.", 500);
      }
      return jsonOk(
        envelope({ items: data ?? [] }),
        correlationId,
        200,
        headers,
      );
    }

    // Config
    if (route === "config" && method === "GET") {
      await requireAdmin(req, "view_metrics");
      const client = adminClient();
      const { data: published } = await client
        .from("remote_config_versions")
        .select("version, payload, published_at, published_by")
        .order("version", { ascending: false })
        .limit(1)
        .maybeSingle();
      const { data: drafts } = await client
        .schema("private")
        .from("config_drafts")
        .select("id, version, status, created_at, validated_at")
        .neq("status", "discarded")
        .order("created_at", { ascending: false })
        .limit(20);
      return jsonOk(
        envelope({ published, drafts: drafts ?? [] }),
        correlationId,
        200,
        headers,
      );
    }

    // Releases
    if (route === "releases" && method === "GET") {
      await requireAdmin(req, "view_metrics");
      const client = adminClient();
      const { data, error } = await client
        .from("release_versions")
        .select(
          "id, platform, architecture, channel, version, build_number, object_key, sha256, manifest_signature, published_at, revoked_at, mandatory_update, file_size_bytes, created_at",
        )
        .order("created_at", { ascending: false })
        .limit(50);
      if (error) {
        throw new AppError("report_failed", "Releases query failed.", 500);
      }
      return jsonOk(
        envelope({ items: data ?? [] }),
        correlationId,
        200,
        headers,
      );
    }

    // Audit
    if (route === "audit" && method === "GET") {
      await requireAdmin(req, "view_audit");
      const limit = Number(url.searchParams.get("limit") ?? "100");
      const cursor = url.searchParams.get("cursor");
      const client = adminClient();
      const { data, error } = await client.rpc("admin_audit_list_v1", {
        p_limit: limit,
        p_cursor: cursor,
      });
      if (error) {
        throw new AppError("report_failed", "Audit query failed.", 500);
      }
      return jsonOk(
        envelope(data ?? { items: [], total: 0, cursor: null }),
        correlationId,
        200,
        headers,
      );
    }

    // Health
    if (route === "health" && method === "GET") {
      await requireAdmin(req, "view_metrics");
      const client = adminClient();
      const { data, error } = await client.rpc("admin_health_v1");
      if (error) {
        throw new AppError("report_failed", "Health query failed.", 500);
      }
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    // Mutations
    if (route === "users/suspend" && method === "POST") {
      const ctx = await requireAdmin(req, "suspend_account", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason || reason.length < 3) {
        throw new AppError("validation_error", "reason is required.", 400);
      }
      const client = adminClient();
      const { data: before } = await client
        .from("profiles")
        .select("status")
        .eq("id", params.userId)
        .single();
      await client.from("profiles").update({ status: "suspended" }).eq(
        "id",
        params.userId,
      );
      await appendAudit({
        actor: ctx.user.id,
        action: "user.suspend",
        targetType: "profile",
        targetId: params.userId,
        reason,
        beforeState: before ?? undefined,
        afterState: { status: "suspended" },
        correlationId,
      });
      return jsonOk(
        envelope({ status: "suspended" }),
        correlationId,
        200,
        headers,
      );
    }

    if (route === "users/reactivate" && method === "POST") {
      const ctx = await requireAdmin(req, "reactivate_account", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason || reason.length < 3) {
        throw new AppError("validation_error", "reason is required.", 400);
      }
      const client = adminClient();
      await client.from("profiles").update({ status: "active" }).eq(
        "id",
        params.userId,
      );
      await appendAudit({
        actor: ctx.user.id,
        action: "user.reactivate",
        targetType: "profile",
        targetId: params.userId,
        reason,
        afterState: { status: "active" },
        correlationId,
      });
      return jsonOk(
        envelope({ status: "active" }),
        correlationId,
        200,
        headers,
      );
    }

    if (route === "devices/revoke" && method === "POST") {
      const ctx = await requireAdmin(req, "revoke_device", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason || reason.length < 3) {
        throw new AppError("validation_error", "reason is required.", 400);
      }
      const client = adminClient();
      const now = new Date().toISOString();
      await client.from("devices").update({ revoked_at: now }).eq(
        "id",
        params.deviceId,
      );
      await appendAudit({
        actor: ctx.user.id,
        action: "device.revoke",
        targetType: "device",
        targetId: params.deviceId,
        reason,
        afterState: { revoked_at: now },
        correlationId,
      });
      return jsonOk(envelope({ revokedAt: now }), correlationId, 200, headers);
    }

    if (route === "users/entitlement-overrides" && method === "POST") {
      const ctx = await requireAdmin(req, "entitlement_override", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      const endsAt = optionalString(body, "endsAt");
      const accessGranted = body.accessGranted === true;
      if (!reason || !endsAt) {
        throw new AppError(
          "validation_error",
          "reason and endsAt are required.",
          400,
        );
      }
      const client = adminClient();
      const { data, error } = await client
        .schema("private")
        .from("entitlement_overrides")
        .insert({
          user_id: params.userId,
          access_granted: accessGranted,
          ends_at: endsAt,
          reason,
          created_by: ctx.user.id,
        })
        .select("id")
        .single();
      if (error) {
        throw new AppError("mutation_failed", "Override creation failed.", 500);
      }
      await appendAudit({
        actor: ctx.user.id,
        action: "entitlement.override.grant",
        targetType: "profile",
        targetId: params.userId,
        reason,
        afterState: { overrideId: data?.id, endsAt, accessGranted },
        correlationId,
      });
      return jsonOk(
        envelope({ overrideId: data?.id }),
        correlationId,
        200,
        headers,
      );
    }

    if (route === "users/subscription" && method === "POST") {
      const ctx = await requireAdmin(req, "billing_sync", { requireMfa: true });
      if (ctx.role !== "owner") {
        throw new AppError(
          "forbidden",
          "Only the owner can grant paid access.",
          403,
        );
      }
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      const planCode = optionalString(body, "planCode");
      const durationDays = Number(body.durationDays);
      if (!reason || reason.length < 10) {
        throw new AppError(
          "validation_error",
          "A reason of at least 10 characters is required.",
          400,
        );
      }
      if (!planCode || !["monthly", "yearly"].includes(planCode)) {
        throw new AppError(
          "validation_error",
          "planCode must be monthly or yearly.",
          400,
        );
      }
      if (
        !Number.isInteger(durationDays) || durationDays < 1 ||
        durationDays > 1825
      ) {
        throw new AppError(
          "validation_error",
          "durationDays must be between 1 and 1825.",
          400,
        );
      }

      const client = adminClient();
      const idempotencyKey = req.headers.get("Idempotency-Key") ?? "";
      if (idempotencyKey.length < 16 || idempotencyKey.length > 200) {
        throw new AppError(
          "validation_error",
          "A valid Idempotency-Key header is required.",
          400,
        );
      }
      const idempotencyScope = `manual_subscription_grant:${params.userId}`;
      const { data: prior } = await client
        .schema("private")
        .from("idempotency_keys")
        .select("response_hash")
        .eq("scope", idempotencyScope)
        .eq("idempotency_key", idempotencyKey)
        .maybeSingle();
      if (prior?.response_hash) {
        return jsonOk(
          envelope(JSON.parse(prior.response_hash)),
          correlationId,
          200,
          headers,
        );
      }
      const { data: before } = await client
        .from("subscriptions")
        .select("id, plan_id, provider, status, current_period_end")
        .eq("user_id", params.userId)
        .eq("provider", "manual")
        .maybeSingle();
      const { data, error } = await client.rpc(
        "admin_grant_manual_subscription_v1",
        {
          p_user_id: params.userId,
          p_plan_code: planCode,
          p_duration_days: durationDays,
        },
      );
      if (error || !data) {
        throw new AppError(
          "mutation_failed",
          "Manual subscription grant failed.",
          500,
        );
      }
      await appendAudit({
        actor: ctx.user.id,
        action: before
          ? "subscription.manual.extend"
          : "subscription.manual.grant",
        targetType: "subscription",
        targetId: params.userId,
        reason,
        beforeState: before ?? undefined,
        afterState: data as Record<string, unknown>,
        correlationId,
      });
      await client.schema("private").from("idempotency_keys").upsert(
        {
          scope: idempotencyScope,
          idempotency_key: idempotencyKey,
          user_id: params.userId,
          response_hash: JSON.stringify(data),
        },
        { onConflict: "scope,idempotency_key" },
      );
      return jsonOk(envelope(data), correlationId, before ? 200 : 201, headers);
    }

    if (route === "users/subscription-cancel" && method === "POST") {
      const ctx = await requireAdmin(req, "billing_sync", { requireMfa: true });
      if (ctx.role !== "owner") {
        throw new AppError(
          "forbidden",
          "Only the owner can cancel manual paid access.",
          403,
        );
      }
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      const immediate = body.immediate === true;
      if (!reason || reason.length < 10) {
        throw new AppError(
          "validation_error",
          "A reason of at least 10 characters is required.",
          400,
        );
      }

      const client = adminClient();
      const { data: before } = await client
        .from("subscriptions")
        .select(
          "id, provider, status, current_period_end, cancel_at_period_end",
        )
        .eq("user_id", params.userId)
        .eq("provider", "manual")
        .maybeSingle();
      if (!before) {
        throw new AppError(
          "not_found",
          "Manual subscription not found for this user.",
          404,
        );
      }
      const { data, error } = await client.rpc(
        "admin_cancel_manual_subscription_v1",
        { p_user_id: params.userId, p_immediate: immediate },
      );
      if (error || !data) {
        throw new AppError(
          "mutation_failed",
          "Manual subscription cancellation failed.",
          500,
        );
      }
      await appendAudit({
        actor: ctx.user.id,
        action: immediate
          ? "subscription.manual.cancel_immediately"
          : "subscription.manual.cancel_at_period_end",
        targetType: "subscription",
        targetId: String(before.id),
        reason,
        beforeState: before,
        afterState: data as Record<string, unknown>,
        correlationId,
      });
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    if (route === "users/trial-revoke" && method === "POST") {
      const ctx = await requireAdmin(req, "entitlement_override", {
        requireMfa: true,
      });
      if (ctx.role !== "owner") {
        throw new AppError(
          "forbidden",
          "Only the owner can revoke a trial.",
          403,
        );
      }
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason || reason.length < 10) {
        throw new AppError(
          "validation_error",
          "A reason of at least 10 characters is required.",
          400,
        );
      }
      const client = adminClient();
      const { data: before } = await client
        .from("trials")
        .select("id, status, started_at, ends_at")
        .eq("user_id", params.userId)
        .maybeSingle();
      if (!before) {
        throw new AppError("not_found", "Trial not found for this user.", 404);
      }
      const { data, error } = await client.rpc("admin_revoke_trial_v1", {
        p_user_id: params.userId,
      });
      if (error || !data) {
        throw new AppError("mutation_failed", "Trial revocation failed.", 500);
      }
      await appendAudit({
        actor: ctx.user.id,
        action: "trial.revoke",
        targetType: "trial",
        targetId: String(before.id),
        reason,
        beforeState: before,
        afterState: data as Record<string, unknown>,
        correlationId,
      });
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    if (route === "users/delete" && method === "DELETE") {
      const ctx = await requireAdmin(req, "delete_user", { requireMfa: true });
      if (ctx.role !== "owner") {
        throw new AppError(
          "forbidden",
          "Only the owner can delete users.",
          403,
        );
      }
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      const confirmation = optionalString(body, "confirmation");
      if (!reason || reason.length < 10) {
        throw new AppError(
          "validation_error",
          "A reason of at least 10 characters is required.",
          400,
        );
      }
      if (confirmation !== `DELETE ${params.userId}`) {
        throw new AppError(
          "validation_error",
          `Type DELETE ${params.userId} to confirm permanent deletion.`,
          400,
        );
      }
      if (params.userId === ctx.user.id) {
        throw new AppError(
          "forbidden",
          "You cannot delete your own owner account.",
          403,
        );
      }
      const client = adminClient();
      const { data, error } = await client.rpc("admin_delete_user_v1", {
        p_user_id: params.userId,
        p_actor_id: ctx.user.id,
        p_reason: reason,
        p_correlation_id: correlationId,
      });
      if (error || !data) {
        const message = error?.message ?? "Permanent user deletion failed.";
        if (message.includes("admin_account_deletion_forbidden")) {
          throw new AppError(
            "forbidden",
            "Admin accounts must be removed from administration before deletion.",
            403,
          );
        }
        throw new AppError(
          "mutation_failed",
          "Permanent user deletion failed.",
          500,
        );
      }
      return jsonOk(envelope(data), correlationId, 200, headers);
    }

    if (route === "entitlement-overrides/delete" && method === "DELETE") {
      const ctx = await requireAdmin(req, "entitlement_override", {
        requireMfa: true,
      });
      const reason = req.headers.get("X-Admin-Reason") ?? "";
      if (reason.length < 3) {
        throw new AppError(
          "validation_error",
          "X-Admin-Reason header is required.",
          400,
        );
      }
      const client = adminClient();
      await client
        .schema("private")
        .from("entitlement_overrides")
        .delete()
        .eq("id", params.overrideId);
      await appendAudit({
        actor: ctx.user.id,
        action: "entitlement.override.revoke",
        targetType: "entitlement_override",
        targetId: params.overrideId,
        reason,
        correlationId,
      });
      return jsonOk(envelope({ deleted: true }), correlationId, 200, headers);
    }

    if (route === "subscriptions/sync" && method === "POST") {
      const ctx = await requireAdmin(req, "billing_sync", { requireMfa: true });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason") ??
        "provider_sync_requested";
      await appendAudit({
        actor: ctx.user.id,
        action: "subscription.sync_requested",
        targetType: "subscription",
        targetId: params.subscriptionId,
        reason,
        correlationId,
      });
      return jsonOk(
        envelope({
          status: "queued",
          message:
            "Billing provider sync is deferred until Phase 4 billing is configured.",
        }),
        correlationId,
        202,
        headers,
      );
    }

    if (route === "config/drafts" && method === "POST") {
      const ctx = await requireAdmin(req, "publish_config", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const version = Number(body.version);
      const payload = body.payload;
      if (!version || !payload || typeof payload !== "object") {
        throw new AppError(
          "validation_error",
          "version and payload are required.",
          400,
        );
      }
      const client = adminClient();
      const { data, error } = await client
        .schema("private")
        .from("config_drafts")
        .insert({ version, payload, created_by: ctx.user.id })
        .select("id, version, status")
        .single();
      if (error) {
        throw new AppError("mutation_failed", "Draft creation failed.", 500);
      }
      await appendAudit({
        actor: ctx.user.id,
        action: "config.draft.create",
        targetType: "config_draft",
        targetId: data?.id,
        correlationId,
      });
      return jsonOk(envelope(data), correlationId, 201, headers);
    }

    if (route === "config/publish" && method === "POST") {
      const ctx = await requireAdmin(req, "publish_config", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason) {
        throw new AppError("validation_error", "reason is required.", 400);
      }
      const client = adminClient();
      const { data: draft } = await client
        .schema("private")
        .from("config_drafts")
        .select("*")
        .eq("id", params.draftId)
        .single();
      if (!draft) throw new AppError("not_found", "Draft not found.", 404);
      await client.from("remote_config_versions").insert({
        version: draft.version,
        payload: draft.payload,
        published_by: ctx.user.id,
      });
      await client
        .schema("private")
        .from("config_drafts")
        .update({ status: "published", published_at: new Date().toISOString() })
        .eq("id", params.draftId);
      await appendAudit({
        actor: ctx.user.id,
        action: "config.publish",
        targetType: "config_draft",
        targetId: params.draftId,
        reason,
        correlationId,
      });
      return jsonOk(
        envelope({ published: true, version: draft.version }),
        correlationId,
        200,
        headers,
      );
    }

    if (route === "releases/publish" && method === "POST") {
      const ctx = await requireAdmin(req, "publish_release", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason) {
        throw new AppError("validation_error", "reason is required.", 400);
      }
      const client = adminClient();
      const { data: release } = await client
        .from("release_versions")
        .select("*")
        .eq("id", params.releaseId)
        .single();
      if (!release) throw new AppError("not_found", "Release not found.", 404);

      const now = new Date().toISOString();
      const manifestBody = buildManifestBody({
        platform: release.platform,
        architecture: release.architecture,
        channel: release.channel,
        version: release.version,
        buildNumber: Number(release.build_number),
        minimumSupportedVersion: release.minimum_supported_prior_version,
        mandatory: Boolean(release.mandatory_update),
        fileSize: release.file_size_bytes,
        sha256: release.sha256,
        publishedAt: now,
        releaseNotesEn: release.release_notes_en,
        releaseNotesAr: release.release_notes_ar,
      });
      const signed = await signReleaseManifest(manifestBody);

      await client
        .from("release_versions")
        .update({
          published_at: now,
          manifest_signature: `${signed.keyId}:${signed.signature}`,
        })
        .eq("id", params.releaseId);
      await appendAudit({
        actor: ctx.user.id,
        action: "release.publish",
        targetType: "release",
        targetId: params.releaseId,
        reason,
        correlationId,
      });
      return jsonOk(
        envelope({ publishedAt: now, keyId: signed.keyId }),
        correlationId,
        200,
        headers,
      );
    }

    if (route === "releases/revoke" && method === "POST") {
      const ctx = await requireAdmin(req, "publish_release", {
        requireMfa: true,
      });
      const body = await readJsonObject(req);
      const reason = optionalString(body, "reason");
      if (!reason) {
        throw new AppError("validation_error", "reason is required.", 400);
      }
      const client = adminClient();
      const now = new Date().toISOString();
      await client
        .from("release_versions")
        .update({ revoked_at: now })
        .eq("id", params.releaseId);
      await appendAudit({
        actor: ctx.user.id,
        action: "release.revoke",
        targetType: "release",
        targetId: params.releaseId,
        reason,
        correlationId,
      });
      return jsonOk(envelope({ revokedAt: now }), correlationId, 200, headers);
    }

    logInfo(correlationId, "admin_api_not_found", { route, method });
    throw new AppError("not_found", "Route not found.", 404);
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
