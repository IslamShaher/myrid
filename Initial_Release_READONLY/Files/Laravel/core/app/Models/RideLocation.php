<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RideLocation extends Model
{
    protected $casts = [
        'location' => 'array'
    ];
}
