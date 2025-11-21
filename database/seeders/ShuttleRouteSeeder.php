<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ShuttleRoute;
use App\Models\RouteStop;
use App\Models\Stop;

class ShuttleRouteSeeder extends Seeder
{
    public function run(): void
    {
        $route = ShuttleRoute::firstOrCreate(
            ['name' => 'Dokki → Sheraton Heliopolis'],
            ['code' => 'DSH01']
        );

        $stopNames = [
            'Rose Hotel',
            'Banque Du Caire',
            'Anglo American Hospital',
            'Cairo Tower',
            'Ramses Hilton',
            'El Tawheed El Togareya',
            'Khan El-Khalili',
            'National Bank of Egypt',
            'General Authority for Investments',
            'Fair Zone',
            'Image Home Department Store',
            'Military Factories Club',
            'On The Run (Orouba)',
            'Baron Hotel Cairo',
            'Tolip El Galaa Hotel',
            'Le Marche',
            'Leonardo Ristorante',
            'Sheraton Apartment 41',
        ];

        foreach ($stopNames as $i => $name) {
            $stop = Stop::where('name', $name)->first();

            if ($stop) {
                RouteStop::updateOrCreate(
                    [
                        'shuttle_route_id' => $route->id,
                        'order' => $i + 1
                    ],
                    [
                        'stop_id' => $stop->id
                    ]
                );
            }
        }
    }
}

