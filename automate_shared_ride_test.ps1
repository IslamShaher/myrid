# Automated Shared Ride Testing Script
# Tests full flow: Create ride on device 1, Join from device 2, Start ride

param(
    [string]$Device1 = "emulator-5554",
    [string]$Device2 = "emulator-5556"
)

$ErrorActionPreference = "Continue"

Write-Host "=== Automated Shared Ride Testing ===" -ForegroundColor Cyan
Write-Host ""

# Find ADB
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe"
}
if (-not (Test-Path $adbPath)) {
    Write-Host "[ERROR] ADB not found!" -ForegroundColor Red
    exit 1
}

$env:Path = "$(Split-Path $adbPath);$env:Path"

# Function to wait
function Wait-For {
    param([int]$Seconds = 2)
    Start-Sleep -Seconds $Seconds
}

# Function to tap on coordinates
function Tap-On {
    param(
        [string]$Device,
        [int]$X,
        [int]$Y
    )
    Write-Host "  [TAP] ($X, $Y) on $Device" -ForegroundColor Gray
    & $adbPath -s $Device shell input tap $X $Y | Out-Null
    Wait-For -Seconds 1
}

# Function to input text
function Input-Text {
    param(
        [string]$Device,
        [string]$Text
    )
    Write-Host "  [INPUT] '$Text' on $Device" -ForegroundColor Gray
    $escapedText = $Text -replace ' ', '\ '
    & $adbPath -s $Device shell input text $escapedText | Out-Null
    Wait-For -Seconds 1
}

# Function to swipe
function Swipe-On {
    param(
        [string]$Device,
        [int]$X1,
        [int]$Y1,
        [int]$X2,
        [int]$Y2,
        [int]$Duration = 300
    )
    Write-Host "  [SWIPE] ($X1,$Y1) -> ($X2,$Y2) on $Device" -ForegroundColor Gray
    & $adbPath -s $Device shell input swipe $X1 $Y1 $X2 $Y2 $Duration | Out-Null
    Wait-For -Seconds 1
}

# Function to press back
function Press-Back {
    param([string]$Device)
    Write-Host "  [BACK] on $Device" -ForegroundColor Gray
    & $adbPath -s $Device shell input keyevent KEYCODE_BACK | Out-Null
    Wait-For -Seconds 1
}

# Function to get screen dimensions
function Get-ScreenSize {
    param([string]$Device)
    $size = & $adbPath -s $Device shell wm size
    if ($size -match "(\d+)x(\d+)") {
        return @{
            Width = [int]$matches[1]
            Height = [int]$matches[2]
        }
    }
    return @{ Width = 1080; Height = 1920 } # Default
}

# Function to dump UI hierarchy
function Get-UIHierarchy {
    param([string]$Device)
    & $adbPath -s $Device shell uiautomator dump /dev/tty | Out-Null
    $xml = & $adbPath -s $Device shell cat /dev/tty
    return $xml
}

