# Smart Automated Shared Ride Testing
# Reads UI, finds elements, and interacts intelligently

param(
    [string]$Device1 = "emulator-5554",
    [string]$Device2 = "emulator-5556"
)

$ErrorActionPreference = "Continue"

Write-Host "=== Smart Automated Shared Ride Testing ===" -ForegroundColor Cyan
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

# Function to dump UI hierarchy and parse XML
function Get-UIHierarchy {
    param([string]$Device)
    
    # Dump UI hierarchy to file
    $dumpFile = "/sdcard/window_dump.xml"
    & $adbPath -s $Device shell uiautomator dump $dumpFile | Out-Null
    Wait-For -Seconds 1
    
    # Pull the file
    $localFile = "$env:TEMP\ui_dump_$Device.xml"
    & $adbPath -s $Device pull $dumpFile $localFile | Out-Null
    
    if (Test-Path $localFile) {
        $xml = [xml](Get-Content $localFile -Raw)
        return $xml
    }
    return $null
}

# Function to find element by text
function Find-ElementByText {
    param(
        [xml]$UIHierarchy,
        [string]$Text,
        [string]$Attribute = "text"
    )
    
    if ($null -eq $UIHierarchy) { return $null }
    
    # Search for elements with matching text
    $nodes = $UIHierarchy.SelectNodes("//node[@$Attribute='$Text']")
    if ($nodes.Count -gt 0) {
        $node = $nodes[0]
        $bounds = $node.bounds
        if ($bounds -match "\[(\d+),(\d+)\]\[(\d+),(\d+)\]") {
            return @{
                X = [int](([int]$matches[1] + [int]$matches[3]) / 2)
                Y = [int](([int]$matches[2] + [int]$matches[4]) / 2)
                Node = $node
            }
        }
    }
    return $null
}

# Function to find element by resource-id
function Find-ElementByResourceId {
    param(
        [xml]$UIHierarchy,
        [string]$ResourceId
    )
    
    if ($null -eq $UIHierarchy) { return $null }
    
    $nodes = $UIHierarchy.SelectNodes("//node[@resource-id='$ResourceId']")
    if ($nodes.Count -gt 0) {
        $node = $nodes[0]
        $bounds = $node.bounds
        if ($bounds -match "\[(\d+),(\d+)\]\[(\d+),(\d+)\]") {
            return @{
                X = [int](([int]$matches[1] + [int]$matches[3]) / 2)
                Y = [int](([int]$matches[2] + [int]$matches[4]) / 2)
                Node = $node
            }
        }
    }
    return $null
}

# Function to find clickable elements containing text
function Find-ClickableByText {
    param(
        [xml]$UIHierarchy,
        [string]$ContainsText
    )
    
    if ($null -eq $UIHierarchy) { return $null }
    
    # Find clickable elements
    $nodes = $UIHierarchy.SelectNodes("//node[@clickable='true']")
    foreach ($node in $nodes) {
        $text = $node.text
        $contentDesc = $node.'content-desc'
        if (($text -and $text -like "*$ContainsText*") -or 
            ($contentDesc -and $contentDesc -like "*$ContainsText*")) {
            $bounds = $node.bounds
            if ($bounds -match "\[(\d+),(\d+)\]\[(\d+),(\d+)\]") {
                return @{
                    X = [int](([int]$matches[1] + [int]$matches[3]) / 2)
                    Y = [int](([int]$matches[2] + [int]$matches[4]) / 2)
                    Node = $node
                    Text = $text
                }
            }
        }
    }
    return $null
}

# Function to tap on coordinates
function Tap-On {
    param(
        [string]$Device,
        [int]$X,
        [int]$Y,
        [string]$Description = ""
    )
    Write-Host "  [TAP] $Description ($X, $Y) on $Device" -ForegroundColor Gray
    & $adbPath -s $Device shell input tap $X $Y | Out-Null
    Wait-For -Seconds 2
}

