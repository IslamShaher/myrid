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
                return null;
            }

            $data = $response->json();

            if ($data['status'] !== 'OK') {
                Log::error('Google Maps API Status Error: ' . $data['status']);
                return null;
            }

            $element = $data['rows'][0]['elements'][0] ?? null;

            if (!$element || $element['status'] !== 'OK') {
                Log::warning('Google Maps Route Not Found: ' . ($element['status'] ?? 'Unknown'));
                return null;
            }

            return [
                'distance' => $element['distance']['value'] / 1000, // Convert meters to km
                'duration' => $element['duration']['text'],
                'duration_value' => $element['duration']['value'], // Seconds
            ];

        } catch (\Exception $e) {
            Log::error('Google Maps Service Exception: ' . $e->getMessage());
            return null;
        }
    }
}
