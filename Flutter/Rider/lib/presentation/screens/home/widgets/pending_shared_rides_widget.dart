import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:intl/intl.dart';

class PendingSharedRidesWidget extends StatelessWidget {
  const PendingSharedRidesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SharedRideController>(
      builder: (controller) {
        if (controller.isLoadingPendingRides) {
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

        if (controller.pendingRides.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pending Shared Rides",
              style: boldLarge.copyWith(color: MyColor.getHeadingTextColor()),
            ),
            spaceDown(Dimensions.space10),
            ...controller.pendingRides.map((ride) {
              return Container(
                margin: EdgeInsets.only(bottom: Dimensions.space10),
                padding: EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.getCardBgColor(),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  boxShadow: MyColor.getCardShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: MyColor.getPrimaryColor()),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Ride #${ride['uid'] ?? ride['id']}",
                            style: boldDefault,
                          ),
                        ),
                      ],
                    ),
                    spaceDown(Dimensions.space10),
                    Text(
                      "${ride['pickup_location'] ?? ''} → ${ride['destination'] ?? ''}",
                      style: regularDefault,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ride['is_scheduled'] == true && ride['scheduled_time'] != null) ...[
                      spaceDown(Dimensions.space8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: MyColor.neutral700),
                          SizedBox(width: 4),
                          Text(
                            "Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(ride['scheduled_time']))}",
                            style: regularSmall.copyWith(color: MyColor.neutral700),
                          ),
                        ],
                      ),
                    ],
                    spaceDown(Dimensions.space8),
                    Text(
                      "Waiting for a match...",
                      style: regularSmall.copyWith(
                        color: MyColor.getPrimaryColor(),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

