# Main script to run parallel shared ride test
# This coordinates all the parallel processes

param(
    [string[]]$EmulatorSerials = @()
)

Write-Host "=== Parallel Shared Ride Test Runner ===" -ForegroundColor Green
Write-Host ""

# Check if emulators are running
$devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" -and $_ -match "device$" }
$availableEmulators = $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }

if ($availableEmulators.Count -lt 2) {
    Write-Host "[ERROR] Need at least 2 emulators running" -ForegroundColor Red
    Write-Host "Available: $($availableEmulators.Count)" -ForegroundColor Yellow
    Write-Host "Start emulators first:" -ForegroundColor Yellow
    Write-Host "  emulator -list-avds" -ForegroundColor White
    Write-Host "  emulator -avd <avd_name_1> &" -ForegroundColor White
    Write-Host "  emulator -avd <avd_name_2> &" -ForegroundColor White
    exit 1
}

# Use provided serials or auto-detect
if ($EmulatorSerials.Count -lt 2) {
    $EmulatorSerials = $availableEmulators[0..1]
}

Write-Host "[SUCCESS] Using emulators:" -ForegroundColor Green
Write-Host "  Emulator 1: $($EmulatorSerials[0])" -ForegroundColor White
Write-Host "  Emulator 2: $($EmulatorSerials[1])" -ForegroundColor White

# Save configuration
@{
    emulator1_serial = $EmulatorSerials[0]
    emulator2_serial = $EmulatorSerials[1]
    last_used = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
} | ConvertTo-Json | Out-File "emulator_config.json"

Write-Host ""
Write-Host "Starting parallel test..." -ForegroundColor Cyan
Write-Host ""

# Run the comprehensive test script
& ".\test_shared_ride_parallel.ps1" -EmulatorSerials $EmulatorSerials




