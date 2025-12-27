<?php
/**
 * Script to check for created shared rides in the database
 * Run via: ssh root@192.168.1.3 "cd /path/to/project && php check_rides.php"
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Ride;
use App\Constants\Status;

echo "=== Checking for Shared Rides ===\n\n";

// Find all shared rides
$sharedRides = Ride::where('ride_type', Status::SHARED_RIDE)
    ->orderBy('created_at', 'desc')
    ->limit(10)
    ->get();

echo "Total Shared Rides found: " . $sharedRides->count() . "\n\n";

foreach ($sharedRides as $ride) {
    echo "Ride ID: {$ride->id}\n";
    echo "  User ID: {$ride->user_id}\n";
    echo "  Status: {$ride->status} (RIDE_ACTIVE=" . Status::RIDE_ACTIVE . ")\n";
    echo "  Ride Type: {$ride->ride_type} (SHARED_RIDE=" . Status::SHARED_RIDE . ")\n";
    echo "  Second User ID: " . ($ride->second_user_id ?? 'NULL') . "\n";
    echo "  Pickup: ({$ride->pickup_latitude}, {$ride->pickup_longitude})\n";
    echo "  Destination: ({$ride->destination_latitude}, {$ride->destination_longitude})\n";
    echo "  Created: {$ride->created_at}\n";
    echo "  ---\n";
}

echo "\n=== Active Shared Rides (available for matching) ===\n";
$activeSharedRides = Ride::where('ride_type', Status::SHARED_RIDE)
    ->where('status', Status::RIDE_ACTIVE)
    ->whereNull('second_user_id')
    ->get();

echo "Count: " . $activeSharedRides->count() . "\n\n";
foreach ($activeSharedRides as $ride) {
    echo "Ride ID: {$ride->id}, User ID: {$ride->user_id}\n";
    echo "  Pickup: ({$ride->pickup_latitude}, {$ride->pickup_longitude})\n";
    echo "  Destination: ({$ride->destination_latitude}, {$ride->destination_longitude})\n";
    echo "  ---\n";
}

// Test matching logic with coordinates from emulators
echo "\n=== Testing Matching Logic ===\n";
echo "Emulator 1 (User 1): Pickup (30.0444, 31.2357) -> Dest (30.0131, 31.2089)\n";
echo "Emulator 2 (User 2): Pickup (30.0450, 31.2360) -> Dest (30.0140, 31.2095)\n\n";

$radius = 5.0; // km

function getHaversineDistance($lat1, $lon1, $lat2, $lon2) {
    $earthRadius = 6371; // km
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat/2) * sin($dLat/2) +
         cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
         sin($dLon/2) * sin($dLon/2);
    $c = 2 * atan2(sqrt($a), sqrt(1-$a));
    return $earthRadius * $c;
}

// Test distances
$startDist = getHaversineDistance(30.0444, 31.2357, 30.0450, 31.2360);
$endDist = getHaversineDistance(30.0131, 31.2089, 30.0140, 31.2095);

echo "Distance between pickup points: " . number_format($startDist, 4) . " km\n";
echo "Distance between destination points: " . number_format($endDist, 4) . " km\n";
echo "Should match (radius $radius km): " . (($startDist <= $radius && $endDist <= $radius) ? "YES" : "NO") . "\n\n";

// Check if there are rides that should match
echo "=== Checking if rides match the criteria ===\n";
if ($activeSharedRides->count() > 0) {
    foreach ($activeSharedRides as $ride) {
        $testStartDist = getHaversineDistance(30.0444, 31.2357, $ride->pickup_latitude, $ride->pickup_longitude);
        $testEndDist = getHaversineDistance(30.0131, 31.2089, $ride->destination_latitude, $ride->destination_longitude);
        echo "Ride ID {$ride->id}: Start dist = " . number_format($testStartDist, 4) . " km, End dist = " . number_format($testEndDist, 4) . " km\n";
        echo "  Matches criteria: " . (($testStartDist <= $radius && $testEndDist <= $radius) ? "YES" : "NO") . "\n";
    }
}

