import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/data/controller/shuttle/shuttle_controller.dart';
import 'package:ovorideuser/data/repo/home/home_repo.dart';
import 'package:ovorideuser/data/repo/shuttle/shuttle_repo.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/screens/dashboard/dashboard_background.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_app_bar.dart';
import 'package:ovorideuser/presentation/screens/home/widgets/home_body.dart';

import 'widgets/location_pickup_widget.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? dashBoardScaffoldKey;

  const HomeScreen({super.key, this.dashBoardScaffoldKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double appBarSize = 90.0;

  @override
  void initState() {
    Get.put(HomeRepo(apiClient: Get.find()));
    Get.put(AppLocationController());
    final controller = Get.put(
      HomeController(homeRepo: Get.find(), appLocationController: Get.find()),
    );
    Get.put(ShuttleRepo(apiClient: Get.find()));
    Get.put(ShuttleController(shuttleRepo: Get.find()));
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData(shouldLoad: true);
    });
  }

  void openDrawer() {
    if (widget.dashBoardScaffoldKey != null) {
      widget.dashBoardScaffoldKey?.currentState?.openEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return DashboardBackground(
          child: Scaffold(
            extendBody: true,
            backgroundColor: MyColor.transparentColor,
            extendBodyBehindAppBar: false,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(appBarSize),
              child: HomeScreenAppBar(
                controller: controller,
                openDrawer: openDrawer,
              ),
            ),
            body: RefreshIndicator(
              color: MyColor.primaryColor,
              backgroundColor: MyColor.colorWhite,
              onRefresh: () async {
                controller.initialData(shouldLoad: true);
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.space16),
                physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
                child: Column(
                  children: [
                    LocationPickUpHomeWidget(controller: controller),
                    spaceDown(Dimensions.space20),
                    HomeBody(controller: controller),
                    spaceDown(Dimensions.space20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
