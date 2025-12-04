<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Driver;
use App\Models\ShuttleRoute;
use App\Models\Zone;
use Illuminate\Support\Facades\Auth;

// --- CONFIGURATION ---
$apiUrl = 'http://127.0.0.1:8000/api'; 

// Ensure a zone exists
$zone = Zone::firstOrCreate(['name' => 'Simulation Zone'], [
    'status' => 1
]);
$zone->coordinates = [
     ['lat' => 0.0, 'lang' => 0.0],
     ['lat' => 0.0, 'lang' => 30.0],
     ['lat' => 30.0, 'lang' => 30.0],
     ['lat' => 30.0, 'lang' => 0.0],
     ['lat' => 0.0, 'lang' => 0.0],
];
$zone->status = 1;
$zone->save();

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
    if ($response === false) {
        echo "CURL Error: " . curl_error($ch) . "\n";
    }
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $decoded = json_decode($response, true);
    if ($decoded === null && json_last_error() !== JSON_ERROR_NONE) {
         echo "JSON Decode Error: " . json_last_error_msg() . "\n";
         echo "Raw Response: " . substr($response, 0, 500) . "\n";
    }

    return ['code' => $httpCode, 'body' => $decoded];
}

function printStep($message) {
    echo "\n\033[1;32m[STEP] $message\033[0m\n";
}

function printError($message) {
    echo "\n\033[1;31m[ERROR] $message\033[0m\n";
    exit(1);
}

// --- SIMULATION START ---

printStep("Initializing Cancellation Simulation...");

// 1. DATA SETUP
$route = ShuttleRoute::with('stops')->first();
if (!$route || $route->stops->count() < 2) printError("No valid shuttle route found.");

$startStop = $route->stops[0];
$endStop = $route->stops[1];

echo "Route: {$route->name} (ID: {$route->id})\n";

// 2. RIDER LOGIN
printStep("Rider Login...");
$user = User::firstOrCreate(
    ['email' => 'rider_cancel@sim.com'],
    ['username' => 'rider_cancel', 'password' => bcrypt('password'), 'country_code' => '1', 'mobile' => '9999999999']
);
$user->ev = 1;
$user->sv = 1;
$user->profile_complete = 1;
$user->tv = 1;
$user->save();

$riderLogin = apiRequest('POST', '/login', null, ['username' => 'rider_cancel@sim.com', 'password' => 'password']);
if ($riderLogin['code'] != 200) printError("Rider login failed.");
$riderToken = $riderLogin['body']['data']['access_token'];
echo "Rider Token: " . substr($riderToken, 0, 20) . "...\n";

// CLEANUP
\App\Models\Ride::where('user_id', $user->id)
    ->whereIn('status', [\App\Constants\Status::RIDE_ACTIVE, \App\Constants\Status::RIDE_RUNNING])
    ->update(['status' => \App\Constants\Status::RIDE_CANCELED]);
echo "Cleaned up active rides for user.\n";


// 3. BOOK RIDE
printStep("Rider Booking Ride...");
$book = apiRequest('POST', '/shuttle/create', $riderToken, [
    'route_id' => $route->id,
    'start_stop_id' => $startStop->id,
    'end_stop_id' => $endStop->id,
    'number_of_passenger' => 1
]);

if ($book['code'] != 200 || !isset($book['body']['data'])) {
    print_r($book['body']);
    printError("Booking failed.");
}
$rideId = $book['body']['data']['ride']['id'];
echo "Ride Created! ID: $rideId\n";

// Verify Status
$ride = \App\Models\Ride::find($rideId);
if ($ride->status != \App\Constants\Status::RIDE_ACTIVE) printError("Ride status incorrect (Expected ACTIVE).");

// 4. CANCEL RIDE
printStep("Rider Cancelling Ride...");
// Use existing cancel endpoint
$cancel = apiRequest('POST', "/ride/cancel/$rideId", $riderToken, [
    'cancel_reason' => 'Changed my mind'
]);

if ($cancel['code'] != 200) {
    print_r($cancel['body']);
    printError("Cancellation failed.");
}

if ($cancel['body']['status'] != 'success') {
    print_r($cancel['body']);
    printError("Cancellation API returned error.");
}

// 5. VERIFY
printStep("Verifying Status...");
$ride->refresh();
echo "Ride Status: {$ride->status}\n";

if ($ride->status == \App\Constants\Status::RIDE_CANCELED) {
    echo "SUCCESS: Ride cancelled successfully.\n";
} else {
    printError("Ride status incorrect (Expected CANCELED). Status: {$ride->status}");
}

printStep("\n--- CANCELLATION SIMULATION COMPLETED ---");

