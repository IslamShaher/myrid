import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/ride/widgets/shared_ride_map_widget.dart';
import 'package:ovorideuser/presentation/components/buttons/enhanced_action_button.dart';

class ConfirmedSharedRideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  
  const ConfirmedSharedRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final otherUser = ride['other_user'] as Map<String, dynamic>?;
    final isRider1 = ride['is_rider1'] as bool? ?? false;
    final userFare = isRider1 
        ? (ride['r1_fare'] is num ? ride['r1_fare'] as num : double.tryParse(ride['r1_fare']?.toString() ?? ''))
        : (ride['r2_fare'] is num ? ride['r2_fare'] as num : double.tryParse(ride['r2_fare']?.toString() ?? ''));
    final totalOverhead = ride['total_overhead'] is num 
        ? ride['total_overhead'] as num 
        : double.tryParse(ride['total_overhead']?.toString() ?? '');
    final estimatedPickupTime = ride['estimated_pickup_time_readable'] as String?;
    final sequence = ride['shared_ride_sequence'] as List<dynamic>?;
    
    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: MyColor.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: MyColor.getPrimaryColor().withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.mediumRadius),
                topRight: Radius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: MyColor.colorGreen, size: 24),
                SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Text(
                    "Confirmed Shared Ride",
                    style: boldDefault.copyWith(color: MyColor.getPrimaryColor()),
                  ),
                ),
                if (ride['uid'] != null)
                  Text(
                    "#${ride['uid']}",
                    style: regularSmall.copyWith(color: MyColor.neutral700),
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(Dimensions.space15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route info
                Text(
                  "${ride['pickup_location'] ?? ''} → ${ride['destination'] ?? ''}",
                  style: regularDefault,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                spaceDown(Dimensions.space15),
                
                // Map
                if (ride['pickup_latitude'] != null && ride['pickup_longitude'] != null &&
                    ride['second_pickup_latitude'] != null && ride['second_pickup_longitude'] != null)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      border: Border.all(color: MyColor.neutral300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                      child: SharedRideMapWidget(
                        startLat1: ride['pickup_latitude'] is num 
                            ? (ride['pickup_latitude'] as num).toDouble()
                            : (double.tryParse(ride['pickup_latitude']?.toString() ?? '') ?? 0.0),
                        startLng1: ride['pickup_longitude'] is num 
                            ? (ride['pickup_longitude'] as num).toDouble()
                            : (double.tryParse(ride['pickup_longitude']?.toString() ?? '') ?? 0.0),
                        endLat1: ride['destination_latitude'] is num 
                            ? (ride['destination_latitude'] as num).toDouble()
                            : (double.tryParse(ride['destination_latitude']?.toString() ?? '') ?? 0.0),
                        endLng1: ride['destination_longitude'] is num 
                            ? (ride['destination_longitude'] as num).toDouble()
                            : (double.tryParse(ride['destination_longitude']?.toString() ?? '') ?? 0.0),
                        startLat2: ride['second_pickup_latitude'] is num 
                            ? (ride['second_pickup_latitude'] as num).toDouble()
                            : (double.tryParse(ride['second_pickup_latitude']?.toString() ?? '') ?? 0.0),
                        startLng2: ride['second_pickup_longitude'] is num 
                            ? (ride['second_pickup_longitude'] as num).toDouble()
                            : (double.tryParse(ride['second_pickup_longitude']?.toString() ?? '') ?? 0.0),
                        endLat2: ride['second_destination_latitude'] is num 
                            ? (ride['second_destination_latitude'] as num).toDouble()
                            : (double.tryParse(ride['second_destination_latitude']?.toString() ?? '') ?? 0.0),
                        endLng2: ride['second_destination_longitude'] is num 
                            ? (ride['second_destination_longitude'] as num).toDouble()
                            : (double.tryParse(ride['second_destination_longitude']?.toString() ?? '') ?? 0.0),
                        sequence: sequence?.map((e) => e.toString()).toList(),
                        directionsData: ride['directions_data'] as Map<String, dynamic>?,
                      ),
                    ),
                  ),
                spaceDown(Dimensions.space15),
                
                // Fare and overhead info
                Container(
                  padding: EdgeInsets.all(Dimensions.space12),
                  decoration: BoxDecoration(
                    color: MyColor.neutral100,
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Your Fare:", style: regularDefault),
                          Text(
                            "\$${userFare?.toStringAsFixed(2) ?? 'N/A'}",
                            style: boldDefault.copyWith(color: MyColor.getPrimaryColor()),
                          ),
                        ],
                      ),
                      if (totalOverhead != null) ...[
                        SizedBox(height: Dimensions.space8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Overhead:", style: regularDefault),
                            Text(
                              "${totalOverhead.toStringAsFixed(1)} min",
                              style: regularDefault.copyWith(color: MyColor.neutral700),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                spaceDown(Dimensions.space15),
                
                // Pickup time
                if (estimatedPickupTime != null) ...[
                  Container(
                    padding: EdgeInsets.all(Dimensions.space12),
                    decoration: BoxDecoration(
                      color: MyColor.getPrimaryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 20, color: MyColor.getPrimaryColor()),
                        SizedBox(width: Dimensions.space10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Estimated Pickup Time",
                                style: regularSmall.copyWith(color: MyColor.neutral700),
                              ),
                              Text(
                                estimatedPickupTime,
                                style: boldDefault.copyWith(color: MyColor.getPrimaryColor()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  spaceDown(Dimensions.space15),
                ],
                
                // Other user profile
                if (otherUser != null) ...[
                  Divider(),
                  spaceDown(Dimensions.space10),
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: MyColor.neutral200,
                        child: otherUser['image'] != null && otherUser['image'].toString().isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  otherUser['image'].toString(),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person, size: 30, color: MyColor.neutral700);
                                  },
                                ),
                              )
                            : Icon(Icons.person, size: 30, color: MyColor.neutral700),
                      ),
                      SizedBox(width: Dimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${otherUser['firstname'] ?? ''} ${otherUser['lastname'] ?? ''}",
                              style: boldDefault,
                            ),
                            if (otherUser['rating'] != null) ...[
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text(
                                    otherUser['rating'].toString(),
                                    style: regularSmall.copyWith(color: MyColor.neutral700),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  spaceDown(Dimensions.space15),
                ],
                
                // Chat button
                EnhancedActionButton(
                  text: "Chat with Partner",
                  icon: Icons.message_outlined,
                  backgroundColor: MyColor.getPrimaryColor(),
                  isPrimary: true,
                  onPressed: () {
                    // RideMessageScreen expects: [rideId, riderName, riderStatus]
                    String riderName = otherUser != null 
                        ? "${otherUser['firstname'] ?? ''} ${otherUser['lastname'] ?? ''}".trim()
                        : "Partner";
                    if (riderName.isEmpty) riderName = "Partner";
                    Get.toNamed(RouteHelper.rideMessageScreen, arguments: [
                      ride['id'].toString(),
                      riderName,
                      ride['status']?.toString() ?? "1"
                    ]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

