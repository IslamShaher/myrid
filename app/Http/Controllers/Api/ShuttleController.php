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
            'route_id'      => 'required|integer',
            'start_stop_id' => 'required|integer',
            'end_stop_id'   => 'required|integer',
        ]);

        $route = ShuttleRoute::find($request->route_id);
        $startStop = Stop::find($request->start_stop_id);
        $endStop = Stop::find($request->end_stop_id);

        if (!$route || !$startStop || !$endStop) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid route or stops.',
            ], 404);
        }

        // Create Ride
        $ride = new \App\Models\Ride();
        $ride->uid                   = getTrx(10);
        $ride->user_id               = auth()->id();
        $ride->service_id            = 1; // Default service ID for now, or fetch a shuttle service
        $ride->pickup_location       = $startStop->name;
        $ride->pickup_latitude       = $startStop->latitude;
        $ride->pickup_longitude      = $startStop->longitude;
        $ride->destination           = $endStop->name;
        $ride->destination_latitude  = $endStop->latitude;
        $ride->destination_longitude = $endStop->longitude;
        $ride->ride_type             = \App\Constants\Status::SHUTTLE_RIDE;
        $ride->status                = \App\Constants\Status::RIDE_ACTIVE;
        $ride->payment_type          = \App\Constants\Status::PAYMENT_TYPE_CASH;
        $ride->amount                = 10.00; // Fixed price for demo
        $ride->otp                   = getNumber(4);
        $ride->driver_id             = 0; // No driver assigned yet
        $ride->save();

        return response()->json([
            'success' => true,
            'message' => 'Shuttle ride booked successfully',
            'ride'    => $ride,
        ]);
    }
}

