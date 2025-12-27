# Quick Capture Tool - Fast screenshot and XML capture
# Usage: .\quick_capture.ps1 [emulator_serial]

param(
    [string]$Serial = "",
    [string]$Label = ""
)

$ErrorActionPreference = "Continue"

# Get emulator if not specified
if (-not $Serial) {
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" }
    if ($devices) {
        $Serial = ($devices[0] -split '\s+')[0]
    } else {
        Write-Host "[ERROR] No emulator found" -ForegroundColor Red
        exit 1
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$filename = if ($Label) { "${timestamp}_${Label}" } else { $timestamp }

Write-Host "Capturing from $Serial..." -ForegroundColor Cyan

# Screenshot
$screenshotPath = "screenshot_${Serial}_${filename}.png"
adb -s $Serial exec-out screencap -p > $screenshotPath 2>&1
if (Test-Path $screenshotPath -and (Get-Item $screenshotPath).Length -gt 0) {
    Write-Host "[SUCCESS] Screenshot: $screenshotPath" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Screenshot failed" -ForegroundColor Red
}

# XML
$xmlRemote = "/sdcard/ui_${timestamp}.xml"
$xmlLocal = "ui_${Serial}_${filename}.xml"
adb -s $Serial shell uiautomator dump $xmlRemote 2>&1 | Out-Null
adb -s $Serial pull $xmlRemote $xmlLocal 2>&1 | Out-Null
adb -s $Serial shell rm $xmlRemote 2>&1 | Out-Null

if (Test-Path $xmlLocal) {
    Write-Host "[SUCCESS] XML: $xmlLocal" -ForegroundColor Green
    
    # Quick parse - show clickable elements
    [xml]$xml = Get-Content $xmlLocal -ErrorAction SilentlyContinue
    if ($xml) {
        $clickable = $xml.SelectNodes("//node[@clickable='true']")
        if ($clickable.Count -gt 0) {
            Write-Host "`nClickable elements found:" -ForegroundColor Yellow
            foreach ($node in $clickable) {
                $text = $node.text
                $bounds = $node.bounds
                if ($bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
                    $x = ([int]$matches[1] + [int]$matches[3]) / 2
                    $y = ([int]$matches[2] + [int]$matches[4]) / 2
                    Write-Host "  '$text' -> tap $x $y" -ForegroundColor White
                }
            }
        }
    }
} else {
    Write-Host "[ERROR] XML capture failed" -ForegroundColor Red
}


