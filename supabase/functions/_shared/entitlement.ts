/**
 * Pure entitlement evaluator — clock injected; no HTTP I/O.
 */

export type AccountStatus =
  | "active"
  | "suspended"
  | "deletion_pending"
  | "deleted";

export type TrialStatus = "pending" | "active" | "expired" | "revoked";

export type SubscriptionStatus =
  | "trialing"
  | "active"
  | "past_due"
  | "grace_period"
  | "canceling_at_period_end"
  | "expired"
  | "refunded"
  | "disputed"
  | "suspended";

export type AccessStatus =
  | "none"
  | "trialing"
  | "active"
  | "grace_period"
  | "denied";

export type Clock = {
  now(): Date;
};

export type EntitlementInput = {
  accountStatus: AccountStatus;
  deviceRevoked: boolean;
  trial: {
    status: TrialStatus;
    endsAt: Date | null;
  } | null;
  subscription: {
    status: SubscriptionStatus;
    currentPeriodEnd: Date | null;
    gracePeriodEndsAt: Date | null;
  } | null;
  override: {
    accessGranted: boolean;
    endsAt: Date | null;
  } | null;
  features: Record<string, boolean>;
  deviceLimit: number;
  minimumSupportedVersion: string;
  planCode: string | null;
};

export type EntitlementResult = {
  accountStatus: AccountStatus;
  accessStatus: AccessStatus;
  planCode: string | null;
  validUntil: string | null;
  serverTime: string;
  deviceLimit: number;
  features: Record<string, boolean>;
  minimumSupportedVersion: string;
  reason: string;
};

export function evaluateEntitlement(
  input: EntitlementInput,
  clock: Clock,
): EntitlementResult {
  const serverTime = clock.now();
  const base = {
    accountStatus: input.accountStatus,
    planCode: input.planCode,
    deviceLimit: input.deviceLimit,
    features: { ...input.features },
    minimumSupportedVersion: input.minimumSupportedVersion,
    serverTime: serverTime.toISOString(),
  };

  if (
    input.accountStatus === "suspended" ||
    input.accountStatus === "deleted" ||
    input.accountStatus === "deletion_pending"
  ) {
    return {
      ...base,
      accessStatus: "denied",
      validUntil: null,
      reason: `account_${input.accountStatus}`,
    };
  }

  if (input.deviceRevoked) {
    return {
      ...base,
      accessStatus: "denied",
      validUntil: null,
      reason: "device_revoked",
    };
  }

  if (input.override?.accessGranted) {
    if (!input.override.endsAt || input.override.endsAt > serverTime) {
      return {
        ...base,
        accessStatus: "active",
        validUntil: input.override.endsAt?.toISOString() ?? null,
        reason: "admin_override",
      };
    }
  }

  const sub = input.subscription;
  if (sub) {
    if (
      (sub.status === "active" || sub.status === "canceling_at_period_end" ||
        sub.status === "trialing") &&
      sub.currentPeriodEnd &&
      sub.currentPeriodEnd > serverTime
    ) {
      return {
        ...base,
        accessStatus: "active",
        validUntil: sub.currentPeriodEnd.toISOString(),
        reason: `subscription_${sub.status}`,
      };
    }

    if (
      (sub.status === "past_due" || sub.status === "grace_period") &&
      sub.gracePeriodEndsAt &&
      sub.gracePeriodEndsAt > serverTime
    ) {
      return {
        ...base,
        accessStatus: "grace_period",
        validUntil: sub.gracePeriodEndsAt.toISOString(),
        reason: "subscription_grace",
      };
    }
  }

  const trial = input.trial;
  if (
    trial &&
    trial.status === "active" &&
    trial.endsAt &&
    trial.endsAt > serverTime
  ) {
    return {
      ...base,
      accessStatus: "trialing",
      validUntil: trial.endsAt.toISOString(),
      reason: "trial_active",
    };
  }

  if (trial?.status === "active" && trial.endsAt && trial.endsAt <= serverTime) {
    return {
      ...base,
      accessStatus: "denied",
      validUntil: null,
      reason: "trial_expired",
    };
  }

  return {
    ...base,
    accessStatus: "none",
    validUntil: null,
    reason: "no_entitlement",
  };
}
