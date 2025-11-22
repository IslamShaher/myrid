import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:ovorideuser/presentation/components/text/header_text.dart';

class HomeScreenAppBar extends StatelessWidget {
  HomeController controller;
  Function openDrawer;
  HomeScreenAppBar({
    super.key,
    required this.controller,
    required this.openDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Dimensions.space16, vertical: Dimensions.space16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(RouteHelper.profileScreen);
                        },
                        child: MyImageWidget(
                          imageUrl: '${UrlContainer.domainUrl}/${controller.userImagePath}/${controller.user.image}',
                          height: 50,
                          width: 50,
                          radius: 50,
                          isProfile: true,
                        ),
                      ),
                      spaceSide(Dimensions.space10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: HeaderText(
                                text: controller.user.id == '-1' ? controller.homeRepo.apiClient.getUserName().toTitleCase() : controller.user.getFullName(),
                                style: boldLarge.copyWith(
                                  color: MyColor.getTextColor(),
                                  fontSize: Dimensions.fontLarge,
                                ),
                              ),
                            ),
                            spaceDown(Dimensions.space3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomSvgPicture(
                                  image: MyIcons.currentLocation,
                                  color: MyColor.primaryColor,
                                ),
                                spaceSide(Dimensions.space5),
                                Expanded(
                                  child: Text(
                                    controller.appLocationController.currentAddress,
                                    style: regularDefault.copyWith(
                                      color: MyColor.getBodyTextColor(),
                                      fontSize: Dimensions.fontDefault,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            spaceDown(Dimensions.space2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Dimensions.space30),
                InkWell(
                  onTap: () => openDrawer(),
                  splashFactory: NoSplash.splashFactory,
                  splashColor: MyColor.transparentColor,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: MyColor.cardBgColor,
                      border: Border.all(color: MyColor.naturalTextColor),
                      borderRadius: BorderRadius.circular(
                        Dimensions.largeRadius,
                      ),
                    ),
                    child: SvgPicture.asset(MyIcons.sideMenu),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
