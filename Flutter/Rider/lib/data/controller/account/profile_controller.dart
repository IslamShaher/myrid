import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/global/user/global_user_model.dart';
import 'package:ovorideuser/data/model/profile/profile_response_model.dart';
import 'package:ovorideuser/data/model/user_post_model/user_post_model.dart';
import 'package:ovorideuser/data/repo/account/profile_repo.dart';
import 'package:ovorideuser/data/repo/auth/general_setting_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class ProfileController extends GetxController {
  ProfileRepo profileRepo;
  ProfileResponseModel model = ProfileResponseModel();
  GeneralSettingRepo repo = Get.find();
  ProfileController({required this.profileRepo});

  String imageUrl = '';
  String imagePath = '';
  bool isLoading = true;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileNoController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController zipCodeController = TextEditingController();
  TextEditingController cityController = TextEditingController();

  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastNameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode mobileNoFocusNode = FocusNode();
  FocusNode addressFocusNode = FocusNode();
  FocusNode stateFocusNode = FocusNode();
  FocusNode zipCodeFocusNode = FocusNode();
  FocusNode cityFocusNode = FocusNode();
  FocusNode countryFocusNode = FocusNode();

  File? imageFile;
  GlobalUser? user;

  Future<void> loadProfileInfo({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    await getGSData();
    update();
    model = await profileRepo.loadProfileInfo();
    if (model.data != null && model.status?.toLowerCase() == MyStrings.success.toLowerCase()) {
      loadData(model);
    } else {
      isLoading = false;
      update();
    }
  }

  bool isSubmitLoading = false;
  Future<void> updateProfile() async {
    isSubmitLoading = true;
    update();

    String firstName = firstNameController.text;
    String lastName = lastNameController.text.toString();
    String address = addressController.text.toString();
    String city = cityController.text.toString();
    String zip = zipCodeController.text.toString();
    String state = stateController.text.toString();
    user = model.data?.user;

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      UserPostModel model = UserPostModel(
        firstname: firstName,
        lastName: lastName,
        mobile: user?.mobile ?? '',
        email: user?.email ?? '',
        username: user?.username ?? '',
        countryCode: user?.countryCode ?? '',
        country: user?.country ?? '',
        mobileCode: '',
        image: imageFile,
        address: address,
        state: state,
        zip: zip,
        city: city,
        refer: '',
      );

      AuthorizationResponseModel responseModel = await profileRepo.updateProfile(model, true);
      if (responseModel.status == "success") {
        await loadProfileInfo(shouldLoad: false);
        await profileRepo.apiClient.sharedPreferences.setString(
          SharedPreferenceHelper.userFullNameKey,
          '$firstName $lastName',
        );
        CustomSnackBar.success(successList: responseModel.message ?? [MyStrings.requestSuccess]);
      } else {
        CustomSnackBar.error(errorList: responseModel.message ?? [MyStrings.somethingWentWrong]);
      }
    } else {
      if (firstName.isEmpty) {
        CustomSnackBar.error(errorList: [MyStrings.kFirstNameNullError.tr]);
      }
      if (lastName.isEmpty) {
        CustomSnackBar.error(errorList: [MyStrings.kLastNameNullError.tr]);
      }
    }

    isSubmitLoading = false;
    update();
  }

  void loadData(ProfileResponseModel? model) {
    user = model?.data?.user ?? GlobalUser();
    profileRepo.apiClient.sharedPreferences.setString(
      SharedPreferenceHelper.userNameKey,
      '${model?.data?.user?.username}',
    );

    firstNameController.text = model?.data?.user?.firstname ?? '';
    lastNameController.text = model?.data?.user?.lastname ?? '';
    emailController.text = model?.data?.user?.email ?? '';
    mobileNoController.text = "+${model?.data?.user?.dialCode ?? ''}${model?.data?.user?.mobile ?? ''}";
    addressController.text = model?.data?.user?.address ?? '';
    stateController.text = model?.data?.user?.state ?? '';
    zipCodeController.text = model?.data?.user?.zip ?? '';
    cityController.text = model?.data?.user?.city ?? '';
    imageUrl = model?.data?.user?.image == null ? '' : '${model?.data?.user?.image}';
    imagePath = model?.data?.imagePath.toString() ?? '';
    if (imageUrl.isNotEmpty && imageUrl != 'null') {
      imageUrl = '${UrlContainer.domainUrl}/$imagePath/$imageUrl';
    }
    profileRepo.apiClient.sharedPreferences.setString(
      SharedPreferenceHelper.userProfileKey,
      imageUrl,
    );

    isLoading = false;
    update();
  }

  void openGallery(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (result != null) {
      imageFile = File(result.files.single.path!);
    }
    update();
  }

  // review
  final InAppReview inAppReview = InAppReview.instance;
  // logout
  bool logoutLoading = false;
  Future<void> logout() async {
    logoutLoading = true;
    update();

    await profileRepo.logout();
    CustomSnackBar.success(successList: [MyStrings.logoutSuccessMsg]);

    logoutLoading = false;
    update();
    Get.offAllNamed(RouteHelper.loginScreen);
  }
  //

  Future<void> getGSData() async {
    ResponseModel response = await repo.getGeneralSetting();

    if (response.statusCode == 200) {
      GeneralSettingResponseModel model = GeneralSettingResponseModel.fromJson((response.responseJson));
      if (model.status?.toLowerCase() == MyStrings.success) {
        repo.apiClient.storeGeneralSetting(model);
        repo.apiClient.storePushSetting(
          model.data?.generalSetting?.pushConfig ?? PusherConfig(),
        );
      } else {
        printD(model.message);
      }
    } else {
      printX(response.message);
    }
  }
}
