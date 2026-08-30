# HOPE TV — Owner Configuration

Non-secret commercial configuration for the control plane.  
Aligned with `MASTER_SUBSCRIPTION_ANALYTICS_AGENT_PLAN.md` Section 0 and Section 5.  
**Never put API keys, signing passwords, webhook secrets, or email credentials in this file.**

| Key | Value | Status |
|---|---|---|
| Product / business name | **HOPE TV** | Confirmed (trademark/legal validation still required before commercial launch) |
| Customer portal frontend | Cloudflare Pages (small web app) | Confirmed |
| Owner dashboard frontend | **`hope-tv-insights/`** (TanStack Start + React) — see `hope-tv-insights/INTEGRATION.md` | Confirmed |
| Legacy dashboard scaffold | `admin-dashboard/` (minimal Vite app; superseded by hope-tv-insights) | Deprecated |
| Owner dashboard backend | Supabase Edge Function `admin-api` (no service-role in browser) | Confirmed |
| Commercial backend | Supabase Auth + PostgreSQL + Edge Functions | Confirmed |
| Release storage / delivery | Private Cloudflare R2 + isolated download Worker | Confirmed |
| Temporary customer website | Available `*.pages.dev` name | Free staging path; exact name unresolved |
| Temporary owner dashboard | `https://hope-tv.mostafaazab3024.workers.dev` | Confirmed and configured in Supabase CORS |
| Temporary download endpoint | Generated `*.workers.dev` | Free staging path |
| Temporary API endpoint | `https://<project-ref>.supabase.co` | Free staging path |
| Production website domain | `PLACEHOLDER_WEBSITE_DOMAIN` | Required before paid production |
| Production API / custom domain | `PLACEHOLDER_API_DOMAIN` | Optional; unresolved |
| Portal origin | `https://hope-tv.mostafaazab3024.workers.dev` | Current shared browser origin configured through `PORTAL_ORIGIN` |
| Admin dashboard origin | `https://hope-tv.mostafaazab3024.workers.dev` | Confirmed; exact origin has no trailing slash |
| Android application ID | Proposed `com.hopetv.iptvplayer` | **Unconfirmed** — do not change `com.example.iptv` until owner approves |
| Windows publisher identity | `PLACEHOLDER_WINDOWS_PUBLISHER` | Unresolved |
| Merchant country / entity | `PLACEHOLDER_MERCHANT_ENTITY` | Unresolved |
| Payment provider | `PLACEHOLDER_PAYMENT_PROVIDER` | Unresolved — NotConfigured provider fails closed |
| Monthly price | `PLACEHOLDER_MONTHLY_PRICE` | Unresolved |
| Yearly price | `PLACEHOLDER_YEARLY_PRICE` | Unresolved |
| Tax handling | `PLACEHOLDER_TAX_HANDLING` | Unresolved |
| Refund policy | `PLACEHOLDER_REFUND_POLICY` | Unresolved |
| Device limit | `3` | Recommended; owner confirmation required |
| Failed-payment grace period | `72` hours | Recommended; owner confirmation required |
| Offline entitlement lease | `24` hours | Recommended; owner confirmation required |
| Entitlement signing key ID | `entitlement-prod-2026-08-29-01` | Production Ed25519 key configured in Supabase |
| Entitlement public key (hex) | `64eb26d19dafdd3a1ffd3e0c7a5998554579a5e967215c334a194e5638023952` | Non-secret; embed through `ENTITLEMENT_PUBLIC_KEYS_JSON` |
| Trial duration (new trials) | `7` days | Server-authoritative; snapshot on activation |
| Email delivery provider | `PLACEHOLDER_EMAIL_PROVIDER` | Unresolved |
| Support contact email | `PLACEHOLDER_SUPPORT_EMAIL` | Unresolved |
| Support contact URL | `PLACEHOLDER_SUPPORT_URL` | Unresolved |
| Supabase region | `ap-southeast-1` | Confirmed from linked project |
| Supabase project (local) | local CLI stack | See LOCAL_DEV.md |
| Supabase project (staging) | `PLACEHOLDER_SUPABASE_STAGING_PROJECT` | Unresolved |
| Supabase project (production) | `otmovtxevvuxbsrmurkb` (`iptv`) | Linked; paid plan with backups required before paying users |
| Distribution mode | **Manual** until Phase 6 | APK / Windows installer by hand |

## Environments

| Environment | Purpose | Secrets location |
|---|---|---|
| local | Developer machine via Supabase CLI | Local `.env` / Vault (gitignored) |
| staging | Free Pages / Workers / Supabase project | Staging secret store only |
| production | Live customers + custom domain | Production secret store only |

Example env files contain placeholders only. Real values never belong in Git.
