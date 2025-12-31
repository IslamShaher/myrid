<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GoogleMapsService
{
    protected $apiKey;
    protected $baseUrl = 'https://maps.googleapis.com/maps/api';

    public function __construct()
    {
        $this->apiKey = env('GOOGLE_MAPS_API_KEY');
    }

    /**
     * Get distance and duration between two points.
     *
     * @param float $startLat
     * @param float $startLng
     * @param float $endLat
     * @param float $endLng
     * @return array|null Returns ['distance' => float (km), 'duration' => string] or null on failure.
     */
    public function getDistanceMatrix($startLat, $startLng, $endLat, $endLng)
    {
        if (empty($this->apiKey) || env('APP_ENV') === 'local') {
             return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
        }

        $url = "{$this->baseUrl}/distancematrix/json";

        try {
            $response = Http::get($url, [
                'origins' => "{$startLat},{$startLng}",
                'destinations' => "{$endLat},{$endLng}",
                'units' => 'metric',
                'mode' => 'driving',
                'key' => $this->apiKey,
            ]);

            if ($response->failed()) {
                Log::error('Google Maps API Error: ' . $response->body());
                return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
            }

            $data = $response->json();

            if ($data['status'] !== 'OK') {
                Log::error('Google Maps API Status Error: ' . $data['status']);
                return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
            }

            $element = $data['rows'][0]['elements'][0] ?? null;

            if (!$element || $element['status'] !== 'OK') {
                Log::warning('Google Maps Route Not Found: ' . ($element['status'] ?? 'Unknown'));
                return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
            }

            return [
                'distance' => $element['distance']['value'] / 1000, // Convert meters to km
                'duration' => $element['duration']['text'],
                'duration_value' => $element['duration']['value'], // Seconds
            ];

        } catch (\Exception $e) {
            Log::error('Google Maps Service Exception: ' . $e->getMessage());
            return $this->getFallbackDistance($startLat, $startLng, $endLat, $endLng);
        }
    }

    /**
     * Get directions with waypoints (for shared rides with multiple stops)
     *
     * @param array $waypoints Array of ['lat' => float, 'lng' => float]
     * @return array|null Returns polyline encoded string and route data or null on failure
     */
    public function getDirectionsWithWaypoints($waypoints)
    {
        if (empty($this->apiKey) || count($waypoints) < 2) {
            return null;
        }

        $url = "{$this->baseUrl}/directions/json";

        try {
            // Build waypoints string (exclude origin and destination)
            $waypointsStr = '';
            if (count($waypoints) > 2) {
                $middlePoints = array_slice($waypoints, 1, -1);
                $waypointsStr = implode('|', array_map(function($point) {
                    return "{$point['lat']},{$point['lng']}";
                }, $middlePoints));
            }

            $params = [
                'origin' => "{$waypoints[0]['lat']},{$waypoints[0]['lng']}",
                'destination' => "{$waypoints[count($waypoints)-1]['lat']},{$waypoints[count($waypoints)-1]['lng']}",
                'mode' => 'driving',
                'key' => $this->apiKey,
            ];

            if (!empty($waypointsStr)) {
                $params['waypoints'] = $waypointsStr;
            }

            $response = Http::get($url, $params);

            if ($response->failed()) {
                Log::error('Google Maps Directions API Error: ' . $response->body());
                return null;
            }

            $data = $response->json();

            if ($data['status'] !== 'OK' || empty($data['routes'])) {
                Log::error('Google Maps Directions API Status Error: ' . ($data['status'] ?? 'Unknown'));
                return null;
            }

            $route = $data['routes'][0];
            $legs = $route['legs'] ?? [];
            
            // Extract polyline
            $overviewPolyline = $route['overview_polyline']['points'] ?? null;
            
            // Calculate total distance and duration
            $totalDistance = 0;
            $totalDuration = 0;
            foreach ($legs as $leg) {
                $totalDistance += $leg['distance']['value'] ?? 0;
                $totalDuration += $leg['duration']['value'] ?? 0;
            }

            return [
                'polyline' => $overviewPolyline,
                'distance' => $totalDistance / 1000, // Convert to km
                'duration' => $totalDuration, // seconds
                'duration_text' => $this->formatDuration($totalDuration),
                'route_data' => $route, // Full route data for detailed segments
            ];

        } catch (\Exception $e) {
            Log::error('Google Maps Directions Service Exception: ' . $e->getMessage());
            return null;
        }
    }

    private function formatDuration($seconds)
    {
        $hours = floor($seconds / 3600);
        $minutes = floor(($seconds % 3600) / 60);
        
        if ($hours > 0) {
            return "{$hours} hr {$minutes} min";
        }
        return "{$minutes} min";
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

        return [
            'distance' => round($distance, 2),
            'duration' => round($distance * 2) . ' mins', // Assume 30km/h
            'duration_value' => round($distance * 2 * 60)
        ];
    }

}
