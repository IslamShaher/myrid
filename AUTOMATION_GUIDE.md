# Automated Shared Ride Testing Guide

## Overview

This guide explains how to automate testing of shared ride functionality using Android emulators with ADB commands, screenshots, and UI element detection.

## Tools Used

1. **ADB (Android Debug Bridge)**: For device communication
2. **UI Automator**: For UI element detection via XML dumps
3. **PowerShell/Python**: For automation scripting
4. **Parallel Execution**: For simultaneous emulator operations

## Setup

### Prerequisites

1. Android SDK Platform Tools (ADB)
2. At least 2 Android emulators
3. Python 3.x (for Python script)
4. PowerShell (for PowerShell script)

### Start Emulators

```powershell
# List available AVDs
emulator -list-avds

# Start two emulators
emulator -avd Pixel_5_API_33 &
emulator -avd Pixel_6_API_33 &
```

### Verify Emulators

```powershell
adb devices
```

Should show two emulators:
```
List of devices attached
emulator-5554    device
emulator-5556    device
```

## Automation Scripts

### Option 1: PowerShell Script (Windows)

```powershell
.\automate_shared_ride_test.ps1
```

**Features:**
- Parallel execution for both emulators
- Automatic screenshot capture
- XML-based UI element detection
- Timed delays between steps

### Option 2: Python Script (Cross-platform)

```bash
python automate_shared_ride_python.py
```

**Features:**
- Better XML parsing
- More robust element finding
- Cross-platform support
- Thread-based parallel execution

## ADB Commands Reference

### Screenshots

```bash
# Take screenshot
adb -s emulator-5554 shell screencap -p > screenshot.png

# Take screenshot to file
adb -s emulator-5554 shell screencap -p | sed 's/\r$//' > screenshot.png
```

### UI XML Dump

```bash
# Dump UI hierarchy
adb -s emulator-5554 shell uiautomator dump /sdcard/ui.xml

# Pull XML file
adb -s emulator-5554 pull /sdcard/ui.xml

# Parse XML to find elements
# Use XML parsing tools or regex to find text/coordinates
```

### Input Events

```bash
# Tap at coordinates
adb -s emulator-5554 shell input tap 500 600

# Input text
adb -s emulator-5554 shell input text "hello@test.com"

# Send key event
adb -s emulator-5554 shell input keyevent KEYCODE_ENTER

# Swipe
adb -s emulator-5554 shell input swipe 500 1000 500 500 300
```

### App Control

```bash
# Launch app
adb -s emulator-5554 shell monkey -p com.ovoride.rider -c android.intent.category.LAUNCHER 1

# Get app package
adb -s emulator-5554 shell pm list packages | grep ovoride
```

## UI Element Detection Best Practices

### 1. Using UI Automator Viewer

```bash
# Start UI Automator Viewer
uiautomatorviewer
```

This GUI tool helps:
- View current screen hierarchy
- Get exact element coordinates
- Find resource IDs
- Export element properties

### 2. Finding Elements by Text

```python
# In XML dump, search for:
# <node text="Login" bounds="[100,500][400,600]" />
# Extract center coordinates: (250, 550)
```

### 3. Finding Elements by Resource ID

```python
# Search for resource-id attribute
# <node resource-id="com.ovoride.rider:id/login_button" />
```

### 4. Handling Dynamic Content

- Use approximate coordinates with tolerance
- Wait for UI to load (add delays)
- Retry element finding if not found
- Use multiple fallback methods

## Handling Text Input Cursor

### Common Issues

1. **Cursor visibility** can affect screenshot comparisons
2. **Keyboard appearance** changes layout
3. **Text selection** can interfere with input

### Solutions

```python
# Clear field first
adb shell input keyevent KEYCODE_CTRL_LEFT KEYCODE_A

# Or tap and clear
adb shell input tap X Y
adb shell input keyevent KEYCODE_CTRL_LEFT KEYCODE_A

# Hide keyboard after input
adb shell input keyevent KEYCODE_BACK
```

## Parallel Execution Strategy

### PowerShell Approach

```powershell
# Use Start-Job for parallel execution
$job1 = Start-Job -ScriptBlock { adb -s emulator-5554 shell input tap 500 600 }
$job2 = Start-Job -ScriptBlock { adb -s emulator-5556 shell input tap 500 600 }

# Wait for completion
$job1 | Wait-Job
$job2 | Wait-Job
```

### Python Approach

```python
from concurrent.futures import ThreadPoolExecutor

with ThreadPoolExecutor(max_workers=2) as executor:
    executor.submit(action_on_emulator1)
    executor.submit(action_on_emulator2)
```

## Screenshot Management

### Naming Convention

```
{emulator_serial}_{step_description}_{timestamp}.png
```

Example:
- `emulator-5554_01_app_launched.png`
- `emulator-5556_02_after_login.png`
- `emulator-5554_03_shared_ride_created.png`

### Organization

```
emulator_test_screenshots/
  ├── emulator-5554_01_app_launched.png
  ├── emulator-5554_02_after_login.png
  ├── emulator-5556_01_app_launched.png
  └── emulator-5556_02_after_login.png
```

## Testing Flow

1. **Setup Phase** (Parallel)
   - Start emulators
   - Unlock devices
   - Launch app on both

2. **Login Phase** (Parallel)
   - Login user 1 on emulator 1
   - Login user 2 on emulator 2
   - Capture screenshots

3. **Create Ride Phase** (Sequential)
   - Emulator 1: Navigate to shared ride screen
   - Enter pickup/destination coordinates
   - Create shared ride
   - Capture screenshot

4. **Match Search Phase** (Sequential)
   - Emulator 2: Navigate to shared ride screen
   - Enter coordinates
   - Search for matches
   - Capture screenshot

5. **Join Ride Phase** (Sequential)
   - Emulator 2: Select matched ride
   - Join ride
   - Capture final screenshots

## Troubleshooting

### Emulator Not Found

```bash
# Restart ADB server
adb kill-server
adb start-server
adb devices
```

### Element Not Found

1. Increase wait time
2. Check if app is fully loaded
3. Verify coordinates using UI Automator Viewer
4. Use resource-id instead of text if available

### Input Issues

```bash
# Clear input field
adb shell input keyevent KEYCODE_CTRL_LEFT KEYCODE_A

# Use IME for complex text
adb shell ime set com.android.inputmethod.latin/.LatinIME
```

### Screenshot Issues

```bash
# Use alternative method
adb -s emulator-5554 exec-out screencap -p > screenshot.png

# On Windows PowerShell
adb -s emulator-5554 shell screencap -p | Set-Content screenshot.png -Encoding Byte
```

## Advanced: Using Appium (Optional)

For more robust automation, consider Appium:

```python
from appium import webdriver

capabilities = {
    'platformName': 'Android',
    'deviceName': 'emulator-5554',
    'appPackage': 'com.ovoride.rider',
    'appActivity': '.MainActivity'
}

driver = webdriver.Remote('http://localhost:4723/wd/hub', capabilities)
element = driver.find_element_by_id('com.ovoride.rider:id/login_button')
element.click()
```

## Next Steps

1. Customize coordinates based on your UI
2. Add error handling and retries
3. Implement element waiting strategies
4. Add screenshot comparison for validation
5. Integrate with CI/CD pipeline


