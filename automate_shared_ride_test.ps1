# Automated Shared Ride Testing Script for Android Emulators
# Uses ADB commands for automation, screenshots, and XML UI dumps

param(
    [string[]]$EmulatorSerials = @(),
    [int]$StepDelay = 3,
    [string]$ScreenshotDir = "emulator_test_screenshots",
    [switch]$KeepEmulatorsOpen = $false
)

$ErrorActionPreference = "Continue"

# Colors for output
function Write-Step { param($msg) Write-Host "[STEP] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Yellow }

# Test credentials
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

# Test coordinates
$coords1 = @{
    pickup_lat = "30.0444"
    pickup_lng = "31.2357"
    dest_lat = "30.0131"
    dest_lng = "31.2089"
}

$coords2 = @{
    pickup_lat = "30.0450"
    pickup_lng = "31.2360"
    dest_lat = "30.0140"
    dest_lng = "31.2095"
}

# Create screenshot directory
if (-not (Test-Path $ScreenshotDir)) {
    New-Item -ItemType Directory -Path $ScreenshotDir | Out-Null
}
Write-Success "Screenshots will be saved to: $ScreenshotDir"

# ADB helper functions
function Get-EmulatorList {
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" }
    return $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }
}

function Take-Screenshot {
    param($serial, $filename)
    $path = Join-Path $ScreenshotDir "${serial}_${filename}"
    adb -s $serial shell screencap -p | Set-Content -Path "$path.png" -Encoding Byte -ErrorAction SilentlyContinue
    if (Test-Path "$path.png") {
        Write-Info "Screenshot: $path.png"
        return $path
    }
    return $null
}

function Get-UIXML {
    param($serial)
    $xmlPath = "/sdcard/ui_dump_$(Get-Date -Format 'yyyyMMddHHmmss').xml"
    adb -s $serial shell uiautomator dump $xmlPath | Out-Null
    adb -s $serial pull $xmlPath "ui_dump_${serial}.xml" 2>&1 | Out-Null
    adb -s $serial shell rm $xmlPath | Out-Null
    if (Test-Path "ui_dump_${serial}.xml") {
        return Get-Content "ui_dump_${serial}.xml" -Raw
    }
    return $null
}

function Tap-Coordinates {
    param($serial, $x, $y)
    adb -s $serial shell input tap $x $y | Out-Null
    Start-Sleep -Milliseconds 500
}

function Input-Text {
    param($serial, $text)
    # Clear first
    adb -s $serial shell input keyevent KEYCODE_CTRL_LEFT KEYCODE_A | Out-Null
    Start-Sleep -Milliseconds 200
    # Type text
    $escapedText = $text -replace ' ', '%s' -replace "'", "''"
    adb -s $serial shell input text "'$escapedText'" 2>&1 | Out-Null
    Start-Sleep -Milliseconds 300
}

function Send-Key {
    param($serial, $keycode)
    adb -s $serial shell input keyevent $keycode | Out-Null
    Start-Sleep -Milliseconds 300
}

function Wait-ForUI {
    param($serial, $timeout = 10)
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        $xml = Get-UIXML $serial
        if ($xml) { return $true }
        Start-Sleep -Seconds 1
        $elapsed++
    }
    return $false
}

function Find-ElementByText {
    param($xml, $text)
    if ($xml -match "text=`"$text`"[^>]*bounds=`"\[(\d+),(\d+)\]\[(\d+),(\d+)\]`"") {
        $matches | Out-Null
        $x = ([int]$matches[1] + [int]$matches[3]) / 2
        $y = ([int]$matches[2] + [int]$matches[4]) / 2
        return @{ X = $x; Y = $y }
    }
    return $null
}

# === MAIN SCRIPT ===

Write-Step "Starting Automated Shared Ride Test"
Write-Host "=" * 60

# Step 1: Check for emulators
Write-Step "Checking for Android emulators..."
$availableEmulators = Get-EmulatorList

