import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shuttle_controller.dart';
import 'package:ovorideuser/data/model/shuttle/shuttle_route_model.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';

class ShuttleRouteCard extends StatelessWidget {
  final ShuttleMatch match;
  final ShuttleController controller;
  final int index;

  const ShuttleRouteCard({
    super.key,
    required this.match,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.selectMatch(match);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Dimensions.space10),
        padding: EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: controller.selectedMatch?.route?.id == match.route?.id && controller.selectedMatch?.startStop?.id == match.startStop?.id
              ? MyColor.primaryColor.withValues(alpha: 0.1)
              : MyColor.colorWhite,
          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          border: Border.all(
            color: controller.selectedMatch?.route?.id == match.route?.id && controller.selectedMatch?.startStop?.id == match.startStop?.id
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
                    match.route?.name ?? '',
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
                    match.route?.code ?? '',
                    style: regularSmall.copyWith(color: MyColor.primaryColor),
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space10),
            Row(
              children: [
                Icon(Icons.access_time, color: MyColor.primaryColor, size: 20),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Text(
                    match.nextSchedule != null 
                        ? "Next: ${match.nextSchedule}"
                        : "No Schedule",
                    style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space10),
            Row(
              children: [
                Icon(Icons.directions_bus, color: MyColor.primaryColor, size: 20),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Text(
                    "From: ${match.startStop?.name}",
                    style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            spaceDown(Dimensions.space5),
            Row(
              children: [
                Icon(Icons.location_on, color: MyColor.redCancelTextColor, size: 20),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Text(
                    "To: ${match.endStop?.name}",
                  style: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                    overflow: TextOverflow.ellipsis,
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
