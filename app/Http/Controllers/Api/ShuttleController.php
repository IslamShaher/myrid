<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ShuttleRoute;
use App\Models\Stop;
use Illuminate\Support\Facades\DB;

class ShuttleController extends Controller
{
    /**
     * Fetch all shuttle routes with their stops in correct order
     */
    public function index()
    {
        $routes = ShuttleRoute::with(['stops' => function ($query) {
            $query->orderBy('pivot_order');
        }])->get();

        return response()->json([
            'success' => true,
            'routes' => $routes
        ]);
    }

    /**
     * Match nearest stops for start and end coordinates,
     * and find which shuttle routes contain BOTH stops.
     */
    public function matchRoute(Request $request)
    {
        $request->validate([
            'start_lat' => 'required|numeric',
            'start_lng' => 'required|numeric',
            'end_lat'   => 'required|numeric',
            'end_lng'   => 'required|numeric',
        ]);

        $startLat = $request->start_lat;
        $startLng = $request->start_lng;
        $endLat   = $request->end_lat;
        $endLng   = $request->end_lng;

        // 🔍 Find nearest start stop
        $startStop = Stop::selectRaw("
            stops.*,
            ST_Distance_Sphere(
                point(longitude, latitude),
                point(?, ?)
            ) AS distance
        ", [$startLng, $startLat])
        ->orderBy('distance')
        ->first();

        // 🔍 Find nearest end stop
        $endStop = Stop::selectRaw("
            stops.*,
            ST_Distance_Sphere(
                point(longitude, latitude),
                point(?, ?)
            ) AS distance
        ", [$endLng, $endLat])
        ->orderBy('distance')
        ->first();

        if (!$startStop || !$endStop) {
            return response()->json([
                'success' => false,
                'message' => 'No matching stops found.',
            ], 404);
        }

        // 🔍 Find all routes that contain BOTH stops
        $routes = ShuttleRoute::whereHas('stops', function ($q) use ($startStop) {
                $q->where('stops.id', $startStop->id);
            })
            ->whereHas('stops', function ($q) use ($endStop) {
                $q->where('stops.id', $endStop->id);
            })
            ->with(['stops' => function ($q) {
                $q->orderBy('pivot_order');
            }])
            ->get();

        return response()->json([
            'success'      => true,
            'start_stop'   => $startStop,
            'end_stop'     => $endStop,
            'matched_routes' => $routes,
        ]);
    }
    /**
     * Create a new shuttle ride
     */
    public function create(Request $request)
    {
        $request->validate([
            'route_id'            => 'required|integer',
            'start_stop_id'       => 'required|integer',
            'end_stop_id'         => 'required|integer',
            'number_of_passenger' => 'required|integer|min:1',
        ]);

        // 1. Check for existing active ride
        $existsRide = \App\Models\Ride::where('user_id', auth()->id())
            ->whereIn('status', [\App\Constants\Status::RIDE_ACTIVE, \App\Constants\Status::RIDE_RUNNING])
            ->exists();

        if ($existsRide) {
            $notify[] = 'You can create a ride after finishing an ongoing ride.';
            return apiResponse("not_found", 'error', $notify);
        }

        // 2. Validate route and stops
        $route = ShuttleRoute::with('stops')->find($request->route_id);
        if (!$route) {
            $notify[] = 'Invalid shuttle route.';
            return apiResponse('not_found', 'error', $notify);
        }

        $startStop = $route->stops->firstWhere('id', $request->start_stop_id);
        $endStop = $route->stops->firstWhere('id', $request->end_stop_id);

        if (!$startStop || !$endStop) {
            $notify[] = 'Selected stops do not belong to this route.';
            return apiResponse('not_found', 'error', $notify);
        }

        // Validate stop order
        if ($startStop->pivot->order >= $endStop->pivot->order) {
            $notify[] = 'End stop must come after start stop.';
            return apiResponse('validation_error', 'error', $notify);
        }

        // 3. Calculate distance and duration using Google Maps API
        $googleMapData = $this->getGoogleMapData(
            $startStop->latitude,
            $startStop->longitude,
            $endStop->latitude,
            $endStop->longitude
        );

        if (@$googleMapData['status'] == 'error') {
            $notify[] = $googleMapData['message'];
            return apiResponse('api_error', 'error', $notify);
        }

        // 4. Get zones
        $zoneData = $this->getZone(
            $startStop->latitude,
            $startStop->longitude,
            $endStop->latitude,
            $endStop->longitude
        );

        if (@$zoneData['status'] == 'error') {
            $notify[] = $zoneData['message'];
            return apiResponse('not_found', 'error', $notify);
        }

        // 5. Calculate pricing (fixed for shuttle, based on stops)
        $stopCount = $endStop->pivot->order - $startStop->pivot->order;
        $basePrice = 5.00;
        $pricePerStop = 2.00;
        $amount = $basePrice + ($stopCount * $pricePerStop);

        // 6. Create ride
        $ride = new \App\Models\Ride();
        $ride->uid                   = getTrx(10);
        $ride->user_id               = auth()->id();
        $ride->service_id            = 1; // Default service ID
        $ride->pickup_location       = $startStop->name;
        $ride->pickup_latitude       = $startStop->latitude;
        $ride->pickup_longitude      = $startStop->longitude;
        $ride->destination           = $endStop->name;
        $ride->destination_latitude  = $endStop->latitude;
        $ride->destination_longitude = $endStop->longitude;
        $ride->ride_type             = \App\Constants\Status::SHUTTLE_RIDE;
        $ride->status                = \App\Constants\Status::RIDE_ACTIVE;
        $ride->payment_type          = \App\Constants\Status::PAYMENT_TYPE_CASH;
        $ride->distance              = $googleMapData['distance'];
        $ride->duration              = $googleMapData['duration'];
        $ride->number_of_passenger   = $request->number_of_passenger;
        $ride->pickup_zone_id        = $zoneData['pickup_zone']->id;
        $ride->destination_zone_id   = $zoneData['destination_zone']->id;
        $ride->recommend_amount      = $amount;
        $ride->min_amount            = $amount;
        $ride->max_amount            = $amount;
        $ride->amount                = $amount;
        $ride->commission_percentage = 10; // 10% commission
        $ride->otp                   = getNumber(4);
        $ride->driver_id             = 0; // No driver assigned yet
        $ride->save();

        // 7. Send Pusher event to user
        event(new \App\Events\Ride("rider-user-{$ride->user_id}", "NEW_RIDE_CREATED", [
            'ride' => $ride,
        ]));

        // 8. Load relationships
        $ride->load('user', 'service');

        $notify[] = 'Shuttle ride booked successfully';
        return apiResponse('ride_create_success', 'success', $notify, [
            'ride' => $ride
        ]);
    }

    /**
     * Calculate distance and duration using Google Maps API
     */
    private function getGoogleMapData($startLat, $startLng, $endLat, $endLng)
    {
        $apiKey = env('GOOGLE_MAPS_API_KEY');
        $url = "https://maps.googleapis.com/maps/api/distancematrix/json?origins={$startLat},{$startLng}&destinations={$endLat},{$endLng}&units=driving&key={$apiKey}";
        
        $response = @file_get_contents($url);
        if (!$response) {
            return ['status' => 'error', 'message' => 'Unable to connect to Google Maps API.'];
        }

        $googleMapData = json_decode($response);

        if ($googleMapData->status != 'OK') {
            return ['status' => 'error', 'message' => 'Unable to calculate route distance.'];
        }

        if ($googleMapData->rows[0]->elements[0]->status == 'ZERO_RESULTS') {
            return ['status' => 'error', 'message' => 'Direction not found'];
        }

        $distance = $googleMapData->rows[0]->elements[0]->distance->value / 1000;
        $duration = $googleMapData->rows[0]->elements[0]->duration->text;

        return [
            'distance' => $distance,
            'duration' => $duration,
        ];
    }

    /**
     * Get zones for pickup and destination
     */
    private function getZone($pickupLat, $pickupLng, $destLat, $destLng)
    {
        $zones = \App\Models\Zone::active()->get();
        
        $pickupZone = null;
        foreach ($zones as $zone) {
            if (insideZone(['lat' => $pickupLat, 'long' => $pickupLng], $zone)) {
                $pickupZone = $zone;
                break;
            }
        }

        if (!$pickupZone) {
            return ['status' => 'error', 'message' => 'Pickup location is not inside any zone.'];
        }

        $destinationZone = null;
        foreach ($zones as $zone) {
            if (insideZone(['lat' => $destLat, 'long' => $destLng], $zone)) {
                $destinationZone = $zone;
                break;
            }
        }

        if (!$destinationZone) {
            return ['status' => 'error', 'message' => 'Destination location is not inside any zone.'];
        }

        return [
            'pickup_zone'      => $pickupZone,
            'destination_zone' => $destinationZone,
            'status'           => 'success'
        ];
    }
}

