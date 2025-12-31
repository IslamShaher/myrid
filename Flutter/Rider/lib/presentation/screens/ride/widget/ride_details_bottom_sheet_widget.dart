import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:ovorideuser/data/services/api_client.dart';
import 'package:ovorideuser/data/services/download_service.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/bottom_sheet_bar.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/column_widget/card_column.dart';
import 'package:ovorideuser/presentation/components/divider/custom_divider.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_local_image_widget.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';
import 'package:ovorideuser/presentation/components/text/small_text.dart';
import 'package:ovorideuser/presentation/components/timeline/custom_time_line.dart';
import 'package:ovorideuser/presentation/packages/simple_ripple_animation.dart';
import 'package:ovorideuser/presentation/screens/location/widgets/driver_profile_widget.dart';
import 'package:ovorideuser/presentation/screens/location/widgets/ride_cancel_bottom_sheet_body.dart';
import 'package:ovorideuser/presentation/screens/location/widgets/ride_details_review_bottom_sheet.dart';
import 'package:ovorideuser/presentation/screens/location/widgets/ride_sos_bottom_sheet_body.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ovorideuser/presentation/screens/payment/widget/ride_details_tips_bottom_sheet_body.dart';
import 'package:ovorideuser/presentation/screens/ride/widget/searching_for_ride_aniamtion.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_fare_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_rate_user_widget.dart';

class RideDetailsBottomSheetWidget extends StatelessWidget {
  final ScrollController scrollController;

