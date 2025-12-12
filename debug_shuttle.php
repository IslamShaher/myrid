<?php

require __DIR__ . '/vendor/autoload.php';
$app = require __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Stop;
use App\Models\ShuttleRoute;

echo "--- Debug Shuttle Route ---\n";

$startName = 'Cairo Tower';
$endName = 'Leonardo Ristorante';

echo "Searching for stops: '$startName' and '$endName'...\n";

$startStops = Stop::where('name', 'LIKE', "%$startName%")->get();
$endStops = Stop::where('name', 'LIKE', "%$endName%")->get();

if ($startStops->isEmpty()) {
    echo "ERROR: Start stop '$startName' not found.\n";
} else {
    foreach ($startStops as $s) {
        echo "Found Start Stop: [{$s->id}] {$s->name} ({$s->latitude}, {$s->longitude})\n";
    }
}

if ($endStops->isEmpty()) {
    echo "ERROR: End stop '$endName' not found.\n";
} else {
    foreach ($endStops as $s) {
        echo "Found End Stop: [{$s->id}] {$s->name} ({$s->latitude}, {$s->longitude})\n";
    }
}

if ($startStops->isEmpty() || $endStops->isEmpty()) {
    exit("Cannot proceed with route check due to missing stops.\n");
}

$startIds = $startStops->pluck('id')->toArray();
$endIds = $endStops->pluck('id')->toArray();

echo "\nChecking Routes containing these stops...\n";

$routes = ShuttleRoute::whereHas('stops', function ($q) use ($startIds) {
    $q->whereIn('stops.id', $startIds);
})
->whereHas('stops', function ($q) use ($endIds) {
    $q->whereIn('stops.id', $endIds);
})
->with(['stops' => function($q) use ($startIds, $endIds) {
    $q->whereIn('stops.id', array_merge($startIds, $endIds));
}])
->get();

if ($routes->isEmpty()) {
    echo "NO ROUTES FOUND containing both stops.\n";
} else {
    echo "Found " . $routes->count() . " potentially matching routes:\n";
    foreach ($routes as $r) {
        echo "Route [{$r->id}] {$r->name}:\n";
        foreach ($r->stops as $stop) {
            echo "  - Stop [{$stop->id}] {$stop->name} | Order: " . ($stop->pivot->order ?? 'NULL') . "\n";
        }
    }
}
