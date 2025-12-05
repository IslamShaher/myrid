<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Ride;
use App\Models\RidePayment;
use Carbon\Carbon;

class DriverEarningController extends Controller {
    public function driverEarning($id) {
        $driver = Driver::findOrFail($id);

        $pageTitle = 'Driver Earning - ' . $driver->username;

        $driverEarningQuery = Ride::where('driver_id', $driver->id)->completed();
        $widget             = [
            'total_earning'            => (clone $driverEarningQuery)->sum('amount'),
            'total_tips'               => (clone $driverEarningQuery)->sum('tips_amount'),
            'total_commission_paid'    => (clone $driverEarningQuery)->sum('commission_amount'),
            'average_earning_per_ride' => (clone $driverEarningQuery)->avg('amount'),
            'today_earning'            => (clone $driverEarningQuery)
                ->whereDate('created_at', Carbon::today())
                ->sum('amount'),
            'this_week_earning'        => (clone $driverEarningQuery)
                ->whereBetween('created_at', [Carbon::now()->startOfWeek(), Carbon::now()->endOfWeek()])
                ->sum('amount'),
            'this_month_earning'       => (clone $driverEarningQuery)
                ->whereMonth('created_at', Carbon::now()->month)
                ->whereYear('created_at', Carbon::now()->year)
                ->sum('amount'),
            'this_year_earning'        => (clone $driverEarningQuery)
                ->whereYear('created_at', Carbon::now()->year)
                ->sum('amount'),

        ];

        $baseQuery = RidePayment::where('driver_id', $driver->id)->searchable(['driver:username', 'rider:username', 'ride:uid'])->filter(['driver_id', 'rider_id', 'payment_type'])->orderBy('id', getOrderBy());
        if (request()->export) {
            return exportData($baseQuery, request()->export, "RidePayment");
        }
        $payments = $baseQuery->with('rider', 'driver', 'ride')->paginate(getPaginate());

        return view('admin.driver.earning.details', compact('pageTitle', 'widget', 'driver', 'payments'));
    }
}
