import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/my_bottom_sheet_bar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/card/custom_app_card.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class PassengerBottomSheet extends StatelessWidget {
  const PassengerBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return AnnotatedRegionWidget(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space15,
              vertical: Dimensions.space10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MyBottomSheetBar(),
                const SizedBox(height: Dimensions.space10),
                Text(
                  MyStrings.howManyOfYouWillGo.tr,
                  style: boldExtraLarge.copyWith(),
                ),
                const SizedBox(height: Dimensions.space40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ZoomTapAnimation(
                      onTap: () => controller.updatePassenger(false),
                      child: CustomAppCard(
                        backgroundColor: MyColor.neutral100,
                        padding: EdgeInsets.all(Dimensions.space10),
                        child: Icon(
                          Icons.remove,
                          size: Dimensions.space40,
                          color: MyColor.getHeadingTextColor(),
                        ),
                      ),
                    ),
                    Text(
                      controller.passenger.toString(),
                      style: boldExtraLarge.copyWith(
                        fontSize: Dimensions.fontBalance,
                      ),
                    ),
                    ZoomTapAnimation(
                      onTap: () => controller.updatePassenger(true),
                      child: CustomAppCard(
                        backgroundColor: MyColor.neutral100,
                        padding: EdgeInsets.all(Dimensions.space10),
                        child: Icon(
                          Icons.add,
                          size: Dimensions.space40,
                          color: MyColor.getHeadingTextColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.space40),
                RoundedButton(
                  text: MyStrings.done.toTitleCase(),
                  press: () {
                    Get.back();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
