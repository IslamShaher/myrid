<?php

namespace App\Models;

use App\Constants\Status;
use App\Traits\GlobalStatus;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Casts\Attribute;

class SosAlert extends Model
{
    use  GlobalStatus;

    protected $casts = [
        'ride_id' => 'integer',
        'status'  => 'integer',
    ];

    public function ride()
    {
        return $this->belongsTo(Ride::class);
    }

    public function statusBadge(): Attribute
    {
        return new Attribute(function () {
            $html = '';
            if ($this->status == Status::ENABLE) {
                $html = '<span class="badge badge--danger">' . trans('Pending') . '</span>';
            } else {
                $html = '<span class="badge badge--success">' . trans('Resolved') . '</span>';
            }
            return $html;
        });
    }
}
