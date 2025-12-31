# Comprehensive Parallel Testing Script for Shared Rides
# Runs emulators, tests, and monitors database + logs simultaneously

param(
    [string[]]$EmulatorSerials = @(),
    [int]$TestDelay = 5,
    [string]$OutputDir = "parallel_test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

$ErrorActionPreference = "Continue"

# Test configuration
$emulator1 = @{
    email = "emulator1@test.com"
    password = "password123"
    serial = ""
    coordinates = @{
        pickup_lat = "30.0444"
        pickup_lng = "31.2357"
        dest_lat = "30.0131"
        dest_lng = "31.2089"
    }
}

$emulator2 = @{
    email = "emulator2@test.com"
    password = "password123"
    serial = ""
    coordinates = @{
        pickup_lat = "30.0450"
        pickup_lng = "31.2360"
        dest_lat = "30.0140"
        dest_lng = "31.2095"
    }
}

$apiBaseUrl = "http://192.168.1.13:8000/api"
$devToken = "ovoride-dev-123"

function Write-Header { param($msg) Write-Host "`n$('=' * 60)" -ForegroundColor Cyan; Write-Host $msg -ForegroundColor Cyan; Write-Host $('=' * 60) -ForegroundColor Cyan }
function Write-Step { param($msg) Write-Host "[STEP] $msg" -ForegroundColor Yellow }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor White }

# Create output directories
$dirs = @("$OutputDir", "$OutputDir\screenshots", "$OutputDir\logs", "$OutputDir\database")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

Write-Header "Parallel Shared Ride Testing System"

# === STEP 1: Setup ===
Write-Step "Step 1: Setting up emulators and environment..."

# Get emulator list
function Get-EmulatorList {
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" -and $_ -match "device$" }
    return $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }
}

$availableEmulators = Get-EmulatorList
if ($availableEmulators.Count -lt 2) {
    Write-Error "Need at least 2 emulators. Found: $($availableEmulators.Count)"
    Write-Info "Start emulators with: emulator -avd <avd_name> &"
    exit 1
}

# Assign emulators
if ($EmulatorSerials.Count -ge 2) {
    $emulator1.serial = $EmulatorSerials[0]
    $emulator2.serial = $EmulatorSerials[1]
} else {
    $emulator1.serial = $availableEmulators[0]
    $emulator2.serial = $availableEmulators[1]
}

Write-Success "Emulator 1: $($emulator1.serial)"
Write-Success "Emulator 2: $($emulator2.serial)"

# Save configuration
@{
    emulator1 = $emulator1
    emulator2 = $emulator2
    test_time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
} | ConvertTo-Json | Out-File "$OutputDir\test_config.json"

# === STEP 2: Database Monitor (Background Job) ===
Write-Step "Step 2: Starting database monitor..."

$dbMonitorScript = {
    param($outputFile)
    require __DIR__ . '/vendor/autoload.php';
    $app = require_once __DIR__ . '/bootstrap/app.php';
    $app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();
    
    use App\Models\Ride;
    use App\Constants\Status;
    
    $log = @"
=== Database Monitor Started ===
$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

"@
    
    while ($true) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        
        # Count active shared rides
        $activeRides = Ride::where('ride_type', Status::SHARED_RIDE)
            ->where('status', Status::RIDE_ACTIVE)
            ->get();
        
        $matchedRides = Ride::where('ride_type', Status::SHARED_RIDE)
            ->whereNotNull('second_user_id')
            ->get();
        
        $status = @"
[$timestamp] Database Status:
  Active Shared Rides: $($activeRides.Count)
  Matched Rides (with 2nd user): $($matchedRides.Count)

"@
        
        Add-Content -Path $outputFile -Value $status
        Start-Sleep -Seconds 2
    }
}

# Start database monitor as background job
$dbLogFile = "$OutputDir\logs\database_monitor.log"
$dbJob = Start-Job -ScriptBlock {
    param($scriptPath, $logFile)
    php $scriptPath > $logFile 2>&1
} -ArgumentList "monitor_database.php", $dbLogFile

# === STEP 3: Laravel Log Monitor (Background Job) ===
Write-Step "Step 3: Starting Laravel log monitor..."

