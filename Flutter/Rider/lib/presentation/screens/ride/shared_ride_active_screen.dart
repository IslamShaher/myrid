import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class SharedRideActiveScreen extends StatefulWidget {
  final String rideId;
  const SharedRideActiveScreen({super.key, required this.rideId});

  @override
  State<SharedRideActiveScreen> createState() => _SharedRideActiveScreenState();
}

class _SharedRideActiveScreenState extends State<SharedRideActiveScreen> {
  
  @override
  void initState() {
    super.initState();
    // Fetch ride details if not available
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Active Shared Ride"),
      body: GetBuilder<SharedRideController>(
        builder: (controller) {
          // Mock data or use controller's current ride
          // We assume controller has the ride details loaded or we fetch it.
          // For now, let's use a placeholder logic for buttons based on role.
          
          bool isRider1 = true; // TODO: Check auth user id vs ride.user_id
          bool isRider2 = false;
          
          String status = "active"; // ride.status
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.space15),
            child: Column(
              children: [
                // Info Card
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(color: MyColor.getCardBgColor(), borderRadius: BorderRadius.circular(Dimensions.mediumRadius)),
                  child: Column(
                    children: [
                      Text("Ride #${widget.rideId}", style: boldLarge),
                      spaceDown(10),
                      Text("Status: $status"),
                    ],
                  ),
                ),
                spaceDown(20),
                
                // Ride Guide Button (Rider 1)
                if(isRider1)
                  RoundedButton(
                    text: "Ride Details (Route Guide)",
                    press: () {
                      // Open Route Guide Screen
                      Get.dialog(AlertDialog(
                        title: Text("Route Guide"),
                        content: Text("1. Pickup You\n2. Pickup Rider 2\n3. Dropoff You\n4. Dropoff Rider 2\n\n(Enter this order in Uber/Careem)"),
                        actions: [TextButton(onPressed: ()=>Get.back(), child: Text("Close"))],
                      ));
                    },
                    color: MyColor.secondaryColor,
                  ),
                spaceDown(10),
                
                // Active Flow Buttons
                if (isRider1 && status == 'active')
                  RoundedButton(
                    text: "I Started Driving",
                    press: () {
                      controller.sharedRideRepo.updateRideStatus(rideId: widget.rideId, action: 'start_driving');
                    },
                  ),
                  
                if (isRider1) 
                  RoundedButton(
                    text: "I Arrived at Rider 2",
                    press: () {
                      controller.sharedRideRepo.updateRideStatus(rideId: widget.rideId, action: 'arrived_at_pickup');
                      // Start timer locally?
                    },
                  ),
                
                if (isRider2)
                   RoundedButton(
                    text: "Confirm Pickup",
                    press: () {
                      controller.sharedRideRepo.updateRideStatus(rideId: widget.rideId, action: 'confirm_pickup');
                    },
                  ),

                spaceDown(20),
                RoundedButton(
                  text: "Upload Fare Screenshot",
                  press: () {
                     // Image Picker logic
                  },
                  color: Colors.blueGrey,
                  textColor: Colors.white,
                ),

                spaceDown(20),
                RoundedButton(
                  text: "Chat with Rider",
                  press: () {
                    // Navigate to Message Screen
                    // Get.toNamed(RouteHelper.messageScreen, arguments: widget.rideId);
                  },
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
