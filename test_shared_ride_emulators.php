<?php
/**
 * Test script to simulate shared ride matching between two emulators
 * This simulates what happens when two users create shared rides and try to match
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(\Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\User;
use App\Models\Ride;
use App\Constants\Status;
use Illuminate\Support\Facades\Hash;

// Configuration
$apiBaseUrl = 'http://192.168.1.13:8000/api';
$devToken = 'ovoride-dev-123';

// Test coordinates from check_rides.php
$emulator1 = [
    'pickup_lat' => 30.0444,
    'pickup_lng' => 31.2357,
    'dest_lat' => 30.0131,
    'dest_lng' => 31.2089,
    'pickup_location' => 'Emulator 1 Pickup Location',
    'destination' => 'Emulator 1 Destination'
];

$emulator2 = [
    'pickup_lat' => 30.0450,
    'pickup_lng' => 31.2360,
    'dest_lat' => 30.0140,
    'dest_lng' => 31.2095,
    'pickup_location' => 'Emulator 2 Pickup Location',
    'destination' => 'Emulator 2 Destination'
];

function printStep($message) {
    echo "\n\033[1;32m[STEP] $message\033[0m\n";
}

function printError($message) {
    echo "\n\033[1;31m[ERROR] $message\033[0m\n";
}

function printSuccess($message) {
    echo "\033[1;36m[SUCCESS] $message\033[0m\n";
}

function apiRequest($url, $method = 'GET', $token = null, $data = []) {
    global $devToken;
    
    $ch = curl_init($url);
    
    $headers = [
        'Accept: application/json',
        'Content-Type: application/json',
        "dev-token: $devToken"
    ];
    
    if ($token) {
        $headers[] = "Authorization: Bearer $token";
    }
    
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    
    if ($method === 'POST' && !empty($data)) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    }
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    return [
        'code' => $httpCode,
        'body' => json_decode($response, true),
        'raw' => $response
    ];
}

// === STEP 1: Create/Get Test Users ===
printStep("Setting up test users...");

$user1 = User::firstOrCreate(
    ['email' => 'emulator1@test.com'],
    [
        'username' => 'emulator1',
        'password' => Hash::make('password123'),
        'firstname' => 'Emulator',
        'lastname' => 'One',
        'ev' => Status::VERIFIED,
        'sv' => Status::VERIFIED,
        'tv' => Status::VERIFIED,
        'ts' => Status::DISABLE,
        'profile_complete' => Status::YES,
        'status' => Status::ENABLE,
        'is_deleted' => Status::NO
    ]
);

$user2 = User::firstOrCreate(
    ['email' => 'emulator2@test.com'],
    [
        'username' => 'emulator2',
        'password' => Hash::make('password123'),
        'firstname' => 'Emulator',
        'lastname' => 'Two',
        'ev' => Status::VERIFIED,
        'sv' => Status::VERIFIED,
        'tv' => Status::VERIFIED,
        'ts' => Status::DISABLE,
        'profile_complete' => Status::YES,
        'status' => Status::ENABLE,
        'is_deleted' => Status::NO
    ]
);

echo "User 1 ID: {$user1->id}, Email: {$user1->email}\n";
echo "User 2 ID: {$user2->id}, Email: {$user2->email}\n";

// === STEP 2: Clear any existing active rides for these users ===
printStep("Clearing existing active rides...");
Ride::where('user_id', $user1->id)
    ->where('ride_type', Status::SHARED_RIDE)
    ->where('status', Status::RIDE_ACTIVE)
    ->update(['status' => Status::RIDE_CANCELED]);

Ride::where('user_id', $user2->id)
    ->where('ride_type', Status::SHARED_RIDE)
    ->where('status', Status::RIDE_ACTIVE)
    ->update(['status' => Status::RIDE_CANCELED]);

// === STEP 3: Login users and get tokens ===
printStep("Logging in users...");

$login1 = apiRequest("$apiBaseUrl/login", 'POST', null, [
    'username' => 'emulator1@test.com',
    'password' => 'password123'
]);

if ($login1['code'] !== 200 || !isset($login1['body']['data']['access_token'])) {
    printError("Failed to login user 1");
    print_r($login1);
    exit(1);
}

$token1 = $login1['body']['data']['access_token'];
printSuccess("User 1 logged in, token obtained");

$login2 = apiRequest("$apiBaseUrl/login", 'POST', null, [
    'username' => 'emulator2@test.com',
    'password' => 'password123'
]);

if ($login2['code'] !== 200 || !isset($login2['body']['data']['access_token'])) {
    printError("Failed to login user 2");
    print_r($login2);
    exit(1);
}

$token2 = $login2['body']['data']['access_token'];
printSuccess("User 2 logged in, token obtained");

// === STEP 4: Emulator 1 creates a shared ride ===
printStep("Emulator 1 creating shared ride...");
echo "Pickup: ({$emulator1['pickup_lat']}, {$emulator1['pickup_lng']})\n";
echo "Dest: ({$emulator1['dest_lat']}, {$emulator1['dest_lng']})\n";

$create1 = apiRequest("$apiBaseUrl/shuttle/create-shared-ride", 'POST', $token1, [
    'start_lat' => $emulator1['pickup_lat'],
    'start_lng' => $emulator1['pickup_lng'],
    'end_lat' => $emulator1['dest_lat'],
    'end_lng' => $emulator1['dest_lng'],
    'pickup_location' => $emulator1['pickup_location'],
    'destination' => $emulator1['destination']
]);

if ($create1['code'] !== 200) {
    printError("Failed to create shared ride for user 1");
    print_r($create1);
    exit(1);
}

$ride1Id = $create1['body']['ride']['id'] ?? null;
if (!$ride1Id) {
    printError("Ride ID not found in response");
    print_r($create1);
    exit(1);
}

printSuccess("User 1 created shared ride ID: $ride1Id");

// Verify ride was created in database
$ride1 = Ride::find($ride1Id);
if (!$ride1) {
    printError("Ride not found in database");
    exit(1);
}

echo "  Ride Type: {$ride1->ride_type} (Expected: " . Status::SHARED_RIDE . ")\n";
echo "  Status: {$ride1->status} (Expected: " . Status::RIDE_ACTIVE . ")\n";
echo "  User ID: {$ride1->user_id}\n";
echo "  Second User ID: " . ($ride1->second_user_id ?? 'NULL') . "\n";

// === STEP 5: Emulator 2 tries to match ===
printStep("Emulator 2 searching for matching rides...");
echo "Pickup: ({$emulator2['pickup_lat']}, {$emulator2['pickup_lng']})\n";
echo "Dest: ({$emulator2['dest_lat']}, {$emulator2['dest_lng']})\n";

$match2 = apiRequest("$apiBaseUrl/shuttle/match-shared-ride", 'POST', $token2, [
    'start_lat' => $emulator2['pickup_lat'],
    'start_lng' => $emulator2['pickup_lng'],
    'end_lat' => $emulator2['dest_lat'],
    'end_lng' => $emulator2['dest_lng']
]);

echo "Match API Response Code: {$match2['code']}\n";
if ($match2['code'] === 200) {
    $matches = $match2['body']['matches'] ?? [];
    echo "Matches found: " . count($matches) . "\n";
    
    if (count($matches) > 0) {
        printSuccess("MATCH FOUND! Emulator 2 can see Emulator 1's ride");
        foreach ($matches as $index => $match) {
            echo "\nMatch #" . ($index + 1) . ":\n";
            echo "  Ride ID: {$match['ride']['id']}\n";
            echo "  Total Overhead: {$match['total_overhead']}\n";
            if (isset($match['r1_fare'])) {
                echo "  Rider 1 Fare: {$match['r1_fare']}\n";
            }
            if (isset($match['r2_fare'])) {
                echo "  Rider 2 Fare: {$match['r2_fare']}\n";
            }
        }
        
        // === STEP 6: Emulator 2 joins the ride ===
        printStep("Emulator 2 joining the ride...");
        $joinRide = apiRequest("$apiBaseUrl/shuttle/join-ride", 'POST', $token2, [
            'ride_id' => $matches[0]['ride']['id']
        ]);
        
        if ($joinRide['code'] === 200) {
            printSuccess("User 2 successfully joined the ride!");
            
            // Verify in database
            $updatedRide = Ride::find($matches[0]['ride']['id']);
            echo "  Ride ID: {$updatedRide->id}\n";
            echo "  User 1 ID: {$updatedRide->user_id}\n";
            echo "  User 2 ID: {$updatedRide->second_user_id}\n";
            echo "  Status: {$updatedRide->status}\n";
        } else {
            printError("Failed to join ride");
            print_r($joinRide);
        }
    } else {
        printError("NO MATCHES FOUND - This is the problem!");
        echo "Response body:\n";
        print_r($match2['body']);
    }
} else {
    printError("Match API call failed");
    print_r($match2);
}

// === STEP 7: Check database state ===
printStep("Final database check...");
$activeRides = Ride::where('ride_type', Status::SHARED_RIDE)
    ->where('status', Status::RIDE_ACTIVE)
    ->whereNull('second_user_id')
    ->get();

echo "Active shared rides (available for matching): " . $activeRides->count() . "\n";
foreach ($activeRides as $ride) {
    echo "  Ride ID: {$ride->id}, User ID: {$ride->user_id}\n";
}

echo "\n=== Test Complete ===\n";




