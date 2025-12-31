# Complete Parallel Test Runner - Shared Ride Testing
# Starts monitors and runs API test while monitoring everything

param(
    [string[]]$EmulatorSerials = @()
)

$ErrorActionPreference = "Continue"

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

Write-Host "=== Comprehensive Parallel Shared Ride Test ===" -ForegroundColor Cyan
Write-Host ""

# Check emulators
$devices = & $adbPath devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" -and $_ -match "device" }
$emulators = $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }

if ($emulators.Count -lt 2) {
    Write-Host "[ERROR] Need 2 emulators. Found: $($emulators.Count)" -ForegroundColor Red
    Write-Host ""
    Write-Host "To start emulators:" -ForegroundColor Yellow
    Write-Host "  1. List available: emulator -list-avds" -ForegroundColor White
    Write-Host "  2. Start first: Start-Process emulator -ArgumentList '-avd', '<avd_name_1>' -WindowStyle Minimized" -ForegroundColor White  
    Write-Host "  3. Start second: Start-Process emulator -ArgumentList '-avd', '<avd_name_2>' -WindowStyle Minimized" -ForegroundColor White
    Write-Host "  4. Wait for them to boot, then run this script again" -ForegroundColor White
    exit 1
}

$em1 = if ($EmulatorSerials.Count -ge 1) { $EmulatorSerials[0] } else { $emulators[0] }
$em2 = if ($EmulatorSerials.Count -ge 2) { $EmulatorSerials[1] } else { $emulators[1] }

Write-Host "[SUCCESS] Using emulators:" -ForegroundColor Green
Write-Host "  Emulator 1: $em1" -ForegroundColor White
Write-Host "  Emulator 2: $em2" -ForegroundColor White
Write-Host ""

# Save config
@{
    emulator1 = $em1
    emulator2 = $em2
    last_used = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
} | ConvertTo-Json | Out-File "emulator_config.json" -Encoding UTF8

# Output directory
$outputDir = "test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$dirs = @("$outputDir", "$outputDir\screenshots", "$outputDir\logs")
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

Write-Host "[INFO] Output directory: $outputDir" -ForegroundColor Cyan
Write-Host ""

# Start monitors using background jobs (simpler approach)
Write-Host "[STEP] Starting parallel monitors..." -ForegroundColor Yellow

# 1. Database Monitor (PHP script)
Write-Host "  - Database monitor..." -ForegroundColor White
$dbLog = "$outputDir\logs\database_monitor.log"
Start-Job -ScriptBlock {
    param($logFile)
    php monitor_database.php $logFile
} -ArgumentList $dbLog | Out-Null

# 2. Laravel Log Monitor
Write-Host "  - Laravel log monitor..." -ForegroundColor White
$laravelLog = "$outputDir\logs\laravel_monitor.log"
Start-Job -ScriptBlock {
    param($sourceLog, $outputLog)
    $lastSize = 0
    while ($true) {
        if (Test-Path $sourceLog) {
            $size = (Get-Item $sourceLog -ErrorAction SilentlyContinue).Length
            if ($size -gt $lastSize) {
                Get-Content $sourceLog -Tail 10 -ErrorAction SilentlyContinue | 
                    ForEach-Object { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $_" | Add-Content $outputLog }
                $lastSize = $size
            }
        }
        Start-Sleep -Seconds 1
    }
} -ArgumentList "storage\logs\laravel.log", $laravelLog | Out-Null

# 3. Flutter Log Monitors
Write-Host "  - Flutter log monitors..." -ForegroundColor White
& $adbPath -s $em1 logcat -c 2>&1 | Out-Null
& $adbPath -s $em2 logcat -c 2>&1 | Out-Null

$flutterLog1 = "$outputDir\logs\flutter_em1.log"
Start-Job -ScriptBlock {
    param($adb, $serial, $logFile)
    while ($true) {
        $log = & $adb -s $serial logcat -d -s flutter:* *:E 2>&1 | Select-Object -Last 10
        if ($log) {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $serial" | Add-Content $logFile
            $log | Add-Content $logFile
        }
        & $adb -s $serial logcat -c 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} -ArgumentList $adbPath, $em1, $flutterLog1 | Out-Null

$flutterLog2 = "$outputDir\logs\flutter_em2.log"
Start-Job -ScriptBlock {
    param($adb, $serial, $logFile)
    while ($true) {
        $log = & $adb -s $serial logcat -d -s flutter:* *:E 2>&1 | Select-Object -Last 10
        if ($log) {
            "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $serial" | Add-Content $logFile
            $log | Add-Content $logFile
        }
        & $adb -s $serial logcat -c 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} -ArgumentList $adbPath, $em2, $flutterLog2 | Out-Null

# 4. Screenshot Monitor
Write-Host "  - Screenshot monitor..." -ForegroundColor White
$screenshotDir = "$outputDir\screenshots"
Start-Job -ScriptBlock {
    param($adb, $serial1, $serial2, $screenshotDir)
    $counter = 0
    while ($true) {
        $counter++
        $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
        & $adb -s $serial1 exec-out screencap -p > "$screenshotDir\${serial1}_${ts}_${counter}.png" 2>&1
        & $adb -s $serial2 exec-out screencap -p > "$screenshotDir\${serial2}_${ts}_${counter}.png" 2>&1
        Start-Sleep -Seconds 3
    }
} -ArgumentList $adbPath, $em1, $em2, $screenshotDir | Out-Null

Start-Sleep -Seconds 3

# Run API test
Write-Host ""
Write-Host "[STEP] Running shared ride API test..." -ForegroundColor Yellow
Write-Host ""
php test_shared_ride_emulators.php 2>&1 | Tee-Object -FilePath "$outputDir\logs\api_test.log"

# Wait a bit for monitors to capture
Write-Host ""
Write-Host "[INFO] Monitoring for 30 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

# Final database check
Write-Host ""
Write-Host "[STEP] Final database check..." -ForegroundColor Yellow
php check_rides.php 2>&1 | Tee-Object -FilePath "$outputDir\logs\final_check.log"

# Stop monitors
Write-Host ""
Write-Host "[STEP] Stopping monitors..." -ForegroundColor Yellow
Get-Job | Stop-Job
Get-Job | Remove-Job

# Stop database monitor process
Get-Process php -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*monitor_database*" 
} | Stop-Process -Force -ErrorAction SilentlyContinue

# Report
Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Results saved to: $outputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files:" -ForegroundColor Yellow
Write-Host "  - Screenshots: $outputDir\screenshots\" -ForegroundColor White
Write-Host "  - Database log: $dbLog" -ForegroundColor White
Write-Host "  - Laravel log: $laravelLog" -ForegroundColor White
Write-Host "  - Flutter logs: $flutterLog1, $flutterLog2" -ForegroundColor White
Write-Host "  - API test: $outputDir\logs\api_test.log" -ForegroundColor White
Write-Host "  - Final check: $outputDir\logs\final_check.log" -ForegroundColor White




