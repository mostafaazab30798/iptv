import { assertEquals } from "jsr:@std/assert";
import {
  buildManifestBody,
  signReleaseManifest,
} from "./release_signing.ts";

Deno.test("signReleaseManifest uses Ed25519 when configured", async () => {
  const prevAlg = Deno.env.get("RELEASE_SIGNING_ALG");
  const prevKeyId = Deno.env.get("RELEASE_SIGNING_KEY_ID");
  const prevPkcs8 = Deno.env.get("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64");

  try {
    const keyPair = await crypto.subtle.generateKey(
      { name: "Ed25519" },
      true,
      ["sign", "verify"],
    ) as CryptoKeyPair;
    const pkcs8 = new Uint8Array(
      await crypto.subtle.exportKey("pkcs8", keyPair.privateKey),
    );
    let binary = "";
    for (const b of pkcs8) binary += String.fromCharCode(b);
    const pkcs8B64 = btoa(binary);

    Deno.env.set("RELEASE_SIGNING_ALG", "ed25519");
    Deno.env.set("RELEASE_SIGNING_KEY_ID", "release-test-1");
    Deno.env.set("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64", pkcs8B64);

    const body = buildManifestBody({
      platform: "android",
      architecture: "arm64-v8a",
      channel: "stable",
      version: "0.1.0",
      buildNumber: 2,
      minimumSupportedVersion: null,
      mandatory: false,
      fileSize: 100,
      sha256: "aa".repeat(32),
      publishedAt: "2026-08-30T00:00:00Z",
      releaseNotesEn: "Test",
      releaseNotesAr: null,
    });

    const signed = await signReleaseManifest(body);
    assertEquals(signed.keyId, "release-test-1");
    assertEquals(typeof signed.signature, "string");
    assertEquals(signed.signature.length > 10, true);
  } finally {
    if (prevAlg === undefined) Deno.env.delete("RELEASE_SIGNING_ALG");
    else Deno.env.set("RELEASE_SIGNING_ALG", prevAlg);
    if (prevKeyId === undefined) Deno.env.delete("RELEASE_SIGNING_KEY_ID");
    else Deno.env.set("RELEASE_SIGNING_KEY_ID", prevKeyId);
    if (prevPkcs8 === undefined) {
      Deno.env.delete("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64");
    } else Deno.env.set("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64", prevPkcs8);
  }
});

Deno.test("signReleaseManifest fails closed when Ed25519 key missing", async () => {
  const prevAlg = Deno.env.get("RELEASE_SIGNING_ALG");
  const prevPkcs8 = Deno.env.get("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64");
  try {
    Deno.env.set("RELEASE_SIGNING_ALG", "ed25519");
    Deno.env.delete("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64");

    const body = buildManifestBody({
      platform: "windows",
      architecture: "x64",
      channel: "stable",
      version: "0.1.0",
      buildNumber: 1,
      minimumSupportedVersion: null,
      mandatory: false,
      fileSize: 100,
      sha256: "bb".repeat(32),
      publishedAt: "2026-08-30T00:00:00Z",
      releaseNotesEn: null,
      releaseNotesAr: null,
    });

    let threw = false;
    try {
      await signReleaseManifest(body);
    } catch (e) {
      threw = true;
      assertEquals((e as { code?: string }).code, "misconfigured");
    }
    assertEquals(threw, true);
  } finally {
    if (prevAlg === undefined) Deno.env.delete("RELEASE_SIGNING_ALG");
    else Deno.env.set("RELEASE_SIGNING_ALG", prevAlg);
    if (prevPkcs8 === undefined) {
      Deno.env.delete("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64");
    } else Deno.env.set("RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64", prevPkcs8);
  }
});
