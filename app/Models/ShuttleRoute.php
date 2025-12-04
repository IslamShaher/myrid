<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShuttleRoute extends Model
{
    use HasFactory;

    protected $table = 'routes';

    protected $fillable = ['name', 'code', 'capacity', 'base_price', 'price_per_km'];

    public function stops()
    {
        return $this->belongsToMany(Stop::class, 'route_stops', 'route_id', 'stop_id')
                    ->withPivot('order')
                    ->orderBy('pivot_order');
    }

    public function schedules()
    {
        return $this->hasMany(RouteSchedule::class, 'route_id');
    }
}
