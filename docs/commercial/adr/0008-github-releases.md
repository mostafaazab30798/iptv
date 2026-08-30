# ADR 0008: GitHub Releases for application distribution

## Status

Accepted

## Context

The production CI workflow already builds Android and Windows artifacts, publishes them to GitHub Releases, computes their SHA-256 digests, and registers the resulting asset URLs in Supabase `release_versions`. Earlier plans referenced private Cloudflare R2 and an isolated download Worker, but that path is not used.

## Decision

- GitHub Releases is the canonical binary store for Android and Windows releases.
- `.github/workflows/release.yml` owns artifact creation, checksums, publishing, and Supabase metadata registration.
- Public GitHub release URLs are returned directly by the Supabase `downloads` Edge Function.
- If the repository becomes private, `downloads` may exchange an API asset URL using a contents-read `GITHUB_PAT` stored only in Supabase secrets.
- Signed release manifests and SHA-256 verification remain independent of GitHub transport.
- `services/download_gateway` remains a deprecated reference scaffold and is not deployed.

## Consequences

- No Cloudflare R2 subscription, bucket, download Worker, or `downloads.hope-tv.site` hostname is required.
- GitHub repository and workflow permissions become part of the release trust boundary.
- Release rollback requires coordinating the GitHub asset and the Supabase metadata row.
- Public GitHub asset URLs are intentionally visible; integrity is enforced through signing and checksums rather than URL secrecy.
