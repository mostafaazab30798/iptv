/**
 * Admin path dispatch tests.
 */
import { parseAdminPath } from "./admin_auth.ts";

Deno.test("parseAdminPath overview", () => {
  const { route } = parseAdminPath(new URL("http://localhost/admin-api/v1/overview"));
  if (route !== "overview") throw new Error(`got ${route}`);
});

Deno.test("parseAdminPath user detail", () => {
  const url = new URL("http://x/admin-api/v1/users/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
  const parsed = parseAdminPath(url);
  if (parsed.route !== "users/detail") throw new Error(`got ${parsed.route}`);
  if (parsed.params.userId !== "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa") {
    throw new Error("userId mismatch");
  }
});

Deno.test("parseAdminPath deployed edge function path", () => {
  const session = parseAdminPath(
    new URL("https://ref.supabase.co/functions/v1/admin-api/v1/session"),
  );
  if (session.route !== "session") throw new Error(`session route got ${session.route}`);

  const overview = parseAdminPath(
    new URL("https://ref.supabase.co/functions/v1/admin-api/v1/overview"),
  );
  if (overview.route !== "overview") throw new Error(`overview route got ${overview.route}`);

  const userDetail = parseAdminPath(
    new URL(
      "https://ref.supabase.co/functions/v1/admin-api/v1/users/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    ),
  );
  if (userDetail.route !== "users/detail") throw new Error(`got ${userDetail.route}`);
  if (userDetail.params.userId !== "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa") {
    throw new Error("userId mismatch");
  }
});

Deno.test("parseAdminPath device revoke", () => {
  const parsed = parseAdminPath(
    new URL("http://x/admin-api/v1/devices/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/revoke"),
  );
  if (parsed.route !== "devices/revoke") throw new Error(`got ${parsed.route}`);
});

Deno.test("parseAdminPath entitlement override delete", () => {
  const parsed = parseAdminPath(
    new URL("http://x/admin-api/v1/entitlement-overrides/cccccccc-cccc-cccc-cccc-cccccccccccc"),
  );
  if (parsed.route !== "entitlement-overrides/delete") {
    throw new Error(`got ${parsed.route}`);
  }
});
