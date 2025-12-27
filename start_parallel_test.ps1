# Main entry point for comprehensive parallel testing
# Handles ADB path detection and coordinates all monitoring processes

param(
    [string[]]$EmulatorSerials = @()
)

$ErrorActionPreference = "Continue"

# Find ADB in common locations
function Find-ADB {
    $paths = @(
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "C:\Android\platform-tools\adb.exe",
        "adb"  # Try system PATH
    )
    
    foreach ($path in $paths) {
        if ($path -eq "adb") {
            $found = Get-Command adb -ErrorAction SilentlyContinue
            if ($found) { return $found.Source }
        } elseif (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

$adbPath = Find-ADB
if (-not $adbPath) {
    Write-Host "[ERROR] ADB not found. Please:" -ForegroundColor Red
    Write-Host "  1. Install Android SDK Platform Tools" -ForegroundColor Yellow
    Write-Host "  2. Add to PATH, or set ADB path in script" -ForegroundColor Yellow
    exit 1
}

Write-Host "[INFO] Using ADB: $adbPath" -ForegroundColor Green

# Add ADB to PATH for this session
$env:Path = "$(Split-Path $adbPath);$env:Path"

# Check for emulators
$devices = & $adbPath devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" -and $_ -match "device" }
$availableEmulators = $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }

if ($availableEmulators.Count -lt 2) {
    Write-Host "[ERROR] Need at least 2 emulators. Found: $($availableEmulators.Count)" -ForegroundColor Red
    Write-Host "[INFO] Start emulators first:" -ForegroundColor Yellow
    Write-Host "  emulator -list-avds" -ForegroundColor White
    Write-Host "  emulator -avd <avd_name_1> &" -ForegroundColor White
    Write-Host "  emulator -avd <avd_name_2> &" -ForegroundColor White
    exit 1
}

Write-Host "[SUCCESS] Found $($availableEmulators.Count) emulator(s)" -ForegroundColor Green

# Create simplified test runner
Write-Host ""
Write-Host "=== Starting Comprehensive Parallel Test ===" -ForegroundColor Cyan
Write-Host ""

$OutputDir = "parallel_test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$dirs = @("$OutputDir", "$OutputDir\screenshots", "$OutputDir\logs")
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Assign emulators
if ($EmulatorSerials.Count -ge 2) {
    $em1 = $EmulatorSerials[0]
    $em2 = $EmulatorSerials[1]
} else {
    $em1 = $availableEmulators[0]
    $em2 = $availableEmulators[1]
}

Write-Host "Emulator 1: $em1" -ForegroundColor Green
Write-Host "Emulator 2: $em2" -ForegroundColor Green
Write-Host ""

# Save config
@{
    emulator1_serial = $em1
    emulator2_serial = $em2
    last_used = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
} | ConvertTo-Json | Out-File "emulator_config.json" -Encoding UTF8

# Start all monitors using separate PowerShell windows for parallel execution
Write-Host "[STEP] Starting parallel monitors..." -ForegroundColor Yellow

# 1. Database Monitor
Write-Host "  - Starting database monitor..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$PWD'; php monitor_database.php '$OutputDir\logs\database_monitor.log'"
) -WindowStyle Minimized

# 2. Laravel Log Monitor  
Write-Host "  - Starting Laravel log monitor..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit", 
    "-Command",
    "cd '$PWD'; `$lastSize=0; while(`$true) { if(Test-Path 'storage\logs\laravel.log') { `$size=(Get-Item 'storage\logs\laravel.log').Length; if(`$size -gt `$lastSize) { Get-Content 'storage\logs\laravel.log' -Tail 5 | ForEach-Object { '[$(Get-Date -Format \"yyyy-MM-dd HH:mm:ss\")] ' + `$_ | Add-Content '$OutputDir\logs\laravel_monitor.log' }; `$lastSize=`$size } }; Start-Sleep -Seconds 1 }"
) -WindowStyle Minimized

# 3. Flutter Log Monitors
Write-Host "  - Starting Flutter log monitors..." -ForegroundColor Cyan
& $adbPath -s $em1 logcat -c 2>&1 | Out-Null
& $adbPath -s $em2 logcat -c 2>&1 | Out-Null

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command", 
    "cd '$PWD'; while(`$true) { `$log=& '$adbPath' -s $em1 logcat -d -s flutter:* *:E 2>&1 | Select-Object -Last 10; if(`$log) { '[$(Get-Date -Format \"yyyy-MM-dd HH:mm:ss\")] $em1' | Add-Content '$OutputDir\logs\flutter_em1.log'; `$log | Add-Content '$OutputDir\logs\flutter_em1.log' }; & '$adbPath' -s $em1 logcat -c 2>&1 | Out-Null; Start-Sleep -Seconds 2 }"
) -WindowStyle Minimized

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$PWD'; while(`$true) { `$log=& '$adbPath' -s $em2 logcat -d -s flutter:* *:E 2>&1 | Select-Object -Last 10; if(`$log) { '[$(Get-Date -Format \"yyyy-MM-dd HH:mm:ss\")] $em2' | Add-Content '$OutputDir\logs\flutter_em2.log'; `$log | Add-Content '$OutputDir\logs\flutter_em2.log' }; & '$adbPath' -s $em2 logcat -c 2>&1 | Out-Null; Start-Sleep -Seconds 2 }"
) -WindowStyle Minimized

# 4. Screenshot Monitor
Write-Host "  - Starting screenshot monitor..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "cd '$PWD'; `$counter=0; while(`$true) { `$counter++; `$ts=Get-Date -Format 'yyyyMMdd_HHmmss'; & '$adbPath' -s $em1 exec-out screencap -p > '$OutputDir\screenshots\${em1}_`${ts}_`${counter}.png' 2>&1; & '$adbPath' -s $em2 exec-out screencap -p > '$OutputDir\screenshots\${em2}_`${ts}_`${counter}.png' 2>&1; Start-Sleep -Seconds 3 }"
) -WindowStyle Minimized

Start-Sleep -Seconds 3

# Run API test
Write-Host ""
Write-Host "[STEP] Running shared ride API test..." -ForegroundColor Yellow
php test_shared_ride_emulators.php 2>&1 | Tee-Object -FilePath "$OutputDir\logs\api_test.log"

# Final database check
Write-Host ""
Write-Host "[STEP] Final database check..." -ForegroundColor Yellow
php check_rides.php 2>&1 | Tee-Object -FilePath "$OutputDir\logs\final_database_check.log"

# Generate report
$report = @"
=== Parallel Shared Ride Test Report ===
Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Output Directory: $OutputDir

Emulators Used:
  - Emulator 1: $em1 (emulator1@test.com)
  - Emulator 2: $em2 (emulator2@test.com)

Files Generated:
  - Screenshots: $OutputDir\screenshots\
  - Database Log: $OutputDir\logs\database_monitor.log  
  - Laravel Log: $OutputDir\logs\laravel_monitor.log
  - Flutter Logs: $OutputDir\logs\flutter_em*.log
  - API Test Log: $OutputDir\logs\api_test.log
  - Final DB Check: $OutputDir\logs\final_database_check.log

NOTE: Monitor windows are still running in background.
Close them manually or they will continue monitoring.

"@

$report | Out-File "$OutputDir\test_report.txt" -Encoding UTF8
Write-Host ""
Write-Host $report -ForegroundColor Cyan

Write-Host "[SUCCESS] Test complete! Review files in: $OutputDir" -ForegroundColor Green


