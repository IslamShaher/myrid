<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DeviceToken extends Model
{
    protected $casts = [
        'user_id'   => 'integer',
        'driver_id' => 'integer',
        'is_app'    => 'integer',
    ];
}