# Function to input text (clears first)
function Input-Text {
    param(
        [string]$Device,
        [string]$Text,
        [string]$Description = ""
    )
    Write-Host "  [INPUT] $Description '$Text' on $Device" -ForegroundColor Gray
    # Clear any existing text
    & $adbPath -s $Device shell input keyevent KEYCODE_CTRL_A | Out-Null
    Wait-For -Seconds 0.5
    & $adbPath -s $Device shell input keyevent KEYCODE_DEL | Out-Null
    Wait-For -Seconds 0.5
    # Input new text
    $escapedText = $Text -replace ' ', '%s'
    $escapedText = $escapedText -replace ',', '\,' 
    & $adbPath -s $Device shell input text $escapedText | Out-Null
    Wait-For -Seconds 1
}

# Function to press back
function Press-Back {
    param([string]$Device)
    Write-Host "  [BACK] on $Device" -ForegroundColor Gray
    & $adbPath -s $Device shell input keyevent KEYCODE_BACK | Out-Null
    Wait-For -Seconds 1
}

# Function to swipe (for slider)
function Swipe-On {
    param(
        [string]$Device,
        [int]$X1,
        [int]$Y1,
        [int]$X2,
        [int]$Y2,
        [int]$Duration = 500
    )
    Write-Host "  [SWIPE] ($X1,$Y1) -> ($X2,$Y2) on $Device" -ForegroundColor Gray
    & $adbPath -s $Device shell input swipe $X1 $Y1 $X2 $Y2 $Duration | Out-Null
    Wait-For -Seconds 2
}

# Function to check for errors in logs
function Check-ForErrors {
    param([string]$Device)
    
    $errors = & $adbPath -s $Device logcat -d -t 50 | Select-String -Pattern "Exception|Error|FATAL|NoSuchMethod|null check" -Context 2,5
    return $errors
}

# Function to interact with element if found
function Try-TapElement {
    param(
        [string]$Device,
        [xml]$UIHierarchy,
        [string]$SearchText,
        [string]$ElementType = "text"
    )
    
    Write-Host "  Searching for: '$SearchText'..." -ForegroundColor Yellow
    
    if ($ElementType -eq "text") {
        $element = Find-ElementByText -UIHierarchy $UIHierarchy -Text $SearchText
    } else {
        $element = Find-ClickableByText -UIHierarchy $UIHierarchy -ContainsText $SearchText
    }
    
    if ($element) {
        Write-Host "  ✓ Found at ($($element.X), $($element.Y))" -ForegroundColor Green
        Tap-On -Device $Device -X $element.X -Y $element.Y -Description $SearchText
        return $true
    } else {
        Write-Host "  ✗ Not found" -ForegroundColor Red
        return $false
    }
}

