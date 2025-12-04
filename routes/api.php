<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
use App\Http\Controllers\Api\ShuttleController;
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/
use App\Http\Controllers\Api\ShuttleController;

Route::prefix('shuttle')->middleware(['auth:sanctum', 'token.permission:auth_token'])->group(function () {
    Route::get('routes', [ShuttleController::class, 'index']);
    Route::post('match-route', [ShuttleController::class, 'matchRoute']);
    Route::post('create', [ShuttleController::class, 'create']);
});

// Driver Shuttle Routes
Route::namespace('Api\Driver')->prefix('driver/shuttle')->middleware(['auth:sanctum', 'token.permission:driver_token'])->group(function () {
    Route::get('routes', 'ShuttleDriverController@listRoutes');
    Route::post('start', 'ShuttleDriverController@startTrip');
    Route::post('arrive', 'ShuttleDriverController@arriveAtStop');
    Route::post('depart', 'ShuttleDriverController@departStop');
    Route::post('live-location', 'ShuttleDriverController@liveLocation');
});
Route::namespace("Api")->group(function () {
    Route::controller('AppController')->group(function () {
        Route::any('general-setting', 'generalSetting');
        Route::get('get-countries', 'getCountries');
        Route::get('language/{key}', 'getLanguage');
        Route::get('policies', 'policies');
        Route::get('faq', 'faq');
        Route::get('zones', 'zone');
    });
});

Route::namespace('Api\User')->group(function () {

    Route::namespace('Auth')->group(function () {
        Route::controller('LoginController')->group(function () {
            Route::post('login', 'login');
            Route::post('check-token', 'checkToken');
            Route::post('social-login', 'socialLogin');
            Route::post('dev-login', 'devLogin');
        });
        Route::post('register', 'RegisterController@register');
        Route::controller('ForgotPasswordController')->group(function () {
            Route::post('password/email', 'sendResetCodeEmail');
            Route::post('password/verify-code', 'verifyCode');
            Route::post('password/reset', 'reset');
        });
    });

    Route::middleware(['auth:sanctum', 'token.permission:auth_token'])->group(function () {

        Route::post('user-data-submit', 'UserController@userDataSubmit');

        //authorization
        Route::middleware('registration.complete')->controller('AuthorizationController')->group(function () {
            Route::get('authorization', 'authorization');
            Route::get('resend-verify/{type}', 'sendVerifyCode');
            Route::post('verify-email', 'emailVerification');
            Route::post('verify-mobile', 'mobileVerification');
        });

        Route::middleware(['registration.complete', 'check.status'])->group(function () {

            Route::controller('UserController')->group(function () {

                Route::get('dashboard', 'dashboard');
                Route::post('profile-setting', 'submitProfile');
                Route::post('change-password', 'submitPassword');

                Route::get('user-info', 'userInfo');

                //Report

                Route::any('payment/history', 'paymentHistory');

                Route::post('save-device-token', 'addDeviceToken');
                Route::get('push-notifications', 'pushNotifications');
                Route::post('push-notifications/read/{id}', 'pushNotificationsRead');

                Route::post('delete-account', 'deleteAccount');

                Route::post('pusher/auth/{socketId}/{channelName}', 'pusher');
            });

            Route::prefix('ride')->controller('RideController')->group(function () {
                Route::post('fare-and-distance', 'findFareAndDistance');
                Route::post('create', 'create');
                Route::get('bids/{id}', 'bids');
                Route::post('reject/{id}', 'reject');
                Route::post('accept/{bidId}', 'accept');
                Route::get('list', 'list');
                Route::post('cancel/{id}', 'cancel');
                Route::post('sos/{id}', 'sos');
                Route::get('details/{id}', 'details');
                Route::get('payment/{id}', 'payment');
                Route::post('payment/{id}', 'paymentSave');
                Route::get('receipt/{id}', 'receipt');
            });

            // Coupon
            Route::controller('CouponController')->group(function () {
                Route::get('coupons', 'coupons');
                Route::post('apply-coupon/{id}', 'applyCoupon');
                Route::post('remove-coupon/{id}', 'removeCoupon');
            });

            Route::controller('ReviewController')->group(function () {
                Route::get('review', 'review');
                Route::post('review/{id}', 'reviewStore');
                Route::get('get-driver-review/{driverId}', 'driverReview');
            });

            Route::controller('TicketController')->prefix('ticket')->group(function () {
                Route::get('/', 'supportTicket');
                Route::post('create', 'storeSupportTicket');
                Route::get('view/{ticket}', 'viewTicket');
                Route::post('reply/{id}', 'replyTicket');
                Route::post('close/{id}', 'closeTicket');
                Route::get('download/{attachment_id}', 'ticketDownload');
            });
            //message
            Route::controller('MessageController')->prefix('ride')->group(function () {
                Route::get('messages/{id}', 'messages');
                Route::post('send/message/{id}', 'messageSave');
            });
        });
        Route::get('logout', 'Auth\LoginController@logout');
    });
});

