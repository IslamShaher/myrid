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
  Widget build(BuildContext context) {
    // This widget should check if there is an active shared ride.
    // For now, let's just make it a button to "Find Shared Ride" 
    // AND if controller has active ride, show status.
    
    // We need to inject SharedRideController somewhere globally or access it here.
    // Let's assume it's put in home screen.
    
    return GetBuilder<SharedRideController>(
      builder: (controller) {
        // If has active ride (mocked check for now, or check controller state)
        bool hasActiveRide = false; // controller.hasActiveRide; 
        
        return Container(
           margin: EdgeInsets.symmetric(vertical: Dimensions.space10),
           padding: EdgeInsets.all(Dimensions.space15),
           decoration: BoxDecoration(
             color: MyColor.primaryColor.withOpacity(0.1),
             borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
             border: Border.all(color: MyColor.primaryColor, width: 0.5)
           ),
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Row(
                 children: [
                   Icon(Icons.people_outline, color: MyColor.primaryColor),
                   SizedBox(width: 10),
                   Expanded(
                     child: Text(
                       hasActiveRide ? "Active Shared Ride" : "Shared Rides (2 Riders)",
                       style: boldDefault.copyWith(color: MyColor.primaryColor),
                     ),
                   ),
                   if(hasActiveRide)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: MyColor.greenP, borderRadius: BorderRadius.circular(4)),
                        child: Text("Active", style: regularSmall.copyWith(color: Colors.white)),
                      )
                 ],
               ),
               spaceDown(Dimensions.space10),
               if (!hasActiveRide)
                 InkWell(
                   onTap: () {
                     Get.to(() => const SharedRideScreen());
                   },
                   child: Container(
                     width: double.infinity,
                     padding: EdgeInsets.symmetric(vertical: 10),
                     decoration: BoxDecoration(
                       color: MyColor.primaryColor,
                       borderRadius: BorderRadius.circular(8)
                     ),
                     child: Center(child: Text("Find / Create Shared Ride", style: boldDefault.copyWith(color: Colors.white))),
                   ),
                 )
               else
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("Your ride is scheduled/active.", style: regularDefault),
                     spaceDown(5),
                     Text("Rider 2: Waiting/Joined", style: regularSmall),
                     spaceDown(10),
                     InkWell(
                       onTap: () {
                           // Go to active ride details
                           // Get.to(() => SharedRideActiveScreen()); // TODO
                       },
                       child: Text("View Details >", style: boldDefault.copyWith(color: MyColor.primaryColor)),
                     )
                   ],
                 )
             ],
           ),
        );
      }
    );
  }
}
