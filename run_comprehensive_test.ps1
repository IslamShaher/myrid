# Comprehensive Parallel Testing - Shared Ride between 2 Emulators
# Monitors database, Laravel logs, Flutter logs, and captures screenshots in parallel

param(
    [string[]]$EmulatorSerials = @()
)

$ErrorActionPreference = "Continue"

function Write-Header { param($msg) Write-Host "`n$('=' * 70)" -ForegroundColor Cyan; Write-Host $msg -ForegroundColor Cyan; Write-Host $('=' * 70) -ForegroundColor Cyan }
function Write-Step { param($msg) Write-Host "`n[STEP] $msg" -ForegroundColor Yellow }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor White }

# Configuration
$emulator1 = @{
    email = "emulator1@test.com"
    password = "password123"
    serial = ""
}

$emulator2 = @{
    email = "emulator2@test.com"
    password = "password123"
    serial = ""
}

$OutputDir = "test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$Jobs = @{}

Write-Header "Comprehensive Parallel Shared Ride Test"

# === STEP 1: Check Emulators ===
Write-Step "Step 1: Checking for Android emulators..."

$devices = adb devices 2>&1 | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" -and $_ -match "device" }
$availableEmulators = $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }

if ($availableEmulators.Count -lt 2) {
    Write-Error "Need at least 2 emulators. Found: $($availableEmulators.Count)"
    Write-Info "Start emulators with: emulator -avd <avd_name> &"
    Write-Info "Or check: adb devices"
    exit 1
}

if ($EmulatorSerials.Count -ge 2) {
    $emulator1.serial = $EmulatorSerials[0]
    $emulator2.serial = $EmulatorSerials[1]
} else {
    $emulator1.serial = $availableEmulators[0]
    $emulator2.serial = $availableEmulators[1]
}

Write-Success "Emulator 1: $($emulator1.serial)"
Write-Success "Emulator 2: $($emulator2.serial)"

# Save config for future reference
@{
    emulator1_serial = $emulator1.serial
    emulator2_serial = $emulator2.serial
    last_used = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
} | ConvertTo-Json | Out-File "emulator_config.json" -Encoding UTF8

# Create output directories
$dirs = @("$OutputDir", "$OutputDir\screenshots", "$OutputDir\logs", "$OutputDir\database")
foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
}

Write-Success "Output directory: $OutputDir"

# === STEP 2: Start Database Monitor ===
Write-Step "Step 2: Starting database monitor (background job)..."

$dbLogFile = "$OutputDir\logs\database_monitor.log"
# Start database monitor using PHP directly
$dbMonitorProcess = Start-Process -FilePath "php" -ArgumentList "monitor_database.php", $dbLogFile -PassThru -NoNewWindow -WindowStyle Hidden
Start-Sleep -Seconds 2
$Jobs['database'] = $dbMonitorProcess
Write-Info "Database monitor started (PID: $($dbMonitorProcess.Id))"

# === STEP 3: Start Laravel Log Monitor ===
Write-Step "Step 3: Starting Laravel log monitor..."