//start driver route
Route::namespace('Api\Driver')->prefix('driver')->group(function () {
    Route::namespace('Auth')->group(function () {
        Route::controller('LoginController')->group(function () {
            Route::post('login', 'login');
            Route::post('social-login', 'socialLogin');
        });
        Route::post('register', 'RegisterController@register');

        Route::controller('ForgotPasswordController')->group(function () {
            Route::post('password/email', 'sendResetCodeEmail');
            Route::post('password/verify-code', 'verifyCode');
            Route::post('password/reset', 'reset');
        });
    });

    Route::middleware(['auth:sanctum', 'token.permission:driver_token'])->group(function () {
        //authorization
        Route::post('driver-data-submit', 'DriverController@driverDataSubmit');
        Route::middleware('registration.complete')->group(function () {
            Route::controller('AuthorizationController')->group(function () {
                Route::get('authorization', 'authorization');
                Route::get('resend-verify/{type}', 'sendVerifyCode');
                Route::post('verify-email', 'emailVerification');
                Route::post('verify-mobile', 'mobileVerification');
                Route::post('verify-g2fa', 'g2faVerification');
            });

            Route::middleware(['check.status'])->group(function () {

                Route::controller('DriverController')->group(function () {
                    Route::get('dashboard', 'dashboard');
                    Route::get('driver-info', 'driverInfo');

                    Route::post('profile-setting', 'submitProfile');
                    Route::post('change-password', 'submitPassword');
                    Route::post('delete-account', 'accountDelete');

                    Route::post('pusher/auth/{socketId}/{channelName}', 'pusher');
                    
                    //Driver Verification
                    Route::get('driver-verification', 'driverVerification');
                    Route::post('driver-verification', 'driverVerificationStore');

                    //vehicle verification 
                    Route::get('vehicle-verification', 'vehicleVerification');
                    Route::post('vehicle-verification', 'vehicleVerificationStore');

                    //Report
                    Route::any('deposit/history', 'depositHistory');
                    Route::get('transactions', 'transactions');
                    Route::get('payment/history', 'paymentHistory');
                    Route::post('online-status', 'onlineStatus');

                    Route::post('save-device-token', 'addDeviceToken');

                    //2FA
                    Route::get('twofactor', 'show2faForm');
                    Route::post('twofactor/enable', 'create2fa');
                    Route::post('twofactor/disable', 'disable2fa');
                });

                Route::controller('ReviewController')->group(function () {
                    Route::get('review', 'review');
                    Route::post('review/{rideId}', 'reviewStore');
                    Route::get('get-rider-review/{riderId}', 'riderReview');
                });
                //Withdraw
                Route::middleware('driver.verification')->group(function () {
                    Route::controller('WithdrawController')->group(function () {
                        Route::get('withdraw-method', 'withdrawMethod');
                        Route::post('withdraw-request', 'withdrawStore');
                        Route::post('withdraw-request/confirm', 'withdrawSubmit');
                        Route::get('withdraw/history', 'withdrawLog');
                    });
                    // Rides
                    Route::controller('RideController')->prefix('rides')->group(function () {
                        Route::get('/', 'rides');
                        Route::get('details/{id}', 'details');
                        Route::post('start/{id}', 'start');
                        Route::post('end/{id}', 'end');
                        Route::get('list', 'list');
                        Route::post('received-cash-payment/{id}', 'receivedCashPayment');
                        Route::post('live-location/{id}', 'liveLocation');
                        Route::get('receipt/{id}', 'receipt');
                    });
                    //Bid
                    Route::controller('BidController')->prefix('bid')->group(function () {
                        Route::post('create/{id}', 'create');
                        Route::get('cancel/{id}', 'cancel');
                    });
                    //message
                    Route::controller('MessageController')->prefix('ride')->group(function () {
                        Route::get('messages/{id}', 'messages');
                        Route::post('send/message/{id}', 'messageSave');
                    });
                });
                //payment
                Route::controller('PaymentController')->group(function () {
                    Route::get('deposit/methods', 'methods');
                    Route::post('deposit/insert', 'depositInsert');
                });
                //ticket
                Route::controller('TicketController')->prefix('ticket')->group(function () {
                    Route::get('/', 'supportTicket');
                    Route::post('create', 'storeSupportTicket');
                    Route::get('view/{ticket}', 'viewTicket');
                    Route::post('reply/{id}', 'replyTicket');
                    Route::post('close/{id}', 'closeTicket');
                    Route::get('download/{attachment_id}', 'ticketDownload');
                });
            });
        });
        Route::get('logout', 'Auth\LoginController@logout');
    });
});