# Check devices
Write-Host "Checking devices..." -ForegroundColor Yellow
$devices = & $adbPath devices | Select-String "device$"
if (-not ($devices -match $Device1) -or -not ($devices -match $Device2)) {
    Write-Host "[ERROR] Both devices must be connected!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Both devices connected" -ForegroundColor Green
Write-Host ""

# Open app on both devices
Write-Host "=== Opening apps ===" -ForegroundColor Cyan
$packageName = "com.ovosolution.ovorideuser"
& $adbPath -s $Device1 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null
Wait-For -Seconds 3
& $adbPath -s $Device2 shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Null
Wait-For -Seconds 3
Write-Host "[OK] Apps opened" -ForegroundColor Green
Write-Host ""

# DEVICE 1: Create/Find Shared Ride
Write-Host "=== DEVICE 1: Creating Shared Ride ===" -ForegroundColor Cyan
$ui1 = Get-UIHierarchy -Device $Device1

# Look for "Find / Create Shared Ride" button or similar
if (-not (Try-TapElement -Device $Device1 -UIHierarchy $ui1 -SearchText "Find / Create Shared Ride" -ElementType "clickable")) {
    # Try alternatives
    Try-TapElement -Device $Device1 -UIHierarchy $ui1 -SearchText "Shared Ride" -ElementType "clickable" | Out-Null
    Try-TapElement -Device $Device1 -UIHierarchy $ui1 -SearchText "Create" -ElementType "clickable" | Out-Null
}
Wait-For -Seconds 3

# Now on shared ride screen - get UI again
$ui1 = Get-UIHierarchy -Device $Device1

# Find and fill pickup location
Write-Host "  Filling pickup location..." -ForegroundColor Yellow
$pickupField = Find-ClickableByText -UIHierarchy $ui1 -ContainsText "pickup"
if (-not $pickupField) {
    # Try tapping center top area where pickup usually is
    $screen1 = & $adbPath -s $Device1 shell wm size | Select-String "(\d+)x(\d+)" 
    if ($screen1 -match "(\d+)x(\d+)") {
        $height = [int]$matches[2]
        Tap-On -Device $Device1 -X 540 -Y [int]($height * 0.25) -Description "Pickup field (estimated)"
    }
} else {
    Tap-On -Device $Device1 -X $pickupField.X -Y $pickupField.Y -Description "Pickup field"
}
Wait-For -Seconds 2
Input-Text -Device $Device1 -Text "30.0444,31.2357" -Description "Pickup coordinates"
Wait-For -Seconds 2

# Get UI again after input
$ui1 = Get-UIHierarchy -Device $Device1

# Find and fill destination
Write-Host "  Filling destination..." -ForegroundColor Yellow
$destField = Find-ClickableByText -UIHierarchy $ui1 -ContainsText "destination"
if (-not $destField) {
    $screen1 = & $adbPath -s $Device1 shell wm size | Select-String "(\d+)x(\d+)" 
    if ($screen1 -match "(\d+)x(\d+)") {
        $height = [int]$matches[2]
        Tap-On -Device $Device1 -X 540 -Y [int]($height * 0.35) -Description "Destination field (estimated)"
    }
} else {
    Tap-On -Device $Device1 -X $destField.X -Y $destField.Y -Description "Destination field"
}
Wait-For -Seconds 2
Input-Text -Device $Device1 -Text "30.0131,31.2089" -Description "Destination coordinates"
Wait-For -Seconds 2

# Find search/create button
Write-Host "  Clicking search/create button..." -ForegroundColor Yellow
$ui1 = Get-UIHierarchy -Device $Device1
if (-not (Try-TapElement -Device $Device1 -UIHierarchy $ui1 -SearchText "Search" -ElementType "clickable")) {
    Try-TapElement -Device $Device1 -UIHierarchy $ui1 -SearchText "Find" -ElementType "clickable" | Out-Null
    Try-TapElement -Device $Device1 -UIHierarchy $ui1 -SearchText "Create" -ElementType "clickable" | Out-Null
}
Wait-For -Seconds 5

# Check for errors
$errors1 = Check-ForErrors -Device $Device1
if ($errors1) {
    Write-Host "[ERRORS ON DEVICE 1]:" -ForegroundColor Red
    $errors1 | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

# DEVICE 2: Join Ride
Write-Host ""
Write-Host "=== DEVICE 2: Joining Shared Ride ===" -ForegroundColor Cyan
Wait-For -Seconds 2

$ui2 = Get-UIHierarchy -Device $Device2

# Navigate to shared ride
if (-not (Try-TapElement -Device $Device2 -UIHierarchy $ui2 -SearchText "Find / Create Shared Ride" -ElementType "clickable")) {
    Try-TapElement -Device $Device2 -UIHierarchy $ui2 -SearchText "Shared Ride" -ElementType "clickable" | Out-Null
}
Wait-For -Seconds 3

$ui2 = Get-UIHierarchy -Device $Device2

# Fill pickup
Write-Host "  Filling pickup location..." -ForegroundColor Yellow
$pickupField2 = Find-ClickableByText -UIHierarchy $ui2 -ContainsText "pickup"
if ($pickupField2) {
    Tap-On -Device $Device2 -X $pickupField2.X -Y $pickupField2.Y -Description "Pickup field"
} else {
    $screen2 = & $adbPath -s $Device2 shell wm size | Select-String "(\d+)x(\d+)" 
    if ($screen2 -match "(\d+)x(\d+)") {
        $height = [int]$matches[2]
        Tap-On -Device $Device2 -X 540 -Y [int]($height * 0.25) -Description "Pickup field (estimated)"
    }
}
Wait-For -Seconds 2
Input-Text -Device $Device2 -Text "30.0277,31.2136" -Description "Pickup coordinates"
Wait-For -Seconds 2

# Fill destination
Write-Host "  Filling destination..." -ForegroundColor Yellow
$ui2 = Get-UIHierarchy -Device $Device2
$destField2 = Find-ClickableByText -UIHierarchy $ui2 -ContainsText "destination"
if ($destField2) {
    Tap-On -Device $Device2 -X $destField2.X -Y $destField2.Y -Description "Destination field"
} else {
    $screen2 = & $adbPath -s $Device2 shell wm size | Select-String "(\d+)x(\d+)" 
    if ($screen2 -match "(\d+)x(\d+)") {
        $height = [int]$matches[2]
        Tap-On -Device $Device2 -X 540 -Y [int]($height * 0.35) -Description "Destination field (estimated)"
    }
}
Wait-For -Seconds 2
Input-Text -Device $Device2 -Text "30.0131,31.2089" -Description "Destination coordinates"
Wait-For -Seconds 2

# Search/Join
Write-Host "  Clicking search button..." -ForegroundColor Yellow
$ui2 = Get-UIHierarchy -Device $Device2
Try-TapElement -Device $Device2 -UIHierarchy $ui2 -SearchText "Search" -ElementType "clickable" | Out-Null
Wait-For -Seconds 5

# If match found, try to join
$ui2 = Get-UIHierarchy -Device $Device2
Try-TapElement -Device $Device2 -UIHierarchy $ui2 -SearchText "Join" -ElementType "clickable" | Out-Null
Try-TapElement -Device $Device2 -UIHierarchy $ui2 -SearchText "Confirm" -ElementType "clickable" | Out-Null
Wait-For -Seconds 5

# Check for errors on device 2
$errors2 = Check-ForErrors -Device $Device2
if ($errors2) {
    Write-Host "[ERRORS ON DEVICE 2]:" -ForegroundColor Red
    $errors2 | Select-Object -Last 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
}

# Wait for ride to be active
Write-Host ""
Write-Host "=== Waiting for ride to be active ===" -ForegroundColor Cyan
Wait-For -Seconds 5

# DEVICE 1: Start ride (swipe to start)
Write-Host "=== DEVICE 1: Starting Ride ===" -ForegroundColor Cyan
$ui1 = Get-UIHierarchy -Device $Device1

# Look for swipe-to-start button or slider
$startButton = Find-ClickableByText -UIHierarchy $ui1 -ContainsText "Start"
if ($startButton) {
    Tap-On -Device $Device1 -X $startButton.X -Y $startButton.Y -Description "Start button"
} else {
    # Try swiping (Uber-style slider)
    $screen1 = & $adbPath -s $Device1 shell wm size | Select-String "(\d+)x(\d+)" 
    if ($screen1 -match "(\d+)x(\d+)") {
        $width = [int]$matches[1]
        $height = [int]$matches[2]
        Swipe-On -Device $Device1 -X1 [int]($width * 0.2) -Y1 [int]($height * 0.9) -X2 [int]($width * 0.8) -Y2 [int]($height * 0.9)
    }
}
Wait-For -Seconds 5

# Final error check
Write-Host ""
Write-Host "=== Final Error Check ===" -ForegroundColor Cyan
$finalErrors1 = Check-ForErrors -Device $Device1
$finalErrors2 = Check-ForErrors -Device $Device2

$hasErrors = $false
if ($finalErrors1) {
    Write-Host "[FINAL ERRORS ON DEVICE 1]:" -ForegroundColor Red
    $finalErrors1 | Select-Object -Last 10 | ForEach-Object { 
        Write-Host "  $_" -ForegroundColor Yellow 
        $hasErrors = $true
    }
}

if ($finalErrors2) {
    Write-Host "[FINAL ERRORS ON DEVICE 2]:" -ForegroundColor Red
    $finalErrors2 | Select-Object -Last 10 | ForEach-Object { 
        Write-Host "  $_" -ForegroundColor Yellow 
        $hasErrors = $true
    }
}

if (-not $hasErrors) {
    Write-Host "[OK] No errors found in final check" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan

