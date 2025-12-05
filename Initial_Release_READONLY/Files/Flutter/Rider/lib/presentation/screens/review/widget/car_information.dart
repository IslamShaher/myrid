import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/review/review_controller.dart';
import 'package:ovorideuser/data/model/global/user/global_driver_model.dart';
import 'package:ovorideuser/presentation/components/column_widget/card_column.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';

class CarInformation extends StatefulWidget {
  const CarInformation({super.key});

  @override
  State<CarInformation> createState() => _CarInformationState();
}

class _CarInformationState extends State<CarInformation> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReviewController>(
      builder: (controller) {
        return SizedBox(
          width: double.infinity,
          child: ListView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
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
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MyStrings.driverInformation.tr,
                          style: boldDefault.copyWith(),
                        ),
                        spaceDown(Dimensions.space10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 10,
                            children: [
                              verifiedChip(
                                text: MyStrings.email.tr,
                                isVerified: controller.driver?.ev == "1",
                              ),
                              verifiedChip(
                                text: MyStrings.phone.tr,
                                isVerified: controller.driver?.sv == "1",
                              ),
                              verifiedChip(
                                text: MyStrings.driverVerification.tr,
                                isVerified: controller.driver?.dv == "1",
                              ),
                              verifiedChip(
                                text: MyStrings.vehicleVerification.tr,
                                isVerified: controller.driver?.vv == "1",
                              ),
                            ],
                          ),
                        ),
                        spaceDown(Dimensions.space10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            controller.driver?.driverData?.length ?? 0,
                            (index) => vehicleData(
                              data: controller.driver?.driverData?[index] ?? KycPendingData(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // spaceDown(Dimensions.space20),
                  // AnimatedContainer(
                  //   decoration: BoxDecoration(
                  //     color: MyColor.getCardBgColor(),
                  //     boxShadow: MyUtils.getCardShadow(),
                  //     borderRadius: BorderRadius.circular(Dimensions.moreRadius),
                  //   ),
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: Dimensions.space16,
                  //     vertical: Dimensions.space16,
                  //   ),
                  //   duration: const Duration(milliseconds: 500),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         MyStrings.additionalInformation.tr,
                  //         style: boldDefault.copyWith(),
                  //       ),
                  //       spaceDown(Dimensions.space10),
                  //     ],
                  //   ),
                  // ),
                  spaceDown(Dimensions.space20),
                  AnimatedContainer(
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
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MyStrings.carRules.tr,
                          style: boldDefault.copyWith(),
                        ),
                        spaceDown(Dimensions.space10),
                        Column(
                          children: List.generate(
                            (controller.driver?.rules?.length ?? 0),
                            (index) => rulesData(
                              text: controller.driver?.rules?[index] ?? "",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  spaceDown(Dimensions.space20),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget verifiedChip({required String text, bool isVerified = false}) {
    return Row(
      children: [
        Text(
          text.tr,
          style: boldDefault.copyWith(
            color: isVerified ? MyColor.getHeadingTextColor() : MyColor.getHeadingTextColor().withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(width: Dimensions.space5),
        Icon(
          isVerified ? Icons.check : Icons.close_outlined,
          size: Dimensions.space15,
          color: isVerified ? MyColor.greenSuccessColor : MyColor.redCancelTextColor,
        ),
        const SizedBox(width: Dimensions.space5),
      ],
    );
  }

  Widget rulesData({required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: MyColor.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Dimensions.space8),
          Text(
            text.tr.toTitleCase(),
            style: regularDefault.copyWith(color: MyColor.bodyTextColor),
          ),
        ],
      ),
    );
  }

  Widget vehicleData({required KycPendingData data}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CardColumn(
        header: data.name ?? '',
        body: data.type == "file" ? "Attachment".tr : data.value ?? '',
        bodyMaxLine: 2,
        headerTextStyle: regularDefault.copyWith(color: MyColor.bodyTextColor),
        bodyTextStyle: boldDefault.copyWith(color: MyColor.colorBlack),
      ),
    );
  }
}
