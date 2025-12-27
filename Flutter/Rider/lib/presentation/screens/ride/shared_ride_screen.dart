import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/data/repo/shuttle/shared_ride_repo.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_route_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';
import 'package:intl/intl.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  bool isScheduled = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  
  @override
  void initState() {
    // Create repo and controller directly since they're not in dependency injection
    if (!Get.isRegistered<SharedRideController>()) {
      Get.put(SharedRideController(sharedRideRepo: SharedRideRepo(apiClient: Get.find())));
    }
    // Default to today and current time
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    super.initState();
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }
  
  DateTime? _getScheduledDateTime() {
    if (!isScheduled || selectedDate == null || selectedTime == null) {
      return null;
    }
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
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
                      
                      // Coordinate Inputs for Testing
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.startLatController,
                              decoration: InputDecoration(labelText: "Start Lat", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller.startLngController,
                              decoration: InputDecoration(labelText: "Start Lng", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      spaceDown(Dimensions.space10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller.endLatController,
                              decoration: InputDecoration(labelText: "End Lat", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: controller.endLngController,
                              decoration: InputDecoration(labelText: "End Lng", border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      spaceDown(Dimensions.space15),
                      
                      // Schedule Options
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MyColor.neutral100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MyColor.neutral300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Radio<bool>(
                                  value: false,
                                  groupValue: isScheduled,
                                  onChanged: (value) {
                                    setState(() {
                                      isScheduled = false;
                                    });
                                  },
                                  activeColor: MyColor.getPrimaryColor(),
                                ),
                                Text("Now", style: regularDefault),
                                SizedBox(width: 20),
                                Radio<bool>(
                                  value: true,
                                  groupValue: isScheduled,
                                  onChanged: (value) {
                                    setState(() {
                                      isScheduled = true;
                                    });
                                  },
                                  activeColor: MyColor.getPrimaryColor(),
                                ),
                                Text("Schedule", style: regularDefault),
                              ],
                            ),
                            if (isScheduled) ...[
                              spaceDown(10),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectDate(context),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: MyColor.colorWhite,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: MyColor.neutral300),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 20, color: MyColor.getPrimaryColor()),
                                            SizedBox(width: 8),
                                            Text(
                                              selectedDate != null 
                                                ? DateFormat('MMM dd, yyyy').format(selectedDate!)
                                                : "Select Date",
                                              style: regularDefault,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectTime(context),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: MyColor.colorWhite,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: MyColor.neutral300),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.access_time, size: 20, color: MyColor.getPrimaryColor()),
                                            SizedBox(width: 8),
                                            Text(
                                              selectedTime != null
                                                ? selectedTime!.format(context)
                                                : "Select Time",
                                              style: regularDefault,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      spaceDown(Dimensions.space15),
                      
                      RoundedButton(
                        text: "Match Ride",
                        press: () {
                           print("Match Ride button pressed");
                           double? sLat = double.tryParse(controller.startLatController.text);
                           double? sLng = double.tryParse(controller.startLngController.text);
                           double? eLat = double.tryParse(controller.endLatController.text);
                           double? eLng = double.tryParse(controller.endLngController.text);

                           print("Coords: $sLat, $sLng -> $eLat, $eLng");

                           if (sLat != null && sLng != null && eLat != null && eLng != null) {
                             DateTime? scheduledDateTime = _getScheduledDateTime();
                             controller.matchSharedRide(
                               startLat: sLat,
                               startLng: sLng,
                               endLat: eLat,
                               endLng: eLng,
                               pickupLocation: "Test Source",
                               destination: "Test Destination",
                               scheduledTime: scheduledDateTime,
                             );
                           } else {
                             print("Setting dummy values...");
                             controller.startLatController.text = "30.0444";
                             controller.startLngController.text = "31.2357";
                             controller.endLatController.text = "30.0131";
                             controller.endLngController.text = "31.2089";
                             controller.update(); // Trigger rebuild if needed for fields
                           }
                        },
                      ),
                      spaceDown(Dimensions.space10),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.grey.withOpacity(0.1),
                            padding: const EdgeInsets.all(10),
                            child: const Text("Enter coords above (Cairo defaults set on first click if empty)"),
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
                                 subtitle: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text("Est. Fare: \$${match.r2Fare} ${match.r2SoloFare != null ? '(Savings: \$${(match.r2SoloFare! - match.r2Fare!).toStringAsFixed(1)})' : ''}", maxLines: 1, overflow: TextOverflow.ellipsis),
                                     if (match.estimatedPickupTimeReadable != null) ...[
                                       SizedBox(height: 4),
                                       Row(
                                         children: [
                                           Icon(Icons.schedule, size: 14, color: MyColor.getPrimaryColor()),
                                           SizedBox(width: 4),
                                           Text(
                                             "Est. Pickup: ${match.estimatedPickupTimeReadable}",
                                             style: regularSmall.copyWith(color: MyColor.getPrimaryColor()),
                                           ),
                                         ],
                                       ),
                                     ],
                                   ],
                                 ),
                                 trailing: ElevatedButton(
                                   child: const Text("Join"),
                                   onPressed: () {
                                     double? sLat = double.tryParse(controller.startLatController.text);
                                     double? sLng = double.tryParse(controller.startLngController.text);
                                     double? eLat = double.tryParse(controller.endLatController.text);
                                     double? eLng = double.tryParse(controller.endLngController.text);
                                     controller.joinRide(
                                       match.ride!.id.toString(),
                                       startLat: sLat,
                                       startLng: sLng,
                                       endLat: eLat,
                                       endLng: eLng,
                                     );
                                   },
                                   style: ElevatedButton.styleFrom(backgroundColor: MyColor.primaryColor, foregroundColor: Colors.white),
                                 ),
                               ),
                               Divider(),
                               // Route Visualization
                               if (match.ride?.pickupLat != null)
                                  SharedRideMapWidget(
                                    startLat1: match.ride!.pickupLat!,
                                    startLng1: match.ride!.pickupLng!,
                                    endLat1: match.ride!.destLat!,
                                    endLng1: match.ride!.destLng!,
                                    startLat2: double.tryParse(controller.startLatController.text) ?? 0,
                                    startLng2: double.tryParse(controller.startLngController.text) ?? 0,
                                    endLat2: double.tryParse(controller.endLatController.text) ?? 0,
                                    endLng2: double.tryParse(controller.endLngController.text) ?? 0,
                                    sequence: match.sequence,
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
