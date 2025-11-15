<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShuttleRoute extends Model
{
    use HasFactory;

    protected $table = 'routes';

    protected $fillable = [
        'name',
    ];

    public function stops()
    {
        return $this->belongsToMany(Stop::class, 'route_stops')
            ->withPivot('order')
            ->orderBy('route_stops.order');
    }
}
 