  final DraggableScrollableController draggableScrollableController;
  const RideDetailsBottomSheetWidget({
    super.key,
    required this.scrollController,
    required this.draggableScrollableController,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideDetailsController>(
      builder: (controller) {
        final ride = controller.ride;
        final currency = controller.currency;

        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: MyColor.colorWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimensions.moreRadius),
                  topRight: Radius.circular(Dimensions.moreRadius),
                ),
              ),
              padding: EdgeInsets.only(
                top: Dimensions.space10,
                left: Dimensions.space16,
                right: Dimensions.space16,
              ),
              child: ListView(
                clipBehavior: Clip.none,
                controller: scrollController,
                children: [
                  if (ride.status != AppStatus.RIDE_PAYMENT_REQUESTED && ride.status != AppStatus.RIDE_COMPLETED && ride.status != AppStatus.RIDE_CANCELED) ...[
                    spaceDown(Dimensions.space10),
                    BottomSheetBar(),
                    spaceDown(Dimensions.space10),
                  ],
                  //NEW RIDE
                  //Driver finding
                  if (ride.status == AppStatus.RIDE_PENDING) ...[
                    spaceDown(Dimensions.space10),
                    if (controller.totalBids == 0) ...[
                      SearchingForRideAnimation(),
                      spaceDown(Dimensions.space10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          HeaderText(
                            text: MyStrings.searchingForDriver.tr,
                            style: boldMediumLarge.copyWith(
                              color: MyColor.getHeadingTextColor(),
                            ),
                          ),
                          SmallText(
                            text: MyStrings.itMayTakeSomeTimes.tr,
                            textStyle: regularDefault.copyWith(
                              color: MyColor.getBodyTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      //Bid Found

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HeaderText(
                                  text: MyStrings.bidFoundTitle.tr,
                                  style: boldMediumLarge.copyWith(
                                    color: MyColor.getHeadingTextColor(),
                                  ),
                                ),
                                SmallText(
                                  text: MyStrings.bidFoundSubTitle.tr,
                                  maxLine: 10,
                                  textStyle: regularDefault.copyWith(
                                    color: MyColor.getBodyTextColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          spaceSide(Dimensions.space20),
                          IconButton(
                            onPressed: () {
                              Get.toNamed(
                                RouteHelper.rideBidScreen,
                                arguments: ride.id.toString(),
                              )?.then((value) async {
                                await Future.wait([
                                  controller.getRideBidList(ride.id ?? ""),
                                  controller.getRideDetails(ride.id ?? "", shouldLoading: false),
                                ]);
                              });
                            },
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: MyColor.primaryColor,
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.mediumRadius,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(Dimensions.space12),
                                  child: const MyLocalImageWidget(
                                    imagePath: MyIcons.driverIcon,
                                    height: Dimensions.space30,
                                    width: Dimensions.space30,
                                  ),
                                ),
                                Positioned(
                                  top: -10,
                                  right: -10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: MyColor.greenSuccessColor,
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.radiusHuge,
                                      ),
                                      border: Border.all(
                                        color: MyColor.colorWhite,
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(Dimensions.space2),
                                    height: Dimensions.space25,
                                    width: Dimensions.space25,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Center(
                                        child: Text(
                                          controller.totalBids.toString(),
                                          style: boldDefault.copyWith(
                                            color: MyColor.colorWhite,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      spaceDown(Dimensions.space20),
                    ],

                    spaceDown(Dimensions.space10),
                    //Ride details Counters Widget
                    buildRideCounterWidget(ride, currency),
                    spaceDown(Dimensions.space20),
                    RoundedButton(
                      text: MyStrings.cancelRide.tr,
                      press: () {
                        CustomBottomSheet(
                          child: const RideCancelBottomSheetBody(),
                        ).customBottomSheet(context);
                      },
                      bgColor: MyColor.redCancelTextColor,
                    ),
                  ],

                  //Active Ride
                  if (ride.status == AppStatus.RIDE_ACTIVE) ...[
                    SearchingForRideAnimation(),
                    spaceDown(Dimensions.space10),
                    Center(
                      child: SmallText(
                        text: MyStrings.driverArriveMsg.tr,
                        textStyle: regularDefault.copyWith(
                          color: MyColor.getBodyTextColor(),
                        ),
                      ),
                    ),
                    spaceDown(Dimensions.space20),
                    //Security code

                    Row(
                      children: [
                        HeaderText(
                          text: MyStrings.securityCode,
                        ),
                        spaceSide(Dimensions.space20),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: InkWell(
                              onTap: () {
                                MyUtils.copy(
                                  text: ride.otp ?? '',
                                );
                              },
                              child: Row(
                                children: [
                                  ...'${ride.otp}'.split('').asMap().entries.map(
                                    (entry) {
                                      final index = entry.key;
                                      final e = entry.value;
                                      final isLast = index == (ride.otp?.length ?? 0) - 1;

                                      return Padding(
                                        padding: EdgeInsetsDirectional.only(
                                          end: isLast ? 0 : Dimensions.space10,
                                        ),
                                        child: InnerShadowContainer(
                                          width: 40,
                                          height: 50,
                                          backgroundColor: MyColor.neutral50,
                                          borderRadius: Dimensions.largeRadius,
                                          blur: 6,
                                          offset: Offset(3, 3),
                                          shadowColor: MyColor.colorBlack.withValues(alpha: 0.04),
                                          isShadowTopLeft: true,
                                          isShadowBottomRight: true,
                                          child: Center(
                                              child: HeaderText(
                                            text: e,
                                          )),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ride.driver != null) ...[
                      spaceDown(Dimensions.space25),
                      DriverProfileWidget(
                        driver: ride.driver,
                        driverImage: '${controller.driverImagePath}/${ride.driver?.avatar ?? ''}',
                        serviceImage: '${controller.serviceImagePath}/${ride.service?.image ?? ''}',
                        totalCompletedRide: controller.driverTotalCompletedRide,
                      ),
                    ],
                    spaceDown(Dimensions.space30),
                    //messages or call widget
                    buildMessageOrCallWidget(ride),
                    spaceDown(Dimensions.space30),
                    RoundedButton(
                      text: MyStrings.cancelRide.tr,
                      press: () {
                        CustomBottomSheet(
                          child: const RideCancelBottomSheetBody(),
                        ).customBottomSheet(context);
                      },
                      bgColor: MyColor.redCancelTextColor,
                    ),
                  ],

                  //Running Ride
                  if (ride.status == AppStatus.RIDE_RUNNING) ...[
                    if (ride.driver != null) ...[
                      DriverProfileWidget(
                        driver: ride.driver,
                        driverImage: '${controller.driverImagePath}/${ride.driver?.avatar ?? ''}',
                        serviceImage: '${controller.serviceImagePath}/${ride.service?.image ?? ''}',
                        totalCompletedRide: controller.driverTotalCompletedRide,
                      ),
                      spaceDown(Dimensions.space25),
                      buildMessageOrCallWidget(ride),
                      spaceDown(Dimensions.space25),
                    ],
                    // Shared ride fare widget (only for shared rides)
                    if (ride.rideType == '4' && ride.secondUser != null) ...[
                      SharedRideFareWidget(
                        ride: ride,
                        rideDetailsController: controller,
                      ),
                      spaceDown(Dimensions.space15),
                    ],
                    buildRideCounterWidget(ride, currency),
                    spaceDown(Dimensions.space15),
                    buildRideLocationAndDestinationWidget(ride),
                    spaceDown(Dimensions.space15),
                    // Shared ride actions (End Ride / Mark Arrived)
                    if (ride.rideType == '4' && ride.secondUser != null) ...[
                      if (controller.hasLastDropoff()) ...[
                        RoundedButton(
                          text: 'End Ride',
                          bgColor: MyColor.primaryColor,
                          isLoading: controller.isEndingRide,
                          press: () async {
                            await controller.endSharedRide();
                            // After ending, show rating option
                            if (controller.ride.status == AppStatus.RIDE_COMPLETED.toString()) {
                              CustomBottomSheet(
                                child: SharedRideRateUserWidget(
                                  ride: controller.ride,
                                  rideDetailsController: controller,
                                ),
                              ).customBottomSheet(context);
                            }
                          },
                        ),
                        spaceDown(Dimensions.space10),
                      ] else if (controller.hasFirstDropoff()) ...[
                        RoundedButton(
                          text: 'I Arrived',
                          bgColor: MyColor.primaryColor,
                          isLoading: controller.isMarkingArrived,
                          press: () async {
                            await controller.markArrived();
                            // After marking arrived, show rating option
                            CustomBottomSheet(
                              child: SharedRideRateUserWidget(
                                ride: controller.ride,
                                rideDetailsController: controller,
                              ),
                            ).customBottomSheet(context);
                          },
                        ),
                        spaceDown(Dimensions.space10),
                      ],
                    ],
                    RoundedButton(
                      text: MyStrings.sos,
                      bgColor: MyColor.redCancelTextColor,
                      isLoading: controller.isSosLoading,
                      press: () {
                        CustomBottomSheet(
                          child: RideDetailsSosBottomSheetBody(
                            controller: controller,
                            id: ride.id ?? '-1',
                          ),
                        ).customBottomSheet(context);
                      },
                    ),
                  ],

                  //Ready For payment
                  if (ride.status == AppStatus.RIDE_PAYMENT_REQUESTED) ...[
                    spaceDown(Dimensions.space70),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              HeaderText(
                                text: MyStrings.billToPay,
                                style: regularDefault.copyWith(
                                  color: MyColor.getBodyTextColor(),
                                ),
                              ),
                              spaceDown(Dimensions.space3),
                              HeaderText(
                                text: "${controller.repo.apiClient.getCurrency(isSymbol: true)}${StringConverter.formatNumber(ride.amount.toString())}",
                                style: boldOverLarge.copyWith(color: MyColor.getHeadingTextColor(), fontSize: Dimensions.fontOverLarge22),
                              ),
                            ],
                          ),
                        ),
                        RoundedButton(
                          isOutlined: true,
                          text: MyStrings.addTip,
                          press: () async {
                            CustomBottomSheet(
                              child: const RideDetailsTipsBottomSheet(),
                            ).customBottomSheet(context);
                          },
                          bgColor: MyColor.getPrimaryColor().withValues(alpha: 0.1),
                          textColor: MyColor.getPrimaryColor(),
                          textStyle: regularDefault.copyWith(
                            color: MyColor.getPrimaryColor(),
                            fontSize: Dimensions.fontLarge,
                            fontWeight: FontWeight.bold,
                          ),
                          child: Row(
                            children: [
                              if (controller.tipsController.text.trim() == "") ...[
                                Icon(Icons.add, color: MyColor.getPrimaryColor(), size: Dimensions.space25),
                              ],
                              SizedBox(width: Dimensions.space5),
                              Text(controller.tipsController.text.trim() != "" ? "+${controller.currencySym}${controller.tipsController.text}" : MyStrings.addTip, style: boldLarge.copyWith(color: MyColor.getPrimaryColor())),
                            ],
                          ),
                        ),
                      ],
                    ),
                    spaceDown(Dimensions.space10),
                    CustomDivider(
                      space: Dimensions.space2,
                      color: MyColor.neutral500,
                    ),
                    if (ride.driver != null) ...[
                      spaceDown(Dimensions.space25),
                      DriverProfileWidget(
                        driver: ride.driver,
                        driverImage: '${controller.driverImagePath}/${ride.driver?.avatar ?? ''}',
                        serviceImage: '${controller.serviceImagePath}/${ride.service?.image ?? ''}',
                        totalCompletedRide: controller.driverTotalCompletedRide,
                      ),
                    ],
                    // buildMessageOrCallWidget(ride),
                    spaceDown(Dimensions.space25),
                    if (ride.paymentStatus == '2' && controller.isPaymentRequested == false) ...[
                      SizedBox(height: Dimensions.space20),
                      RoundedButton(
                        text: MyStrings.payNow,
                        isOutlined: false,
                        press: () {
                          Get.toNamed(
                            RouteHelper.paymentScreen,
                            arguments: [ride, controller.tipsController.text.trim()],
                          );
                        },
                        textColor: MyColor.colorWhite,
                      ).animate().shakeX(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          ),
                    ] else ...[
                      Column(
                        children: [
                          spaceDown(Dimensions.space10),
                          RippleAnimation(
                            repeat: true,
                            color: MyColor.primaryColor,
                            minRadius: 18,
                            child: Container(
                              padding: const EdgeInsets.all(
                                Dimensions.space15,
                              ),
                              decoration: BoxDecoration(
                                color: MyColor.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          spaceDown(Dimensions.space20),
                          Center(
                            child: Text(
                              MyStrings.waitForDriverResponse,
                              style: boldDefault.copyWith(
                                color: MyColor.primaryColor,
                              ),
                            ).animate(
                              onComplete: (controller) {
                                controller.repeat();
                                MyUtils.vibrate();
                              },
                            ).shimmer(
                              duration: const Duration(seconds: 2),
                              curve: Curves.easeInOut,
                            ),
                          ),
                          const SizedBox(height: Dimensions.space10),
                        ],
                      ),
                      SizedBox(height: Dimensions.space20),
                    ],
                  ],

                  //Completed Ride
                  if (ride.status == AppStatus.RIDE_COMPLETED) ...[
                    spaceDown(Dimensions.space60),
                    buildRideLocationAndDestinationWidget(ride),

                    spaceDown(Dimensions.space10),
                    CustomDivider(
                      space: Dimensions.space2,
                      color: MyColor.neutral500,
                    ),
                    spaceDown(Dimensions.space10),
                    //Ride details Counters Widget
                    // buildRideCounterWidget(ride, currency),
                    if (ride.driver != null) ...[
                      DriverProfileWidget(
                        driver: ride.driver,
                        driverImage: '${controller.driverImagePath}/${ride.driver?.avatar ?? ''}',
                        serviceImage: '${controller.serviceImagePath}/${ride.service?.image ?? ''}',
                        totalCompletedRide: controller.driverTotalCompletedRide,
                      ),
                    ],
                    spaceDown(Dimensions.space20),
                    // Shared ride: show rating option for other user
                    if (ride.rideType == '4' && ride.secondUser != null) ...[
                      // Check if user already rated the other user
                      // For now, we'll show the rating button if ride is completed
                      // TODO: Check if review exists for this user
                      spaceDown(Dimensions.space25),
                      RoundedButton(
                        text: 'Rate Co-Rider',
                        isOutlined: false,
                        press: () {
                          CustomBottomSheet(
                            child: SharedRideRateUserWidget(
                              ride: controller.ride,
                              rideDetailsController: controller,
                            ),
                          ).customBottomSheet(context);
                        },
                        textColor: MyColor.colorWhite,
                      ),
                      spaceDown(Dimensions.space15),
                    ],
                    // Normal ride: show rating option for driver
                    if (ride.driverReview == null && (ride.rideType != '4' || ride.secondUser == null)) ...[
                      spaceDown(Dimensions.space25),
                      RoundedButton(
                        text: MyStrings.review,
                        isOutlined: false,
                        press: () {
                          CustomBottomSheet(
                            child: RideDetailsReviewBottomSheet(
                              ride: controller.ride,
                            ),
                          ).customBottomSheet(context);
                        },
                        textColor: MyColor.colorWhite,
                      ),
                    ] else if (ride.rideType != '4' || ride.secondUser == null) ...[
                      spaceDown(Dimensions.space25),
                      Builder(builder: (context) {
                        bool isDownLoadLoading = false;
                        return StatefulBuilder(builder: (context, setState) {
                          return RoundedButton(
                            isOutlined: true,
                            text: MyStrings.receipt,
                            isLoading: isDownLoadLoading,
                            press: () async {
                              setState(() {
                                isDownLoadLoading = true;
                              });
                              await DownloadService.downloadPDF(
                                url: "${UrlContainer.rideReceipt}/${ride.id}",
                                fileName: "${Environment.appName}_receipt_${ride.id}.pdf",
                              );
                              setState(() {
                                isDownLoadLoading = false;
                              });
                            },
                            bgColor: MyColor.getPrimaryColor().withValues(alpha: 0.1),
                            textColor: MyColor.getPrimaryColor(),
                            textStyle: regularDefault.copyWith(
                              color: MyColor.getPrimaryColor(),
                              fontSize: Dimensions.fontLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        });
                      }),
                    ]
                  ],

                  //Canceled Ride
                  if (ride.status == AppStatus.RIDE_CANCELED) ...[
                    spaceDown(Dimensions.space70),
                    buildRideLocationAndDestinationWidget(ride),
                    spaceDown(Dimensions.space10),
                    CustomDivider(
                      space: Dimensions.space2,
                      color: MyColor.neutral500,
                    ),
                    spaceDown(Dimensions.space10),
                    //Ride details Counters Widget
                    buildRideCounterWidget(ride, currency),
                    spaceDown(Dimensions.space20),
                  ],
                ],
              ),
            ),

            //show arriving message
            if (ride.status == AppStatus.RIDE_PAYMENT_REQUESTED || (ride.status == AppStatus.RIDE_COMPLETED) || (ride.status == AppStatus.RIDE_CANCELED)) ...[
              Positioned(
                top: 0,
                right: 0,
                left: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.space20, vertical: Dimensions.space15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: (ride.status == AppStatus.RIDE_CANCELED) ? MyColor.redCancelTextColor.withValues(alpha: 0.2) : MyColor.getPrimaryColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.moreRadius),
                        topRight: Radius.circular(Dimensions.moreRadius),
                      ),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: HeaderText(
                          text: (ride.status == AppStatus.RIDE_COMPLETED)
                              ? MyStrings.rideCompleted
                              : (ride.status == AppStatus.RIDE_CANCELED)
                                  ? MyStrings.rideCanceled
                                  : MyStrings.arriveAtMsg.tr,
                          style: boldExtraLarge.copyWith(color: (ride.status == AppStatus.RIDE_CANCELED) ? MyColor.redCancelTextColor : MyColor.getPrimaryColor()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  CustomTimeLine buildRideLocationAndDestinationWidget(RideModel ride) {
    return CustomTimeLine(
      firstIndicatorColor: MyColor.getPrimaryColor(),
      indicatorPosition: 0.1,
      dashColor: MyColor.getPrimaryColor(),
      firstWidget: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                MyStrings.pickUpLocation.tr,
                style: boldLarge.copyWith(
                  color: MyColor.rideTitle,
                  fontSize: Dimensions.fontLarge - 1,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            spaceDown(Dimensions.space5),
            Text(
              ride.pickupLocation ?? '',
              style: regularDefault.copyWith(
                color: MyColor.getBodyTextColor(),
                fontSize: Dimensions.fontSmall,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            spaceDown(Dimensions.space10),
          ],
        ),
      ),
      secondWidget: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                MyStrings.destination.tr,
                style: boldLarge.copyWith(
                  color: MyColor.rideTitle,
                  fontSize: Dimensions.fontLarge - 1,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: Dimensions.space5 - 1),
            Text(
              ride.destination ?? '',
              style: regularDefault.copyWith(
                color: MyColor.getBodyTextColor(),
                fontSize: Dimensions.fontSmall,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Row buildMessageOrCallWidget(RideModel ride) {
    return Row(
      children: [
        Expanded(
          child: GetBuilder<RideMessageController>(
            builder: (msgController) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () {
                      msgController.updateCount(0);
                      Get.toNamed(RouteHelper.rideMessageScreen, arguments: [ride.id.toString(), ride.driver?.getFullName(), ride.status.toString()]);
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            MyStrings.anyPickUpNotes.tr,
                            style: regularLarge.copyWith(
                              color: MyColor.getBodyTextColor(),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (msgController.unreadMsg != 0) ...[
                    Positioned(
                      top: -8,
                      right: -8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: MyColor.redCancelTextColor,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusHuge,
                          ),
                          border: Border.all(
                            color: MyColor.colorWhite,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(Dimensions.space2),
                        height: Dimensions.space25,
                        width: Dimensions.space25,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Center(
                            child: Text(
                              msgController.unreadMsg.toString(),
                              style: boldDefault.copyWith(
                                color: MyColor.colorWhite,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().shakeX(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        ),
                  ],
                ],
              );
            },
          ),
        ),
        spaceSide(Dimensions.space5),
        IconButton(
          onPressed: () {
            MyUtils.launchPhone(
              '${ride.driver?.mobile}',
            );
          },
          icon: Container(
            decoration: BoxDecoration(
              color: MyColor.getPrimaryColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(Dimensions.largeRadius),
            ),
            height: Dimensions.space55,
            width: Dimensions.space55,
            padding: const EdgeInsets.all(Dimensions.space10),
            child: MyLocalImageWidget(
              imagePath: MyIcons.callIcon,
              height: Dimensions.space30,
              width: Dimensions.space30,
              imageOverlayColor: MyColor.getPrimaryColor(),
            ),
          ),
        ),
      ],
    );
  }

  Container buildRideCounterWidget(RideModel ride, String currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space15,
        vertical: Dimensions.space15,
      ),
      decoration: BoxDecoration(
        color: MyColor.neutral50,
        borderRadius: BorderRadius.circular(
          Dimensions.largeRadius,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: rideCardDetails(
                title: '${ride.getDistance()} ${MyUtils.getDistanceLabel(distance: ride.distance, unit: Get.find<ApiClient>().getDistanceUnit())}',
                description: MyStrings.distance,
              ),
            ),
          ),
          Container(
            color: MyColor.neutral200,
            height: Dimensions.space50,
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.space10,
            ),
            width: 1,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: rideCardDetails(
                title: '${ride.duration}',
                description: MyStrings.estimatedTime,
              ),
            ),
          ),
          Container(
            color: MyColor.neutral200,
            height: Dimensions.space50,
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.space10,
            ),
            width: 1,
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: rideCardDetails(
                title: '${StringConverter.formatNumber(ride.amount.toString())} $currency',
                description: MyStrings.rideFare,
              ),
            ),
          ),
        ],
      ),
    );
  }

  CardColumn rideCardDetails({
    required String title,
    required String description,
  }) {
    return CardColumn(
      header: title.tr,
      body: description.tr,
      headerTextStyle: boldMediumLarge.copyWith(color: MyColor.getPrimaryColor()),
      bodyTextStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
      alignmentCenter: true,
    );
  }
}
