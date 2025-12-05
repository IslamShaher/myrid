import 'dart:io';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/utils/method.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/profile/profile_response_model.dart';
import 'package:ovorideuser/data/model/user_post_model/user_post_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';

class ProfileRepo {
  ApiClient apiClient;

  ProfileRepo({required this.apiClient});

  Future<AuthorizationResponseModel> updateProfile(
    UserPostModel m,
    bool isProfile,
  ) async {
    try {
      String url = '${UrlContainer.baseUrl}${isProfile ? UrlContainer.updateProfileEndPoint : UrlContainer.profileCompleteEndPoint}';

      Map<String, String> finalMap = {
        'username': m.username,
        'firstname': m.firstname,
        'lastname': m.lastName,
        'mobile_code': m.mobileCode,
        'country_code': m.countryCode,
        'country': m.country,
        'mobile': m.mobile,
        'address': m.address ?? '',
        'zip': m.zip ?? '',
        'state': m.state ?? "",
        'city': m.city ?? '',
        'reference': m.refer ?? '',
      };

      //Attachments file list
      Map<String, File> attachmentFiles = {};
      if (m.image != null) {
        attachmentFiles = {"image": m.image!};
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
        return model;
      } else {
        return model;
      }
    } catch (e) {
      return AuthorizationResponseModel(
        status: "error",
        message: [MyStrings.somethingWentWrong],
      );
    }
  }

  Future<ProfileResponseModel> loadProfileInfo() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.getProfileEndPoint}';

    ResponseModel responseModel = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );

    if (responseModel.statusCode == 200) {
      ProfileResponseModel model = ProfileResponseModel.fromJson((responseModel.responseJson));
      if (model.status == 'success') {
        return model;
      } else {
        return ProfileResponseModel();
      }
    } else {
      return ProfileResponseModel();
    }
  }

  Future<dynamic> getCountryList() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.countryEndPoint}';
    ResponseModel model = await apiClient.request(url, Method.getMethod, null);
    return model;
  }

  //
  Future<ResponseModel> logout() async {
    String url = '${UrlContainer.baseUrl}${UrlContainer.logoutUrl}';

    ResponseModel responseModel = await apiClient.request(
      url,
      Method.getMethod,
      null,
      passHeader: true,
    );
    await clearSharedPrefData();
    return responseModel;
  }

  Future<void> clearSharedPrefData() async {
    await apiClient.sharedPreferences.setString(
      SharedPreferenceHelper.userNameKey,
      '',
    );
    await apiClient.sharedPreferences.setString(
      SharedPreferenceHelper.userEmailKey,
      '',
    );
    await apiClient.sharedPreferences.setString(
      SharedPreferenceHelper.accessTokenType,
      '',
    );
    await apiClient.sharedPreferences.setString(
      SharedPreferenceHelper.accessTokenKey,
      '',
    );
    await apiClient.sharedPreferences.setBool(
      SharedPreferenceHelper.rememberMeKey,
      false,
    );
    return Future.value();
  }
}
