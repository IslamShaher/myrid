# Automated test script for shared ride chat between two emulators
$emulator1 = "emulator-5554"
$emulator2 = "emulator-5556"
$packageName = "com.ovosolution.ovorideuser"

Write-Host "=== Automated Shared Ride Chat Test ===" -ForegroundColor Cyan
Write-Host ""

# Function to capture screenshot
function Capture-Screenshot {
    param($device, $filename)
    $output = "screenshots\$filename"
    New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null
    adb -s $device shell screencap -p | Set-Content -Path $output -Encoding Byte -NoNewline
    Write-Host "Screenshot: $output" -ForegroundColor Green
}

# Function to wait
function Wait-For {
    param($seconds)
    Start-Sleep -Seconds $seconds
}

# Step 1: Launch apps
Write-Host "Step 1: Launching apps..." -ForegroundColor Yellow
adb -s $emulator1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Wait-For -seconds 3
adb -s $emulator2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Wait-For -seconds 3
Capture-Screenshot -device $emulator1 -filename "01_em1_launched.png"
Capture-Screenshot -device $emulator2 -filename "01_em2_launched.png"

Write-Host "`nApps launched. Waiting for you to:" -ForegroundColor Cyan
Write-Host "  1. Login on both emulators" -ForegroundColor Yellow
Write-Host "  2. Create a shared ride on emulator 1" -ForegroundColor Yellow
Write-Host "  3. Join the ride on emulator 2" -ForegroundColor Yellow
Write-Host "  4. Click 'Chat with Partner' on either emulator" -ForegroundColor Yellow
Write-Host "`nScript will capture screenshots every 3 seconds..." -ForegroundColor Cyan

# Monitor and capture screenshots
for ($i = 1; $i -le 20; $i++) {
    Wait-For -seconds 3
    Capture-Screenshot -device $emulator1 -filename "chat_test_${i}_em1.png"
    Capture-Screenshot -device $emulator2 -filename "chat_test_${i}_em2.png"
    Write-Host "Captured screenshots #$i" -ForegroundColor Gray
}

Write-Host "`n=== Test Monitoring Complete ===" -ForegroundColor Cyan
Write-Host "Screenshots saved in 'screenshots' folder"



