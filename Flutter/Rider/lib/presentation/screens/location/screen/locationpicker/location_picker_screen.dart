import 'package:custom_marker_builder/custom_marker_builder.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/route/route.dart';
import 'package:ovorideuser/core/theme/light/light.dart';
import 'package:ovorideuser/core/utils/debouncer.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/core/utils/util.dart';
import 'package:ovorideuser/data/controller/home/home_controller.dart';
import 'package:ovorideuser/environment.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovorideuser/presentation/components/buttons/rounded_button.dart';
import 'package:ovorideuser/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/components/image/custom_svg_picture.dart';
import 'package:ovorideuser/presentation/components/text-form-field/location_pick_text_field.dart';
import 'package:ovorideuser/presentation/components/text/label_text.dart';
import '../../../../../core/utils/dimensions.dart';
import '../../../../../core/utils/helper.dart';
import '../../../../../core/utils/my_color.dart';
import '../../../../../core/utils/my_strings.dart';
import '../../../../../data/controller/location/select_location_controller.dart';
import '../../../../../data/repo/location/location_search_repo.dart';

class LocationPickerScreen extends StatefulWidget {
  final int pickupLocationForIndex;
  const LocationPickerScreen({super.key, required this.pickupLocationForIndex});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final GlobalKey _secondContainerKey = GlobalKey();
  double? _secondContainerHeight;
  TextEditingController searchLocationController = TextEditingController(text: '');
  int index = 0;
  Uint8List? pickUpIcon;
  Uint8List? destinationIcon;
  bool isSearching = false;
  bool isFirsTime = true;

  Marker? pickupInfoMarker;
  Marker? destinationInfoMarker;

