import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class ShuttleRepo {
  ApiClient apiClient;
  ShuttleRepo({required this.apiClient});

  Future<ResponseModel> matchRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.shuttleMatchRoute}";
    Map<String, dynamic> params = {
      "start_lat": startLat,
      "start_lng": startLng,
      "end_lat": endLat,
      "end_lng": endLng,
    };

    ResponseModel responseModel = await apiClient.request(
      url,
      Method.postMethod,
      params,
      passHeader: true,
    );
    return responseModel;
  }
}
