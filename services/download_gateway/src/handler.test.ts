import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { mintTestToken, type Env } from "./auth.ts";
import { handleRequest } from "./handler.ts";

function mockEnv(overrides: Partial<Env> = {}): Env {
  const objects = new Map<string, { body: string; httpEtag: string }>();
  objects.set("releases/android/hope-tv-1.0.0.apk", {
    body: "apk-bytes",
    httpEtag: '"etag-1"',
  });

  return {
    PRODUCT_NAME: "HOPE TV",
    SUPABASE_URL: "https://placeholder.supabase.co",
    DOWNLOAD_TOKEN_HMAC_SECRET: "test-secret",
    RELEASES: {
      async get(key: string) {
        const hit = objects.get(key);
        if (!hit) return null;
        return {
          body: hit.body,
          httpEtag: hit.httpEtag,
          writeHttpMetadata(headers: Headers) {
            headers.set("content-type", "application/vnd.android.package-archive");
          },
        };
      },
    } as unknown as R2Bucket,
    ...overrides,
  };
}

describe("handleRequest", () => {
  it("health reports isolation from IPTV proxy", async () => {
    const res = await handleRequest(
      new Request("https://downloads.example/health"),
      mockEnv(),
    );
    assert.equal(res.status, 200);
    const body = await res.json() as {
      iptvProxyCoupled: boolean;
      product: string;
    };
    assert.equal(body.product, "HOPE TV");
    assert.equal(body.iptvProxyCoupled, false);
  });

  it("streams an authorized object", async () => {
    const token = await mintTestToken("test-secret", {
      tid: "11111111-1111-4111-8111-111111111111",
      objectKey: "releases/android/hope-tv-1.0.0.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) + 60,
    });
    const res = await handleRequest(
      new Request(`https://downloads.example/v1/downloads/${encodeURIComponent(token)}`),
      mockEnv(),
    );
    assert.equal(res.status, 200);
    assert.equal(await res.text(), "apk-bytes");
    assert.equal(res.headers.get("x-hope-release-id"), "rel-1");
  });

  it("rejects expired tokens", async () => {
    const token = await mintTestToken("test-secret", {
      tid: "22222222-2222-4222-8222-222222222222",
      objectKey: "releases/android/hope-tv-1.0.0.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) - 10,
    });
    const res = await handleRequest(
      new Request(`https://downloads.example/v1/downloads/${encodeURIComponent(token)}`),
      mockEnv(),
    );
    assert.equal(res.status, 401);
    const body = await res.json() as { error: { code: string } };
    assert.equal(body.error.code, "token_expired");
  });

  it("does not import or reference root worker.js", async () => {
    // Structural isolation: this package has its own wrangler entrypoint.
    const fs = await import("node:fs");
    const path = await import("node:path");
    const root = path.resolve(import.meta.dirname, "..");
    const wrangler = fs.readFileSync(path.join(root, "wrangler.toml"), "utf8");
    assert.equal(wrangler.includes("hope-tv-download-gateway"), true);
    assert.equal(/^main\s*=\s*"src\/index\.ts"/m.test(wrangler), true);
    assert.equal(wrangler.includes("build/web"), false);
  });
});
