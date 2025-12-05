import 'package:ovorideuser/core/helper/date_converter.dart';
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
import 'package:ovorideuser/data/controller/ride/all_ride_controller.dart';
import 'package:ovorideuser/data/model/global/app/ride_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/services/download_service.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/custom_app_card.dart';
import 'package:ovorideuser/presentation/components/image/my_local_image_widget.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';
import '../../../components/divider/custom_spacer.dart';
import '../../../components/timeline/custom_time_line.dart';

class RideInfoCard extends StatefulWidget {
  AllRideController controller;
  RideModel ride;
  RideInfoCard({super.key, required this.controller, required this.ride});

  @override
  State<RideInfoCard> createState() => _RideInfoCardState();
}

class _RideInfoCardState extends State<RideInfoCard> {
  bool isDownLoadLoading = false;

  @override
  Widget build(BuildContext context) {
    return CustomAppCard(
      onPressed: () {
        Get.toNamed(
          RouteHelper.rideDetailsScreen,
          arguments: widget.ride.id.toString(),
        )?.then((value) {
          widget.controller.initialData(shouldLoading: false, tabID: widget.controller.selectedTab);
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimensions.space5,
                  vertical: Dimensions.space2,
                ),
                decoration: BoxDecoration(
                  color: MyUtils.getRideStatusColor(
                    widget.ride.status ?? '9',
                  ).withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(
                    Dimensions.mediumRadius,
                  ),
                  border: Border.all(
                    color: MyUtils.getRideStatusColor(
                      widget.ride.status ?? '9',
                    ),
                  ),
                ),
                child: Text(
                  MyUtils.getRideStatus(widget.ride.status ?? '9').tr,
                  style: regularDefault.copyWith(
                    fontSize: 16,
                    color: MyUtils.getRideStatusColor(
                      widget.ride.status ?? '9',
                    ),
                  ),
                ),
              ),
              spaceSide(Dimensions.space20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${widget.controller.defaultCurrencySymbol}${StringConverter.formatNumber(widget.ride.offerAmount.toString())}",
                      textAlign: TextAlign.end,
                      style: boldLarge.copyWith(
                        fontSize: Dimensions.fontLarge,
                        fontWeight: FontWeight.w700,
                        color: MyColor.rideTitle,
                      ),
                    ),
                    if (widget.ride.service != null && widget.ride.service!.name != null) ...[
                      Text(
                        widget.ride.service?.name ?? '',
                        textAlign: TextAlign.end,
                        style: regularLarge.copyWith(
                          color: MyColor.getBodyTextColor(),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space20),
          CustomTimeLine(
            indicatorPosition: 0.1,
            dashColor: MyColor.neutral300,
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
                        color: MyColor.getHeadingTextColor(),
                        fontSize: Dimensions.fontTitleLarge,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  spaceDown(Dimensions.space5),
                  Text(
                    widget.ride.pickupLocation ?? '',
                    style: regularDefault.copyWith(
                      color: MyColor.getBodyTextColor(),
                      fontSize: Dimensions.fontDefault,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.ride.startTime != null) ...[
                    spaceDown(Dimensions.space8),
                    Text(
                      DateConverter.estimatedDate(
                        DateTime.tryParse('${widget.ride.startTime}') ?? DateTime.now(),
                      ),
                      style: regularDefault.copyWith(
                        color: MyColor.bodyMutedTextColor,
                        fontSize: Dimensions.fontSmall,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  spaceDown(Dimensions.space15),
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
                        color: MyColor.getHeadingTextColor(),
                        fontSize: Dimensions.fontTitleLarge,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: Dimensions.space5 - 1),
                  Text(
                    widget.ride.destination ?? '',
                    style: regularDefault.copyWith(
                      color: MyColor.getBodyTextColor(),
                      fontSize: Dimensions.fontDefault,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.ride.endTime != null) ...[
                    spaceDown(Dimensions.space8),
                    Text(
                      DateConverter.estimatedDate(
                        DateTime.tryParse('${widget.ride.endTime}') ?? DateTime.now(),
                      ),
                      style: regularDefault.copyWith(
                        color: MyColor.bodyMutedTextColor,
                        fontSize: Dimensions.fontSmall,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ),
          spaceDown(Dimensions.space15),
          Column(
            children: [
              if (![AppStatus.RIDE_CANCELED, AppStatus.RIDE_COMPLETED, AppStatus.RIDE_ACTIVE, AppStatus.RIDE_PAYMENT_REQUESTED].contains(widget.ride.status))
                CustomAppCard(
                  radius: Dimensions.largeRadius,
                  width: double.infinity,
                  backgroundColor: MyColor.neutral100,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        MyStrings.createdTime.tr,
                        style: boldDefault.copyWith(
                          color: MyColor.colorGrey,
                        ),
                      ),
                      Text(
                        DateConverter.estimatedDate(
                          DateTime.tryParse('${widget.ride.createdAt}') ?? DateTime.now(),
                        ),
                        style: boldDefault.copyWith(
                          color: MyColor.colorGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.ride.status == AppStatus.RIDE_ACTIVE) ...[
                spaceDown(Dimensions.space15),
                buildMessageAndCallWidget(),
                spaceDown(Dimensions.space15),
              ],
              if (widget.ride.status == AppStatus.RIDE_PAYMENT_REQUESTED) ...[
                spaceDown(Dimensions.space15),
                RoundedButton(
                  text: MyStrings.payNow.tr,
                  press: () {
                    Get.toNamed(
                      RouteHelper.paymentScreen,
                      arguments: [widget.ride, ""],
                    )?.then((value) {
                      widget.controller.initialData(shouldLoading: false, tabID: widget.controller.selectedTab);
                    });
                  },
                  isOutlined: false,
                ),
              ],
              if (widget.ride.status == AppStatus.RIDE_PENDING) ...[
                spaceDown(Dimensions.space15),
                RoundedButton(
                  text: "${MyStrings.viewBids.tr}${widget.ride.bidsCount != null && widget.ride.bidsCount != "0" ? " (${widget.ride.bidsCount})" : ""}",
                  press: () {
                    Get.toNamed(
                      RouteHelper.rideBidScreen,
                      arguments: widget.ride.id.toString(),
                    )?.then((value) {
                      widget.controller.initialData(shouldLoading: false, tabID: widget.controller.selectedTab);
                    });
                  },
                  isOutlined: false,
                ),
              ],
              if (widget.ride.status == AppStatus.RIDE_COMPLETED) ...[
                spaceDown(Dimensions.space15),
                RoundedButton(
                  isOutlined: true,
                  text: MyStrings.receipt,
                  isLoading: isDownLoadLoading,
                  press: () async {
                    setState(() {
                      isDownLoadLoading = true;
                    });
                    await DownloadService.downloadPDF(
                      url: "${UrlContainer.rideReceipt}/${widget.ride.id}",
                      fileName: "${Environment.appName}_receipt_${widget.ride.id}.pdf",
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
                ),
              ],
              if (widget.ride.status == AppStatus.RIDE_CANCELED) ...[
                spaceDown(Dimensions.space15),
                if (widget.ride.cancelReason != null) ...[
                  CustomAppCard(
                    radius: Dimensions.largeRadius,
                    width: double.infinity,
                    backgroundColor: MyColor.redCancelTextColor.withValues(alpha: 0.1),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: widget.ride.canceledUserType == "1" ? (widget.ride.driver?.getFullName() ?? '') : MyStrings.byMe.tr,
                            style: boldLarge.copyWith(
                              color: MyColor.redCancelTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.ride.driver != null) ...[
                            TextSpan(
                              text: ' : ',
                              style: regularDefault.copyWith(
                                color: MyColor.redCancelTextColor,
                              ),
                            ),
                          ],
                          TextSpan(
                            text: widget.ride.cancelReason ?? '',
                            style: regularDefault.copyWith(
                              color: MyColor.redCancelTextColor,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMessageAndCallWidget() {
    return Row(
      children: [
        Expanded(
          child: CustomAppCard(
            radius: Dimensions.largeRadius,
            backgroundColor: MyColor.getPrimaryColor().withValues(alpha: 0.1),
            onPressed: () {
              Get.toNamed(RouteHelper.rideMessageScreen, arguments: [widget.ride.id.toString(), widget.ride.driver?.getFullName(), widget.ride.status.toString()]);
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyLocalImageWidget(
                  imagePath: MyIcons.message,
                  width: Dimensions.space25,
                  height: Dimensions.space25,
                  boxFit: BoxFit.contain,
                  imageOverlayColor: MyColor.getPrimaryColor(),
                ),
                spaceSide(Dimensions.space10),
                HeaderText(
                  text: MyStrings.message,
                  style: boldDefault.copyWith(fontSize: Dimensions.fontTitleLarge, color: MyColor.getPrimaryColor()),
                ),
              ],
            ),
          ),
        ),
        spaceSide(Dimensions.space10),
        Expanded(
          child: CustomAppCard(
            radius: Dimensions.largeRadius,
            backgroundColor: MyColor.getPrimaryColor().withValues(alpha: 0.1),
            onPressed: () {
              MyUtils.launchPhone('${widget.ride.driver?.mobile}');
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyLocalImageWidget(
                  imagePath: MyIcons.callIcon,
                  width: Dimensions.space25,
                  height: Dimensions.space25,
                  boxFit: BoxFit.contain,
                  imageOverlayColor: MyColor.getPrimaryColor(),
                ),
                spaceSide(Dimensions.space10),
                HeaderText(
                  text: MyStrings.call,
                  style: boldDefault.copyWith(fontSize: Dimensions.fontTitleLarge, color: MyColor.getPrimaryColor()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
