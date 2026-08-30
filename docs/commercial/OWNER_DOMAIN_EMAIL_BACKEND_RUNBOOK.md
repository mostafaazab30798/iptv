# HOPE TV — Owner setup runbook

This file is for the project owner. It covers the actions that must be completed in Cloudflare, the domain registrar, turboSMTP, Supabase, and GitHub.

## Final production architecture

| Purpose | Production service |
|---|---|
| Public web application | `https://hope-tv.site` |
| Canonical `www` address | `https://www.hope-tv.site` redirects to `https://hope-tv.site` |
| Owner dashboard | `https://admin.hope-tv.site` |
| Authentication and database | Supabase project `otmovtxevvuxbsrmurkb` |
| Authentication email | turboSMTP through Supabase Custom SMTP |
| Authentication sender | `no-reply@auth.hope-tv.site` |
| Support address | `support@hope-tv.site` |
| Android and Windows downloads | GitHub Releases in `mostafaazab30798/iptv` |
| Release metadata and authorization | Supabase `release_versions`, `version`, and `downloads` |

Cloudflare R2 and `downloads.hope-tv.site` are not part of the production design.

## Current external status

Rechecked on 2026-08-30:

- `hope-tv.site` resolves on Cloudflare (`200 OK` over HTTPS).
- `admin.hope-tv.site` resolves and redirects to `/overview`.
- `auth.hope-tv.site` resolves on Cloudflare (use for turboSMTP DNS records only; not a public web app).
- The existing dashboard Worker remains available at `https://hope-tv.mostafaazab3024.workers.dev`.
- GitHub Actions secrets currently include: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `PORTAL_ORIGIN`, `ENTITLEMENT_PUBLIC_KEYS_JSON`, and `ANDROID_KEYSTORE_*`.
- Still owner-operated: turboSMTP domain verification, Supabase Custom SMTP, Magic Link template with `{{ .Token }}`, and `RELEASE_PUBLIC_KEYS_JSON` once release signing is Ed25519 in production.

Recheck these conditions before making changes because external state may have changed.

## 1. Activate the domain in Cloudflare

1. Sign in to the Cloudflare account associated with `mostafaazab3024@gmail.com`.
2. Select **Add a domain** and enter `hope-tv.site`.
3. Choose the desired Cloudflare plan.
4. Cloudflare will display two authoritative nameservers.
5. Sign in to the registrar where `hope-tv.site` was purchased.
6. Replace the registrar nameservers with the exact two Cloudflare nameservers.
7. Wait until Cloudflare reports the zone as **Active**.
8. Confirm that public NS resolution works before deploying either hostname.

Do not create arbitrary A records for Workers. Custom Worker domains create the required proxied DNS records through Cloudflare.

## 2. Deploy the public Flutter website

The root [`wrangler.toml`](../../wrangler.toml) targets both `hope-tv.site` and `www.hope-tv.site`.

Build with the public Supabase URL and publishable/anon key:

```powershell
flutter build web --release `
  --dart-define=SUPABASE_URL=https://otmovtxevvuxbsrmurkb.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

Deploy after the Cloudflare zone becomes active:

```powershell
services\download_gateway\node_modules\.bin\wrangler.cmd deploy --config wrangler.toml
```

After deployment:

- Open `https://hope-tv.site`.
- Open `https://www.hope-tv.site` and confirm it resolves.
- Configure a redirect from `www` to the apex domain if both currently serve content.
- Verify the HTTPS certificate and application assets.

## 3. Attach the owner dashboard domain

1. Open **Cloudflare → Workers & Pages → hope-tv**.
2. Open **Settings → Domains & Routes**.
3. Add custom domain `admin.hope-tv.site`.
4. Keep `https://hope-tv.mostafaazab3024.workers.dev` enabled during migration.
5. Open `https://admin.hope-tv.site` and confirm the login page loads.

Do not expose the dashboard at the apex `hope-tv.site` address.

## 4. Configure the turboSMTP sending domain

Use `auth.hope-tv.site` for authentication email. This isolates authentication reputation from support or future marketing email.

1. Sign in to turboSMTP.
2. Add `auth.hope-tv.site` as a sending domain.
3. Copy the exact SPF and DKIM records displayed by turboSMTP.
4. Add those records in **Cloudflare → DNS**.
5. Add a DMARC TXT record at `_dmarc.auth` in monitoring mode:

```text
v=DMARC1; p=none; adkim=s; aspf=s
```

6. Verify the sending domain inside turboSMTP.
7. Use `no-reply@auth.hope-tv.site` as the Supabase sender.

TXT records are DNS records and are never proxied. If turboSMTP displays values different from an online example, use the values from the turboSMTP account.

## 5. Configure Supabase Auth URLs

Open Supabase project `otmovtxevvuxbsrmurkb`, then go to **Authentication → URL Configuration**.

