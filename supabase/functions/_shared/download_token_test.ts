import {
  mintDownloadToken,
  verifyDownloadToken,
} from "./download_token.ts";

const secret = "phase6-test-secret";

Deno.test("mint and verify download token", async () => {
  const token = await mintDownloadToken(
    {
      tid: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      objectKey: "releases/android/app.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) + 120,
    },
    secret,
  );
  const result = await verifyDownloadToken(token, secret);
  if (!result.ok) throw new Error("expected valid token");
  if (result.claims.tid !== "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa") {
    throw new Error("tid mismatch");
  }
});

Deno.test("rejects expired download token", async () => {
  const token = await mintDownloadToken(
    {
      tid: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      objectKey: "releases/android/app.apk",
      releaseId: "rel-1",
      userId: "user-1",
      exp: Math.floor(Date.now() / 1000) - 5,
    },
    secret,
  );
  const result = await verifyDownloadToken(token, secret);
  if (result.ok || result.code !== "token_expired") {
    throw new Error("expected token_expired");
  }
});
