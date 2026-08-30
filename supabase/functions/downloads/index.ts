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

/**
 * Returns a time-limited download URL for a release asset.
 *
 * ## object_key conventions (stored in release_versions.object_key)
 *
 * ### Private GitHub repo (recommended)
 *   https://api.github.com/repos/{owner}/{repo}/releases/assets/{asset_id}
 *   → The function calls the GitHub API with a PAT (GITHUB_PAT secret).
 *     GitHub returns a 302 to a temporary Fastly/S3 CDN URL (valid ~5 min).
 *     That CDN URL is returned to the client — no token in the URL.
 *
 * ### Public GitHub repo
 *   https://github.com/{owner}/{repo}/releases/download/{tag}/{filename}
 *   → URL is returned directly. No auth required.
 *
 * ## Required Supabase secret
 *   GITHUB_PAT — a GitHub Personal Access Token (classic or fine-grained)
 *   with `repo` scope (or `contents:read` for fine-grained).
 *   Not needed for public repos.
 */

/** Resolve a GitHub asset URL to a downloadable CDN URL.  */
async function resolveGitHubUrl(objectKey: string): Promise<string> {
  // Public GitHub release asset — direct URL, no auth needed.
  if (objectKey.startsWith("https://github.com/")) {
    return objectKey;
  }

  // Private GitHub API asset URL — exchange for a temporary CDN URL.
  if (objectKey.startsWith("https://api.github.com/")) {
    const pat = Deno.env.get("GITHUB_PAT");
    if (!pat || pat.startsWith("PLACEHOLDER")) {
      throw new AppError(
        "misconfigured",
        "GITHUB_PAT secret is not configured for private release assets.",
        503,
      );
    }

    // GitHub returns a 302 to a temporary CDN URL.
    // We follow the redirect to extract the CDN URL without revealing the PAT.
    const response = await fetch(objectKey, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${pat}`,
        "Accept": "application/octet-stream",
        "User-Agent": "HOPE-TV-Download-Gateway/1.0",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      redirect: "manual", // Don't auto-follow — capture the Location header.
    });

    // GitHub responds with 302 and a Location pointing to the CDN signed URL.
    const location = response.headers.get("Location");
    if ((response.status === 302 || response.status === 301) && location) {
      return location;
    }

    // Some clients (or large assets) may get a direct 200 stream.
    // In that case return the original API URL — the client will need to pass
    // the PAT, which is not ideal. Log a warning.
    if (response.status === 200) {
      // Fallback: return the API URL. Client will need to authenticate.
      // This case is unusual for binary assets.
      console.warn("GitHub asset returned 200 directly instead of 302 redirect.");
      return objectKey;
    }

    throw new AppError(
      "asset_unavailable",
      `GitHub asset resolution failed (HTTP ${response.status}).`,
      502,
    );
  }

  throw new AppError(
    "invalid_object_key",
    "object_key must be a github.com or api.github.com URL.",
    500,
  );
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
    // 10 download authorizations per user per hour (prevents token farming).
    await limiter.check(`downloads:${user.id}`, 10, 3600_000);

    const body = await readJsonObject(req);
    const releaseId = optionalString(body, "releaseId");
    const platform = optionalString(body, "platform");
    if (!releaseId) {
      throw new AppError("validation_error", "releaseId is required.", 400);
    }

    const admin = createClient(getSupabaseUrl(), getServiceRoleKey(), {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // 1. Verify release exists, is published, and matches the requested platform.
    const { data: release, error: releaseError } = await admin
      .from("release_versions")
      .select("id, platform, object_key, version, published_at, revoked_at")
      .eq("id", releaseId)
      .maybeSingle();

    if (releaseError || !release) {
      throw new AppError("release_not_found", "Release not found.", 404);
    }
    if (!release.published_at || release.revoked_at) {
      throw new AppError("release_unavailable", "Release is not available for download.", 403);
    }
    if (platform && platform !== release.platform) {
      throw new AppError("platform_mismatch", "Release platform does not match.", 400);
    }

    // 2. Resolve the GitHub asset URL to a downloadable CDN URL.
    const downloadUrl = await resolveGitHubUrl(release.object_key);

    // 3. Emit analytics event.
    await admin.schema("analytics").from("download_events").insert({
      user_id: user.id,
      release_id: release.id,
      platform: release.platform,
      event_name: "download_authorized",
      metadata: { correlationId, version: release.version },
    });

    logInfo(correlationId, "download_authorized", {
      userId: user.id,
      releaseId: release.id,
      platform: release.platform,
    });

    // CDN signed URLs from GitHub expire in approximately 5 minutes.
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    return jsonOk(
      {
        schemaVersion: 1,
        downloadUrl,
        expiresAt,
        releaseId: release.id,
        platform: release.platform,
        version: release.version,
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
