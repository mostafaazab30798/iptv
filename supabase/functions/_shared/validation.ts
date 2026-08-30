/**
 * Request validation helpers.
 */

import { AppError } from "./errors.ts";

export async function readJsonObject(req: Request): Promise<Record<string, unknown>> {
  const contentType = req.headers.get("Content-Type") ?? "";
  if (req.method !== "GET" && req.method !== "HEAD" && req.method !== "OPTIONS") {
    if (!contentType.includes("application/json")) {
      throw new AppError(
        "unsupported_media_type",
        "Content-Type must be application/json.",
        415,
      );
    }
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    throw new AppError("invalid_json", "Request body must be valid JSON.", 400);
  }

  if (!body || typeof body !== "object" || Array.isArray(body)) {
    throw new AppError("invalid_body", "Request body must be a JSON object.", 400);
  }

  return body as Record<string, unknown>;
}

export function requireString(
  obj: Record<string, unknown>,
  key: string,
): string {
  const value = obj[key];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new AppError("validation_error", `Field '${key}' is required.`, 400, {
      field: key,
    });
  }
  return value.trim();
}

export function optionalString(
  obj: Record<string, unknown>,
  key: string,
): string | undefined {
  const value = obj[key];
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") {
    throw new AppError("validation_error", `Field '${key}' must be a string.`, 400, {
      field: key,
    });
  }
  return value.trim();
}

/** Soft rate-limit interface — Phase 1 stub; replace with durable limiter later. */
export interface RateLimiter {
  check(key: string, limit: number, windowMs: number): Promise<void>;
}

export class InMemoryRateLimiter implements RateLimiter {
  private readonly hits = new Map<string, number[]>();

  async check(key: string, limit: number, windowMs: number): Promise<void> {
    const now = Date.now();
    const windowStart = now - windowMs;
    const prior = (this.hits.get(key) ?? []).filter((t) => t >= windowStart);
    if (prior.length >= limit) {
      throw new AppError("rate_limited", "Too many requests. Try again later.", 429);
    }
    prior.push(now);
    this.hits.set(key, prior);
  }
}
