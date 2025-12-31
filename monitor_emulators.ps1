# Emulator Monitor - Automated Screenshot and XML Capture
# Monitors emulators and captures screenshots/XML on demand or continuously

param(
    [string[]]$EmulatorSerials = @(),
    [int]$Interval = 2,  # seconds between captures
    [string]$OutputDir = "emulator_monitor_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    [switch]$Continuous = $false,
    [switch]$XMLOnly = $false,
    [switch]$ScreenshotOnly = $false
)

$ErrorActionPreference = "Continue"

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Success { param($msg) Write-Host "[SUCCESS] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    New-Item -ItemType Directory -Path "$OutputDir\screenshots" | Out-Null
    New-Item -ItemType Directory -Path "$OutputDir\xml_dumps" | Out-Null
    New-Item -ItemType Directory -Path "$OutputDir\parsed_xml" | Out-Null
}
Write-Success "Output directory: $OutputDir"

# Get emulator list
function Get-EmulatorList {
    $devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "emulator-" }
    return $devices | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ }
}

# Capture screenshot
function Capture-Screenshot {
    param($serial, $filename)
    $path = Join-Path "$OutputDir\screenshots" "${serial}_${filename}.png"
    $result = adb -s $serial shell screencap -p 2>&1 | Out-File -FilePath $path -Encoding Byte -ErrorAction SilentlyContinue
    
    # Alternative method if above fails
    if (-not (Test-Path $path) -or (Get-Item $path -ErrorAction SilentlyContinue).Length -eq 0) {
        adb -s $serial exec-out screencap -p > $path 2>&1
    }
    
    if (Test-Path $path -and (Get-Item $path).Length -gt 0) {
        Write-Info "Screenshot: $path"
        return $path
    }
    return $null
}

# Capture and parse XML
function Capture-XML {
    param($serial, $filename)
    
    # Dump UI hierarchy
    $xmlPath = "/sdcard/ui_dump_$(Get-Date -Format 'yyyyMMddHHmmss').xml"
    adb -s $serial shell uiautomator dump $xmlPath 2>&1 | Out-Null
    
    # Pull XML file
    $localXml = Join-Path "$OutputDir\xml_dumps" "${serial}_${filename}.xml"
    adb -s $serial pull $xmlPath $localXml 2>&1 | Out-Null
    adb -s $serial shell rm $xmlPath 2>&1 | Out-Null
    
    if (Test-Path $localXml) {
        Write-Info "XML dump: $localXml"
        
        # Parse and create readable version
        $parsedXml = Join-Path "$OutputDir\parsed_xml" "${serial}_${filename}_parsed.txt"
        Parse-XMLToText -xmlPath $localXml -outputPath $parsedXml
        
        return $localXml
    }
    return $null
}

# Parse XML to readable text format
function Parse-XMLToText {
    param($xmlPath, $outputPath)
    
    try {
        [xml]$xml = Get-Content $xmlPath -ErrorAction Stop
        $output = @()
        $output += "=" * 80
        $output += "UI Hierarchy - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $output += "=" * 80
        $output += ""
        
        function Process-Node {
            param($node, $depth = 0)
            $indent = "  " * $depth
            $attrs = @()
            
            if ($node.text) { $attrs += "text='$($node.text)'" }
            if ($node.'resource-id') { $attrs += "id='$($node.'resource-id')'" }
            if ($node.'content-desc') { $attrs += "desc='$($node.'content-desc')'" }
            if ($node.class) { $attrs += "class='$($node.class)'" }
            if ($node.bounds) { 
                $attrs += "bounds='$($node.bounds)'"
                # Extract center coordinates
                if ($node.bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
                    $x1, $y1, $x2, $y2 = [int]$matches[1], [int]$matches[2], [int]$matches[3], [int]$matches[4]
                    $centerX = ($x1 + $x2) / 2
                    $centerY = ($y1 + $y2) / 2
                    $attrs += "center=($centerX, $centerY)"
                }
            }
            if ($node.clickable -eq 'true') { $attrs += "[CLICKABLE]" }
            if ($node.'checkable' -eq 'true') { $attrs += "[CHECKABLE]" }
            
            $line = "$indent<$($node.class)"
            if ($attrs.Count -gt 0) {
                $line += " " + ($attrs -join " ")
            }
            $line += ">"
            
            if ($node.text) {
                $output += $line
                $output += "$indent  Text: $($node.text)"
            } else {
                $output += $line
            }
            
            foreach ($child in $node.ChildNodes) {
                if ($child.NodeType -eq 'Element') {
                    Process-Node -node $child -depth ($depth + 1)
                }
            }
        }
        
        Process-Node -node $xml.hierarchy
        
        $output | Out-File -FilePath $outputPath -Encoding UTF8
        Write-Info "Parsed XML: $outputPath"
        
    } catch {
        Write-Error "Failed to parse XML: $_"
    }
}

