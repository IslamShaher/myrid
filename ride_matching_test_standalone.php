<?php
/**
 * Standalone Ride Matching Algorithm Test File
 * 
 * This file contains the core ride matching algorithm extracted from SharedRideController
 * for testing outside the Laravel environment.
 * 
 * Usage:
 *   php ride_matching_test_standalone.php
 */

// ============================================================================
// MOCK CLASSES (Replace these with your actual implementations in Laravel)
// ============================================================================

/**
 * Mock Google Maps Service
 * In production, this uses Google Maps Distance Matrix API
 */
class GoogleMapsService
{
    protected $apiKey;
    protected $useApi = false; // Set to true to use real API

    public function __construct($apiKey = null)
    {
        $this->apiKey = $apiKey;
    }

    /**
     * Get distance and duration between two points
     * 
     * @param float $startLat
     * @param float $startLng
     * @param float $endLat
     * @param float $endLng
     * @return array|null Returns ['distance' => float (km), 'duration' => string, 'duration_value' => int (seconds)]
     */
    public function getDistanceMatrix($startLat, $startLng, $endLat, $endLng)
    {
        if ($this->useApi && $this->apiKey) {
            return $this->getApiDistance($startLat, $startLng, $endLat, $endLng);
        }
        
        // Fallback: Haversine formula with speed approximation
        return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
    }

    private function getApiDistance($startLat, $startLng, $endLat, $endLng)
    {
        $url = "https://maps.googleapis.com/maps/api/distancematrix/json";
        $params = http_build_query([
            'origins' => "{$startLat},{$startLng}",
            'destinations' => "{$endLat},{$endLng}",
            'units' => 'metric',
            'mode' => 'driving',
            'key' => $this->apiKey,
        ]);
        
        $response = @file_get_contents($url . '?' . $params);
        if (!$response) {
            return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
        }
        
        $data = json_decode($response, true);
        
        if ($data['status'] !== 'OK' || !isset($data['rows'][0]['elements'][0])) {
            return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
        }
        
        $element = $data['rows'][0]['elements'][0];
        if ($element['status'] !== 'OK') {
            return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
        }
        
        return [
            'distance' => $element['distance']['value'] / 1000, // Convert meters to km
            'duration' => $element['duration']['text'],
            'duration_value' => $element['duration']['value'], // Seconds
        ];
    }

    private function getFallbackDistance($startLat, $startLng, $endLat, $endLng)
    {
        // Haversine Formula
        $earthRadius = 6371; // km

        $dLat = deg2rad($endLat - $startLat);
        $dLon = deg2rad($endLng - $startLng);

        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($startLat)) * cos(deg2rad($endLat)) *
             sin($dLon/2) * sin($dLon/2);

        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        $distance = $earthRadius * $c;

        // Assume average speed of 30 km/h = 2 minutes per km
        $durationMinutes = $distance * 2;
        $durationSeconds = $durationMinutes * 60;

        return [
            'distance' => round($distance, 2),
            'duration' => round($durationMinutes) . ' mins',
            'duration_value' => round($durationSeconds),
        ];
    }
}

/**
 * Mock Ride Object
 */
class MockRide
{
    public $id;
    public $user_id;
    public $pickup_latitude;
    public $pickup_longitude;
    public $destination_latitude;
    public $destination_longitude;
    public $distance; // km
    public $duration; // minutes
    public $scheduled_time; // DateTime or string

    public function __construct($data)
    {
        foreach ($data as $key => $value) {
            $this->$key = $value;
        }
    }
}

// ============================================================================
// RIDE MATCHING ALGORITHM
// ============================================================================

class RideMatchingAlgorithm
{
    protected $googleMapsService;

    public function __construct(GoogleMapsService $googleMapsService)
    {
        $this->googleMapsService = $googleMapsService;
    }

