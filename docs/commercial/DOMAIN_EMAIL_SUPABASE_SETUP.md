# HOPE TV production domain, email, and Supabase setup

Production hostnames:

| Purpose | Hostname |
|---|---|
| Customer web app | `https://hope-tv.site` |
| Canonical redirect | `https://www.hope-tv.site` → `https://hope-tv.site` |
| Owner dashboard | `https://admin.hope-tv.site` |
| Release downloads | GitHub Releases for `mostafaazab30798/iptv` |
| Hosted Supabase | `https://otmovtxevvuxbsrmurkb.supabase.co` |
| Optional Supabase custom domain | `https://api.hope-tv.site` |
| Auth email sender | `no-reply@auth.hope-tv.site` |

Never commit Cloudflare tokens, Resend API keys, Supabase service-role keys, or SMTP passwords.

## 1. Confirm DNS in Cloudflare

The `hope-tv.site` Cloudflare zone is active. The apex currently serves a Hostinger parked page, so verify the zone and existing records before deploying custom-domain routes:

1. Confirm Cloudflare reports the `hope-tv.site` zone as **Active**.
2. Confirm the registrar still uses the two nameservers assigned by Cloudflare.
3. Review existing DNS records before changing or removing the Hostinger parking records.
4. Confirm that `NS`, `A/CNAME`, and HTTPS resolution work before removing any `workers.dev` fallback.

Do not invent A records for Workers. Wrangler/Cloudflare creates the required proxied DNS records when a custom domain is attached.

## 2. Attach Cloudflare services

The root Flutter Worker uses `wrangler.toml` and targets `hope-tv.site` plus `www.hope-tv.site`. Deploy only after the zone is active:

```powershell
flutter build web --release `
  --dart-define=SUPABASE_URL=https://otmovtxevvuxbsrmurkb.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>

services\download_gateway\node_modules\.bin\wrangler.cmd deploy --config wrangler.toml
```

Attach the existing `hope-tv` admin Worker to `admin.hope-tv.site` from **Workers & Pages → hope-tv → Settings → Domains & Routes**.

Release artifacts do not need a Cloudflare hostname. GitHub Actions publishes Android and Windows artifacts to GitHub Releases and writes their URLs into Supabase `release_versions`. The legacy `services/download_gateway` R2 Worker is not deployed.

Keep `https://hope-tv.mostafaazab3024.workers.dev` available during cutover. Remove it from the Supabase CORS allowlist only after `admin.hope-tv.site` is verified.

## 3. Verify the sending domain in Resend

Use the dedicated auth subdomain `auth.hope-tv.site` so authentication email reputation is isolated from support or future marketing email.

1. Create a free Resend account and open **Domains → Add Domain**.
2. Add `auth.hope-tv.site` and choose a region appropriate for the application's users.
3. Copy the exact DNS records Resend supplies into the `hope-tv.site` Cloudflare zone. Keep mail-related records DNS-only when Cloudflare offers a proxy toggle.
4. Wait until Resend reports the domain as verified.
5. Create a sending-only Resend API key and keep it only in Supabase hosted Auth settings; never put it in Flutter, GitHub Actions, a Worker, or a committed file.

Resend's SMTP endpoint is `smtp.resend.com`. Use port `587` with STARTTLS, the literal username `resend`, and the Resend API key as the password. The free plan currently allows 100 messages per day and 3,000 per month, so monitor usage before production growth.

## 4. Configure hosted Supabase Auth

In Supabase project `otmovtxevvuxbsrmurkb`:

### URL Configuration

- Site URL: `https://hope-tv.site`
- Redirect URLs:
  - `https://hope-tv.site/**`
  - `https://www.hope-tv.site/**`
  - `https://admin.hope-tv.site/**`
- Keep localhost redirects only for explicit development use.

### Custom SMTP

- Enable custom SMTP: yes
- Sender email: `no-reply@auth.hope-tv.site`
- Sender name: `HOPE TV`
- Host: `smtp.resend.com`
- Port: `587`
- Username: `resend`
- Password: Resend sending API key

Store these values only in Supabase Auth settings. They are not Edge Function secrets and must never be placed in Flutter, Vite, or GitHub build variables.

### Email templates

The Flutter client expects the six-digit value produced by `{{ .Token }}`. Copy the body from `supabase/templates/magic_link.html` into both hosted Supabase templates:

- **Confirm signup** — used the first time a new email address signs in.
- **Magic Link** — used for an existing account.

Keep OTP length at `6`. Both templates must contain `{{ .Token }}` and must not contain `{{ .ConfirmationURL }}`; otherwise new users receive an activation link while returning users receive a code.

After saving SMTP, review **Authentication → Rate Limits**. Supabase starts custom SMTP projects with conservative email limits; raise them only to a measured production value.

### Edge Function browser origins

Set these Supabase Edge Function secrets:

```text
PORTAL_ORIGIN=https://admin.hope-tv.site
CORS_ALLOWLIST=https://admin.hope-tv.site,https://hope-tv.mostafaazab3024.workers.dev
```

Redeploy the affected Edge Functions after changing secrets.

## 5. Verification before cutover

1. Resolve the website and admin production hostnames over public DNS.
2. Confirm valid HTTPS certificates and redirect `www` to the apex domain.
3. Send an OTP to a non-owner test mailbox and verify the sender, SPF, DKIM, DMARC, Resend delivery log, and six-digit code.
4. Sign in to `admin.hope-tv.site` and confirm `admin-api` preflight responses allow that exact origin.
5. Run the GitHub release workflow and confirm both assets and their Supabase `release_versions` rows use matching GitHub URLs and SHA-256 values.
6. Remove the temporary `workers.dev` origin from CORS only after the new admin hostname passes all checks.
