# Generate Ed25519 release manifest signing keys and optionally upload secrets.
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/release/create_release_signing_keys.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/release/create_release_signing_keys.ps1 -UploadSecrets
#
# Creates gitignored files under secrets/release-signing/ — never commit them.

param(
    [switch]$UploadSecrets
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repoRoot

$deno = Get-Command deno -ErrorAction SilentlyContinue
if (-not $deno) {
    throw "deno not found. Install Deno to generate Ed25519 release signing keys."
}

$args = @("run", "--allow-write=secrets/release-signing")
if ($UploadSecrets) {
    $args += @("--allow-run=supabase,gh", "--allow-env")
    $args += "tool/release/generate_release_signing_keys.ts"
    $args += "--upload"
} else {
    $args += "tool/release/generate_release_signing_keys.ts"
}

& deno @args

Write-Host ""
if (-not $UploadSecrets) {
    Write-Host "Next: re-run with -UploadSecrets after reviewing secrets/release-signing/README.txt"
    Write-Host "Then deploy Edge Functions:"
    Write-Host "  supabase functions deploy version downloads"
}
