import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route_middleware.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/authorization/authorization_response_model.dart';
import 'package:ovorideuser/data/model/country_model/country_model.dart';
import 'package:ovorideuser/data/model/profile/profile_response_model.dart';
import 'package:ovorideuser/data/model/user_post_model/user_post_model.dart';
import 'package:ovorideuser/data/repo/account/profile_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class ProfileCompleteController extends GetxController {
  ProfileRepo profileRepo;
  ProfileCompleteController({required this.profileRepo});

  ProfileResponseModel model = ProfileResponseModel();

  TextEditingController userNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileNoController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController zipCodeController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  TextEditingController referController = TextEditingController();

  FocusNode userNameFocusNode = FocusNode();
  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastNameFocusNode = FocusNode();
  FocusNode emailFocusNode = FocusNode();
  FocusNode mobileNoFocusNode = FocusNode();
  FocusNode addressFocusNode = FocusNode();
  FocusNode stateFocusNode = FocusNode();
  FocusNode zipCodeFocusNode = FocusNode();
  FocusNode cityFocusNode = FocusNode();
  FocusNode countryFocusNode = FocusNode();

  bool isLoading = false;

  Future<void> initialData() async {
    //    await loadProfileInfo();
    countryList = profileRepo.apiClient.getOperatingCountries();
    update();
    if (countryList.isNotEmpty) {
      selectCountryData(countryList.first);
    }
  }

  ProfileResponseModel profileResponseModel = ProfileResponseModel();

  String imageUrl = '';

  File? imageFile;
  String emailData = '';
  String countryData = '';
  String countryCodeData = '';
  String phoneCodeData = '';
  String phoneData = '';

  String loginType = '';

  Future<void> loadProfileInfo() async {
    isLoading = true;
    update();
    try {
      profileResponseModel = await profileRepo.loadProfileInfo();
      if (profileResponseModel.data != null && profileResponseModel.status?.toLowerCase() == MyStrings.success.toLowerCase()) {
        emailData = profileResponseModel.data?.user?.email ?? '';
        countryData = profileResponseModel.data?.user?.country ?? '';
        countryCodeData = profileResponseModel.data?.user?.countryCode ?? '';
        phoneData = profileResponseModel.data?.user?.mobile ?? '';
        loginType = profileResponseModel.data?.user?.loginBy ?? '';
      } else {
        isLoading = false;
        update();
      }
    } catch (e) {
      isLoading = false;
      update();
    }
    isLoading = false;
    update();
  } // country data

  TextEditingController searchCountryController = TextEditingController();
  bool countryLoading = true;
  List<Countries> countryList = [];
  List<Countries> filteredCountries = [];

  Countries selectedCountryData = Countries();
  void selectCountryData(Countries value) {
    selectedCountryData = value;
    update();
  }

  bool submitLoading = false;
  Future<void> updateProfile() async {
    String firstName = firstNameController.text;
    String lastName = lastNameController.text.toString();
    String address = addressController.text.toString();
    String city = cityController.text.toString();
    String zip = zipCodeController.text.toString();
    String state = stateController.text.toString();
    printD("model.username");

    submitLoading = true;
    update();

    UserPostModel model = UserPostModel(
      image: null,
      firstname: firstName,
      lastName: lastName,
      mobile: mobileNoController.text,
      email: '',
      username: userNameController.text,
      countryCode: selectedCountryData.countryCode.toString(),
      country: selectedCountryData.country.toString(),
      mobileCode: selectedCountryData.dialCode.toString(),
      address: address,
      state: state,
      zip: zip,
      city: city,
      refer: referController.text,
    );

    AuthorizationResponseModel responseModel = await profileRepo.updateProfile(model, false);

    if (responseModel.status == "success") {
      await profileRepo.apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.userFullNameKey,
        '$firstName $lastName',
      );
      CustomSnackBar.success(successList: responseModel.message ?? [MyStrings.requestSuccess]);
      RouteMiddleware.checkNGotoNext(user: responseModel.data?.user);
    } else {
      CustomSnackBar.error(errorList: responseModel.message ?? [MyStrings.somethingWentWrong]);
    }

    submitLoading = false;
    update();
  }
}
