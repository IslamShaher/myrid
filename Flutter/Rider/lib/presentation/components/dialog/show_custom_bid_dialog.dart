import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/model/global/bid/bid_model.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';
import 'package:toastification/toastification.dart';

class CustomBidDialog {
  static void newBid({
    required BidModel bid,
    required String currency,
    required String driverImagePath,
    required String serviceImagePath,
    required String totalRideCompleted,
    int duration = 20,
  }) {
    toastification.showCustom(
      context: Get.context, // optional if you use ToastificationWrapper
      autoCloseDuration: Duration(seconds: duration),
      alignment: Alignment.topCenter,

      dismissDirection: DismissDirection.horizontal,
      builder: (BuildContext context, ToastificationItem holder) {
        return buildBidPoupDesign(
          holder: holder,
          bid: bid,
          currency: currency,
          driverImagePath: driverImagePath,
          serviceImagePath: serviceImagePath,
          totalRideCompleted: totalRideCompleted,
        );
      },
    );
  }

  static Widget buildBidPoupDesign({
    required BidModel bid,
    required String currency,
    required String driverImagePath,
    required String serviceImagePath,
    required String totalRideCompleted,
    required ToastificationItem holder,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.space10, vertical: Dimensions.space10),
      child: Material(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.largeRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.space15, horizontal: Dimensions.space20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        MyImageWidget(
                          imageUrl: driverImagePath,
                          height: 50,
                          width: 50,
                          radius: Dimensions.radiusHuge,
                          boxFit: BoxFit.contain,
                          isProfile: true,
                        ),
                        spaceSide(Dimensions.space5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: HeaderText(
                                      text: bid.driver?.getFullName() ?? bid.driver?.username ?? "",
                                      style: boldLarge.copyWith(
                                        color: MyColor.getTextColor(),
                                        fontSize: Dimensions.fontTitleLarge,
                                      ),
                                    ),
                                  ),
                                  if (bid.bidAmount != null) ...[
                                    spaceSide(Dimensions.space10),
                                    Text(
                                      bid.bidAmount == null ? "" : "$currency${bid.bidAmount}",
                                      style: boldExtraLarge.copyWith(color: MyColor.primaryColor),
                                    ),
                                  ]
                                ],
                              ),
                              spaceDown(Dimensions.space3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: MyColor.colorOrange,
                                    size: Dimensions.fontExtraLarge,
                                  ),
                                  spaceSide(Dimensions.space3),
                                  Text(
                                    bid.driver?.avgRating == '0.00' ? MyStrings.nA.tr : (bid.driver?.avgRating ?? ''),
                                    style: boldDefault.copyWith(
                                      fontSize: Dimensions.fontSmall,
                                      color: MyColor.getHeadingTextColor(),
                                    ),
                                  ),
                                  spaceSide(Dimensions.space5),
                                  if (bid.driver?.vehicleData?.model?.name != null) ...[
                                    Text(
                                      "•",
                                      style: boldDefault.copyWith(
                                        fontSize: Dimensions.fontSmall,
                                        color: MyColor.getHeadingTextColor(),
                                      ),
                                    ),
                                    spaceSide(Dimensions.space5),
                                    Expanded(
                                      child: Text(
                                        bid.driver?.vehicleData?.model?.name ?? "",
                                        style: regularDefault.copyWith(fontSize: Dimensions.fontDefault, color: MyColor.getBodyTextColor()),
                                        maxLines: 2,
                                        textAlign: TextAlign.start,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space20),
              Row(
                children: [
                  Expanded(
                    child: GetBuilder<RideDetailsController>(builder: (controller) {
                      return RoundedButton(
                        isOutlined: true,
                        text: MyStrings.cancel,
                        isLoading: controller.isRejectLoading && controller.selectedId == bid.id.toString(),
                        press: () async {
                          controller.rejectBid(
                            bid.id.toString(),
                            onSuccess: () {
                              toastification.dismissById(holder.id);
                            },
                          );
                        },
                        bgColor: MyColor.getPrimaryColor().withValues(alpha: 0.1),
                        textColor: MyColor.getPrimaryColor(),
                        textStyle: regularDefault.copyWith(
                          color: MyColor.getPrimaryColor(),
                          fontSize: Dimensions.fontLarge,
                          fontWeight: FontWeight.bold,
                        ),
                        isColorChange: true,
                      );
                    }),
                  ),
                  const SizedBox(width: Dimensions.space20),
                  Expanded(
                    child: GetBuilder<RideDetailsController>(builder: (controller) {
                      return RoundedButton(
                        text: MyStrings.confirm,
                        isLoading: controller.isAcceptLoading && controller.selectedId == bid.id.toString(),
                        press: () async {
                          controller.acceptBid(
                            bid.id.toString(),
                            onSuccess: () {
                              toastification.dismissById(holder.id);
                            },
                          );
                        },
                        bgColor: MyColor.primaryColor,
                        isColorChange: true,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
