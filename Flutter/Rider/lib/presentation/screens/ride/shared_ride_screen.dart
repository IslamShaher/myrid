import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/location_pickup_widget.dart'; // Reusing location picker widgets if possible
// Or create a simple UI for inputs

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  final TextEditingController startLatController = TextEditingController();
  final TextEditingController startLngController = TextEditingController();
  final TextEditingController endLatController = TextEditingController();
  final TextEditingController endLngController = TextEditingController();
  
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
                         child: ListTile(
                           title: Text("Trp: ${match.ride?.pickupLocation} -> ${match.ride?.destination}"),
                           subtitle: Text("Savings/Overhead: ${match.totalOverhead}"),
                           trailing: ElevatedButton(
                             child: const Text("Join"),
                             onPressed: () {
                               controller.joinRide(match.ride!.id.toString());
                             },
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
