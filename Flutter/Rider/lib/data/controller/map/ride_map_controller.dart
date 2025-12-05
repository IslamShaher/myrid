import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/app_status.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';
import 'package:ovorideuser/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/helper/string_format_helper.dart';
import 'package:ovorideuser/core/utils/helper.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_images.dart';
import 'package:ovorideuser/environment.dart';
import 'package:ovorideuser/presentation/packages/polyline_animation/polyline_animation_v1.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {
  bool isLoading = false;
  final PolylineAnimator animator = PolylineAnimator();

  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);

  LatLng? _previousDriverLatLng;
  LatLng driverLatLng = const LatLng(0, 0);

  /// rotation for driver marker in degrees
  double driverRotation = 0.0;

  Map<PolylineId, Polyline> polylines = {};

  // Map controller used by UI to set controller reference
  GoogleMapController? mapController;

  // Animation controller for interpolating marker movement
  late final AnimationController _animationController;

  @override
  void onInit() {
    super.onInit();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  }

  @override
  void onClose() {
    _animationController.dispose();
    super.onClose();
  }

  /// Public method to receive driver location updates
  void updateDriverLocation({required LatLng latLng, required bool isRunning}) {
    printX('ride map update $latLng, $isRunning');

    // If this is the first position - just set it
    if (driverLatLng.latitude == 0 && driverLatLng.longitude == 0) {
      _previousDriverLatLng = latLng;
      driverLatLng = latLng;
      getCurrentDriverAddress();
      update();
      return;
    }

    // Animate marker from current location to new location
    _animateMarker(latLng);
    getCurrentDriverAddress();
  }

  void _animateMarker(LatLng newPosition) {
    final oldPosition = _previousDriverLatLng ?? driverLatLng;
    _previousDriverLatLng = oldPosition;

    // stop any previous animation listeners
    _animationController.stop();
    _animationController.reset();

    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    final latTween = Tween<double>(begin: oldPosition.latitude, end: newPosition.latitude);
    final lngTween = Tween<double>(begin: oldPosition.longitude, end: newPosition.longitude);

    void listener() {
      final lat = latTween.evaluate(animation);
      final lng = lngTween.evaluate(animation);
      final position = LatLng(lat, lng);

      // update rotation using last previous and current interpolated position
      driverRotation = _getRotation(
        oldPosition.latitude,
        oldPosition.longitude,
        position.latitude,
        position.longitude,
      );

      // update actual marker position used by UI
      driverLatLng = position;
      update(); // rebuild markers in the UI

      // Optionally follow the driver with camera
      // mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }

    // remove previous listeners
    _animationController.removeListener(() {});
    _animationController.addListener(listener);

    _animationController.forward().whenComplete(() {
      // ensure final exact position is set and rotation updated
      driverLatLng = newPosition;
      driverRotation = _getRotation(
        oldPosition.latitude,
        oldPosition.longitude,
        newPosition.latitude,
        newPosition.longitude,
      );
      update();

      // update previous position for next animation
      _previousDriverLatLng = newPosition;
      // remove the listener to avoid duplicate calls
      _animationController.removeListener(listener);
    });
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  /// Calculates bearing (degrees) from (lat1, lon1) to (lat2, lon2)
  double _getRotation(double lat1, double lon1, double lat2, double lon2) {
    // convert to radians
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final deltaLambda = _toRadians(lon2 - lon1);

    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final bearing = atan2(y, x);
    var bearingDegrees = (bearing * 180.0 / pi + 360.0) % 360.0; // normalize 0-360

    return bearingDegrees;
  }

  void loadMap({
    required LatLng pickup,
    required LatLng destination,
    bool? isRunning = false,
  }) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    getPolyLinePoints().then((data) {
      polylineCoordinates = data;
      generatePolyLineFromPoints(data);
      fitPolylineBounds(data);
      if (Get.isRegistered<RideDetailsController>()) {
        if (![AppStatus.RIDE_RUNNING, AppStatus.RIDE_ACTIVE, AppStatus.RIDE_COMPLETED].contains(Get.find<RideDetailsController>().ride.status)) {
          // animator.animatePolyline(
          //   data,
          //   'polyline_id',
          //   MyColor.colorOrange,
          //   MyColor.primaryColor,
          //   polylines,
          //   () {
          //     if (Get.isRegistered<RideDetailsController>()) {
          //       if (![AppStatus.RIDE_RUNNING, AppStatus.RIDE_ACTIVE, AppStatus.RIDE_COMPLETED].contains(Get.find<RideDetailsController>().ride.status)) {
          //         update();
          //       }
          //     }
          //   },
          // );
        }
      }
    });

    await setCustomMarkerIcon();
  }

  void animateMapCameraPosition() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
          zoom: Environment.mapDefaultZoom,
        ),
      ),
    );
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    isLoading = true;
    update();
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: MyColor.getPrimaryColor(),
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    isLoading = false;
    update();
  }

  List<LatLng> polylineCoordinates = [];
  Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
        destination: PointLatLng(
          destinationLatLng.latitude,
          destinationLatLng.longitude,
        ),
        mode: TravelMode.driving,
      ),
      googleApiKey: Environment.mapKey,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      printX(result.errorMessage);
    }
    return polylineCoordinates;
  }

  // icons
  Uint8List? pickupIcon;
  Uint8List? destinationIcon;
  Uint8List? driverIcon;

  Set<Marker> getMarkers({
    required LatLng pickup,
    required LatLng destination,
    LatLng? maybeDriverLatLng,
  }) {
    // prefer currently animated driverLatLng
    final mkDriverLatLng = maybeDriverLatLng ?? driverLatLng;

    final markers = <Marker>{};

    if (mkDriverLatLng.latitude != 0 || mkDriverLatLng.longitude != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_marker_id'),
          position: mkDriverLatLng,
          rotation: driverRotation,
          anchor: const Offset(0.5, 0.5),
          icon: driverIcon == null
              ? BitmapDescriptor.defaultMarker
              : BitmapDescriptor.bytes(
                  driverIcon!,
                  width: 30,
                  height: 45,
                  // bitmapScaling: MapBitmapScaling.auto,
                ),
          infoWindow: InfoWindow(title: driverAddress, onTap: () {}),
          onTap: () async {
            getCurrentDriverAddress();
            printX('Driver current position $mkDriverLatLng');
            printX('Driver current address $driverAddress');
          },
        ),
      );
    }

    // pickup
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_marker_id'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: pickupIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                pickupIcon!,
                height: 45,
                width: 45,
                // bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () async {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
                zoom: Environment.mapDefaultZoom,
              ),
            ),
          );
        },
      ),
    );

    // destination
    markers.add(
      Marker(
        markerId: const MarkerId('destination_marker_id'),
        position: LatLng(destination.latitude, destination.longitude),
        icon: destinationIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                destinationIcon!,
                height: 45,
                width: 45,
                // bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () async {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(destination.latitude, destination.longitude),
                zoom: Environment.mapDefaultZoom,
              ),
            ),
          );
        },
      ),
    );

    return markers;
  }

  Future<void> setCustomMarkerIcon() async {
    pickupIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerPickUpIcon, 150);
    destinationIcon = await Helper.getBytesFromAsset(MyIcons.mapMarkerIcon, 150);
    driverIcon = await Helper.getBytesFromAsset(MyImages.mapDriverMarker, 80);
    update();
  }

  String driverAddress = 'Loading...';

  Future<void> getCurrentDriverAddress() async {
    try {
      final List<Placemark> placeMark = await placemarkFromCoordinates(
        driverLatLng.latitude,
        driverLatLng.longitude,
      );
      driverAddress = "";
      driverAddress = "${placeMark[0].street} ${placeMark[0].subThoroughfare} ${placeMark[0].thoroughfare},${placeMark[0].subLocality},${placeMark[0].locality},${placeMark[0].country}";
      update();
      printX('appLocations position $driverAddress');
    } catch (e) {
      printX('Error in getting position: $e');
    }
  }

  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    setMapFitToTour(Set<Polyline>.of(polylines.values));
  }

  void setMapFitToTour(Set<Polyline> p) {
    if (p.isEmpty) return;

    double minLat = p.first.points.first.latitude;
    double minLong = p.first.points.first.longitude;
    double maxLat = p.first.points.first.latitude;
    double maxLong = p.first.points.first.longitude;
    for (var poly in p) {
      for (var point in poly.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLong) minLong = point.longitude;
        if (point.longitude > maxLong) maxLong = point.longitude;
      }
    }
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong)),
        30,
      ),
    );
  }
}
