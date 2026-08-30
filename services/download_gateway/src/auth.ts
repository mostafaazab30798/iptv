/**
 * Download authorization verification for the isolated download gateway.
 */

export type DownloadAuthResult =
  | { ok: true; objectKey: string; releaseId: string; userId: string; tokenId: string }
  | { ok: false; status: number; code: string; message: string };

export type Env = {
  RELEASES: R2Bucket;
  PRODUCT_NAME: string;
  SUPABASE_URL: string;
  DOWNLOAD_TOKEN_HMAC_SECRET?: string;
  DOWNLOAD_CONSUME_URL?: string;
  GATEWAY_SERVICE_SECRET?: string;
};

type TokenClaims = {
  tid?: string;
  objectKey?: string;
  releaseId?: string;
  userId?: string;
  exp?: number;
};

export async function verifyDownloadToken(
  token: string,
  env: Env,
  nowMs: number = Date.now(),
): Promise<DownloadAuthResult> {
  const secret = env.DOWNLOAD_TOKEN_HMAC_SECRET;
  if (!token || !token.startsWith("v1.")) {
    return {
      ok: false,
      status: 401,
      code: "invalid_token",
      message: "Missing or malformed download token.",
    };
  }

  if (!secret) {
    return {
      ok: false,
      status: 503,
      code: "gateway_not_configured",
      message: "Download gateway secrets are not configured.",
    };
  }

  const parts = token.split(".");
  if (parts.length !== 3) {
    return {
      ok: false,
      status: 401,
      code: "invalid_token",
      message: "Malformed download token.",
    };
  }

  const [, payloadB64, sigB64] = parts;
  const expectedSig = await hmacBase64Url(secret, payloadB64);
  if (!equalStringsConstantTime(sigB64, expectedSig)) {
    return {
      ok: false,
      status: 401,
      code: "invalid_signature",
      message: "Download token signature mismatch.",
    };
  }

  let payload: TokenClaims;
  try {
    payload = JSON.parse(utf8FromBase64Url(payloadB64));
  } catch {
    return {
      ok: false,
      status: 401,
      code: "invalid_token",
      message: "Download token payload is invalid.",
    };
  }

  if (!payload.tid || !payload.objectKey || !payload.releaseId || !payload.userId || !payload.exp) {
    return {
      ok: false,
      status: 401,
      code: "invalid_token",
      message: "Download token claims incomplete.",
    };
  }

  if (payload.exp * 1000 <= nowMs) {
    return {
      ok: false,
      status: 401,
      code: "token_expired",
      message: "Download token expired.",
    };
  }

  const consumed = await consumeToken(env, payload.tid);
  if (!consumed.ok) {
    return {
      ok: false,
      status: consumed.status,
      code: consumed.code,
      message: consumed.message,
    };
  }

  return {
    ok: true,
    objectKey: consumed.objectKey ?? payload.objectKey,
    releaseId: payload.releaseId,
    userId: payload.userId,
    tokenId: payload.tid,
  };
}

async function consumeToken(
  env: Env,
  tokenId: string,
): Promise<
  | { ok: true; objectKey?: string }
  | { ok: false; status: number; code: string; message: string }
> {
  const url = env.DOWNLOAD_CONSUME_URL;
  const secret = env.GATEWAY_SERVICE_SECRET;
  if (!url || !secret) {
    // Local dev without consume wiring falls back to signature-only verification.
    return { ok: true };
  }

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Gateway-Secret": secret,
    },
    body: JSON.stringify({ tokenId }),
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({})) as {
      error?: { code?: string; message?: string };
    };
    return {
      ok: false,
      status: res.status,
      code: body.error?.code ?? "consume_denied",
      message: body.error?.message ?? "Download authorization was rejected.",
    };
  }

  const data = await res.json() as { objectKey?: string };
  return { ok: true, objectKey: data.objectKey };
}

/** Test helper — mints v1 token with tid claim. */
export async function mintTestToken(
  secret: string,
  claims: {
    tid: string;
    objectKey: string;
    releaseId: string;
    userId: string;
    exp: number;
  },
): Promise<string> {
  const payloadB64 = base64UrlFromUtf8(JSON.stringify(claims));
  const sig = await hmacBase64Url(secret, payloadB64);
  return `v1.${payloadB64}.${sig}`;
}

async function hmacBase64Url(secret: string, message: string): Promise<string> {
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
    new TextEncoder().encode(message),
  );
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
