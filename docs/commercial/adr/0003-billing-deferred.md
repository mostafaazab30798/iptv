# ADR 0003: Billing deferred behind BillingProvider

## Status

Accepted

## Context

HOPE TV needs production-grade trial and entitlement foundations, but no payment provider is selected yet. Inventing a production provider would violate the master plan.

## Decision

- Define a server-side `BillingProvider` interface (`createCheckoutSession`, `createCustomerPortalSession`, `verifyAndParseWebhook`, `retrieveSubscription`).
- Ship a **NotConfigured** implementation that fails closed with a clear error for checkout/webhook operations.
- Keep subscription tables and webhook event schema ready for a future provider.
- Entitlement evaluation remains server-authoritative and testable without live billing.

## Consequences

- Paid access cannot be granted until a real provider is wired and sandbox-tested.
- Trial and device limits can still be implemented and tested.
- Owner must confirm provider, prices, and tax/refund policy before Phase 4 production billing work.
