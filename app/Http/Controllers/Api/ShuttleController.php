<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\ShuttleRoute;
use App\Models\Stop;
use App\Services\GoogleMapsService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class ShuttleController extends Controller
{
    protected $googleMapsService;

    public function __construct(GoogleMapsService $googleMapsService)
    {
        $this->googleMapsService = $googleMapsService;
    }

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
        $validator = Validator::make($request->all(), [
            'start_lat' => 'required|numeric',
            'start_lng' => 'required|numeric',
            'end_lat'   => 'required|numeric',
            'end_lng'   => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $startLat = $request->start_lat;
        $startLng = $request->start_lng;
        $endLat   = $request->end_lat;
        $endLng   = $request->end_lng;

        // Search radius in meters (e.g., 1000m = 1km)
        $radius = 1000;

        // 🔍 Find ALL nearby start stops
        $startStops = Stop::selectRaw("
            stops.*,
            ST_Distance_Sphere(
                point(longitude, latitude),
                point(?, ?)
            ) AS distance
        ", [$startLng, $startLat])
        ->having('distance', '<=', $radius)
        ->orderBy('distance')
        ->get();

        // 🔍 Find ALL nearby end stops
        $endStops = Stop::selectRaw("
            stops.*,
            ST_Distance_Sphere(
                point(longitude, latitude),
                point(?, ?)
            ) AS distance
        ", [$endLng, $endLat])
        ->having('distance', '<=', $radius)
        ->orderBy('distance')
        ->get();

        if ($startStops->isEmpty() || $endStops->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'No stops found near your location or destination.',
            ], 404);
        }

        $matchedRoutes = [];
        $startStopIds = $startStops->pluck('id')->toArray();
        $endStopIds = $endStops->pluck('id')->toArray();

        // 🔍 Find routes that have at least one start stop AND one end stop
        // AND where the start stop comes BEFORE the end stop
        $routes = ShuttleRoute::whereHas('stops', function ($q) use ($startStopIds) {
            $q->whereIn('stops.id', $startStopIds);
        })
        ->whereHas('stops', function ($q) use ($endStopIds) {
            $q->whereIn('stops.id', $endStopIds);
        })
        ->with(['stops' => function ($q) {
            $q->orderBy('pivot_order');
        }])
        ->get();

        foreach ($routes as $route) {
            // Find the best pair of stops for this route
            $bestStart = null;
            $bestEnd = null;
            $minDistance = floatval('inf');

            // Filter route stops to only those in our nearby lists
            $routeStartStops = $route->stops->whereIn('id', $startStopIds);
            $routeEndStops = $route->stops->whereIn('id', $endStopIds);

            foreach ($routeStartStops as $sStop) {
                foreach ($routeEndStops as $eStop) {
                    // Check order: Start must be before End
                    if ($sStop->pivot->order < $eStop->pivot->order) {
                        // Calculate total walking distance (start->stop + stop->end)
                        // We already have distance from user to stop in the 'distance' attribute from the query
                        // But we need to retrieve it from the original collections because relation loaded stops won't have it
                        $sDist = $startStops->firstWhere('id', $sStop->id)->distance;
                        $eDist = $endStops->firstWhere('id', $eStop->id)->distance;
                        $totalDist = $sDist + $eDist;

                        if ($totalDist < $minDistance) {
                            $minDistance = $totalDist;
                            $bestStart = $sStop;
                            $bestEnd = $eStop;
                        }
                    }
                }
            }

            if ($bestStart && $bestEnd) {
                $matchedRoutes[] = [
                    'route' => $route,
                    'start_stop' => $bestStart,
                    'end_stop' => $bestEnd,
                    'walking_distance' => $minDistance
                ];
            }
        }

        if (empty($matchedRoutes)) {
            return response()->json([
                'success' => false,
                'message' => 'No valid routes found connecting your locations.',
            ], 404);
        }

        // Sort by walking distance
        usort($matchedRoutes, function ($a, $b) {
            return $a['walking_distance'] <=> $b['walking_distance'];
        });

        return response()->json([
            'success'      => true,
            'matches'      => $matchedRoutes,
        ]);
    }

    /**
     * Create a new shuttle ride
     */
    public function create(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'route_id'            => 'required|integer',
            'start_stop_id'       => 'required|integer',
            'end_stop_id'         => 'required|integer',
            'number_of_passenger' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return apiResponse('validation_error', 'error', $validator->errors()->all());
        }

        // 1. Check for existing active ride
        $existsRide = \App\Models\Ride::where('user_id', auth()->id())
            ->whereIn('status', [\App\Constants\Status::RIDE_ACTIVE, \App\Constants\Status::RIDE_RUNNING])
            ->exists();

        if ($existsRide) {
            $notify[] = 'You can create a ride after finishing an ongoing ride.';
            return apiResponse("not_found", 'error', $notify);
        }

        try {
            DB::beginTransaction();

            // 2. Validate route and stops with lock for capacity check
            // Using lockForUpdate to prevent race conditions on capacity
            $route = ShuttleRoute::where('id', $request->route_id)->lockForUpdate()->first();

            if (!$route) {
                DB::rollBack();
                $notify[] = 'Invalid shuttle route.';
                return apiResponse('not_found', 'error', $notify);
            }

            // Check capacity
            $activePassengers = \App\Models\Ride::where('route_id', $route->id)
                ->where('status', \App\Constants\Status::RIDE_ACTIVE)
                ->sum('number_of_passenger');
            
            if (($activePassengers + $request->number_of_passenger) > $route->capacity) {
                DB::rollBack();
                $notify[] = 'Shuttle is full. Available seats: ' . ($route->capacity - $activePassengers);
                return apiResponse('validation_error', 'error', $notify);
            }

            // Load stops to validate
            $route->load('stops');
            $startStop = $route->stops->firstWhere('id', $request->start_stop_id);
            $endStop = $route->stops->firstWhere('id', $request->end_stop_id);

            if (!$startStop || !$endStop) {
                DB::rollBack();
                $notify[] = 'Selected stops do not belong to this route.';
                return apiResponse('not_found', 'error', $notify);
            }

            // Validate stop order
            if ($startStop->pivot->order >= $endStop->pivot->order) {
                DB::rollBack();
                $notify[] = 'End stop must come after start stop.';
                return apiResponse('validation_error', 'error', $notify);
            }

            // 3. Calculate distance and duration using Google Maps Service
            $googleMapData = $this->googleMapsService->getDistanceMatrix(
                $startStop->latitude,
                $startStop->longitude,
                $endStop->latitude,
                $endStop->longitude
            );

            if (!$googleMapData) {
                DB::rollBack();
                $notify[] = 'Unable to calculate route distance.';
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
                DB::rollBack();
                $notify[] = $zoneData['message'];
                return apiResponse('not_found', 'error', $notify);
            }

            // 5. Calculate pricing
            // Use route specific pricing if available, otherwise defaults
            $distance = $googleMapData['distance'];
            $basePrice = $route->base_price ?? 5.00;
            $pricePerKm = $route->price_per_km ?? 2.00;
            $amount = $basePrice + ($distance * $pricePerKm);
            
            // Multiply by passengers
            $totalAmount = $amount * $request->number_of_passenger;

            // 6. Create ride
            $ride = new \App\Models\Ride();
            $ride->uid                   = getTrx(10);
            $ride->user_id               = auth()->id();
            $ride->service_id            = 1; // Default service ID - Consider making this dynamic
            $ride->route_id              = $route->id;
            $ride->start_stop_id         = $startStop->id;
            $ride->end_stop_id           = $endStop->id;
            $ride->pickup_location       = $startStop->name;
            $ride->pickup_latitude       = $startStop->latitude;
            $ride->pickup_longitude      = $startStop->longitude;
            $ride->destination           = $endStop->name;
            $ride->destination_latitude  = $endStop->latitude;
            $ride->destination_longitude = $endStop->longitude;
            $ride->ride_type             = \App\Constants\Status::SHUTTLE_RIDE;
            $ride->status                = \App\Constants\Status::RIDE_ACTIVE;
            $ride->payment_type          = \App\Constants\Status::PAYMENT_TYPE_CASH; // TODO: Support other types
            $ride->distance              = $googleMapData['distance'];
            $ride->duration              = $googleMapData['duration'];
            $ride->number_of_passenger   = $request->number_of_passenger;
            $ride->pickup_zone_id        = $zoneData['pickup_zone']->id;
            $ride->destination_zone_id   = $zoneData['destination_zone']->id;
            $ride->recommend_amount      = $totalAmount;
            $ride->min_amount            = $totalAmount;
            $ride->max_amount            = $totalAmount;
            $ride->amount                = $totalAmount;
            $ride->commission_percentage = 10; // 10% commission
            $ride->otp                   = getNumber(4);
            $ride->driver_id             = 0; // No driver assigned yet
            $ride->save();

            DB::commit();
        } catch (\Exception $e) {
            DB::rollBack();
            $notify[] = 'Failed to create ride: ' . $e->getMessage();
            return apiResponse('server_error', 'error', $notify);
        }

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

