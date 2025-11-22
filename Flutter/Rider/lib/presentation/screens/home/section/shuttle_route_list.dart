import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shuttle_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/shuttle_route_card.dart';

class ShuttleRouteList extends StatelessWidget {
  const ShuttleRouteList({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShuttleController>(
      builder: (controller) {
        if (controller.isLoading) {
          return Center(child: CircularProgressIndicator(color: MyColor.primaryColor));
        }

        if (controller.shuttleRouteModel == null ||
            (controller.shuttleRouteModel?.matchedRoutes?.isEmpty ?? true)) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(Dimensions.space20),
            decoration: BoxDecoration(
              color: MyColor.getCardBgColor(),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
            ),
            child: Column(
              children: [
                Icon(Icons.directions_bus_outlined, size: 50, color: MyColor.bodyMutedTextColor),
                spaceDown(Dimensions.space10),
                Text(
                  "No shuttle routes found for this trip.",
                  style: regularDefault.copyWith(color: MyColor.bodyMutedTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(Dimensions.space15),
          decoration: BoxDecoration(
            color: MyColor.getCardBgColor(),
            borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Available Shuttle Routes",
                style: boldLarge.copyWith(color: MyColor.getTextColor()),
              ),
              spaceDown(Dimensions.space15),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.shuttleRouteModel?.matchedRoutes?.length ?? 0,
                itemBuilder: (context, index) {
                  return ShuttleRouteCard(
                    route: controller.shuttleRouteModel!.matchedRoutes![index],
                    controller: controller,
                    index: index,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
