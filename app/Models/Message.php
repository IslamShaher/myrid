<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    protected $casts = [
        'ride_id'   => 'integer',
        'user_id'   => 'integer',
        'driver_id' => 'integer',
    ];
}
