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
            'scheduled_time' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $startLat = $request->start_lat;
        $startLng = $request->start_lng;
        $endLat   = $request->end_lat;
        $endLng   = $request->end_lng;
        
        // Get requested scheduled time (default to now)
        $requestedTime = $request->has('scheduled_time') && $request->scheduled_time 
            ? Carbon::parse($request->scheduled_time) 
            : Carbon::now();

        // Radius in km
        $radius = 5.0;
        
        // Time window: ±40 minutes
        $timeWindowMinutes = 40;
        $timeWindowStart = $requestedTime->copy()->subMinutes($timeWindowMinutes);
        $timeWindowEnd = $requestedTime->copy()->addMinutes($timeWindowMinutes);

        // Find active shared rides with no second user, matching time window
        $rides = Ride::where('status', \App\Constants\Status::RIDE_ACTIVE)
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
            ->whereNull('second_user_id')
            ->where('user_id', '!=', auth()->id()) // Don't match own ride
            ->whereBetween('scheduled_time', [$timeWindowStart, $timeWindowEnd])
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
                    // Calculate estimated pickup time for user 2
                    // Time = ride scheduled_time + cumulative travel time to reach user 2's pickup point
                    $rideScheduledTime = $ride->scheduled_time ? Carbon::parse($ride->scheduled_time) : Carbon::now();
                    
                    // Calculate cumulative travel time to S2 based on sequence
                    $sequence = $matchData['sequence'] ?? [];
                    if (!empty($sequence)) {
                        $s2Index = array_search('S2', $sequence);
                        $s1Index = array_search('S1', $sequence);
                        
                        if ($s2Index !== false && $s1Index !== false && $s2Index > $s1Index) {
                            // S2 comes after S1 - calculate time from S1 to S2
                            $travelTimeData = $this->googleMapsService->getDistanceMatrix(
                                $ride->pickup_latitude, $ride->pickup_longitude,
                                $startLat, $startLng
                            );
                            
                            if ($travelTimeData) {
                                $travelTimeSeconds = $travelTimeData['duration_value'] ?? 0;
                                $estimatedPickupTime = $rideScheduledTime->copy()->addSeconds($travelTimeSeconds);
                                $matchData['estimated_pickup_time'] = $estimatedPickupTime->toIso8601String();
                                $matchData['estimated_pickup_time_readable'] = $estimatedPickupTime->format('H:i');
                            }
                        } elseif ($s2Index !== false && $s1Index !== false && $s2Index < $s1Index) {
                            // S2 comes before S1 - user 2 will be picked up first (shouldn't happen often)
                            // For now, estimate based on travel from ride start to S2
                            // Actually, if S2 is first, the scheduled time might represent when S2 should be picked up
                            // But since Rider 1 created the ride, we assume they start at their location
                            $travelTimeData = $this->googleMapsService->getDistanceMatrix(
                                $ride->pickup_latitude, $ride->pickup_longitude,
                                $startLat, $startLng
                            );
                            
                            if ($travelTimeData) {
                                $travelTimeSeconds = $travelTimeData['duration_value'] ?? 0;
                                // If S2 is first, pickup might be before scheduled time (rider 1 leaves early)
                                // For simplicity, use scheduled time as baseline
                                $estimatedPickupTime = $rideScheduledTime->copy()->addSeconds($travelTimeSeconds);
                                $matchData['estimated_pickup_time'] = $estimatedPickupTime->toIso8601String();
                                $matchData['estimated_pickup_time_readable'] = $estimatedPickupTime->format('H:i');
                            }
                        }
                        
                        // Get directions for the complete route with all 4 points
                        $waypoints = [];
                        $pointMap = [
                            'S1' => ['lat' => $ride->pickup_latitude, 'lng' => $ride->pickup_longitude],
                            'E1' => ['lat' => $ride->destination_latitude, 'lng' => $ride->destination_longitude],
                            'S2' => ['lat' => $startLat, 'lng' => $startLng],
                            'E2' => ['lat' => $endLat, 'lng' => $endLng],
                        ];
                        
                        foreach ($sequence as $code) {
                            $waypoints[] = $pointMap[$code];
                        }
                        
                        $directionsData = $this->googleMapsService->getDirectionsWithWaypoints($waypoints);
                        if ($directionsData) {
                            $matchData['directions'] = $directionsData;
                        }
                    }
                    
                    // Also include ride scheduled time
                    $matchData['ride_scheduled_time'] = $rideScheduledTime->toIso8601String();
                    $matchData['ride_scheduled_time_readable'] = $rideScheduledTime->format('M d, Y H:i');
                    
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
        $r1SoloDuration = $ride->duration * 60; // Convert minutes to seconds
        $r1SoloDistance = $ride->distance; // km

        // Rider 2 Solo - Need to calculate
        $r2Solo = $this->googleMapsService->getDistanceMatrix(
            $p2Start['lat'], $p2Start['lng'],
            $p2End['lat'], $p2End['lng']
        );
        if(!$r2Solo) return null;
        $r2SoloDuration = $r2Solo['duration_value']; // seconds
        $r2SoloDistance = $r2Solo['distance']; // km

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
        
        $pricePerKm = 2.00; // Configurable
        
        foreach ($permutations as $perm) {
            // Calculate total duration of this sequence
            $dur = 0;
            $coords = $perm['coords'];
            
            // Segment Calculations with Fare Logic
            $seq = $perm['seq'];
            $activeRiders = []; // Track who is in the car
            
            $r1Cost = 0;
            $r2Cost = 0;
            $totalSeqDuration = 0;

            // Initialize riders at start point
            // The loop iterates segments between points.
            // Point 0 (Start of ride) -> Add Rider
            // Point 0 -> Point 1 is Segment 1.
            
            // We need to know who is in the car for each segment.
            // Logic:
            // 1. Process point i action (Pickup/Dropoff) -> Update activeRiders
            // 2. BUT activeRiders applies to the segment AFTER the point? 
            //    No, for "S1->S2", S1 is pickup. So R1 is in car for S1->S2.
            
            // Let's track existing riders before segment starts.
            
            for ($i = 0; $i < 3; $i++) {
                $pStart = $seq[$i];   // Code e.g. 'S1'
                $pEnd   = $seq[$i+1]; // Code e.g. 'S2'
                
                // Update riders based on pStart
                if (str_contains($pStart, 'S')) { // Pickup
                     $riderIdx = str_contains($pStart, '1') ? 1 : 2;
                     if (!in_array($riderIdx, $activeRiders)) $activeRiders[] = $riderIdx;
                }
                if (str_contains($pStart, 'E')) { // Dropoff
                     $riderIdx = str_contains($pStart, '1') ? 1 : 2;
                     $activeRiders = array_diff($activeRiders, [$riderIdx]);
                }
                
                // Calculate Segment Distance/Duration
                $segDur = $this->getSegmentDuration($coords[$i], $coords[$i+1]); // seconds?
                // Convert duration to distance approx (since getSegmentDuration returns seconds-based-value in current mock)
                // Current mock: Haversine * 120 (2 min/km). So Dist = Dur / 120.
                $segDistKm = $segDur / 120.0;
                $segPrice = $segDistKm * $pricePerKm;
                
                $totalSeqDuration += $segDur;
                
                // Distribute Cost
                $count = count($activeRiders);
                if ($count > 0) {
                    $costPerRider = $segPrice / $count;
                    if (in_array(1, $activeRiders)) $r1Cost += $costPerRider;
                    if (in_array(2, $activeRiders)) $r2Cost += $costPerRider;
                }
            }
            
            // Calculate individual times for overhead check
            $idxS1 = array_search('S1', $seq);
            $idxE1 = array_search('E1', $seq);
            $r1DurationInRide = $this->getSubSequenceDuration($coords, $idxS1, $idxE1);

            $idxS2 = array_search('S2', $seq);
            $idxE2 = array_search('E2', $seq);
            $r2DurationInRide = $this->getSubSequenceDuration($coords, $idxS2, $idxE2);

            $overhead1 = $r1DurationInRide - $r1SoloDuration;
            $overhead2 = $r2DurationInRide - $r2SoloDuration;
            $totalOverhead = $overhead1 + $overhead2;

            if ($totalSeqDuration < $minTotalDuration) {
                $minTotalDuration = $totalSeqDuration;
                $bestSequence = $seq;
                $bestOverhead = [
                    'r1_overhead' => round($overhead1 / 60, 1), // Convert to minutes
                    'r2_overhead' => round($overhead2 / 60, 1), // Convert to minutes
                    'total_overhead' => round($totalOverhead / 60, 1), // Convert to minutes
                    'sequence' => $seq,
                    'r1_solo' => $r1SoloDuration,
                    'r2_solo' => $r2SoloDuration,
                    'r1_shared' => $r1DurationInRide,
                    'r2_shared' => $r2DurationInRide,
                    'r1_fare' => round($r1Cost, 2),
                    'r2_fare' => round($r2Cost, 2),
                ];
            }
        }
        
        // Add Base Fare to both? Or split base fare? 
        // Usually base fare is per rider.
        $baseFare = 5.00;
        $pricePerKm = 2.00;
        if(isset($bestOverhead)) {
            $bestOverhead['r1_fare'] += $baseFare;
            $bestOverhead['r2_fare'] += $baseFare;
            
            // Calculate solo fares for savings calculation
            $r1SoloFare = $baseFare + ($r1SoloDistance * $pricePerKm);
            $r2SoloFare = $baseFare + ($r2SoloDistance * $pricePerKm);
            $bestOverhead['r1_solo_fare'] = round($r1SoloFare, 2);
            $bestOverhead['r2_solo_fare'] = round($r2SoloFare, 2);
        }
        
        return array_merge(['ride' => $ride], $bestOverhead ?? []);
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
            'start_lat' => 'nullable|numeric',
            'start_lng' => 'nullable|numeric',
            'end_lat' => 'nullable|numeric',
            'end_lng' => 'nullable|numeric',
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
        
        // Store Rider 2's coordinates if provided (for map display)
        if ($request->has('start_lat') && $request->has('start_lng') && 
            $request->has('end_lat') && $request->has('end_lng')) {
            // Store in a JSON field or separate columns
            // For now, we'll use a JSON approach or add columns
            // Since we don't have columns, let's calculate and store the sequence
            $u2StartLat = $request->start_lat;
            $u2StartLng = $request->start_lng;
            $u2EndLat = $request->end_lat;
            $u2EndLng = $request->end_lng;
            
            // Calculate the best sequence and store it
            $matchData = $this->calculateOverhead($ride, $u2StartLat, $u2StartLng, $u2EndLat, $u2EndLng);
            if ($matchData && isset($matchData['sequence'])) {
                // Store sequence as JSON in a field (we'll add a migration for this)
                // For now, store in a JSON column if it exists, otherwise we'll add it
                $ride->second_pickup_latitude = $u2StartLat;
                $ride->second_pickup_longitude = $u2StartLng;
                $ride->second_destination_latitude = $u2EndLat;
                $ride->second_destination_longitude = $u2EndLng;
                $ride->shared_ride_sequence = json_encode($matchData['sequence']);
                
                // Get and save directions data for the complete route
                $waypoints = [];
                $pointMap = [
                    'S1' => ['lat' => $ride->pickup_latitude, 'lng' => $ride->pickup_longitude],
                    'E1' => ['lat' => $ride->destination_latitude, 'lng' => $ride->destination_longitude],
                    'S2' => ['lat' => $u2StartLat, 'lng' => $u2StartLng],
                    'E2' => ['lat' => $u2EndLat, 'lng' => $u2EndLng],
                ];
                
                foreach ($matchData['sequence'] as $code) {
                    $waypoints[] = $pointMap[$code];
                }
                
                $directionsData = $this->googleMapsService->getDirectionsWithWaypoints($waypoints);
                if ($directionsData) {
                    $ride->directions_data = json_encode($directionsData);
                }
            }
        }
        
        $ride->save();

        // Load the joining user (Rider 2) with details for notification
        $rider2 = \App\Models\User::find(auth()->id());
        $rider1 = \App\Models\User::find($ride->user_id);
        
        // Prepare rider name and rating for notifications
        $riderName = 'A rider';
        $riderRating = '0.0';
        
        if ($rider2) {
            $riderName = trim(($rider2->firstname ?? '') . ' ' . ($rider2->lastname ?? ''));
            if (empty($riderName)) {
                $riderName = $rider2->username ?? 'A rider';
            }
            $riderRating = number_format($rider2->avg_rating ?? 0, 1);
        }
        
        // Notify Rider 1 with push notification including Rider 2 details
        // Note: For push notification to work, DEFAULT template must exist in notification_templates table
        // with push_status enabled. Otherwise, only Pusher event will be sent.
        if ($rider1) {
            $shortCodes = [
                'subject' => 'New Rider Joined Your Shared Ride',
                'message' => "{$riderName} (Rating: {$riderRating}) has joined your shared ride.",
            ];
            // Try to send push notification (will only work if DEFAULT template exists)
            try {
                notify($rider1, 'DEFAULT', $shortCodes, ['push']);
            } catch (\Exception $e) {
                // If notification fails, Pusher event will still notify the user
            }
        }
        
        // Also send Pusher events for real-time update
        // Send to Rider 1's user channel
        event(new \App\Events\Ride("rider-user-{$ride->user_id}", "RIDER_JOINED", [
            'ride' => $ride->load(['user', 'secondUser']),
            'message' => "{$riderName} has joined your ride!"
        ]));
        
        // Also send to the ride channel itself
        event(new \App\Events\Ride("ride-{$ride->id}", "RIDER_JOINED", [
            'ride' => $ride->load(['user', 'secondUser']),
            'message' => "{$riderName} has joined your ride!"
        ]));

        return response()->json([
            'success' => true,
            'message' => ['You have joined the ride.'],
            'ride' => $ride->load('secondUser')
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
            event(new \App\Events\Ride("rider-user-{$ride->second_user_id}", "RIDE_STARTED_DRIVING", ['ride' => $ride]));
            $message = "Notified Rider 2 that you started driving.";
        }
        elseif ($action == 'arrived_at_pickup') {
            if ($ride->user_id != auth()->id()) return response()->json(['success'=>false, 'message'=>'Only Rider 1 can mark arrival'], 403);
            event(new \App\Events\Ride("rider-user-{$ride->second_user_id}", "RIDER_ARRIVED_PICKUP", ['ride' => $ride]));
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
            'is_scheduled' => 'nullable|boolean',
            'scheduled_time' => 'nullable|date',
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
        
        // Handle scheduling
        $ride->is_scheduled = $request->has('is_scheduled') && $request->is_scheduled;
        if ($ride->is_scheduled && $request->has('scheduled_time') && $request->scheduled_time) {
            $ride->scheduled_time = Carbon::parse($request->scheduled_time);
        } else {
            // Default to now if not scheduled
            $ride->is_scheduled = false;
            $ride->scheduled_time = Carbon::now();
        }
        
        $ride->save();
        
        // Different message for scheduled rides
        $message = $ride->is_scheduled && $ride->scheduled_time > Carbon::now()
            ? 'Your ride has been created. You\'ll receive a notification when a match is found.'
            : 'Shared Ride matched/created successfully.';
        
        return response()->json([
            'success' => true,
            'message' => [$message], // Changed to array to match Flutter AuthorizationResponseModel
            'ride' => $ride,
            'is_scheduled' => $ride->is_scheduled,
            'should_return_to_home' => $ride->is_scheduled && $ride->scheduled_time > Carbon::now() && !$ride->second_user_id
        ]);
    }

    public function activeSharedRide(Request $request)
    {
        try {
            // Check if user is rider 1 (created the ride) or rider 2 (joined the ride)
            $ride = Ride::where(function($query) {
                    $query->where('user_id', auth()->id())
                          ->orWhere('second_user_id', auth()->id());
                })
                ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
                ->whereIn('status', [\App\Constants\Status::RIDE_ACTIVE, \App\Constants\Status::RIDE_RUNNING])
                ->with('user', 'service', 'secondUser')
                ->first();

            if ($ride) {
                // If we have Rider 2's coordinates, calculate and include sequence info
                $responseData = $ride->toArray();
                
                if ($ride->second_user_id && 
                    $ride->second_pickup_latitude && 
                    $ride->second_pickup_longitude &&
                    $ride->second_destination_latitude &&
                    $ride->second_destination_longitude) {
                    // Recalculate sequence if not stored, or use stored one
                    if ($ride->shared_ride_sequence) {
                        $responseData['shared_ride_sequence'] = json_decode($ride->shared_ride_sequence, true);
                    } else {
                        // Recalculate
                        $matchData = $this->calculateOverhead(
                            $ride,
                            $ride->second_pickup_latitude,
                            $ride->second_pickup_longitude,
                            $ride->second_destination_latitude,
                            $ride->second_destination_longitude
                        );
                        if ($matchData && isset($matchData['sequence'])) {
                            $responseData['shared_ride_sequence'] = $matchData['sequence'];
                        }
                    }
                    
                    // Decode and include directions_data if it exists
                    if ($ride->directions_data) {
                        $responseData['directions_data'] = json_decode($ride->directions_data, true);
                    } else {
                        // If directions_data doesn't exist, generate it now
                        // This ensures both devices have directions when ride starts
                        $waypoints = [];
                        $pointMap = [
                            'S1' => ['lat' => $ride->pickup_latitude, 'lng' => $ride->pickup_longitude],
                            'E1' => ['lat' => $ride->destination_latitude, 'lng' => $ride->destination_longitude],
                            'S2' => ['lat' => $ride->second_pickup_latitude, 'lng' => $ride->second_pickup_longitude],
                            'E2' => ['lat' => $ride->second_destination_latitude, 'lng' => $ride->second_destination_longitude],
                        ];
                        
                        $sequence = $responseData['shared_ride_sequence'] ?? ['S1', 'S2', 'E1', 'E2'];
                        foreach ($sequence as $code) {
                            if (isset($pointMap[$code])) {
                                $waypoints[] = $pointMap[$code];
                            }
                        }
                        
                        if (count($waypoints) == 4) {
                            $directionsData = $this->googleMapsService->getDirectionsWithWaypoints($waypoints);
                            if ($directionsData) {
                                $ride->directions_data = json_encode($directionsData);
                                $ride->save();
                                $responseData['directions_data'] = $directionsData;
                            }
                        }
                    }
                }
                
                return response()->json([
                    'success' => true,
                    'data' => $responseData
                ]);
            }

            return response()->json([
                'success' => false,
                'message' => 'No active shared ride found.'
            ], 404);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error fetching active ride: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get pending shared rides (rides without second user)
     */
    public function getPendingSharedRides(Request $request)
    {
        try {
            $rides = Ride::where('ride_type', \App\Constants\Status::SHARED_RIDE)
                ->where(function($query) {
                    $query->where('user_id', auth()->id())
                          ->orWhere('second_user_id', auth()->id());
                })
                ->where('status', \App\Constants\Status::RIDE_ACTIVE)
                ->whereNull('second_user_id')
                ->with('user')
                ->orderBy('created_at', 'desc')
                ->get();

            $ridesData = $rides->map(function($ride) {
                return [
                    'id' => $ride->id,
                    'uid' => $ride->uid,
                    'pickup_location' => $ride->pickup_location,
                    'destination' => $ride->destination,
                    'pickup_latitude' => $ride->pickup_latitude,
                    'pickup_longitude' => $ride->pickup_longitude,
                    'destination_latitude' => $ride->destination_latitude,
                    'destination_longitude' => $ride->destination_longitude,
                    'distance' => $ride->distance,
                    'duration' => $ride->duration,
                    'amount' => $ride->amount,
                    'is_scheduled' => $ride->is_scheduled,
                    'scheduled_time' => $ride->scheduled_time ? $ride->scheduled_time->toIso8601String() : null,
                    'scheduled_time_readable' => $ride->scheduled_time ? $ride->scheduled_time->format('M d, Y H:i') : null,
                    'created_at' => $ride->created_at->toIso8601String(),
                    'user' => [
                        'id' => $ride->user->id,
                        'firstname' => $ride->user->firstname,
                        'lastname' => $ride->user->lastname,
                        'username' => $ride->user->username,
                        'image' => $ride->user->image,
                        'rating' => $ride->user->rating ?? 0,
                    ]
                ];
            });

            return response()->json([
                'success' => true,
                'rides' => $ridesData
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'An error occurred: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get confirmed shared rides (rides with second user but ride hasn't started yet)
     */
    public function getConfirmedSharedRides(Request $request)
    {
        try {
            $now = Carbon::now();
            $rides = Ride::where('ride_type', \App\Constants\Status::SHARED_RIDE)
                ->where(function($query) {
                    $query->where('user_id', auth()->id())
                          ->orWhere('second_user_id', auth()->id());
                })
                ->where('status', \App\Constants\Status::RIDE_ACTIVE)
                ->whereNotNull('second_user_id')
                ->where(function($query) use ($now) {
                    $query->whereNull('scheduled_time')
                          ->orWhere('scheduled_time', '>', $now);
                })
                ->with('user', 'secondUser')
                ->orderBy('scheduled_time', 'asc')
                ->get();

            $currentUserId = auth()->id();
            $ridesData = $rides->map(function($ride) use ($currentUserId) {
                // Determine if current user is rider 1 or rider 2
                $isRider1 = $ride->user_id == $currentUserId;
                $otherUser = $isRider1 ? $ride->secondUser : $ride->user;
                
                // Calculate estimated pickup time for current user
                $estimatedPickupTime = null;
                $estimatedPickupTimeReadable = null;
                
                if ($ride->scheduled_time && $ride->shared_ride_sequence) {
                    $sequence = json_decode($ride->shared_ride_sequence, true);
                    if ($sequence && is_array($sequence)) {
                        $rideScheduledTime = Carbon::parse($ride->scheduled_time);
                        
                        // Find when current user's pickup (S1 or S2) comes in sequence
                        $userPickupCode = $isRider1 ? 'S1' : 'S2';
                        $otherPickupCode = $isRider1 ? 'S2' : 'S1';
                        
                        $userPickupIndex = array_search($userPickupCode, $sequence);
                        $otherPickupIndex = array_search($otherPickupCode, $sequence);
                        
                        if ($userPickupIndex !== false && $otherPickupIndex !== false) {
                            // If other pickup comes first, add travel time
                            if ($otherPickupIndex < $userPickupIndex) {
                                $fromLat = $isRider1 ? $ride->second_pickup_latitude : $ride->pickup_latitude;
                                $fromLng = $isRider1 ? $ride->second_pickup_longitude : $ride->pickup_longitude;
                                $toLat = $isRider1 ? $ride->pickup_latitude : $ride->second_pickup_latitude;
                                $toLng = $isRider1 ? $ride->pickup_longitude : $ride->second_pickup_longitude;
                                
                                $travelTimeData = $this->googleMapsService->getDistanceMatrix($fromLat, $fromLng, $toLat, $toLng);
                                if ($travelTimeData) {
                                    $travelTimeSeconds = $travelTimeData['duration_value'] ?? 0;
                                    $estimatedPickupTime = $rideScheduledTime->copy()->addSeconds($travelTimeSeconds);
                                    $estimatedPickupTimeReadable = $estimatedPickupTime->format('H:i');
                                }
                            } else {
                                // User is picked up first
                                $estimatedPickupTime = $rideScheduledTime;
                                $estimatedPickupTimeReadable = $rideScheduledTime->format('H:i');
                            }
                        }
                    }
                }
                
                // Get match data for fare and overhead info
                $r1Fare = null;
                $r2Fare = null;
                $totalOverhead = null;
                
                if ($ride->second_pickup_latitude && $ride->second_pickup_longitude) {
                    $matchData = $this->calculateOverhead(
                        $ride,
                        $ride->second_pickup_latitude,
                        $ride->second_pickup_longitude,
                        $ride->second_destination_latitude,
                        $ride->second_destination_longitude
                    );
                    if ($matchData) {
                        $r1Fare = $matchData['r1_fare'] ?? null;
                        $r2Fare = $matchData['r2_fare'] ?? null;
                        $totalOverhead = $matchData['total_overhead'] ?? null;
                    }
                }
                
                return [
                    'id' => $ride->id,
                    'uid' => $ride->uid,
                    'pickup_location' => $ride->pickup_location,
                    'destination' => $ride->destination,
                    'pickup_latitude' => $ride->pickup_latitude,
                    'pickup_longitude' => $ride->pickup_longitude,
                    'destination_latitude' => $ride->destination_latitude,
                    'destination_longitude' => $ride->destination_longitude,
                    'second_pickup_latitude' => $ride->second_pickup_latitude,
                    'second_pickup_longitude' => $ride->second_pickup_longitude,
                    'second_destination_latitude' => $ride->second_destination_latitude,
                    'second_destination_longitude' => $ride->second_destination_longitude,
                    'shared_ride_sequence' => json_decode($ride->shared_ride_sequence, true),
                    'directions_data' => $ride->directions_data ? json_decode($ride->directions_data, true) : null,
                    'is_rider1' => $isRider1,
                    'estimated_pickup_time' => $estimatedPickupTime ? $estimatedPickupTime->toIso8601String() : null,
                    'estimated_pickup_time_readable' => $estimatedPickupTimeReadable,
                    'scheduled_time' => $ride->scheduled_time ? $ride->scheduled_time->toIso8601String() : null,
                    'scheduled_time_readable' => $ride->scheduled_time ? $ride->scheduled_time->format('M d, Y H:i') : null,
                    'r1_fare' => $r1Fare,
                    'r2_fare' => $r2Fare,
                    'total_overhead' => $totalOverhead,
                    'other_user' => $otherUser ? [
                        'id' => $otherUser->id,
                        'firstname' => $otherUser->firstname,
                        'lastname' => $otherUser->lastname,
                        'username' => $otherUser->username,
                        'image' => $otherUser->image,
                        'rating' => $otherUser->rating ?? 0,
                    ] : null,
                ];
            });

            return response()->json([
                'success' => true,
                'rides' => $ridesData
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'An error occurred: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Update live location for shared ride user
     * Broadcasts location to the other user in the shared ride
     */
    public function updateLiveLocation(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'latitude'  => 'required|numeric',
            'longitude' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        $userId = auth()->id();

        // Find active shared ride where user is either rider 1 or rider 2
        $ride = Ride::where(function($query) use ($userId) {
                $query->where('user_id', $userId)
                      ->orWhere('second_user_id', $userId);
            })
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
            ->whereIn('status', [\App\Constants\Status::RIDE_ACTIVE, \App\Constants\Status::RIDE_RUNNING])
            ->first();

        if (!$ride) {
            return response()->json([
                'success' => false,
                'message' => 'No active shared ride found'
            ], 404);
        }

        // Determine the other user ID
        $otherUserId = null;
        if ($ride->user_id == $userId) {
            $otherUserId = $ride->second_user_id;
        } else {
            $otherUserId = $ride->user_id;
        }

        // Broadcast location to the other user if they exist
        if ($otherUserId) {
            event(new \App\Events\Ride("rider-user-$otherUserId", 'LIVE_LOCATION', [
                'ride'      => $ride,
                'latitude'  => $request->latitude,
                'longitude' => $request->longitude,
                'userId'    => $userId, // Include sender's user_id to identify which user's location
            ]));
        }
        
        // Also broadcast to sender's channel for consistency (optional)
        event(new \App\Events\Ride("rider-user-$userId", 'LIVE_LOCATION', [
            'ride'      => $ride,
            'latitude'  => $request->latitude,
            'longitude' => $request->longitude,
            'userId'    => $userId,
        ]));

        return response()->json([
            'success' => true,
            'message' => ['Location updated successfully']
        ]);
    }

    /**
     * Upload fare screenshot and calculate fares for both users
     */
    public function uploadFareScreenshot(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer|exists:rides,id',
            'fare_amount' => 'required|numeric|min:0',
            'fare_image' => ['required', 'image', new \App\Rules\FileTypeValidate(['jpg', 'jpeg', 'png'])],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => $validator->errors()->first()
            ], 422);
        }

        $userId = auth()->id();
        $ride = Ride::where(function($query) use ($userId) {
                $query->where('user_id', $userId)
                      ->orWhere('second_user_id', $userId);
            })
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
            ->where('id', $request->ride_id)
            ->first();

        if (!$ride) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found or you do not have permission'
            ], 404);
        }

        // Check if user is the one with first pickup
        $sequence = json_decode($ride->shared_ride_sequence, true);
        if (!$sequence || count($sequence) < 2) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid ride sequence'
            ], 400);
        }

        $firstPickup = $sequence[0];
        $isRider1 = $ride->user_id == $userId;
        $canUpload = ($firstPickup == 'S1' && $isRider1) || ($firstPickup == 'S2' && !$isRider1);

        if (!$canUpload) {
            return response()->json([
                'success' => false,
                'message' => 'Only the user with the first pickup can upload the fare screenshot'
            ], 403);
        }

        // Upload image
        try {
            $imagePath = fileUploader($request->fare_image, getFilePath('ride'), null, null);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to upload image: ' . $e->getMessage()
            ], 500);
        }

        $totalFare = floatval($request->fare_amount);
        
        // Calculate fares for both users based on overhead calculation
        $rider1Fare = null;
        $rider2Fare = null;
        
        if ($ride->second_user_id && 
            $ride->second_pickup_latitude && 
            $ride->second_pickup_longitude &&
            $ride->second_destination_latitude &&
            $ride->second_destination_longitude) {
            
            // Recalculate overhead to get fare distribution
            $matchData = $this->calculateOverhead(
                $ride,
                $ride->second_pickup_latitude,
                $ride->second_pickup_longitude,
                $ride->second_destination_latitude,
                $ride->second_destination_longitude
            );
            
            if ($matchData && isset($matchData['r1_fare']) && isset($matchData['r2_fare'])) {
                // Use the ratio from overhead calculation
                $r1Ratio = $matchData['r1_fare'] / ($matchData['r1_fare'] + $matchData['r2_fare']);
                $r2Ratio = $matchData['r2_fare'] / ($matchData['r1_fare'] + $matchData['r2_fare']);
                
                $rider1Fare = round($totalFare * $r1Ratio, 2);
                $rider2Fare = round($totalFare * $r2Ratio, 2);
            } else {
                // Fallback: split 50/50
                $rider1Fare = round($totalFare / 2, 2);
                $rider2Fare = round($totalFare / 2, 2);
            }
        } else {
            // If no second user yet, rider 1 pays full amount
            $rider1Fare = $totalFare;
            $rider2Fare = 0;
        }

        // Update ride with fare information
        $ride->fare_screenshot = $imagePath;
        $ride->fare_amount_text = $totalFare;
        $ride->rider1_fare = $rider1Fare;
        $ride->rider2_fare = $rider2Fare;
        $ride->save();

        // Notify the other user
        $otherUserId = $isRider1 ? $ride->second_user_id : $ride->user_id;
        if ($otherUserId) {
            event(new \App\Events\Ride("rider-user-$otherUserId", "FARE_SCREENSHOT_UPLOADED", [
                'ride' => $ride->load('user', 'secondUser'),
                'rider1_fare' => $rider1Fare,
                'rider2_fare' => $rider2Fare,
            ]));
        }

        return response()->json([
            'success' => true,
            'message' => 'Fare screenshot uploaded successfully',
            'ride' => $ride->load('user', 'secondUser'),
            'rider1_fare' => $rider1Fare,
            'rider2_fare' => $rider2Fare,
        ]);
    }

    /**
     * End shared ride (for user with last dropoff)
     */
    public function endSharedRide(Request $request, $rideId)
    {
        $userId = auth()->id();
        $ride = Ride::where('id', $rideId)
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
            ->where(function($query) use ($userId) {
                $query->where('user_id', $userId)
                      ->orWhere('second_user_id', $userId);
            })
            ->first();

        if (!$ride) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found or you do not have permission'
            ], 404);
        }

        // Check if ride is running
        if ($ride->status != \App\Constants\Status::RIDE_RUNNING) {
            return response()->json([
                'success' => false,
                'message' => 'Ride is not running'
            ], 400);
        }

        // Determine who has last dropoff
        $sequence = json_decode($ride->shared_ride_sequence, true);
        if (!$sequence || count($sequence) < 4) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid ride sequence'
            ], 400);
        }

        $lastDropoff = $sequence[3]; // E1 or E2
        $isRider1 = $ride->user_id == $userId;
        $canEndRide = ($lastDropoff == 'E1' && $isRider1) || ($lastDropoff == 'E2' && !$isRider1);

        if (!$canEndRide) {
            return response()->json([
                'success' => false,
                'message' => 'Only the user with the last dropoff can end the ride'
            ], 403);
        }

        // End the ride
        $ride->status = \App\Constants\Status::RIDE_COMPLETED;
        $ride->end_time = now();
        if ($ride->start_time) {
            $duration = \Carbon\Carbon::parse($ride->start_time)->diffInMinutes(now());
            $ride->duration = $duration . " Min";
        }
        $ride->save();

        // Notify the other user
        $otherUserId = $isRider1 ? $ride->second_user_id : $ride->user_id;
        if ($otherUserId) {
            event(new \App\Events\Ride("rider-user-$otherUserId", "SHARED_RIDE_ENDED", [
                'ride' => $ride->load('user', 'secondUser'),
            ]));
        }

        return response()->json([
            'success' => true,
            'message' => 'Ride ended successfully. You can now rate the other user.',
            'ride' => $ride->load('user', 'secondUser')
        ]);
    }

    /**
     * Mark "I arrived" (for user with first dropoff)
     */
    public function markArrived(Request $request, $rideId)
    {
        $userId = auth()->id();
        $ride = Ride::where('id', $rideId)
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
            ->where(function($query) use ($userId) {
                $query->where('user_id', $userId)
                      ->orWhere('second_user_id', $userId);
            })
            ->first();

        if (!$ride) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found or you do not have permission'
            ], 404);
        }

        // Check if ride is running
        if ($ride->status != \App\Constants\Status::RIDE_RUNNING) {
            return response()->json([
                'success' => false,
                'message' => 'Ride is not running'
            ], 400);
        }

        // Determine who has first dropoff
        $sequence = json_decode($ride->shared_ride_sequence, true);
        if (!$sequence || count($sequence) < 4) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid ride sequence'
            ], 400);
        }

        // Find first dropoff (E1 or E2)
        $firstDropoff = null;
        foreach ($sequence as $index => $code) {
            if ($code == 'E1' || $code == 'E2') {
                $firstDropoff = $code;
                break;
            }
        }

        if (!$firstDropoff) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid ride sequence'
            ], 400);
        }

        $isRider1 = $ride->user_id == $userId;
        $canMarkArrived = ($firstDropoff == 'E1' && $isRider1) || ($firstDropoff == 'E2' && !$isRider1);

        if (!$canMarkArrived) {
            return response()->json([
                'success' => false,
                'message' => 'Only the user with the first dropoff can mark arrival'
            ], 403);
        }

        // Mark user as arrived (we can add a field for this, or just notify)
        // For now, we'll just notify the other user
        $otherUserId = $isRider1 ? $ride->second_user_id : $ride->user_id;
        if ($otherUserId) {
            event(new \App\Events\Ride("rider-user-$otherUserId", "RIDER_ARRIVED_DESTINATION", [
                'ride' => $ride->load('user', 'secondUser'),
                'arrived_user_id' => $userId,
            ]));
        }

        return response()->json([
            'success' => true,
            'message' => 'You have marked your arrival. You can now rate the other user.',
            'ride' => $ride->load('user', 'secondUser')
        ]);
    }

    /**
     * Rate the other user in a shared ride
     */
    public function rateOtherUser(Request $request, $rideId)
    {
        $validator = Validator::make($request->all(), [
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $userId = auth()->id();
        $ride = Ride::where('id', $rideId)
            ->where('ride_type', \App\Constants\Status::SHARED_RIDE)
            ->where(function($query) use ($userId) {
                $query->where('user_id', $userId)
                      ->orWhere('second_user_id', $userId);
            })
            ->first();

        if (!$ride) {
            return response()->json([
                'success' => false,
                'message' => 'Ride not found or you do not have permission'
            ], 404);
        }

        // Determine the other user
        $otherUserId = null;
        if ($ride->user_id == $userId) {
            $otherUserId = $ride->second_user_id;
        } else {
            $otherUserId = $ride->user_id;
        }

        if (!$otherUserId) {
            return response()->json([
                'success' => false,
                'message' => 'No other user found in this ride'
            ], 400);
        }

        // Check if user already reviewed the other user for this ride
        $existsReview = \App\Models\Review::where('ride_id', $ride->id)
            ->where('user_id', $userId)
            ->where('reviewed_user_id', $otherUserId)
            ->exists();

        if ($existsReview) {
            return response()->json([
                'success' => false,
                'message' => 'You have already reviewed this user for this ride'
            ], 400);
        }

        // Create review
        $review = new \App\Models\Review();
        $review->ride_id = $ride->id;
        $review->user_id = $userId; // Reviewer
        $review->driver_id = 0; // Not a driver review
        $review->reviewed_user_id = $otherUserId; // The user being reviewed
        $review->rating = $request->rating;
        $review->review = $request->review;
        $review->save();

        // Update the reviewed user's rating
        $reviewedUser = \App\Models\User::find($otherUserId);
        if ($reviewedUser) {
            $userReviews = \App\Models\Review::where('reviewed_user_id', $otherUserId)
                ->where('driver_id', 0) // Only user-to-user reviews
                ->get();
            
            $reviewedUser->avg_rating = $userReviews->avg('rating');
            $reviewedUser->total_reviews = $userReviews->count();
            $reviewedUser->save();
        }

        // Notify the other user
        event(new \App\Events\Ride("rider-user-$otherUserId", "RATED_BY_OTHER_USER", [
            'ride' => $ride->load('user', 'secondUser'),
            'rating' => $request->rating,
            'review' => $request->review,
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Review submitted successfully',
            'review' => $review
        ]);
    }
}

