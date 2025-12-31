<?php

// Script to create a second test user for shared ride testing
// Run this via: ssh root@192.168.1.3 "cd /path/to/project && php create_second_user.php"

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use App\Constants\Status;
use Illuminate\Support\Facades\Hash;

// Create second test user
$email = 'rider2@test.com';
$username = 'rider2';
$password = 'password123';

// Check if user already exists
$existingUser = User::where('email', $email)
    ->orWhere('username', $username)
    ->first();

if ($existingUser) {
    echo "User already exists with email: {$email} or username: {$username}\n";
    echo "ID: {$existingUser->id}\n";
    echo "Email: {$existingUser->email}\n";
    echo "Username: {$existingUser->username}\n";
    exit(0);
}

// Create new user
$user = new User();
$user->firstname = 'Rider';
$user->lastname = 'Two';
$user->email = $email;
$user->username = $username;
$user->password = Hash::make($password);
$user->ev = Status::VERIFIED;
$user->sv = Status::VERIFIED;
$user->ts = Status::DISABLE;
$user->tv = Status::VERIFIED;
$user->profile_complete = Status::YES;
$user->is_deleted = Status::NO;
$user->status = Status::ENABLE;
$user->save();

echo "Second user created successfully!\n";
echo "Email: {$email}\n";
echo "Username: {$username}\n";
echo "Password: {$password}\n";
echo "User ID: {$user->id}\n";










