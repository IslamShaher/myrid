import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/shimmer/create_ride_shimmer.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/bottomsheet/ride_meassage_bottom_sheet_body.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_offer_rate_widget.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_select_payment_method.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/passenger_bottom_sheet.dart';

class RideCreateForm extends StatelessWidget {
  const RideCreateForm({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              MyStrings.findDriver.tr,
              style: boldLarge.copyWith(
                color: MyColor.getRideTitleColor(),
                fontWeight: FontWeight.w500,
                fontSize: Dimensions.fontTitleLarge,
              ),
            ),
            spaceDown(Dimensions.space10),
            if (controller.isLoading) ...[
              CreateRideShimmer(),
            ] else ...[
              InkWell(
                onTap: () {
                  if (controller.isPriceLocked == false) {
                    CustomBottomSheet(
                      child: const HomeSelectPaymentMethod(),
                    ).customBottomSheet(context);
                  }
                },
                child: InnerShadowContainer(
                  width: double.infinity,
                  backgroundColor: MyColor.neutral50,
                  borderRadius: Dimensions.largeRadius,
                  blur: 6,
                  offset: Offset(3, 3),
                  shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                  isShadowTopLeft: true,
                  isShadowBottomRight: true,
                  padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (controller.selectedPaymentMethod.id == '-1' || controller.selectedPaymentMethod.id == '-9') ...[
                            CustomSvgPicture(
                              image: MyIcons.money,
                              color: MyColor.primaryColor,
                              width: Dimensions.space30,
                              height: Dimensions.space30,
                            ),
                          ] else ...[
                            MyImageWidget(
                              imageUrl: '${UrlContainer.domainUrl}/${controller.gatewayImagePath}/${controller.selectedPaymentMethod.method?.image}',
                              width: Dimensions.space30,
                              height: Dimensions.space30,
                              boxFit: BoxFit.fitWidth,
                              radius: 4,
                            ),
                          ],
                          spaceSide(Dimensions.space10),
                          Text(
                            (controller.selectedPaymentMethod.id == '-1' ? MyStrings.paymentMethod.tr : controller.selectedPaymentMethod.method?.name ?? MyStrings.paymentMethod).tr,
                            style: regularDefault.copyWith(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: MyColor.getRideSubTitleColor(),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              spaceDown(Dimensions.space15),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () {
                          if (controller.selectedService.id != '-99') {
                            if (controller.isPriceLocked == false) {
                              controller.updateMainAmount(controller.mainAmount);
                              CustomBottomSheet(child: const HomeOfferRateWidget()).customBottomSheet(context);
                            }
                          } else {
                            CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
                          }
                        },
                        child: InnerShadowContainer(
                          width: double.infinity,
                          backgroundColor: MyColor.neutral50,
                          borderRadius: Dimensions.largeRadius,
                          blur: 6,
                          offset: Offset(3, 3),
                          shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                          isShadowTopLeft: true,
                          isShadowBottomRight: true,
                          padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  controller.mainAmount == 0 ? MyStrings.offerYourRate.tr : '${StringConverter.formatDouble(controller.mainAmount.toString())} ${controller.defaultCurrency}',
                                  style: regularDefault.copyWith(
                                    color: MyColor.bodyTextColor,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: MyColor.getRideSubTitleColor(),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    spaceSide(Dimensions.space15),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () {
                          if (controller.selectedService.id != '-99') {
                            CustomBottomSheet(
                              child: const PassengerBottomSheet(),
                            ).customBottomSheet(context);
                          } else {
                            CustomSnackBar.error(errorList: [MyStrings.pleaseSelectAService]);
                          }
                        },
                        child: InnerShadowContainer(
                          width: double.infinity,
                          backgroundColor: MyColor.neutral50,
                          borderRadius: Dimensions.largeRadius,
                          blur: 6,
                          offset: Offset(3, 3),
                          shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                          isShadowTopLeft: true,
                          isShadowBottomRight: true,
                          padding: EdgeInsetsGeometry.symmetric(vertical: Dimensions.space16, horizontal: Dimensions.space16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CustomSvgPicture(
                                      image: MyIcons.user,
                                      color: MyColor.primaryColor,
                                    ),
                                    spaceSide(Dimensions.space8),
                                    Expanded(
                                      child: Text(
                                        "${controller.passenger.toString()} ${MyStrings.person.tr}",
                                        style: regularDefault.copyWith(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: MyColor.getRideSubTitleColor(),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              spaceDown(Dimensions.space15),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        text: MyStrings.findDriver.tr,
                        isLoading: controller.isSubmitLoading,
                        press: () {
                          if (controller.isValidForNewRide()) {
                            controller.createRide();
                          }
                        },
                        isOutlined: false,
                      ),
                    ),
                    const SizedBox(width: Dimensions.space8),
                    IconButton(
                      onPressed: () {
                        if (controller.selectedService.id != '-99') {
                          CustomBottomSheet(
                            child: const RideMassageBottomSheet(),
                          ).customBottomSheet(context);
                        }
                      },
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12, vertical: Dimensions.space12),
                        decoration: BoxDecoration(
                          color: MyColor.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            Dimensions.largeRadius,
                          ),
                          border: Border.all(
                            color: MyColor.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        child: CustomSvgPicture(
                          image: MyIcons.note,
                          color: MyColor.primaryColor,
                          height: Dimensions.space25,
                          width: Dimensions.space25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
