import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/presentation/components/card/inner_shadow_container.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';

import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/utils/util.dart';
import '../../../components/divider/custom_spacer.dart';
import '../../../components/text/header_text.dart';

class LocationPickUpHomeWidget extends StatefulWidget {
  final HomeController controller;
  const LocationPickUpHomeWidget({super.key, required this.controller});

  @override
  State<LocationPickUpHomeWidget> createState() => _LocationPickUpHomeWidgetState();
}

class _LocationPickUpHomeWidgetState extends State<LocationPickUpHomeWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        boxShadow: MyUtils.getCardShadow(),
        borderRadius: BorderRadius.circular(Dimensions.moreRadius),
      ),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: Dimensions.space16, vertical: Dimensions.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderText(
            text: MyStrings.letsTakeARide,
            style: boldLarge.copyWith(fontSize: 17),
          ),
          spaceDown(Dimensions.space15),
          InkWell(
            onTap: () {
              widget.controller.updateIsServiceShake(false);
              Get.toNamed(RouteHelper.locationPickUpScreen, arguments: [1])?.then((v) {
                if (widget.controller.selectedLocations.length > 1) {
                  widget.controller.getRideFare();
                }
              });
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
                  CustomSvgPicture(
                    image: MyIcons.location,
                    color: MyColor.primaryColor,
                  ),
                  spaceSide(Dimensions.space10),
                  Expanded(
                    child: Text(
                      (widget.controller.getSelectedLocationInfoAtIndex(1)?.getFullAddress(showFull: true) ?? MyStrings.whereToGo.tr),
                      style: regularDefault.copyWith(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // LocationPickTextField(
          //   hintText: MyStrings.pickUpLocation,
          //   controller: TextEditingController(
          //     text: widget.controller.getSelectedLocationInfoAtIndex(0)?.getFullAddress(showFull: true) ?? (widget.controller.currentAddress.contains(MyStrings.loading) ? '' : widget.controller.currentAddress),
          //   ),
          //   onTap: () {
          //     widget.controller.updateIsServiceShake(false);
          //     Get.toNamed(RouteHelper.locationPickUpScreen, arguments: [0])?.then((v) {
          //       if (widget.controller.selectedLocations.length > 1 && widget.controller.selectedService.id != '-99') {
          //         widget.controller.getRideFare();
          //       }
          //     });
          //   },
          //   onChanged: (val) {},
          //   radius: Dimensions.mediumRadius,
          //   readOnly: true,
          //   prefixIcon: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 10.0),
          //     child: CustomSvgPicture(
          //       image: MyIcons.currentLocation,
          //       color: MyColor.primaryColor,
          //     ),
          //   ),
          // ),
          // SizedBox(
          //   child: Padding(
          //     padding: EdgeInsetsDirectional.only(start: 20),
          //     child: Column(
          //       children: List.generate(
          //         6,
          //         (index) => Container(
          //           decoration: BoxDecoration(color: MyColor.primaryColor),
          //           width: 1,
          //           height: 3,
          //           margin: EdgeInsets.only(bottom: 1),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // LocationPickTextField(
          //   controller: TextEditingController(
          //     text: widget.controller.getSelectedLocationInfoAtIndex(1)?.getFullAddress(showFull: true) ?? '',
          //   ),
          //   onTap: () {
          //     widget.controller.updateIsServiceShake(false);
          //     Get.toNamed(RouteHelper.locationPickUpScreen, arguments: [1])?.then((v) {
          //       if (widget.controller.selectedLocations.length > 1 && widget.controller.selectedService.id != '-99') {
          //         widget.controller.getRideFare();
          //       }
          //     });
          //   },
          //   fillColor: MyColor.secondaryScreenBgColor,
          //   borderColor: MyColor.naturalTextColor,
          //   textColor: MyColor.bodyMutedTextColor,
          //   onChanged: (val) {},
          //   hintText: MyStrings.whereToGo.tr,
          //   radius: Dimensions.largeRadius,
          //   readOnly: true,
          //   prefixIcon: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 10.0),
          //     child: CustomSvgPicture(
          //       image: MyIcons.location,
          //       color: MyColor.primaryColor,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
