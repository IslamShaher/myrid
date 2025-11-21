<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Stop;

class StopSeeder extends Seeder
{
    public function run(): void
    {
        $stops = [
            ['name' => 'Rose Hotel', 'latitude' => 30.0388148, 'longitude' => 31.2103418],
            ['name' => 'Banque Du Caire', 'latitude' => 30.0428566, 'longitude' => 31.2119131],
            ['name' => 'Anglo American Hospital', 'latitude' => 30.0463530, 'longitude' => 31.2216344],
            ['name' => 'Cairo Tower', 'latitude' => 30.0465220, 'longitude' => 31.2242989],
            ['name' => 'Ramses Hilton', 'latitude' => 30.0503650, 'longitude' => 31.2320411],
            ['name' => 'El Tawheed El Togareya', 'latitude' => 30.0508237, 'longitude' => 31.2518615],
            ['name' => 'Khan El-Khalili', 'latitude' => 30.0477386, 'longitude' => 31.2622538],
            ['name' => 'National Bank of Egypt', 'latitude' => 30.0485374, 'longitude' => 31.2717568],
            ['name' => 'General Authority for Investments', 'latitude' => 30.0711765, 'longitude' => 31.2963999],
            ['name' => 'Fair Zone', 'latitude' => 30.0732570, 'longitude' => 31.3009800],
            ['name' => 'Image Home Department Store', 'latitude' => 30.0798290, 'longitude' => 31.3147057],
            ['name' => 'Military Factories Club', 'latitude' => 30.0822406, 'longitude' => 31.3194895],
            ['name' => 'On The Run (Orouba)', 'latitude' => 30.0848464, 'longitude' => 31.3257490],
            ['name' => 'Baron Hotel Cairo', 'latitude' => 30.0861069, 'longitude' => 31.3316670],
            ['name' => 'Tolip El Galaa Hotel', 'latitude' => 30.0984475, 'longitude' => 31.3489093],
            ['name' => 'Le Marche', 'latitude' => 30.1003244, 'longitude' => 31.3507396],
            ['name' => 'Leonardo Ristorante', 'latitude' => 30.1066692, 'longitude' => 31.3649767],
            ['name' => 'Sheraton Apartment 41', 'latitude' => 30.1038995, 'longitude' => 31.3710777],
        ];

        foreach ($stops as $stop) {
            Stop::firstOrCreate(['name' => $stop['name']], $stop);
        }
    }
}

