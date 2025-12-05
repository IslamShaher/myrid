<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;

class PermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    // php artisan db:seed --class=PermissionSeeder
    public function run(): void
    {
        $permissions = [
            "manage rides" => [
                "view rides",
            ],
            "zone" => [
                "view zone",
                "add zone",
                "edit zone",
            ],
            "service" => [
                "view service",
                "add service",
                "edit service",
            ],
            "coupon" => [
                "view coupon",
                "add coupon",
                "edit coupon",
            ],
            "brand" => [
                "view brand",
                "add brand",
                "edit brand",
            ],
            "vehicle_model" => [
                "view vehicle model",
                "add vehicle model",
                "edit vehicle model",
            ],
            "vehicle_year" => [
                "view vehicle year",
                "add vehicle year",
                "edit vehicle year",
            ],
            "vehicle_color" => [
                "view vehicle color",
                "add vehicle color",
                "edit vehicle color",
            ],
            "rider_rule" => [
                "view rider rule",
                "add rider rule",
                "edit rider rule",
            ],
            "manage verification form" => [
                "view driver verification form",
                "view vehicle verification form",
            ],
            "manage content" => [
                "manage pages",
                "manage sections",
            ],
            "manage admin" => [
                "view admin",
                "add admin",
                "edit admin"
            ],
            "driver deposits" => [
                "view driver deposits",
                "approve driver deposits",
                "reject driver deposits",
            ],
            "driver withdrawals" => [
                "view driver withdrawals",
                "approve driver withdrawals",
                "reject driver withdrawals",
            ],
            "rider report" => [
                "view rider payment report",
                "view rider login history",
                "view rider notification history",
            ],
            "support ticket" => [
                "view user tickets",
                "answer tickets",
                "close tickets"
            ],
            "manage roles" => [
                "view roles",
                "add role",
                "edit role",
                "assign permissions"
            ],
            "manage gateways" => [
                "view payment gateway",
                "update payment gateway",
                "view withdrawals methods",
                "update withdrawals methods",
            ],
            "driver report" => [
                "view driver commission history",
                "view driver notification history",
                "view driver transaction history",
                "view driver login history",
            ],
            "manage riders" => [
                "view riders",
                "send notification to riders",
                "ban riders",
                "view rider notifications",
                "update riders"
            ],
            "manage drivers" => [
                "view drivers",
                "notification to all drivers",
                "update driver balance",
                "ban drivers",
                "view driver notifications",
                "update drivers"
            ],
            "system utilities" => [
                "view extension",
                "update extension",
                "view seo",
                "update seo",
                "view language",
                "update language",
            ],
            "setting" => [
                "general settings",
                "brand settings",
                "system configuration",
                "notification settings",
                "cron job settings",
                "gdpr cookie",
                "custom css",
                "sitemap",
                "robot",
                "maintenance mode",
                "ride settings",
                "pusher configuration",
                "google maps setting",
            ],
            "other" => [
                "view dashboard",
                "all reviews",
                "promotional notify",
                "manage subscribers",
                "view application info"
            ],

        ];

        foreach ($permissions as $k => $permission) {
            foreach ($permission as  $item) {
                $exists = Permission::where("name", $item)->where('group_name', $k)->exists();
                if ($exists) continue;
                $permission             = new Permission();
                $permission->name       = $item;
                $permission->group_name = $k;
                $permission->guard_name = "admin";
                $permission->save();
            }
        }
    }
}
