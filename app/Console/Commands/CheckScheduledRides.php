<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Ride;
use App\Constants\Status;
use App\Events\Ride as RideEvent;
use Carbon\Carbon;

class CheckScheduledRides extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'shared-ride:check-scheduled';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check scheduled shared rides and send notifications when time arrives';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $now = Carbon::now();
        // Check rides scheduled within the last minute (to account for cron interval)
        $timeWindowStart = $now->copy()->subMinute();
        $timeWindowEnd = $now->copy()->addMinute();

        $rides = Ride::where('ride_type', Status::SHARED_RIDE)
                     ->where('status', Status::RIDE_ACTIVE)
                     ->whereNotNull('scheduled_time')
                     ->whereNotNull('second_user_id') // Only confirmed rides
                     ->whereBetween('scheduled_time', [$timeWindowStart, $timeWindowEnd])
                     ->with('user', 'secondUser')
                     ->get();

        foreach ($rides as $ride) {
            // Send notification to both users
            $rideData = [
                'ride_id' => $ride->id,
                'message' => 'Your shared ride is starting now!',
            ];

            // Notify Rider 1
            event(new RideEvent(
                "rider-user-{$ride->user_id}",
                "SHARED_RIDE_STARTED",
                array_merge($rideData, ['ride' => $ride])
            ));

            // Send push notification to Rider 1
            if ($ride->user) {
                notify(
                    $ride->user,
                    'SHARED_RIDE_STARTED',
                    [
                        'ride_id' => $ride->id,
                        'message' => 'Your shared ride is starting now!',
                    ]
                );
            }

            // Notify Rider 2
            if ($ride->secondUser) {
                event(new RideEvent(
                    "rider-user-{$ride->second_user_id}",
                    "SHARED_RIDE_STARTED",
                    array_merge($rideData, ['ride' => $ride])
                ));

                // Send push notification to Rider 2
                notify(
                    $ride->secondUser,
                    'SHARED_RIDE_STARTED',
                    [
                        'ride_id' => $ride->id,
                        'message' => 'Your shared ride is starting now!',
                    ]
                );
            }

            $this->info("Notified users for shared ride ID: {$ride->id}");
        }

        return Command::SUCCESS;
    }
}
