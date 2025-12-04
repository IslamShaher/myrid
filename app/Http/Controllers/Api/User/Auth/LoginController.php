<?php

namespace App\Http\Controllers\Api\User\Auth;

use App\Constants\Status;
use App\Http\Controllers\Controller;
use App\Lib\SocialLogin;
use App\Models\User;
use App\Models\UserLogin;
use Illuminate\Foundation\Auth\AuthenticatesUsers;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Laravel\Sanctum\PersonalAccessToken;

class LoginController extends Controller
{
    /*
    |--------------------------------------------------------------------------
    | Login Controller
    |--------------------------------------------------------------------------
    |
    | This controller handles authenticating users for the application and
    | redirecting them to your home screen. The controller uses a trait
    | to conveniently provide its functionality to your applications.
    |
    */

    use AuthenticatesUsers;

    /**
     * Where to redirect users after login.
     *
     * @var string
     */

    protected $username;

    /**
     * Create a new controller instance.
     *
     * @return void
     */


    public function __construct()
    {
        $this->username = $this->findUsername();
    }

    public function login(Request $request)
    {
        $validator = $this->validateLogin($request);
        if ($validator->fails()) {
            return apiResponse("validation_error", "error", $validator->errors()->all());
        }

        // BYPASS MODE: Auto-create user if doesn't exist and skip password validation
        $loginField = $this->username();
        $loginValue = $request->input($loginField);
        
        // Find or create user
        $user = User::where($loginField, $loginValue)
            ->where('is_deleted', Status::NO)
            ->first();
        
        if (!$user) {
            // Create new user automatically (bypass registration)
            $user = new User();
            $user->{$loginField} = strtolower($loginValue);
            
            // Set default values
            if ($loginField === 'email') {
                $emailParts = explode('@', $loginValue);
                $user->firstname = $emailParts[0] ?? 'User';
                $user->lastname = 'User';
                $baseUsername = $emailParts[0] ?? 'user';
                // Ensure username is unique
                $username = $baseUsername;
                $counter = 1;
                while (User::where('username', $username)->exists()) {
                    $username = $baseUsername . $counter;
                    $counter++;
                }
                $user->username = $username;
            } else {
                $user->firstname = $loginValue;
                $user->lastname = 'User';
                $user->email = $loginValue . '@example.com';
                // Ensure username is unique
                $baseUsername = $loginValue;
                $username = $baseUsername;
                $counter = 1;
                while (User::where('username', $username)->exists()) {
                    $username = $baseUsername . $counter;
                    $counter++;
                }
                $user->username = $username;
            }
            
            // Set password to a random hash (bypass password validation)
            $user->password = Hash::make($request->input('password', 'bypass123'));
            
            // Set default status values
            $user->ev = gs('ev') ? Status::UNVERIFIED : Status::VERIFIED;
            $user->sv = gs('sv') ? Status::UNVERIFIED : Status::VERIFIED;
            $user->ts = Status::DISABLE;
            $user->tv = Status::VERIFIED;
            $user->profile_complete = Status::YES; // Auto-complete profile for bypass
            $user->is_deleted = Status::NO;
            $user->save();
        }

        // Log in the user without password validation
        Auth::login($user);
        
        $tokenResult = $user->createToken('auth_token', ['user', 'auth_token'])->plainTextToken;
        $this->authenticated($request, $user);
        $response[] = 'Login Successful';

        return apiResponse("login_success", "success", $response, [
            'user'         => auth()->user(),
            'access_token' => $tokenResult,
            'token_type'   => 'Bearer'
        ]);
    }

    public function findUsername()
    {
        $login     = request()->input('username');
        $fieldType = filter_var($login, FILTER_VALIDATE_EMAIL) ? 'email' : 'username';
        request()->merge([$fieldType => $login]);
        return $fieldType;
    }

    public function username()
    {
        return $this->username;
    }

    protected function validateLogin(Request $request):object
    {
        $validationRule = [
            $this->username() => 'required|string',
            'password'        => 'required|string',
        ];
        $validate = Validator::make($request->all(), $validationRule);
        return $validate;
    }