# Find elements in XML
function Find-ElementsInXML {
    param($xmlPath, $searchText, $searchId)
    
    try {
        [xml]$xml = Get-Content $xmlPath -ErrorAction Stop
        $results = @()
        
        function Search-Node {
            param($node)
            
            $match = $false
            $info = @{
                text = $node.text
                resourceId = $node.'resource-id'
                bounds = $node.bounds
                clickable = $node.clickable
            }
            
            if ($searchText -and $node.text -like "*$searchText*") {
                $match = $true
            }
            if ($searchId -and $node.'resource-id' -like "*$searchId*") {
                $match = $true
            }
            
            if ($match) {
                if ($node.bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
                    $x1, $y1, $x2, $y2 = [int]$matches[1], [int]$matches[2], [int]$matches[3], [int]$matches[4]
                    $info.centerX = ($x1 + $x2) / 2
                    $info.centerY = ($y1 + $y2) / 2
                }
                $results += $info
            }
            
            foreach ($child in $node.ChildNodes) {
                if ($child.NodeType -eq 'Element') {
                    Search-Node -node $child
                }
            }
        }
        
        Search-Node -node $xml.hierarchy
        return $results
        
    } catch {
        Write-Error "Failed to search XML: $_"
        return @()
    }
}

# Main capture function
function Capture-All {
    param($serials, $suffix = "")
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $filename = if ($suffix) { "${timestamp}_${suffix}" } else { $timestamp }
    
    foreach ($serial in $serials) {
        Write-Info "Capturing from $serial..."
        
        if (-not $XMLOnly) {
            Capture-Screenshot -serial $serial -filename $filename
        }
        
        if (-not $ScreenshotOnly) {
            $xmlPath = Capture-XML -serial $serial -filename $filename
        }
    }
}

# === MAIN SCRIPT ===

Write-Host "=" * 60
Write-Host "Emulator Monitor - Screenshot & XML Capture Tool"
Write-Host "=" * 60
Write-Host ""

# Get emulators
if ($EmulatorSerials.Count -eq 0) {
    Write-Info "Detecting emulators..."
    $EmulatorSerials = Get-EmulatorList
}

if ($EmulatorSerials.Count -eq 0) {
    Write-Error "No emulators found. Start emulators first."
    Write-Info "Check with: adb devices"
    exit 1
}

Write-Success "Monitoring $($EmulatorSerials.Count) emulator(s):"
$EmulatorSerials | ForEach-Object { Write-Info "  - $_" }

Write-Host ""
Write-Info "Press Ctrl+C to stop monitoring"
Write-Host ""

if ($Continuous) {
    Write-Info "Continuous mode: Capturing every $Interval seconds"
    $counter = 0
    
    try {
        while ($true) {
            $counter++
            Write-Host "`n[Capture #$counter] $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
            Capture-All -serials $EmulatorSerials -suffix "auto_$counter"
            Start-Sleep -Seconds $Interval
        }
    } catch {
        Write-Host "`nMonitoring stopped." -ForegroundColor Yellow
    }
} else {
    Write-Info "Single capture mode"
    Write-Info "Press Enter to capture, or type 'q' to quit"
    
    $counter = 0
    while ($true) {
        $input = Read-Host "Capture (Enter) or Quit (q)"
        if ($input -eq 'q') { break }
        
        $counter++
        Write-Host ""
        Capture-All -serials $EmulatorSerials -suffix "manual_$counter"
        Write-Host ""
    }
}

Write-Success "`nMonitoring complete. Files saved in: $OutputDir"




