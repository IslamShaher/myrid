<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Driver;
use App\Models\ShuttleRoute;
use App\Models\Ride;
use App\Models\Zone;

// --- CONFIGURATION ---
$apiUrl = 'http://127.0.0.1:8000/api'; 
// Ensure a zone exists for the test coordinates
$zone = Zone::firstOrCreate(['name' => 'Simulation Zone'], [
    'status' => 1
]);
// Force update coordinates to use 'lang' (legacy support)
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

printStep("Initializing Multi-Rider Simulation...");

// Clear existing rides for test users to prevent "active ride" error
$u1 = User::where('username', 'rider1')->first();
if($u1) Ride::where('user_id', $u1->id)->delete();
$u2 = User::where('username', 'rider2')->first();
if($u2) Ride::where('user_id', $u2->id)->delete();


// 1. DATA SETUP
$route = ShuttleRoute::with('stops')->first();
if (!$route || $route->stops->count() < 3) {
    if(!$route || $route->stops->count() < 2) printError("No valid shuttle route found.");
}

$stopA = $route->stops[0];
$stopB = $route->stops[1];
$stopC = isset($route->stops[2]) ? $route->stops[2] : $stopB; // Logic for 2 stops

echo "Route: {$route->name}\n";
echo "Stop A: {$stopA->name} ({$stopA->latitude}, {$stopA->longitude})\n";
echo "Stop B: {$stopB->name} ({$stopB->latitude}, {$stopB->longitude})\n";
if($stopC != $stopB) echo "Stop C: {$stopC->name} ({$stopC->latitude}, {$stopC->longitude})\n";

// 2. USERS LOGIN
printStep("Logging in Users...");
// Rider 1: A -> B
$user1 = User::firstOrCreate(['email' => 'rider1@sim.com'], ['username' => 'rider1', 'password' => bcrypt('password'), 'country_code' => '1', 'mobile' => '1111111111']);
$res1 = apiRequest('POST', '/login', null, ['username' => 'rider1@sim.com', 'password' => 'password']);
$token1 = $res1['body']['data']['access_token'];

// Rider 2: A -> C (or B if only 2 stops)
$user2 = User::firstOrCreate(['email' => 'rider2@sim.com'], ['username' => 'rider2', 'password' => bcrypt('password'), 'country_code' => '1', 'mobile' => '2222222222']);
$res2 = apiRequest('POST', '/login', null, ['username' => 'rider2@sim.com', 'password' => 'password']);
$token2 = $res2['body']['data']['access_token'];

// Driver
$driver = \App\Models\Driver::firstOrCreate(['email' => 'driver@sim.com'], ['username' => 'driver_sim', 'password' => bcrypt('password'), 'service_id' => 1, 'zone_id' => 1]);
$resD = apiRequest('POST', '/driver/login', null, ['username' => 'driver@sim.com', 'password' => 'password']);
$tokenD = $resD['body']['data']['access_token'];


// 3. BOOKINGS
printStep("Booking Rides...");

// Rider 1 books A -> B
$book1 = apiRequest('POST', '/shuttle/create', $token1, [
    'route_id' => $route->id,
    'start_stop_id' => $stopA->id,
    'end_stop_id' => $stopB->id,
    'number_of_passenger' => 1
]);

if ($book1['code'] != 200) {
    print_r($book1['body']);
    printError("Rider 1 Booking Failed");
}

$ride1Id = $book1['body']['data']['ride']['id'];
echo "Rider 1 booked Ride ID: $ride1Id (A -> B)\n";

// Rider 2 books A -> C
$book2 = apiRequest('POST', '/shuttle/create', $token2, [
    'route_id' => $route->id,
    'start_stop_id' => $stopA->id,
    'end_stop_id' => $stopC->id,
    'number_of_passenger' => 2
]);

if ($book2['code'] != 200) {
    print_r($book2['body']);
    printError("Rider 2 Booking Failed");
}

if (!isset($book2['body']['data'])) {
     echo "ERROR: 'data' key missing in Rider 2 booking response.\n";
     print_r($book2['body']);
     exit(1);
}

$ride2Id = $book2['body']['data']['ride']['id'];
echo "Rider 2 booked Ride ID: $ride2Id (A -> C)\n";


// 4. DRIVER START
printStep("Driver Starts Trip...");
apiRequest('POST', '/driver/shuttle/start', $tokenD, ['route_id' => $route->id]);

// Verify both assigned
$r1 = \App\Models\Ride::find($ride1Id);
$r2 = \App\Models\Ride::find($ride2Id);

echo "Driver Object ID: {$driver->id}\n";
echo "Ride 1 Driver ID: {$r1->driver_id}\n";
echo "Ride 2 Driver ID: {$r2->driver_id}\n";

if($r1->driver_id == $driver->id && $r2->driver_id == $driver->id) {
    echo "SUCCESS: Both rides assigned to driver.\n";
} else {
    printError("Driver assignment failed.");
}


// 5. STOP A (Pickup Both)
printStep("Processing Stop A (Pickup Both)...");
apiRequest('POST', '/driver/shuttle/arrive', $tokenD, ['route_id' => $route->id, 'stop_id' => $stopA->id]);
apiRequest('POST', '/driver/shuttle/depart', $tokenD, ['route_id' => $route->id, 'stop_id' => $stopA->id]);

$r1->refresh(); $r2->refresh();
if($r1->status == 3 && $r2->status == 3) {
    echo "SUCCESS: Both rides started (RUNNING).\n";
} else {
    printError("Rides failed to start. R1: {$r1->status}, R2: {$r2->status}");
}


// 6. STOP B (Dropoff Rider 1, Rider 2 continues if C exists)
printStep("Processing Stop B...");
apiRequest('POST', '/driver/shuttle/arrive', $tokenD, ['route_id' => $route->id, 'stop_id' => $stopB->id]);
apiRequest('POST', '/driver/shuttle/depart', $tokenD, ['route_id' => $route->id, 'stop_id' => $stopB->id]);

$r1->refresh(); $r2->refresh();

if($r1->status == 1) { // COMPLETED
    echo "SUCCESS: Rider 1 completed at Stop B.\n";
} else {
    printError("Rider 1 failed to complete. Status: {$r1->status}");
}

if($stopC->id != $stopB->id) {
    if($r2->status == 3) {
        echo "SUCCESS: Rider 2 still running (going to C).\n";
    } else {
        printError("Rider 2 status incorrect (Expected RUNNING). Status: {$r2->status}");
    }

    // 7. STOP C (Dropoff Rider 2)
    printStep("Processing Stop C...");
    apiRequest('POST', '/driver/shuttle/arrive', $tokenD, ['route_id' => $route->id, 'stop_id' => $stopC->id]);
    apiRequest('POST', '/driver/shuttle/depart', $tokenD, ['route_id' => $route->id, 'stop_id' => $stopC->id]);
    
    $r2->refresh();
    if($r2->status == 1) {
        echo "SUCCESS: Rider 2 completed at Stop C.\n";
    } else {
        printError("Rider 2 failed to complete. Status: {$r2->status}");
    }
} else {
    if($r2->status == 1) {
        echo "SUCCESS: Rider 2 completed at Stop B (Same as C).\n";
    }
}

printStep("\n--- MULTI-RIDER SIMULATION COMPLETED ---");