    /**
     * Find matching rides for a ride request
     * 
     * @param array $requestData ['start_lat', 'start_lng', 'end_lat', 'end_lng', 'scheduled_time' (optional)]
     * @param array $availableRides Array of MockRide objects
     * @param int $userId Current user ID (to exclude own rides)
     * @return array Array of matches sorted by total overhead
     */
    public function findMatches($requestData, $availableRides, $userId = null)
    {
        $startLat = $requestData['start_lat'];
        $startLng = $requestData['start_lng'];
        $endLat = $requestData['end_lat'];
        $endLng = $requestData['end_lng'];
        
        // Parse scheduled time (default to now)
        $requestedTime = isset($requestData['scheduled_time']) 
            ? (is_string($requestData['scheduled_time']) 
                ? new DateTime($requestData['scheduled_time']) 
                : $requestData['scheduled_time'])
            : new DateTime();

        // Parameters
        $radius = 5.0; // km
        $timeWindowMinutes = 40;
        
        $timeWindowStart = clone $requestedTime;
        $timeWindowStart->modify("-{$timeWindowMinutes} minutes");
        $timeWindowEnd = clone $requestedTime;
        $timeWindowEnd->modify("+{$timeWindowMinutes} minutes");

        $matches = [];

        foreach ($availableRides as $ride) {
            // Filter: exclude own rides
            if ($userId && $ride->user_id == $userId) {
                continue;
            }

            // Filter: time window
            if ($ride->scheduled_time) {
                $rideTime = is_string($ride->scheduled_time) 
                    ? new DateTime($ride->scheduled_time) 
                    : $ride->scheduled_time;
                
                if ($rideTime < $timeWindowStart || $rideTime > $timeWindowEnd) {
                    continue;
                }
            }

            // Check proximity: both pickup and destination must be within radius
            $distStart = $this->getHaversineDistance(
                $ride->pickup_latitude, $ride->pickup_longitude,
                $startLat, $startLng
            );

            $distEnd = $this->getHaversineDistance(
                $ride->destination_latitude, $ride->destination_longitude,
                $endLat, $endLng
            );

            if ($distStart <= $radius && $distEnd <= $radius) {
                // Calculate overhead and optimal sequence
                $matchData = $this->calculateOverhead($ride, $startLat, $startLng, $endLat, $endLng);
                
                if ($matchData) {
                    // Calculate estimated pickup time for user 2
                    if ($ride->scheduled_time) {
                        $rideScheduledTime = is_string($ride->scheduled_time) 
                            ? new DateTime($ride->scheduled_time) 
                            : $ride->scheduled_time;
                        
                        $sequence = $matchData['sequence'] ?? [];
                        if (!empty($sequence)) {
                            $s2Index = array_search('S2', $sequence);
                            $s1Index = array_search('S1', $sequence);
                            
                            if ($s2Index !== false && $s1Index !== false) {
                                $travelTimeData = $this->googleMapsService->getDistanceMatrix(
                                    $ride->pickup_latitude, $ride->pickup_longitude,
                                    $startLat, $startLng
                                );
                                
                                if ($travelTimeData) {
                                    $travelTimeSeconds = $travelTimeData['duration_value'] ?? 0;
                                    $estimatedPickupTime = clone $rideScheduledTime;
                                    $estimatedPickupTime->modify("+{$travelTimeSeconds} seconds");
                                    $matchData['estimated_pickup_time'] = $estimatedPickupTime->format('c');
                                    $matchData['estimated_pickup_time_readable'] = $estimatedPickupTime->format('H:i');
                                }
                            }
                        }
                        
                        $matchData['ride_scheduled_time'] = $rideScheduledTime->format('c');
                        $matchData['ride_scheduled_time_readable'] = $rideScheduledTime->format('M d, Y H:i');
                    }
                    
                    $matches[] = $matchData;
                }
            }
        }

        // Sort by total overhead (ascending - lower is better)
        usort($matches, function ($a, $b) {
            return $a['total_overhead'] <=> $b['total_overhead'];
        });

        return $matches;
    }

