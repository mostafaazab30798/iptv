/**
 * Signed release update manifests (separate keys from entitlement leases).
 */

import { AppError } from "./errors.ts";
import { canonicalJson } from "./lease.ts";

export type ReleaseManifest = {
  schemaVersion: 1;
  platform: "android" | "windows";
  architecture: string;
  channel: "stable" | "beta" | "internal";
  version: string;
  buildNumber: number;
  minimumSupportedVersion: string | null;
  mandatory: boolean;
  fileSize: number | null;
  sha256: string;
  downloadAuthorizationPath: string;
  publishedAt: string;
  releaseNotesEn: string | null;
  releaseNotesAr: string | null;
  keyId: string;
  signature: string;
};

export function getReleaseKeyId(): string {
  return Deno.env.get("RELEASE_SIGNING_KEY_ID") ?? "release-dev-1";
}

function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

export async function signReleaseManifest(
  body: Omit<ReleaseManifest, "keyId" | "signature">,
): Promise<ReleaseManifest> {
  const keyId = getReleaseKeyId();
  const unsigned = { ...body, keyId };
  const payload = bytesToBase64Url(new TextEncoder().encode(canonicalJson(unsigned)));
  const alg = (Deno.env.get("RELEASE_SIGNING_ALG") ?? "hmac").toLowerCase();

  let signature: string;
  if (alg === "ed25519") {
    const pkcs8B64 = Deno.env.get("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64");
    if (!pkcs8B64) {
      throw new AppError(
        "misconfigured",
        "RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64 is required for Ed25519 release signing.",
        500,
      );
    }
    const pkcs8 = Uint8Array.from(atob(pkcs8B64), (c) => c.charCodeAt(0));
    const privateKey = await crypto.subtle.importKey(
      "pkcs8",
      pkcs8,
      { name: "Ed25519" },
      false,
      ["sign"],
    );
    const sig = await crypto.subtle.sign(
      "Ed25519",
      privateKey,
      new TextEncoder().encode(payload),
    );
    signature = bytesToBase64Url(new Uint8Array(sig));
  } else {
    const secret = Deno.env.get("RELEASE_SIGNING_HMAC_SECRET");
    if (!secret) {
      throw new AppError(
        "misconfigured",
        "RELEASE_SIGNING_HMAC_SECRET is required for release signing.",
        500,
      );
    }
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const sig = await crypto.subtle.sign(
      "HMAC",
      key,
      new TextEncoder().encode(payload),
    );
    signature = bytesToBase64Url(new Uint8Array(sig));
  }

  return { ...unsigned, signature };
}

export function buildManifestBody(input: {
  platform: "android" | "windows";
  architecture: string;
  channel: "stable" | "beta" | "internal";
  version: string;
  buildNumber: number;
  minimumSupportedVersion: string | null;
  mandatory: boolean;
  fileSize: number | null;
  sha256: string;
  publishedAt: string;
  releaseNotesEn: string | null;
  releaseNotesAr: string | null;
}): Omit<ReleaseManifest, "keyId" | "signature"> {
  return {
    schemaVersion: 1,
    platform: input.platform,
    architecture: input.architecture,
    channel: input.channel,
    version: input.version,
    buildNumber: input.buildNumber,
    minimumSupportedVersion: input.minimumSupportedVersion,
    mandatory: input.mandatory,
    fileSize: input.fileSize,
    sha256: input.sha256,
    downloadAuthorizationPath: "/v1/downloads/authorize",
    publishedAt: input.publishedAt,
    releaseNotesEn: input.releaseNotesEn,
    releaseNotesAr: input.releaseNotesAr,
  };
}
