<?php

require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Http\Request;
use App\Http\Controllers\Api\ShuttleController;
use App\Services\GoogleMapsService;

$controller = new ShuttleController(new GoogleMapsService());

$refStartLat = 30.0388148;
$refStartLng = 31.2103418;
$refEndLat = 30.0465220;
$refEndLng = 31.2242989;

function getOffsetPoint($lat, $lng, $offsetMeters) {
    $latOffset = 0;
    $lngOffset = -($offsetMeters / (111000 * cos(deg2rad($lat))));
    return [$lat, $lng + $lngOffset];
}

function runTest($name, $distMeters) {
    global $controller, $refStartLat, $refStartLng, $refEndLat, $refEndLng;
    
    echo "\n=== TEST: $name ($distMeters meters away) ===\n";
    
    list($sLat, $sLng) = getOffsetPoint($refStartLat, $refStartLng, $distMeters);
    list($eLat, $eLng) = getOffsetPoint($refEndLat, $refEndLng, $distMeters);
    
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
        echo "Result: ✅ MATCH FOUND\n";
        $match = $data['matches'][0];
        echo "Route: " . $match['route']['name'] . "\n";
        echo "Start: " . $match['start_stop']['name'] . "\n";
        echo "End: " . $match['end_stop']['name'] . "\n";
    } else {
        echo "Result: ❌ NO MATCH (" . ($data['message'] ?? 'Unknown error') . ")\n";
    }
}

runTest("0.5km Distance", 500);
runTest("1.5km Distance", 1500);


