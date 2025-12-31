import 'dart:io';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';

class SharedRideRepo {
  ApiClient apiClient;
  SharedRideRepo({required this.apiClient});

  Future<ResponseModel> matchSharedRide({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    Map<String, dynamic> params = {
      "start_lat": startLat.toString(),
      "start_lng": startLng.toString(),
      "end_lat": endLat.toString(),
      "end_lng": endLng.toString(),
    };

    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/match-shared-ride",
      Method.postMethod,
      params,
      passHeader: true,
    );
  }

  Future<ResponseModel> joinRide({
    required String rideId,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
  }) async {
    Map<String, dynamic> params = {"ride_id": rideId};
    if (startLat != null && startLng != null && endLat != null && endLng != null) {
      params["start_lat"] = startLat.toString();
      params["start_lng"] = startLng.toString();
      params["end_lat"] = endLat.toString();
      params["end_lng"] = endLng.toString();
    }
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/join-ride",
      Method.postMethod,
      params,
      passHeader: true,
    );
  }

  Future<ResponseModel> getActiveSharedRide() async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/active-shared-ride",
      Method.getMethod,
      {},
      passHeader: true,
    );
  }

  Future<ResponseModel> createSharedRide({
     required double startLat,
     required double startLng,
     required double endLat,
     required double endLng,
     required String pickupLocation,
     required String destination,
     bool isScheduled = false,
     String? scheduledTime,
  }) async {
      Map<String, dynamic> params = {
        "start_lat": startLat.toString(),
        "start_lng": startLng.toString(),
        "end_lat": endLat.toString(),
        "end_lng": endLng.toString(),
        "pickup_location": pickupLocation,
        "destination": destination,
        "is_scheduled": isScheduled,
      };
      
      if (isScheduled && scheduledTime != null) {
        params["scheduled_time"] = scheduledTime;
      }
      
      return await apiClient.request(
        "${UrlContainer.baseUrl}shuttle/create-shared-ride", 
        Method.postMethod,
        params,
        passHeader: true,
      );
  }

  Future<ResponseModel> updateRideStatus({required String rideId, required String action}) async {
    return await apiClient.request(
        "${UrlContainer.baseUrl}shuttle/update-ride-status", 
        Method.postMethod,
        {"ride_id": rideId, "action": action},
        passHeader: true,
    );
  }

  Future<ResponseModel> getPendingSharedRides() async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/pending-shared-rides",
      Method.getMethod,
      {},
      passHeader: true,
    );
  }

  Future<ResponseModel> getConfirmedSharedRides() async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/confirmed-shared-rides",
      Method.getMethod,
      {},
      passHeader: true,
    );
  }

  Future<ResponseModel> updateLiveLocation({
    required double latitude,
    required double longitude,
  }) async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/shared-ride/live-location",
      Method.postMethod,
      {
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
      },
      passHeader: true,
    );
  }

  Future<ResponseModel> uploadFareScreenshot({
    required String rideId,
    required String fareAmount,
    required File fareImage,
  }) async {
    Map<String, dynamic> params = {
      "fare_amount": fareAmount,
    };
    
    Map<String, File> files = {
      "fare_image": fareImage,
    };
    
    return await apiClient.multipartRequest(
      "${UrlContainer.baseUrl}shuttle/shared-ride/upload-fare-screenshot/$rideId",
      Method.postMethod,
      params,
      files: files,
      passHeader: true,
    );
  }

  Future<ResponseModel> endSharedRide({
    required String rideId,
  }) async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/shared-ride/end-ride/$rideId",
      Method.postMethod,
      {},
      passHeader: true,
    );
  }

  Future<ResponseModel> markArrived({
    required String rideId,
  }) async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/shared-ride/mark-arrived/$rideId",
      Method.postMethod,
      {},
      passHeader: true,
    );
  }

  Future<ResponseModel> rateOtherUser({
    required String rideId,
    required int rating,
    required String review,
  }) async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}shuttle/shared-ride/rate-user/$rideId",
      Method.postMethod,
      {
        "rating": rating.toString(),
        "review": review,
      },
      passHeader: true,
    );
  }
}
