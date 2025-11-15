<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ShuttleRoute;
use App\Models\Stop;
use Illuminate\Http\Request;

class ShuttleController extends Controller
{
    /**
     * Match a user trip (start/end lat/lng) to shuttle routes.
     */
    public function matchRoute(Request $request)
    {
        $request->validate([
            'start_lat' => 'required|numeric',
            'start_lng' => 'required|numeric',
            'end_lat'   => 'required|numeric',
            'end_lng'   => 'required|numeric',
        ]);

        $startLat = $request->input('start_lat');
        $startLng = $request->input('start_lng');
        $endLat   = $request->input('end_lat');
        $endLng   = $request->input('end_lng');

        // Haversine formula in SQL (distance in km)
        $nearestStart = Stop::select('*')
            ->selectRaw(
                "(
                    6371 * acos(
                        cos(radians(?)) * cos(radians(latitude)) *
                        cos(radians(longitude) - radians(?)) +
                        sin(radians(?)) * sin(radians(latitude))
                    )
                ) AS distance",
                [$startLat, $startLng, $startLat]
            )
            ->orderBy('distance')
            ->first();

        $nearestEnd = Stop::select('*')
            ->selectRaw(
                "(
                    6371 * acos(
                        cos(radians(?)) * cos(radians(latitude)) *
                        cos(radians(longitude) - radians(?)) +
                        sin(radians(?)) * sin(radians(latitude))
                    )
                ) AS distance",
                [$endLat, $endLng, $endLat]
            )
            ->orderBy('distance')
            ->first();

        if (!$nearestStart || !$nearestEnd) {
            return response()->json([
                'remark'  => 'no_stops',
                'status'  => 'error',
                'message' => ['No shuttle stops found'],
            ], 404);
        }

        // Routes that contain both nearestStart and nearestEnd
        $routes = ShuttleRoute::whereHas('stops', function ($q) use ($nearestStart) {
                $q->where('stops.id', $nearestStart->id);
            })
            ->whereHas('stops', function ($q) use ($nearestEnd) {
                $q->where('stops.id', $nearestEnd->id);
            })
            ->with(['stops'])
            ->get();

        return response()->json([
            'remark'  => 'shuttle_match',
            'status'  => 'success',
            'message' => ['Shuttle routes fetched successfully'],
            'data'    => [
                'nearest_start_stop' => $nearestStart,
                'nearest_end_stop'   => $nearestEnd,
                'routes'             => $routes,
            ],
        ]);
    }

    /**
     * List all stops.
     */
    public function stops()
    {
        $stops = Stop::all();

        return response()->json([
            'remark'  => 'stops',
            'status'  => 'success',
            'message' => ['Stops fetched successfully'],
            'data'    => $stops,
        ]);
    }

    /**
     * List all shuttle routes with stops.
     */
    public function routes()
    {
        $routes = ShuttleRoute::with('stops')->get();

        return response()->json([
            'remark'  => 'routes',
            'status'  => 'success',
            'message' => ['Routes fetched successfully'],
            'data'    => $routes,
        ]);
    }
}
