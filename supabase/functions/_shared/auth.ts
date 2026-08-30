/**
 * JWT / caller identity helpers for Edge Functions.
 * Uses the request Authorization bearer token; service role must never be sent by clients.
 */

import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";
import { AppError } from "./errors.ts";

export type AuthedUser = {
  id: string;
  email?: string;
};

export function getSupabaseUrl(): string {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) {
    throw new AppError("misconfigured", "SUPABASE_URL is not configured.", 500);
  }
  return url;
}

export function getAnonKey(): string {
  const key = Deno.env.get("SUPABASE_ANON_KEY");
  if (!key) {
    throw new AppError("misconfigured", "SUPABASE_ANON_KEY is not configured.", 500);
  }
  return key;
}

export function getServiceRoleKey(): string {
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!key) {
    throw new AppError(
      "misconfigured",
      "SUPABASE_SERVICE_ROLE_KEY is not configured.",
      500,
    );
  }
  return key;
}

export function bearerToken(req: Request): string {
  const header = req.headers.get("Authorization");
  if (!header?.toLowerCase().startsWith("bearer ")) {
    throw new AppError("unauthenticated", "Missing bearer token.", 401);
  }
  const token = header.slice(7).trim();
  if (!token) {
    throw new AppError("unauthenticated", "Missing bearer token.", 401);
  }
  return token;
}

export function userClientFromRequest(req: Request): SupabaseClient {
  const token = bearerToken(req);
  return createClient(getSupabaseUrl(), getAnonKey(), {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export function serviceClient(): SupabaseClient {
  return createClient(getSupabaseUrl(), getServiceRoleKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function requireUser(req: Request): Promise<AuthedUser> {
  const client = userClientFromRequest(req);
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) {
    throw new AppError("unauthenticated", "Invalid or expired session.", 401);
  }
  return { id: data.user.id, email: data.user.email };
}
