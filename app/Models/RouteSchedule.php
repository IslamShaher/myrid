<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RouteSchedule extends Model
{
    use HasFactory;

    protected $fillable = ['route_id', 'start_time', 'status'];

    public function route()
    {
        return $this->belongsTo(ShuttleRoute::class, 'route_id');
    }
}
