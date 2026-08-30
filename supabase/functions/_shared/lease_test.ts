/**
 * Lease HMAC round-trip tests.
 * Run: deno test supabase/functions/_shared/lease_test.ts
 */

import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { evaluateEntitlement } from "./entitlement.ts";
import { signLease, verifyLeaseHmac } from "./lease.ts";
import { AppError } from "./errors.ts";

Deno.test("sign and verify lease with HMAC", async () => {
  Deno.env.set("ENTITLEMENT_SIGNING_ALG", "hmac");
  Deno.env.set("ENTITLEMENT_SIGNING_HMAC_SECRET", "test-secret-phase3");
  Deno.env.set("ENTITLEMENT_SIGNING_KEY_ID", "entitlement-dev-1");
  Deno.env.set("OFFLINE_LEASE_HOURS", "24");

  const entitlement = evaluateEntitlement(
    {
      accountStatus: "active",
      deviceRevoked: false,
      trial: {
        status: "active",
        endsAt: new Date("2026-09-05T12:00:00.000Z"),
      },
      subscription: null,
      override: null,
      features: { liveTv: true },
      deviceLimit: 3,
      minimumSupportedVersion: "0.1.0",
      planCode: null,
    },
    { now: () => new Date("2026-08-29T12:00:00.000Z") },
  );

  const lease = await signLease({
    userId: "user-1",
    deviceId: "device-1",
    entitlement,
    now: new Date("2026-08-29T12:00:00.000Z"),
  });

  const claims = await verifyLeaseHmac(lease, "test-secret-phase3", {
    deviceId: "device-1",
    nowMs: Date.parse("2026-08-29T12:00:00.000Z"),
  });
  assertEquals(claims.accessStatus, "trialing");
  assertEquals(claims.deviceId, "device-1");
});

Deno.test("lease rejects wrong device", async () => {
  Deno.env.set("ENTITLEMENT_SIGNING_HMAC_SECRET", "test-secret-phase3");
  const entitlement = evaluateEntitlement(
    {
      accountStatus: "active",
      deviceRevoked: false,
      trial: { status: "active", endsAt: new Date("2026-09-05T12:00:00.000Z") },
      subscription: null,
      override: null,
      features: { liveTv: true },
      deviceLimit: 3,
      minimumSupportedVersion: "0.1.0",
      planCode: null,
    },
    { now: () => new Date("2026-08-29T12:00:00.000Z") },
  );
  const lease = await signLease({
    userId: "user-1",
    deviceId: "device-1",
    entitlement,
    now: new Date("2026-08-29T12:00:00.000Z"),
  });
  await assertRejects(
    () =>
      verifyLeaseHmac(lease, "test-secret-phase3", {
        deviceId: "other-device",
        nowMs: Date.parse("2026-08-29T12:00:00.000Z"),
      }),
    AppError,
  );
});
