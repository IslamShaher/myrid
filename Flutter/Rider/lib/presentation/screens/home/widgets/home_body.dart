import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/controller/shuttle/shuttle_controller.dart';
import 'package:ovorideuser/presentation/screens/home/section/ride_create_form.dart';
import 'package:ovorideuser/presentation/screens/home/section/ride_service_section.dart';
import 'package:ovorideuser/presentation/screens/home/section/shuttle_route_list.dart';
import '../../../../core/utils/dimensions.dart';
import '../../../../core/utils/my_color.dart';
import '../../../../core/utils/my_strings.dart';
import '../../../../core/utils/style.dart';
import '../../../../core/utils/util.dart';
import '../../../components/divider/custom_spacer.dart';

class HomeBody extends StatefulWidget {
  final HomeController controller;
  const HomeBody({super.key, required this.controller});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  bool isShuttleMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle Switch
        Container(
          margin: EdgeInsets.only(bottom: Dimensions.space20),
          padding: EdgeInsets.all(Dimensions.space5),
          decoration: BoxDecoration(
            color: MyColor.getCardBgColor(),
            borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            boxShadow: MyUtils.getCardShadow(),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isShuttleMode = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.space10),
                    decoration: BoxDecoration(
                      color: !isShuttleMode ? MyColor.primaryColor : MyColor.transparentColor,
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    ),
                    child: Center(
                      child: Text(
                        "Ride",
                        style: boldDefault.copyWith(
                          color: !isShuttleMode ? MyColor.colorWhite : MyColor.getTextColor(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isShuttleMode = true;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.space10),
                    decoration: BoxDecoration(
                      color: isShuttleMode ? MyColor.primaryColor : MyColor.transparentColor,
                      borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    ),
                    child: Center(
                      child: Text(
                        "Shuttle",
                        style: boldDefault.copyWith(
                          color: isShuttleMode ? MyColor.colorWhite : MyColor.getTextColor(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // SERVICES / SHUTTLE LIST
        if (isShuttleMode) ...[
          ShuttleRouteList(),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.controller.isLoading == false && widget.controller.appServicesList.isEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: MyColor.getCardBgColor(),
                    boxShadow: MyUtils.getCardShadow(),
                    borderRadius: BorderRadius.circular(Dimensions.moreRadius),
                  ),
                  width: double.infinity,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: Dimensions.space16, vertical: Dimensions.space16),
                  child: Center(
                    child: Text(
                      MyStrings.noServiceAvailable.tr,
                      style: regularDefault.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                RideServiceSection(),
              ],
            ],
          ),
        ],
        
        spaceDown(Dimensions.space20),
        
        // RIDE FORM (Only show if not shuttle mode or if we want to reuse it for shuttle later)
        // For now, keeping it for both but we might want to hide it for shuttle if the flow is different
        if (!isShuttleMode) ...[
          Container(
            decoration: BoxDecoration(
              color: MyColor.getCardBgColor(),
              boxShadow: MyUtils.getCardShadow(),
              borderRadius: BorderRadius.circular(Dimensions.moreRadius),
            ),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space16,
              vertical: Dimensions.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RideCreateForm(),
                spaceDown(Dimensions.space15),
              ],
            ),
          ),
        ] else ...[
           // Shuttle specific action button could go here
           GetBuilder<ShuttleController>(builder: (shuttleController) {
             return shuttleController.selectedRoute != null ? 
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    shuttleController.bookShuttle();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColor.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: Dimensions.space15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.mediumRadius)),
                  ),
                  child: Text("Book Shuttle", style: boldLarge.copyWith(color: MyColor.colorWhite)),
                ),
              ) : SizedBox.shrink();
           }),
        ],
        
        spaceDown(Dimensions.space50 + 20),
      ],
    );
  }
}
