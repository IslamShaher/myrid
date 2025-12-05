import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/model/global/response_model/response_model.dart';
import 'package:ovorideuser/data/model/global/user/global_user_model.dart';
import 'package:ovorideuser/data/model/payment_history/payment_history_response_model.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

import '../../../core/utils/my_color.dart';
import '../../repo/payment_history/payment_history_repo.dart';

class PaymentHistoryController extends GetxController {
  PaymentHistoryRepo paymentRepo;
  PaymentHistoryController({required this.paymentRepo});

  bool isLoading = true;
  final formKey = GlobalKey<FormState>();

  List<String> transactionTypeList = ["All", "Plus", "Minus"];
  List<String> remarksList = ["All"];

  List<PaymentHistoryData> transactionList = [];
  GlobalUser user = GlobalUser();

  String? nextPageUrl;
  String trxSearchText = '';
  String currency = '';
  String currencySym = '';

  int page = 0;
  int index = 0;

  TextEditingController trxController = TextEditingController();

  String selectedRemark = "All";
  String selectedTrxType = "All";

  void initData({bool shouldLoad = true}) async {
    page = 0;
    selectedRemark = "All";
    selectedTrxType = "All";
    trxController.text = '';
    trxSearchText = '';
    isLoading = shouldLoad;
    update();
    user = await paymentRepo.loadProfileInfo();
    await loadTransaction();
  }

  Future<void> loadTransaction({bool shouldLoad = true}) async {
    try {
      page = page + 1;

      if (page == 1) {
        currency = paymentRepo.apiClient.getCurrency();
        currencySym = paymentRepo.apiClient.getCurrency(isSymbol: true);
        remarksList.clear();
      }

      ResponseModel responseModel = await paymentRepo.getTransactionList(
        page,
        type: selectedTrxType.toLowerCase(),
        remark: selectedRemark.toLowerCase(),
        searchText: trxSearchText,
      );

      if (responseModel.statusCode == 200) {
        PaymentHistoryResponseModel model = PaymentHistoryResponseModel.fromJson((responseModel.responseJson));

        nextPageUrl = model.data?.payments?.nextPageUrl;

        if (model.status.toString().toLowerCase() == MyStrings.success.toLowerCase()) {
          List<PaymentHistoryData>? tempDataList = model.data?.payments?.data ?? [];
          if (page == 1) {
            transactionList.clear();
          }

          if (tempDataList.isNotEmpty) {
            transactionList.addAll(tempDataList);
            if (page == 1) {
              changeExpandIndex(0);
            }
          }
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
      update();
    } catch (e) {
      printE(e.toString());
    } finally {
      isLoading = false;
      update();
    }
  }

  void changeSelectedRemark(String remarks) {
    selectedRemark = remarks;
    update();
  }

  void changeSelectedTrxType(String trxType) {
    selectedTrxType = trxType;
    update();
  }

  bool filterLoading = false;

  Future<void> filterData() async {
    trxSearchText = trxController.text;
    page = 0;
    filterLoading = true;
    update();
    transactionList.clear();

    await loadTransaction();

    filterLoading = false;
    update();
  }

  bool hasNext() {
    return nextPageUrl != null && nextPageUrl!.isNotEmpty && nextPageUrl != 'null' ? true : false;
  }

  bool isSearch = false;
  void changeSearchIcon() {
    isSearch = !isSearch;
    update();
    if (!isSearch) {
      initData();
    }
  }

  Color changeTextColor(String trxType) {
    return trxType == "+" ? MyColor.greenSuccessColor : MyColor.colorRed;
  }

  int expandIndex = -1;
  void changeExpandIndex(int index) {
    expandIndex = expandIndex == index ? -1 : index;
    update();
  }
}
