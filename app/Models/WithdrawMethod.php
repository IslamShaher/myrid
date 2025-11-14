<?php

namespace App\Models;

use App\Traits\GlobalStatus;
use Illuminate\Database\Eloquent\Model;

class WithdrawMethod extends Model
{
    use GlobalStatus;

    protected $casts = [
        'user_data'      => 'object',
        'form_id'        => 'integer',
        'min_limit'      => 'double',
        'max_limit'      => 'double',
        'fixed_charge'   => 'double',
        'rate'           => 'double',
        'percent_charge' => 'double',
        'status'         => 'integer',
    ];

    public function form()
    {
        return $this->belongsTo(Form::class);
    }
}
