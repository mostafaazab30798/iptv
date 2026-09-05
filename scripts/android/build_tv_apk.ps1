<#
.SYNOPSIS
    Builds an Android TV APK for HOPE IPTV.

.DESCRIPTION
    Compiles the Flutter application for Android TV.
    Supports optional separate package ID (`com.hopetv.iptvplayer.tv`) via `-SeparatePackageId`,
    allowing side-by-side installation with the mobile build on test devices.

.PARAMETER Release
    Build in release mode (requires key.properties for signing). Defaults to debug.

.PARAMETER SeparatePackageId
    Appends `.tv` to the applicationId (resulting in `com.hopetv.iptvplayer.tv`).

.PARAMETER ConfigFile
    Path to environment configuration file (defaults to .env.tv if present, otherwise .env.local).

.EXAMPLE
    .\scripts\android\build_tv_apk.ps1
    .\scripts\android\build_tv_apk.ps1 -Release
    .\scripts\android\build_tv_apk.ps1 -SeparatePackageId
#>

param(
    [switch]$Release,
    [switch]$SeparatePackageId,
    [string]$ConfigFile = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
Set-Location $repoRoot

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   HOPE IPTV — Android TV APK Builder           " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Resolve configuration file
if ([string]::IsNullOrWhiteSpace($ConfigFile)) {
    if (Test-Path (Join-Path $repoRoot ".env.tv")) {
        $ConfigFile = Join-Path $repoRoot ".env.tv"
    } elseif (Test-Path (Join-Path $repoRoot ".env.local")) {
        $ConfigFile = Join-Path $repoRoot ".env.local"
    }
}

$flutterArgs = @("build", "apk")

if ($Release) {
    $flutterArgs += "--release"
    $buildMode = "release"
} else {
    $flutterArgs += "--debug"
    $buildMode = "debug"
}

if (-not [string]::IsNullOrWhiteSpace($ConfigFile) -and (Test-Path $ConfigFile)) {
    Write-Host "[*] Using environment: $ConfigFile" -ForegroundColor Gray
    $flutterArgs += "--dart-define-from-file=$ConfigFile"
} else {
    Write-Host "[*] No .env.tv or .env.local found. Building without external defines." -ForegroundColor Yellow
}

$gradleArgs = @()
if ($SeparatePackageId) {
    Write-Host "[*] Building with separate TV Package ID (com.hopetv.iptvplayer.tv)" -ForegroundColor Green
    $gradleArgs += "-PtvBuild=true"
}

if ($gradleArgs.Count -gt 0) {
    $flutterArgs += "--"
    $flutterArgs += $gradleArgs
}

Write-Host "[*] Running: flutter $($flutterArgs -join ' ')" -ForegroundColor Cyan
& flutter @flutterArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Flutter APK build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Determine source APK path
$sourceApk = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-$buildMode.apk"
if (-not (Test-Path $sourceApk)) {
    $sourceApk = Join-Path $repoRoot "build\app\outputs\flutter-apk\app.apk"
}

if (Test-Path $sourceApk) {
    $outputName = if ($SeparatePackageId) { "hope-tv-standalone-$buildMode.apk" } else { "hope-tv-android-tv-$buildMode.apk" }
    $destApk = Join-Path $repoRoot "build\app\outputs\flutter-apk\$outputName"
    Copy-Item -Path $sourceApk -Destination $destApk -Force

    $apkItem = Get-Item $destApk
    $sizeMb = [math]::Round($apkItem.Length / 1MB, 2)
    $hash = (Get-FileHash -Path $destApk -Algorithm SHA256).Hash

    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " [OK] Android TV APK built successfully!" -ForegroundColor Green
    Write-Host " Path:   $destApk" -ForegroundColor White
    Write-Host " Size:   $sizeMb MB" -ForegroundColor White
    Write-Host " SHA256: $hash" -ForegroundColor Gray
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "To install on your Android TV:" -ForegroundColor Yellow
    Write-Host "  .\scripts\android\install_tv.ps1 -DeviceIp <tv-ip-address>" -ForegroundColor Gray
} else {
    Write-Warning "Could not find generated APK at $sourceApk"
}
