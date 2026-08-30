/**
 * Redacted logging for Edge Functions.
 */

const SENSITIVE_KEY =
  /pass(word)?|secret|token|authorization|cookie|apikey|api_key|refresh|email|hostname|stream|playlist|xtream|credential/i;

export function correlationIdFrom(req: Request): string {
  return req.headers.get("X-Correlation-Id") ?? crypto.randomUUID();
}

export function redactValue(key: string, value: unknown): unknown {
  if (SENSITIVE_KEY.test(key)) return "[REDACTED]";
  if (typeof value === "string" && looksLikeUrl(value)) {
    try {
      const u = new URL(value);
      return `${u.protocol}//${u.host}/[REDACTED_PATH]`;
    } catch {
      return "[REDACTED_STRING]";
    }
  }
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return redactObject(value as Record<string, unknown>);
  }
  return value;
}

export function redactObject(
  input: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(input)) {
    out[k] = redactValue(k, v);
  }
  return out;
}

function looksLikeUrl(value: string): boolean {
  return /^https?:\/\//i.test(value);
}

export function logInfo(
  correlationId: string,
  message: string,
  fields: Record<string, unknown> = {},
): void {
  console.log(JSON.stringify({
    level: "info",
    correlationId,
    message,
    ...redactObject(fields),
  }));
}

export function logError(
  correlationId: string,
  message: string,
  fields: Record<string, unknown> = {},
): void {
  console.error(JSON.stringify({
    level: "error",
    correlationId,
    message,
    ...redactObject(fields),
  }));
}