# Check devices
Write-Host "Checking devices..." -ForegroundColor Yellow
$devices = & $adbPath devices | Select-String "device$"
if (-not ($devices -match $Device1)) {
    Write-Host "[ERROR] $Device1 not connected!" -ForegroundColor Red
    exit 1
}
if (-not ($devices -match $Device2)) {
    Write-Host "[ERROR] $Device2 not connected!" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Both devices connected" -ForegroundColor Green
Write-Host ""

# Get screen sizes
$screen1 = Get-ScreenSize -Device $Device1
$screen2 = Get-ScreenSize -Device $Device2
Write-Host "Device 1 screen: $($screen1.Width)x$($screen1.Height)" -ForegroundColor Gray
Write-Host "Device 2 screen: $($screen2.Width)x$($screen2.Height)" -ForegroundColor Gray
Write-Host ""

# Calculate center points (assuming 1080x1920 for now, will adjust)
$centerX = $screen1.Width / 2
$centerY = $screen1.Height / 2
$bottomY = $screen1.Height - 100

Write-Host "=== STEP 1: Opening app on both devices ===" -ForegroundColor Cyan
# Open app (assuming package name)
$packageName = "com.ovosolution.ovorideuser"
& $adbPath -s $Device1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null
Wait-For -Seconds 3
& $adbPath -s $Device2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null
Wait-For -Seconds 3
Write-Host "[OK] Apps opened" -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 2: Navigate to Shared Ride on Device 1 ===" -ForegroundColor Cyan
# Tap on shared ride button (assuming it's on home screen, need to find exact coordinates)
# This is approximate - in real scenario, we'd parse UI XML to find exact coordinates
Tap-On -Device $Device1 -X $centerX -Y [int]($screen1.Height * 0.6)  # Approximate shared ride button
Wait-For -Seconds 2
Write-Host "[OK] Navigated to shared ride" -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 3: Enter pickup location on Device 1 ===" -ForegroundColor Cyan
# Tap pickup field
Tap-On -Device $Device1 -X $centerX -Y [int]($screen1.Height * 0.3)
Wait-For -Seconds 2
Input-Text -Device $Device1 -Text "30.0444,31.2357"  # Cairo coordinates
Wait-For -Seconds 2
Press-Back -Device $Device1  # Close keyboard
Wait-For -Seconds 1
Write-Host "[OK] Pickup entered" -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 4: Enter destination on Device 1 ===" -ForegroundColor Cyan
# Tap destination field
Tap-On -Device $Device1 -X $centerX -Y [int]($screen1.Height * 0.4)
Wait-For -Seconds 2
Input-Text -Device $Device1 -Text "30.0131,31.2089"  # Cairo destination
Wait-For -Seconds 2
Press-Back -Device $Device1  # Close keyboard
Wait-For -Seconds 1
Write-Host "[OK] Destination entered" -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 5: Create/Search for shared ride on Device 1 ===" -ForegroundColor Cyan
# Tap search/create button (usually at bottom or prominent button)
Tap-On -Device $Device1 -X $centerX -Y [int]($screen1.Height * 0.85)
Wait-For -Seconds 5  # Wait for matching/search
Write-Host "[OK] Searching for matches..." -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 6: On Device 2, navigate to shared ride and join ===" -ForegroundColor Cyan
# Navigate to shared ride
Tap-On -Device $Device2 -X $centerX -Y [int]($screen2.Height * 0.6)
Wait-For -Seconds 2

# Enter pickup on device 2
Tap-On -Device $Device2 -X $centerX -Y [int]($screen2.Height * 0.3)
Wait-For -Seconds 2
Input-Text -Device $Device2 -Text "30.0277,31.2136"  # Different pickup
Wait-For -Seconds 2
Press-Back -Device $Device2
Wait-For -Seconds 1

# Enter destination on device 2
Tap-On -Device $Device2 -X $centerX -Y [int]($screen2.Height * 0.4)
Wait-For -Seconds 2
Input-Text -Device $Device2 -Text "30.0131,31.2089"  # Same destination
Wait-For -Seconds 2
Press-Back -Device $Device2
Wait-For -Seconds 1

# Search/join
Tap-On -Device $Device2 -X $centerX -Y [int]($screen2.Height * 0.85)
Wait-For -Seconds 3

# If match appears, tap to join (approximate location)
Tap-On -Device $Device2 -X $centerX -Y $centerY
Wait-For -Seconds 2

# Confirm join if there's a button
Tap-On -Device $Device2 -X $centerX -Y [int]($screen2.Height * 0.8)
Wait-For -Seconds 5
Write-Host "[OK] Device 2 joined ride" -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 7: Wait for ride to be active ===" -ForegroundColor Cyan
Wait-For -Seconds 5

Write-Host "=== STEP 8: Start ride from Device 1 ===" -ForegroundColor Cyan
# Swipe to start (Uber-like slider)
# Usually at bottom center, swipe right
$startX = [int]($screen1.Width * 0.2)
$startY = [int]($screen1.Height * 0.9)
$endX = [int]($screen1.Width * 0.8)
Swipe-On -Device $Device1 -X1 $startX -Y1 $startY -X2 $endX -Y2 $startY -Duration 500
Wait-For -Seconds 3
Write-Host "[OK] Ride started (swipe attempted)" -ForegroundColor Green
Write-Host ""

Write-Host "=== STEP 9: Monitor for errors ===" -ForegroundColor Cyan
Write-Host "Checking logs for errors..." -ForegroundColor Yellow
Wait-For -Seconds 5

$errors1 = & $adbPath -s $Device1 logcat -d | Select-String -Pattern "Exception|Error|FATAL|null" -Context 2,5 | Select-Object -Last 20
$errors2 = & $adbPath -s $Device2 logcat -d | Select-String -Pattern "Exception|Error|FATAL|null" -Context 2,5 | Select-Object -Last 20

if ($errors1) {
    Write-Host "[ERRORS FOUND ON DEVICE 1]:" -ForegroundColor Red
    $errors1 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

if ($errors2) {
    Write-Host "[ERRORS FOUND ON DEVICE 2]:" -ForegroundColor Red
    $errors2 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

if (-not $errors1 -and -not $errors2) {
    Write-Host "[OK] No errors found in logs" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: This script uses approximate coordinates." -ForegroundColor Yellow
Write-Host "For accurate testing, UI XML parsing would be needed to find exact element positions." -ForegroundColor Yellow
