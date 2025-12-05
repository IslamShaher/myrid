import 'dart:io';

import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class MessageRepo {
  ApiClient apiClient;
  MessageRepo({required this.apiClient});

  Future<ResponseModel> getRideMessageList({required String id}) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.rideMessageList}/$id";
    ResponseModel responseModel = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );
    return responseModel;
  }

  Future<bool> sendMessage({
    required String id,
    required String txt,
    File? file,
  }) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.sendMessage}/$id";
    apiClient.initToken();
    Map<String, String> finalMap = {'message': txt};

    //Attachments file list
    Map<String, File> attachmentFiles = {};
    if (file != null) {
      attachmentFiles = {"image": file};
    }

    ResponseModel responseModel = await apiClient.multipartRequest(
      url,
      Method.postMethod,
      finalMap,
      files: attachmentFiles,
      passHeader: true,
    );

    AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((responseModel.responseJson));

    if (model.status?.toLowerCase() == MyStrings.success.toLowerCase()) {
      return true;
    } else {
      CustomSnackBar.error(errorList: model.message ?? [MyStrings.requestFail]);
      return false;
    }
  }
}
