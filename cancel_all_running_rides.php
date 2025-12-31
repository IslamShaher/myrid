<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$response = $kernel->handle($request = Illuminate\Http\Request::capture());

use Illuminate\Support\Facades\DB;
use App\Models\Ride;
use App\Constants\Status;

try {
    // Cancel all active rides (both normal and shared)
    // Includes: RIDE_ACTIVE (2), RIDE_RUNNING (3)
    // Excludes: RIDE_PENDING (0), RIDE_COMPLETED (1), RIDE_END (4), RIDE_CANCELED (9)
    $rides = Ride::whereIn('status', [Status::RIDE_ACTIVE, Status::RIDE_RUNNING])
        ->get();
    
    $canceled = 0;
    foreach ($rides as $ride) {
        $originalStatus = $ride->status;
        $ride->status = Status::RIDE_CANCELED;
        $ride->canceled_user_type = Status::USER;
        $ride->cancel_reason = 'Cancelled - active ride cleanup';
        $ride->cancelled_at = now();
        $ride->save();
        $canceled++;
        $statusLabel = $originalStatus == Status::RIDE_ACTIVE ? 'Active' : 'Running';
        $typeLabel = $ride->ride_type == Status::SHARED_RIDE ? 'Shared' : 'Normal';
        echo "Cancelled ride ID: {$ride->id} (Status: {$statusLabel}, Type: {$typeLabel})\n";
    }
    
    echo "\nTotal cancelled: $canceled active rides (both normal and shared).\n";
} catch (\Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
    echo "Stack trace: " . $e->getTraceAsString() . "\n";
}

