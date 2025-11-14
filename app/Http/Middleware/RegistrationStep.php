<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class RegistrationStep
{
    /**
     * Handle an incoming request.
     */
    public function handle(Request $request, Closure $next)
    {
        // DEV BYPASS: if dev-token header is present, skip registration checks.
        if ($request->header('dev-token') === 'ovoride-dev-123') {
            \Log::info('DEV TOKEN BYPASS', ['got' => $request->header('dev-token')]);
            return $next($request);
        }

        $user = auth()->user();
        if (!$user || !$user->profile_complete) {
            if ($request->is('api/*')) {
                $notify[] = 'Please complete your profile to go next';
                return apiResponse("profile_incomplete", "error", $notify, [
                    'user' => $user
                ]);
            } else {
                return to_route('user.data');
            }
        }

        return $next($request);
    }
}
