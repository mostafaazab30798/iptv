# HOPE TV — LLM agent instructions for domain, email, releases, and backend work

This file is the authoritative working brief for an LLM agent modifying the HOPE TV codebase or backend configuration related to domains, email, authentication, releases, or deployment.

## Objective

Maintain this production architecture:

```text
hope-tv.site              -> public Flutter web Worker
admin.hope-tv.site        -> existing hope-tv owner-dashboard Worker
Supabase                  -> Auth, PostgreSQL, RLS, Edge Functions, release metadata
Resend Free               -> Supabase authentication email transport
GitHub Releases           -> Android APK and Windows installer storage/delivery
```

There is no production R2 download path and no `downloads.hope-tv.site` hostname.

## Confirmed identifiers

| Item | Value |
|---|---|
| Product | `HOPE TV` |
| Root domain | `hope-tv.site` |
| Admin domain | `admin.hope-tv.site` |
| Temporary dashboard | `https://hope-tv.mostafaazab3024.workers.dev` |
| Cloudflare account ID | `57d73e28720e0bd2a332fe5bba33520f` |
| Existing admin Worker | `hope-tv` |
| Public web Worker | `hope-tv-site` |
| Supabase project ref | `otmovtxevvuxbsrmurkb` |
| Supabase URL | `https://otmovtxevvuxbsrmurkb.supabase.co` |
| GitHub repository | `mostafaazab30798/iptv` |
| Auth sender | `no-reply@auth.hope-tv.site` |
| Support email | `support@hope-tv.site` |

## Required first checks

Before modifying anything:

1. Read root `git status --short`.
2. Read nested `hope-tv-insights/AGENTS.md` and `git -C hope-tv-insights status --short` before changing that repository.
3. Preserve all unrelated user changes. In particular, do not discard an existing modification in `lib/app/router.dart`.
4. Inspect the actual implementation before trusting older planning documents.
5. Recheck external state rather than assuming the 2026-08-30 snapshot is still current.

Known snapshot on 2026-08-30:

- The zone resolves through Cloudflare, but `hope-tv.site` returned a Hostinger parked page instead of the Flutter Worker.
- Cloudflare contained a Worker named `hope-tv`.
- Supabase CLI was authenticated and linked to project `otmovtxevvuxbsrmurkb`.

## Source-of-truth files

Read these before making related changes:

| Concern | Source of truth |
|---|---|
| Owner-confirmed values | `docs/commercial/OWNER_CONFIG.md` |
| Owner setup procedure | `docs/commercial/OWNER_DOMAIN_EMAIL_BACKEND_RUNBOOK.md` |
| Release architecture | `docs/commercial/adr/0008-github-releases.md` |
| Release CI | `.github/workflows/release.yml` |
| Public web deployment | `wrangler.toml`, `worker.js`, `web/` |
| Hosted Auth/local Auth model | `supabase/config.toml` |
| OTP template | `supabase/templates/magic_link.html` |
| CORS policy | `supabase/functions/_shared/cors.ts` |
| GitHub URL resolution | `supabase/functions/downloads/index.ts` |
| Update checks | `supabase/functions/version/index.ts`, `lib/core/releases/` |
| Dashboard integration | `hope-tv-insights/INTEGRATION.md` |

Older master plans may still describe R2. Their R2 sections are historical and are superseded by ADR 0008.

## Non-negotiable architecture rules

1. Do not introduce Cloudflare R2 into the active release path.
2. Do not create or configure `downloads.hope-tv.site`.
3. Do not deploy `services/download_gateway`; it is a deprecated reference scaffold.
4. Do not change GitHub release URLs to R2, Supabase Storage, or an unapproved proxy.
5. Do not expose the owner dashboard at `hope-tv.site`; use `admin.hope-tv.site`.
6. Do not replace the Supabase project URL with `api.hope-tv.site` unless the owner explicitly enables and confirms a Supabase custom domain.
7. Do not remove the temporary `workers.dev` CORS origin until `admin.hope-tv.site` has been verified in production.
8. Do not change the Android application ID from `com.example.iptv` without explicit owner approval.

## Secret-handling rules

Never read into output, commit, log, or place in client code any of the following:

- Supabase service-role key.
- Supabase management access token.
- Resend API key or SMTP password.
- GitHub PAT.
- Cloudflare OAuth/access token.
- Entitlement or release signing private keys.
- Cron, billing, webhook, gateway, or deletion secrets.

Public values that may be present in client builds:

- Supabase project URL.
- Supabase publishable/anon key.
- Public verification keys.
- Public GitHub release URLs.

Do not ask the owner to paste secrets into chat. Ask them to enter secrets directly into the appropriate dashboard or a gitignored local secret store.

## Domain-related code changes

When changing public-domain behavior:

1. Keep `https://hope-tv.site` as the canonical public origin.
2. Keep `https://admin.hope-tv.site` as the dashboard origin.
3. Update all relevant CORS, redirect, SEO, manifest, and deployment configuration together.
4. Use exact production origins without trailing slashes in CORS values.
5. Preserve explicit localhost entries used for development.
6. Verify Worker custom-domain syntax with `wrangler deploy --dry-run` before live deployment.
7. Do not deploy a custom-domain route until the Cloudflare zone is Active.

Relevant expected values:

