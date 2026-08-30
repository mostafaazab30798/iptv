/**
 * Billing provider boundary. Production provider is not configured yet.
 */

import { AppError } from "./errors.ts";

export type CheckoutSessionInput = {
  userId: string;
  planCode: string;
  successUrl: string;
  cancelUrl: string;
};

export type CheckoutSessionResult = {
  provider: string;
  checkoutUrl: string;
  sessionId: string;
};

export type CustomerPortalInput = {
  userId: string;
  returnUrl: string;
};

export type CustomerPortalResult = {
  portalUrl: string;
};

export type ParsedWebhookEvent = {
  providerEventId: string;
  type: string;
  providerCustomerId?: string;
  providerSubscriptionId?: string;
  occurredAt: Date;
  rawSummary: Record<string, unknown>;
};

export type ProviderSubscription = {
  providerSubscriptionId: string;
  status: string;
  currentPeriodEnd: Date | null;
};

export interface BillingProvider {
  createCheckoutSession(
    input: CheckoutSessionInput,
  ): Promise<CheckoutSessionResult>;
  createCustomerPortalSession(
    input: CustomerPortalInput,
  ): Promise<CustomerPortalResult>;
  verifyAndParseWebhook(
    rawBody: string,
    headers: Headers,
  ): Promise<ParsedWebhookEvent>;
  retrieveSubscription(
    providerSubscriptionId: string,
  ): Promise<ProviderSubscription>;
}

/** Fails closed until a real hosted billing provider is approved. */
export class NotConfiguredBillingProvider implements BillingProvider {
  async createCheckoutSession(
    _input: CheckoutSessionInput,
  ): Promise<CheckoutSessionResult> {
    throw new AppError(
      "billing_not_configured",
      "Billing is not configured for HOPE TV yet. Checkout is unavailable.",
      503,
    );
  }

  async createCustomerPortalSession(
    _input: CustomerPortalInput,
  ): Promise<CustomerPortalResult> {
    throw new AppError(
      "billing_not_configured",
      "Billing is not configured for HOPE TV yet. Customer portal is unavailable.",
      503,
    );
  }

  async verifyAndParseWebhook(
    _rawBody: string,
    _headers: Headers,
  ): Promise<ParsedWebhookEvent> {
    throw new AppError(
      "billing_not_configured",
      "Billing is not configured for HOPE TV yet. Webhooks are rejected.",
      503,
    );
  }

  async retrieveSubscription(
    _providerSubscriptionId: string,
  ): Promise<ProviderSubscription> {
    throw new AppError(
      "billing_not_configured",
      "Billing is not configured for HOPE TV yet.",
      503,
    );
  }
}

export function getBillingProvider(): BillingProvider {
  const name = (Deno.env.get("BILLING_PROVIDER") ?? "none").toLowerCase();
  if (name === "none" || name === "not_configured") {
    return new NotConfiguredBillingProvider();
  }
  // Future providers register here after owner approval.
  return new NotConfiguredBillingProvider();
}
