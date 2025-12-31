# Emulator Monitoring Guide

## Overview

Tools for automated screenshot and XML capture from Android emulators. **NO action automation** - just monitoring and analysis.

## Tools

### 1. Quick Capture (PowerShell)
Fast single capture of screenshot + XML

```powershell
# Capture from first available emulator
.\quick_capture.ps1

# Capture from specific emulator with label
.\quick_capture.ps1 -Serial emulator-5554 -Label "after_login"
```

**Output:**
- `screenshot_emulator-5554_20251226_143022.png`
- `ui_emulator-5554_20251226_143022.xml`
- Shows clickable elements with tap coordinates

### 2. Monitor Tool (PowerShell)
Continuous or manual monitoring

```powershell
# Manual capture mode (press Enter to capture)
.\monitor_emulators.ps1

# Continuous mode (captures every 2 seconds)
.\monitor_emulators.ps1 -Continuous -Interval 2

# XML only
.\monitor_emulators.ps1 -XMLOnly

# Screenshot only
.\monitor_emulators.ps1 -ScreenshotOnly

# Specific emulators
.\monitor_emulators.ps1 -EmulatorSerials emulator-5554,emulator-5556
```

**Output Structure:**
```
emulator_monitor_20251226_143022/
  ├── screenshots/
  │   ├── emulator-5554_20251226_143022_manual_1.png
  │   └── emulator-5556_20251226_143022_manual_1.png
  ├── xml_dumps/
  │   ├── emulator-5554_20251226_143022_manual_1.xml
  │   └── emulator-5556_20251226_143022_manual_1.xml
  └── parsed_xml/
      ├── emulator-5554_20251226_143022_manual_1_parsed.txt
      └── emulator-5556_20251226_143022_manual_1_parsed.txt
```

### 3. Monitor Tool (Python)
Cross-platform version with better XML parsing

```bash
# Manual capture
python monitor_emulators.py

# Continuous mode
python monitor_emulators.py -c -i 3

# XML only
python monitor_emulators.py --xml-only

# Specific emulators
python monitor_emulators.py -s emulator-5554 emulator-5556
```

## Usage Workflow

### Step 1: Start Emulators
```powershell
# List available AVDs
emulator -list-avds

# Start emulators
emulator -avd Pixel_5_API_33 &
emulator -avd Pixel_6_API_33 &

# Verify
adb devices
```

### Step 2: Launch Monitoring
```powershell
# Start monitoring in background or separate terminal
.\monitor_emulators.ps1 -Continuous -Interval 3
```

### Step 3: Manual Testing
- Interact with emulators manually
- Monitoring tool captures screenshots/XML automatically
- Or use quick capture for specific moments

### Step 4: Analyze Results
- Review screenshots in `screenshots/` folder
- Check parsed XML in `parsed_xml/` folder
- Find element coordinates for future automation

## XML Analysis

### Parsed XML Format

The parsed XML shows:
- Element hierarchy with indentation
- Text content
- Resource IDs
- Bounds (coordinates)
- Center coordinates for tapping
- Clickable/checkable flags

Example:
```
<android.widget.Button text='Login' bounds='[100,500][400,600]' center=(250, 550) [CLICKABLE]>
  Text: Login
```

### Finding Elements

**By Text:**
```powershell
# In parsed XML, search for:
Select-String -Path "parsed_xml\*.txt" -Pattern "Login"
```

**By Resource ID:**
```powershell
Select-String -Path "parsed_xml\*.txt" -Pattern "login_button"
```

**By Coordinates:**
The parsed XML shows center coordinates for each element:
```
center=(250, 550)
```

## Screenshot Management

### Naming Convention
- `{serial}_{timestamp}_{label}.png`
- Timestamp format: `yyyyMMdd_HHmmss`

### Organization
- Screenshots organized by emulator serial
- Timestamped for chronological order
- Labels for specific test steps

## Best Practices

### 1. Label Your Captures
```powershell
.\quick_capture.ps1 -Label "after_login"
.\quick_capture.ps1 -Label "shared_ride_screen"
```

### 2. Use Continuous Mode for Flows
```powershell
# Start monitoring before testing
.\monitor_emulators.ps1 -Continuous -Interval 2

# Then perform your manual testing
# All screenshots/XML captured automatically
```

### 3. Review Parsed XML
The parsed XML files are easier to read than raw XML:
- Human-readable format
- Shows element relationships
- Includes tap coordinates

### 4. Compare Screenshots
Use screenshot comparison to verify UI changes:
```powershell
# Compare two screenshots
Compare-Object (Get-Item screenshot1.png) (Get-Item screenshot2.png)
```

## Troubleshooting

### No Screenshots Captured
```powershell
# Try alternative method
adb -s emulator-5554 exec-out screencap -p > test.png

# Check file size
(Get-Item test.png).Length
```

### XML Dump Fails
```powershell
# Check if UI Automator is available
adb -s emulator-5554 shell uiautomator --help

# Try alternative
adb -s emulator-5554 shell dumpsys window | Select-String "mCurrentFocus"
```

### Multiple Emulators
```powershell
# List all
adb devices

# Capture from specific one
.\quick_capture.ps1 -Serial emulator-5554
```

## Integration with Testing

### During Manual Testing
1. Start monitoring: `.\monitor_emulators.ps1 -Continuous`
2. Perform manual actions on emulators
3. Review captured screenshots/XML
4. Extract coordinates for automation scripts

### For Documentation
1. Capture at key steps with labels
2. Use screenshots in documentation
3. Reference XML for element locations

### For Debugging
1. Capture when issue occurs
2. Review XML to see UI state
3. Check element visibility/clickability
4. Verify coordinates are correct

## Advanced: XML Element Search

Create a search script:
```powershell
# search_xml.ps1
param($xmlPath, $searchText)

[xml]$xml = Get-Content $xmlPath
$nodes = $xml.SelectNodes("//node[@text='$searchText']")
foreach ($node in $nodes) {
    $bounds = $node.bounds
    if ($bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
        $x = ([int]$matches[1] + [int]$matches[3]) / 2
        $y = ([int]$matches[2] + [int]$matches[4]) / 2
        Write-Host "$searchText -> tap $x $y"
    }
}
```

Usage:
```powershell
.\search_xml.ps1 -xmlPath "ui_emulator-5554_*.xml" -searchText "Login"
```




