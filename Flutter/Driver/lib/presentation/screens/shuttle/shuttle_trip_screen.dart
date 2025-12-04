import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/shuttle/shuttle_driver_controller.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_spacer.dart';

class ShuttleTripScreen extends StatefulWidget {
  const ShuttleTripScreen({super.key});

  @override
  State<ShuttleTripScreen> createState() => _ShuttleTripScreenState();
}

class _ShuttleTripScreenState extends State<ShuttleTripScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Active Trip"),
      body: GetBuilder<ShuttleDriverController>(
        builder: (controller) {
          var route = controller.currentRouteData;
          if (route == null) return Center(child: Text("No active trip data"));

          List stops = route['stops'] ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(Dimensions.space15),
            itemCount: stops.length,
            itemBuilder: (context, index) {
              var stop = stops[index];
              return Container(
                margin: EdgeInsets.only(bottom: Dimensions.space10),
                padding: EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.colorWhite,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  border: Border.all(color: MyColor.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: MyColor.primaryColor,
                          child: Text("${index + 1}", style: regularSmall.copyWith(color: Colors.white)),
                        ),
                        spaceSide(Dimensions.space10),
                        Expanded(child: Text(stop['name'] ?? '', style: boldMediumLarge)),
                      ],
                    ),
                    spaceDown(Dimensions.space15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.arriveAtStop(stop['id']),
                            child: Text("Arrive"),
                          ),
                        ),
                        spaceSide(Dimensions.space10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => controller.departStop(stop['id']),
                            style: ElevatedButton.styleFrom(backgroundColor: MyColor.primaryColor),
                            child: Text("Depart", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

