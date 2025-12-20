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
      "${UrlContainer.baseUrl}api/shuttle/match-shared-ride",
      Method.postMethod,
      params,
      passHeader: true,
    );
  }

  Future<ResponseModel> joinRide({required String rideId}) async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}api/shuttle/join-ride",
      Method.postMethod,
      {"ride_id": rideId},
      passHeader: true,
    );
  }

  Future<ResponseModel> getActiveSharedRide() async {
    return await apiClient.request(
      "${UrlContainer.baseUrl}api/shuttle/active-shared-ride",
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
  }) async {
      Map<String, dynamic> params = {
        "start_lat": startLat.toString(),
        "start_lng": startLng.toString(),
        "end_lat": endLat.toString(),
        "end_lng": endLng.toString(),
        "pickup_location": pickupLocation,
        "destination": destination,
      };
      
      return await apiClient.request(
        "${UrlContainer.baseUrl}api/shuttle/create-shared-ride", 
        Method.postMethod,
        params,
        passHeader: true,
      );
  }
}
