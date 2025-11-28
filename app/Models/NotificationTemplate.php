<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationTemplate extends Model
{
    protected $casts = [
        'shortcodes'   => 'object',
        'email_status' => 'integer',
        'sms_status'   => 'integer',
        'push_status'  => 'integer',
        'whatsapp_status' => 'integer',
    ];
}
