/**
 * Signed offline entitlement lease helpers.
 * Default local alg: HMAC-SHA256 (ENTITLEMENT_SIGNING_HMAC_SECRET).
 * Production path: Ed25519 via ENTITLEMENT_SIGNING_ALG=ed25519 + PKCS8 key.
 */

import { AppError } from "./errors.ts";
import type { AccessStatus, EntitlementResult } from "./entitlement.ts";

export type LeaseClaims = {
  schemaVersion: 1;
  sub: string;
  deviceId: string;
  accessStatus: AccessStatus;
  features: Record<string, boolean>;
  iat: number;
  exp: number;
  keyId: string;
  aud: string;
};

export type SignedLease = {
  payload: string;
  signature: string;
  keyId: string;
};

export const LEASE_AUDIENCE = "hope-tv-player";

export function canonicalJson(value: unknown): string {
  return JSON.stringify(sortKeys(value));
}

function sortKeys(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (value && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const key of Object.keys(obj).sort()) {
      out[key] = sortKeys(obj[key]);
    }
    return out;
  }
  return value;
}

function bytesToBase64Url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function base64UrlToBytes(value: string): Uint8Array {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/");
  const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const out = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out;
}

export function getLeaseKeyId(): string {
  return Deno.env.get("ENTITLEMENT_SIGNING_KEY_ID") ?? "entitlement-dev-1";
}

export function getLeaseTtlSeconds(): number {
  const hours = Number(Deno.env.get("OFFLINE_LEASE_HOURS") ?? "24");
  return Math.max(1, Math.min(hours, 72)) * 3600;
}

export async function signLease(input: {
  userId: string;
  deviceId: string;
  entitlement: EntitlementResult;
  now?: Date;
}): Promise<SignedLease> {
  const now = input.now ?? new Date();
  const iat = Math.floor(now.getTime() / 1000);
  const exp = iat + getLeaseTtlSeconds();
  const keyId = getLeaseKeyId();

  const claims: LeaseClaims = {
    schemaVersion: 1,
    sub: input.userId,
    deviceId: input.deviceId,
    accessStatus: input.entitlement.accessStatus,
    features: input.entitlement.features,
    iat,
    exp,
    keyId,
    aud: LEASE_AUDIENCE,
  };

  const payload = bytesToBase64Url(new TextEncoder().encode(canonicalJson(claims)));
  const alg = (Deno.env.get("ENTITLEMENT_SIGNING_ALG") ?? "hmac").toLowerCase();

  if (alg === "ed25519") {
    const pkcs8B64 = Deno.env.get("ENTITLEMENT_SIGNING_PRIVATE_KEY_PKCS8_B64");
    if (!pkcs8B64) {
      throw new AppError(
        "misconfigured",
        "ENTITLEMENT_SIGNING_PRIVATE_KEY_PKCS8_B64 is required for Ed25519 leases.",
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
    return { payload, signature: bytesToBase64Url(new Uint8Array(sig)), keyId };
  }

  const secret = Deno.env.get("ENTITLEMENT_SIGNING_HMAC_SECRET");
  if (!secret) {
    throw new AppError(
      "misconfigured",
      "ENTITLEMENT_SIGNING_HMAC_SECRET is required for lease signing.",
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
  return { payload, signature: bytesToBase64Url(new Uint8Array(sig)), keyId };
}

function toArrayBuffer(bytes: Uint8Array): ArrayBuffer {
  return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
}

export async function verifyLeaseHmac(
  lease: SignedLease,
  secret: string,
  opts: { deviceId: string; nowMs?: number; audience?: string },
): Promise<LeaseClaims> {
  const key = await crypto.subtle.importKey(
    "raw",
    toArrayBuffer(new TextEncoder().encode(secret)),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  const ok = await crypto.subtle.verify(
    "HMAC",
    key,
    toArrayBuffer(base64UrlToBytes(lease.signature)),
    toArrayBuffer(new TextEncoder().encode(lease.payload)),
  );
  if (!ok) {
    throw new AppError("invalid_lease", "Lease signature invalid.", 401);
  }
  const claims = JSON.parse(
    new TextDecoder().decode(base64UrlToBytes(lease.payload)),
  ) as LeaseClaims;
  const nowMs = opts.nowMs ?? Date.now();
  if (claims.exp * 1000 <= nowMs) {
    throw new AppError("lease_expired", "Offline lease expired.", 401);
  }
  if (claims.deviceId !== opts.deviceId) {
    throw new AppError("lease_device_mismatch", "Lease device mismatch.", 401);
  }
  if (claims.aud !== (opts.audience ?? LEASE_AUDIENCE)) {
    throw new AppError("lease_audience_mismatch", "Lease audience mismatch.", 401);
  }
  return claims;
}
