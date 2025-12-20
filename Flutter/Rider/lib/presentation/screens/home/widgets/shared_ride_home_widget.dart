import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/ride/shared_ride_screen.dart';

class SharedRideHomeWidget extends StatelessWidget {
  const SharedRideHomeWidget({super.key});

  @override
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/shared_ride_active_screen.dart';

class SharedRideHomeWidget extends StatelessWidget {
  const SharedRideHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SharedRideController>(
      builder: (controller) {
        bool hasActived = controller.currentRide != null;
        
        return Container(
           margin: EdgeInsets.symmetric(vertical: Dimensions.space10),
           padding: EdgeInsets.all(Dimensions.space15),
           decoration: BoxDecoration(
             color: MyColor.getCardBgColor(),
             borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
             boxShadow: MyColor.getCardShadow(),
             border: Border.all(color: MyColor.primaryColor.withOpacity(0.3), width: 1)
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               if (!hasActived) ...[
                 Row(
                   children: [
                     Icon(Icons.directions_car_filled_outlined, color: MyColor.primaryColor),
                     SizedBox(width: 10),
                     Text("Shared Rides (2 Riders)", style: boldDefault),
                   ],
                 ),
                 spaceDown(10),
                 InkWell(
                   onTap: () => Get.to(() => const SharedRideScreen()),
                   child: Container(
                     width: double.infinity,
                     padding: EdgeInsets.symmetric(vertical: 12),
                     decoration: BoxDecoration(color: MyColor.primaryColor, borderRadius: BorderRadius.circular(8)),
                     child: Center(child: Text("Find / Create Shared Ride", style: boldDefault.copyWith(color: Colors.white))),
                   ),
                 )
               ] else ...[
                 // Active/Pending Ride Card
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text("Your Shared Ride", style: boldLarge.copyWith(color: MyColor.primaryColor)),
                     Container(
                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: MyColor.greenP, borderRadius: BorderRadius.circular(4)),
                       child: Text("Active", style: regularSmall.copyWith(color: Colors.white)),
                     )
                   ],
                 ),
                 spaceDown(10),
                 // Map Preview
                 if (controller.currentRide?.pickupLat != null)
                   SharedRideMapWidget(
                      startLat1: controller.currentRide!.pickupLat!, 
                      startLng1: controller.currentRide!.pickupLng!, 
                      endLat1: controller.currentRide!.destLat!, 
                      endLng1: controller.currentRide!.destLng!, 
                      // For pending ride, R2 might be null. Show what we have.
                      // If R1 is me, R2 is unknown.
                      // Map Widget expects 4 points. We can duplicate or hide R2.
                      // Let's just show single route if solo.
                      startLat2: controller.currentRide!.pickupLat!, 
                      startLng2: controller.currentRide!.pickupLng!, 
                      endLat2: controller.currentRide!.destLat!, 
                      endLng2: controller.currentRide!.destLng! 
                   ),
                 spaceDown(10),
                 Text("${controller.currentRide?.pickupLocation} -> ${controller.currentRide?.destination}", maxLines: 1),
                 spaceDown(10),
                 InkWell(
                   onTap: () => Get.to(() => SharedRideActiveScreen(rideId: controller.currentRide!.id.toString())),
                   child: Text("View Details >", style: boldDefault.copyWith(color: MyColor.primaryColor)),
                 )
               ]
             ],
           ),
        );
      }
    );
  }
}
