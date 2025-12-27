# Shared Ride Testing Results

## ✅ Test Status: PASSING

The shared ride matching functionality is working correctly between two emulators.

## Test Results

### Test Scenario
- **Emulator 1**: Created shared ride from (30.0444, 31.2357) to (30.0131, 31.2089)
- **Emulator 2**: Searched for matching rides from (30.0450, 31.2360) to (30.0140, 31.2095)
- **Distance**: 0.0727 km pickup, 0.1156 km destination (well within 5km radius)

### Results
1. ✅ **Ride Creation**: User 1 successfully created shared ride (ID: 33)
2. ✅ **Matching**: User 2 found the matching ride (1 match found)
3. ✅ **Joining**: User 2 successfully joined the ride
4. ✅ **Database**: Ride correctly updated with both users

### Match Details
- **Total Overhead**: 59.30 minutes
- **Rider 1 Fare**: 9.45
- **Rider 2 Fare**: 9.36
- **Ride Status**: Active (Status: 2)

## How to Test with Real Emulators

### Using Flutter Emulators

1. **Start two emulators** (or use physical devices)
2. **Login with different users**:
   - Emulator 1: `emulator1@test.com` / `password123`
   - Emulator 2: `emulator2@test.com` / `password123`

3. **Create Shared Ride on Emulator 1**:
   - Navigate to Shared Ride screen
   - Enter coordinates:
     - Pickup: 30.0444, 31.2357
     - Destination: 30.0131, 31.2089
   - Tap "Create Shared Ride"

4. **Search for Match on Emulator 2**:
   - Navigate to Shared Ride screen
   - Enter coordinates:
     - Pickup: 30.0450, 31.2360
     - Destination: 30.0140, 31.2095
   - Tap "Search for Match"
   - Should see Emulator 1's ride

5. **Join Ride on Emulator 2**:
   - Tap "Join Ride" on the matched ride
   - Both users should see the ride update

### API Endpoints Used

```
POST /api/shuttle/create-shared-ride
POST /api/shuttle/match-shared-ride
POST /api/shuttle/join-ride
GET  /api/shuttle/active-shared-ride
```

### Test Script

Run the automated test:
```bash
php test_shared_ride_emulators.php
```

## Current Configuration

- **Server**: http://192.168.1.13:8000
- **Database**: Remote MySQL (192.168.1.3)
- **Matching Radius**: 5 km
- **Test Users**: 
  - emulator1@test.com / password123
  - emulator2@test.com / password123

## Notes

- The matching algorithm uses Haversine distance calculation
- Rides must be within 5km for both pickup and destination
- Only active rides (status = 2) without a second user are available for matching
- Users cannot match their own rides


