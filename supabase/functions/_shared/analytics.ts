/**
 * Analytics event validation and sanitization.
 * Rejects forbidden IPTV/credential properties per master plan §13.3.
 */

import { AppError } from "./errors.ts";

export const ALLOWED_EVENT_NAMES = new Set([
  "app_first_open",
  "app_updated",
  "session_started",
  "session_heartbeat",
  "session_ended",
  "account_created",
  "account_signed_in",
  "device_registered",
  "trial_started",
  "trial_expiring",
  "trial_expired",
  "subscription_page_opened",
  "subscription_activated",
  "subscription_renewed",
  "payment_failed",
  "subscription_canceled",
  "entitlement_refreshed",
  "entitlement_denied",
  "iptv_connection_succeeded",
  "playback_started",
  "playback_failed",
  "download_authorized",
  "release_download_requested",
  "update_available",
  "update_downloaded",
]);

const FORBIDDEN_PROPERTY_KEYS = [
  "password",
  "username",
  "server_url",
  "serverUrl",
  "stream_url",
  "streamUrl",
  "playlist",
  "playlist_url",
  "playlistUrl",
  "channel_title",
  "channelTitle",
  "movie_title",
  "movieTitle",
  "series_title",
  "seriesTitle",
  "email",
  "access_token",
  "accessToken",
  "refresh_token",
  "refreshToken",
  "token",
  "query_string",
  "queryString",
];

const URL_LIKE = /^https?:\/\//i;

export type AnalyticsEventInput = {
  eventId: string;
  eventName: string;
  schemaVersion?: number;
  occurredAt: string;
  platform?: string;
  appVersion?: string;
  installationIdHash?: string;
  properties?: Record<string, unknown>;
};

export const ALLOWED_PLATFORMS = new Set(["android", "windows", "web", "unknown"]);

const MAX_PROPERTIES = 20;
const MAX_PROPERTY_VALUE_LENGTH = 256;
const CLOCK_SKEW_MS = 24 * 60 * 60 * 1000; // ±24 hours

export function validateAndSanitizeEvent(
  raw: Record<string, unknown>,
): AnalyticsEventInput {
  const eventId = typeof raw.eventId === "string" ? raw.eventId.trim() : "";
  const eventName = typeof raw.eventName === "string" ? raw.eventName.trim() : "";
  const occurredAt = typeof raw.occurredAt === "string" ? raw.occurredAt : "";

  if (!eventId || !/^[0-9a-f-]{36}$/i.test(eventId)) {
    throw new AppError("validation_error", "eventId must be a UUID.", 400);
  }
  if (!ALLOWED_EVENT_NAMES.has(eventName)) {
    throw new AppError("validation_error", `Event '${eventName}' is not allowed.`, 400, {
      eventName,
    });
  }
  if (!occurredAt || Number.isNaN(Date.parse(occurredAt))) {
    throw new AppError("validation_error", "occurredAt must be a valid ISO timestamp.", 400);
  }

  // Clock-skew: reject events more than ±24h from server time.
  const eventMs = Date.parse(occurredAt);
  const nowMs = Date.now();
  if (Math.abs(nowMs - eventMs) > CLOCK_SKEW_MS) {
    throw new AppError(
      "clock_skew",
      `occurredAt is more than 24h from server time.`,
      400,
    );
  }

  // Platform allowlist.
  const platformRaw = optionalTrimmedString(raw.platform);
  if (platformRaw !== undefined && !ALLOWED_PLATFORMS.has(platformRaw)) {
    throw new AppError("validation_error", `Platform '${platformRaw}' is not allowed.`, 400);
  }

  const properties = sanitizeProperties(
    (raw.properties && typeof raw.properties === "object" && !Array.isArray(raw.properties))
      ? raw.properties as Record<string, unknown>
      : {},
  );

  return {
    eventId,
    eventName,
    schemaVersion: typeof raw.schemaVersion === "number" ? raw.schemaVersion : 1,
    occurredAt,
    platform: platformRaw,
    appVersion: optionalTrimmedString(raw.appVersion),
    installationIdHash: optionalTrimmedString(raw.installationIdHash),
    properties,
  };
}

function optionalTrimmedString(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

export function sanitizeProperties(
  props: Record<string, unknown>,
): Record<string, unknown> {
  const entries = Object.entries(props);
  if (entries.length > MAX_PROPERTIES) {
    throw new AppError(
      "validation_error",
      `Too many properties: max ${MAX_PROPERTIES}, got ${entries.length}.`,
      400,
    );
  }
  const out: Record<string, unknown> = {};
  for (const [key, value] of entries) {
    const lower = key.toLowerCase();
    if (FORBIDDEN_PROPERTY_KEYS.some((f) => lower.includes(f.toLowerCase()))) {
      throw new AppError(
        "forbidden_property",
        `Property '${key}' is not allowed in analytics.`,
        400,
      );
    }
    if (typeof value === "string") {
      if (URL_LIKE.test(value)) {
        throw new AppError(
          "forbidden_property",
          `URL values are not allowed in analytics properties.`,
          400,
        );
      }
      if (value.length > MAX_PROPERTY_VALUE_LENGTH) {
        throw new AppError(
          "validation_error",
          `Property '${key}' value exceeds max length of ${MAX_PROPERTY_VALUE_LENGTH}.`,
          400,
        );
      }
    }
    if (value !== null && typeof value === "object") {
      continue;
    }
    out[key] = value;
  }
  return out;
}
