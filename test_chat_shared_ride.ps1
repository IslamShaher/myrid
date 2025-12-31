# Automated Shared Ride Chat Test Script
$emulator1 = "emulator-5554"
$emulator2 = "emulator-5556"
$packageName = "com.ovosolution.ovorideuser"

Write-Host "=== Shared Ride Chat Automated Test ===" -ForegroundColor Cyan
Write-Host ""

# Create screenshots directory
New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null

# Function to capture screenshot
function Capture-Screenshot {
    param($device, $filename)
    $output = "screenshots\$filename"
    adb -s $device shell screencap -p | Set-Content -Path $output -Encoding Byte -NoNewline
    Write-Host "  Screenshot: $output" -ForegroundColor Green
}

# Step 1: Launch apps
Write-Host "Step 1: Launching apps on both emulators..." -ForegroundColor Yellow
adb -s $emulator1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 3
adb -s $emulator2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 3
Capture-Screenshot -device $emulator1 -filename "01_em1_launched.png"
Capture-Screenshot -device $emulator2 -filename "01_em2_launched.png"

Write-Host "`nStep 2: Monitoring for chat interaction..." -ForegroundColor Yellow
Write-Host "Please:" -ForegroundColor Cyan
Write-Host "  1. Login on both emulators (if needed)" -ForegroundColor White
Write-Host "  2. Create a shared ride on emulator 1" -ForegroundColor White
Write-Host "  3. Join the ride on emulator 2" -ForegroundColor White
Write-Host "  4. Click 'Chat with Partner' button on either emulator" -ForegroundColor White
Write-Host "  5. Send some messages between the two" -ForegroundColor White
Write-Host "`nScript will capture screenshots every 5 seconds for 2 minutes..." -ForegroundColor Cyan

# Monitor and capture screenshots
$monitorCount = 24  # 24 * 5 seconds = 2 minutes
for ($i = 1; $i -le $monitorCount; $i++) {
    Start-Sleep -Seconds 5
    $timestamp = Get-Date -Format "HHmmss"
    Capture-Screenshot -device $emulator1 -filename "chat_${i}_${timestamp}_em1.png"
    Capture-Screenshot -device $emulator2 -filename "chat_${i}_${timestamp}_em2.png"
    if ($i % 6 -eq 0) {
        Write-Host "  Progress: $i/$monitorCount screenshots captured..." -ForegroundColor Gray
    }
}

Write-Host "`n=== Monitoring Complete ===" -ForegroundColor Cyan
Write-Host "Total screenshots captured: $($monitorCount * 2)" -ForegroundColor Green
Write-Host "All screenshots saved in 'screenshots' folder" -ForegroundColor Green



