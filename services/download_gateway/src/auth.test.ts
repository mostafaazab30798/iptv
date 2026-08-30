import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { mintTestToken, verifyDownloadToken, type Env } from "./auth.ts";

function testEnv(secret?: string): Env {
  return {
    PRODUCT_NAME: "HOPE TV",
    SUPABASE_URL: "https://placeholder.supabase.co",
    DOWNLOAD_TOKEN_HMAC_SECRET: secret,
    RELEASES: {} as R2Bucket,
  };
}

describe("verifyDownloadToken", () => {
  it("rejects missing secret as not configured", async () => {
    const result = await verifyDownloadToken("v1.a.b", testEnv());
    assert.equal(result.ok, false);
    if (!result.ok) assert.equal(result.code, "gateway_not_configured");
  });

  it("accepts a valid minted token", async () => {
    const secret = "test-secret";
    const token = await mintTestToken(secret, {
      tid: "11111111-1111-4111-8111-111111111111",
      objectKey: "releases/android/hope-tv-1.0.0.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) + 60,
    });
    const result = await verifyDownloadToken(token, testEnv(secret));
    assert.equal(result.ok, true);
    if (result.ok) {
      assert.equal(result.objectKey, "releases/android/hope-tv-1.0.0.apk");
      assert.equal(result.userId, "user-1");
    }
  });

  it("rejects expired tokens", async () => {
    const secret = "test-secret";
    const token = await mintTestToken(secret, {
      tid: "22222222-2222-4222-8222-222222222222",
      objectKey: "releases/android/hope-tv-1.0.0.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) - 10,
    });
    const result = await verifyDownloadToken(token, testEnv(secret));
    assert.equal(result.ok, false);
    if (!result.ok) assert.equal(result.code, "token_expired");
  });

  it("rejects tampered signatures", async () => {
    const secret = "test-secret";
    const token = await mintTestToken(secret, {
      tid: "33333333-3333-4333-8333-333333333333",
      objectKey: "releases/android/hope-tv-1.0.0.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) + 60,
    });
    const tampered = token.slice(0, -4) + "xxxx";
    const result = await verifyDownloadToken(tampered, testEnv(secret));
    assert.equal(result.ok, false);
  });
});
