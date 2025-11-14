<?php

namespace App\Models;

use App\Traits\GlobalStatus;
use Illuminate\Database\Eloquent\Model;

class CronJob extends Model
{
    use GlobalStatus;

    protected $casts = [
        'action'           => 'array',
        'cron_schedule_id' => 'integer',
        'is_running'       => 'integer',
        'is_default'       => 'integer',
    ];

    public function schedule()
    {
        return $this->belongsTo(CronSchedule::class, 'cron_schedule_id');
    }

    public function logs()
    {
        return $this->hasMany(CronJobLog::class, 'cron_job_id');
    }
}