    /**
     * Calculate Haversine distance between two points
     * 
     * @param float $lat1
     * @param float $lon1
     * @param float $lat2
     * @param float $lon2
     * @return float Distance in kilometers
     */
    private function getHaversineDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // km
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat/2) * sin($dLat/2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon/2) * sin($dLon/2);
        $c = 2 * atan2(sqrt($a), sqrt(1-$a));
        return $earthRadius * $c;
    }

    /**
     * Calculate overhead and find optimal route sequence
     * 
     * @param MockRide $ride Existing ride (Rider 1)
     * @param float $u2StartLat Rider 2 pickup latitude
     * @param float $u2StartLng Rider 2 pickup longitude
     * @param float $u2EndLat Rider 2 destination latitude
     * @param float $u2EndLng Rider 2 destination longitude
     * @return array|null Match data with overhead, sequence, and fares
     */
    public function calculateOverhead($ride, $u2StartLat, $u2StartLng, $u2EndLat, $u2EndLng)
    {
        // Points
        $p1Start = ['lat' => $ride->pickup_latitude, 'lng' => $ride->pickup_longitude];
        $p1End   = ['lat' => $ride->destination_latitude, 'lng' => $ride->destination_longitude];
        $p2Start = ['lat' => $u2StartLat, 'lng' => $u2StartLng];
        $p2End   = ['lat' => $u2EndLat, 'lng' => $u2EndLng];

        // Calculate solo durations
        $r1SoloDuration = $ride->duration * 60; // Convert minutes to seconds
        $r1SoloDistance = $ride->distance; // km

        // Rider 2 Solo - Need to calculate
        $r2Solo = $this->googleMapsService->getDistanceMatrix(
            $p2Start['lat'], $p2Start['lng'],
            $p2End['lat'], $p2End['lng']
        );
        if (!$r2Solo) {
            return null;
        }
        $r2SoloDuration = $r2Solo['duration_value']; // seconds
        $r2SoloDistance = $r2Solo['distance']; // km

        // Test 4 permutations
        $permutations = [
            ['seq' => ['S1', 'S2', 'E1', 'E2'], 'coords' => [$p1Start, $p2Start, $p1End, $p2End]],
            ['seq' => ['S1', 'S2', 'E2', 'E1'], 'coords' => [$p1Start, $p2Start, $p2End, $p1End]],
            ['seq' => ['S2', 'S1', 'E1', 'E2'], 'coords' => [$p2Start, $p1Start, $p1End, $p2End]],
            ['seq' => ['S2', 'S1', 'E2', 'E1'], 'coords' => [$p2Start, $p1Start, $p2End, $p1End]],
        ];

        $bestSequence = null;
        $minTotalDuration = PHP_INT_MAX;
        $bestOverhead = null;

        $pricePerKm = 2.00;

        foreach ($permutations as $perm) {
            $coords = $perm['coords'];
            $seq = $perm['seq'];
            
            $activeRiders = []; // Track who is in the car
            $r1Cost = 0;
            $r2Cost = 0;
            $totalSeqDuration = 0;

            // Process each segment
            for ($i = 0; $i < 3; $i++) {
                $pStart = $seq[$i];   // Code e.g. 'S1'
                $pEnd   = $seq[$i+1]; // Code e.g. 'S2'
                
                // Update riders based on pStart (pickup or dropoff)
                if (strpos($pStart, 'S') !== false) { // Pickup
                    $riderIdx = (strpos($pStart, '1') !== false) ? 1 : 2;
                    if (!in_array($riderIdx, $activeRiders)) {
                        $activeRiders[] = $riderIdx;
                    }
                }
                if (strpos($pStart, 'E') !== false) { // Dropoff
                    $riderIdx = (strpos($pStart, '1') !== false) ? 1 : 2;
                    $activeRiders = array_values(array_diff($activeRiders, [$riderIdx]));
                }
                
                // Calculate segment duration and distance
                $segDur = $this->getSegmentDuration($coords[$i], $coords[$i+1]); // seconds
                $segDistKm = $segDur / 120.0; // Convert duration to distance (120 sec/km = 30 km/h)
                $segPrice = $segDistKm * $pricePerKm;
                
                $totalSeqDuration += $segDur;
                
                // Distribute cost among active riders
                $count = count($activeRiders);
                if ($count > 0) {
                    $costPerRider = $segPrice / $count;
                    if (in_array(1, $activeRiders)) {
                        $r1Cost += $costPerRider;
                    }
                    if (in_array(2, $activeRiders)) {
                        $r2Cost += $costPerRider;
                    }
                }
            }
            
            // Calculate individual ride durations for overhead
            $idxS1 = array_search('S1', $seq);
            $idxE1 = array_search('E1', $seq);
            $r1DurationInRide = $this->getSubSequenceDuration($coords, $idxS1, $idxE1);

            $idxS2 = array_search('S2', $seq);
            $idxE2 = array_search('E2', $seq);
            $r2DurationInRide = $this->getSubSequenceDuration($coords, $idxS2, $idxE2);

            $overhead1 = $r1DurationInRide - $r1SoloDuration;
            $overhead2 = $r2DurationInRide - $r2SoloDuration;
            $totalOverhead = $overhead1 + $overhead2;

            // Track best sequence (minimum total duration)
            if ($totalSeqDuration < $minTotalDuration) {
                $minTotalDuration = $totalSeqDuration;
                $bestSequence = $seq;
                $bestOverhead = [
                    'r1_overhead' => round($overhead1 / 60, 1), // Convert to minutes
                    'r2_overhead' => round($overhead2 / 60, 1),
                    'total_overhead' => round($totalOverhead / 60, 1),
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
        
        // Add base fare
        $baseFare = 5.00;
        $pricePerKm = 2.00;
        
        if ($bestOverhead) {
            $bestOverhead['r1_fare'] += $baseFare;
            $bestOverhead['r2_fare'] += $baseFare;
            
            // Calculate solo fares for savings comparison
            $r1SoloFare = $baseFare + ($r1SoloDistance * $pricePerKm);
            $r2SoloFare = $baseFare + ($r2SoloDistance * $pricePerKm);
            $bestOverhead['r1_solo_fare'] = round($r1SoloFare, 2);
            $bestOverhead['r2_solo_fare'] = round($r2SoloFare, 2);
        }
        
        return array_merge(['ride_id' => $ride->id], $bestOverhead ?? []);
    }

    /**
     * Get segment duration between two points
     * Uses Haversine distance with speed approximation
     * 
     * @param array $p1 ['lat' => float, 'lng' => float]
     * @param array $p2 ['lat' => float, 'lng' => float]
     * @return int Duration in seconds
     */
    private function getSegmentDuration($p1, $p2)
    {
        // Haversine distance * 120 seconds/km (assumes ~30 km/h = 2 min/km)
        return $this->getHaversineDistance($p1['lat'], $p1['lng'], $p2['lat'], $p2['lng']) * 120;
    }

    /**
     * Get duration for a subsequence of coordinates
     * 
     * @param array $coords Array of coordinate arrays
     * @param int $startIdx Starting index
     * @param int $endIdx Ending index
     * @return int Total duration in seconds
     */
    private function getSubSequenceDuration($coords, $startIdx, $endIdx)
    {
        $dur = 0;
        for ($i = $startIdx; $i < $endIdx; $i++) {
            $dur += $this->getSegmentDuration($coords[$i], $coords[$i+1]);
        }
        return $dur;
    }
}

// ============================================================================
// TEST EXAMPLE
// ============================================================================

if (php_sapi_name() === 'cli' && basename(__FILE__) === basename($_SERVER['PHP_SELF'])) {
    echo "=== Ride Matching Algorithm Test ===\n\n";
    
    // Initialize service (set useApi = true and provide API key for real API calls)
    $googleMapsService = new GoogleMapsService(null);
    $matcher = new RideMatchingAlgorithm($googleMapsService);
    
    // Sample ride request
    $requestData = [
        'start_lat' => 30.0444,  // Cairo coordinates
        'start_lng' => 31.2357,
        'end_lat' => 30.0445,
        'end_lng' => 31.2358,
        'scheduled_time' => new DateTime(), // Now
    ];
    
    // Sample available rides
    $availableRides = [
        new MockRide([
            'id' => 1,
            'user_id' => 100,
            'pickup_latitude' => 30.0440,
            'pickup_longitude' => 31.2355,
            'destination_latitude' => 30.0446,
            'destination_longitude' => 31.2359,
            'distance' => 2.5, // km
            'duration' => 5,   // minutes
            'scheduled_time' => new DateTime(),
        ]),
        new MockRide([
            'id' => 2,
            'user_id' => 200,
            'pickup_latitude' => 30.0442,
            'pickup_longitude' => 31.2356,
            'destination_latitude' => 30.0447,
            'destination_longitude' => 31.2360,
            'distance' => 3.0, // km
            'duration' => 6,   // minutes
            'scheduled_time' => new DateTime(),
        ]),
    ];
    
    // Find matches
    $matches = $matcher->findMatches($requestData, $availableRides, null);
    
    echo "Found " . count($matches) . " match(es):\n\n";
    
    foreach ($matches as $i => $match) {
        echo "Match #" . ($i + 1) . " (Ride ID: {$match['ride_id']}):\n";
        echo "  Sequence: " . implode(' → ', $match['sequence']) . "\n";
        echo "  Total Overhead: {$match['total_overhead']} minutes\n";
        echo "  Rider 1 Overhead: {$match['r1_overhead']} minutes\n";
        echo "  Rider 2 Overhead: {$match['r2_overhead']} minutes\n";
        echo "  Rider 1 Fare: \${$match['r1_fare']} (Solo: \${$match['r1_solo_fare']})\n";
        echo "  Rider 2 Fare: \${$match['r2_fare']} (Solo: \${$match['r2_solo_fare']})\n";
        echo "\n";
    }
    
    echo "=== Test Complete ===\n";
}






