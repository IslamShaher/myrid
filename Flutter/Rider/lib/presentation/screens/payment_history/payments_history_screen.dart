import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/payment_history/payment_history_controller.dart';
import 'package:ovorideuser/data/repo/payment_history/payment_history_repo.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/no_data.dart';
import 'package:ovorideuser/presentation/components/shimmer/transaction_card_shimmer.dart';
import 'package:ovorideuser/presentation/screens/payment_history/widget/custom_payment_card.dart';
import 'package:get/get.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final ScrollController scrollController = ScrollController();

  void fetchData() {
    Get.find<PaymentHistoryController>().loadTransaction();
  }

  void scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      if (Get.find<PaymentHistoryController>().hasNext()) {
        fetchData();
      }
    }
  }

  @override
  void initState() {
    Get.put(PaymentHistoryRepo(apiClient: Get.find()));
    final controller = Get.put(
      PaymentHistoryController(paymentRepo: Get.find()),
    );

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initData();
      scrollController.addListener(scrollListener);
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PaymentHistoryController>(
      builder: (controller) => AnnotatedRegionWidget(
        child: Scaffold(
          backgroundColor: MyColor.secondaryScreenBgColor,
          appBar: CustomAppBar(
            isTitleCenter: false,
            elevation: 1,
            title: MyStrings.payment,
          ),
          body: RefreshIndicator(
            color: MyColor.primaryColor,
            backgroundColor: MyColor.colorWhite,
            onRefresh: () async {
              controller.initData(shouldLoad: true);
            },
            child: controller.isLoading
                ? ListView.separated(
                    itemCount: 20,
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.space16,
                      vertical: Dimensions.space16,
                    ),
                    separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space10),
                    itemBuilder: (context, index) {
                      return Container(
                          decoration: BoxDecoration(
                            color: MyColor.getCardBgColor(),
                            boxShadow: MyUtils.getCardShadow(),
                            borderRadius: BorderRadius.circular(Dimensions.moreRadius),
                          ),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.space16,
                            vertical: Dimensions.space16,
                          ),
                          child: TransactionCardShimmer());
                    },
                  )
                : controller.transactionList.isEmpty && controller.isLoading == false
                    ? Center(child: NoDataWidget(text: MyStrings.noTrxFound))
                    : ListView.separated(
                        controller: scrollController,
                        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.space16,
                          vertical: Dimensions.space16,
                        ),
                        scrollDirection: Axis.vertical,
                        itemCount: controller.transactionList.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space10),
                        itemBuilder: (context, index) {
                          if (controller.transactionList.length == index) {
                            return controller.hasNext()
                                ? Container(
                                    height: 40,
                                    width: MediaQuery.of(context).size.width,
                                    margin: const EdgeInsets.all(5),
                                    child: const CustomLoader(),
                                  )
                                : const SizedBox();
                          }

                          return CustomPaymentCard(
                            index: index,
                            expandIndex: controller.expandIndex,
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}
