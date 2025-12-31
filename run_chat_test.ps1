# Shared Ride Chat Test - Automated Monitoring
param(
    [int]$DurationMinutes = 2
)

$emulator1 = "emulator-5554"
$emulator2 = "emulator-5556"
$packageName = "com.ovosolution.ovorideuser"

Write-Host "=== Shared Ride Chat Test ===" -ForegroundColor Cyan
Write-Host "Duration: $DurationMinutes minutes" -ForegroundColor Yellow
Write-Host ""

# Create screenshots directory
if (-not (Test-Path "screenshots")) {
    New-Item -ItemType Directory -Path "screenshots" | Out-Null
}

function Capture-Screenshot {
    param($device, $filename)
    $output = "screenshots\$filename"
    try {
        adb -s $device shell screencap -p | Set-Content -Path $output -Encoding Byte -NoNewline
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Screenshot: $filename" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Failed to capture: $filename" -ForegroundColor Red
        return $false
    }
}

# Launch apps
Write-Host "Launching apps..." -ForegroundColor Yellow
adb -s $emulator1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
Start-Sleep -Seconds 2
adb -s $emulator2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
Start-Sleep -Seconds 2

Capture-Screenshot -device $emulator1 -filename "00_em1_start.png"
Capture-Screenshot -device $emulator2 -filename "00_em2_start.png"

Write-Host "`n=== Monitoring Started ===" -ForegroundColor Cyan
Write-Host "Please perform these steps:" -ForegroundColor Yellow
Write-Host "  1. Login on both emulators (if needed)" -ForegroundColor White
Write-Host "  2. Create a shared ride on emulator 1 ($emulator1)" -ForegroundColor White
Write-Host "  3. Join the ride on emulator 2 ($emulator2)" -ForegroundColor White
Write-Host "  4. Click 'Chat with Partner' on either emulator" -ForegroundColor White
Write-Host "  5. Send messages between the two" -ForegroundColor White
Write-Host "`nCapturing screenshots every 5 seconds..." -ForegroundColor Cyan
Write-Host ""

# Calculate number of captures
$intervalSeconds = 5
$totalCaptures = [math]::Floor(($DurationMinutes * 60) / $intervalSeconds)

for ($i = 1; $i -le $totalCaptures; $i++) {
    Start-Sleep -Seconds $intervalSeconds
    $timestamp = Get-Date -Format "HHmmss"
    Capture-Screenshot -device $emulator1 -filename "chat_${i}_${timestamp}_em1.png"
    Capture-Screenshot -device $emulator2 -filename "chat_${i}_${timestamp}_em2.png"
    
    if ($i % 6 -eq 0) {
        $elapsed = [math]::Floor($i * $intervalSeconds / 60)
        Write-Host "  Progress: $elapsed/$DurationMinutes minutes ($i/$totalCaptures captures)" -ForegroundColor Gray
    }
}

Write-Host "`n=== Monitoring Complete ===" -ForegroundColor Cyan
Write-Host "Total screenshots: $($totalCaptures * 2)" -ForegroundColor Green
Write-Host "Saved in: screenshots\" -ForegroundColor Green



