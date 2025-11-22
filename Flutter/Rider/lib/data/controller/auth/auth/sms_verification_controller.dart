import 'dart:async';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/route/route_middleware.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/repo/auth/sms_email_verification_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class SmsVerificationController extends GetxController {
  SmsEmailVerificationRepo repo;
  SmsVerificationController({required this.repo});

  bool hasError = false;
  bool isLoading = true;
  String currentText = '';
  String userPhone = '';

  Future<void> loadBefore() async {
    isLoading = true;
    userPhone = repo.apiClient.sharedPreferences.getString(
          SharedPreferenceHelper.userPhoneNumberKey,
        ) ??
        '';
    update();
    await repo.sendAuthorizationRequest();
    isLoading = false;
    update();
    return;
  }

  bool submitLoading = false;
  Future<void> verifyYourSms(String currentText) async {
    if (currentText.isEmpty) {
      CustomSnackBar.error(errorList: [MyStrings.otpFieldEmptyMsg.tr]);
      return;
    }

    submitLoading = true;
    update();

    ResponseModel responseModel = await repo.verify(
      currentText,
      isEmail: false,
      isTFA: false,
    );

    if (responseModel.statusCode == 200) {
      AuthorizationResponseModel model = AuthorizationResponseModel.fromJson((responseModel.responseJson));

      if (model.status == MyStrings.success) {
        CustomSnackBar.success(
          successList: model.message ?? ['${MyStrings.sms.tr} ${MyStrings.verificationSuccess.tr}'],
        );
        RouteMiddleware.checkNGotoNext(user: model.data?.user);
      } else {
        CustomSnackBar.error(
          errorList: model.message ?? ['${MyStrings.sms.tr} ${MyStrings.verificationFailed}'],
        );
      }
    } else {
      CustomSnackBar.error(errorList: [responseModel.message]);
    }

    submitLoading = false;
    update();
  }

  bool resendLoading = false;
  Future<void> sendCodeAgain() async {
    resendLoading = true;
    update();
    await repo.resendVerifyCode(isEmail: false);
    currentText = "";
    resendLoading = false;
    update();
  }
}
