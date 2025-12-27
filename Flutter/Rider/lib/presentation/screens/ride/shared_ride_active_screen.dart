import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/data/model/shuttle/shared_ride_match_model.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/components/buttons/enhanced_action_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';

class SharedRideActiveScreen extends StatefulWidget {
  final String rideId;
  const SharedRideActiveScreen({super.key, required this.rideId});

  @override
  State<SharedRideActiveScreen> createState() => _SharedRideActiveScreenState();
}

class _SharedRideActiveScreenState extends State<SharedRideActiveScreen> {
  RideInfo? rideData;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadRideData();
  }
  
  Future<void> _loadRideData() async {
    try {
      final controller = Get.find<SharedRideController>();
      final response = await controller.sharedRideRepo.getActiveSharedRide();
      if (response.statusCode == 200 && response.responseJson['data'] != null) {
        setState(() {
          rideData = RideInfo.fromJson(response.responseJson['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Active Shared Ride"),
      body: GetBuilder<SharedRideController>(
        builder: (controller) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          // Get current user ID
          final currentUserId = int.tryParse(controller.sharedRideRepo.apiClient.getUserID()) ?? -1;
          
          // Determine user role
          bool isRider1 = rideData?.userId == currentUserId;
          bool isRider2 = rideData?.secondUserId == currentUserId;
          
          // Check if current user's pickup is first in sequence (only they can upload screenshot)
          bool canUploadScreenshot = false;
          if (rideData?.sharedRideSequence != null && rideData!.sharedRideSequence!.isNotEmpty) {
            String firstPickup = rideData!.sharedRideSequence!.first;
            // If sequence starts with S1, only Rider 1 can upload
            // If sequence starts with S2, only Rider 2 can upload
            canUploadScreenshot = (firstPickup == 'S1' && isRider1) || (firstPickup == 'S2' && isRider2);
          }
          
          String status = "active"; // Could get from rideData.status if needed
          
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
                      if (rideData != null) ...[
                        spaceDown(5),
                        Text("You are: ${isRider1 ? 'Rider 1' : isRider2 ? 'Rider 2' : 'Unknown'}", style: regularSmall),
                      ],
                    ],
                  ),
                ),
                spaceDown(20),
                
                // Ride Guide Button (Rider 1) - Enhanced with icon
                if(isRider1)
                  EnhancedActionButton(
                    text: "Ride Details (Route Guide)",
                    icon: Icons.route_outlined,
                    backgroundColor: MyColor.neutral100,
                    textColor: MyColor.primaryTextColor,
                    iconColor: MyColor.getPrimaryColor(),
                    isOutlined: false,
                    onPressed: () {
                      // Open Route Guide Screen
                      Get.dialog(
                        AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: [
                              Icon(Icons.route, color: MyColor.getPrimaryColor()),
                              const SizedBox(width: 12),
                              const Text("Route Guide"),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Follow this pickup order:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildRouteStep("1", "Pickup You", Icons.person),
                              _buildRouteStep("2", "Pickup Rider 2", Icons.person_outline),
                              _buildRouteStep("3", "Dropoff You", Icons.location_on),
                              _buildRouteStep("4", "Dropoff Rider 2", Icons.location_on_outlined),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: MyColor.neutral100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Enter this order in Uber/Careem",
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text("Got it"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                spaceDown(16),
                
                // Active Flow Buttons - Enhanced
                if (isRider1 && status == 'active')
                  EnhancedActionButton(
                    text: "I Started Driving",
                    icon: Icons.play_circle_outline,
                    backgroundColor: MyColor.colorGreen,
                    isPrimary: true,
                    isLoading: controller.isLoading,
                    onPressed: () async {
                      controller.isLoading = true;
                      controller.update();
                      try {
                        final response = await controller.sharedRideRepo.updateRideStatus(rideId: widget.rideId, action: 'start_driving');
                        if (response.statusCode == 200) {
                          CustomSnackBar.success(successList: [response.responseJson['message'] ?? 'Status updated']);
                        } else {
                          CustomSnackBar.error(errorList: [response.message]);
                        }
                      } catch (e) {
                        CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
                      } finally {
                        controller.isLoading = false;
                        controller.update();
                      }
                    },
                  ),
                spaceDown(12),
                  
                if (isRider1) 
                  EnhancedActionButton(
                    text: "I Arrived at Rider 2",
                    icon: Icons.location_on,
                    backgroundColor: MyColor.getPrimaryColor(),
                    isPrimary: true,
                    isLoading: controller.isLoading,
                    onPressed: () async {
                      controller.isLoading = true;
                      controller.update();
                      try {
                        final response = await controller.sharedRideRepo.updateRideStatus(rideId: widget.rideId, action: 'arrived_at_pickup');
                        if (response.statusCode == 200) {
                          CustomSnackBar.success(successList: [response.responseJson['message'] ?? 'Status updated']);
                        } else {
                          CustomSnackBar.error(errorList: [response.message]);
                        }
                      } catch (e) {
                        CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
                      } finally {
                        controller.isLoading = false;
                        controller.update();
                      }
                    },
                  ),
                spaceDown(12),
                
                if (isRider2)
                  EnhancedActionButton(
                    text: "Confirm Pickup",
                    icon: Icons.check_circle_outline,
                    backgroundColor: MyColor.colorGreen,
                    isPrimary: true,
                    isLoading: controller.isLoading,
                    onPressed: () async {
                      controller.isLoading = true;
                      controller.update();
                      try {
                        final response = await controller.sharedRideRepo.updateRideStatus(rideId: widget.rideId, action: 'confirm_pickup');
                        if (response.statusCode == 200) {
                          CustomSnackBar.success(successList: [response.responseJson['message'] ?? 'Pickup confirmed']);
                          _loadRideData(); // Reload to get updated status
                        } else {
                          CustomSnackBar.error(errorList: [response.message]);
                        }
                      } catch (e) {
                        CustomSnackBar.error(errorList: [MyStrings.somethingWentWrong.tr]);
                      } finally {
                        controller.isLoading = false;
                        controller.update();
                      }
                    },
                  ),

                spaceDown(20),
                // Only show upload screenshot button to user whose pickup is first in sequence
                if (canUploadScreenshot)
                  EnhancedActionButton(
                    text: "Upload Fare Screenshot",
                    icon: Icons.camera_alt_outlined,
                    backgroundColor: MyColor.neutral700,
                    isPrimary: false,
                    onPressed: () {
                       // Image Picker logic
                      CustomSnackBar.success(successList: ["Opening camera..."]);
                    },
                  ),

                spaceDown(20),
                // Enhanced Call and Chat buttons
                Row(
                  children: [
                    Expanded(
                      child: EnhancedActionButton(
                        text: "Call Rider",
                        icon: Icons.phone,
                        backgroundColor: MyColor.colorGreen,
                        isPrimary: true,
                        width: double.infinity,
                        onPressed: () {
                          // Using URL Launcher to call
                          // MyUtils.launchPhoneUrl(widget.ride.otherUserPhone);
                          CustomSnackBar.success(successList: ["Calling Rider..."]);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnhancedActionButton(
                        text: "Chat",
                        icon: Icons.message_outlined,
                        backgroundColor: MyColor.getPrimaryColor(),
                        isPrimary: true,
                        width: double.infinity,
                        onPressed: () {
                          // RideMessageScreen expects: [rideId, riderName, riderStatus]
                          String riderName = "Partner";
                          String riderStatus = "1"; // Default status for shared rides
                          
                          // Try to get other user's name from rideData
                          // For now, use a default name since RideInfo doesn't include user details
                          Get.toNamed(RouteHelper.rideMessageScreen, arguments: [
                            widget.rideId,
                            riderName,
                            riderStatus
                          ]);
                        },
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRouteStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: MyColor.getPrimaryColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: boldDefault.copyWith(
                  color: MyColor.getPrimaryColor(),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: MyColor.neutral700),
          const SizedBox(width: 8),
          Text(
            text,
            style: regularDefault.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}
