<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Driver;
use App\Models\ShuttleRoute;
use Illuminate\Support\Facades\Auth;

// --- CONFIGURATION ---
$apiUrl = 'http://127.0.0.1:8000/api'; 

// --- HELPER FUNCTIONS ---

function apiRequest($method, $endpoint, $token = null, $data = [], $isDriver = false) {
    global $apiUrl;
    
    $url = $apiUrl . $endpoint;
    $ch = curl_init($url);
    
    $headers = [
        'Accept: application/json',
        'Content-Type: application/json',
        'dev-token: ovoride-dev-123',
        'User-Agent: SimulationScript'
    ];
    
    if ($token) {
        $headers[] = "Authorization: Bearer $token";
    }
    
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    
    if ($method === 'POST') {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return ['code' => $httpCode, 'body' => json_decode($response, true)];
}

function printStep($message) {
    echo "\n\033[1;32m[STEP] $message\033[0m\n";
}

function printError($message) {
    echo "\n\033[1;31m[ERROR] $message\033[0m\n";
    exit(1);
}

// --- SIMULATION START ---

printStep("Initializing Simulation...");

// 1. DATA SETUP
$route = ShuttleRoute::with('stops')->first();
if (!$route || $route->stops->count() < 2) printError("No valid shuttle route found.");

$startStop = $route->stops[0];
$endStop = $route->stops[1];

echo "Route: {$route->name} (ID: {$route->id})\n";
echo "Pickup: {$startStop->name} (ID: {$startStop->id}) Lat: {$startStop->latitude}\n";
echo "Dropoff: {$endStop->name} (ID: {$endStop->id}) Lat: {$endStop->latitude}\n";

// 2. RIDER LOGIN
printStep("Rider Login...");
$user = User::firstOrCreate(
    ['email' => 'rider@simulation.com'],
    ['username' => 'rider_sim', 'password' => bcrypt('password'), 'country_code' => '1', 'mobile' => '1234567890']
);
$riderLogin = apiRequest('POST', '/login', null, ['username' => 'rider_sim', 'password' => 'password']);
if ($riderLogin['code'] != 200) printError("Rider login failed.");
$riderToken = $riderLogin['body']['data']['access_token'];
echo "Rider Token: " . substr($riderToken, 0, 20) . "...\n";

// 3. DRIVER LOGIN
printStep("Driver Login...");
$driver = \App\Models\Driver::firstOrCreate(
    ['email' => 'driver@simulation.com'],
    ['username' => 'driver_sim', 'password' => bcrypt('password'), 'country_code' => '1', 'mobile' => '0987654321', 'service_id' => 1, 'zone_id' => 1]
);
$driverLogin = apiRequest('POST', '/driver/login', null, ['username' => 'driver_sim', 'password' => 'password']);
if ($driverLogin['code'] != 200) printError("Driver login failed.");
$driverToken = $driverLogin['body']['data']['access_token'];
echo "Driver Token: " . substr($driverToken, 0, 20) . "...\n";


// 4. RIDER SEARCH & BOOK
printStep("Rider Searching Route...");
$match = apiRequest('POST', '/shuttle/match-route', $riderToken, [
    'start_lat' => $startStop->latitude,
    'start_lng' => $startStop->longitude,
    'end_lat' => $endStop->latitude,
    'end_lng' => $endStop->longitude
]);

if ($match['code'] != 200) {
    print_r($match['body']); // Debug output
    printError("No matching route found.");
}
$foundRoute = $match['body']['matches'][0];
echo "Found Route: {$foundRoute['route']['name']}\n";

printStep("Rider Booking Ride...");
$book = apiRequest('POST', '/shuttle/create', $riderToken, [
    'route_id' => $route->id,
    'start_stop_id' => $startStop->id,
    'end_stop_id' => $endStop->id,
    'number_of_passenger' => 1
]);

if ($book['code'] != 200) {
    print_r($book['body']);
    printError("Booking failed.");
}
$rideData = $book['body']['data']['ride'];
$rideId = $rideData['id'];
echo "Ride Created! ID: $rideId, UID: {$rideData['uid']}\n";


// 5. DRIVER START TRIP
printStep("Driver Starting Trip...");
$startTrip = apiRequest('POST', '/driver/shuttle/start', $driverToken, [
    'route_id' => $route->id
], true);

if ($startTrip['code'] != 200) {
    print_r($startTrip['body']);
    printError("Driver failed to start trip.");
}
echo "Trip Started. Driver assigned to relevant rides.\n";

// Verify assignment
$ride = \App\Models\Ride::find($rideId);
if ($ride->driver_id != $driver->id) printError("Driver was NOT assigned to the ride.");
echo "SUCCESS: Driver ID {$driver->id} assigned to Ride ID {$rideId}.\n";


// 6. DRIVER ARRIVE AT PICKUP
printStep("Driver Arriving at Pickup...");
$arrive = apiRequest('POST', '/driver/shuttle/arrive', $driverToken, [
    'route_id' => $route->id,
    'stop_id' => $startStop->id
], true);
echo "Arrived at Stop ID {$startStop->id}.\n";


// 7. DRIVER DEPART PICKUP (START RIDE)
printStep("Driver Departing Pickup (Pickup Passengers)...");
$departPickup = apiRequest('POST', '/driver/shuttle/depart', $driverToken, [
    'route_id' => $route->id,
    'stop_id' => $startStop->id
], true);

$ride->refresh();
if ($ride->status != 3) { // 3 = RIDE_RUNNING (Status::RIDE_RUNNING)
    echo "Status is: " . $ride->status . "\n";
    printError("Ride status did not change to RUNNING.");
}
echo "SUCCESS: Ride status is RUNNING.\n";


// 8. DRIVER ARRIVE AT DROPOFF
printStep("Driver Arriving at Dropoff...");
$arriveDropoff = apiRequest('POST', '/driver/shuttle/arrive', $driverToken, [
    'route_id' => $route->id,
    'stop_id' => $endStop->id
], true);
echo "Arrived at Stop ID {$endStop->id}.\n";


// 9. DRIVER DEPART DROPOFF (END RIDE & PAY)
printStep("Driver Departing Dropoff (End Ride & Pay)...");
$departDropoff = apiRequest('POST', '/driver/shuttle/depart', $driverToken, [
    'route_id' => $route->id,
    'stop_id' => $endStop->id
], true);

$ride->refresh();
if ($ride->status != 1) { // 1 = RIDE_COMPLETED (Status::RIDE_COMPLETED)
    echo "Status is: " . $ride->status . "\n";
    printError("Ride status did not change to COMPLETED.");
}
echo "SUCCESS: Ride status is COMPLETED.\n";
echo "Payment Status: " . $ride->payment_status . "\n";

printStep("\n--- SIMULATION COMPLETED SUCCESSFULLY ---");
