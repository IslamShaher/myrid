<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\ShuttleRoute;
use App\Models\Stop;

class ShuttleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create sample stops
        $stopA = Stop::firstOrCreate(
            ['name' => 'Stop A'],
            ['latitude' => 30.052, 'longitude' => 31.233]
        );

        $stopB = Stop::firstOrCreate(
            ['name' => 'Stop B'],
            ['latitude' => 30.056, 'longitude' => 31.237]
        );

        $stopC = Stop::firstOrCreate(
            ['name' => 'Stop C'],
            ['latitude' => 30.060, 'longitude' => 31.240]
        );

        // Create a route and attach stops in order
        $route1 = ShuttleRoute::firstOrCreate(['name' => 'Route 1']);

        $route1->stops()->syncWithoutDetaching([
            $stopA->id => ['order' => 1],
            $stopB->id => ['order' => 2],
            $stopC->id => ['order' => 3],
        ]);
    }
}
