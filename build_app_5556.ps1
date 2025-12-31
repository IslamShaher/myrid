# Build and run Flutter app on emulator 5556

$ErrorActionPreference = "Continue"

Write-Host "=== Building Flutter App on Emulator 5556 ===" -ForegroundColor Cyan
Write-Host ""

# Find ADB
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe"
}
if (-not (Test-Path $adbPath)) {
    Write-Host "[ERROR] ADB not found. Install Android SDK Platform Tools." -ForegroundColor Red
    exit 1
}

$env:Path = "$(Split-Path $adbPath);$env:Path"

# Check if emulator 5556 is running
Write-Host "Checking if emulator-5556 is running..." -ForegroundColor Yellow
$devices = & $adbPath devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-5556" -and $_ -match "device" }

if (-not $devices) {
    Write-Host "[ERROR] Emulator 5556 is not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start emulator 5556 first:" -ForegroundColor Yellow
    Write-Host "  emulator -avd <your_avd_name>" -ForegroundColor White
    Write-Host ""
    Write-Host "Or check if it's already running with a different serial:" -ForegroundColor Yellow
    & $adbPath devices
    exit 1
}

Write-Host "[SUCCESS] Emulator 5556 is connected" -ForegroundColor Green
Write-Host ""

# Change to Flutter Rider directory
$flutterDir = "Flutter\Rider"
if (-not (Test-Path $flutterDir)) {
    Write-Host "[ERROR] Flutter\Rider directory not found!" -ForegroundColor Red
    exit 1
}

Set-Location $flutterDir
Write-Host "Changed to directory: $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Build and run on emulator 5556
Write-Host "Starting Flutter build and run on emulator-5556..." -ForegroundColor Cyan
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

flutter run -d emulator-5556