$laravelLogJob = Start-Job -ScriptBlock {
    param($logPath, $outputPath)
    $lastSize = 0
    while ($true) {
        if (Test-Path $logPath) {
            $currentSize = (Get-Item $logPath).Length
            if ($currentSize -gt $lastSize) {
                $newContent = Get-Content $logPath -Tail 10 -ErrorAction SilentlyContinue
                $newContent | ForEach-Object {
                    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    "[$timestamp] $_" | Add-Content -Path $outputPath
                }
                $lastSize = $currentSize
            }
        }
        Start-Sleep -Seconds 1
    }
} -ArgumentList "storage\logs\laravel.log", "$OutputDir\logs\laravel_monitor.log"

# === STEP 4: Flutter Log Monitors (Background Jobs) ===
Write-Step "Step 4: Starting Flutter log monitors..."

$flutterLog1 = Start-Job -ScriptBlock {
    param($serial, $outputPath)
    $buffer = ""
    while ($true) {
        $newLog = adb -s $serial logcat -d *:V 2>&1 | Select-Object -Last 20
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        "[$timestamp] Emulator $serial Flutter Log:" | Add-Content -Path $outputPath
        $newLog | Add-Content -Path $outputPath
        adb -s $serial logcat -c 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} -ArgumentList $emulator1.serial, "$OutputDir\logs\flutter_emulator1.log"

$flutterLog2 = Start-Job -ScriptBlock {
    param($serial, $outputPath)
    $buffer = ""
    while ($true) {
        $newLog = adb -s $serial logcat -d *:V 2>&1 | Select-Object -Last 20
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        "[$timestamp] Emulator $serial Flutter Log:" | Add-Content -Path $outputPath
        $newLog | Add-Content -Path $outputPath
        adb -s $serial logcat -c 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} -ArgumentList $emulator2.serial, "$OutputDir\logs\flutter_emulator2.log"

# === STEP 5: Screenshot Monitor (Background Job) ===
Write-Step "Step 5: Starting screenshot monitor..."

$screenshotJob = Start-Job -ScriptBlock {
    param($serial1, $serial2, $outputDir, $interval)
    $counter = 0
    while ($true) {
        $counter++
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        # Screenshot emulator 1
        adb -s $serial1 exec-out screencap -p > "$outputDir\screenshots\${serial1}_${timestamp}.png" 2>&1
        
        # Screenshot emulator 2
        adb -s $serial2 exec-out screencap -p > "$outputDir\screenshots\${serial2}_${timestamp}.png" 2>&1
        
        Start-Sleep -Seconds $interval
    }
} -ArgumentList $emulator1.serial, $emulator2.serial, "$OutputDir\screenshots", 3

# === STEP 6: Create Database Monitor PHP Script ===
Write-Step "Step 6: Creating database monitor script..."

$dbMonitorPhp = @'
<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Ride;
use App\Constants\Status;

$outputFile = $argv[1] ?? 'database_monitor.log';
$fp = fopen($outputFile, 'a');

fwrite($fp, "=== Database Monitor Started ===\n");
fwrite($fp, date('Y-m-d H:i:s') . "\n\n");

while (true) {
    $timestamp = date('Y-m-d H:i:s');
    
    // Count active shared rides
    $activeRides = Ride::where('ride_type', Status::SHARED_RIDE)
        ->where('status', Status::RIDE_ACTIVE)
        ->whereNull('second_user_id')
        ->get();
    
    $matchedRides = Ride::where('ride_type', Status::SHARED_RIDE)
        ->whereNotNull('second_user_id')
        ->get();
    
    $allSharedRides = Ride::where('ride_type', Status::SHARED_RIDE)
        ->orderBy('created_at', 'desc')
        ->limit(5)
        ->get();
    
    fwrite($fp, "[$timestamp] Database Status:\n");
    fwrite($fp, "  Active Shared Rides (available for matching): " . $activeRides->count() . "\n");
    fwrite($fp, "  Matched Rides (with 2nd user): " . $matchedRides->count() . "\n");
    fwrite($fp, "  Recent Shared Rides:\n");
    
    foreach ($allSharedRides as $ride) {
        fwrite($fp, sprintf(
            "    Ride ID: %d | User: %d | 2nd User: %s | Status: %d\n",
            $ride->id,
            $ride->user_id,
            $ride->second_user_id ?? 'NULL',
            $ride->status
        ));
    }
    
    fwrite($fp, "\n");
    fflush($fp);
    sleep(2);
}
'@

$dbMonitorPhp | Out-File -FilePath "monitor_database.php" -Encoding UTF8

# === STEP 7: Run API Test ===
Write-Step "Step 7: Running API test for shared ride creation..."

Start-Sleep -Seconds 3  # Wait for monitors to start

Write-Info "Executing API test script..."
php test_shared_ride_emulators.php 2>&1 | Tee-Object -FilePath "$OutputDir\logs\api_test.log"

# === STEP 8: Monitor Progress ===
Write-Header "Monitoring Active - Press Ctrl+C to stop"

$startTime = Get-Date
$monitoringDuration = 60  # Monitor for 60 seconds after test

try {
    $elapsed = 0
    while ($elapsed -lt $monitoringDuration) {
        Clear-Host
        Write-Header "Parallel Test Monitor - $OutputDir"
        
        Write-Host "`n[Monitor Status]"
        Write-Host "  Database Monitor: $($dbJob.State)"
        Write-Host "  Laravel Log Monitor: $($laravelLogJob.State)"
        Write-Host "  Flutter Log 1: $($flutterLog1.State)"
        Write-Host "  Flutter Log 2: $($flutterLog2.State)"
        Write-Host "  Screenshot Monitor: $($screenshotJob.State)"
        
        Write-Host "`n[Database Status] (last 5 lines)"
        if (Test-Path "$OutputDir\logs\database_monitor.log") {
            Get-Content "$OutputDir\logs\database_monitor.log" -Tail 5 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" }
        }
        
        Write-Host "`n[Laravel Logs] (last 3 lines)"
        if (Test-Path "$OutputDir\logs\laravel_monitor.log") {
            Get-Content "$OutputDir\logs\laravel_monitor.log" -Tail 3 -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $_" }
        }
        
        Write-Host "`n[Screenshots captured: $((Get-ChildItem "$OutputDir\screenshots" -ErrorAction SilentlyContinue).Count)]"
        Write-Host "`n[Time elapsed: $elapsed seconds / $monitoringDuration seconds]"
        
        Start-Sleep -Seconds 5
        $elapsed += 5
    }
} catch {
    Write-Error "Monitoring interrupted: $_"
} finally {
    # Cleanup
    Write-Step "Stopping monitors..."
    $dbJob, $laravelLogJob, $flutterLog1, $flutterLog2, $screenshotJob | Stop-Job -ErrorAction SilentlyContinue
    $dbJob, $laravelLogJob, $flutterLog1, $flutterLog2, $screenshotJob | Remove-Job -ErrorAction SilentlyContinue
    
    # Kill database monitor PHP process
    Get-Process -Name "php" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*monitor_database*" } | Stop-Process -Force -ErrorAction SilentlyContinue
}

# === STEP 9: Generate Report ===
Write-Step "Step 9: Generating test report..."

$report = @"
=== Parallel Shared Ride Test Report ===
Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Output Directory: $OutputDir

Emulators Used:
  - Emulator 1: $($emulator1.serial) ($($emulator1.email))
  - Emulator 2: $($emulator2.serial) ($($emulator2.email))

Test Coordinates:
  Emulator 1: ($($emulator1.coordinates.pickup_lat), $($emulator1.coordinates.pickup_lng)) -> ($($emulator1.coordinates.dest_lat), $($emulator1.coordinates.dest_lng))
  Emulator 2: ($($emulator2.coordinates.pickup_lat), $($emulator2.coordinates.pickup_lng)) -> ($($emulator2.coordinates.dest_lat), $($emulator2.coordinates.dest_lng))

Files Generated:
  - Screenshots: $OutputDir\screenshots\
  - Database Log: $OutputDir\logs\database_monitor.log
  - Laravel Log: $OutputDir\logs\laravel_monitor.log
  - Flutter Logs: $OutputDir\logs\flutter_*.log
  - API Test Log: $OutputDir\logs\api_test.log

"@

$report | Out-File "$OutputDir\test_report.txt"
Write-Host $report

Write-Header "Test Complete!"
Write-Success "All logs and screenshots saved to: $OutputDir"
Write-Info "Review the files to see database changes, API calls, and UI states"




