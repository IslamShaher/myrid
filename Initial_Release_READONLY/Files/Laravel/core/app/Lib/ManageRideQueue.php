<?php

namespace App\Lib;

use App\Constants\Status;
use App\Events\Ride as EventsRide;
use App\Models\Driver;
use App\Models\Ride;

class ManageRideQueue
{
    public function  initQueue($queue)
    {

        $this->queueAction($queue);
    }

    private function queueAction($queue)
    {
        return match ($queue->action_type) {
            'new_driver_notification' => $this->sendNewRideNotificationToDriver($queue),
            default => throw new \Exception("Unknown queue action: {$queue->action_type}")
        };
    }


    public function sendNewRideNotificationToDriver($queue)
    {

        $ride = Ride::pending()->find($queue->ride_id);

        if ($ride) {

            // Prepare short code for notification
            $shortCode = [
                'ride_id'         => $ride->uid,
                'service'         => $ride->service->name,
                'pickup_location' => $ride->pickup_location,
                'destination'     => $ride->destination,
                'duration'        => $ride->duration,
                'distance'        => $ride->distance,
                'pickup_time'     => showDateTime(now()),
            ];

            $ride->load('user', 'service', 'driver', 'driver.vehicle', 'driver.vehicle.model', 'driver.vehicle.color', 'driver.vehicle.year');

            $driverImagePath = getFilePath('driver');
            $userImagePath   = getFilePath('user');

            // Use chunking to process drivers in batches of 100
            Driver::active()
                ->where('online_status', Status::YES)
                ->where('zone_id', $ride->pickup_zone_id)
                ->where("service_id", $ride->service_id)
                ->where('dv', Status::VERIFIED)
                ->where('vv', Status::VERIFIED)
                ->notRunning()
                ->chunk(20, function ($drivers) use ($ride, $shortCode, $driverImagePath, $userImagePath) {
                    foreach ($drivers as $driver) {
                        event(new EventsRide("rider-driver-$driver->id", "NEW_RIDE", [
                            'ride'              => $ride,
                            'driver_image_path' => $driverImagePath,
                            'user_image_path'   => $userImagePath,
                        ]));
                        notify($driver, 'NEW_RIDE', $shortCode);
                    }
                });

            $queue->delete();
        }
    }
}
