import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/shared_preference_helper.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/model/global/app/ride_message_model.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/ride/ride_meassage_response_list.dart';
import 'package:ovorideuser/data/repo/message/message_repo.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class RideMessageController extends GetxController {
  MessageRepo repo;
  RideMessageController({required this.repo});

  bool isLoading = false;
  TextEditingController massageController = TextEditingController();
  String imagePath = "";
  String defaultCurrency = "";
  String defaultCurrencySymbol = "";
  String username = "";
  List<RideMessage> massageList = [];

  String userId = '-1';
  String rideId = '-1';

  File? imageFile;
  ScrollController scrollController = ScrollController();
  Future<void> initialData(String id) async {
    userId = repo.apiClient.getUserID();
    defaultCurrency = repo.apiClient.getCurrency();
    defaultCurrencySymbol = repo.apiClient.getCurrency(isSymbol: true);
    username = repo.apiClient.getUserName();
    massageList = [];
    rideId = id;
    imageFile = null;
    update();
    printX(userId);
    await getRideMessage(id);
  }

  Future<void> getRideMessage(String id, {bool shouldLoading = true}) async {
    isLoading = shouldLoading;
    update();
    try {
      ResponseModel responseModel = await repo.getRideMessageList(id: id);
      if (responseModel.statusCode == 200) {
        RideMessageListResponseModel model = RideMessageListResponseModel.fromJson((responseModel.responseJson));
        if (model.status == "success") {
          imagePath = '${UrlContainer.domainUrl}/${model.data?.imagePath}';
          massageList = model.data?.messages ?? [];
          update();
        } else {
          CustomSnackBar.error(errorList: model.message ?? [MyStrings.somethingWentWrong]);
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e);
    }

    isLoading = false;
    update();
  }

  bool isSubmitLoading = false;
  Future<void> sendMessage() async {
    isSubmitLoading = true;

    update();
    try {
      String msg = massageController.text;

      bool response = await repo.sendMessage(
        id: rideId,
        txt: msg,
        file: imageFile,
      );
      if (response == true) {
        isSubmitLoading = false;
        msg = '';
        massageController.text = '';
        imageFile = null;
        update();
        await getRideMessage(rideId, shouldLoading: false);
      } else {
        CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong]);
      }
    } catch (e) {
      printX(e);
    }
    isSubmitLoading = false;
    update();
  }

  void addEventMessage(RideMessage rideMessage) {
    userId = repo.apiClient.sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '-1';
    printX("$userId ${rideMessage.rideId}");
    massageList.insert(0, rideMessage);
    updateCount(unreadMsg + 1);
    MyUtils.vibrate();
    update();
  }

  void pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );
    if (result == null) return;

    imageFile = File(result.files.single.path!);

    update();
  }

  int unreadMsg = 0;
  void updateCount(int c) {
    if (Get.currentRoute == RouteHelper.rideMessageScreen) {
      unreadMsg = 0;
      try {
        scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(microseconds: 500), curve: Curves.easeInOut);
      } catch (e) {
        printE(e);
      }
    } else {
      unreadMsg = c;
    }
    update();
  }
}