if ($availableEmulators.Count -lt 2) {
    Write-Error "Need at least 2 emulators. Found: $($availableEmulators.Count)"
    Write-Info "Available emulators:"
    $availableEmulators | ForEach-Object { Write-Info "  - $_" }
    Write-Info "To start emulators, run:"
    Write-Info "  emulator -avd <avd_name_1> &"
    Write-Info "  emulator -avd <avd_name_2> &"
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

# Step 2: Unlock devices and take initial screenshots
Write-Step "Unlocking devices..."
Send-Key $emulator1.serial "KEYCODE_WAKEUP"
Send-Key $emulator2.serial "KEYCODE_WAKEUP"
Start-Sleep -Seconds 2
Send-Key $emulator1.serial "KEYCODE_MENU"
Send-Key $emulator2.serial "KEYCODE_MENU"
Take-Screenshot $emulator1.serial "00_initial"
Take-Screenshot $emulator2.serial "00_initial"

# Step 3: Launch app on both emulators (parallel)
Write-Step "Launching Rider app on both emulators..."
$appPackage = "com.ovoride.rider"  # Adjust package name as needed
Start-Job -ScriptBlock {
    param($serial, $package)
    adb -s $serial shell monkey -p $package -c android.intent.category.LAUNCHER 1
} -ArgumentList $emulator1.serial, $appPackage | Out-Null

Start-Job -ScriptBlock {
    param($serial, $package)
    adb -s $serial shell monkey -p $package -c android.intent.category.LAUNCHER 1
} -ArgumentList $emulator2.serial, $appPackage | Out-Null

Start-Sleep -Seconds 5
Take-Screenshot $emulator1.serial "01_app_launched"
Take-Screenshot $emulator2.serial "01_app_launched"

# Step 4: Login on both emulators (parallel)
Write-Step "Logging in users on both emulators..."
# Note: This is a simplified version. You'll need to adapt based on your app's UI structure

# For Emulator 1
Start-Job -ScriptBlock {
    param($serial, $email, $password)
    
    # Get UI XML to find elements
    $xml = adb -s $serial shell uiautomator dump /sdcard/ui.xml
    adb -s $serial pull /sdcard/ui.xml "temp_${serial}.xml" 2>&1 | Out-Null
    
    # Try to find and tap username/email field (adjust coordinates based on your UI)
    # This is a template - you'll need to adjust based on actual UI
    adb -s $serial shell input tap 500 400  # Approximate position
    
    # Enter email
    $emailEscaped = $email -replace '@', '\@'
    adb -s $serial shell input text "$emailEscaped"
    Start-Sleep -Seconds 1
    
    # Tap password field
    adb -s $serial shell input tap 500 500
    Start-Sleep -Seconds 1
    
    # Enter password
    adb -s $serial shell input text "$password"
    Start-Sleep -Seconds 1
    
    # Tap login button (approximate)
    adb -s $serial shell input tap 500 600
    
} -ArgumentList $emulator1.serial, $emulator1.email, $emulator1.password | Out-Null

# Similar for Emulator 2
Start-Job -ScriptBlock {
    param($serial, $email, $password)
    # Same login logic
    adb -s $serial shell input tap 500 400
    $emailEscaped = $email -replace '@', '\@'
    adb -s $serial shell input text "$emailEscaped"
    Start-Sleep -Seconds 1
    adb -s $serial shell input tap 500 500
    adb -s $serial shell input text "$password"
    Start-Sleep -Seconds 1
    adb -s $serial shell input tap 500 600
} -ArgumentList $emulator2.serial, $emulator2.email, $emulator2.password | Out-Null

Start-Sleep -Seconds $StepDelay
Take-Screenshot $emulator1.serial "02_after_login"
Take-Screenshot $emulator2.serial "02_after_login"

Write-Warning "NOTE: The automation script uses approximate coordinates."
Write-Warning "You may need to adjust tap coordinates based on your actual UI layout."
Write-Warning "Consider using UI Automator Viewer to get exact coordinates."

# Generate a Python script for more advanced automation
Write-Step "Generating Python automation script for better UI element detection..."


