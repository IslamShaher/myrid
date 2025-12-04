# Shuttle Rides Matching Test Cases

## Overview
This document details the verification of the Shuttle Matching logic, specifically testing the distance threshold (1km radius) for finding stops.

## Test Scenarios

### Test Case 1: User within 0.5km of Stops
**Objective:** Verify matching works when user is ~500m away from the stop.
**Result:** **✅ PASS**
- **Status:** 200
- **Message:** Match found successfully
- **Matched Route:** "Dokki → Sheraton Heliopolis"
- **Start Stop:** Rose Hotel
- **End Stop:** Anglo American Hospital
- **Analysis:** Successfully matched when user is 500m away from reference stops. The system correctly finds nearby stops within the 1km radius and matches them to valid routes.

### Test Case 2: User 1.5km away from Stops
**Objective:** Verify matching fails when user is > 1km away.
**Result:** **✅ PASS (Expected)**
- **Status:** 404
- **Message:** "No stops found near your location or destination."
- **Analysis:** This correctly indicates that no stops were found within the 1000m radius, as expected.

## Bug Fix Applied
**Issue:** The matching logic was failing even when valid stop pairs were found.
**Root Cause:** `floatval('inf')` was being evaluated as `0` instead of infinity, causing the distance comparison `$totalDist < $minDistance` to fail.
**Solution:** Changed `$minDistance = floatval('inf')` to `$minDistance = PHP_FLOAT_MAX` to properly initialize the minimum distance variable.
**Additional Fix:** Added check to prevent same-stop comparison (`$sStop->id == $eStop->id`) when a stop appears in both start and end lists.

## Test Script
The following PHP script can be run to verify the matching logic:
```php
<?php

require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Http\Request;
use App\Http\Controllers\Api\ShuttleController;
use App\Services\GoogleMapsService;

// Setup
$controller = new ShuttleController(new GoogleMapsService());

// Reference Stops
// Start: Rose Hotel (Stop 6)
$refStartLat = 30.0388148;
$refStartLng = 31.2103418;

// End: Cairo Tower (Stop 9)
$refEndLat = 30.0465220;
$refEndLng = 31.2242989;

// Helper to calculate offset point
function getOffsetPoint($lat, $lng, $offsetMeters) {
    // Roughly: 1 degree lat = 111,000 meters
    // Roughly: 1 degree lng = 111,000 * cos(lat) meters
    // Moving West (Negative Lng) to avoid hitting other stops
    $latOffset = 0;
    $lngOffset = -($offsetMeters / (111000 * cos(deg2rad($lat))));
    return [$lat, $lng + $lngOffset];
}

// Test Function
function runTest($name, $distMeters) {
    global $controller, $refStartLat, $refStartLng, $refEndLat, $refEndLng;
    
    echo "\n=== TEST: $name ($distMeters meters away) ===\n";
    
    list($sLat, $sLng) = getOffsetPoint($refStartLat, $refStartLng, $distMeters);
    list($eLat, $eLng) = getOffsetPoint($refEndLat, $refEndLng, $distMeters);
    
    echo "Start Point: $sLat, $sLng\n";
    echo "End Point:   $eLat, $eLng\n";
    
    $request = Request::create('/api/shuttle/match-route', 'POST', [
        'start_lat' => $sLat,
        'start_lng' => $sLng,
        'end_lat'   => $eLat,
        'end_lng'   => $eLng
    ]);
    
    $response = $controller->matchRoute($request);
    $status = $response->getStatusCode();
    $data = $response->getData(true);
    
    echo "Status: $status\n";
    if ($status == 200) {
        echo "Result: MATCH FOUND\n";
        foreach ($data['matches'] as $match) {
            echo " - Route: " . $match['route']['name'] . "\n";
            echo " - Start Stop: " . $match['start_stop']['name'] . " (Dist: " . round($match['start_stop']['distance']) . "m)\n";
            echo " - End Stop:   " . $match['end_stop']['name'] . " (Dist: " . round($match['end_stop']['distance']) . "m)\n";
        }
    } else {
        echo "Result: NO MATCH (" . ($data['message'] ?? 'Unknown error') . ")\n";
    }
}

// Run Tests
runTest("0.5km Distance", 500);
runTest("1.5km Distance", 1500);
```

**Usage:**
```bash
php test_shuttle_distances.php
```

**Expected Output:**
```
=== TEST: 0.5km Distance (500 meters away) ===
Status: 200
Result: ✅ MATCH FOUND
Route: Dokki → Sheraton Heliopolis
Start: Rose Hotel
End: Anglo American Hospital

=== TEST: 1.5km Distance (1500 meters away) ===
Status: 404
Result: ❌ NO MATCH (No stops found near your location or destination.)
```

