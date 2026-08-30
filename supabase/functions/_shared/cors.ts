/**
 * CORS helpers for Edge Functions.
 * Portal origin is a placeholder until OWNER_CONFIG is filled.
 */

const DEFAULT_ALLOW_HEADERS =
  "authorization, x-client-info, apikey, content-type, x-correlation-id, idempotency-key";

export function portalOrigin(): string {
  return Deno.env.get("PORTAL_ORIGIN") ?? "http://127.0.0.1:3000";
}

export function corsHeaders(requestOrigin: string | null): HeadersInit {
  const allowOrigin = requestOrigin && isAllowedOrigin(requestOrigin)
    ? requestOrigin
    : portalOrigin();

  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers": DEFAULT_ALLOW_HEADERS,
    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    "Vary": "Origin",
  };
}

export function isAllowedOrigin(origin: string): boolean {
  const allowlist = (Deno.env.get("CORS_ALLOWLIST") ?? portalOrigin())
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (allowlist.includes(origin)) return true;

  // Local dashboard dev servers bind to arbitrary ports (5173, 8080, 8084, …).
  // Admin-api remains protected by JWT + private.admin_users.
  try {
    const { hostname, protocol } = new URL(origin);
    if ((hostname === "localhost" || hostname === "127.0.0.1") && protocol === "http:") {
      return true;
    }
  } catch {
    // ignore malformed Origin
  }

  return false;
}

export function handleOptions(req: Request): Response | null {
  if (req.method !== "OPTIONS") return null;
  const origin = req.headers.get("Origin");
  return new Response(null, { status: 204, headers: corsHeaders(origin) });
}
