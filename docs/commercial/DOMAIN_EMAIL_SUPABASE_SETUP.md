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

Never commit Cloudflare tokens, Supabase service-role keys, turboSMTP Consumer Secrets, or SMTP passwords.

## 1. Activate DNS in Cloudflare

The domain currently returns `NXDOMAIN`, and the connected Cloudflare account has no zone for `hope-tv.site`. Complete this before deploying custom-domain routes:

1. In Cloudflare, choose **Add a domain** and enter `hope-tv.site`.
2. Copy the two Cloudflare nameservers shown for the zone.
3. At the registrar where the domain was purchased, replace the current nameservers with those two values.
4. Wait until Cloudflare reports the zone as **Active**.
5. Confirm that `NS`, `A/CNAME`, and HTTPS resolution work before removing any `workers.dev` fallback.

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

## 3. Authenticate the sending domain in turboSMTP

Use the dedicated auth subdomain `auth.hope-tv.site` so authentication email reputation is isolated from support or future marketing email.

1. In turboSMTP, add and verify `auth.hope-tv.site` as a sending domain.
2. Add the exact SPF and DKIM records turboSMTP displays to the Cloudflare DNS zone.
3. Add a DMARC TXT record at `_dmarc.auth` beginning with monitoring mode, for example `v=DMARC1; p=none; adkim=s; aspf=s`.
4. Keep all email-authentication TXT records set to **DNS only**; TXT records are never proxied.
5. Verify SPF, DKIM, and DMARC inside turboSMTP before enabling production Auth email.

turboSMTP's normal SMTP endpoint is `pro.turbo-smtp.com` with authenticated submission on port `587`. EU accounts may be assigned `pro.eu.turbo-smtp.com`; always use the host shown in the account. The username is the turboSMTP Consumer Key and the password is its Consumer Secret.

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
- Host: the host assigned by turboSMTP, normally `pro.turbo-smtp.com`
- Port: `587`
- Username: turboSMTP Consumer Key
- Password: turboSMTP Consumer Secret

Store these values only in Supabase Auth settings. They are not Edge Function secrets and must never be placed in Flutter, Vite, or GitHub build variables.

### Email template

The Flutter client expects the six-digit value produced by `{{ .Token }}`. Copy the body from `supabase/templates/magic_link.html` into the hosted Supabase **Magic Link** template and keep OTP length at `6`.

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
3. Send an OTP to a non-owner test mailbox and verify the sender, SPF, DKIM, DMARC, and six-digit code.
4. Sign in to `admin.hope-tv.site` and confirm `admin-api` preflight responses allow that exact origin.
5. Run the GitHub release workflow and confirm both assets and their Supabase `release_versions` rows use matching GitHub URLs and SHA-256 values.
6. Remove the temporary `workers.dev` origin from CORS only after the new admin hostname passes all checks.
