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
                'units' => 'driving',
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
