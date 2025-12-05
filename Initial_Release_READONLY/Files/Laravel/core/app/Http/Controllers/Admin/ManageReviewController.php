<?php
namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Driver;
use App\Models\Review;
use App\Models\User;

class ManageReviewController extends Controller {
    public function reviews() {
        $pageTitle = 'All Reviews';
        $reviews   = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());
        return view('admin.reviews.all', compact('pageTitle', 'reviews'));
    }

    public function allRiderReviews() {
        $pageTitle = 'All Rider Reviews';
        $reviews   = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('user_id', '!=', 0)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());
        return view('admin.reviews.all', compact('pageTitle', 'reviews'));
    }

    public function riderReviews($id) {
        $rider    = User::findOrFail($id);
        $pageTitle = 'Rider Reviews - ' . $rider->username;
        $reviews   = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('user_id',  $rider->id)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());
        return view('admin.reviews.all', compact('pageTitle', 'reviews'));
    }

    public function allDriverReviews() {
        $pageTitle = 'All Driver Reviews';
        $reviews   = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('driver_id', '!=', 0)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());
        return view('admin.reviews.all', compact('pageTitle', 'reviews'));
    }

    public function driverReviews($id) {
        $driver    = Driver::findOrFail($id);
        $pageTitle = 'Driver Reviews - ' . $driver->username;
        $reviews   = Review::with(['ride', 'ride.user', 'ride.driver', 'driver'])
            ->where('driver_id', $driver->id)
            ->searchable(['ride:uid', 'user:username', 'driver:username'])
            ->orderBy("id", getOrderBy())
            ->paginate(getPaginate());
        return view('admin.reviews.all', compact('pageTitle', 'reviews'));
    }
}
