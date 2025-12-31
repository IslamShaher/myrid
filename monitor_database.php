<?php
/**
 * Database Monitor - Monitors shared ride creation and matching in real-time
 * Run as: php monitor_database.php [output_file]
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Ride;
use App\Constants\Status;

$outputFile = $argv[1] ?? 'database_monitor.log';
$fp = fopen($outputFile, 'a');

if (!$fp) {
    echo "Error: Cannot open output file: $outputFile\n";
    exit(1);
}

fwrite($fp, "=== Database Monitor Started ===\n");
fwrite($fp, date('Y-m-d H:i:s') . "\n");
fwrite($fp, "Monitoring shared rides in real-time...\n\n");
fflush($fp);

$lastRideId = 0;

while (true) {
    $timestamp = date('Y-m-d H:i:s');
    
    try {
        // Count active shared rides
        $activeRides = Ride::where('ride_type', Status::SHARED_RIDE)
            ->where('status', Status::RIDE_ACTIVE)
            ->whereNull('second_user_id')
            ->get();
        
        // Count matched rides
        $matchedRides = Ride::where('ride_type', Status::SHARED_RIDE)
            ->whereNotNull('second_user_id')
            ->get();
        
        // Get recent shared rides (latest 5)
        $recentRides = Ride::where('ride_type', Status::SHARED_RIDE)
            ->orderBy('created_at', 'desc')
            ->limit(5)
            ->get();
        
        // Check for new rides
        $newRides = Ride::where('ride_type', Status::SHARED_RIDE)
            ->where('id', '>', $lastRideId)
            ->orderBy('id', 'asc')
            ->get();
        
        if ($newRides->count() > 0) {
            fwrite($fp, "\n[$timestamp] *** NEW RIDE DETECTED ***\n");
            foreach ($newRides as $ride) {
                fwrite($fp, sprintf(
                    "  NEW: Ride ID: %d | User: %d | 2nd User: %s | Status: %d | Created: %s\n",
                    $ride->id,
                    $ride->user_id,
                    $ride->second_user_id ?? 'NULL',
                    $ride->status,
                    $ride->created_at
                ));
            }
            $lastRideId = $newRides->last()->id;
        }
        
        // Status update
        fwrite($fp, "[$timestamp] Status:\n");
        fwrite($fp, "  Active Shared Rides (available for matching): " . $activeRides->count() . "\n");
        fwrite($fp, "  Matched Rides (with 2nd user): " . $matchedRides->count() . "\n");
        
        if ($recentRides->count() > 0) {
            fwrite($fp, "  Recent Shared Rides:\n");
            foreach ($recentRides as $ride) {
                $statusText = match($ride->status) {
                    Status::RIDE_ACTIVE => 'ACTIVE',
                    Status::RIDE_RUNNING => 'RUNNING',
                    Status::RIDE_COMPLETED => 'COMPLETED',
                    Status::RIDE_CANCELED => 'CANCELED',
                    default => "STATUS_{$ride->status}"
                };
                
                fwrite($fp, sprintf(
                    "    ID: %d | User1: %d | User2: %s | %s | Pickup: (%.4f, %.4f) | Dest: (%.4f, %.4f)\n",
                    $ride->id,
                    $ride->user_id,
                    $ride->second_user_id ?? 'NULL',
                    $statusText,
                    $ride->pickup_latitude,
                    $ride->pickup_longitude,
                    $ride->destination_latitude,
                    $ride->destination_longitude
                ));
            }
        }
        
        fwrite($fp, "\n");
        fflush($fp);
        
    } catch (\Exception $e) {
        fwrite($fp, "[$timestamp] ERROR: " . $e->getMessage() . "\n");
        fflush($fp);
    }
    
    sleep(2);
}

fclose($fp);




