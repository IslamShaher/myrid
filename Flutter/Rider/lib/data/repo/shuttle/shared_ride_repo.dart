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
      url: "${UrlContainer.baseUrl}api/shuttle/match-shared-ride",
      method: Method.postMethod,
      params: params,
    );
  }

  Future<ResponseModel> joinRide({required String rideId}) async {
    return await apiClient.request(
      url: "${UrlContainer.baseUrl}api/shuttle/join-ride",
      method: Method.postMethod,
      params: {"ride_id": rideId},
    );
  }

  Future<ResponseModel> updateRideStatus({required String rideId, required String action}) async {
    return await apiClient.request(
      url: "${UrlContainer.baseUrl}api/shuttle/update-ride-status",
      method: Method.postMethod,
      params: {"ride_id": rideId, "action": action},
    );
  }
 
  // For creating a NEW ride (Rider 1), we might reuse ShuttleRepo.create or make a param here.
  // But wait, the standard create uses Route ID.
  // We need a way to create a 'Flexible' shuttle ride.
  // I need to check ShuttleController.create on backend again.
  // It REQUIRES route_id.
  
  // PROBLEM: The user wants to create a ride if no match found.
  // Using ShuttleController::create will fail because it validates Route ID.
  // I need a NEW create endpoint for Shared Rides that doesn't require Route ID.
  
  Future<ResponseModel> createSharedRide({
     required double startLat,
     required double startLng,
     required double endLat,
     required double endLng,
     required String pickupLocation,
     required String destination,
  }) async {
      // I will need to implement 'create-shared-ride' on backend.
      Map<String, dynamic> params = {
        "start_lat": startLat.toString(),
        "start_lng": startLng.toString(),
        "end_lat": endLat.toString(),
        "end_lng": endLng.toString(),
        "pickup_location": pickupLocation,
        "destination": destination,
      };
      
      return await apiClient.request(
        url: "${UrlContainer.baseUrl}api/shuttle/create-shared-ride", 
        method: Method.postMethod,
        params: params
      );
  }
}
