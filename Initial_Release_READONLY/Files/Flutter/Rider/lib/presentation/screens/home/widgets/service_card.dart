import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/url_container.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/model/global/app/app_service_model.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/my_network_image_widget.dart';
import 'package:get/get.dart';

class ServiceCard extends StatelessWidget {
  final AppService service;
  final HomeController controller;
  const ServiceCard({
    super.key,
    required this.service,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        margin: EdgeInsets.only(bottom: Dimensions.space10),
        padding: EdgeInsets.symmetric(horizontal: Dimensions.space5, vertical: Dimensions.space5),
        decoration: BoxDecoration(
          color: service.id == controller.selectedService.id ? MyColor.primaryColor.withValues(alpha: 0.1) : MyColor.neutral50,
          borderRadius: BorderRadius.circular(16),
          border: service.id == controller.selectedService.id ? Border.all(color: MyColor.primaryColor, width: 1.5) : Border.all(color: MyColor.neutral200, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                Dimensions.space8,
              ),
              decoration: BoxDecoration(
                color: service.id == controller.selectedService.id ? MyColor.primaryColor.withValues(alpha: 0.1) : MyColor.neutral50,
                borderRadius: BorderRadius.circular(Dimensions.largeRadius),
                border: service.id == controller.selectedService.id ? Border.all(color: MyColor.primaryColor, width: 1.5) : Border.all(color: MyColor.neutral200, width: 1.2),
              ),
              child: MyImageWidget(
                imageUrl: '${UrlContainer.domainUrl}/${controller.serviceImagePath}/${service.image}',
                height: Dimensions.space50,
                width: Dimensions.space50,
                radius: Dimensions.largeRadius,
              ),
            ),
            Expanded(
                child: Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: Dimensions.space10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (service.name ?? '').tr,
                          style: boldMediumLarge.copyWith(
                            color: MyColor.getHeadingTextColor(),
                          ),
                        ),
                        spaceDown(Dimensions.space2),
                        Text(
                          (service.subTitle ?? '').tr,
                          style: regularMediumLarge.copyWith(
                            fontSize: Dimensions.fontMedium,
                            color: MyColor.bodyMutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  spaceSide(Dimensions.space10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axis: Axis.horizontal,
                            child: child,
                          ),
                        );
                      },
                      child: service.recommendAmount == null
                          ? Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  textAlign: TextAlign.end,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${controller.homeRepo.apiClient.getCurrency(isSymbol: true)}${service.recommendAmount ?? service.cityRecommendFare ?? ""}",
                                        style: boldMediumLarge.copyWith(color: MyColor.getPrimaryColor(), fontWeight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: "/${MyUtils.getDistanceLabel(unit: controller.homeRepo.apiClient.getDistanceUnit())}",
                                        style: regularSmall.copyWith(color: MyColor.getBodyTextColor()),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${controller.homeRepo.apiClient.getCurrency(isSymbol: true)}${service.recommendAmount ?? service.cityRecommendFare ?? ""}",
                                    style: boldMediumLarge.copyWith(color: MyColor.getPrimaryColor(), fontWeight: FontWeight.w700),
                                  ),
                                ),
                                spaceDown(Dimensions.space5),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "${controller.distance.toPrecision(2)} ${MyUtils.getDistanceLabel(distance: controller.distance.toString(), unit: controller.homeRepo.apiClient.getDistanceUnit())}",
                                    style: regularSmall.copyWith(color: MyColor.getTextColor()),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ))
          ],
        ),
      ),
    );
  }
}
