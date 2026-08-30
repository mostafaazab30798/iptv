# Generate a production Android release keystore and (optionally) upload CI secrets.
#
# Usage (from repo root):
#   powershell -ExecutionPolicy Bypass -File scripts/android/create_release_keystore.ps1
#   powershell -ExecutionPolicy Bypass -File scripts/android/create_release_keystore.ps1 -UploadSecrets
#
# Never commit android/keystore/*.jks or android/key.properties.

param(
    [switch]$UploadSecrets,
    [string]$Alias = "hope_tv",
    [string]$KeystoreRelativePath = "android/keystore/hope-tv-release.jks"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repoRoot

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    $javaHome = $env:JAVA_HOME
    if ($javaHome) {
        $candidate = Join-Path $javaHome "bin/keytool.exe"
        if (Test-Path $candidate) { $keytoolPath = $candidate }
    }
    if (-not $keytoolPath) {
        throw "keytool not found. Install a JDK 17+ and ensure keytool is on PATH."
    }
} else {
    $keytoolPath = $keytool.Source
}

$keystoreDir = Join-Path $repoRoot "android/keystore"
$keystorePath = Join-Path $repoRoot $KeystoreRelativePath
$keyPropsPath = Join-Path $repoRoot "android/key.properties"
$secretsOutDir = Join-Path $repoRoot "android/keystore"
$passwordsPath = Join-Path $secretsOutDir "hope-tv-release.passwords.txt"

New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

function New-StrongPassword {
    $bytes = New-Object byte[] 24
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ([Convert]::ToBase64String($bytes) -replace '[+/=]', 'x')
}

if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists at $keystorePath"
    Write-Host "Refusing to overwrite. Delete it manually only if you intentionally rotate keys."
    exit 1
}

$storePassword = New-StrongPassword
$keyPassword = $storePassword

Write-Host "Generating release keystore..."
& $keytoolPath `
    -genkeypair `
    -v `
    -storetype JKS `
    -keystore $keystorePath `
    -alias $Alias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $storePassword `
    -keypass $keyPassword `
    -dname "CN=HOPE TV, OU=Mobile, O=HOPE TV, L=Unknown, ST=Unknown, C=US"

# storeFile is relative to android/app/
$storeFileForGradle = "../keystore/hope-tv-release.jks"
@(
    "storePassword=$storePassword"
    "keyPassword=$keyPassword"
    "keyAlias=$Alias"
    "storeFile=$storeFileForGradle"
) | Set-Content -Path $keyPropsPath -Encoding ascii

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($keystorePath))
$base64Path = Join-Path $secretsOutDir "hope-tv-release.jks.base64.txt"
Set-Content -Path $base64Path -Value $base64 -Encoding ascii -NoNewline

@(
    "HOPE TV Android release keystore passwords"
    "Generated: $((Get-Date).ToUniversalTime().ToString('o'))"
    "Alias: $Alias"
    "Store/Key password: $storePassword"
    ""
    "GitHub Actions secrets to set:"
    "  ANDROID_KEYSTORE_BASE64  <- contents of hope-tv-release.jks.base64.txt"
    "  ANDROID_KEYSTORE_PASSWORD"
    "  ANDROID_KEY_PASSWORD"
    "  ANDROID_KEY_ALIAS=$Alias"
    ""
    "KEEP THIS FILE OFFLINE. Do not commit it."
) | Set-Content -Path $passwordsPath -Encoding utf8

Write-Host ""
Write-Host "Created:"
Write-Host "  $keystorePath"
Write-Host "  $keyPropsPath"
Write-Host "  $base64Path"
Write-Host "  $passwordsPath"
Write-Host ""

if ($UploadSecrets) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) { throw "gh CLI not found; cannot upload secrets." }

    $base64 | gh secret set ANDROID_KEYSTORE_BASE64
    $storePassword | gh secret set ANDROID_KEYSTORE_PASSWORD
    $keyPassword | gh secret set ANDROID_KEY_PASSWORD
    $Alias | gh secret set ANDROID_KEY_ALIAS
    Write-Host "Uploaded ANDROID_KEYSTORE_* secrets to GitHub."
} else {
    Write-Host "To upload CI secrets now, re-run with -UploadSecrets"
}
