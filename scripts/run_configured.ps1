param(
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$configPath = Join-Path $repoRoot ".env.local"

if (-not (Test-Path -LiteralPath $configPath)) {
    throw "Missing .env.local. Create it from the project owner configuration before running the app."
}

$flutterArgs = @("run", "--dart-define-from-file=$configPath")
if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    $flutterArgs += @("-d", $DeviceId)
}

& flutter @flutterArgs
exit $LASTEXITCODE
