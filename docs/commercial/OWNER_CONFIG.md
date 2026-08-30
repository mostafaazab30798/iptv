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
| Release storage / delivery | GitHub Releases + Supabase release metadata | Confirmed and implemented in `.github/workflows/release.yml` |
| Temporary customer website | Available `*.pages.dev` name | Free staging path; exact name unresolved |
| Temporary owner dashboard | `https://hope-tv.mostafaazab3024.workers.dev` | Confirmed and configured in Supabase CORS |
| Temporary API endpoint | `https://<project-ref>.supabase.co` | Free staging path |
| Production website domain | `https://hope-tv.site` (`www` redirects to apex) | Confirmed; DNS resolves on Cloudflare (2026-08-30) |
| Production admin dashboard | `https://admin.hope-tv.site` | Resolves; keep `workers.dev` fallback during cutover |
| Production API / custom domain | `https://api.hope-tv.site` | Optional; keep Supabase project URL until its custom-domain add-on is enabled |
| Portal origin | `https://admin.hope-tv.site` | Production `PORTAL_ORIGIN`; exact origin has no trailing slash |
| Admin dashboard origin | `https://admin.hope-tv.site` | Production target; exact origin has no trailing slash |
| Android application ID | `com.hopetv.iptvplayer` | Set in Gradle for production release builds |
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
| Email delivery provider | turboSMTP through Supabase Custom SMTP | Confirmed; credentials remain in Supabase only |
| Auth sender email | `no-reply@auth.hope-tv.site` | Confirmed target; verify the sending domain in turboSMTP first |
| Android release signing | Generated locally; uploaded as `ANDROID_KEYSTORE_*` GitHub secrets | Ready for CI (backup passwords file is gitignored under `android/keystore/`) |
| Client entitlement verify key | Embedded via `ENTITLEMENT_PUBLIC_KEYS_JSON` secret + workflow default | Set |
| Client portal origin | `PORTAL_ORIGIN=https://admin.hope-tv.site` | Set in GitHub secrets |
| Release manifest public keys | `RELEASE_PUBLIC_KEYS_JSON` | Ed25519 `release-prod-2026-08-30-01` configured in Supabase + GitHub |
| Support contact email | `support@hope-tv.site` | Confirmed address; mailbox/forwarder still owner-operated |
| Support contact URL | `mailto:support@hope-tv.site` | Confirmed |
| Supabase region | `ap-southeast-1` | Confirmed from linked project |
| Supabase project (local) | local CLI stack | See LOCAL_DEV.md |
| Supabase project (staging) | `PLACEHOLDER_SUPABASE_STAGING_PROJECT` | Unresolved |
| Supabase project (production) | `otmovtxevvuxbsrmurkb` (`iptv`) | Linked; paid plan with backups required before paying users |
| Distribution mode | GitHub Actions → GitHub Releases | Automated for Android and Windows |

## Environments

| Environment | Purpose | Secrets location |
|---|---|---|
| local | Developer machine via Supabase CLI | Local `.env` / Vault (gitignored) |
| staging | Free Pages / Workers / Supabase project | Staging secret store only |
| production | Live customers + custom domain | Production secret store only |

Example env files contain placeholders only. Real values never belong in Git.
