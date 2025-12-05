<?php
namespace App\Http\Controllers\Admin;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Models\Review;
use App\Models\Ride;
use App\Models\RidePayment;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;

class RiderAnalysisController extends Controller {
    public function allRiderAnalysis() {
        $pageTitle      = 'Rider Analysis';
        $rideQuery      = Ride::query();
        $completedRides = (clone $rideQuery)->completed();
        $canceledRides  = (clone $rideQuery)->canceled();

        $widget = [
            'total_ride'            => (clone $rideQuery)->count(),
            'completed_ride'        => (clone $completedRides)->count(),
            'canceled_ride'         => (clone $canceledRides)->count(),
            'total_distance_ride'   => getAmount((clone $completedRides)->sum('distance') ),
            'total_riding_time'     => getAmount((clone $completedRides)->sum('duration')),
            'average_fare_per_ride' => (clone $completedRides)->avg('amount'),
        ];

        $widget['successful_ride_percentage'] = 0;

        if ($widget['total_ride'] > 0) {
            $widget['successful_ride_percentage'] = round(($widget['completed_ride'] / $widget['total_ride']) * 100, 2);
        }

        $paymentQuery = RidePayment::selectRaw('payment_type, COUNT(*) as total')
            ->groupBy('payment_type')
            ->get();


        $paymentTypes = [
            Status::PAYMENT_TYPE_CASH    => __('Cash'),
            Status::PAYMENT_TYPE_GATEWAY => __('Gateway'),
        ];

        $reviews = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('user_id', '!=', 0)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());

        $averageRating            = $reviews->avg('rating');
        $widget['average_rating'] = $averageRating ?? '-';

        return view('admin.analysis.all.rider', compact('pageTitle', 'widget', 'paymentQuery', 'paymentTypes', 'reviews'));
    }

    public function allPaymentSpentReport(Request $request) {

        $today             = Carbon::today();
        $timePeriodDetails = $this->timePeriodDetails($today);
        $timePeriod        = (object) $timePeriodDetails[$request->time_period ?? 'daily'];
        $carbonMethod      = $timePeriod->carbon_method;
        $starDate          = $today->copy()->$carbonMethod($timePeriod->take);
        $endDate           = $today->copy();

        $spents = Ride::completed()
            ->where('user_id', '!=', 0)
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

    public function riderAnalysis($id) {
        
        $user = User::findOrFail($id);

        $pageTitle = 'Rider Analysis - ' . $user->username;

        $rideQuery      = Ride::where('user_id', $user->id);
        $completedRides = (clone $rideQuery)->completed();
        $canceledRides  = (clone $rideQuery)->canceled();

        $widget = [
            'total_ride'            => (clone $rideQuery)->count() ,
            'completed_ride'        => (clone $completedRides)->count() ,
            'canceled_ride'         => (clone $canceledRides)->count() ,
            'total_distance_ride'   => getAmount((clone $completedRides)->sum('distance')) ,
            'total_riding_time'     => getAmount((clone $completedRides)->sum('duration')) ,
            'average_fare_per_ride' => (clone $completedRides)->avg('amount') ,
        ];

        $widget['successful_ride_percentage'] = 0;
        if ($widget['total_ride'] > 0) {
            $widget['successful_ride_percentage'] = round(($widget['completed_ride'] / $widget['total_ride']) * 100, 2);
        }

        $paymentQuery = RidePayment::where('rider_id', $user->id)->selectRaw('payment_type, COUNT(*) as total')
            ->groupBy('payment_type')
            ->get();
        $paymentTypes = [
            Status::PAYMENT_TYPE_CASH    => __('Cash'),
            Status::PAYMENT_TYPE_GATEWAY => __('Gateway'),
            Status::PAYMENT_TYPE_WALLET  => __('Wallet'),
        ];

        $reviews = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('user_id', $user->id)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());
        $averageRating            = $reviews->avg('rating');
        $widget['average_rating'] = $averageRating ?? '-';

        return view('admin.analysis.rider', compact('pageTitle', 'widget', 'user', 'paymentQuery', 'paymentTypes', 'reviews'));
    }

    public function paymentSpentReport(Request $request, $id) {
        $user              = User::findOrFail($id);
        $today             = Carbon::today();
        $timePeriodDetails = $this->timePeriodDetails($today);
        $timePeriod        = (object) $timePeriodDetails[$request->time_period ?? 'daily'];
        $carbonMethod      = $timePeriod->carbon_method;
        $starDate          = $today->copy()->$carbonMethod($timePeriod->take);
        $endDate           = $today->copy();

        $spents = Ride::completed()
            ->where('user_id', $user->id)
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

    private function timePeriodDetails($today): array {
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
