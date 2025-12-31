<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$response = $kernel->handle($request = Illuminate\Http\Request::capture());

use Illuminate\Support\Facades\DB;
use App\Models\Ride;
use App\Constants\Status;

try {
    // Cancel ALL active and running rides (both normal and shared)
    $rides = Ride::whereIn('status', [Status::RIDE_ACTIVE, Status::RIDE_RUNNING])
        ->get();
    
    $canceled = 0;
    foreach ($rides as $ride) {
        $ride->status = Status::RIDE_CANCELED;
        $ride->canceled_user_type = 'rider';
        $ride->cancel_reason = 'Cancelled for testing';
        $ride->cancel_date = now();
        $ride->cancelled_at = now();
        $ride->save();
        $canceled++;
        echo "Cancelled ride ID: {$ride->id} (Type: " . ($ride->ride_type == Status::SHARED_RIDE ? 'Shared' : 'Normal') . ")\n";
    }
    
    echo "\nTotal cancelled: $canceled rides (all types).\n";
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
