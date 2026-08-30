/**
 * Legacy opaque download tokens for the deprecated R2 download gateway.
 * Production downloads use GitHub Releases and do not import this module.
 * Format: v1.<base64url(json)>.<base64url(hmac-sha256)>
 */

export type DownloadTokenClaims = {
  tid: string;
  objectKey: string;
  releaseId: string;
  userId: string;
  exp: number;
};

export function getDownloadTokenSecret(): string | undefined {
  return Deno.env.get("DOWNLOAD_TOKEN_HMAC_SECRET");
}

export async function mintDownloadToken(
  claims: DownloadTokenClaims,
  secret?: string,
): Promise<string> {
  const key = secret ?? getDownloadTokenSecret();
  if (!key) {
    throw new Error("DOWNLOAD_TOKEN_HMAC_SECRET is not configured.");
  }
  const payloadB64 = base64UrlFromUtf8(JSON.stringify(claims));
  const sig = await hmacBase64Url(key, payloadB64);
  return `v1.${payloadB64}.${sig}`;
}

export async function verifyDownloadToken(
  token: string,
  secret: string | undefined,
  nowMs: number = Date.now(),
): Promise<
  | { ok: true; claims: DownloadTokenClaims }
  | { ok: false; code: string; message: string }
> {
  if (!token?.startsWith("v1.")) {
    return { ok: false, code: "invalid_token", message: "Missing or malformed token." };
  }
  if (!secret) {
    return { ok: false, code: "misconfigured", message: "Download token secret missing." };
  }

  const parts = token.split(".");
  if (parts.length !== 3) {
    return { ok: false, code: "invalid_token", message: "Malformed token." };
  }

  const [, payloadB64, sigB64] = parts;
  const expected = await hmacBase64Url(secret, payloadB64);
  if (!equalStringsConstantTime(sigB64, expected)) {
    return { ok: false, code: "invalid_signature", message: "Token signature mismatch." };
  }

  let claims: DownloadTokenClaims;
  try {
    claims = JSON.parse(utf8FromBase64Url(payloadB64)) as DownloadTokenClaims;
  } catch {
    return { ok: false, code: "invalid_token", message: "Invalid token payload." };
  }

  if (!claims.tid || !claims.objectKey || !claims.releaseId || !claims.userId || !claims.exp) {
    return { ok: false, code: "invalid_token", message: "Token claims incomplete." };
  }

  if (claims.exp * 1000 <= nowMs) {
    return { ok: false, code: "token_expired", message: "Download token expired." };
  }

  return { ok: true, claims };
}

export function hashTokenForStorage(token: string): Promise<string> {
  return crypto.subtle.digest("SHA-256", new TextEncoder().encode(token)).then((buf) => {
    const bytes = new Uint8Array(buf);
    return Array.from(bytes).map((b) => b.toString(16).padStart(2, "0")).join("");
  });
}

async function hmacBase64Url(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return base64UrlFromBytes(new Uint8Array(sig));
}

function base64UrlFromUtf8(value: string): string {
  return base64UrlFromBytes(new TextEncoder().encode(value));
}

function utf8FromBase64Url(value: string): string {
  const padded = value.replace(/-/g, "+").replace(/_/g, "/");
  const pad = padded.length % 4 === 0 ? "" : "=".repeat(4 - (padded.length % 4));
  const binary = atob(padded + pad);
  const bytes = Uint8Array.from(binary, (c) => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

function base64UrlFromBytes(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function equalStringsConstantTime(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let out = 0;
  for (let i = 0; i < a.length; i++) out |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return out === 0;
}
