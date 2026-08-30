# ADR 0005: Manual distribution until automated downloads

## Status

Superseded by [ADR 0008](./0008-github-releases.md).

## Context

HOPE TV will be distributed directly (not via Play Store / App Store). Automated signed download tracking is planned, but the owner will distribute APK and Windows installers manually for now.

## Decision

- Operational distribution mode is **manual** until Phase 6 gates pass.
- Scaffold `services/download_gateway` with private R2 binding placeholders and no production secrets.
- Do not publish public permanent R2 URLs.
- Release metadata tables exist in PostgreSQL so automated delivery can attach later without schema churn.

## Consequences

- Download analytics remain incomplete until authorized download flow is live.
- Manual releases must still follow signing and checksum hygiene before customer builds.
