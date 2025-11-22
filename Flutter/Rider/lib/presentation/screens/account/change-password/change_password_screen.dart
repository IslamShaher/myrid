import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/card/app_body_card.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/account/change_password_controller.dart';
import 'package:ovorideuser/data/repo/account/change_password_repo.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';
import 'package:ovorideuser/presentation/screens/account/change-password/widget/change_password_form.dart';

import '../../../../core/utils/dimensions.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  @override
  void initState() {
    Get.put(ChangePasswordRepo(apiClient: Get.find()));
    Get.put(ChangePasswordController(changePasswordRepo: Get.find()));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ChangePasswordController>().clearData();
    });
  }

  @override
  void dispose() {
    Get.find<ChangePasswordController>().clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      child: Scaffold(
        backgroundColor: MyColor.secondaryScreenBgColor,
        appBar: CustomAppBar(
          title: MyStrings.changePassword.tr,
          isShowBackBtn: true,
        ),
        body: GetBuilder<ChangePasswordController>(
          builder: (controller) {
            return SingleChildScrollView(
              padding: Dimensions.screenPaddingHV,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: Dimensions.space15),
                    child: AppBodyWidgetCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              MyStrings.changePassword.tr,
                              style: boldDefault.copyWith(
                                color: MyColor.getHeadingTextColor(),
                                fontSize: Dimensions.fontOverLarge22,
                              ),
                            ),
                          ),
                          spaceDown(Dimensions.space10),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              MyStrings.createPasswordSubText.tr,
                              textAlign: TextAlign.center,
                              style: regularDefault.copyWith(
                                color: MyColor.getBodyTextColor(),
                              ),
                            ),
                          ),
                          spaceDown(Dimensions.space30),
                          const ChangePasswordForm(),
                        ],
                      ),
                    ),
                  ),
                  spaceDown(Dimensions.space30),
                  InkWell(
                    onTap: () {
                      Get.toNamed(RouteHelper.forgotPasswordScreen);
                    },
                    child: HeaderText(
                      text: MyStrings.forgotPassword.tr,
                      style: mediumMediumLarge.copyWith(color: MyColor.redCancelTextColor, fontSize: Dimensions.fontExtraLarge),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
