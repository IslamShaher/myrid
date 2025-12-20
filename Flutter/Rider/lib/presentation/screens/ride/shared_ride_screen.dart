import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_route_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/location_pickup_widget.dart'; // Reusing location picker widgets if possible
// Or create a simple UI for inputs

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  // Controllers moved to SharedRideController
  
  // In a real app, we would use the LocationPickerScreen result.
  // For now, I'll simulate or use a simple form to call the controller.
  // Or better, reuse the "LocationPickUpHomeWidget" style but for this screen.
  
  // Let's assume we navigate here with picked locations OR pick them here.
  // The user requirement: "1- rider 1 enters start and end -> find matches"
  
  @override
  void initState() {
    Get.put(SharedRideController(sharedRideRepo: Get.find())); // Ensure controller is loaded
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(title: "Shared Ride"),
      body: GetBuilder<SharedRideController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.space15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(Dimensions.space15),
                  decoration: BoxDecoration(
                    color: MyColor.getCardBgColor(),
                    borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                    boxShadow: MyColor.getCardShadow(),
                  ),
                  child: Column(
                    children: [
                      Text("Find a Shared Ride Partner", style: boldLarge),
                      spaceDown(Dimensions.space15),
                      // Inputs
                      // For prototype speed, I am adding direct text fields for lat/lng
                      // BUT ideally this should open the Map Picker.
                      // Let's use a placeholder button "Pick Locations"
                      RoundedButton(
                        text: "Select Trip Route",
                        press: () {
                           // Logic to open LocationPicker and get result
                           // This requires hooking into existing LocationPicker logic
                           // checking location_picker_screen.dart
                        },
                      ),
                      // Temporary Manual Input for testing
                      spaceDown(Dimensions.space10),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.grey.withOpacity(0.1),
                            padding: const EdgeInsets.all(10),
                            child: const Text("Location Picker Integration Required\nUsing fixed coordinates for test? Or add map integration."),
                          ),
                      ),
                    ],
                  ),
                ),
                spaceDown(Dimensions.space20),
                
                if (controller.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (controller.searched && controller.matches.isEmpty)
                   Center(child: Text("No existing rides found. Creating new...", style: regularDefault))
                else 
                   ListView.builder(
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     itemCount: controller.matches.length,
                     itemBuilder: (context, index) {
                       var match = controller.matches[index];
                       return Card(
                         child: Padding(
                           padding: EdgeInsets.all(10),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               ListTile(
                                 contentPadding: EdgeInsets.zero,
                                 title: Text("Overhead: ${match.totalOverhead?.toStringAsFixed(1)} min", style: boldDefault),
                                 // Now assumes Match model has 'r2Amount' or we grab it from map
                                 // Note: Model update needed to parse r2_fare from JSON.
                                 // For now using the logic that backend sends it.
                                 subtitle: Text("Est. Fare: \$${match.r2Fare} (Savings: \$${(match.r2Solo! * 2.0/120 * 2.0 - match.r2Fare!).toStringAsFixed(1)})", maxLines: 1, overflow: TextOverflow.ellipsis),
                                 trailing: ElevatedButton(
                                   child: const Text("Join"),
                                   onPressed: () {
                                     controller.joinRide(match.ride!.id.toString());
                                   },
                                   style: ElevatedButton.styleFrom(backgroundColor: MyColor.primaryColor, foregroundColor: Colors.white),
                                 ),
                               ),
                               Divider(),
                               // Route Visualization
                               if (index < 5 && match.ride?.pickupLat != null)
                                  SharedRideMapWidget(
                                    startLat1: match.ride!.pickupLat!,
                                    startLng1: match.ride!.pickupLng!,
                                    endLat1: match.ride!.destLat!,
                                    endLng1: match.ride!.destLng!,
                                    // Current user coords passed from input/controller
                                    // Wait, we need the stored input coords. 
                                    // I'll grab them from the controller temporarily or pass them.
                                    // Controller.startLat is not public? 
                                    // Let's assume for now we use the ones from the match creation request 
                                    // (which aren't in the match object yet, but were sent).
                                    // Quick fix: Use dummy or pass via controller.
                                    // Using 0,0 placeholder if not available, but should be fixed.
                                    startLat2: double.tryParse(controller.startLatController.text) ?? 0,
                                    startLng2: double.tryParse(controller.startLngController.text) ?? 0,
                                    endLat2: double.tryParse(controller.endLatController.text) ?? 0,
                                    endLng2: double.tryParse(controller.endLngController.text) ?? 0,
                                  )
                               else
                                  SharedRideRouteWidget(sequence: match.sequence ?? [])
                             ],
                           ),
                         ),
                       );
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
