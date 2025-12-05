import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/presentation/components/bottom-sheet/bottom_sheet_header_row.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';

class RideCancelBottomSheetBody extends StatelessWidget {
  const RideCancelBottomSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideDetailsController>(
      builder: (controller) {
        return Column(
          children: [
            const BottomSheetHeaderRow(),
            const SizedBox(height: Dimensions.space10),
            CustomTextField(
              fillColor: MyColor.colorGrey.withValues(alpha: 0.1),
              hintText: MyStrings.cancelationReason.tr,
              labelText: MyStrings.cancelReason.tr,
              maxLines: 6,
              controller: controller.cancelReasonController,
              onChanged: (c) {},
            ),
            const SizedBox(height: Dimensions.space20),
            const SizedBox(height: Dimensions.space20),
            RoundedButton(
              text: MyStrings.submit,
              isLoading: controller.isCancelLoading,
              press: () {
                if (controller.cancelReasonController.text.isNotEmpty) {
                  controller.cancelRide();
                } else {
                  CustomSnackBar.error(errorList: [MyStrings.rideCancelMsg.tr]);
                }
              },
            ),
            const SizedBox(height: Dimensions.space10),
          ],
        );
      },
    );
  }
}
