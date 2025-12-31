# Script to test shared ride chat between two emulators
# Assumes both emulators are running and app is installed

$emulator1 = "emulator-5554"
$emulator2 = "emulator-5556"
$packageName = "com.ovosolution.ovorideuser"

Write-Host "=== Shared Ride Chat Test ===" -ForegroundColor Cyan
Write-Host ""

# Function to capture screenshot
function Capture-Screenshot {
    param($device, $filename)
    $output = "screenshots\$filename"
    New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null
    adb -s $device shell screencap -p | Set-Content -Path $output -Encoding Byte -NoNewline
    Write-Host "Screenshot saved: $output" -ForegroundColor Green
}

# Function to dump UI XML
function Dump-UI {
    param($device, $filename)
    $output = "screenshots\$filename"
    adb -s $device shell uiautomator dump /dev/tty | Out-Null
    adb -s $device pull /sdcard/window_dump.xml $output 2>&1 | Out-Null
    Write-Host "UI dump saved: $output"
}

# Function to wait for UI element
function Wait-ForElement {
    param($device, $timeout = 10)
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        Start-Sleep -Seconds 1
        $elapsed++
    }
}

# Function to tap on coordinates
function Tap-Coordinate {
    param($device, $x, $y)
    adb -s $device shell input tap $x $y
    Start-Sleep -Milliseconds 500
}

# Function to send text
function Send-Text {
    param($device, $text)
    adb -s $device shell input text $text
    Start-Sleep -Milliseconds 300
}

Write-Host "Step 1: Launching app on both emulators..." -ForegroundColor Yellow
adb -s $emulator1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 3
adb -s $emulator2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 3

Capture-Screenshot -device $emulator1 -filename "01_emulator1_launched.png"
Capture-Screenshot -device $emulator2 -filename "01_emulator2_launched.png"

Write-Host "`nStep 2: Creating shared ride on emulator 1..." -ForegroundColor Yellow
# Navigate to shared ride screen (this would need to be customized based on your UI)
# For now, just capture current state
Capture-Screenshot -device $emulator1 -filename "02_emulator1_home.png"
Capture-Screenshot -device $emulator2 -filename "02_emulator2_home.png"

Write-Host "`nNote: Manual interaction may be needed to:" -ForegroundColor Yellow
Write-Host "  1. Create a shared ride on emulator 1" -ForegroundColor Yellow
Write-Host "  2. Join the ride on emulator 2" -ForegroundColor Yellow
Write-Host "  3. Click chat button on either emulator" -ForegroundColor Yellow
Write-Host "  4. Send messages between the two" -ForegroundColor Yellow

Write-Host "`nScript will capture screenshots every 5 seconds for monitoring..." -ForegroundColor Cyan
$count = 0
for ($i = 0; $i -lt 12; $i++) {
    Start-Sleep -Seconds 5
    $count++
    Capture-Screenshot -device $emulator1 -filename "monitor_${count}_em1.png"
    Capture-Screenshot -device $emulator2 -filename "monitor_${count}_em2.png"
    Write-Host "Captured monitoring screenshots #$count" -ForegroundColor Gray
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Screenshots saved in 'screenshots' folder"



