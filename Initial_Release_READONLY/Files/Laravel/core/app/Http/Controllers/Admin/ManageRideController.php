<?php
namespace App\Http\Controllers\Admin;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Models\Bid;
use App\Models\Ride;
use App\Models\RideLocation;
use Illuminate\Http\Request;

class ManageRideController extends Controller {
    public function allRides() {
        $pageTitle = 'All Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function riderRides() {
        $pageTitle = 'All Rider Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->where('user_id', '!=', 0)->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function riderCompletedRides() {
        $pageTitle = 'Completed Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->completed()->where('user_id', '!=', 0)->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function riderCanceledRides() {
        $pageTitle = 'Canceled Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->canceled()->where('user_id', '!=', 0)->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function driverRides() {
        $pageTitle = 'All Driver Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->where('driver_id', '!=', 0)->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function driverCompletedRides() {
        $pageTitle = 'Completed Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->completed()->where('driver_id', '!=', 0)->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function driverCanceledRides() {
        $pageTitle = 'Canceled Rides';
        extract($this->rideData());
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->canceled()->where('driver_id', '!=', 0)->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function new () {
        $pageTitle = 'Pending Rides';
        extract($this->rideData('pending'));
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function running() {
        $pageTitle = 'Running Rides';
        extract($this->rideData('running'));
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function completed(Request $request) {
        $pageTitle = 'Completed Rides';
        extract($this->rideData('completed'));

        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    public function canceled() {
        $pageTitle = 'Canceled Rides';
        extract($this->rideData('canceled'));
        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }

    protected function rideData($scope = 'query') {
        $baseQuery = Ride::$scope()->with(['user', 'driver', 'sosAlert'])->withCount('bids')->searchable(['uid', 'user:username', 'driver:username'])->filter(['user_id', 'driver_id', 'applied_coupon_id', 'ride_type', 'service_id'])->orderBy('id', 'desc')->dateFilter();

        return [
            'baseQuery' => $baseQuery,
        ];
    }
    public function detail($id) {
        $pageTitle         = 'Ride Details';
        $ride              = Ride::with(['bids'])->findOrFail($id);
        $totalUserCancel   = Ride::where('user_id', $ride->user_id)->where('status', Status::RIDE_CANCELED)->where('canceled_user_type', Status::USER)->count();
        $totalDriverCancel = Ride::where('driver_id', $ride->driver_id)->where('status', Status::RIDE_CANCELED)->where('canceled_user_type', Status::DRIVER)->count();

        return view('admin.rides.details', compact('pageTitle', 'ride', 'totalUserCancel', 'totalDriverCancel'));
    }

    public function bid($id) {
        $ride      = Ride::FindOrFail($id);
        $pageTitle = "Bid List of Ride:" . $ride->uid;
        $bids      = Bid::with('driver')->searchable(['driver:username', 'bid_amount'])->where('ride_id', $ride->id)->paginate(getPaginate());
        return view('admin.rides.bid', compact('pageTitle', 'bids'));
    }

    private function callExportData($baseQuery) {
        return exportData($baseQuery, request()->export, "ride", "A4 landscape");
    }

    public function location($id) {
        $ride      = Ride::findOrFail($id);
        $pageTitle = "Ride Location";

        $rideLocations = RideLocation::where('ride_id', $ride->id)?->first()?->location ?? [
            [
                'latitude'  => $ride->pickup_latitude,
                'longitude' => $ride->pickup_longitude,
            ],
        ];

        return view('admin.rides.location', compact('pageTitle', 'ride', 'rideLocations'));
    }
    public function liveLocation($id) {
        $ride = Ride::find($id);

        if (! $ride) {
            return apiResponse('error', "error", ["Ride not found"]);
        }

        $count = session()->get('COUNT') ?? 1;

        if ($count >= 18) {
            $count = 1;
        }

        $rideLocation = RideLocation::where('ride_id', $ride->id)?->first();

        if (! $rideLocation) {
            return apiResponse('success', "success", [], [
                'rideLocation' => [
                    ["latitude" => $ride->pickup_latitude, "longitude" => $ride->pickup_longitude],
                ],
            ]);
        }

        return apiResponse('success', "success", [], [
            'rideLocation' => $rideLocation->location,
        ]);
    }
    public function tips(Request $request) {
        $pageTitle = 'All Tips Logs';
        extract($this->rideData('tips'));

        if (request()->export) {
            return $this->callExportData($baseQuery);
        }
        $rides = $baseQuery->paginate(getPaginate());
        return view('admin.rides.list', compact('pageTitle', 'rides'));
    }
}
