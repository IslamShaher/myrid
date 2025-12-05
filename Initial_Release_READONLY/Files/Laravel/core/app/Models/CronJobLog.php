<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CronJobLog extends Model
{
    protected $casts = [
        'cron_job_id' => 'integer',
        'duration'    => 'integer',
    ];
}
