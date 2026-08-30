/**
 * Unit tests for pure entitlement evaluation and NotConfigured billing.
 * Run: deno test supabase/functions/_shared/
 */

import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  evaluateEntitlement,
  type Clock,
  type EntitlementInput,
} from "./entitlement.ts";
import { NotConfiguredBillingProvider } from "./billing_provider.ts";
import { AppError } from "./errors.ts";
import { redactObject } from "./logging.ts";

function fixedClock(iso: string): Clock {
  return { now: () => new Date(iso) };
}

function baseInput(partial: Partial<EntitlementInput> = {}): EntitlementInput {
  return {
    accountStatus: "active",
    deviceRevoked: false,
    trial: null,
    subscription: null,
    override: null,
    features: { liveTv: true, movies: true },
    deviceLimit: 3,
    minimumSupportedVersion: "0.1.0",
    planCode: null,
    ...partial,
  };
}

Deno.test("active trial grants trialing access until ends_at", () => {
  const clock = fixedClock("2026-08-29T12:00:00.000Z");
  const result = evaluateEntitlement(
    baseInput({
      trial: {
        status: "active",
        endsAt: new Date("2026-09-05T12:00:00.000Z"),
      },
    }),
    clock,
  );
  assertEquals(result.accessStatus, "trialing");
  assertEquals(result.validUntil, "2026-09-05T12:00:00.000Z");
  assertEquals(result.reason, "trial_active");
});

Deno.test("trial expires exactly at ends_at boundary", () => {
  const ends = "2026-09-05T12:00:00.000Z";
  const clock = fixedClock(ends);
  const result = evaluateEntitlement(
    baseInput({
      trial: { status: "active", endsAt: new Date(ends) },
    }),
    clock,
  );
  assertEquals(result.accessStatus, "denied");
  assertEquals(result.reason, "trial_expired");
});

Deno.test("paid subscription active until period end", () => {
  const clock = fixedClock("2026-08-29T12:00:00.000Z");
  const result = evaluateEntitlement(
    baseInput({
      planCode: "monthly",
      subscription: {
        status: "active",
        currentPeriodEnd: new Date("2026-09-29T12:00:00.000Z"),
        gracePeriodEndsAt: null,
      },
    }),
    clock,
  );
  assertEquals(result.accessStatus, "active");
  assertEquals(result.reason, "subscription_active");
});

Deno.test("grace period grants grace_period access", () => {
  const clock = fixedClock("2026-08-29T12:00:00.000Z");
  const result = evaluateEntitlement(
    baseInput({
      subscription: {
        status: "past_due",
        currentPeriodEnd: new Date("2026-08-20T12:00:00.000Z"),
        gracePeriodEndsAt: new Date("2026-08-30T12:00:00.000Z"),
      },
    }),
    clock,
  );
  assertEquals(result.accessStatus, "grace_period");
});

Deno.test("suspended account is denied", () => {
  const result = evaluateEntitlement(
    baseInput({ accountStatus: "suspended" }),
    fixedClock("2026-08-29T12:00:00.000Z"),
  );
  assertEquals(result.accessStatus, "denied");
  assertEquals(result.reason, "account_suspended");
});

Deno.test("revoked device is denied", () => {
  const result = evaluateEntitlement(
    baseInput({
      deviceRevoked: true,
      trial: {
        status: "active",
        endsAt: new Date("2026-09-05T12:00:00.000Z"),
      },
    }),
    fixedClock("2026-08-29T12:00:00.000Z"),
  );
  assertEquals(result.accessStatus, "denied");
  assertEquals(result.reason, "device_revoked");
});

Deno.test("NotConfigured billing fails closed on checkout", async () => {
  const provider = new NotConfiguredBillingProvider();
  await assertRejects(
    () =>
      provider.createCheckoutSession({
        userId: "u1",
        planCode: "monthly",
        successUrl: "https://example.com/ok",
        cancelUrl: "https://example.com/cancel",
      }),
    AppError,
    "Billing is not configured",
  );
});

Deno.test("redaction strips tokens and urls", () => {
  const redacted = redactObject({
    authorization: "Bearer secret",
    streamUrl: "https://iptv.example/live?token=abc",
    ok: "fine",
  });
  assertEquals(redacted.authorization, "[REDACTED]");
  assertEquals(redacted.ok, "fine");
  assertEquals(typeof redacted.streamUrl, "string");
});
