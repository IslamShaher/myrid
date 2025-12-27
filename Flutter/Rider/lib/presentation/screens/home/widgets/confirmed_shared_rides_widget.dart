import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/confirmed_shared_ride_card.dart';

class ConfirmedSharedRidesWidget extends StatelessWidget {
  const ConfirmedSharedRidesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SharedRideController>(
      builder: (controller) {
        if (controller.isLoadingConfirmedRides) {
          return Container(
            padding: EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: MyColor.getCardBgColor(),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              boxShadow: MyColor.getCardShadow(),
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (controller.confirmedRides.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirmed Shared Rides",
              style: boldLarge.copyWith(color: MyColor.getHeadingTextColor()),
            ),
            spaceDown(Dimensions.space10),
            ...controller.confirmedRides.map((ride) {
              return ConfirmedSharedRideCard(ride: ride);
            }).toList(),
          ],
        );
      },
    );
  }
}

