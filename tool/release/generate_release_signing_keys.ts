/**
 * Generates an Ed25519 release manifest signing keypair compatible with
 * supabase/functions/_shared/release_signing.ts and Flutter ReleaseVerifier.
 *
 * Usage:
 *   deno run --allow-write tool/release/generate_release_signing_keys.ts
 *   deno run --allow-write --allow-env tool/release/generate_release_signing_keys.ts --upload
 */

import { parseArgs } from "jsr:@std/cli/parse-args";

const KEY_ID = `release-prod-${new Date().toISOString().slice(0, 10)}-01`;
const OUT_DIR = "secrets/release-signing";

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary);
}

async function main() {
  const args = parseArgs(Deno.args, { boolean: ["upload"] });
  const upload = args.upload === true;

  const keyPair = await crypto.subtle.generateKey(
    { name: "Ed25519" },
    true,
    ["sign", "verify"],
  );

  const pkcs8Der = new Uint8Array(
    await crypto.subtle.exportKey("pkcs8", keyPair.privateKey),
  );
  const rawPublic = new Uint8Array(
    await crypto.subtle.exportKey("raw", keyPair.publicKey),
  );

  const pkcs8B64 = bytesToBase64(pkcs8Der);
  const publicHex = bytesToHex(rawPublic);
  const publicKeysJson = JSON.stringify({ [KEY_ID]: publicHex });

  await Deno.mkdir(OUT_DIR, { recursive: true });

  const readme = [
    "HOPE TV release manifest signing material",
    `Generated: ${new Date().toISOString()}`,
    `Key ID: ${KEY_ID}`,
    "",
    "Supabase Edge Function secrets:",
    "  RELEASE_SIGNING_ALG=ed25519",
    `  RELEASE_SIGNING_KEY_ID=${KEY_ID}`,
    `  RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64=<see release-private.pkcs8.b64.txt>`,
    "",
    "GitHub Actions secret:",
    `  RELEASE_PUBLIC_KEYS_JSON=${publicKeysJson}`,
    "",
    "KEEP OFFLINE. Never commit this directory.",
  ].join("\n");

  await Deno.writeTextFile(`${OUT_DIR}/README.txt`, readme);
  await Deno.writeTextFile(`${OUT_DIR}/release-private.pkcs8.b64.txt`, pkcs8B64);
  await Deno.writeTextFile(`${OUT_DIR}/release-public.hex.txt`, publicHex);
  await Deno.writeTextFile(`${OUT_DIR}/release-public-keys.json`, publicKeysJson);

  // Round-trip sign/verify using the same algorithm as production.
  const testBody = {
    schemaVersion: 1,
    platform: "android",
    architecture: "arm64-v8a",
    channel: "stable",
    version: "0.0.0",
    buildNumber: 1,
    minimumSupportedVersion: null,
    mandatory: false,
    fileSize: 1,
    sha256: "aa".repeat(32),
    downloadAuthorizationPath: "/v1/downloads/authorize",
    publishedAt: new Date().toISOString(),
    releaseNotesEn: null,
    releaseNotesAr: null,
    keyId: KEY_ID,
  };
  const payloadB64 = bytesToBase64(
    new TextEncoder().encode(JSON.stringify(testBody)),
  ).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
  const sig = await crypto.subtle.sign(
    "Ed25519",
    keyPair.privateKey,
    new TextEncoder().encode(payloadB64),
  );
  const ok = await crypto.subtle.verify(
    "Ed25519",
    keyPair.publicKey,
    sig,
    new TextEncoder().encode(payloadB64),
  );
  if (!ok) throw new Error("Self-test Ed25519 sign/verify failed.");

  console.log(`Generated release signing keys in secrets/release-signing/`);
  console.log(`Key ID: ${KEY_ID}`);
  console.log(`Public hex length: ${publicHex.length} chars`);

  if (upload) {
    const repoRoot = Deno.cwd();
    const supabase = new Deno.Command("supabase", {
      args: [
        "secrets",
        "set",
        `RELEASE_SIGNING_ALG=ed25519`,
        `RELEASE_SIGNING_KEY_ID=${KEY_ID}`,
        `RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64=${pkcs8B64}`,
      ],
      cwd: repoRoot,
      stdout: "inherit",
      stderr: "inherit",
    });
    const supaStatus = await supabase.spawn().status;
    if (!supaStatus.success) {
      throw new Error("supabase secrets set failed.");
    }

    const gh = new Deno.Command("gh", {
      args: ["secret", "set", "RELEASE_PUBLIC_KEYS_JSON", "--body", publicKeysJson],
      cwd: repoRoot,
      stdout: "inherit",
      stderr: "inherit",
    });
    const ghStatus = await gh.spawn().status;
    if (!ghStatus.success) {
      throw new Error("gh secret set RELEASE_PUBLIC_KEYS_JSON failed.");
    }

    console.log("Uploaded Supabase release signing secrets and GitHub RELEASE_PUBLIC_KEYS_JSON.");
  } else {
    console.log("Re-run with --upload to push secrets to Supabase + GitHub.");
  }
}

await main();
