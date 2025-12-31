import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/date_converter.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovorideuser/data/model/shuttle/shared_ride_match_model.dart';
import 'package:ovorideuser/data/model/global/app/ride_message_model.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/buttons/swipe_to_start_button.dart';
import 'package:ovorideuser/presentation/components/buttons/enhanced_action_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_navigation_widget.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_route_widget.dart';
import 'package:ovorideuser/presentation/packages/flutter_chat_bubble/chat_bubble.dart';

class SharedRideUnifiedScreen extends StatefulWidget {
  final String? rideId;
  
  const SharedRideUnifiedScreen({super.key, this.rideId});

  @override
  State<SharedRideUnifiedScreen> createState() => _SharedRideUnifiedScreenState();
}

class _SharedRideUnifiedScreenState extends State<SharedRideUnifiedScreen> {
  // Matching state
  bool isScheduled = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  
  // Active ride state
  RideInfo? rideData;
  bool isLoadingRide = true;
  String? rideStatus;
  Timer? _locationUpdateTimer;
  Timer? _dataRefreshTimer;
  Timer? _messagePollTimer;
  
  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.now();
    
    if (widget.rideId != null) {
      _loadRideData();
      _startLocationTracking();
      _startMessagePolling(widget.rideId!);
    } else {
      _checkForActiveRide();
    }
  }
  
  void _checkForActiveRide() async {
    try {
      final controller = Get.find<SharedRideController>();
      final response = await controller.sharedRideRepo.getActiveSharedRide();
      if (response.statusCode == 200 && response.responseJson['data'] != null) {
        final data = response.responseJson['data'];
        setState(() {
          rideData = RideInfo.fromJson(data);
          rideStatus = data['status']?.toString() ?? 'active';
          isLoadingRide = false;
        });
        _startLocationTracking();
        _startMessagePolling(rideData!.id.toString());
        _dataRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          _loadRideData();
        });
      } else {
        setState(() {
          isLoadingRide = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingRide = false;
      });
    }
  }
  
  void _startMessagePolling(String rideId) {
    if (Get.isRegistered<RideMessageController>()) {
      final msgController = Get.find<RideMessageController>();
      msgController.initialData(rideId);
      _messagePollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        msgController.getRideMessage(rideId, shouldLoading: false);
      });
    }
  }
  
  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _dataRefreshTimer?.cancel();
    _messagePollTimer?.cancel();
    super.dispose();
  }
  
  void _startLocationTracking() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (rideStatus == 'active' || rideStatus == 'running' || rideStatus == '2') {
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
        final newRideData = RideInfo.fromJson(data);
        setState(() {
          rideData = newRideData;
          rideStatus = data['status']?.toString() ?? 'active';
          isLoadingRide = false;
        });
        
        // Update ride ID if it changed (e.g., when user 2 joins)
        if (widget.rideId == null && newRideData.id != null) {
          // Start message polling if not already started
          if (_messagePollTimer == null) {
            _startMessagePolling(newRideData.id.toString());
          }
        }
      } else {
        setState(() {
          isLoadingRide = false;
        });
      }
    } catch (e) {
      print('Error loading ride data: $e');
      setState(() {
        isLoadingRide = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: MyColor.screenBgColor,
        body: GetBuilder<SharedRideController>(
          builder: (controller) {
            if (rideData != null) {
              return _buildActiveRideLayout(controller);
            }
            return _buildMatchingViewLayout(controller);
          },
        ),
      ),
    );
  }

  Widget _buildMatchMapWidget(SharedMatch match, SharedRideController controller) {
    // Validate ride coordinates exist
    if (match.ride?.pickupLat == null || match.ride?.pickupLng == null ||
        match.ride?.destLat == null || match.ride?.destLng == null) {
      return SharedRideRouteWidget(sequence: match.sequence ?? []);
    }
    
    // Get user coordinates from controller
    final userStartLat = double.tryParse(controller.startLatController.text);
    final userStartLng = double.tryParse(controller.startLngController.text);
    final userEndLat = double.tryParse(controller.endLatController.text);
    final userEndLng = double.tryParse(controller.endLngController.text);
    
    // Validate user coordinates before showing map
    if (userStartLat == null || userStartLng == null || 
        userEndLat == null || userEndLng == null ||
        userStartLat == 0 || userStartLng == 0 ||
        userEndLat == 0 || userEndLng == 0) {
      // Show route widget if coordinates invalid
      return SharedRideRouteWidget(sequence: match.sequence ?? []);
    }
    
    // Show map with all 4 points
    return SharedRideMapWidget(
      startLat1: match.ride!.pickupLat!,
      startLng1: match.ride!.pickupLng!,
      endLat1: match.ride!.destLat!,
      endLng1: match.ride!.destLng!,
      startLat2: userStartLat,
      startLng2: userStartLng,
      endLat2: userEndLat,
      endLng2: userEndLng,
      sequence: match.sequence,
      directionsData: match.directions,
    );
  }

  Widget _buildMapWidget(SharedRideController controller) {
    if (rideData == null || 
        rideData!.pickupLat == null || rideData!.pickupLng == null ||
        rideData!.destLat == null || rideData!.destLng == null) {
      return const Center(child: CustomLoader());
    }
    
    // Check if user 2 has joined - if yes, require all 4 points
    bool hasSecondUser = rideData!.secondUserId != null && 
                         rideData!.secondPickupLat != null && 
                         rideData!.secondPickupLng != null &&
                         rideData!.secondDestLat != null && 
                         rideData!.secondDestLng != null;
    
    if (hasSecondUser) {
      // Show map with all 4 points
      return SharedRideMapWidget(
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
      );
    } else {
      // Show map with only 2 points (user 1's pickup and destination)
      return SharedRideMapWidget(
        startLat1: rideData!.pickupLat!,
        startLng1: rideData!.pickupLng!,
        endLat1: rideData!.destLat!,
        endLng1: rideData!.destLng!,
        startLat2: rideData!.pickupLat!, // Temporary: use same points until user 2 joins
        startLng2: rideData!.pickupLng!,
        endLat2: rideData!.destLat!,
        endLng2: rideData!.destLng!,
        sequence: ['S1', 'E1'],
        directionsData: null,
        currentUserLocation: controller.currentUserLocation.value,
        otherUserLocation: controller.otherUserLocation.value,
        showLiveLocations: false,
      );
    }
  }

  Widget _buildActiveRideLayout(SharedRideController controller) {
    final currentUserId = int.tryParse(controller.sharedRideRepo.apiClient.getUserID()) ?? -1;
    bool isRider1 = rideData?.userId == currentUserId;
    String status = rideStatus ?? "active";
    bool isRideRunning = status == 'running' || status == '2' || status == '2.0';

    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              _buildMapWidget(controller),
              
              Positioned(
                top: 40,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
              
              if (isRideRunning && isRider1 && 
                  rideData?.directionsData != null &&
                  rideData!.sharedRideSequence != null &&
                  rideData!.sharedRideSequence!.length == 4 &&
                  rideData!.secondPickupLat != null &&
                  rideData!.secondPickupLng != null &&
                  rideData!.secondDestLat != null &&
                  rideData!.secondDestLng != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: SharedRideNavigationWidget(
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
                ),
            ],
          ),
        ),
        
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ride #${rideData?.id}", style: boldDefault),
                          Text("Status: $status", style: regularSmall.copyWith(color: MyColor.getPrimaryColor())),
                        ],
                      ),
                      if (isRider1 && (status == 'active' || status == '1'))
                        SizedBox(
                          width: 180,
                          child: SwipeToStartButton(
                            text: "Start Ride",
                            onStart: () async {
                              await controller.sharedRideRepo.updateRideStatus(rideId: rideData!.id.toString(), action: 'start_driving');
                              _loadRideData();
                            },
                          ),
                        ),
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
                
                Expanded(
                  child: GetBuilder<RideMessageController>(
                    builder: (msgController) {
                      return Column(
                        children: [
                          Expanded(
                            child: msgController.isLoading 
                              ? const CustomLoader()
                              : msgController.massageList.isEmpty
                                ? const Center(child: Text("No messages yet. Chat with your partner!"))
                                : ListView.builder(
                                    reverse: true,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: msgController.massageList.length,
                                    itemBuilder: (context, index) {
                                      final item = msgController.massageList[index];
                                      bool isMe = item.userId == msgController.userId;
                                      return _buildChatBubble(item, isMe);
                                    },
                                  ),
                          ),
                          _buildChatInput(msgController),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(RideMessage item, bool isMe) {
    return ChatBubble(
      clipper: isMe ? ChatBubbleClipper3(type: BubbleType.sendBubble) : ChatBubbleClipper3(type: BubbleType.receiverBubble),
      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
      margin: const EdgeInsets.only(top: 8),
      backGroundColor: isMe ? MyColor.getPrimaryColor() : Colors.grey[200],
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.message ?? "",
              style: TextStyle(color: isMe ? Colors.white : Colors.black87),
            ),
            Text(
              DateConverter.getTimeAgo(item.createdAt ?? ""),
              style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(RideMessageController controller) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.image, color: MyColor.getPrimaryColor()),
            onPressed: () => controller.pickFile(),
          ),
          Expanded(
            child: TextField(
              controller: controller.massageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: MyColor.getPrimaryColor()),
            onPressed: () {
              if (controller.massageController.text.isNotEmpty) {
                controller.sendMessage();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingViewLayout(SharedRideController controller) {
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
                
                // Coordinate Inputs
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.startLatController,
                        decoration: InputDecoration(
                          labelText: "Start Lat",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller.startLngController,
                        decoration: InputDecoration(
                          labelText: "Start Lng",
                          border: OutlineInputBorder(),
                        ),
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
                        decoration: InputDecoration(
                          labelText: "End Lat",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller.endLngController,
                        decoration: InputDecoration(
                          labelText: "End Lng",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                spaceDown(Dimensions.space15),
                
                RoundedButton(
                  text: "Match Ride",
                  press: () {
                    double? sLat = double.tryParse(controller.startLatController.text);
                    double? sLng = double.tryParse(controller.startLngController.text);
                    double? eLat = double.tryParse(controller.endLatController.text);
                    double? eLng = double.tryParse(controller.endLngController.text);

                    if (sLat != null && sLng != null && eLat != null && eLng != null) {
                      controller.matchSharedRide(
                        startLat: sLat,
                        startLng: sLng,
                        endLat: eLat,
                        endLng: eLng,
                        pickupLocation: "Test Source",
                        destination: "Test Destination",
                      );
                    } else {
                      controller.startLatController.text = "30.0444";
                      controller.startLngController.text = "31.2357";
                      controller.endLatController.text = "30.0131";
                      controller.endLngController.text = "31.2089";
                      controller.update();
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
                              ).then((_) {
                                // After joining, reload to show active ride
                                _checkForActiveRide();
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: MyColor.primaryColor, foregroundColor: Colors.white),
                          ),
                        ),
                        Divider(),
                        // Route Visualization - Show all 4 points with map
                        _buildMatchMapWidget(match, controller),
                      ],
                    ),
                  ),
                );
              },
            )
        ],
      ),
    );
  }
}
