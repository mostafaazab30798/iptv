<#
.SYNOPSIS
    Installs HOPE IPTV APK onto an Android TV device via ADB.

.DESCRIPTION
    Connects to an Android TV over Wi-Fi (or uses an existing USB/ADB device)
    and installs the TV APK.

.PARAMETER DeviceIp
    IP address of the Android TV on your local network (e.g. 192.168.1.50).

.PARAMETER Port
    ADB port on the TV (defaults to 5555).

.PARAMETER DeviceId
    Specific ADB device ID to target if multiple devices are attached.

.PARAMETER ApkPath
    Path to the APK file (defaults to the latest TV build in build/app/outputs/flutter-apk/).

.EXAMPLE
    .\scripts\android\install_tv.ps1 -DeviceIp 192.168.1.50
    .\scripts\android\install_tv.ps1 -DeviceId 192.168.1.50:5555
#>

param(
    [string]$DeviceIp = "",
    [int]$Port = 5555,
    [string]$DeviceId = "",
    [string]$ApkPath = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   HOPE IPTV — Android TV ADB Installer         " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check ADB availability
$adbCmd = Get-Command "adb" -ErrorAction SilentlyContinue
if (-not $adbCmd) {
    Write-Error "adb command not found in PATH. Please ensure Android SDK Platform-Tools are installed."
    exit 1
}

# Connect over IP if specified
if (-not [string]::IsNullOrWhiteSpace($DeviceIp)) {
    $targetAddress = "${DeviceIp}:${Port}"
    Write-Host "[*] Connecting to Android TV at $targetAddress..." -ForegroundColor Cyan
    & adb connect $targetAddress
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to connect to $targetAddress. Ensure Developer Options & ADB Debugging are enabled on the TV."
    }
    if ([string]::IsNullOrWhiteSpace($DeviceId)) {
        $DeviceId = $targetAddress
    }
}

# Locate APK if not specified
if ([string]::IsNullOrWhiteSpace($ApkPath)) {
    $candidates = @(
        (Join-Path $repoRoot "build\app\outputs\flutter-apk\hope-tv-android-tv-release.apk"),
        (Join-Path $repoRoot "build\app\outputs\flutter-apk\hope-tv-android-tv-debug.apk"),
        (Join-Path $repoRoot "build\app\outputs\flutter-apk\hope-tv-standalone-release.apk"),
        (Join-Path $repoRoot "build\app\outputs\flutter-apk\hope-tv-standalone-debug.apk"),
        (Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"),
        (Join-Path $repoRoot "build\app\outputs\flutter-apk\app-debug.apk")
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $ApkPath = $cand
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($ApkPath) -or -not (Test-Path $ApkPath)) {
    Write-Host "[!] No pre-built TV APK found. Building debug TV APK now..." -ForegroundColor Yellow
    & (Join-Path $PSScriptRoot "build_tv_apk.ps1")
    $ApkPath = Join-Path $repoRoot "build\app\outputs\flutter-apk\hope-tv-android-tv-debug.apk"
    if (-not (Test-Path $ApkPath)) {
        Write-Error "Could not build or locate TV APK."
        exit 1
    }
}

Write-Host "[*] Target APK: $ApkPath" -ForegroundColor Gray

$installArgs = @("install", "-r", "-d", $ApkPath)
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $installArgs = @("-s", $DeviceId) + $installArgs
}

Write-Host "[*] Installing to Android TV..." -ForegroundColor Cyan
& adb @installArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " [OK] Successfully installed on Android TV!" -ForegroundColor Green
    Write-Host " You can launch HOPE TV from your Leanback apps row." -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Green
} else {
    Write-Error "ADB install failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
