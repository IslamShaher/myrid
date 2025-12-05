import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/route/route_middleware.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/auth/login/login_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/repo/auth/login_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class LoginController extends GetxController {
  LoginRepo loginRepo;
  LoginController({required this.loginRepo});

  final FocusNode mobileNumberFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String? email;
  String? password;

  List<String> errors = [];
  bool remember = true;

  void forgetPassword() {
    Get.toNamed(RouteHelper.forgotPasswordScreen);
  }

  bool isSubmitLoading = false;
  void loginUser() async {
    isSubmitLoading = true;
    update();

    try {
      ResponseModel model = await loginRepo.loginUser(
        emailController.text.toString(),
        passwordController.text.toString(),
      );

      if (model.statusCode == 200) {
        LoginResponseModel loginModel = LoginResponseModel.fromJson(model.responseJson);
        if (loginModel.status.toString().toLowerCase() == MyStrings.success.toLowerCase()) {
          await loginRepo.apiClient.sharedPreferences.setBool(
            SharedPreferenceHelper.rememberMeKey,
            remember,
          );
          printX(loginModel.data?.toJson());
          RouteMiddleware.checkNGotoNext(
            accessToken: loginModel.data?.accessToken ?? '',
            tokenType: loginModel.data?.tokenType ?? '',
            user: loginModel.data?.user,
          );
        } else {
          CustomSnackBar.error(
            errorList: loginModel.message ?? [MyStrings.loginFailedTryAgain],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [model.message]);
      }
    } catch (e) {
      printE(e);
    }

    isSubmitLoading = false;
    update();
  }

  void changeRememberMe() {
    remember = !remember;
    update();
  }

  void clearTextField() {
    passwordController.text = '';
    emailController.text = '';

    if (remember) {
      remember = false;
    }
    update();
  }
}