$laravelLogFile = "$OutputDir\logs\laravel_monitor.log"
$laravelJob = Start-Job -ScriptBlock {
    param($sourceLog, $outputLog)
    $lastSize = 0
    while ($true) {
        if (Test-Path $sourceLog) {
            $currentSize = (Get-Item $sourceLog -ErrorAction SilentlyContinue).Length
            if ($currentSize -gt $lastSize) {
                Get-Content $sourceLog -Tail 20 -ErrorAction SilentlyContinue | 
                    ForEach-Object { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $_" | Add-Content $outputLog }
                $lastSize = $currentSize
            }
        }
        Start-Sleep -Seconds 1
    }
} -ArgumentList "storage\logs\laravel.log", $laravelLogFile

$Jobs['laravel'] = $laravelJob

# === STEP 4: Start Flutter Log Monitors ===
Write-Step "Step 4: Starting Flutter log monitors..."

# Clear logcat buffers first
adb -s $emulator1.serial logcat -c 2>&1 | Out-Null
adb -s $emulator2.serial logcat -c 2>&1 | Out-Null

$flutterLog1 = Start-Job -ScriptBlock {
    param($serial, $outputFile)
    while ($true) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $log = adb -s $serial logcat -d -s flutter:* *:E 2>&1 | Select-Object -Last 10
        if ($log) {
            "[$timestamp] $serial" | Add-Content $outputFile
            $log | Add-Content $outputFile
        }
        adb -s $serial logcat -c 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} -ArgumentList $emulator1.serial, "$OutputDir\logs\flutter_em1.log"

$flutterLog2 = Start-Job -ScriptBlock {
    param($serial, $outputFile)
    while ($true) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $log = adb -s $serial logcat -d -s flutter:* *:E 2>&1 | Select-Object -Last 10
        if ($log) {
            "[$timestamp] $serial" | Add-Content $outputFile
            $log | Add-Content $outputFile
        }
        adb -s $serial logcat -c 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} -ArgumentList $emulator2.serial, "$OutputDir\logs\flutter_em2.log"

$Jobs['flutter1'] = $flutterLog1
$Jobs['flutter2'] = $flutterLog2

# === STEP 5: Start Screenshot Monitor ===
Write-Step "Step 5: Starting screenshot monitor..."

$screenshotJob = Start-Job -ScriptBlock {
    param($serial1, $serial2, $outputDir, $interval)
    $counter = 0
    while ($true) {
        $counter++
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        
        # Screenshot both emulators in parallel
        $job1 = Start-Job -ScriptBlock { param($s, $f) adb -s $s exec-out screencap -p > $f 2>&1 } -ArgumentList $serial1, "$outputDir\${serial1}_${timestamp}_${counter}.png"
        $job2 = Start-Job -ScriptBlock { param($s, $f) adb -s $s exec-out screencap -p > $f 2>&1 } -ArgumentList $serial2, "$outputDir\${serial2}_${timestamp}_${counter}.png"
        
        $job1, $job2 | Wait-Job | Out-Null
        $job1, $job2 | Remove-Job
        
        Start-Sleep -Seconds $interval
    }
} -ArgumentList $emulator1.serial, $emulator2.serial, "$OutputDir\screenshots", 3

$Jobs['screenshots'] = $screenshotJob

# === STEP 6: Wait for monitors to start ===
Write-Step "Step 6: Waiting for monitors to initialize..."
Start-Sleep -Seconds 3

# === STEP 7: Run API Test ===
Write-Step "Step 7: Running shared ride API test..."

Write-Info "Executing test_shared_ride_emulators.php..."
$testOutput = php test_shared_ride_emulators.php 2>&1
$testOutput | Tee-Object -FilePath "$OutputDir\logs\api_test.log"

Write-Host ""
Write-Info "API Test Output:"
Write-Host $testOutput

# === STEP 8: Monitor Progress ===
Write-Header "Active Monitoring - Press Ctrl+C to stop or wait 60 seconds"

$startTime = Get-Date
$monitorDuration = 60
$elapsed = 0

try {
    while ($elapsed -lt $monitorDuration) {
        Clear-Host
        Write-Header "Parallel Test Monitor - $OutputDir"
        Write-Host "Elapsed: $elapsed / $monitorDuration seconds`n"
        
        # Monitor status
        Write-Host "[Monitor Status]"
        foreach ($key in $Jobs.Keys) {
            $job = $Jobs[$key]
            if ($job -is [System.Management.Automation.Job]) {
                Write-Host "  $key : $($job.State)" -ForegroundColor $(if ($job.State -eq 'Running') { 'Green' } else { 'Yellow' })
            } elseif ($job -is [System.Diagnostics.Process]) {
                $status = if ($job.HasExited) { "Stopped" } else { "Running" }
                Write-Host "  $key : $status" -ForegroundColor $(if ($status -eq 'Running') { 'Green' } else { 'Yellow' })
            }
        }
        
        # Database status
        Write-Host "`n[Database Status] (last 3 lines)"
        if (Test-Path "$OutputDir\logs\database_monitor.log") {
            Get-Content "$OutputDir\logs\database_monitor.log" -Tail 3 -ErrorAction SilentlyContinue | 
                ForEach-Object { Write-Host "  $_" -ForegroundColor White }
        }
        
        # Screenshot count
        $screenshotCount = (Get-ChildItem "$OutputDir\screenshots" -ErrorAction SilentlyContinue).Count
        Write-Host "`n[Screenshots: $screenshotCount]"
        
        Start-Sleep -Seconds 5
        $elapsed += 5
    }
} catch {
    Write-Error "Monitoring interrupted: $_"
} finally {
    # Cleanup
    Write-Step "Stopping all monitors..."
    
    # Stop jobs
    foreach ($job in $Jobs.Values) {
        if ($job -is [System.Management.Automation.Job]) {
            Stop-Job -Job $job -ErrorAction SilentlyContinue
            Remove-Job -Job $job -ErrorAction SilentlyContinue
        } elseif ($job -is [System.Diagnostics.Process] -and -not $job.HasExited) {
            Stop-Process -Id $job.Id -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Stop database monitor
    Get-Process php -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*monitor_database*" } | 
        Stop-Process -Force -ErrorAction SilentlyContinue
}

# === STEP 9: Final Database Check ===
Write-Step "Step 9: Final database check..."
php check_rides.php 2>&1 | Tee-Object -FilePath "$OutputDir\logs\final_database_check.log"

# === STEP 10: Generate Report ===
Write-Step "Step 10: Generating test report..."

$report = @"
=== Parallel Shared Ride Test Report ===
Test Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Output Directory: $OutputDir

Emulators Used:
  - Emulator 1: $($emulator1.serial) ($($emulator1.email))
  - Emulator 2: $($emulator2.serial) ($($emulator2.email))

Files Generated:
  - Screenshots: $OutputDir\screenshots\ ($screenshotCount files)
  - Database Log: $OutputDir\logs\database_monitor.log
  - Laravel Log: $OutputDir\logs\laravel_monitor.log
  - Flutter Logs: $OutputDir\logs\flutter_*.log
  - API Test Log: $OutputDir\logs\api_test.log
  - Final DB Check: $OutputDir\logs\final_database_check.log

To review:
  1. Check screenshots for UI states
  2. Review database_monitor.log for ride creation/matching
  3. Check Laravel logs for API errors
  4. Review Flutter logs for app errors

"@

$report | Out-File "$OutputDir\test_report.txt" -Encoding UTF8
Write-Host $report

Write-Header "Test Complete!"
Write-Success "All data saved to: $OutputDir"
Write-Info "Review the files to analyze the shared ride test"

