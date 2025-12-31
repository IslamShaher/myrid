# Complete Automated Chat Test Script
# This script automates the full chat flow between two emulators

$emulator1 = "emulator-5554"
$emulator2 = "emulator-5556"
$packageName = "com.ovosolution.ovorideuser"

Write-Host "=== Automated Shared Ride Chat Test ===" -ForegroundColor Cyan
Write-Host ""

# Create screenshots directory
New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null

function Capture-Screenshot {
    param($device, $filename)
    $output = "screenshots\$filename"
    adb -s $device shell screencap -p | Set-Content -Path $output -Encoding Byte -NoNewline
    Write-Host "  [$device] Screenshot: $filename" -ForegroundColor Green
}

function Wait-For {
    param($seconds)
    Start-Sleep -Seconds $seconds
}

function Tap-Coordinates {
    param($device, $x, $y)
    adb -s $device shell input tap $x $y
    Wait-For -seconds 1
    Write-Host "  [$device] Tapped: ($x, $y)" -ForegroundColor Gray
}

function Send-Key {
    param($device, $keycode)
    adb -s $device shell input keyevent $keycode
    Wait-For -seconds 0.5
}

function Get-UI-XML {
    param($device)
    $xmlFile = "screenshots\temp_ui_${device}.xml"
    adb -s $device shell uiautomator dump /sdcard/window_dump.xml 2>&1 | Out-Null
    adb -s $device pull /sdcard/window_dump.xml $xmlFile 2>&1 | Out-Null
    if (Test-Path $xmlFile) {
        return Get-Content $xmlFile -Raw
    }
    return $null
}

function Find-Element-ByText {
    param($xml, $searchText)
    if (-not $xml) { return $null }
    
    # Simple regex to find element with text
    $pattern = '<node[^>]*text="([^"]*)"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"'
    $matches = [regex]::Matches($xml, $pattern)
    
    foreach ($match in $matches) {
        $text = $match.Groups[1].Value
        if ($text -like "*$searchText*") {
            $x1 = [int]$match.Groups[2].Value
            $y1 = [int]$match.Groups[3].Value
            $x2 = [int]$match.Groups[4].Value
            $y2 = [int]$match.Groups[5].Value
            $centerX = [math]::Floor(($x1 + $x2) / 2)
            $centerY = [math]::Floor(($y1 + $y2) / 2)
            return @{ X = $centerX; Y = $centerY; Text = $text }
        }
    }
    return $null
}

# Step 1: Launch apps
Write-Host "Step 1: Launching apps..." -ForegroundColor Yellow
adb -s $emulator1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Wait-For -seconds 3
adb -s $emulator2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
Wait-For -seconds 3
Capture-Screenshot -device $emulator1 -filename "01_em1_launched.png"
Capture-Screenshot -device $emulator2 -filename "01_em2_launched.png"

Write-Host "`nStep 2: Setting up shared ride..." -ForegroundColor Yellow
Write-Host "Please login and create/join a shared ride manually, then press Enter to continue..." -ForegroundColor Cyan
Read-Host

Capture-Screenshot -device $emulator1 -filename "02_em1_ride_setup.png"
Capture-Screenshot -device $emulator2 -filename "02_em2_ride_setup.png"

# Step 3: Find and click Chat button
Write-Host "`nStep 3: Finding and clicking Chat button..." -ForegroundColor Yellow

$xml1 = Get-UI-XML -device $emulator1
$chatButton1 = Find-Element-ByText -xml $xml1 -searchText "Chat"
if ($chatButton1) {
    Write-Host "  Found Chat button on emulator 1 at ($($chatButton1.X), $($chatButton1.Y))" -ForegroundColor Green
    Tap-Coordinates -device $emulator1 -x $chatButton1.X -y $chatButton1.Y
    Wait-For -seconds 2
    Capture-Screenshot -device $emulator1 -filename "03_em1_chat_opened.png"
} else {
    Write-Host "  Chat button not found on emulator 1, trying alternative methods..." -ForegroundColor Yellow
    # Try alternative: look for "Chat with Partner" or message icon
    $chatAlt1 = Find-Element-ByText -xml $xml1 -searchText "Partner"
    if ($chatAlt1) {
        Tap-Coordinates -device $emulator1 -x $chatAlt1.X -y $chatAlt1.Y
        Wait-For -seconds 2
        Capture-Screenshot -device $emulator1 -filename "03_em1_chat_opened_alt.png"
    } else {
        Write-Host "  Could not find chat button automatically. Please click it manually." -ForegroundColor Red
        Write-Host "  Waiting 10 seconds for manual click..." -ForegroundColor Yellow
        Wait-For -seconds 10
        Capture-Screenshot -device $emulator1 -filename "03_em1_chat_manual.png"
    }
}

# Step 4: Send messages
Write-Host "`nStep 4: Attempting to send test messages..." -ForegroundColor Yellow

$xmlChat = Get-UI-XML -device $emulator1
if ($xmlChat -and ($xmlChat -like "*message*" -or $xmlChat -like "*send*")) {
    Write-Host "  Chat screen detected, attempting to send message..." -ForegroundColor Green
    
    # Find message input field (usually near bottom)
    # Try tapping in the bottom area where text input typically is
    $screenInfo = adb -s $emulator1 shell wm size
    if ($screenInfo -match '(\d+)x(\d+)') {
        $width = [int]$matches[1]
        $height = [int]$matches[2]
        $inputY = [math]::Floor($height * 0.9)  # Bottom 10% area
        $inputX = [math]::Floor($width / 2)
        
        Tap-Coordinates -device $emulator1 -x $inputX -y $inputY
        Wait-For -seconds 1
        
        # Type message
        $message1 = "Hello from Emulator 1! Test message at $(Get-Date -Format 'HH:mm:ss')"
        Write-Host "  Sending message on emulator 1..." -ForegroundColor Gray
        adb -s $emulator1 shell input text "Hello%20from%20Emulator%201"
        Wait-For -seconds 1
        Send-Key -device $emulator1 -keycode "KEYCODE_ENTER"
        Wait-For -seconds 2
        Capture-Screenshot -device $emulator1 -filename "04_em1_message_sent.png"
        Capture-Screenshot -device $emulator2 -filename "04_em2_message_received.png"
    }
}

# Step 5: Monitor chat conversation
Write-Host "`nStep 5: Monitoring chat conversation..." -ForegroundColor Yellow
Write-Host "Capturing screenshots every 3 seconds for 30 seconds..." -ForegroundColor Cyan

for ($i = 1; $i -le 10; $i++) {
    Wait-For -seconds 3
    $timestamp = Get-Date -Format "HHmmss"
    Capture-Screenshot -device $emulator1 -filename "chat_${i}_${timestamp}_em1.png"
    Capture-Screenshot -device $emulator2 -filename "chat_${i}_${timestamp}_em2.png"
    if ($i % 3 -eq 0) {
        Write-Host "  Captured $i monitoring screenshots..." -ForegroundColor Gray
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Total screenshots captured. Check 'screenshots' folder." -ForegroundColor Green
Write-Host "Latest screenshots:" -ForegroundColor Yellow
Get-ChildItem screenshots\*.png | Sort-Object LastWriteTime -Descending | Select-Object -First 10 Name | Format-Table -HideTableHeaders



