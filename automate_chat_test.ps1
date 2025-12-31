# Automated Chat Test Script
# This script attempts to automate the chat flow between two emulators

$emulator1 = "emulator-5554"
$emulator2 = "emulator-5556"
$packageName = "com.ovosolution.ovorideuser"

Write-Host "=== Automated Shared Ride Chat Test ===" -ForegroundColor Cyan
Write-Host ""

function Capture-Screenshot {
    param($device, $filename)
    $output = "screenshots\$filename"
    New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null
    adb -s $device shell screencap -p | Set-Content -Path $output -Encoding Byte -NoNewline
    Write-Host "  Screenshot: $output" -ForegroundColor Green
}

function Wait-For {
    param($seconds)
    Start-Sleep -Seconds $seconds
}

function Tap-Coordinates {
    param($device, $x, $y)
    adb -s $device shell input tap $x $y
    Wait-For -seconds 1
}

function Send-Text {
    param($device, $text)
    # Replace spaces with %s for ADB input
    $text = $text -replace ' ', '%s'
    adb -s $device shell input text $text
    Wait-For -seconds 0.5
}

function Get-UI-Dump {
    param($device, $outputFile)
    adb -s $device shell uiautomator dump /dev/tty 2>&1 | Out-Null
    adb -s $device pull /sdcard/window_dump.xml $outputFile 2>&1 | Out-Null
}

# Step 1: Launch apps
Write-Host "Step 1: Launching apps..." -ForegroundColor Yellow
adb -s $emulator1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Wait-For -seconds 3
adb -s $emulator2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Wait-For -seconds 3
Capture-Screenshot -device $emulator1 -filename "01_em1_launched.png"
Capture-Screenshot -device $emulator2 -filename "01_em2_launched.png"

Write-Host "`nStep 2: Waiting for manual login/interaction..." -ForegroundColor Yellow
Write-Host "Please login on both emulators and create/join a shared ride" -ForegroundColor Cyan
Write-Host "The script will then attempt to click the chat button and send messages" -ForegroundColor Cyan

# Wait for user to set up the ride
Write-Host "`nWaiting 30 seconds for you to set up the shared ride..." -ForegroundColor Yellow
Wait-For -seconds 30

Capture-Screenshot -device $emulator1 -filename "02_em1_before_chat.png"
Capture-Screenshot -device $emulator2 -filename "02_em2_before_chat.png"

# Try to find and click "Chat" or "Chat with Partner" button
Write-Host "`nStep 3: Attempting to find and click chat button..." -ForegroundColor Yellow

# Get UI dump to find chat button
Get-UI-Dump -device $emulator1 -outputFile "screenshots\em1_ui_dump.xml"
Get-UI-Dump -device $emulator2 -outputFile "screenshots\em2_ui_dump.xml"

# Try to find chat button in UI dump (simplified - would need XML parsing)
# For now, try clicking in a likely area (this is approximate)
# Chat buttons are typically in the bottom area
Write-Host "  Attempting to tap chat button area on emulator 1..." -ForegroundColor Gray
# Approximate coordinates (will need adjustment based on actual UI)
# This is just a placeholder - actual coordinates should be found via UI dump
Tap-Coordinates -device $emulator1 -x 540 -y 1800

Wait-For -seconds 2
Capture-Screenshot -device $emulator1 -filename "03_em1_after_chat_tap.png"

Write-Host "`nStep 4: Monitoring chat screen..." -ForegroundColor Yellow
Write-Host "If chat opened, you can send messages manually" -ForegroundColor Cyan
Write-Host "Script will capture screenshots every 3 seconds for 1 minute..." -ForegroundColor Cyan

# Monitor chat
for ($i = 1; $i -le 20; $i++) {
    Wait-For -seconds 3
    $timestamp = Get-Date -Format "HHmmss"
    Capture-Screenshot -device $emulator1 -filename "chat_monitor_${i}_${timestamp}_em1.png"
    Capture-Screenshot -device $emulator2 -filename "chat_monitor_${i}_${timestamp}_em2.png"
    if ($i % 5 -eq 0) {
        Write-Host "  Captured $i screenshots..." -ForegroundColor Gray
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Screenshots saved in 'screenshots' folder" -ForegroundColor Green



