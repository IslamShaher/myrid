import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/ride_bid_list/ride_bid_list_controller.dart';
import 'package:ovorideuser/data/model/global/bid/bid_model.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/custom_app_card.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';

import '../../../components/divider/custom_spacer.dart';

class BidInfoCard extends StatelessWidget {
  BidModel bid;
  RideModel ride;
  String currency;

  BidInfoCard({
    super.key,
    required this.bid,
    required this.ride,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideBidListController>(
      builder: (controller) {
        return CustomAppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Get.toNamed(
                          RouteHelper.driverReviewScreen,
                          arguments: bid.driver?.id,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: MyColor.borderColor,
                              width: .5,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: MyImageWidget(
                            imageUrl: '${controller.driverImagePath}${bid.driver?.avatar}',
                            isProfile: true,
                            height: 40,
                            width: 40,
                            radius: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.space10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${bid.driver?.getFullName()}",
                            style: regularDefault.copyWith(fontSize: 16),
                          ),
                          Row(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 12,
                                    color: MyColor.colorYellow,
                                  ),
                                  const SizedBox(width: Dimensions.space2),
                                  Text(
                                    "${bid.driver?.avgRating}",
                                    style: boldDefault.copyWith(
                                      color: MyColor.colorGrey,
                                      fontSize: Dimensions.fontDefault,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: Dimensions.space8),
                              Text(
                                "${ride.duration}, ${ride.getDistance()} ${MyUtils.getDistanceLabel(distance: ride.distance, unit: Get.find<ApiClient>().getDistanceUnit())}",
                                style: boldDefault.copyWith(
                                  color: MyColor.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.space5),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    "$currency${StringConverter.formatNumber(bid.bidAmount.toString())}",
                    style: boldLarge.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MyColor.rideTitle,
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space20),
              if (bid.driver?.rules?.isNotEmpty ?? false) ...[
                Text(MyStrings.rideRulse.tr, style: boldLarge),
                spaceDown(Dimensions.space5),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: Dimensions.space10),
                  child: Column(
                    children: List.generate(
                      (bid.driver?.rules?.length ?? 0),
                      (index) => rulseData(text: bid.driver?.rules?[index] ?? ""),
                    ),
                  ),
                ),
                spaceDown(Dimensions.space20),
              ],
              Row(
                children: [
                  Expanded(
                    child: RoundedButton(
                      isOutlined: true,
                      text: MyStrings.reject,
                      isLoading: controller.isRejectLoading && controller.selectedId == bid.id.toString(),
                      press: () async {
                        await controller.rejectBid(bid.id.toString());
                      },
                      bgColor: MyColor.getPrimaryColor().withValues(alpha: 0.1),
                      textColor: MyColor.getPrimaryColor(),
                      textStyle: regularDefault.copyWith(
                        color: MyColor.getPrimaryColor(),
                        fontSize: Dimensions.fontLarge,
                        fontWeight: FontWeight.bold,
                      ),
                      isColorChange: true,
                    ),
                  ),
                  const SizedBox(width: Dimensions.space20),
                  Expanded(
                    child: RoundedButton(
                      text: MyStrings.confirm,
                      isLoading: controller.isAcceptLoading && controller.selectedId == bid.id.toString(),
                      press: () async {
                        await controller.acceptBid(
                          bid.id.toString(),
                          ride.id.toString(),
                        );
                      },
                      bgColor: MyColor.primaryColor,
                      isColorChange: true,
                    ),
                  ),
                ],
              ),
              spaceDown(Dimensions.space10),
            ],
          ),
        );
      },
    );
  }

  Widget rulseData({required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
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
          Expanded(
            child: Text(
              text,
              style: regularDefault.copyWith(color: MyColor.bodyTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
