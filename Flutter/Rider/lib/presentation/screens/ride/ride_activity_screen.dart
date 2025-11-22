import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_strings.dart';
import 'package:ovorideuser/data/controller/ride/all_ride_controller.dart';
import 'package:ovorideuser/data/repo/ride/ride_repo.dart';
import 'package:ovorideuser/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovorideuser/presentation/screens/ride/section/all_rides_list_section.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RideActivityScreen extends StatefulWidget {
  final VoidCallback? onBackPress;
  const RideActivityScreen({super.key, this.onBackPress});

  @override
  State<RideActivityScreen> createState() => _RideActivityScreenState();
}

class _RideActivityScreenState extends State<RideActivityScreen> with SingleTickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  static const int totalTabls = 6;

  void scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      if (Get.find<AllRideController>().hasNext()) {
        Get.find<AllRideController>().getAllRide();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Get.put(RideRepo(apiClient: Get.find()));
    var controller = Get.put(AllRideController(repo: Get.find()));
    controller.tabController = TabController(length: totalTabls, vsync: this, initialIndex: controller.selectedTab);

    WidgetsBinding.instance.addPostFrameCallback((time) {
      controller.initialData(
        shouldLoading: true,
        tabID: controller.selectedTab,
        rideType: "${Get.arguments ?? ""}",
      );
      scrollController.addListener(scrollListener);
    });
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.secondaryScreenBgColor,
      appBar: CustomAppBar(
        title: (Get.arguments ?? "") == "" ? MyStrings.activity.tr : (Get.arguments == 1 ? MyStrings.city.tr : MyStrings.interCity.tr),
        backBtnPress: () {
          if (Get.currentRoute == RouteHelper.dashboard) {
            if (widget.onBackPress != null) {
              widget.onBackPress?.call();
            }
          } else {
            Get.back();
          }
        },
      ),
      body: GetBuilder<AllRideController>(
        builder: (controller) {
          return Column(
            children: [
              Container(
                color: MyColor.colorWhite,
                child: DefaultTabController(
                  length: totalTabls,
                  initialIndex: controller.selectedTab,
                  child: Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: MyColor.colorWhite),
                          ),
                        ),
                        child: TabBar(
                          controller: controller.tabController,
                          tabAlignment: TabAlignment.start,
                          dividerColor: MyColor.borderColor,
                          indicator: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: MyColor.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          indicatorSize: TabBarIndicatorSize.label,
                          isScrollable: true,
                          labelColor: MyColor.primaryColor,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          unselectedLabelColor: MyColor.colorBlack,
                          physics: const BouncingScrollPhysics(),
                          onTap: (i) {
                            controller.changeTab(i);
                          },
                          tabs: [
                            Tab(text: MyStrings.allRides.tr),
                            Tab(text: MyStrings.activeRide.tr),
                            Tab(text: MyStrings.newRide.tr),
                            Tab(text: MyStrings.runningRide.tr),
                            Tab(text: MyStrings.completedRides.tr),
                            Tab(text: MyStrings.canceledRides.tr),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.space10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space10,
                  ),
                  child: AllRidesListSection(
                    scrollController: scrollController,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
