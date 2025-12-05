import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/coupon/coupon_controller.dart';
import 'package:ovorideuser/data/repo/coupon/coupon_repo.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';
import 'package:ovorideuser/presentation/screens/coupon/widget/coupon_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  @override
  void initState() {
    Get.put(CouponRepo(apiClient: Get.find()));
    Get.put(CouponController(couponRepo: Get.find(), rideId: Get.arguments));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(title: MyStrings.applyCoupon),
      body: GetBuilder<CouponController>(
        builder: (controller) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: Dimensions.screenPaddingHV,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space15 + 1,
                    vertical: Dimensions.space25 - 1,
                  ),
                  decoration: BoxDecoration(
                    color: MyColor.colorWhite,
                    borderRadius: BorderRadius.circular(
                      Dimensions.mediumRadius,
                    ),
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        onChanged: (val) {},
                        radius: Dimensions.mediumRadius,
                        hintText: MyStrings.enterCouponCode,
                        controller: controller.applyTextController,
                      ),
                      const SizedBox(height: Dimensions.space25 - 1),
                      RoundedButton(
                        text: MyStrings.apply,
                        isLoading: controller.isApplyLoading,
                        press: () {
                          if (controller.applyTextController.text.isNotEmpty) {
                            controller.apply();
                          } else {
                            CustomSnackBar.error(
                              errorList: [MyStrings.enterCouponCode.tr],
                            );
                          }
                        },
                        bgColor: MyColor.colorBlack,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.space20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space15 + 1,
                    vertical: Dimensions.space25 - 1,
                  ),
                  decoration: BoxDecoration(
                    color: MyColor.colorWhite,
                    borderRadius: BorderRadius.circular(
                      Dimensions.mediumRadius,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(MyStrings.selectCoupon.tr, style: boldExtraLarge),
                      const SizedBox(height: Dimensions.space12),
                      Column(
                        children: List.generate(
                          controller.couponList.length,
                          (index) => MyCouponCard(
                            isApplied: controller.couponList[index].code.toString() == controller.selectedCoupon.code.toString(),
                            coupon: controller.couponList[index],
                            currencySym: controller.defaultCurrencySymbol,
                            apply: () {
                              controller.applyCoupon(
                                controller.couponList[index],
                              );
                            },
                            remove: () {
                              if (controller.isRemoveLoading) return;
                              controller.removeCoupon(
                                controller.selectedCoupon,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
