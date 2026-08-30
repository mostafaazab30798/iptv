# ADR 0006: Owner dashboard as separate React app + admin-api

## Status

Accepted (per master plan Section 0 and `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md`)

## Context

HOPE TV needs a private owner dashboard for metrics, support actions, config publish, and release metadata. Embedding this in Flutter or exposing the Supabase service-role key to a browser is unsafe.

## Decision

- Implement `admin-dashboard/` as **React + TypeScript + Vite + CSS/CSS Modules**.
- Deploy to Cloudflare Pages (staging: suggested `hope-tv-admin.pages.dev`).
- Back all protected reads/mutations with a single Supabase Edge Function family: **`admin-api`**.
- Require admin role; require MFA/AAL2 for production mutations.
- Append-only audit records for every owner mutation.
- Never ship service-role, billing, R2, webhook, SMTP, or signing secrets to the dashboard bundle.

Dashboard work is Phase 5+ and must follow `ADMIN_DASHBOARD_LLM_AGENT_PLAN.md`. Do not invent alternate metric definitions in React.

## Consequences

- Extra deployable (Pages app) separate from the customer portal and Flutter app.
- Metric authority stays in PostgreSQL / Edge Functions (including WAEA).
- Phase 3–4 can proceed without the dashboard UI, but schema should remain dashboard-ready.
