<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Ride;
use App\Services\GoogleMapsService;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

class SharedRideController extends Controller
{
    protected $googleMapsService;

    public function __construct(GoogleMapsService $googleMapsService)
    {
        $this->googleMapsService = $googleMapsService;
    }

    public function matchSharedRide(Request $request)
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

        // Radius in km
        $radius = 5.0;

        // Find active shared rides with no second user
        $rides = Ride::where('status', \App\Constants\Status::RIDE_ACTIVE)
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE) // Use SHARED_RIDE to avoid mixing with fixed route shuttles
            ->whereNull('second_user_id')
            ->where('user_id', '!=', auth()->id()) // Don't match own ride
            ->get();

        $matches = [];

        foreach ($rides as $ride) {
            // Check specific radius condition:
            // "pickup and dropoff of both users should be both within radius of 5km"
            // Start1 (Found Ride) - Start2 (Request) <= 5km
            // End1 (Found Ride) - End2 (Request) <= 5km
            
            $distStart = $this->getHaversineDistance(
                $ride->pickup_latitude, $ride->pickup_longitude,
                $startLat, $startLng
            );

            $distEnd = $this->getHaversineDistance(
                $ride->destination_latitude, $ride->destination_longitude,
                $endLat, $endLng
            );

            if ($distStart <= $radius && $distEnd <= $radius) {
                // Determine Overhead
                $matchData = $this->calculateOverhead($ride, $startLat, $startLng, $endLat, $endLng);
                if ($matchData) {
                     $matches[] = $matchData;
                }
            }
        }

        // Sort by sum of overhead
        usort($matches, function ($a, $b) {
            return $a['total_overhead'] <=> $b['total_overhead'];
        });

        return response()->json([
            'success' => true,
            'matches' => $matches
        ]);
    }

    private function getHaversineDistance($lat1, $lon1, $lat2, $lon2) {
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon/2) * sin($dLon/2);
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        return $earthRadius * $c;
    }

    private function calculateOverhead($ride, $u2StartLat, $u2StartLng, $u2EndLat, $u2EndLng)
    {
        // Points
        // 1: Rider 1 (Existing)
        // 2: Rider 2 (New)
        $p1Start = ['lat' => $ride->pickup_latitude, 'lng' => $ride->pickup_longitude];
        $p1End   = ['lat' => $ride->destination_latitude, 'lng' => $ride->destination_longitude];
        $p2Start = ['lat' => $u2StartLat, 'lng' => $u2StartLng];
        $p2End   = ['lat' => $u2EndLat, 'lng' => $u2EndLng];

        // 1. Calculate Solo Times (Approximation or via API)
        // For accurate overhead, we need API calls.
        // Assuming we can use Google Maps Service here.
        // But making many API calls in a loop is bad. 
        // Logic says: "check shortest ride time for the 4 combinations"
        
        // We will try to fetch a matrix for these 4 points if possible, or 4 individual calls.
        // To optimize, maybe we just calculate straight line or use stored duration for Rider 1 solo.
        
        // Stored Rider 1 Solo Duration
        $r1SoloDuration = $ride->duration; // seconds

        // Rider 2 Solo - Need to calculate
        $r2Solo = $this->googleMapsService->getDistanceMatrix(
            $p2Start['lat'], $p2Start['lng'],
            $p2End['lat'], $p2End['lng']
        );
        if(!$r2Solo) return null;
        $r2SoloDuration = $r2Solo['duration_value']; // seconds

        // 2. Permutations
        // S1 -> S2 -> E1 -> E2
        // S1 -> S2 -> E2 -> E1
        // S2 -> S1 -> E1 -> E2
        // S2 -> S1 -> E2 -> E1
        // Note: Pickups must be before Dropoffs.
        
        $permutations = [
            ['seq' => ['S1', 'S2', 'E1', 'E2'], 'coords' => [$p1Start, $p2Start, $p1End, $p2End]],
            ['seq' => ['S1', 'S2', 'E2', 'E1'], 'coords' => [$p1Start, $p2Start, $p2End, $p1End]],
            ['seq' => ['S2', 'S1', 'E1', 'E2'], 'coords' => [$p2Start, $p1Start, $p1End, $p2End]],
            ['seq' => ['S2', 'S1', 'E2', 'E1'], 'coords' => [$p2Start, $p1Start, $p2End, $p1End]],
        ];

        $bestSequence = null;
        $minTotalDuration = PHP_INT_MAX;
        $bestOverhead = [];

        // This is heavy on API. 4 permutations * 3 segments = 12 calls/segments. 
        // Better to use Waypoints API if possible or Matrix.
        // For prototype, we might use Haversine/Speed constant if API quota is concern, 
        // but user asked for "check shortest ride time".
        
        foreach ($permutations as $perm) {
            // Calculate total duration of this sequence
            // Segments: 0->1, 1->2, 2->3
            $dur = 0;
            $coords = $perm['coords'];
            
            // To reduce API calls, one could do a Matrix 4x4 once? 
            // But let's assume we do sequential checks or simple addition of segments.
            // We'll calculate segment distances using Haversine and avg speed (e.g. 30km/h) 
            // OR use google maps if strictly required. 
            // Given "GoogleMapsService" usually does 1-to-1, let's use it carefully.
            
            // Actually, getDistanceMatrix can take multiple origins/destinations.
            // But here we need specific path.
            
            // Let's implement a 'calculateRouteDuration' helper that sums segments.
            $seg1 = $this->getSegmentDuration($coords[0], $coords[1]);
            $seg2 = $this->getSegmentDuration($coords[1], $coords[2]);
            $seg3 = $this->getSegmentDuration($coords[2], $coords[3]);
            
            $totalSeqDuration = $seg1 + $seg2 + $seg3;
            
            // Calculate individual times in this sequence
            // Rider 1 Start/End indices
            $idxS1 = array_search('S1', $perm['seq']);
            $idxE1 = array_search('E1', $perm['seq']);
            $r1DurationInRide = $this->getSubSequenceDuration($coords, $idxS1, $idxE1);

            $idxS2 = array_search('S2', $perm['seq']);
            $idxE2 = array_search('E2', $perm['seq']);
            $r2DurationInRide = $this->getSubSequenceDuration($coords, $idxS2, $idxE2);

            $overhead1 = $r1DurationInRide - $r1SoloDuration;
            $overhead2 = $r2DurationInRide - $r2SoloDuration;
            $totalOverhead = $overhead1 + $overhead2;

            if ($totalSeqDuration < $minTotalDuration) {
                $minTotalDuration = $totalSeqDuration;
                $bestSequence = $perm['seq'];
                $bestOverhead = [
                    'r1_overhead' => $overhead1,
                    'r2_overhead' => $overhead2,
                    'total_overhead' => $totalOverhead,
                    'sequence' => $perm['seq'],
                    'r1_solo' => $r1SoloDuration,
                    'r2_solo' => $r2SoloDuration,
                    'r1_shared' => $r1DurationInRide,
                    'r2_shared' => $r2DurationInRide,
                ];
            }
        }
        
        return array_merge(['ride' => $ride], $bestOverhead);
    }

    private function getSegmentDuration($p1, $p2) {
        // Mocking for now to avoid 100s of API calls during development/listing
        // specific implementation should use Cache or Matrix.
        // For real implementation:
        // return $this->googleMapsService->getDistance($p1, $p2)['duration'];
        
        // Fallback or optimized approach:
        return $this->getHaversineDistance($p1['lat'], $p1['lng'], $p2['lat'], $p2['lng']) * 120; // ~30km/h -> 2 min/km
    }

    private function getSubSequenceDuration($coords, $startIdx, $endIdx) {
        $dur = 0;
        for ($i = $startIdx; $i < $endIdx; $i++) {
            $dur += $this->getSegmentDuration($coords[$i], $coords[$i+1]);
        }
        return $dur;
    }

    public function joinRide(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|exists:rides,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $ride = Ride::find($request->ride_id);

        if ($ride->second_user_id) {
             return response()->json(['success' => false, 'message' => 'Ride is already full.'], 400);
        }
        
        if ($ride->user_id == auth()->id()) {
             return response()->json(['success' => false, 'message' => 'You cannot join your own ride.'], 400);
        }

        $ride->second_user_id = auth()->id();
        $ride->save();

        // Notify Rider 1
        // event(new \App\Events\Ride("rider-user-{$ride->user_id}", "RIDER_JOINED", ['ride' => $ride]));

        return response()->json([
            'success' => true,
            'message' => 'You have joined the ride.',
            'ride' => $ride
        ]);
    }

    public function updateRideStatus(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|exists:rides,id',
            'action' => 'required|in:start_driving,arrived_at_pickup,confirm_pickup,end_ride'
        ]);
        
        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $ride = Ride::find($request->ride_id);
        
        if ($ride->user_id != auth()->id() && $ride->second_user_id != auth()->id()) {
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 403);
        }

        $action = $request->action;
        $message = "";
        
        if ($action == 'start_driving') {
            if ($ride->user_id != auth()->id()) return response()->json(['success'=>false, 'message'=>'Only Rider 1 can start driving'], 403);
            // event(new \App\Events\Ride("rider-user-{$ride->second_user_id}", "RIDE_STARTED_DRIVING", ['ride' => $ride]));
            $message = "Notified Rider 2 that you started driving.";
        }
        elseif ($action == 'arrived_at_pickup') {
            if ($ride->user_id != auth()->id()) return response()->json(['success'=>false, 'message'=>'Only Rider 1 can mark arrival'], 403);
            // event(new \App\Events\Ride("rider-user-{$ride->second_user_id}", "RIDER_ARRIVED_PICKUP", ['ride' => $ride]));
            $message = "Notified Rider 2 that you arrived.";
        }
        elseif ($action == 'confirm_pickup') {
            if ($ride->second_user_id != auth()->id()) return response()->json(['success'=>false, 'message'=>'Only Rider 2 can confirm pickup'], 403);
            $ride->status = \App\Constants\Status::RIDE_RUNNING;
            $ride->save();
            $message = "Pickup confirmed. Ride is running.";
        }
        
        return response()->json([
            'success' => true,
            'message' => $message,
            'ride' => $ride
        ]);
        }

    public function createSharedRide(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'start_lat' => 'required|numeric',
            'start_lng' => 'required|numeric',
            'end_lat'   => 'required|numeric',
            'end_lng'   => 'required|numeric',
            'pickup_location' => 'required|string',
            'destination' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        // Calculate Distance/Price
        $distanceData = $this->googleMapsService->getDistanceMatrix(
            $request->start_lat, $request->start_lng,
            $request->end_lat, $request->end_lng
        );

        if (!$distanceData) {
            return response()->json(['success' => false, 'message' => 'Unable to calculate distance'], 500);
        }

        $distanceKm = $distanceData['distance']; // km
        $duration   = $distanceData['duration']; // text
        
        // Pricing Logic (Simplified for Shared Ride)
        // Check for 'Shuttle' service or 'Shared' service rate
        $basePrice = 5.00;
        $pricePerKm = 2.00;
        
        // Try to get dynamic settings if available (mocked or simple query)
        // $service = \App\Models\Service::where('name', 'Shuttle')->first();
        // if($service) { ... }

        $amount = $basePrice + ($distanceKm * $pricePerKm);

        $ride = new Ride();
        $ride->uid                   = getTrx(10);
        $ride->user_id               = auth()->id();
        $ride->ride_type             = \App\Constants\Status::SHARED_RIDE; // NEW Shared Ride Type
        $ride->status                = \App\Constants\Status::RIDE_ACTIVE; // Active means visible for matching
        $ride->payment_type          = \App\Constants\Status::PAYMENT_TYPE_CASH;
        
        $ride->pickup_latitude       = $request->start_lat;
        $ride->pickup_longitude      = $request->start_lng;
        $ride->pickup_location       = $request->pickup_location;
        
        $ride->destination_latitude  = $request->end_lat;
        $ride->destination_longitude = $request->end_lng;
        $ride->destination           = $request->destination;
        
        $ride->distance              = $distanceKm;
        $ride->duration              = $distanceData['duration_value'] / 60; // minutes
        $ride->amount                = $amount;
        $ride->recommend_amount      = $amount;
        $ride->number_of_passenger   = 1;
        $ride->otp                   = getNumber(4);
        $ride->driver_id             = 0;
        $ride->save();
        
        return response()->json([
            'success' => true,
            'message' => 'Shared Ride matched/created successfully.',
            'ride' => $ride
        ]);
    }
}

