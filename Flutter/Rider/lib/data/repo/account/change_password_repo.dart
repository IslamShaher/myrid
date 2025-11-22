import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class ChangePasswordRepo {
  ApiClient apiClient;

  ChangePasswordRepo({required this.apiClient});
  String token = '', tokenType = '';

  Future<bool> changePassword(String currentPass, String password) async {
    final params = modelToMap(currentPass, password);
    String url = '${UrlContainer.baseUrl}${UrlContainer.changePasswordEndPoint}';

    ResponseModel responseModel = await apiClient.request(
      url,
      Method.postMethod,
      params,
      passHeader: true,
    );
    if (responseModel.statusCode == 200) {
      AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((responseModel.responseJson));
      if (model.status == "success") {
        CustomSnackBar.success(
          successList: model.message ?? [MyStrings.passwordChanged.tr],
        );
        return true;
      } else {
        CustomSnackBar.error(
          errorList: model.message ?? [MyStrings.requestFail.tr],
        );
        return false;
      }
    } else {
      return false;
    }
  }

  Map<String, dynamic> modelToMap(String currentPassword, String newPass) {
    Map<String, dynamic> map2 = {
      'current_password': currentPassword,
      'password': newPass,
      'password_confirmation': newPass,
    };
    return map2;
  }
}
