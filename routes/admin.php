
<?php

use Illuminate\Support\Facades\Route;

Route::namespace('Auth')->group(function () {
    Route::middleware('admin.guest')->group(function () {
        Route::controller('LoginController')->group(function () {
            Route::get('/', 'showLoginForm')->name('login');
            Route::post('/', 'login')->name('login.submit');
            Route::get('logout', 'logout')->middleware('admin')->withoutMiddleware('admin.guest')->name('logout');
        });
        // Admin Password Reset
        Route::controller('ForgotPasswordController')->prefix('password')->name('password.')->group(function () {
            Route::get('reset', 'showLinkRequestForm')->name('reset');
            Route::post('reset', 'sendResetCodeEmail');
            Route::get('code-verify', 'codeVerify')->name('code.verify');
            Route::post('verify-code', 'verifyCode')->name('verify.code');
        });

        Route::controller('ResetPasswordController')->group(function () {
            Route::get('password/reset/{token}', 'showResetForm')->name('password.reset.form');
            Route::post('password/reset/change', 'reset')->name('password.change');
        });
    });
});


Route::middleware('admin')->group(function () {

    //zone
    Route::controller('ZoneController')->prefix('zone')->name('zone.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view zone,admin');
        Route::get('create', 'create')->name('create')->middleware('permission:add zone,admin');
        Route::get('edit/{id}', 'edit')->name('edit')->middleware('permission:edit zone,admin');
        Route::post('save/{id}', 'save')->name('save')->middleware('permission:edit zone,admin');
        Route::post('change-status/{id}', 'changeStatus')->name('status')->middleware('permission:edit zone,admin');
    });

    //Service
    Route::controller('ServiceController')->prefix('services')->name('service.')->group(function () {
        Route::get('index', 'index')->name('index')->middleware('permission:view service,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add service,admin');
        Route::post('update/{id}', 'store')->name('update')->middleware('permission:edit service,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:edit service,admin');
    });

    //Brands
    Route::controller('BrandController')->prefix('brands')->name('brand.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view brand,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:edit brand,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add brand,admin');
        Route::post('update/{id}', 'store')->name('update')->middleware('permission:edit brand,admin');
    });
    //model
    Route::controller('VehicleModelController')->prefix('vehicle-model')->name('model.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view vehicle model,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:edit vehicle model,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add vehicle model,admin');
        Route::post('update/{id}', 'store')->name('update')->middleware('permission:edit vehicle model,admin');
    });
    //color
    Route::controller('VehicleColorController')->prefix('vehicle-color')->name('color.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view vehicle color,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:edit vehicle color,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add vehicle color,admin');
        Route::post('update/{id}', 'store')->name('update')->middleware('permission:edit vehicle color,admin');
    });
    
    //year
    Route::controller('VehicleYearController')->prefix('vehicle-year')->name('year.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view vehicle year,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:edit vehicle year,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add vehicle year,admin');
        Route::post('update/{id}', 'store')->name('update')->middleware('permission:edit vehicle year,admin');
    });

    //Coupons
    Route::controller('CouponController')->prefix('coupon')->name('coupon.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view coupon,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add coupon,admin');
        Route::post('update/{id}', 'store')->name('update')->middleware('permission:edit coupon,admin');
        Route::post('change-status/{id}', 'changeStatus')->name('status.change')->middleware('permission:edit coupon,admin');
    });

    Route::controller('ManageReviewController')->name('reviews.')->prefix('reviews')->group(function () {
        Route::get('/', 'reviews')->name('all')->middleware('permission:all reviews,admin');
    });

    Route::controller('ManageRideController')->middleware('permission:view rides,admin')->name('rides.')->prefix('rides')->group(function () {
        Route::get('/', 'allRides')->name('all');
        Route::get('new', 'new')->name('new');
        Route::get('running', 'running')->name('running');
        Route::get('completed', 'completed')->name('completed');
        Route::get('canceled', 'canceled')->name('canceled');
        Route::get('detail/{id}', 'detail')->name('detail');
        Route::get('bids/{id}', 'bid')->name('bids');
    });

    // Users Manager
    Route::controller('ManageRiderController')->name('rider.')->prefix('rider')->group(function () {
        Route::get('/', 'allUsers')->name('all')->middleware('permission:view riders,admin');
        Route::get('active', 'activeUsers')->name('active')->middleware('permission:view riders,admin');
        Route::get('banned', 'bannedUsers')->name('banned')->middleware('permission:view riders,admin');
        Route::get('email-verified', 'emailVerifiedUsers')->name('email.verified')->middleware('permission:view riders,admin');
        Route::get('email-unverified', 'emailUnverifiedUsers')->name('email.unverified')->middleware('permission:view riders,admin');
        Route::get('mobile-unverified', 'mobileUnverifiedUsers')->name('mobile.unverified')->middleware('permission:view riders,admin');
        Route::get('mobile-verified', 'mobileVerifiedUsers')->name('mobile.verified')->middleware('permission:view riders,admin');

        Route::get('detail/{id}', 'detail')->name('detail')->middleware('permission:view riders,admin');
        Route::post('update/{id}', 'update')->name('update')->middleware('permission:update riders,admin');
        Route::post('add-sub-balance/{id}', 'addSubBalance')->name('add.sub.balance')->middleware('permission:update riders,admin');
        Route::get('send-notification/{id}', 'showNotificationSingleForm')->name('notification.single')->middleware('permission:send notification to riders,admin');
        Route::post('send-notification/{id}', 'sendNotificationSingle')->name('notification.single.get')->middleware('permission:send notification to riders,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:update riders,admin');

        Route::get('send-notification', 'showNotificationAllForm')->name('notification.all')->middleware('permission:send notification to riders,admin');
        Route::post('send-notification', 'sendNotificationAll')->name('notification.all.send')->middleware('permission:send notification to riders,admin');
        Route::get('list', 'list')->name('list');
        Route::get('count-by-segment/{methodName}', 'countBySegment')->name('segment.count');
        Route::get('notification-log/{id}', 'notificationLog')->name('notification.log')->middleware('permission:view rider notifications,admin');
    });

    //Rider Rules
    Route::controller('RiderRuleController')->prefix('rider/rules')->name('rider.rule.')->group(function () {
        Route::get('index', 'index')->name('index')->middleware('permission:view rider rule,admin');
        Route::post('store', 'store')->name('store')->middleware('permission:add rider rule,admin');
        Route::post('update/{id?}', 'store')->name('update')->middleware('permission:edit rider rule,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:edit rider rule,admin');
    });

    // Driver Manager
    Route::controller('ManageDriversController')->name('driver.')->prefix('drivers')->group(function () {
        Route::get('/', 'allDrivers')->name('all')->middleware('permission:view drivers,admin');
        Route::get('active', 'activeDrivers')->name('active')->middleware('permission:view drivers,admin');
        Route::get('banned', 'bannedDrivers')->name('banned')->middleware('permission:view drivers,admin');
        Route::get('email-verified', 'emailVerifiedDrivers')->name('email.verified')->middleware('permission:view drivers,admin');
        Route::get('email-unverified', 'emailUnverifiedDrivers')->name('email.unverified')->middleware('permission:view drivers,admin');
        Route::get('mobile-unverified', 'mobileUnverifiedDrivers')->name('mobile.unverified')->middleware('permission:view drivers,admin');
        Route::get('unverified', 'unverifiedDrivers')->name('unverified')->middleware('permission:view drivers,admin');
        Route::get('verify-pending', 'verifyPendingDrivers')->name('verify.pending')->middleware('permission:view drivers,admin');


        Route::get('vehicle-unverified', 'vehicleUnverifiedDrivers')->name('vehicle.unverified')->middleware('permission:view drivers,admin');
        Route::get('vehicle-verify-pending', 'vehiclePendingDrivers')->name('vehicle.verify.pending')->middleware('permission:view drivers,admin');

        Route::get('mobile-verified', 'mobileVerifiedDrivers')->name('mobile.verified')->middleware('permission:view drivers,admin');

        Route::get('detail/{id}', 'detail')->name('detail')->middleware('permission:view drivers,admin');
        Route::get('verification/details/{id}', 'verificationDetails')->name('verification.details');
        Route::post('verification-approve/{id}', 'verificationApprove')->name('verification.approve');
        Route::post('verification-reject/{id}', 'verificationReject')->name('verification.reject');
        Route::post('vehicle-approve/{id}', 'vehicleApprove')->name('vehicle.approve');
        Route::post('vehicle-reject/{id}', 'vehicleReject')->name('vehicle.reject');
        Route::get('rides/rules/{id}', 'rideRules')->name('rides.rules');

        Route::post('update/{id}', 'update')->name('update');
        Route::post('add-sub-balance/{id}', 'addSubBalance')->name('add.sub.balance')->middleware('permission:update driver balance,admin');
        Route::get('send-notification/{id}', 'showNotificationSingleForm')->name('notification.single')->middleware('permission:notification to all drivers,admin');
        Route::post('send-notification/{id}', 'sendNotificationSingle')->name('notification.single')->middleware('permission:notification to all drivers,admin');
        Route::post('status/{id}', 'status')->name('status');
        Route::post('account/delete/{id}', 'deleteAccount')->name('delete.account');

        Route::get('send-notification', 'showNotificationAllForm')->name('notification.all')->middleware('permission:notification to all drivers,admin');
        Route::post('send-notification', 'sendNotificationAll')->name('notification.all.send')->middleware('permission:notification to all drivers,admin');
        Route::get('list', 'list')->name('list');
        Route::get('count-by-segment/{methodName}', 'countBySegment')->name('segment.count');
        Route::get('notification-log/{id}', 'notificationLog')->name('notification.log')->middleware('permission:view driver notifications,admin');
    });

    // role & permission
    Route::controller('RoleController')->name('role.')->prefix('role')->group(function () {
        Route::get('list', 'list')->name('list')->middleware('permission:view roles,admin');
        Route::post('create', 'save')->name('create')->middleware('permission:add role,admin');
        Route::post('update/{id}', 'save')->name('update')->middleware('permission:edit role,admin');
        Route::post('status-change/{id}', 'status')->name('status.change')->middleware('permission:edit role,admin');
        Route::get('permission/{id}', 'permission')->name('permission')->middleware('permission:assign permissions,admin');
        Route::post('permission/update/{id}', 'permissionUpdate')->name('permission.update')->middleware('permission:assign permissions,admin');
    });

    // Subscriber
    Route::controller('SubscriberController')->middleware('permission:manage subscribers,admin')->prefix('subscriber')->name('subscriber.')->group(function () {
        Route::get('/', 'index')->name('index');
        Route::get('send-email', 'sendEmailForm')->name('send.email');
        Route::post('remove/{id}', 'remove')->name('remove');
        Route::post('send-email', 'sendEmail')->name('send.email');
    });

    // Report
    Route::controller('ReportController')->name('report.')->prefix('report')->group(function () {
        Route::prefix('rider')->name('rider.')->group(function () {
            Route::get('rider-payment', 'riderPayment')->name('payment')->middleware('permission:view rider payment report,admin');
            Route::get('login/history', 'loginHistory')->name('login.history')->middleware('permission:view rider login history,admin');
            Route::get('login/ipHistory/{ip}', 'loginIpHistory')->name('login.ipHistory')->middleware('permission:view rider login history,admin');
            Route::get('notification/history', 'notificationHistory')->name('notification.history')->middleware('permission:view rider notification history,admin');
            Route::get('email/detail/{id}', 'emailDetails')->name('email.details');
        });
        Route::prefix('driver')->name('driver.')->group(function () {
            Route::get('transaction', 'transaction')->name('transaction')->middleware('permission:view driver transaction history,admin');
            Route::get('commission', 'commission')->name('commission')->middleware('permission:view driver commission history,admin');
            Route::get('login/history', 'loginHistoryDriver')->name('login.history')->middleware('permission:view driver login history,admin');
            Route::get('login/ipHistory/{ip}', 'loginIpHistory')->name('login.ipHistory')->middleware('permission:view driver login history,admin');
            Route::get('notification/history', 'notificationHistoryDriver')->name('notification.history')->middleware('permission:view driver notification history,admin');
            Route::get('email/detail/{id}', 'emailDetails')->name('email.details');
        });
    });

    // Admin Support
    Route::controller('SupportTicketController')->prefix('ticket')->name('ticket.')->group(function () {
        Route::get('/', 'tickets')->name('index')->middleware('permission:view user tickets,admin');
        Route::get('pending', 'pendingTicket')->name('pending')->middleware('permission:view user tickets,admin');
        Route::get('closed', 'closedTicket')->name('closed')->middleware('permission:view user tickets,admin');
        Route::get('answered', 'answeredTicket')->name('answered')->middleware('permission:view user tickets,admin');
        Route::get('view/{id}', 'ticketReply')->name('view')->middleware('permission:view user tickets,admin');
        Route::post('reply/{id}', 'replyTicket')->name('reply')->middleware('permission:answer tickets,admin');
        Route::post('close/{id}', 'closeTicket')->name('close')->middleware('permission:close tickets,admin');
        Route::get('download/{attachment_id}', 'ticketDownload')->name('download');
        Route::post('delete/{id}', 'ticketDelete')->name('delete');
    });


    Route::controller('AdminController')->group(function () {
        Route::get('dashboard', 'dashboard')->name('dashboard')->middleware('permission:view dashboard,admin');
        Route::get('chart/deposit-withdraw', 'depositAndWithdrawReport')->name('chart.deposit.withdraw')->middleware('permission:view dashboard,admin');
        Route::get('chart/transaction', 'transactionReport')->name('chart.transaction')->middleware('permission:view dashboard,admin');
        Route::get('profile', 'profile')->name('profile');
        Route::post('profile', 'profileUpdate')->name('profile.update');
        Route::get('password', 'password')->name('password');
        Route::post('password', 'passwordUpdate')->name('password.update');

        //Notification
        Route::get('notifications', 'notifications')->name('notifications')->middleware('permission:notification settings,admin');
        Route::get('notification/read/{id}', 'notificationRead')->name('notification.read')->middleware('permission:notification settings,admin');
        Route::get('notifications/read-all', 'readAllNotification')->name('notifications.read.all')->middleware('permission:notification settings,admin');
        Route::post('notifications/delete-all', 'deleteAllNotification')->name('notifications.delete.all')->middleware('permission:notification settings,admin');
        Route::post('notifications/delete-single/{id}', 'deleteSingleNotification')->name('notifications.delete.single')->middleware('permission:notification settings,admin');

        //Report Bugs
        Route::get('download-attachments/{file_hash}', 'downloadAttachment')->name('download.attachment');
        Route::get('send/promotional-notification', 'showPromotionalNotificationForm')->name('promotional.notification.all')->middleware('permission:promotional notify,admin');
        Route::post('send-promotional-notification', 'sendPromotionalNotificationAll')->name('promotional.notification.all.send');

        // Assign role
        Route::get('list', 'list')->name('list')->middleware('permission:view admin,admin');
        Route::post('store', 'save')->name('store')->middleware('permission:add admin,admin');
        Route::post('update/{id}', 'save')->name('update')->middleware('permission:edit admin,admin');
        Route::post('status-change/{id}', 'status')->name('status.change')->middleware('permission:edit admin,admin');
    });

    // extensions
    Route::controller('ExtensionController')->prefix('extensions')->name('extensions.')->group(function () {
        Route::get('/', 'index')->name('index')->middleware('permission:view extension,admin');
        Route::post('update/{id}', 'update')->name('update')->middleware('permission:update extension,admin');
        Route::post('status/{id}', 'status')->name('status')->middleware('permission:update extension,admin');
    });

    // Language Manager
    Route::controller('LanguageController')->prefix('language')->name('language.')->group(function () {
        Route::get('/', 'langManage')->name('manage')->middleware('permission:view language,admin');
        Route::post('/', 'langStore')->name('manage.store')->middleware('permission:update language,admin');
        Route::post('delete/{id}', 'langDelete')->name('manage.delete')->middleware('permission:update language,admin');
        Route::post('update/{id}', 'langUpdate')->name('manage.update')->middleware('permission:update language,admin');
        Route::get('edit/{id}', 'langEdit')->name('key')->middleware('permission:update language,admin');
        Route::post('import', 'langImport')->name('import.lang')->middleware('permission:update language,admin');
        Route::post('store/key/{id}', 'storeLanguageJson')->name('store.key')->middleware('permission:update language,admin');
        Route::post('delete/key/{id}/{key}', 'deleteLanguageJson')->name('delete.key')->middleware('permission:update language,admin');
        Route::post('update/key/{id}', 'updateLanguageJson')->name('update.key')->middleware('permission:update language,admin');
        Route::get('get-keys', 'getKeys')->name('get.key')->middleware('permission:update language,admin');
    });


    //Notification Setting
    Route::name('setting.notification.')->middleware('permission:notification settings,admin')->controller('NotificationController')->prefix('notification')->group(function () {
        //Template Setting
        Route::get('global/email', 'globalEmail')->name('global.email');
        Route::post('global/email/update', 'globalEmailUpdate')->name('global.email.update');

        Route::get('global/sms', 'globalSms')->name('global.sms');
        Route::post('global/sms/update', 'globalSmsUpdate')->name('global.sms.update');

        Route::get('global/push', 'globalPush')->name('global.push');
        Route::post('global/push/update', 'globalPushUpdate')->name('global.push.update');

        Route::get('templates', 'templates')->name('templates');
        Route::get('template/edit/{type}/{id}', 'templateEdit')->name('template.edit');
        Route::post('template/update/{type}/{id}', 'templateUpdate')->name('template.update');

        //Email Setting
        Route::get('email/setting', 'emailSetting')->name('email');
        Route::post('email/setting', 'emailSettingUpdate');
        Route::post('email/test', 'emailTest')->name('email.test');

        //SMS Setting
        Route::get('sms/setting', 'smsSetting')->name('sms');
        Route::post('sms/setting', 'smsSettingUpdate');
        Route::post('sms/test', 'smsTest')->name('sms.test');

        //WhatsApp Setting
        Route::get('whatsapp/setting', 'whatsappSetting')->name('whatsapp');
        Route::post('whatsapp/setting', 'whatsappSettingUpdate');
        Route::post('whatsapp/test', 'whatsappTest')->name('whatsapp.test');

        Route::get('notification/push/setting', 'pushSetting')->name('push');
        Route::post('notification/push/setting', 'pushSettingUpdate');
        Route::post('notification/push/setting/upload', 'pushSettingUpload')->name('push.upload');
        Route::get('notification/push/setting/download', 'pushSettingDownload')->name('push.download');
    });

    //KYC setting
    Route::controller('KycController')->group(function () {
        Route::get('driver-verification', 'driverVerification')->name('verification.driver.form')->middleware('permission:view driver verification form,admin');
        Route::post('driver-verification', 'driverVerificationUpdate')->name('verification.driver.update')->middleware('permission:update driver verification form,admin');

        Route::get('vehicle-verification', 'vehicleVerification')->name('vehicle.verification.form')->middleware('permission:view vehicle verification form,admin');
        Route::post('vehicle-verification', 'vehicleVerificationUpdate')->name('vehicle.verification.update')->middleware('permission:update vehicle verification form,admin');
    });

    // DEPOSIT SYSTEM
    Route::controller('DepositController')->prefix('deposit')->name('deposit.')->group(function () {
        Route::get('all', 'deposit')->name('list')->middleware('permission:view driver deposits,admin');
        Route::get('pending', 'pending')->name('pending')->middleware('permission:view driver deposits,admin');
        Route::get('rejected', 'rejected')->name('rejected')->middleware('permission:view driver deposits,admin');
        Route::get('approved', 'approved')->name('approved')->middleware('permission:view driver deposits,admin');
        Route::get('successful', 'successful')->name('successful')->middleware('permission:view driver deposits,admin');
        Route::get('initiated', 'initiated')->name('initiated')->middleware('permission:view driver deposits,admin');
        Route::get('details/{id}', 'details')->name('details')->middleware('permission:view driver deposits,admin');
        Route::post('reject', 'reject')->name('reject')->middleware('permission:reject driver deposits,admin');
        Route::post('approve/{id}', 'approve')->name('approve')->middleware('permission:approve driver deposits,admin');
    });


    // WITHDRAW SYSTEM
    Route::name('withdraw.')->prefix('withdraw')->group(function () {

        Route::controller('WithdrawalController')->name('data.')->group(function () {
            Route::get('pending/{user_id?}', 'pending')->name('pending')->middleware('permission:view driver withdrawals,admin');
            Route::get('approved/{user_id?}', 'approved')->name('approved')->middleware('permission:view driver withdrawals,admin');
            Route::get('rejected/{user_id?}', 'rejected')->name('rejected')->middleware('permission:view driver withdrawals,admin');
            Route::get('all/{user_id?}', 'all')->name('all')->middleware('permission:view driver withdrawals,admin');
            Route::get('details/{id}', 'details')->name('details')->middleware('permission:view driver withdrawals,admin');
            Route::post('approve', 'approve')->name('approve')->middleware('permission:approve driver withdrawals,admin');
            Route::post('reject', 'reject')->name('reject')->middleware('permission:reject driver withdrawals,admin');
        });


        // Withdraw Method
        Route::controller('WithdrawMethodController')->prefix('method')->name('method.')->group(function () {
            Route::get('/', 'methods')->name('index')->middleware('permission:view withdrawals methods,admin');
            Route::get('create', 'create')->name('create')->middleware('permission:update withdrawals methods,admin');
            Route::post('create', 'store')->name('store')->middleware('permission:update withdrawals methods,admin');
            Route::get('edit/{id}', 'edit')->name('edit')->middleware('permission:update withdrawals methods,admin');
            Route::post('edit/{id}', 'update')->name('update')->middleware('permission:update withdrawals methods,admin');
            Route::post('status/{id}', 'status')->name('status')->middleware('permission:update withdrawals methods,admin');
        });
    });

    // SEO
    Route::get('seo', 'FrontendController@seoEdit')->name('seo')->middleware(('permission:view seo,admin'));

    // Frontend
    Route::name('frontend.')->prefix('frontend')->group(function () {

        Route::controller('FrontendController')->middleware('permission:manage sections,admin')->group(function () {
            Route::get('index', 'index')->name('index');
            Route::get('templates', 'templates')->name('templates');
            Route::post('templates', 'templatesActive')->name('templates.active');
            Route::get('frontend-sections/{key?}', 'frontendSections')->name('sections');
            Route::post('frontend-content/{key}', 'frontendContent')->name('sections.content');
            Route::get('frontend-element/{key}/{id?}', 'frontendElement')->name('sections.element');
            Route::get('frontend-slug-check/{key}/{id?}', 'frontendElementSlugCheck')->name('sections.element.slug.check');
            Route::get('frontend-element-seo/{key}/{id}', 'frontendSeo')->name('sections.element.seo');
            Route::post('frontend-element-seo/{key}/{id}', 'frontendSeoUpdate');
            Route::post('remove/{id}', 'remove')->name('remove');
        });

        // Page Builder
        Route::controller('PageBuilderController')->middleware('permission:manage pages,admin')->group(function () {
            Route::get('manage-pages', 'managePages')->name('manage.pages');
            Route::get('manage-pages/check-slug/{id?}', 'checkSlug')->name('manage.pages.check.slug');
            Route::post('manage-pages', 'managePagesSave')->name('manage.pages.save');
            Route::post('manage-pages/update', 'managePagesUpdate')->name('manage.pages.update');
            Route::post('manage-pages/delete/{id}', 'managePagesDelete')->name('manage.pages.delete');
            Route::get('manage-section/{id}', 'manageSection')->name('manage.section');
            Route::post('manage-section/{id}', 'manageSectionUpdate')->name('manage.section.update');

            Route::get('manage-seo/{id}', 'manageSeo')->name('manage.pages.seo');
            Route::post('manage-seo/{id}', 'manageSeoStore');
        });
    });

    //System Information
    Route::controller('SystemController')->name('system.')->prefix('system')->group(function () {
        Route::get('info', 'systemInfo')->name('info')->middleware('permission:view application info,admin');
        Route::get('optimize-clear', 'optimizeClear')->name('optimize.clear');
    });


    Route::controller('GeneralSettingController')->group(function () {


        // General Setting
        Route::get('general-setting', 'general')->name('setting.general')->middleware('permission:general settings,admin');
        Route::post('general-setting', 'generalUpdate')->middleware('permission:general settings,admin');


        //configuration
        Route::get('setting/system-configuration', 'systemConfiguration')->name('setting.system.configuration')->middleware('permission:system configuration,admin');
        Route::get('setting/system-configuration/{key}', 'systemConfigurationUpdate')->name("setting.system.configuration.update")->middleware('permission:system configuration,admin');

        // Logo-Icon
        Route::get('setting/brand', 'logoIcon')->name('setting.brand')->middleware('permission:brand settings,admin');
        Route::post('setting/brand', 'logoIconUpdate')->name('setting.brand')->middleware('permission:brand settings,admin');

        //Custom CSS
        Route::get('custom-css', 'customCss')->name('setting.custom.css')->middleware('permission:custom css,admin');
        Route::post('custom-css', 'customCssSubmit')->middleware('permission:custom css,admin');

        Route::get('sitemap', 'sitemap')->name('setting.sitemap')->middleware('permission:sitemap,admin');
        Route::post('sitemap', 'sitemapSubmit')->middleware('permission:sitemap,admin');

        Route::get('robot', 'robot')->name('setting.robot')->middleware('permission:robot,admin');
        Route::post('robot', 'robotSubmit')->middleware('permission:robot,admin');

        //Cookie
        Route::get('cookie', 'cookie')->name('setting.cookie')->middleware('permission:gdpr cookie,admin');
        Route::post('cookie', 'cookieSubmit')->middleware('permission:gdpr cookie,admin');

        //maintenance_mode
        Route::get('maintenance-mode', 'maintenanceMode')->name('maintenance.mode')->middleware('permission:maintenance mode,admin');
        Route::post('maintenance-mode', 'maintenanceModeSubmit')->middleware('permission:maintenance mode,admin');
    });
    // Deposit Gateway
    Route::name('gateway.')->prefix('gateway')->group(function () {

        // Manual Methods
        Route::controller('ManualGatewayController')->middleware('permission:update payment gateway,admin')->prefix('manual')->name('manual.')->group(function () {
            Route::get('new', 'create')->name('create');
            Route::post('new', 'store')->name('store');
            Route::get('edit/{alias}', 'edit')->name('edit');
            Route::post('update/{id}', 'update')->name('update');
            Route::post('status/{id}', 'status')->name('status');
        });

        // Automatic Gateway
        Route::controller('AutomaticGatewayController')->name('automatic.')->group(function () {
            Route::get('/', 'index')->name('index')->middleware('permission:view payment gateway,admin');
            Route::get('edit/{alias}', 'edit')->name('edit')->middleware('permission:update payment gateway,admin');
            Route::post('update/{code}', 'update')->name('update')->middleware('permission:update payment gateway,admin');
            Route::post('remove/{id}', 'remove')->name('remove')->middleware('permission:update payment gateway,admin');
            Route::post('status/{id}', 'status')->name('status')->middleware('permission:update payment gateway,admin');
        });
    });



    //cron
    Route::controller('CronConfigurationController')->middleware('permission:cron job settings,admin')->name('cron.')->prefix('cron')->group(function () {
        Route::get('index', 'cronJobs')->name('index');
        Route::post('store', 'cronJobStore')->name('store');
        Route::post('update/{id}', 'cronJobUpdate')->name('update');
        Route::post('delete/{id}', 'cronJobDelete')->name('delete');
        Route::get('schedule', 'schedule')->name('schedule');
        Route::post('schedule/store/{id?}', 'scheduleStore')->name('schedule.store');
        Route::post('schedule/status/{id}', 'scheduleStatus')->name('schedule.status');
        Route::get('schedule/pause/{id}', 'schedulePause')->name('schedule.pause');
        Route::get('schedule/logs/{id}', 'scheduleLogs')->name('schedule.logs');
        Route::post('schedule/log/resolved/{id}', 'scheduleLogResolved')->name('schedule.log.resolved');
        Route::post('schedule/log/flush/{id}', 'logFlush')->name('log.flush');
    });
});
