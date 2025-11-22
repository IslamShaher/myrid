import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class FaqRepo {
  ApiClient apiClient;
  FaqRepo({required this.apiClient});

  Future<ResponseModel> getFaqData() async {
    String url = UrlContainer.baseUrl + UrlContainer.faq;
    final response = await apiClient.request(url, Method.getMethod, null);
    return response;
  }
}