  @override
  void initState() {
    index = widget.pickupLocationForIndex;
    printD(index);
    super.initState();
    Get.put(LocationSearchRepo(apiClient: Get.find()));
    var controller = Get.put(
      SelectLocationController(locationSearchRepo: Get.find(), selectedLocationIndex: index),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final RenderBox box = _secondContainerKey.currentContext?.findRenderObject() as RenderBox;
      final double height = box.size.height;
      setState(() => _secondContainerHeight = height);
      await loadMarker();
      controller.initialize();
    });
  }

  Future<void> _loadWidgetMarker(SelectLocationController controller) async {
    if (controller.mapController == null) return;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        LatLng pickupLatLng = controller.pickupLatlong;
        LatLng destinationLatLng = controller.destinationLatlong;
        if (controller.homeController.selectedLocations.length >= 2) {
          final pickUpBitMap = await CustomMapMarkerBuilder.fromWidget(
              context: context,
              marker: _buildInfoWidget(
                "Pickup",
                controller.homeController.selectedLocations[0].fullAddress ?? "",
              ));
          pickupInfoMarker = Marker(
            markerId: const MarkerId("pickup_location_2"),
            position: pickupLatLng,
            icon: pickUpBitMap,
            anchor: const Offset(-0.1, 1.0),
            onTap: () {
              Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0);
            },
          );

          final destinationBitMap = await CustomMapMarkerBuilder.fromWidget(
              context: context,
              marker: _buildInfoWidget(
                "Destination",
                controller.homeController.selectedLocations[1].fullAddress ?? "",
              ));
          destinationInfoMarker = Marker(
            markerId: const MarkerId("destination_location_2"),
            position: destinationLatLng,
            icon: destinationBitMap,
            anchor: const Offset(-0.1, 1.0),
            onTap: () {
              Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1);
            },
          );
        }
        setState(() {});
      });
    } catch (e) {
      printE(e);
    }
  }

  Future<void> loadMarker() async {
    searchLocationController.text = '';
    pickUpIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 150);
    destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
    setState(() {});
  }

  void changeIndex(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegionWidget(
      statusBarColor: MyColor.transparentColor,
      child: GetBuilder<SelectLocationController>(
        builder: (controller) => Scaffold(
          extendBody: true,
          extendBodyBehindAppBar: true,
          backgroundColor: MyColor.screenBgColor,
          resizeToAvoidBottomInset: true,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              if (controller.isLoading && controller.isLoadingFirstTime)
                const SizedBox.expand()
              else
                Stack(
                  children: [
                    SizedBox(
                      height: context.height - (_secondContainerHeight ?? 0),
                      child: GoogleMap(
                        zoomGesturesEnabled: true,
                        trafficEnabled: false,
                        indoorViewEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapToolbarEnabled: false,
                        liteModeEnabled: false,
                        compassEnabled: false,
                        mapType: MapType.normal,
                        minMaxZoomPreference: const MinMaxZoomPreference(0, 100),
                        markers: {
                          Marker(
                            markerId: const MarkerId("pickup_location"),
                            position: LatLng(
                              controller.pickupLatlong.latitude,
                              controller.pickupLatlong.longitude,
                            ),
                            icon: pickUpIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.bytes(pickUpIcon!, height: 45, width: 47),
                            onTap: () => Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 0),
                          ),
                          Marker(
                            markerId: const MarkerId("destination_location"),
                            position: LatLng(
                              controller.destinationLatlong.latitude,
                              controller.destinationLatlong.longitude,
                            ),
                            icon: destinationIcon == null ? BitmapDescriptor.defaultMarker : BitmapDescriptor.bytes(destinationIcon!, height: 45, width: 45),
                            onTap: () => Get.toNamed(RouteHelper.editLocationPickUpScreen, arguments: 1),
                          ),
                          if (pickupInfoMarker != null) pickupInfoMarker!,
                          if (destinationInfoMarker != null) destinationInfoMarker!
                        },
                        initialCameraPosition: CameraPosition(
                          target: controller.getInitialTargetLocationForMap(pickupLocationForIndex: widget.pickupLocationForIndex),
                          zoom: Environment.mapDefaultZoom,
                          bearing: 20,
                          tilt: 0,
                        ),
                        onMapCreated: (googleMapController) {
                          controller.mapController = googleMapController;
                          _loadWidgetMarker(controller);
                        },
                        onCameraIdle: () => _loadWidgetMarker(controller),
                        polylines: Set<Polyline>.of(controller.polylines.values),
                        style: googleMapLightStyleJson,
                      ),
                    ),
                  ],
                ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: controller.isLoading ? CircularProgressIndicator(color: MyColor.getPrimaryColor()) : const SizedBox.shrink(),
                ),
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
          bottomSheet: buildConfirmDestination(pickupLocationForIndex: widget.pickupLocationForIndex),
        ),
      ),
    );
  }

  Widget _buildInfoWidget(String title, String address) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        border: Border.all(
          color: title == "Pickup" ? MyColor.greenSuccessColor : MyColor.getPrimaryColor(),
          width: 1,
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: IntrinsicWidth(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              color: title == "Pickup" ? MyColor.greenSuccessColor : MyColor.getPrimaryColor(),
              child: Icon(title == "Pickup" ? Icons.my_location : Icons.location_on, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                address.isEmpty ? "No address available" : address,
                style: const TextStyle(fontSize: 5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget buildConfirmDestination({required int pickupLocationForIndex}) {
    final myDeBouncer = MyDeBouncer(delay: const Duration(milliseconds: 600));

    return GetBuilder<SelectLocationController>(
      builder: (controller) {
        return AnimatedContainer(
          key: _secondContainerKey,
          duration: const Duration(milliseconds: 600),
          height: null,
          padding: const EdgeInsets.all(Dimensions.space16),
          decoration: BoxDecoration(
            color: MyColor.getCardBgColor(),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: MyColor.colorGrey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                spaceDown(Dimensions.space10),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsetsDirectional.symmetric(vertical: Dimensions.space3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Dimensions.mediumRadius,
                    ),
                  ),
                  child: GetBuilder<HomeController>(
                    builder: (homeController) {
                      return Container(
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LabelText(text: MyStrings.pickUpLocation),
                            spaceDown(Dimensions.space5),
                            LocationPickTextField(
                              fillColor: controller.selectedLocationIndex == 0 ? MyColor.colorWhite : MyColor.textFieldBgColor,
                              shadowColor: controller.selectedLocationIndex == 0 ? MyColor.primaryColor.withValues(alpha: 0.2) : MyColor.colorGrey.withValues(alpha: 0.1),
                              labelText: MyStrings.pickUpLocation,
                              controller: controller.pickUpController,
                              onTap: () {
                                controller.changeIndex(0);
                              },
                              prefixIcon: Padding(
                                padding: EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                                child: CustomSvgPicture(
                                  image: MyIcons.currentLocation,
                                  color: MyColor.primaryColor,
                                  height: Dimensions.space35,
                                ),
                              ),
                              onSubmit: () {},
                              onChanged: (text) {
                                if (isFirsTime == true) {
                                  isFirsTime = false;
                                  setState(() {});
                                }
                                myDeBouncer.run(() {
                                  controller.searchYourAddress(
                                    locationName: text,
                                  );
                                });
                              },
                              hintText: MyStrings.pickUpLocation.tr,
                              radius: Dimensions.moreRadius,
                              inputAction: TextInputAction.done,
                              suffixIcon: Padding(
                                padding: EdgeInsetsDirectional.only(end: Dimensions.space5),
                                child: IconButton(
                                  onPressed: () async {
                                    controller.clearTextFiled(0);
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    size: Dimensions.space20,
                                    color: MyColor.bodyTextColor,
                                  ),
                                ),
                              ),
                            ),
                            spaceDown(Dimensions.space15),
                            LabelText(text: MyStrings.destination),
                            spaceDown(Dimensions.space5),
                            LocationPickTextField(
                              fillColor: controller.selectedLocationIndex == 1 ? MyColor.colorWhite : MyColor.textFieldBgColor,
                              shadowColor: controller.selectedLocationIndex == 1 ? MyColor.primaryColor.withValues(alpha: 0.2) : MyColor.colorGrey.withValues(alpha: 0.1),
                              inputAction: TextInputAction.done,
                              labelText: MyStrings.whereToGo,
                              controller: controller.destinationController,
                              onTap: () {
                                controller.changeIndex(1);
                              },
                              onChanged: (text) {
                                if (isFirsTime == true) {
                                  isFirsTime = false;
                                  setState(() {});
                                }
                                myDeBouncer.run(() {
                                  controller.searchYourAddress(
                                    locationName: text,
                                  );
                                });
                              },
                              hintText: MyStrings.pickUpDestination.tr,
                              radius: Dimensions.mediumRadius,
                              prefixIcon: Padding(
                                padding: EdgeInsetsDirectional.only(start: Dimensions.space12, end: Dimensions.space2),
                                child: CustomSvgPicture(
                                  image: MyIcons.location,
                                  color: MyColor.primaryColor,
                                  height: Dimensions.space35,
                                ),
                              ),
                              suffixIcon: Padding(
                                padding: EdgeInsetsDirectional.only(end: Dimensions.space5),
                                child: IconButton(
                                  onPressed: () async {
                                    controller.clearTextFiled(1);
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    size: Dimensions.space20,
                                    color: MyColor.bodyTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                //show search results
                controller.isSearched && controller.allPredictions.isEmpty
                    ? CustomLoader(isPagination: true)
                    : GestureDetector(
                        onTap: () {},
                        child: SizedBox(
                          height: controller.allPredictions.isNotEmpty ? context.height * .3 : 0,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(vertical: Dimensions.space20),
                            itemCount: controller.allPredictions.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              var item = controller.allPredictions[index];
                              return InkWell(
                                radius: Dimensions.defaultRadius,
                                onTap: () async {
                                  await controller.getLangAndLatFromMap(item).whenComplete(() {
                                    controller.pickLocation();
                                    controller.updateSelectedAddressFromSearch(
                                      item.description ?? '',
                                    );
                                    controller.animateMapCameraPosition();
                                  });

                                  MyUtils.closeKeyboard();
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: const EdgeInsetsDirectional.symmetric(
                                    vertical: Dimensions.space15,
                                    horizontal: Dimensions.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.mediumRadius,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: Dimensions.space20,
                                        color: MyColor.bodyTextColor,
                                      ),
                                      spaceSide(Dimensions.space10),
                                      Expanded(
                                        child: Text(
                                          "${item.description}",
                                          style: regularDefault.copyWith(
                                            color: MyColor.colorBlack,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                spaceDown(Dimensions.space15),
                //Confirm
                RoundedButton(
                  text: MyStrings.confirmLocation,
                  press: () {
                    Get.back(result: 'true');
                  },
                  isOutlined: false,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
