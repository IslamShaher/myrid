<?php

namespace App\Http\Controllers\Api\User;

use App\Events\Ride as EventsRide;
use App\Models\Ride;
use App\Models\Message;
use Illuminate\Http\Request;
use App\Rules\FileTypeValidate;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Validator;

class MessageController extends Controller
{
    public function messages($id)
    {
        $messages = Message::where('ride_id', $id)->orderBy('id', 'desc')->get();
        $notify[] = 'Ride Messages';

        // Get ride info for shared rides to determine message sender
        $ride = Ride::find($id);
        $rideInfo = null;
        if ($ride) {
            $rideInfo = [
                'user_id' => $ride->user_id,
                'second_user_id' => $ride->second_user_id,
                'ride_type' => $ride->ride_type,
            ];
        }

        return apiResponse('ride_message', 'success', $notify, [
            'messages'   => $messages,
            'image_path' => getFilePath('message'),
            'ride'       => $rideInfo
        ]);
    }

    public function messageSave(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'message' => 'required',
            'image'   => ['nullable', 'image', new FileTypeValidate(['jpg', 'jpeg', 'png'])],
        ]);

        if ($validator->fails()) {
            return apiResponse("validation_error", "error", $validator->errors()->all());
        }

        $user = auth()->user();
        $ride = Ride::where(function($q) use ($user) {
            $q->where('user_id', $user->id)
              ->orWhere('second_user_id', $user->id);
        })->find($id);

        if (!$ride) {
            $notify[] = 'Invalid ride';
            return apiResponse('not_found', 'error', $notify);
        }

        $message          = new Message();

        if ($request->hasFile('image')) {
            try {
                $message->image = fileUploader($request->image, getFilePath('message'), null, null);
            } catch (\Exception $exp) {
                $notify[] = "Couldn\'t upload your image";
                return apiResponse('exception', 'error', $notify);
            }
        }

        $message->ride_id = $ride->id;
        // Fix: Save the actual sender's user_id, not the ride's user_id
        $message->user_id = $user->id;
        $message->message = $request->message;
        $message->save();


        $data['message'] = $message;
        $data['ride']    = $ride;

        // For shared rides, send to both users. For normal rides, send to driver.
        if ($ride->ride_type == \App\Constants\Status::SHARED_RIDE && $ride->second_user_id) {
            // Shared ride: send to both users
            event(new EventsRide("rider-user-{$ride->user_id}", "MESSAGE_RECEIVED", $data));
            if ($ride->second_user_id != $user->id) {
                event(new EventsRide("rider-user-{$ride->second_user_id}", "MESSAGE_RECEIVED", $data));
                
                // Send push notification to the other user
                $otherUser = \App\Models\User::find($ride->second_user_id);
                if ($otherUser) {
                    $shortCodes = [
                        'subject' => 'New Message',
                        'message' => $request->message,
                    ];
                    try {
                        notify($otherUser, 'DEFAULT', $shortCodes, ['push']);
                    } catch (\Exception $e) {
                        // If notification fails, Pusher event will still notify
                    }
                }
            } else {
                // Send push notification to rider 1
                $rider1 = \App\Models\User::find($ride->user_id);
                if ($rider1) {
                    $shortCodes = [
                        'subject' => 'New Message',
                        'message' => $request->message,
                    ];
                    try {
                        notify($rider1, 'DEFAULT', $shortCodes, ['push']);
                    } catch (\Exception $e) {
                        // If notification fails, Pusher event will still notify
                    }
                }
            }
        } else {
            // Normal ride: send to driver
            event(new EventsRide("rider-driver-$ride->driver_id", "MESSAGE_RECEIVED", $data));
        }

        $notify[] = 'Message send successfully';
        return apiResponse('message', 'success', $notify, $data);
    }
}
