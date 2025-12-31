<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$response = $kernel->handle($request = Illuminate\Http\Request::capture());

use Illuminate\Support\Facades\DB;
use App\Models\Ride;
use App\Constants\Status;

try {
    // Cancel all active and running rides that are NOT shared rides
    $rides = Ride::whereIn('status', [Status::RIDE_ACTIVE, Status::RIDE_RUNNING])
        ->where('ride_type', '!=', Status::SHARED_RIDE)
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
        echo "Cancelled ride ID: {$ride->id}\n";
    }
    
    echo "\nTotal cancelled: $canceled normal (non-shared) rides.\n";
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
}
