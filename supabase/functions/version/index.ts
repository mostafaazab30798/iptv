import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { getServiceRoleKey, getSupabaseUrl } from "../_shared/auth.ts";
import { corsHeaders, handleOptions } from "../_shared/cors.ts";
import { AppError, jsonError, jsonOk } from "../_shared/errors.ts";
import { correlationIdFrom, logInfo } from "../_shared/logging.ts";
import {
  buildManifestBody,
  signReleaseManifest,
} from "../_shared/release_signing.ts";

const CONTROL_PLANE_VERSION = "0.2.1-android-tv";

const VALID_PLATFORMS = new Set(["android", "windows"]);
const VALID_CHANNELS = new Set(["stable", "beta", "internal"]);
const ANDROID_TV_ARCHITECTURE = "android-tv";
const VALID_ARCHITECTURES = new Set(["arm64-v8a", "x64", ANDROID_TV_ARCHITECTURE]);
const ANDROID_ABI_SPLIT_OFFSET = 1000;

function serviceClient() {
  return createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function parseBuildNumber(raw: string | null): number {
  if (raw == null || raw.trim() === "") {
    throw new AppError("invalid_build_number", "buildNumber is required.", 400);
  }
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 0) {
    throw new AppError(
      "invalid_build_number",
      "buildNumber must be a non-negative integer.",
      400,
    );
  }
  return value;
}

function firstRow(rows: unknown) {
  return Array.isArray(rows) ? rows[0] : rows;
}

function withDownloadUrl(
  manifest: Record<string, unknown>,
  objectKey: unknown,
): Record<string, unknown> {
  if (typeof objectKey !== "string" || objectKey.length === 0) {
    return manifest;
  }
  // Unsigned extra field. Current Flutter clients read it and must not include
  // it in the signed canonical JSON, or verification would fail.
  return { ...manifest, downloadUrl: objectKey };
}

async function lookupRelease(
  client: ReturnType<typeof serviceClient>,
  platform: string,
  channel: string,
  architecture: string,
  currentBuild: number,
) {
  // Universal Android TV APKs use unsplit versionCode (< 1000). Older TV
  // clients still query as android/arm64-v8a, so route them to the TV artifact.
  if (
    platform === "android" &&
    architecture === "arm64-v8a" &&
    currentBuild < ANDROID_ABI_SPLIT_OFFSET
  ) {
    const { data: tvRows, error: tvError } = await client.rpc(
      "latest_release_for_platform",
      {
        p_platform: platform,
        p_channel: channel,
        p_architecture: ANDROID_TV_ARCHITECTURE,
      },
    );
    if (!tvError) {
      const tvRelease = firstRow(tvRows);
      if (tvRelease) return tvRelease;
    }
  }

  const { data: rows, error } = await client.rpc("latest_release_for_platform", {
    p_platform: platform,
    p_channel: channel,
    p_architecture: architecture,
  });

  if (error) {
    throw new AppError("version_lookup_failed", "Release lookup failed.", 500);
  }
  return firstRow(rows);
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

    const url = new URL(req.url);
    const platform = url.searchParams.get("platform") ?? "";
    const channel = url.searchParams.get("channel") ?? "stable";
    const architecture = url.searchParams.get("architecture") ?? "";
    const currentBuild = parseBuildNumber(url.searchParams.get("buildNumber"));

    if (!VALID_PLATFORMS.has(platform)) {
      throw new AppError("invalid_platform", "Unsupported platform.", 400);
    }
    if (!VALID_CHANNELS.has(channel)) {
      throw new AppError("invalid_channel", "Unsupported release channel.", 400);
    }
    if (!VALID_ARCHITECTURES.has(architecture)) {
      throw new AppError(
        "invalid_architecture",
        "Unsupported architecture.",
        400,
      );
    }

    const client = serviceClient();
    const release = await lookupRelease(
      client,
      platform,
      channel,
      architecture,
      currentBuild,
    );
    let updateAvailable = false;
    let manifest = null;

    let isNewer = false;
    let manifestBuildNumber = 0;
    if (release) {
      const releaseBuild = Number(release.build_number);
      manifestBuildNumber = releaseBuild;

      if (releaseBuild > currentBuild) {
        isNewer = true;
      } else if (platform === "android") {
        // Handle Flutter ABI split offset on Android (arm64 adds 2000: e.g. installed 2017 vs raw 19)
        const normalizedCurrent = currentBuild >= ANDROID_ABI_SPLIT_OFFSET
          ? currentBuild % ANDROID_ABI_SPLIT_OFFSET
          : currentBuild;
        const normalizedRelease = releaseBuild >= ANDROID_ABI_SPLIT_OFFSET
          ? releaseBuild % ANDROID_ABI_SPLIT_OFFSET
          : releaseBuild;
        if (normalizedRelease > normalizedCurrent) {
          isNewer = true;
          if (currentBuild >= ANDROID_ABI_SPLIT_OFFSET && releaseBuild < ANDROID_ABI_SPLIT_OFFSET) {
            manifestBuildNumber = 2000 + releaseBuild;
          }
        }
      }
    }

    if (isNewer) {
      updateAvailable = true;
      const body = buildManifestBody({
        platform: platform as "android" | "windows",
        architecture: release.architecture ?? architecture,
        channel: channel as "stable" | "beta" | "internal",
        version: release.version,
        buildNumber: manifestBuildNumber,
        minimumSupportedVersion: release.minimum_supported_prior_version,
        mandatory: Boolean(release.mandatory_update),
        fileSize: release.file_size_bytes,
        sha256: release.sha256,
        publishedAt: release.published_at,
        releaseNotesEn: release.release_notes_en,
        releaseNotesAr: release.release_notes_ar,
      });

      let signed: Record<string, unknown>;
      if (release.manifest_signature) {
        const colon = String(release.manifest_signature).indexOf(":");
        const keyId = colon > 0
          ? String(release.manifest_signature).slice(0, colon)
          : "unknown";
        const signature = colon > 0
          ? String(release.manifest_signature).slice(colon + 1)
          : "";
        signed = { ...body, keyId, signature };
      } else {
        signed = await signReleaseManifest(body);
      }
      manifest = withDownloadUrl(signed, release.object_key);
    }

    logInfo(correlationId, "version_check", {
      platform,
      architecture,
      resolvedArchitecture: release?.architecture ?? architecture,
      currentBuild,
      updateAvailable,
    });

    return jsonOk(
      {
        schemaVersion: 1,
        product: "HOPE TV",
        controlPlaneVersion: CONTROL_PLANE_VERSION,
        platform,
        channel,
        architecture,
        currentBuildNumber: currentBuild,
        updateAvailable,
        releaseId: updateAvailable ? release?.id ?? null : null,
        manifest,
      },
      correlationId,
      200,
      headers,
    );
  } catch (error) {
    return jsonError(error, correlationId, headers);
  }
});