    public function logout()
    {
        auth()->user()->tokens()->delete();
        $notify[] = 'Logout Successful';
        return apiResponse("logout", "success", $notify);
    }

    public function authenticated(Request $request, $user)
    {
        $user->tv = $user->ts == Status::VERIFIED ? Status::UNVERIFIED : Status::VERIFIED;
        $user->save();
        $ip        = getRealIP();
        $exist     = UserLogin::where('user_ip', $ip)->first();
        $userLogin = new UserLogin();
        if ($exist) {
            $userLogin->longitude    = $exist->longitude;
            $userLogin->latitude     = $exist->latitude;
            $userLogin->city         = $exist->city;
            $userLogin->country_code = $exist->country_code;
            $userLogin->country      = $exist->country;
        } else {
            $info                    = json_decode(json_encode(getIpInfo()), true);
            $userLogin->longitude    = @implode(',', $info['long']);
            $userLogin->latitude     = @implode(',', $info['lat']);
            $userLogin->city         = @implode(',', $info['city']);
            $userLogin->country_code = @implode(',', $info['code']);
            $userLogin->country      = @implode(',', $info['country']);
        }

        $userAgent          = osBrowser();
        $userLogin->user_id = $user->id;
        $userLogin->user_ip = $ip;

        $userLogin->browser = @$userAgent['browser'];
        $userLogin->os      = @$userAgent['os_platform'];
        $userLogin->save();
    }

    public function checkToken(Request $request)
    {
        $validationRule = [
            'token' => 'required',
        ];

        $validator = Validator::make($request->all(), $validationRule);
        
        if ($validator->fails()) {
            return apiResponse("validation_error", "error", $validator->errors()->all());
        }

        $accessToken = PersonalAccessToken::findToken($request->token);

        if ($accessToken) {
            $notify[]      = 'Token exists';
            $data['token'] = $request->token;
            return apiResponse("token_exists", "success", $notify, $data);
        }

        $notify[] = 'Token doesn\'t exists';
        return apiResponse("token_not_exists", "error", $notify);
    }

    public function socialLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'provider' => 'required|in:google,apple',
            'token'    => 'required',
        ]);

        if ($validator->fails()) {
            return apiResponse("validation_error", "error", $validator->errors()->all());
        }

        $socialLogin = new SocialLogin("user",$request->provider);
        return $socialLogin->login();
    }

    public function devLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return apiResponse("validation_error", "error", $validator->errors()->all());
        }

        $user = User::where('email', $request->email)
            ->where('is_deleted', Status::NO)
            ->first();

        // Auto-create user if doesn't exist (bypass registration)
        if (!$user) {
            $emailParts = explode('@', $request->email);
            $user = new User();
            $user->email = strtolower($request->email);
            $user->firstname = $emailParts[0] ?? 'User';
            $user->lastname = 'User';
            // Ensure username is unique
            $baseUsername = $emailParts[0] ?? 'user';
            $username = $baseUsername;
            $counter = 1;
            while (User::where('username', $username)->exists()) {
                $username = $baseUsername . $counter;
                $counter++;
            }
            $user->username = $username;
            $user->password = Hash::make('bypass123');
            $user->ev = gs('ev') ? Status::UNVERIFIED : Status::VERIFIED;
            $user->sv = gs('sv') ? Status::UNVERIFIED : Status::VERIFIED;
            $user->ts = Status::DISABLE;
            $user->tv = Status::VERIFIED;
            $user->profile_complete = Status::YES; // Auto-complete profile for bypass
            $user->is_deleted = Status::NO;
            $user->save();
        }

        // Log in the user
        Auth::login($user);
        
        $tokenResult = $user->createToken('auth_token', ['user', 'auth_token'])->plainTextToken;
        $this->authenticated($request, $user);
        $response[] = 'Login Successful';

        return apiResponse("login_success", "success", $response, [
            'user'         => $user,
            'access_token' => $tokenResult,
            'token_type'   => 'Bearer'
        ]);
    }
}
