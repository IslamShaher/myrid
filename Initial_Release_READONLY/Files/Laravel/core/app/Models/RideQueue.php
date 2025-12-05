<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class RideQueue extends Model

{
    protected $casts = [
        'ride_id'  => 'integer',
        'ordering' => 'integer',
    ];
}
