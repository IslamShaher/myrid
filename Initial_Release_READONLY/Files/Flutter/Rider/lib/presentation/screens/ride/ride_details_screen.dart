import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_animation.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/data/controller/map/ride_map_controller.dart';
import 'package:ovorideuser/data/controller/pusher/pusher_ride_controller.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovorideuser/data/repo/message/message_repo.dart';
import 'package:ovorideuser/data/repo/ride/ride_repo.dart';
import 'package:ovorideuser/presentation/screens/ride/widget/poly_line_map.dart';
import 'package:ovorideuser/presentation/screens/ride/widget/ride_details_bottom_sheet_widget.dart';
import 'package:toastification/toastification.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;

  const RideDetailsScreen({super.key, required this.rideId});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  DraggableScrollableController draggableScrollableController = DraggableScrollableController();

  @override
  void initState() {
    Get.put(RideRepo(apiClient: Get.find()));
    Get.put(RideMapController());
    Get.put(MessageRepo(apiClient: Get.find()));
    Get.put(RideMessageController(repo: Get.find()));
    final controller = Get.put(RideDetailsController(repo: Get.find(), mapController: Get.find()));
    Get.put(PusherRideController(apiClient: Get.find(), rideMessageController: Get.find(), rideDetailsController: Get.find(), rideID: widget.rideId));
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controller.initialData(widget.rideId);
      Get.find<PusherRideController>().ensureConnection();
    });
  }

  @override
  void dispose() {
    super.dispose();
    Get.find<PusherRideController>().dispose();
  }

  Future _zoomBasedOnExtent(double extent) async {
    var controller = Get.find<RideMapController>();
    var polylinePoints = controller.polylineCoordinates;
    if (controller.mapController == null || polylinePoints.isEmpty) return;

    controller.fitPolylineBounds(polylinePoints);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RideDetailsController>(
      builder: (controller) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (bool didPop, d) async {
              if (didPop) return;
              printE(Get.previousRoute);
              Get.back();
              toastification.dismissAll();
            },
            child: Scaffold(
              extendBody: true,
              body: Stack(
                children: [
                  //Map
                  controller.isLoading
                      ? SizedBox(
                          height: context.height,
                          width: double.infinity,
                          child: LottieBuilder.asset(
                            MyAnimation.rideDetailsLoadingAnimation,
                          ),
                        )
                      : SizedBox(
                          height: context.isTablet ? context.height : context.height / 1.3,
                          child: const PolyLineMapScreen(),
                        ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.space12),
                        child: IconButton(
                          style: IconButton.styleFrom(backgroundColor: MyColor.colorWhite),
                          color: MyColor.colorBlack,
                          onPressed: () => Get.back(result: true),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              bottomSheet: controller.isLoading
                  ? Container(
                      color: MyColor.colorWhite,
                      height: context.height / 4,
                      child: const SizedBox.shrink(),
                    )
                  : AnimatedPadding(
                      padding: EdgeInsetsDirectional.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.decelerate,
                      child: DraggableScrollableSheet(
                        controller: draggableScrollableController,
                        snap: true,
                        shouldCloseOnMinExtent: true,
                        expand: false,
                        initialChildSize: 0.4, // initial height (percentage of screen height)
                        minChildSize: 0.4, // minimum height when fully collapsed
                        maxChildSize: 0.8, // maximum height when fully expanded
                        snapSizes: [0.4, 0.5, 0.7, 0.8],
                        snapAnimationDuration: Duration(milliseconds: 500),
                        builder: (context, scrollController) {
                          return NotificationListener<DraggableScrollableNotification>(
                            onNotification: (notification) {
                              // printX("Notification: ${notification.extent}");
                              _zoomBasedOnExtent(notification.extent);
                              return true;
                            },
                            child: RideDetailsBottomSheetWidget(
                              scrollController: scrollController,
                              draggableScrollableController: draggableScrollableController,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
