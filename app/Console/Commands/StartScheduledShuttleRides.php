<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Ride;
use App\Constants\Status;
use App\Events\Ride as RideEvent;
use Carbon\Carbon;

class StartScheduledShuttleRides extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'shuttle:start-scheduled';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Automatically start shuttle rides when their scheduled time arrives';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $currentTime = Carbon::now()->format('H:i:s');
        $today = Carbon::today();

        $rides = Ride::where('ride_type', Status::SHUTTLE_RIDE)
                     ->where('status', Status::RIDE_ACTIVE)
                     ->where('start_time', '<=', $currentTime)
                     ->whereDate('created_at', $today)
                     ->get();

        foreach ($rides as $ride) {
            $ride->status = Status::RIDE_RUNNING;
            $ride->save();

            // Notify the user
            event(new RideEvent(
                "rider-user-{$ride->user_id}",
                "ride_started",
                [
                    'ride' => $ride,
                    'message' => 'Your shuttle ride has started.'
                ]
            ));

            $this->info("Started shuttle ride ID: {$ride->id}");
        }

        return Command::SUCCESS;
    }
}
