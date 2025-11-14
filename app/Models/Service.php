<?php

namespace App\Models;

use App\Traits\GlobalStatus;
use Illuminate\Database\Eloquent\Model;

class Service extends Model
{
    use  GlobalStatus;
    protected $casts = [
        'city_min_fare'             => 'double',
        'city_max_fare'             => 'double',
        'city_recommend_fare'       => 'double',
        'city_fare_commission'      => 'double',
        'intercity_min_fare'        => 'double',
        'intercity_max_fare'        => 'double',
        'intercity_recommend_fare'  => 'double',
        'intercity_fare_commission' => 'double',
        'status'                    => 'integer',
    ];
}
