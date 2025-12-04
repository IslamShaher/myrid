class ShuttleDriverRepo {
  ApiClient apiClient;
  ShuttleDriverRepo({required this.apiClient});

  Future<ResponseModel> getRoutes() async {
    return await apiClient.request('driver/shuttle/routes', Method.getMethod, null, passHeader: true);
  }

  Future<ResponseModel> startTrip(int routeId) async {
    return await apiClient.request('driver/shuttle/start', Method.postMethod, {'route_id': routeId}, passHeader: true);
  }

  Future<ResponseModel> arriveAtStop(int routeId, int stopId) async {
    return await apiClient.request('driver/shuttle/arrive', Method.postMethod, {'route_id': routeId, 'stop_id': stopId}, passHeader: true);
  }

  Future<ResponseModel> departStop(int routeId, int stopId) async {
    return await apiClient.request('driver/shuttle/depart', Method.postMethod, {'route_id': routeId, 'stop_id': stopId}, passHeader: true);
  }
  
  Future<ResponseModel> updateLiveLocation(double lat, double lng) async {
    return await apiClient.request('driver/shuttle/live-location', Method.postMethod, {'latitude': lat, 'longitude': lng}, passHeader: true);
  }
}

