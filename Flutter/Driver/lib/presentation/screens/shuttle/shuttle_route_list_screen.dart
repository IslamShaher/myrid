import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/shuttle/shuttle_driver_controller.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_spacer.dart';

class ShuttleRouteListScreen extends StatefulWidget {
  const ShuttleRouteListScreen({super.key});

  @override
  State<ShuttleRouteListScreen> createState() => _ShuttleRouteListScreenState();
}

class _ShuttleRouteListScreenState extends State<ShuttleRouteListScreen> {
  @override
  void initState() {
    Get.find<ShuttleDriverController>().loadRoutes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Shuttle Routes"),
      body: GetBuilder<ShuttleDriverController>(
        builder: (controller) {
          if (controller.isLoading) {
            return Center(child: CircularProgressIndicator(color: MyColor.primaryColor));
          }
          
          if (controller.routes.isEmpty) {
            return Center(child: Text("No shuttle routes assigned."));
          }

          return ListView.builder(
            padding: EdgeInsets.all(Dimensions.space15),
            itemCount: controller.routes.length,
            itemBuilder: (context, index) {
              var route = controller.routes[index];
              return Container(
                margin: EdgeInsets.only(bottom: Dimensions.space10),
                padding: EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.colorWhite,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(route['name'] ?? '', style: boldLarge),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: MyColor.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(route['code'] ?? '', style: regularDefault.copyWith(color: MyColor.primaryColor)),
                        ),
                      ],
                    ),
                    spaceDown(Dimensions.space10),
                    Text("Stops: ${route['stops']?.length ?? 0}", style: regularDefault),
                    spaceDown(Dimensions.space15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.startTrip(route['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyColor.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Start Trip", style: boldDefault.copyWith(color: Colors.white)),
                      ),
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

