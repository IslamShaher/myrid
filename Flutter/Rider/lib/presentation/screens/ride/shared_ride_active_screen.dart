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
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/presentation/components/buttons/swipe_to_start_button.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_navigation_widget.dart';
import 'package:ovorideuser/core/utils/util.dart';

class SharedRideActiveScreen extends StatefulWidget {
  final String rideId;
  const SharedRideActiveScreen({super.key, required this.rideId});

  @override
  State<SharedRideActiveScreen> createState() => _SharedRideActiveScreenState();
}

class _SharedRideActiveScreenState extends State<SharedRideActiveScreen> {
  RideInfo? rideData;
  bool isLoading = true;
  String? rideStatus; // 'active' or 'running'
  Timer? _locationUpdateTimer;
  Timer? _dataRefreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadRideData();
    // Start periodic data refresh
    _dataRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadRideData();
    });
    // Start location tracking if ride is running
    _startLocationTracking();
    // Listen to Pusher events for live location updates
    _setupPusherListener();
  }
  
  void _setupPusherListener() {
    // Listen to Pusher events for live location updates
    // The PusherRideController handles LIVE_LOCATION events
    // We'll update state when location updates are received via GetX
    if (Get.isRegistered<PusherRideController>()) {
      // Location updates will be handled through the controller
      // We can add a listener here if needed
    }
  }
  
  void _updateOtherUserLocation(LatLng location) {
    setState(() {
      otherUserLocation = location;
    });
  }
  
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _dataRefreshTimer?.cancel();
    super.dispose();
  }
  
  void _startLocationTracking() {
    // Update location every 10 seconds when ride is active/running
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (rideStatus == 'active' || rideStatus == 'running') {
        await _updateLiveLocation();
      }
    });
  }
  
  Future<void> _updateLiveLocation() async {
    try {
      final controller = Get.find<SharedRideController>();
      final appLocationController = Get.find<AppLocationController>();
      final position = await appLocationController.getCurrentPosition();
      if (position != null) {
        final location = LatLng(position.latitude, position.longitude);
        controller.updateCurrentUserLocation(location);
        
        // Send to backend
        await controller.sharedRideRepo.updateLiveLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      print('Error updating live location: $e');
    }
  }
  
  Future<void> _loadRideData() async {
    try {
      final controller = Get.find<SharedRideController>();
      final response = await controller.sharedRideRepo.getActiveSharedRide();
      if (response.statusCode == 200 && response.responseJson['data'] != null) {
        final data = response.responseJson['data'];
        setState(() {
          rideData = RideInfo.fromJson(data);
          rideStatus = data['status']?.toString() ?? 'active';
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
          
          String status = rideStatus ?? "active";
          
          // Check if ride has started (status is running)
          // Status values: '1' = active, '2' = running, 'running' = running
          bool isRideRunning = status == 'running' || status == '2' || status == '2.0';
          
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
                
                if (isRideRunning && rideData != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: EnhancedActionButton(
                      text: "Open Directions in Maps",
                      icon: Icons.map_outlined,
                      backgroundColor: MyColor.neutral700,
                      isPrimary: false,
                      onPressed: () {
                        MyUtils.launchMap(rideData!.destLat!, rideData!.destLng!);
                      },
                    ),
                  ),
                
                const Divider(),
                
                // Instructions for Second User (Rider 2)
                if(isRider2) ...[
                  _buildSecondUserInstructionsCard(rideData, status),
                  spaceDown(16),
                ],
                
                // Instructions and Map for Rider 1
                if(isRider1) ...[
                  // Show instructions dialog on first load
                  if (rideData != null && rideData!.secondUserId != null)
                    _buildInstructionsCard(rideData!),
                  spaceDown(16),
                  
                  // Map showing all 4 points with route and live locations
                  if (rideData != null && 
                      rideData!.pickupLat != null && 
                      rideData!.pickupLng != null &&
                      rideData!.destLat != null &&
                      rideData!.destLng != null &&
                      rideData!.secondPickupLat != null &&
                      rideData!.secondPickupLng != null &&
                      rideData!.secondDestLat != null &&
                      rideData!.secondDestLng != null)
                    Container(
                      height: isRideRunning ? 400 : 300,
                      margin: EdgeInsets.only(bottom: Dimensions.space15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        border: Border.all(color: MyColor.neutral300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        child: SharedRideMapWidget(
                          startLat1: rideData!.pickupLat!,
                          startLng1: rideData!.pickupLng!,
                          endLat1: rideData!.destLat!,
                          endLng1: rideData!.destLng!,
                          startLat2: rideData!.secondPickupLat!,
                          startLng2: rideData!.secondPickupLng!,
                          endLat2: rideData!.secondDestLat!,
                          endLng2: rideData!.secondDestLng!,
                          sequence: rideData!.sharedRideSequence,
                          directionsData: rideData!.directionsData,
                          currentUserLocation: controller.currentUserLocation.value,
                          otherUserLocation: controller.otherUserLocation.value,
                          showLiveLocations: true,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 300,
                      margin: EdgeInsets.only(bottom: Dimensions.space15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                        border: Border.all(color: MyColor.neutral300),
                      ),
                      child: Center(
                        child: Text(
                          "Waiting for ride coordinates...",
                          style: regularDefault,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  spaceDown(16),
                  
                  // Uber-style Swipe to Start Button
                  if (status == 'active' || status == '1')
                    SwipeToStartButton(
                      text: "Swipe to Start Ride",
                      isLoading: controller.isLoading,
                      onStart: () async {
                        controller.isLoading = true;
                        controller.update();
                        try {
                          final response = await controller.sharedRideRepo.updateRideStatus(
                            rideId: widget.rideId, 
                            action: 'start_driving'
                          );
                          if (response.statusCode == 200) {
                            CustomSnackBar.success(
                              successList: [response.responseJson['message'] ?? 'Ride started!']
                            );
                            setState(() {
                              rideStatus = 'running';
                            });
                            _loadRideData(); // Reload to update status
                            _startLocationTracking(); // Start location updates
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
                  spaceDown(16),
                ],
                
                // Navigation Mode for Rider 1 when ride is running
                if (isRider1 && isRideRunning && rideData != null &&
                    rideData!.directionsData != null &&
                    rideData!.sharedRideSequence != null)
                  SharedRideNavigationWidget(
                    directionsData: rideData!.directionsData!,
                    sequence: rideData!.sharedRideSequence!,
                    currentLocation: controller.currentUserLocation.value,
                    pickupLat1: rideData!.pickupLat!,
                    pickupLng1: rideData!.pickupLng!,
                    destLat1: rideData!.destLat!,
                    destLng1: rideData!.destLng!,
                    pickupLat2: rideData!.secondPickupLat!,
                    pickupLng2: rideData!.secondPickupLng!,
                    destLat2: rideData!.secondDestLat!,
                    destLng2: rideData!.secondDestLng!,
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
                      // Navigate to fare upload screen or show dialog
                      Get.toNamed(
                        RouteHelper.rideDetailsScreen,
                        arguments: widget.rideId,
                      )?.then((_) {
                        _loadRideData(); // Reload after returning
                      });
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

  Widget _buildInstructionsCard(RideInfo rideData) {
    return Container(
      padding: EdgeInsets.all(Dimensions.space15),
      margin: EdgeInsets.only(bottom: Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.getPrimaryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(
          color: MyColor.getPrimaryColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: MyColor.getPrimaryColor(), size: 24),
              spaceSide(Dimensions.space10),
              Expanded(
                child: Text(
                  "You are the First Pickup",
                  style: boldLarge.copyWith(color: MyColor.getPrimaryColor()),
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space10),
          Text(
            "As the first pickup user, you are responsible for:",
            style: boldDefault.copyWith(fontSize: 14),
          ),
          spaceDown(Dimensions.space8),
          _buildInstructionItem("1. Starting the ride by swiping the button above"),
          _buildInstructionItem("2. Booking the ride in Uber/Careem with these 4 points:"),
          spaceDown(Dimensions.space5),
          if (rideData.sharedRideSequence != null && rideData.sharedRideSequence!.isNotEmpty) ...[
            ...rideData.sharedRideSequence!.asMap().entries.map((entry) {
              int index = entry.key;
              String code = entry.value;
              String pointName = code == 'S1' ? 'Your Pickup' :
                                code == 'S2' ? 'Rider 2 Pickup' :
                                code == 'E1' ? 'Your Dropoff' :
                                'Rider 2 Dropoff';
              return Padding(
                padding: EdgeInsets.only(left: Dimensions.space20, bottom: Dimensions.space5),
                child: Text(
                  "${index + 1}. $pointName ($code)",
                  style: regularDefault.copyWith(fontSize: 13),
                ),
              );
            }),
          ],
          spaceDown(Dimensions.space8),
          _buildInstructionItem("3. Chat or call the other rider if you need more details"),
          _buildInstructionItem("4. Upload the fare screenshot after the ride"),
          spaceDown(Dimensions.space10),
          Container(
            padding: EdgeInsets.all(Dimensions.space10),
            decoration: BoxDecoration(
              color: MyColor.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 20, color: MyColor.getPrimaryColor()),
                spaceSide(Dimensions.space8),
                Expanded(
                  child: Text(
                    "The map below shows all 4 points. You can zoom in/out to see details.",
                    style: regularSmall.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimensions.space5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: boldDefault.copyWith(fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: regularDefault.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondUserInstructionsCard(RideInfo? rideData, String status) {
    String statusMessage = "Waiting for first user to start the ride";
    Color statusColor = MyColor.neutral700;
    IconData statusIcon = Icons.hourglass_empty;
    
    if (status == 'running' || status == '2') {
      statusMessage = "Ride is in progress";
      statusColor = MyColor.colorGreen;
      statusIcon = Icons.directions_car;
    } else if (status == 'active' || status == '1') {
      statusMessage = "Waiting for first user to start the ride";
      statusColor = MyColor.getPrimaryColor();
      statusIcon = Icons.access_time;
    }
    
    return Container(
      padding: EdgeInsets.all(Dimensions.space15),
      margin: EdgeInsets.only(bottom: Dimensions.space15),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              spaceSide(Dimensions.space10),
              Expanded(
                child: Text(
                  "You are the Second Rider",
                  style: boldLarge.copyWith(color: statusColor),
                ),
              ),
            ],
          ),
          spaceDown(Dimensions.space10),
          Container(
            padding: EdgeInsets.all(Dimensions.space10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: statusColor),
                spaceSide(Dimensions.space8),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: boldDefault.copyWith(color: statusColor, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          spaceDown(Dimensions.space10),
          Text(
            "As the second rider, you should:",
            style: boldDefault.copyWith(fontSize: 14),
          ),
          spaceDown(Dimensions.space8),
          _buildInstructionItem("1. Wait for the first rider to start the ride"),
          _buildInstructionItem("2. Be ready at your pickup location when notified"),
          _buildInstructionItem("3. Confirm your pickup when the first rider arrives"),
          _buildInstructionItem("4. Chat or call the first rider if you need to coordinate"),
          if (rideData?.sharedRideSequence != null && rideData!.sharedRideSequence!.isNotEmpty) ...[
            spaceDown(Dimensions.space8),
            Container(
              padding: EdgeInsets.all(Dimensions.space10),
              decoration: BoxDecoration(
                color: MyColor.neutral100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pickup Order:",
                    style: boldDefault.copyWith(fontSize: 13),
                  ),
                  spaceDown(Dimensions.space5),
                  ...rideData.sharedRideSequence!.asMap().entries.map((entry) {
                    int index = entry.key;
                    String code = entry.value;
                    String pointName = code == 'S1' ? 'Rider 1 Pickup' :
                                      code == 'S2' ? 'Your Pickup' :
                                      code == 'E1' ? 'Rider 1 Dropoff' :
                                      'Your Dropoff';
                    return Padding(
                      padding: EdgeInsets.only(left: Dimensions.space10, bottom: Dimensions.space3),
                      child: Text(
                        "${index + 1}. $pointName",
                        style: regularSmall.copyWith(fontSize: 12),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
