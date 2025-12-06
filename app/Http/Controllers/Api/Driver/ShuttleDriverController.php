<?php

namespace App\Http\Controllers\Api\Driver;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ShuttleRoute;
use App\Models\Ride;
use App\Models\Stop;
use App\Constants\Status;
use App\Events\Ride as EventsRide;
use App\Lib\RidePaymentManager;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class ShuttleDriverController extends Controller
{
    // ... listRoutes ...
    public function listRoutes()
    {
        $routes = ShuttleRoute::with(['stops' => function ($query) {
            $query->orderBy('pivot_order');
        }, 'schedules' => function($q) {
            $q->where('status', 1)->orderBy('start_time');
        }])->get();

        $notify[] = 'Shuttle Routes';
        return apiResponse("shuttle_routes", 'success', $notify, [
            'routes' => $routes
        ]);
    }

    // ... startTrip ...
    public function startTrip(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required|exists:routes,id',
        ]);

        if ($validator->fails()) {
            return apiResponse('validation_error', 'error', $validator->errors()->all());
        }

        $driver = auth()->user();
        
        $rides = Ride::where('route_id', $request->route_id)
            ->where('ride_type', Status::SHUTTLE_RIDE)
            ->where('status', Status::RIDE_ACTIVE) // Booked but not running
            ->where('start_time', '>=', Carbon::now()->subMinutes(60))
            ->where('start_time', '<=', Carbon::now()->addMinutes(60))
            ->get();

        if ($rides->isEmpty()) {
            $notify[] = 'No active bookings found for this route right now.';
        }

        foreach ($rides as $ride) {
            $ride->driver_id = $driver->id;
            $ride->save();

            event(new EventsRide("rider-user-{$ride->user_id}", "DRIVER_ASSIGNED", [
                'ride' => $ride,
                'driver_name' => $driver->username,
                'message' => 'A driver has been assigned to your shuttle.'
            ]));
        }

        $notify[] = 'Shuttle trip started. Passengers assigned.';
        return apiResponse("trip_started", 'success', $notify);
    }

    // ... arriveAtStop ...
    public function arriveAtStop(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required|exists:routes,id',
            'stop_id'  => 'required|exists:stops,id',
        ]);

        if ($validator->fails()) {
            return apiResponse('validation_error', 'error', $validator->errors()->all());
        }

        $rides = Ride::where('route_id', $request->route_id)
            ->where('driver_id', auth()->id())
            ->where('start_stop_id', $request->stop_id)
            ->where('status', Status::RIDE_ACTIVE)
            ->get();

        foreach ($rides as $ride) {
            event(new EventsRide("rider-user-{$ride->user_id}", "DRIVER_ARRIVED", [
                'ride' => $ride,
                'message' => 'Shuttle has arrived at your pickup stop.'
            ]));
        }

        $notify[] = 'Arrival notified to passengers.';
        return apiResponse("arrived", 'success', $notify);
    }

    /**
     * Driver departs a stop (Pick up passengers / Drop off passengers)
     */
    public function departStop(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required|exists:routes,id',
            'stop_id'  => 'required|exists:stops,id',
        ]);

        if ($validator->fails()) {
            return apiResponse('validation_error', 'error', $validator->errors()->all());
        }

        $driverId = auth()->id();
        $paymentManager = new RidePaymentManager();

        // 1. PICKUP: Update status to RUNNING for rides starting here
        $startingRides = Ride::where('route_id', $request->route_id)
            ->where('driver_id', $driverId)
            ->where('start_stop_id', $request->stop_id)
            ->where('status', Status::RIDE_ACTIVE)
            ->get();

        foreach ($startingRides as $ride) {
            $ride->status = Status::RIDE_RUNNING;
            $ride->start_time = now(); // Actual start time
            $ride->save();

            event(new EventsRide("rider-user-{$ride->user_id}", "PICK_UP", [
                'ride' => $ride,
                'message' => 'Your ride has started.'
            ]));
        }

        // 2. DROPOFF: Update status to COMPLETED for rides ending here and process payment
        $endingRides = Ride::where('route_id', $request->route_id)
            ->where('driver_id', $driverId)
            ->where('end_stop_id', $request->stop_id)
            ->where('status', Status::RIDE_RUNNING)
            ->with(['user', 'driver'])
            ->get();

        foreach ($endingRides as $ride) {
            $ride->end_time = now();
            $ride->status = Status::RIDE_COMPLETED;
            $ride->save();

            // Process Payment
            if ($ride->payment_type == Status::PAYMENT_TYPE_GATEWAY) {
                 // Online payment (Wallet/Card)
                 $paymentManager->payment($ride, Status::PAYMENT_TYPE_GATEWAY);
            } else {
                 // Cash Payment - Mark as waiting or Paid?
                 // For shuttle, let's assume driver collects cash upon entry or exit.
                 // To simplify flow, we'll mark it as PAID and assume collection.
                 // OR, we can leave it as WAITING_FOR_CASH_PAYMENT if we want a confirmation step.
                 // Let's auto-settle as Cash Paid for smoother flow, or use Manager to log it.
                 
                 // Actually, let's use payment manager with CASH type which logs transaction but doesn't touch user wallet balance (except logging)
                 $paymentManager->ridePayment($ride, Status::PAYMENT_TYPE_CASH);
                 
                 // We also need to deduct commission from driver for Cash rides
                 // The Manager logic for payment() handles commission for Gateway but separate for Cash?
                 // Let's look at RidePaymentManager::payment logic again.
                 // It calls ridePayment, handles driver balance for Gateway.
                 // It deducts commission at the end.
                 
                 // So we should call payment() method regardless of type to handle commission.
                 $paymentManager->payment($ride, Status::PAYMENT_TYPE_CASH);
            }

            event(new EventsRide("rider-user-{$ride->user_id}", "RIDE_END", [
                'ride' => $ride,
                'message' => 'You have reached your destination. Payment processed.'
            ]));
        }

        $notify[] = 'Stop departure processed.';
        return apiResponse("departed", 'success', $notify);
    }

    // ... liveLocation ...
    public function liveLocation(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude'  => 'required|numeric',
            'longitude' => 'required|numeric',
            // route_id is optional if we just find all running rides for this driver
        ]);

        if ($validator->fails()) {
            return apiResponse('validation_error', 'error', $validator->errors()->all());
        }

        $driverId = auth()->id();

        // Find all active/running rides for this driver (across all possible routes/passengers)
        $activeRides = Ride::where('driver_id', $driverId)
            ->whereIn('status', [Status::RIDE_ACTIVE, Status::RIDE_RUNNING])
            ->where('ride_type', Status::SHUTTLE_RIDE)
            ->get();

        // Broadcast to each unique user
        // Optimization: Group by user_id to avoid duplicate events if user has multiple seats (though rare for different rides)
        $userIds = $activeRides->pluck('user_id')->unique();

        foreach ($userIds as $userId) {
            // We need a ride object to pass to the event, just pick one for that user
            $userRide = $activeRides->firstWhere('user_id', $userId);
            
            if ($userRide) {
                event(new EventsRide("rider-user-$userId", 'LIVE_LOCATION', [
                    'ride'      => $userRide,
                    'latitude'  => $request->latitude,
                    'longitude' => $request->longitude,
                ]));
            }
        }

        $notify[] = "Location updated";
        return apiResponse("live_location", 'success', $notify);
    }
}
