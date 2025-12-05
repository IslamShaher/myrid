<?php

namespace App\Http\Controllers;

use App\Constants\Status;
use App\Lib\CurlRequest;
use App\Lib\ManageRideQueue;
use App\Models\CronJob;
use App\Models\CronJobLog;
use App\Models\Driver;
use App\Models\Ride;
use App\Models\RideQueue;
use Carbon\Carbon;
use Exception;

use function Laravel\Prompts\info;
use function Symfony\Component\Clock\now;

class CronController extends Controller
{
    public function cron()
    {
        $general            = gs();
        $general->last_cron = now();
        $general->save();

        $crons = CronJob::with('schedule');

        if (request()->alias) {
            $crons->where('alias', request()->alias);
        } else {
            $crons->where('next_run', '<', now())->where('is_running', Status::YES);
        }

        $crons = $crons->get();

        foreach ($crons as $cron) {
            $cronLog              = new CronJobLog();
            $cronLog->cron_job_id = $cron->id;
            $cronLog->start_at    = now();
            if ($cron->is_default) {
                $controller = new $cron->action[0];
                try {
                    $method = $cron->action[1];
                    $controller->$method();
                } catch (\Exception $e) {
                    $cronLog->error = $e->getMessage();
                }
            } else {
                try {
                    CurlRequest::curlContent($cron->url);
                } catch (\Exception $e) {
                    $cronLog->error = $e->getMessage();
                }
            }
            $cron->last_run = now();
            $cron->next_run = Carbon::now()->addSeconds($cron->schedule->interval);
            $cron->save();

            $cronLog->end_at = $cron->last_run;

            $startTime         = Carbon::parse($cronLog->start_at);
            $endTime           = Carbon::parse($cronLog->end_at);
            $diffInSeconds     = $startTime->diffInSeconds($endTime);
            $cronLog->duration = $diffInSeconds;
            $cronLog->save();
        }

        if (request()->target == 'all') {
            $notify[] = ['success', 'Cron executed successfully'];
            return back()->withNotify($notify);
        }

        if (request()->alias) {
            $notify[] = ['success', keyToTitle(request()->alias) . ' executed successfully'];
            return back()->withNotify($notify);
        }
    }

    public function cancelRide(): void
    {
        try {
            $rideCancelMinute = gs('ride_cancel_time');
            if (!$rideCancelMinute || $rideCancelMinute <= 0) return;
            $cancelTime = Carbon::now()->subMinutes($rideCancelMinute);
            Ride::pending()->where('created_at', "<", $cancelTime)->update(['status' => Status::RIDE_CANCELED]);
        } catch (Exception $ex) {
            throw new Exception($ex->getMessage());
        }
    }


    public function rideQueue()
    {
        $executionTimeRemaining = 45;

        while ($executionTimeRemaining  > 0) {

            $iterationStart = Carbon::now();
            $rideQueue      = RideQueue::orderBy('ordering')->where('dispatch_count', 0)->first();

            if ($rideQueue) {

                if ($rideQueue->dispatch_count == 0) {
                    $rideQueue->dispatch_count = 1;
                    $rideQueue->save();
                }

                (new ManageRideQueue())->initQueue($rideQueue);
            }

            $iterationEnd            = Carbon::now();
            $iterationDuration       = $iterationStart->diffInSeconds($iterationEnd);
            $executionTimeRemaining -= $iterationDuration;
        }
    }
}
