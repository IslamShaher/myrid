<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GeneralSetting extends Model
{
    protected $casts = [
        'mail_config'             => 'object',
        'sms_config'              => 'object',
        'global_shortcodes'       => 'object',
        'socialite_credentials'   => 'object',
        'firebase_config'         => 'object',
        'pusher_config'           => 'object',
        'operating_country'       => 'object',
        'tips_suggest_amount'     => 'array',
        'kv'                      => 'integer',
        'ev'                      => 'integer',
        'en'                      => 'integer',
        'sv'                      => 'integer',
        'sn'                      => 'integer',
        'pn'                      => 'integer',
        'force_ssl'               => 'integer',
        'in_app_payment'          => 'integer',
        'maintenance_mode'        => 'integer',
        'secure_password'         => 'integer',
        'agree'                   => 'integer',
        'multi_language'          => 'integer',
        'registration'            => 'integer',
        'system_customized'       => 'integer',
        'paginate_number'         => 'integer',
        'currency_format'         => 'integer',
        'allow_precision'         => 'integer',
        'user_cancellation_limit' => 'integer',
        'driver_registration'     => 'integer',
        'google_login'            => 'integer',
        'apple_login'             => 'integer',
        'ride_cancel_time'        => 'integer',
        'min_distance'            => 'double',
        'negative_balance_driver' => 'double',
    ];

    protected $hidden = ['email_template', 'mail_config', 'sms_config', 'system_info'];

    public function scopeSiteName($query, $pageTitle)
    {
        $pageTitle = empty($pageTitle) ? '' : ' - ' . $pageTitle;
        return $this->site_name . $pageTitle;
    }

    protected static function boot()
    {
        parent::boot();
        static::saved(function () {
            \Cache::forget('GeneralSetting');
        });
    }
}
