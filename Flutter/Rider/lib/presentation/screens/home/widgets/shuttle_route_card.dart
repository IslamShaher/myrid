import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shuttle_controller.dart';
import 'package:ovorideuser/data/model/shuttle/shuttle_route_model.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';

class ShuttleRouteCard extends StatelessWidget {
  final MatchedRoute route;
  final ShuttleController controller;
  final int index;

  const ShuttleRouteCard({
    super.key,
    required this.route,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.selectRoute(route);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Dimensions.space10),
        padding: EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: controller.selectedRoute?.id == route.id
              ? MyColor.primaryColor.withValues(alpha: 0.1)
              : MyColor.colorWhite,
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          border: Border.all(
            color: controller.selectedRoute?.id == route.id
                ? MyColor.primaryColor
                : MyColor.borderColor,
            width: 1,
          ),
          boxShadow: MyUtils.getCardShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    route.name ?? '',
                    style: boldMediumLarge.copyWith(color: MyColor.getTextColor()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.space10, vertical: Dimensions.space5),
                  decoration: BoxDecoration(
                    color: MyColor.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Text(
                    route.code ?? '',
                    style: regularSmall.copyWith(color: MyColor.primaryColor),
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space10),
            Row(
              children: [
                Icon(Icons.directions_bus, color: MyColor.primaryColor, size: 20),
                spaceSide(Dimensions.space10),
                Text(
                  "${route.stops?.length ?? 0} Stops",
                  style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyUtils {
  static List<BoxShadow> getCardShadow() {
    return [
      BoxShadow(
        color: MyColor.getShadowColor().withValues(alpha: 0.05),
        spreadRadius: 1,
        blurRadius: 10,
        offset: const Offset(0, 1),
      ),
    ];
  }
}
