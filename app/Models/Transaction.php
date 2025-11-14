<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $casts = [
        'user_id'      => 'integer',
        'driver_id'    => 'integer',
        'amount'       => 'double',
        'charge'       => 'double',
        'post_balance' => 'double',
    ];

    public function exportColumns(): array
    {
        return  [
            'driver_id' => [
                'name' => "Driver",
                'callback' => function ($item) {
                    return @$item->driver->username;
                }
            ],
            'trx',
            'created_at' => [
                'name' =>  "transacted",
                'callback' => function ($item) {
                    return showDateTime($item->created_at, lang: 'en');
                }
            ],
            'amount' => [
                'callback' => function ($item) {
                    return showAmount($item->amount);
                }
            ],
            'post_balance' => [
                'callback' => function ($item) {
                    return showAmount($item->post_balance);
                }
            ],
        ];
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
