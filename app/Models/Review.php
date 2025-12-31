<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Review extends Model
{

    protected $casts = [
        'user_id'        => 'integer',
        'driver_id'      => 'integer',
        'ride_id'        => 'integer',
        'rating'         => 'integer',
        'reviewed_user_id' => 'integer',
    ];

    public function ride()
    {
        return $this->belongsTo(Ride::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function driver()
    {
        return $this->belongsTo(Driver::class);
    }
}
