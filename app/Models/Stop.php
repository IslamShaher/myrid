<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

use App\Models\ShuttleRoute;

class Stop extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'latitude',
        'longitude',
    ];

    public function routes()
    {
        return $this->belongsToMany(ShuttleRoute::class, 'route_stops')
            ->withPivot('order');
    }

	public function shuttleRoutes()
	{
	    return $this->belongsToMany(ShuttleRoute::class, 'route_stops', 'stop_id', 'route_id')
		        ->withPivot('order');
	}



}
