# Helper script to start a second Android emulator

Write-Host "=== Starting Second Emulator ===" -ForegroundColor Cyan
Write-Host ""

# Find emulator executable
$emulatorPath = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"
if (-not (Test-Path $emulatorPath)) {
    $emulatorPath = "$env:USERPROFILE\AppData\Local\Android\Sdk\emulator\emulator.exe"
}

if (-not (Test-Path $emulatorPath)) {
    Write-Host "[ERROR] Emulator not found. Install Android SDK Emulator." -ForegroundColor Red
    exit 1
}

# List available AVDs
Write-Host "[INFO] Listing available AVDs..." -ForegroundColor Yellow
& $emulatorPath -list-avds

Write-Host ""
$avdName = Read-Host "Enter AVD name to start (or press Enter to use first available)"

if ([string]::IsNullOrWhiteSpace($avdName)) {
    $avds = & $emulatorPath -list-avds
    if ($avds.Count -gt 0) {
        $avdName = $avds[0]
        Write-Host "[INFO] Using first AVD: $avdName" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] No AVDs found" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "[INFO] Starting emulator: $avdName" -ForegroundColor Yellow
Write-Host "[INFO] This may take a minute..." -ForegroundColor Yellow

Start-Process $emulatorPath -ArgumentList "-avd", $avdName -WindowStyle Normal

Write-Host ""
Write-Host "[SUCCESS] Emulator starting. Wait for it to boot, then check with: adb devices" -ForegroundColor Green




