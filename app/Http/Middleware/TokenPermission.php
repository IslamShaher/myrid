<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TokenPermission
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure  $next
     * @param  string  $permission
     * @return \Symfony\Component\HttpFoundation\Response
     */
    public function handle(Request $request, Closure $next, $permission): Response
    {
        $user = $request->user();

        // Debug log
        \Log::info('TokenPermission debug', [
            'permission' => $permission,
            'user_id'    => $user ? $user->id : null,
            'hasToken'   => $user && $user->currentAccessToken() ? true : false,
            'abilities'  => $user && $user->currentAccessToken()
                ? $user->currentAccessToken()->abilities
                : null,
        ]);

        if (
            !$user ||
            !$user->currentAccessToken() ||
            !in_array($permission, $user->currentAccessToken()->abilities)
        ) {
            $notify[] = "Unauthorized request";
            return apiResponse("unauthorized_request", "error", $notify);
        }

        return $next($request);
    }
}
