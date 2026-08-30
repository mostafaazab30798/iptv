# Production release readiness verification.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/release/verify_production_readiness.ps1

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repoRoot

function Test-GhSecret([string]$Name) {
    $list = gh secret list | Out-String
    if ($list -notmatch "(?m)^$Name\s") {
        throw "Missing GitHub secret: $Name"
    }
    Write-Host "[ok] GitHub secret $Name"
}

function Test-SupaSecret([string]$Name) {
    $list = supabase secrets list | Out-String
    if ($list -notmatch "(?m)^\s*$Name\s") {
        throw "Missing Supabase secret: $Name"
    }
    Write-Host "[ok] Supabase secret $Name"
}

Write-Host "=== GitHub secrets ==="
@(
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "SUPABASE_SERVICE_ROLE_KEY",
    "ANDROID_KEYSTORE_BASE64",
    "ANDROID_KEYSTORE_PASSWORD",
    "ANDROID_KEY_PASSWORD",
    "ANDROID_KEY_ALIAS",
    "ENTITLEMENT_PUBLIC_KEYS_JSON",
    "RELEASE_PUBLIC_KEYS_JSON",
    "PORTAL_ORIGIN"
) | ForEach-Object { Test-GhSecret $_ }

Write-Host ""
Write-Host "=== Supabase secrets ==="
@(
    "RELEASE_SIGNING_ALG",
    "RELEASE_SIGNING_KEY_ID",
    "RELEASE_SIGNING_PRIVATE_KEY_PKCS8_B64",
    "ENTITLEMENT_SIGNING_ALG",
    "ENTITLEMENT_SIGNING_KEY_ID",
    "ENTITLEMENT_SIGNING_PRIVATE_KEY_PKCS8_B64"
) | ForEach-Object { Test-SupaSecret $_ }

Write-Host ""
Write-Host "=== pubspec version format ==="
$raw = (Select-String -Path pubspec.yaml -Pattern '^version:' | Select-Object -First 1).Line
if ($raw -notmatch '\+\d+$') {
    throw "pubspec.yaml must use major.minor.patch+build format. Found: $raw"
}
Write-Host "[ok] $raw"

Write-Host ""
Write-Host "=== version Edge Function smoke test ==="
$base = "https://otmovtxevvuxbsrmurkb.supabase.co"
$anon = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90bW92dHhldnZ1eGJzcm11cmtiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgwMjM1OTcsImV4cCI6MjEwMzU5OTU5N30.UIJTd6-S-07bu38MoanJRxDRK2O_xW2xOhfZsQnxjGA"
$uri = "$base/functions/v1/version?platform=android&architecture=arm64-v8a&buildNumber=0&channel=stable"
$response = Invoke-RestMethod -Uri $uri -Headers @{
    apikey = $anon
    Authorization = "Bearer $anon"
}
if (-not $response.manifest.signature) {
    throw "version function returned no manifest signature"
}
if ($response.manifest.keyId -notmatch '^release-prod-') {
    throw "Unexpected manifest keyId: $($response.manifest.keyId)"
}
Write-Host "[ok] Signed manifest from version (keyId=$($response.manifest.keyId), build=$($response.manifest.buildNumber))"

Write-Host ""
Write-Host "=== Flutter update tests ==="
flutter test test/updates/
Write-Host "[ok] test/updates passed"

Write-Host ""
Write-Host "=== Remaining owner blockers ==="
Write-Host "- Windows Authenticode: not configured (SmartScreen may warn on installer)"
Write-Host "- Dispatch release workflow after bumping pubspec build number"
Write-Host "- Install build N on device, confirm update to N+1, verify in-place upgrade"
Write-Host ""
Write-Host "Production signing pipeline is configured."
