import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/model/global/user/global_driver_model.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';

class DriverProfileWidget extends StatelessWidget {
  GlobalDriverInfo? driver;
  final String driverImage;
  final String serviceImage;
  final String totalCompletedRide;
  DriverProfileWidget({
    super.key,
    this.driver,
    required this.driverImage,
    required this.serviceImage,
    required this.totalCompletedRide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Get.toNamed(
                RouteHelper.driverReviewScreen,
                arguments: driver?.id,
              );
            },
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    MyImageWidget(
                      imageUrl: driverImage,
                      height: 50,
                      width: 50,
                      radius: Dimensions.radiusHuge,
                      boxFit: BoxFit.contain,
                      isProfile: true,
                    ),
                    Positioned(
                      bottom: -10,
                      right: 0,
                      left: 0,
                      child: Container(
                        decoration: BoxDecoration(color: MyColor.colorWhite, borderRadius: BorderRadius.circular(Dimensions.space20), boxShadow: [
                          BoxShadow(
                            color: MyColor.colorBlack.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: Offset(0, 0),
                          ),
                          BoxShadow(
                            color: MyColor.colorBlack.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]),
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.space3, vertical: Dimensions.space3),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
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
                                driver?.avgRating == '0.00' ? MyStrings.nA.tr : (driver?.avgRating ?? ''),
                                style: boldDefault.copyWith(
                                  fontSize: Dimensions.fontSmall,
                                  color: MyColor.getHeadingTextColor(),
                                ),
                              ),
                              spaceSide(Dimensions.space5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                spaceSide(Dimensions.space5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderText(
                        text: driver?.getFullName() ?? driver?.username ?? "",
                        style: boldLarge.copyWith(
                          color: MyColor.getTextColor(),
                          fontSize: Dimensions.fontTitleLarge,
                        ),
                      ),
                      spaceDown(Dimensions.space3),
                      Text(
                        "${MyStrings.rideCompleted.tr}: $totalCompletedRide",
                        style: regularDefault.copyWith(fontSize: Dimensions.fontDefault, color: MyColor.getBodyTextColor()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        spaceSide(Dimensions.space10),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if ((driver?.brand?.name ?? "").isNotEmpty)
                Text(
                  (driver?.brand?.name ?? "").toUpperCase(),
                  style: regularDefault.copyWith(color: MyColor.bodyTextColor),
                ),
              if ((driver?.vehicleData?.vehicleNumber ?? "").isNotEmpty)
                Text(
                  "(${driver?.vehicleData?.vehicleNumber ?? ""})",
                  style: boldDefault.copyWith(
                    color: MyColor.colorBlack,
                    fontSize: 24,
                  ),
                ),
              Text(
                [driver?.vehicleData?.color?.name, driver?.vehicleData?.model?.name, driver?.vehicleData?.year?.name].where((e) => (e != null && e.trim().isNotEmpty)).join(' | '),
                textAlign: TextAlign.end,
                style: lightDefault.copyWith(color: MyColor.bodyTextColor),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
