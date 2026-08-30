/**
 * Unit tests for account deletion helpers.
 * Run: deno test supabase/functions/_shared/account_deletion_test.ts
 */

import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  assertDeletionConfirmation,
  DELETION_CONFIRM_PHRASE,
  DEFAULT_GRACE_DAYS,
  graceDaysFromEnv,
} from "./account_deletion.ts";
import { AppError } from "./errors.ts";

Deno.test("assertDeletionConfirmation accepts exact phrase", () => {
  assertDeletionConfirmation(DELETION_CONFIRM_PHRASE);
});

Deno.test("assertDeletionConfirmation rejects wrong phrase", () => {
  assertThrows(
    () => assertDeletionConfirmation("delete"),
    AppError,
    "DELETE_MY_ACCOUNT",
  );
});

Deno.test("graceDaysFromEnv defaults when unset", () => {
  const prev = Deno.env.get("DELETION_GRACE_DAYS");
  Deno.env.delete("DELETION_GRACE_DAYS");
  try {
    assertEquals(graceDaysFromEnv(), DEFAULT_GRACE_DAYS);
  } finally {
    if (prev) Deno.env.set("DELETION_GRACE_DAYS", prev);
  }
});

Deno.test("graceDaysFromEnv clamps invalid values", () => {
  const prev = Deno.env.get("DELETION_GRACE_DAYS");
  Deno.env.set("DELETION_GRACE_DAYS", "0");
  try {
    assertEquals(graceDaysFromEnv(), DEFAULT_GRACE_DAYS);
  } finally {
    if (prev) Deno.env.set("DELETION_GRACE_DAYS", prev);
    else Deno.env.delete("DELETION_GRACE_DAYS");
  }
});
