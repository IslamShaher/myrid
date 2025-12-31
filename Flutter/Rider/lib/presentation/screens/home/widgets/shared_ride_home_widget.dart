
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/ride/shared_ride_unified_screen.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';

class SharedRideHomeWidget extends StatelessWidget {
  const SharedRideHomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SharedRideController>(
      builder: (controller) {
        if (!Get.isRegistered<SharedRideController>()) {
           return const SizedBox.shrink();
        }
        final ride = controller.currentRide;
        bool hasActived = ride != null;
        
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
                     const SizedBox(width: 10),
                     Text("Shared Rides (2 Riders)", style: boldDefault),
                   ],
                 ),
                 spaceDown(10),
                 InkWell(
                   onTap: () => Get.to(() => const SharedRideUnifiedScreen()),
                   child: Container(
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(vertical: 12),
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
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(color: MyColor.greenP, borderRadius: BorderRadius.circular(4)),
                       child: Text("Active", style: regularSmall.copyWith(color: Colors.white)),
                     )
                   ],
                 ),
                 spaceDown(10),
                 // Map Preview - Show ALL 4 points if second user coordinates exist
                 if (ride.pickupLat != null && ride.pickupLng != null)
                   SharedRideMapWidget(
                      startLat1: ride.pickupLat ?? 0, 
                      startLng1: ride.pickupLng ?? 0, 
                      endLat1: ride.destLat ?? 0, 
                      endLng1: ride.destLng ?? 0, 
                      startLat2: ride.secondPickupLat ?? ride.pickupLat ?? 0, 
                      startLng2: ride.secondPickupLng ?? ride.pickupLng ?? 0, 
                      endLat2: ride.secondDestLat ?? ride.destLat ?? 0, 
                      endLng2: ride.secondDestLng ?? ride.destLng ?? 0,
                      sequence: ride.sharedRideSequence,
                      directionsData: null,
                   ),
                 spaceDown(10),
                 Text("${ride.pickupLocation ?? ''} -> ${ride.destination ?? ''}", maxLines: 1),
                 spaceDown(10),
                 InkWell(
                   onTap: () {
                     if (ride.id != null) {
                       Get.to(() => SharedRideUnifiedScreen(rideId: ride.id.toString()));
                     }
                   },
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
