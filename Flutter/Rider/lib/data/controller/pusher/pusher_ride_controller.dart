import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/audio_utils.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/data/services/pusher_service.dart';
import 'package:ovorideuser/presentation/components/dialog/show_custom_bid_dialog.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/ride/shared_ride_unified_screen.dart';

class PusherRideController extends GetxController {
  ApiClient apiClient;
  RideMessageController rideMessageController;
  RideDetailsController rideDetailsController;
  String rideID;
  PusherRideController({
    required this.apiClient,
    required this.rideMessageController,
    required this.rideDetailsController,
    required this.rideID,
  });

  String get userID => apiClient.getUserID();

  @override
  void onInit() {
    super.onInit();
    PusherManager().addListener(onEvent);
    subscribe();
  }

  PusherConfig pusherConfig = PusherConfig();

  /// Handle incoming Pusher events
  void onEvent(PusherEvent event) {
    try {
      printD('Pusher Channel: ${event.channelName}');
      printD('Pusher Event: ${event.eventName}');
      if (event.data == null) return;

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(event.data);
      } catch (e) {
        printX('Invalid JSON: $e');
        return;
      }

      final model = PusherResponseModel.fromJson(data);
      final modifiedEvent = PusherResponseModel(
        eventName: event.eventName,
        channelName: event.channelName,
        data: model.data,
      );

      updateEvent(modifiedEvent);
    } catch (e) {
      printX('onEvent error: $e');
    }
  }

  /// Update UI or state based on event name
  void updateEvent(PusherResponseModel event) {
    final eventName = event.eventName?.toLowerCase();
    printX('Handling event: $eventName');

    switch (eventName) {
      case 'online_payment_received':
        _handleOnlinePayment(event);
        break;

      case 'message_received':
        _handleMessageReceived(event);
        break;

      case 'live_location':
        _handleLiveLocation(event);
        break;

      case 'shared_ride_live_location':
        _handleSharedRideLiveLocation(event);
        break;

      case 'new_bid':
        _handleNewBid(event);
        break;

      case 'bid_reject':
        rideDetailsController.updateBidCount(true);
        break;

      case 'cash_payment_received':
        _handleCashPayment(event);
        break;

      case 'fare_screenshot_uploaded':
        _handleFareScreenshotUploaded(event);
        break;

      case 'rider_joined':
        _handleRiderJoined(event);
        break;

      case 'pick_up':
      case 'ride_end':
      case 'bid_accept':
        _updateRideIfAvailable(event);
        break;

      default:
        _updateRideIfAvailable(event);
        break;
    }
  }

  /// Handlers for each event type

  void _handleOnlinePayment(PusherResponseModel event) {
    printX('Online payment received for ride: ${event.data?.rideId}');
    Get.offAndToNamed(
      RouteHelper.rideReviewScreen,
      arguments: event.data?.rideId ?? '',
    );
  }

  void _handleMessageReceived(PusherResponseModel eventResponse) {
    if (eventResponse.data?.message != null) {
      if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) {
        printX('Message for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
        return;
      }
      
      // Check if we're on message screen
      bool isOnMessageScreen = Get.currentRoute == RouteHelper.rideMessageScreen;
      
      // Refresh full message list to ensure we have all messages
      rideMessageController.getRideMessage(rideID, shouldLoading: false);
      
      // Show notification if NOT on message screen
      if (!isOnMessageScreen) {
        if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
          MyUtils.vibrate();
        }
        // Show in-app notification/snackbar
        final messageText = eventResponse.data!.message!.message ?? 'New message';
        CustomSnackBar.showToast(message: messageText);
        
        // Also trigger push notification if app is in background
        // This will be handled by the backend push notification service
      }
      
      // Also add message directly to controller for immediate UI update
      rideMessageController.addEventMessage(eventResponse.data!.message!);
    }
  }

  void _handleRiderJoined(PusherResponseModel eventResponse) {
    final eventRideId = eventResponse.data?.ride?.id?.toString();
    final rideIdToUse = eventRideId ?? rideID;
    
    if (rideIdToUse.isEmpty) {
      printX('Rider joined event but no ride ID available');
      return;
    }
    
    // Always refresh SharedRideController to update home screen cards
    if (Get.isRegistered<SharedRideController>()) {
      final sharedRideController = Get.find<SharedRideController>();
      // Refresh pending rides and check for active ride
      sharedRideController.loadPendingAndConfirmedRides();
      sharedRideController.checkPendingRide();
    }
    
    // Check if we're on ride details or shared ride active/unified screen
    bool isOnRideScreen = isRideDetailsPage() || 
                         Get.currentRoute.contains('shared_ride_active') ||
                         Get.currentRoute.contains('shared_ride_unified') ||
                         Get.currentRoute.contains('ride_details');
    
    if (isOnRideScreen) {
      // Show notification
      if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }
      CustomSnackBar.success(
        successList: ["Another rider has joined your shared ride!"]
      );
      
      // Refresh ride details to show updated ride with second user
      if (rideID.isNotEmpty) {
        rideDetailsController.getRideDetails(rideID, shouldLoading: false);
      }
    } else {
      // If not on ride screen, show notification and navigate to unified screen
      if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }
      CustomSnackBar.success(
        successList: ["Another rider has joined your shared ride!"]
      );
      
      // Navigate to unified screen to show the active ride with both users
      Get.to(() => SharedRideUnifiedScreen(rideId: rideIdToUse));
    }
  }

  void _handleSharedRideLiveLocation(PusherResponseModel eventResponse) {
    if (eventResponse.data?.ride != null && eventResponse.data!.ride!.id != rideID) {
      printX('Live location for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
    
    // Check if this is a shared ride
    bool isSharedRide = rideDetailsController.ride.rideType == '4';
    if (!isSharedRide) return;
    
    final userId = eventResponse.data?.userId?.toString();
    final currentUserId = apiClient.getUserID();
    
    // Only update if this is from the other user
    if (userId != null && userId != currentUserId) {
      final lat = StringConverter.formatDouble(eventResponse.data?.driverLatitude ?? '0', precision: 10);
      final lng = StringConverter.formatDouble(eventResponse.data?.driverLongitude ?? '0', precision: 10);
      final location = LatLng(lat, lng);
      
      // Update other user's location on map
      rideDetailsController.mapController.updateDriverLocation(
        latLng: location,
        isRunning: false,
      );
      
      // Also update SharedRideController if registered
      if (Get.isRegistered<SharedRideController>()) {
        Get.find<SharedRideController>().updateOtherUserLocation(location);
      }
    }
  }

  void _handleLiveLocation(PusherResponseModel eventResponse) {
    if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) {
      printX('Message for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
    if (rideDetailsController.ride.status == AppStatus.RIDE_ACTIVE.toString() || rideDetailsController.ride.status == AppStatus.RIDE_RUNNING.toString()) {
      // Check if this is from a driver (normal ride) or another user (shared ride)
      final userId = eventResponse.data?.userId?.toString();
      final currentUserId = apiClient.getUserID();
      
      // Check if this is a shared ride (ride_type = '4' based on backend Status::SHARED_RIDE)
      bool isSharedRide = rideDetailsController.ride.rideType == '4';
      
      // For shared rides, update other user's location
      if (userId != null && userId != currentUserId && isSharedRide) {
        // Use driverLatitude/driverLongitude which are mapped from latitude/longitude in EventData
        final lat = StringConverter.formatDouble(eventResponse.data?.driverLatitude ?? '0', precision: 10);
        final lng = StringConverter.formatDouble(eventResponse.data?.driverLongitude ?? '0', precision: 10);
        final location = LatLng(lat, lng);

        // Update other user's location on map
        rideDetailsController.mapController.updateDriverLocation(
          latLng: location,
          isRunning: false,
        );

        // Also update SharedRideController if registered
        if (Get.isRegistered<SharedRideController>()) {
          Get.find<SharedRideController>().updateOtherUserLocation(location);
        }
      } else if (eventResponse.data?.driverLatitude != null || eventResponse.data?.driverLongitude != null) {
        // Normal ride - driver location
        final lat = StringConverter.formatDouble(eventResponse.data?.driverLatitude ?? '0', precision: 10);
        final lng = StringConverter.formatDouble(eventResponse.data?.driverLongitude ?? '0', precision: 10);
        rideDetailsController.mapController.updateDriverLocation(
          latLng: LatLng(lat, lng),
          isRunning: false,
        );
      }
    }
  }

  void _handleNewBid(PusherResponseModel eventResponse) {
    if (eventResponse.data!.bid != null && eventResponse.data!.bid!.rideId != rideID) {
      printX('Message for different ride: ${eventResponse.data!.bid!.rideId}, current ride: $rideID');
      return;
    }
    final bid = eventResponse.data?.bid;
    if (bid != null) {
      AudioUtils.playAudio(apiClient.getNotificationAudio());
      if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }

      CustomBidDialog.newBid(
        bid: bid,
        currency: rideDetailsController.currencySym,
        driverImagePath: '${rideDetailsController.driverImagePath}/${bid.driver?.avatar}',
        serviceImagePath: '${rideDetailsController.serviceImagePath}/${eventResponse.data?.service?.image}',
        totalRideCompleted: eventResponse.data?.driverTotalRide ?? '0',
      );
    }
    rideDetailsController.updateBidCount(false);
  }

  void _handleCashPayment(PusherResponseModel event) {
    rideDetailsController.updatePaymentRequested(isRequested: false);
    _updateRideIfAvailable(event);
  }

  void _handleFareScreenshotUploaded(PusherResponseModel event) {
    if (event.data?.ride != null && event.data!.ride!.id != rideID) {
      printX('Fare screenshot for different ride: ${event.data!.ride!.id}, current ride: $rideID');
      return;
    }
    // Refresh ride details to show uploaded fare screenshot and calculated fares
    rideDetailsController.getRideDetails(rideID, shouldLoading: false);
    CustomSnackBar.showToast(message: 'Fare screenshot uploaded! Your fare has been calculated.');
  }

  void _updateRideIfAvailable(PusherResponseModel eventResponse) {
    if (eventResponse.data!.ride != null && eventResponse.data!.ride!.id != rideID) {
      printX('Message for different ride: ${eventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }
    final ride = eventResponse.data?.ride;
    if (ride != null) {
      rideDetailsController.updateRide(ride);
    }
  }

  /// Utility
  bool isRideDetailsPage() => Get.currentRoute == RouteHelper.rideDetailsScreen;

  void subscribe() {
    PusherManager().checkAndInitIfNeeded("private-rider-user-$userID");
    PusherManager().checkAndInitIfNeeded("private-ride-$rideID");
  }

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    super.onClose();
  }

  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
      await PusherManager().checkAndInitIfNeeded(channelName ?? "private-rider-user-$userId");
    } catch (e) {
      printX("Error ensuring connection: $e");
    }
  }
}