Set:

```text
Site URL: https://hope-tv.site
```

Add these redirect URLs:

```text
https://hope-tv.site/**
https://www.hope-tv.site/**
https://admin.hope-tv.site/**
```

Keep localhost redirect URLs only when they are needed for development.

## 6. Configure Supabase Custom SMTP

Open **Authentication → Email / SMTP Settings** and enable Custom SMTP.

Use:

| Field | Value |
|---|---|
| Sender email | `no-reply@auth.hope-tv.site` |
| Sender name | `HOPE TV` |
| SMTP host | `pro.turbo-smtp.com`, or the EU host assigned by turboSMTP |
| SMTP port | `587` |
| SMTP username | turboSMTP Consumer Key |
| SMTP password | turboSMTP Consumer Secret |

The Consumer Secret must be entered directly into Supabase. Never place it in Git, Flutter dart-defines, Vite variables, GitHub workflow files, documentation, screenshots, or chat messages.

After saving the SMTP settings:

1. Review **Authentication → Rate Limits**.
2. Keep email OTP length at `6`.
3. Copy the contents of [`supabase/templates/magic_link.html`](../../supabase/templates/magic_link.html) into the hosted Supabase Magic Link template.
4. Confirm that the template still contains `{{ .Token }}`.
5. Send an OTP to a non-owner mailbox and verify delivery.
6. Inspect message headers and confirm SPF, DKIM, and DMARC pass.

## 7. Configure Supabase Edge Function origins

Set these production Edge Function secrets:

```text
PORTAL_ORIGIN=https://admin.hope-tv.site
CORS_ALLOWLIST=https://admin.hope-tv.site,https://hope-tv.mostafaazab3024.workers.dev
```

Redeploy the affected functions after changing secrets. Keep the temporary `workers.dev` origin until the custom admin hostname is fully verified.

When cutover is complete, change the allowlist to:

```text
CORS_ALLOWLIST=https://admin.hope-tv.site
```

## 8. Confirm GitHub Releases configuration

GitHub Releases—not Cloudflare R2—owns the application binaries.

In repository settings, confirm these Actions secrets exist:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
PORTAL_ORIGIN
ENTITLEMENT_PUBLIC_KEYS_JSON
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_PASSWORD
ANDROID_KEY_ALIAS
RELEASE_PUBLIC_KEYS_JSON   # optional until Ed25519 release signing is enabled
```

Generate and upload the Android keystore secrets with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/android/create_release_keystore.ps1 -UploadSecrets
```

The release workflow must:

1. Build the Android APK and Windows installer.
2. Calculate file size and SHA-256.
3. Publish both artifacts to the GitHub release tag.
4. Insert matching `object_key`, size, checksum, version, and build number values into Supabase `release_versions`.

Public GitHub release assets require no `GITHUB_PAT` in Supabase. If the repository becomes private, create a contents-read token and store it only as the Supabase Edge Function secret `GITHUB_PAT`.

## 9. Production verification checklist

- [x] Cloudflare zone resolves for `hope-tv.site` / `admin.hope-tv.site` / `auth.hope-tv.site` (recheck HTTPS content).
- [ ] `hope-tv.site` serves the production Flutter web build.
- [ ] `www.hope-tv.site` redirects to the canonical site.
- [ ] `admin.hope-tv.site` loads the owner dashboard.
- [ ] Supabase Site URL and redirects use the production domain.
- [ ] turboSMTP verifies `auth.hope-tv.site`.
- [ ] OTP messages arrive from `no-reply@auth.hope-tv.site`.
- [ ] OTP messages pass SPF, DKIM, and DMARC.
- [ ] The six-digit OTP signs a test user in successfully.
- [ ] The admin dashboard can call `admin-api` without CORS errors.
- [x] Android release keystore exists and `ANDROID_KEYSTORE_*` secrets are set.
- [x] `PORTAL_ORIGIN` and `ENTITLEMENT_PUBLIC_KEYS_JSON` GitHub secrets are set.
- [ ] `RELEASE_PUBLIC_KEYS_JSON` is set when production uses Ed25519 release signing.
- [ ] GitHub Releases contains the Android and Windows artifacts.
- [ ] Supabase release metadata matches the GitHub assets and checksums.
- [ ] No R2 bucket, download Worker, or `downloads.hope-tv.site` hostname is used.
- [ ] No service-role, SMTP, signing, or GitHub secret is present in a client artifact.

## 10. Rollback

If the custom domain fails:

1. Keep the existing `workers.dev` dashboard available.
2. Restore the previous Supabase CORS allowlist.
3. Do not change or delete Supabase user data.
4. Roll back only the affected Cloudflare Worker deployment.
5. Keep GitHub Releases and Supabase release metadata unchanged unless the release itself is defective.