```text
PORTAL_ORIGIN=https://admin.hope-tv.site
CORS_ALLOWLIST=https://admin.hope-tv.site,https://hope-tv.mostafaazab3024.workers.dev
```

## Supabase Auth changes

Expected hosted Auth configuration:

```text
Site URL: https://hope-tv.site
Redirect URL: https://hope-tv.site/**
Redirect URL: https://www.hope-tv.site/**
Redirect URL: https://admin.hope-tv.site/**
OTP length: 6
```

The Flutter account flow uses `signInWithOtp` followed by `verifyOTP` with `OtpType.email`. The Magic Link template must therefore preserve `{{ .Token }}`.

Do not assume editing `supabase/config.toml` changes the hosted Supabase project. It controls local/CLI configuration. Hosted Auth settings require the Supabase dashboard, Management API, or an authenticated `supabase config push` workflow explicitly authorized by the owner.

## Resend SMTP changes

Expected SMTP model:

```text
Sending domain: auth.hope-tv.site
Sender: no-reply@auth.hope-tv.site
Sender name: HOPE TV
Host: smtp.resend.com
Port: 587 (STARTTLS)
Username: resend
Password: Resend sending API key
```

Rules:

1. Verify the sending domain through Resend and add the exact DNS records it provides to Cloudflare.
2. Do not hardcode account-specific DKIM values or API tokens.
3. Begin DMARC in monitoring mode and tighten policy only after verified delivery.
4. Keep authentication mail separate from marketing email.
5. Never store SMTP credentials as Edge Function source code, Flutter variables, Vite variables, or committed `.env` files.

## GitHub Releases changes

The active flow is:

```text
GitHub Actions
  -> builds Android and Windows artifacts
  -> calculates size and SHA-256
  -> publishes GitHub Release assets
  -> inserts release_versions rows in Supabase

Flutter
  -> calls version Edge Function
  -> verifies signed manifest
  -> calls downloads Edge Function
  -> receives GitHub release URL
```

When modifying this flow:

1. Keep the artifact URL, filename, platform, architecture, version, build number, file size, and SHA-256 synchronized.
2. Keep `SUPABASE_SERVICE_ROLE_KEY` limited to GitHub Actions and backend administration.
3. Public repositories require no GitHub PAT for downloads.
4. For private repositories, store a contents-read `GITHUB_PAT` only in Supabase Edge Function secrets.
5. Never return a private GitHub API URL that requires the client to possess a PAT.
6. Preserve release manifest signing and SHA-256 verification even though GitHub hosts the file.
7. Treat `download-consume` and `services/download_gateway` as retired compatibility code unless the owner explicitly requests removal.

## Backend and database modifications

For Supabase migrations or Edge Functions:

1. Use forward-only migrations. Do not edit an already-applied production migration.
2. Preserve deny-by-default RLS and cross-account isolation.
3. Never use a client-provided premium/subscription flag as authority.
4. Keep service-role use inside trusted backend or CI contexts.
5. Preserve correlation IDs and structured audit logging.
6. Keep CORS allowlists exact and centralized through `_shared/cors.ts`.
7. Validate all URLs stored in `release_versions.object_key`; accepted production values are GitHub URLs.
8. Keep billing fail-closed while no production billing provider is configured.
9. Avoid destructive database operations without explicit owner approval and a verified backup.

## Required validation

Run checks proportional to the modified area.

For general Flutter/domain changes:

```powershell
flutter analyze
flutter test test/commercial/
git diff --check
```

Known baseline: `flutter analyze` may report pre-existing informational issues. Report them separately and do not claim they were introduced by the current change without evidence.

For the public Worker:

```powershell
services\download_gateway\node_modules\.bin\wrangler.cmd deploy --dry-run --config wrangler.toml
```

The command uses Wrangler from the legacy service only as an installed CLI binary; it does not authorize deploying the legacy gateway.

For Edge Functions, if Deno is available:

```powershell
deno test --allow-env supabase/functions/_shared/
```

For GitHub release changes:

- Validate workflow YAML.
- Confirm Android and Windows metadata payloads produce GitHub asset URLs.
- Verify checksums and `release_versions` uniqueness behavior.
- Do not trigger a live release unless explicitly requested.

For dashboard changes:

```powershell
npm run build
npm run lint
```

Run these from `hope-tv-insights` and respect its nested repository state.

## External-write authorization boundary

Repository edits do not automatically authorize live external changes.

Before performing live actions, confirm that the owner's request includes the relevant mutation:

- Adding or changing DNS records.
- Deploying a Worker.
- Changing Supabase hosted Auth configuration.
- Setting Edge Function secrets.
- Sending test email to a real recipient.
- Triggering a GitHub release.
- Modifying production database data.

Read-only diagnostics are allowed when they support the task. Never broaden a domain/setup request into billing, data deletion, key rotation, or release publication without explicit authorization.

## Completion report

Every handoff must state:

1. What changed in code and configuration.
2. What changed in external services, if anything.
3. Which actions remain owner-operated.
4. Which validations passed or failed.
5. Any pre-existing warnings or dirty-worktree files preserved.
6. Whether the custom domain is actually live or only prepared in repository configuration.
7. Confirmation that GitHub Releases remains the binary delivery path and R2 was not introduced.
