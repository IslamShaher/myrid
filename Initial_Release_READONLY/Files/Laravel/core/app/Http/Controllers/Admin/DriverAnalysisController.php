<?php

namespace App\Http\Controllers\Admin;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Models\Bid;
use App\Models\Driver;
use App\Models\Review;
use App\Models\Ride;
use App\Models\RidePayment;
use App\Models\Withdrawal;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DriverAnalysisController extends Controller
{

    public function allDriverAnalysis()
    {
        $pageTitle        = 'Driver Analysis';
        $rideQuery        = Ride::where('driver_id', '!=', 0);
        $completedDrivers = (clone $rideQuery)->completed();
        $canceledDrivers  = (clone $rideQuery)->canceled();

        $widget = [
            'total_ride'            => (clone $rideQuery)->count(),
            'completed_ride'        => (clone $completedDrivers)->count(),
            'canceled_ride'         => (clone $canceledDrivers)->count(),
            'average_fare_per_ride' => (clone $completedDrivers)->avg('amount'),
            'total_commission_paid' => (clone $rideQuery)->sum('commission_amount'),
        ];

        $widget['successful_ride_percentage'] = 0;
        if ($widget['total_ride'] > 0) {
            $widget['successful_ride_percentage'] = round(($widget['completed_ride'] / $widget['total_ride']) * 100, 2);
        }

        $bidQuery            = Bid::where('driver_id', '!=', 0);
        $allRideBid          = (clone $bidQuery)->count();
        $rideAcceptanceBid   = (clone $bidQuery)->where('status', Status::BID_ACCEPTED)->count();
        $rideCancellationBid = (clone $bidQuery)->where('status', Status::BID_CANCELED)->count();

        $widget['ride_acceptance_rate'] = 0;
        $widget['cancellation_rate']    = 0;
        if ($allRideBid > 0) {
            $widget['ride_acceptance_rate'] = round(($rideAcceptanceBid / $allRideBid) * 100, 2);
            $widget['cancellation_rate']    = round(($rideCancellationBid / $allRideBid) * 100, 2);
        }

        $paymentQuery = RidePayment::where('driver_id', '!=', 0)->selectRaw('payment_type, COUNT(*) as total')
            ->groupBy('payment_type')
            ->get();
        $paymentTypes = [
            Status::PAYMENT_TYPE_CASH    => __('Cash'),
            Status::PAYMENT_TYPE_GATEWAY => __('Gateway'),
            Status::PAYMENT_TYPE_WALLET  => __('Wallet'),
        ];

        $reviews = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('driver_id', '!=', 0)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate(), ['*'], 'review_page');
        $averageRating            = $reviews->avg('rating');
        $widget['average_rating'] = $averageRating ?? '-';

        $withdrawals = Withdrawal::with('driver')->where('driver_id', '!=', 0)->where('status', '!=', Status::PAYMENT_INITIATE)->filter(['driver_id'])->searchable(['trx', 'driver:username'])->orderBy("id", getOrderBy())
            ->paginate(getPaginate(), ['*'], 'withdraw_page');

        return view('admin.analysis.all.driver', compact('pageTitle', 'widget', 'paymentQuery', 'paymentTypes', 'reviews', 'withdrawals'));
    }

    public function allPaymentSpentReport(Request $request)
    {
        $driver            = Driver::all();
        $today             = Carbon::today();
        $timePeriodDetails = $this->timePeriodDetails($today);
        $timePeriod        = (object) $timePeriodDetails[$request->time_period ?? 'daily'];
        $carbonMethod      = $timePeriod->carbon_method;
        $starDate          = $today->copy()->$carbonMethod($timePeriod->take);
        $endDate           = $today->copy();

        $spents = Ride::completed()
            ->where('driver_id', '!=', 0)
            ->whereDate('created_at', '>=', $starDate)
            ->whereDate('created_at', '<=', $endDate)
            ->selectRaw('DATE_FORMAT(created_at, "' . $timePeriod->sql_date_format . '") as date,SUM(amount) as amount')
            ->orderBy('date', 'asc')
            ->groupBy('date')
            ->get();

        $data = [];

        for ($i = 0; $i < $timePeriod->take; $i++) {
            $date  = $today->copy()->$carbonMethod($i)->format($timePeriod->php_date_format);
            $spent = $spents->where('date', $date)->first();

            $spentAmount = $spent ? $spent->amount : 0;

            $data[$date] = [
                'spent_amount' => $spentAmount,
            ];
        }
        return response()->json($data);
    }

    public function driverAnalysis($id)
    {
        $driver = Driver::findOrFail($id);

        $pageTitle = 'Driver Analysis - ' . $driver->username;

        $rideQuery        = Ride::where('driver_id', $driver->id);
        $completedDrivers = (clone $rideQuery)->completed();
        $canceledDrivers  = (clone $rideQuery)->canceled();

        $widget = [
            'total_ride'            => (clone $rideQuery)->count(),
            'completed_ride'        => (clone $completedDrivers)->count(),
            'canceled_ride'         => (clone $canceledDrivers)->count(),
            'average_fare_per_ride' => (clone $completedDrivers)->avg('amount'),
            'total_commission_paid' => (clone $rideQuery)->sum('commission_amount'),
        ];

        $widget['successful_ride_percentage'] = 0;
        if ($widget['total_ride'] > 0) {
            $widget['successful_ride_percentage'] = round(($widget['completed_ride'] / $widget['total_ride']) * 100, 2);
        }

        $bidQuery            = Bid::where('driver_id', $driver->id);
        $allRideBid          = (clone $bidQuery)->count();
        $rideAcceptanceBid   = (clone $bidQuery)->where('status', Status::BID_ACCEPTED)->count();
        $rideCancellationBid = (clone $bidQuery)->where('status', Status::BID_CANCELED)->count();

        $widget['ride_acceptance_rate'] = 0;
        $widget['cancellation_rate']    = 0;
        if ($allRideBid > 0) {
            $widget['ride_acceptance_rate'] = round(($rideAcceptanceBid / $allRideBid) * 100, 2);
            $widget['cancellation_rate']    = round(($rideCancellationBid / $allRideBid) * 100, 2);
        }

        $paymentQuery = RidePayment::where('driver_id', $driver->id)->selectRaw('payment_type, COUNT(*) as total')
            ->groupBy('payment_type')
            ->get();
        $paymentTypes = [
            Status::PAYMENT_TYPE_CASH    => __('Cash'),
            Status::PAYMENT_TYPE_GATEWAY => __('Gateway'),
            Status::PAYMENT_TYPE_WALLET  => __('Wallet'),
        ];

        $reviews = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('driver_id', $driver->id)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate(), ['*'], 'review_page');
        $averageRating            = $reviews->avg('rating');
        $widget['average_rating'] = $averageRating ?? '-';

        $withdrawals = Withdrawal::with('driver')->where('driver_id', $driver->id)->where('status', '!=', Status::PAYMENT_INITIATE)->filter(['driver_id'])->searchable(['trx', 'driver:username'])->orderBy("id", getOrderBy())
            ->paginate(getPaginate(), ['*'], 'withdraw_page');

        return view('admin.analysis.driver', compact('pageTitle', 'widget', 'driver', 'paymentQuery', 'paymentTypes', 'reviews', 'withdrawals'));
    }

    public function paymentSpentReport(Request $request, $id)
    {
        $driver            = Driver::findOrFail($id);
        $today             = Carbon::today();
        $timePeriodDetails = $this->timePeriodDetails($today);
        $timePeriod        = (object) $timePeriodDetails[$request->time_period ?? 'daily'];
        $carbonMethod      = $timePeriod->carbon_method;
        $starDate          = $today->copy()->$carbonMethod($timePeriod->take);
        $endDate           = $today->copy();

        $spents = Ride::completed()
            ->where('driver_id', $driver->id)
            ->whereDate('created_at', '>=', $starDate)
            ->whereDate('created_at', '<=', $endDate)
            ->selectRaw('DATE_FORMAT(created_at, "' . $timePeriod->sql_date_format . '") as date,SUM(amount) as amount')
            ->orderBy('date', 'asc')
            ->groupBy('date')
            ->get();

        $data = [];

        for ($i = 0; $i < $timePeriod->take; $i++) {
            $date  = $today->copy()->$carbonMethod($i)->format($timePeriod->php_date_format);
            $spent = $spents->where('date', $date)->first();

            $spentAmount = $spent ? $spent->amount : 0;

            $data[$date] = [
                'spent_amount' => $spentAmount,
            ];
        }
        return response()->json($data);
    }

    private function timePeriodDetails($today): array
    {
        if (request()->date) {
            $date                 = explode('to', request()->date);
            $startDateForCustom   = Carbon::parse(trim($date[0]))->format('Y-m-d');
            $endDateDateForCustom = @$date[1] ? Carbon::parse(trim(@$date[1]))->format('Y-m-d') : $startDateForCustom;
        } else {
            $startDateForCustom   = $today->copy()->subDays(15);
            $endDateDateForCustom = $today->copy();
        }

        return [
            'daily'      => [
                'sql_date_format' => "%d %b,%Y",
                'php_date_format' => "d M,Y",
                'take'            => 15,
                'carbon_method'   => 'subDays',
                'start_date'      => $today->copy()->subDays(15),
                'end_date'        => $today->copy(),
            ],
            'weekly'     => [
                'sql_date_format' => "Week %u, %Y",
                'php_date_format' => "W, Y",
                'take'            => 7,
                'carbon_method'   => 'subWeeks',
                'start_date'      => $today->copy()->subWeeks(7),
                'end_date'        => $today->copy(),
            ],
            'monthly'    => [
                'sql_date_format' => "%b,%Y",
                'php_date_format' => "M,Y",
                'take'            => 12,
                'carbon_method'   => 'subMonths',
                'start_date'      => $today->copy()->subMonths(12),
                'end_date'        => $today->copy(),
            ],
            'yearly'     => [
                'sql_date_format' => '%Y',
                'php_date_format' => 'Y',
                'take'            => 12,
                'carbon_method'   => 'subYears',
                'start_date'      => $today->copy()->subYears(12),
                'end_date'        => $today->copy(),
            ],
            'date_range' => [
                'sql_date_format' => "%d %b,%Y",
                'php_date_format' => "d M,Y",
                'take'            => (int) Carbon::parse($startDateForCustom)->diffInDays(Carbon::parse($endDateDateForCustom)),
                'carbon_method'   => 'subDays',
                'start_date'      => $startDateForCustom,
                'end_date'        => $endDateDateForCustom,
            ],
        ];
    }
}
