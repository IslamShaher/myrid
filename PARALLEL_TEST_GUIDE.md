# Parallel Shared Ride Testing Guide

## Overview

Comprehensive parallel testing system that monitors database, Laravel logs, Flutter logs, and captures screenshots while testing shared ride functionality between two emulators.

## Current Status

- **Emulator 1**: emulator-5556 (running)
- **Emulator 2**: Need to start second emulator
- **Test Users**: emulator1@test.com, emulator2@test.com
- **API**: Working (tested successfully)

## Quick Start

### Step 1: Start Second Emulator

```powershell
# Option A: Use helper script
.\start_second_emulator.ps1

# Option B: Manual
emulator -list-avds
emulator -avd <avd_name> &
```

### Step 2: Verify Both Emulators Running

```powershell
adb devices
```

Should show:
```
emulator-5556    device
emulator-5554    device  (or similar)
```

### Step 3: Run Comprehensive Test

```powershell
.\run_full_test.ps1
```

## What the Test Does

### Parallel Monitoring (All Running Simultaneously)

1. **Database Monitor**
   - Monitors shared ride creation in real-time
   - Tracks active rides and matched rides
   - Logs to: `test_*/logs/database_monitor.log`

2. **Laravel Log Monitor**
   - Tails Laravel application logs
   - Captures API errors, exceptions
   - Logs to: `test_*/logs/laravel_monitor.log`

3. **Flutter Log Monitors** (One per emulator)
   - Captures Flutter debug output
   - Shows app errors, warnings
   - Logs to: `test_*/logs/flutter_em1.log`, `flutter_em2.log`

4. **Screenshot Monitor**
   - Captures screenshots every 3 seconds
   - From both emulators simultaneously
   - Saves to: `test_*/screenshots/`

5. **API Test Execution**
   - Creates shared ride for user 1
   - Searches for match with user 2
   - Joins ride
   - Logs to: `test_*/logs/api_test.log`

## Test Flow

```
Time 0s:  Start all monitors
Time 3s:  Run API test
  ├─ User 1: Login → Create Shared Ride
  ├─ User 2: Login → Search for Match
  └─ User 2: Join Ride
Time 33s: Final database check
Time 36s: Stop monitors, generate report
```

## Output Structure

```
test_20251226_143022/
├── screenshots/
│   ├── emulator-5556_20251226_143022_1.png
│   ├── emulator-5556_20251226_143022_2.png
│   ├── emulator-5554_20251226_143022_1.png
│   └── emulator-5554_20251226_143022_2.png
├── logs/
│   ├── database_monitor.log      # Real-time DB changes
│   ├── laravel_monitor.log       # API/Server logs
│   ├── flutter_em1.log          # Emulator 1 app logs
│   ├── flutter_em2.log          # Emulator 2 app logs
│   ├── api_test.log             # Test execution output
│   └── final_check.log          # Final database state
└── test_config.json             # Test configuration
```

## Monitoring Features

### Database Monitor
- Real-time ride count updates
- New ride detection
- Match status tracking
- Updates every 2 seconds

### Log Monitors
- Continuous tailing
- Timestamped entries
- Error filtering (Flutter)
- Updates every 1-2 seconds

### Screenshot Monitor
- Parallel capture from both emulators
- Timestamped filenames
- Every 3 seconds
- PNG format

## Analyzing Results

### 1. Check Database Progress
```powershell
Get-Content test_*\logs\database_monitor.log -Tail 20
```

Look for:
- Active ride count changes
- New ride IDs
- Second user assignment

### 2. Review API Test Output
```powershell
Get-Content test_*\logs\api_test.log
```

Should show:
- ✅ User 1 logged in
- ✅ Shared ride created
- ✅ User 2 found match
- ✅ Ride joined successfully

### 3. Check for Errors
```powershell
# Laravel errors
Select-String -Path test_*\logs\laravel_monitor.log -Pattern "ERROR|Exception"

# Flutter errors
Select-String -Path test_*\logs\flutter*.log -Pattern "Error|Exception"
```

### 4. View Screenshots
Open `test_*/screenshots/` folder and review UI states at different times.

## Troubleshooting

### Only 1 Emulator Detected
```powershell
# Start second emulator
.\start_second_emulator.ps1

# Or manually
emulator -list-avds
emulator -avd <name> &
```

### Monitors Not Starting
- Check if PHP is available: `php -v`
- Verify ADB path is correct
- Ensure Laravel logs directory exists

### No Screenshots
- Check emulator is fully booted
- Verify ADB can connect: `adb devices`
- Try manual screenshot: `adb -s emulator-5556 exec-out screencap -p > test.png`

### Database Monitor Not Working
- Verify database connection in `.env`
- Check `monitor_database.php` exists
- Ensure PHP can access Laravel bootstrap

## Configuration

### Test Users
- Emulator 1: `emulator1@test.com` / `password123`
- Emulator 2: `emulator2@test.com` / `password123`

### Test Coordinates
- Emulator 1: (30.0444, 31.2357) → (30.0131, 31.2089)
- Emulator 2: (30.0450, 31.2360) → (30.0140, 31.2095)
- Distance: 0.07km pickup, 0.12km dest (well within 5km radius)

### API Endpoints
- Base URL: `http://192.168.1.13:8000/api`
- Dev Token: `ovoride-dev-123`
- Endpoints: `/shuttle/create-shared-ride`, `/shuttle/match-shared-ride`, `/shuttle/join-ride`

## Next Steps

1. Start second emulator
2. Run: `.\run_full_test.ps1`
3. Review results in output directory
4. Analyze logs for any issues
5. Check screenshots for UI state verification


