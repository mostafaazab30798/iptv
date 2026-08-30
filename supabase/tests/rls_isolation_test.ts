/**
 * Cross-account RLS behavior checks using the Supabase JS client patterns.
 * Run with: deno test --allow-env --allow-net supabase/tests/rls_isolation_test.ts
 * Requires local Supabase (`supabase start`) and service role + anon keys in env.
 *
 * When env is missing, tests are skipped so CI without Docker still typechecks other suites.
 */

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const url = Deno.env.get("SUPABASE_URL");
const anon = Deno.env.get("SUPABASE_ANON_KEY");
const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const configured = Boolean(url && anon && service);

async function createVerifiedUser(email: string, password: string) {
  const admin = createClient(url!, service!);
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (error) throw error;
  assertExists(data.user);

  const userClient = createClient(url!, anon!);
  const signIn = await userClient.auth.signInWithPassword({ email, password });
  if (signIn.error) throw signIn.error;
  return { admin, user: data.user, client: userClient, accessToken: signIn.data.session!.access_token };
}

Deno.test({
  name: "RLS: user cannot read another profile or trial",
  ignore: !configured,
  async fn() {
    const stamp = Date.now();
    const a = await createVerifiedUser(`a-${stamp}@example.com`, "test-password-a1");
    const b = await createVerifiedUser(`b-${stamp}@example.com`, "test-password-b1");

    await a.admin.from("trials").upsert({
      user_id: a.user.id,
      status: "active",
      started_at: new Date().toISOString(),
      ends_at: new Date(Date.now() + 86400000).toISOString(),
      duration_days_snapshot: 7,
    });

    const { data: foreignProfile } = await b.client
      .from("profiles")
      .select("id")
      .eq("id", a.user.id)
      .maybeSingle();
    assertEquals(foreignProfile, null);

    const { data: foreignTrial } = await b.client
      .from("trials")
      .select("user_id")
      .eq("user_id", a.user.id)
      .maybeSingle();
    assertEquals(foreignTrial, null);

    const { error: insertTrialError } = await b.client.from("trials").insert({
      user_id: b.user.id,
      status: "active",
      started_at: new Date().toISOString(),
      ends_at: new Date(Date.now() + 86400000).toISOString(),
      duration_days_snapshot: 7,
    });
    assertExists(insertTrialError);

    await a.admin.auth.admin.deleteUser(a.user.id);
    await b.admin.auth.admin.deleteUser(b.user.id);
  },
});
