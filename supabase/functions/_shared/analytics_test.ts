/**
 * Unit tests for analytics event allowlist and forbidden-property stripping.
 */
import {
  ALLOWED_EVENT_NAMES,
  sanitizeProperties,
  validateAndSanitizeEvent,
} from "./analytics.ts";
import { AppError } from "./errors.ts";

Deno.test("allowlist includes session and entitlement events", () => {
  if (!ALLOWED_EVENT_NAMES.has("session_started")) {
    throw new Error("session_started missing");
  }
  if (!ALLOWED_EVENT_NAMES.has("iptv_connection_succeeded")) {
    throw new Error("iptv_connection_succeeded missing");
  }
});

Deno.test("rejects unknown event names", () => {
  try {
    validateAndSanitizeEvent({
      eventId: "11111111-1111-4111-8111-111111111111",
      eventName: "channel_watched",
      occurredAt: new Date().toISOString(),
    });
    throw new Error("expected validation failure");
  } catch (error) {
    if (!(error instanceof AppError) || error.code !== "validation_error") {
      throw error;
    }
  }
});

Deno.test("rejects forbidden IPTV properties", () => {
  try {
    sanitizeProperties({ serverUrl: "http://evil.example" });
    throw new Error("expected forbidden_property");
  } catch (error) {
    if (!(error instanceof AppError) || error.code !== "forbidden_property") {
      throw error;
    }
  }
});

Deno.test("accepts safe properties", () => {
  const props = sanitizeProperties({
    reason: "trial_expired",
    platform: "android",
  });
  if (props.reason !== "trial_expired") {
    throw new Error("safe property stripped incorrectly");
  }
});

Deno.test("validateAndSanitizeEvent accepts valid payload", () => {
  const event = validateAndSanitizeEvent({
    eventId: "22222222-2222-4222-8222-222222222222",
    eventName: "session_started",
    occurredAt: new Date().toISOString(),
    platform: "android",
    properties: { foreground: true },
  });
  if (event.eventName !== "session_started") {
    throw new Error("event name mismatch");
  }
});
