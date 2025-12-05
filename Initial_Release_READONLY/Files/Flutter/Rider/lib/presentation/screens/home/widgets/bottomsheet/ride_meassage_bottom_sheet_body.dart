import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/my_bottom_sheet_bar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';

class RideMassageBottomSheet extends StatelessWidget {
  const RideMassageBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return AnimatedContainer(
          duration: const Duration(microseconds: 300),
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
                MyStrings.additionalInformation.tr,
                style: boldExtraLarge.copyWith(),
              ),
              const SizedBox(height: Dimensions.space30),
              CustomTextField(
                onChanged: (val) {},
                controller: controller.noteController,
                hintText: MyStrings.additionalInformationHint.tr,
                radius: Dimensions.mediumRadius,
                maxLines: 4,
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
        );
      },
    );
  }
}
