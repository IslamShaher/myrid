import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/controller/account/profile_complete_controller.dart';
import 'package:ovorideuser/data/repo/account/profile_repo.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/text-form-field/custom_text_field.dart';
import 'package:ovorideuser/presentation/components/will_pop_widget.dart';
import 'package:ovorideuser/presentation/screens/auth/auth_background.dart';
import 'package:ovorideuser/presentation/screens/auth/registration/widget/country_bottom_sheet.dart';

class ProfileCompleteScreen extends StatefulWidget {
  const ProfileCompleteScreen({super.key});

  @override
  State<ProfileCompleteScreen> createState() => _ProfileCompleteScreenState();
}

class _ProfileCompleteScreenState extends State<ProfileCompleteScreen> {
  @override
  void initState() {
    Get.put(ProfileRepo(apiClient: Get.find()));
    final controller = Get.put(
      ProfileCompleteController(profileRepo: Get.find()),
    );
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      nextRoute: '',
      child: AnnotatedRegionWidget(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: MyColor.colorWhite,
          body: GetBuilder<ProfileCompleteController>(
            builder: (controller) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthBackgroundWidget(
                    colors: [MyColor.colorWhite.withValues(alpha: 0.9), MyColor.colorWhite.withValues(alpha: 0.8)],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(end: Dimensions.space5),
                            child: IconButton(
                              onPressed: () {
                                Get.offAllNamed(RouteHelper.loginScreen);
                              },
                              icon: Icon(
                                Icons.close,
                                size: Dimensions.space30,
                                color: MyColor.getHeadingTextColor(),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Dimensions.space20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                MyStrings.profileCompleteTitle.tr,
                                style: boldExtraLarge.copyWith(
                                  fontSize: 32,
                                  color: MyColor.getHeadingTextColor(),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              spaceDown(Dimensions.space5),
                              Text(
                                MyStrings.profileCompleteSubTitle.tr,
                                style: regularDefault.copyWith(
                                  color: MyColor.getBodyTextColor(),
                                  fontSize: Dimensions.fontLarge,
                                ),
                              ),
                              spaceDown(Dimensions.space40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -Dimensions.space20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: MyColor.colorWhite,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(Dimensions.radius25),
                          topRight: Radius.circular(Dimensions.radius25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: MyColor.colorBlack.withValues(alpha: 0.05), // soft top shadow
                            offset: const Offset(0, -30), // ⬆️ Shadow goes up
                            blurRadius: 15,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.symmetric(horizontal: Dimensions.space20, vertical: Dimensions.space20),
                      child: controller.isLoading
                          ? const CustomLoader()
                          : Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    labelText: MyStrings.username.tr,
                                    hintText: "${MyStrings.enterYour.tr} ${MyStrings.username.toLowerCase().tr}",
                                    textInputType: TextInputType.text,
                                    inputAction: TextInputAction.next,
                                    focusNode: controller.userNameFocusNode,
                                    controller: controller.userNameController,
                                    nextFocus: controller.mobileNoFocusNode,
                                    onChanged: (value) {
                                      return;
                                    },
                                    validator: (value) {
                                      if (value != null && value.isEmpty) {
                                        return MyStrings.enterYourUsername.tr;
                                      } else if (value.length < 6) {
                                        return MyStrings.kShortUserNameError;
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                    height: Dimensions.space20,
                                  ),
                                  CustomTextField(
                                    labelText: MyStrings.phone.tr,
                                    hintText: "XXX-XXX-XXXX",
                                    textInputType: TextInputType.number,
                                    inputAction: TextInputAction.next,
                                    focusNode: controller.countryFocusNode,
                                    controller: controller.mobileNoController,
                                    nextFocus: controller.addressFocusNode,
                                    prefixIcon: IntrinsicWidth(
                                      child: Padding(
                                        padding: EdgeInsetsGeometry.symmetric(horizontal: Dimensions.space10),
                                        child: GestureDetector(
                                          onTap: () {
                                            CountryBottomSheet.profileBottomSheet(
                                              context,
                                              controller,
                                            );
                                          },
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              spaceSide(
                                                Dimensions.space3,
                                              ),
                                              MyImageWidget(
                                                imageUrl: UrlContainer.countryFlagImageLink.replaceAll(
                                                  "{countryCode}",
                                                  controller.selectedCountryData.countryCode.toString().toLowerCase(),
                                                ),
                                                height: Dimensions.space25,
                                                width: Dimensions.space40,
                                              ),
                                              spaceSide(
                                                Dimensions.space5,
                                              ),
                                              Text(
                                                "+${controller.selectedCountryData.dialCode}",
                                                style: regularMediumLarge.copyWith(
                                                  fontSize: Dimensions.fontOverLarge,
                                                ),
                                              ),
                                              Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: MyColor.getBodyTextColor(),
                                              ),
                                              spaceSide(Dimensions.space2),
                                              Container(
                                                color: MyColor.naturalTextColor,
                                                width: 1,
                                                height: Dimensions.space30,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      return;
                                    },
                                    validator: (value) {
                                      if (value != null && value.isEmpty) {
                                        return MyStrings.enterYourPhoneNumber.tr;
                                      } else {
                                        return null;
                                      }
                                    },
                                  ),
                                  const SizedBox(
                                    height: Dimensions.space20,
                                  ),
                                  CustomTextField(
                                    labelText: MyStrings.address.tr,
                                    hintText: "${MyStrings.enterYour.tr} ${MyStrings.address.toLowerCase().tr}",
                                    textInputType: TextInputType.text,
                                    inputAction: TextInputAction.next,
                                    focusNode: controller.addressFocusNode,
                                    controller: controller.addressController,
                                    nextFocus: controller.stateFocusNode,
                                    onChanged: (value) {
                                      return;
                                    },
                                  ),
                                  const SizedBox(
                                    height: Dimensions.space20,
                                  ),
                                  CustomTextField(
                                    labelText: MyStrings.state,
                                    hintText: "${MyStrings.enterYour.tr} ${MyStrings.state.toLowerCase().tr}",
                                    textInputType: TextInputType.text,
                                    inputAction: TextInputAction.next,
                                    focusNode: controller.stateFocusNode,
                                    controller: controller.stateController,
                                    nextFocus: controller.cityFocusNode,
                                    onChanged: (value) {
                                      return;
                                    },
                                  ),
                                  const SizedBox(
                                    height: Dimensions.space20,
                                  ),
                                  CustomTextField(
                                    labelText: MyStrings.city.tr,
                                    hintText: "${MyStrings.enterYour.tr} ${MyStrings.city.toLowerCase().tr}",
                                    textInputType: TextInputType.text,
                                    inputAction: TextInputAction.next,
                                    focusNode: controller.cityFocusNode,
                                    controller: controller.cityController,
                                    nextFocus: controller.zipCodeFocusNode,
                                    onChanged: (value) {
                                      return;
                                    },
                                  ),
                                  const SizedBox(
                                    height: Dimensions.space20,
                                  ),
                                  CustomTextField(
                                    labelText: MyStrings.zipCode.tr,
                                    hintText: "${MyStrings.enterYour.tr} ${MyStrings.zipCode.toLowerCase().tr}",
                                    textInputType: TextInputType.text,
                                    inputAction: TextInputAction.done,
                                    focusNode: controller.zipCodeFocusNode,
                                    controller: controller.zipCodeController,
                                    onChanged: (value) {
                                      return;
                                    },
                                  ),
                                  // if (controller.loginType == "google") ...[
                                  //   const SizedBox(
                                  //     height: Dimensions.space20,
                                  //   ),
                                  //   CustomTextField(
                                  //     labelText: MyStrings.referanceName,
                                  //     hintText: MyStrings.referanceName.tr,
                                  //     textInputType: TextInputType.text,
                                  //     inputAction: TextInputAction.next,
                                  //     controller: controller.referController,
                                  //     nextFocus: controller.addressFocusNode,
                                  //     onChanged: (value) {
                                  //       return;
                                  //     },
                                  //   ),
                                  // ],
                                  const SizedBox(
                                    height: Dimensions.space35,
                                  ),
                                  RoundedButton(
                                    isLoading: controller.submitLoading,
                                    text: MyStrings.completeProfile.tr,
                                    press: () {
                                      if (formKey.currentState!.validate()) {
                                        controller.updateProfile();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(
                    height: Dimensions.space35,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
