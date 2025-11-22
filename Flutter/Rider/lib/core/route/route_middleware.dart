import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/data/model/global/user/global_user_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/services/push_notification_service.dart';

class RouteMiddleware {
  static Future<void> checkNGotoNext({
    GlobalUser? user,
    String accessToken = "",
    String tokenType = "",
  }) async {
    try {
      bool needProfileCompleted = user?.profileComplete == "1" ? false : true;
      bool needEmailVerification = user?.ev == "1" ? false : true;
      bool needSmsVerification = user?.sv == '1' ? false : true;

      final apiClient = ApiClient(sharedPreferences: Get.find());
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userIdKey,
        user?.id.toString() ?? '-1',
      );
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userEmailKey,
        user?.email ?? '',
      );
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userPhoneNumberKey,
        user?.mobile ?? '',
      );
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userNameKey,
        user?.username ?? '',
      );

      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userProfileKey,
        user?.imageWithPath ?? '',
      );
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userFullNameKey,
        '${user?.firstname} ${user?.lastname}',
      );
      if (accessToken.isNotEmpty) {
        await apiClient.sharedPreferences.setString(
          SharedPreferenceHelper.accessTokenType,
          tokenType,
        );
        await apiClient.sharedPreferences.setString(
          SharedPreferenceHelper.accessTokenKey,
          accessToken,
        );
        await apiClient.sharedPreferences.setBool(
          SharedPreferenceHelper.rememberMeKey,
          true,
        );
      }

      if (needProfileCompleted) {
        Get.offAndToNamed(RouteHelper.profileCompleteScreen);
      } else if (needEmailVerification) {
        Get.offAndToNamed(
          RouteHelper.emailVerificationScreen,
          arguments: [false, needProfileCompleted, false],
        );
      } else if (needSmsVerification) {
        Get.offAndToNamed(RouteHelper.smsVerificationScreen);
      } else {
        PushNotificationService(apiClient: Get.find()).sendUserToken();
        Get.toNamed(RouteHelper.dashboard);
      }
    } catch (e) {
      printD(e);
    }
  }
}
