import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'dart:convert';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovorideuser/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class GlobalPusherController extends GetxController {
  ApiClient apiClient;
  GlobalPusherController({required this.apiClient});

  @override
  void onInit() {
    super.onInit();

    PusherManager().addListener(onEvent);
  }

  List<String> activeEventList = ["ride_end", "pick_up", "cash_payment_received", "new_bid"];

  void onEvent(PusherEvent event) {
    try {
      printD("Global pusher event: ${event.eventName}");
      printX("Global pusher data: ${event.data}");
      if (event.data == null || event.eventName == "" || event.data.toString() == "{}") return;

      final eventName = event.eventName.toLowerCase();

      final data = jsonDecode(event.data);
      final model = PusherResponseModel.fromJson(data);

      if (activeEventList.contains(eventName) && !isRideDetailsPage()) {
        final rideId = eventName == "new_bid" ? model.data?.bid?.rideId : model.data?.ride?.id;
        if (rideId != null) {
          Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        }
      }
    } catch (e) {
      printE("Error handling event ${event.eventName}: $e");
    }
  }

  bool isRideDetailsPage() {
    return Get.currentRoute == RouteHelper.rideDetailsScreen;
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
