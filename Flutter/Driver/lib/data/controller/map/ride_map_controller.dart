import 'dart:typed_data';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovoride_driver/core/utils/app_status.dart';
import 'package:ovoride_driver/core/utils/helper.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_icons.dart';
import 'package:ovoride_driver/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovoride_driver/environment.dart';
import 'package:ovoride_driver/presentation/packages/polyline_animation/polyline_animation_v1.dart';

class RideMapController extends GetxController {
  bool isLoading = false;
  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);
  Map<PolylineId, Polyline> polylines = {};
  final PolylineAnimator animator = PolylineAnimator();

  void loadMap({required LatLng pickup, required LatLng destination}) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    getPolyLinePoints().then((data) {
      polylineCoordinates = data;
      generatePolyLineFromPoints(data);
      fitPolylineBounds(data);
      if (Get.isRegistered<RideDetailsController>()) {
        if (![
          AppStatus.RIDE_RUNNING,
          AppStatus.RIDE_ACTIVE,
          AppStatus.RIDE_COMPLETED,
        ].contains(Get.find<RideDetailsController>().ride.status)) {
          animator.animatePolyline(
            data,
            'polyline_id',
            MyColor.colorOrange,
            MyColor.primaryColor,
            polylines,
            () {
              if (Get.isRegistered<RideDetailsController>()) {
                if (![
                  AppStatus.RIDE_RUNNING,
                  AppStatus.RIDE_ACTIVE,
                  AppStatus.RIDE_COMPLETED,
                ].contains(Get.find<RideDetailsController>().ride.status)) {
                  update();
                }
              }
            },
          );
        }
      }
    });
    await setCustomMarkerIcon();
  }

  GoogleMapController? mapController;
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
      color: MyColor.primaryColor,
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
    PolylinePoints polylinePoints = PolylinePoints(apiKey: Environment.mapKey);
    // Create Routes API request
    RoutesApiRequest request = RoutesApiRequest(
      origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
      destination: PointLatLng(
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      ),
      travelMode: TravelMode.driving,
      routingPreference: RoutingPreference.trafficAware,
    );

    // Get route using Routes API
    RoutesApiResponse response = await polylinePoints.getRouteBetweenCoordinatesV2(request: request);

    if (response.primaryRoute?.polylinePoints case List<PointLatLng> points) {
      for (var point in points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    return polylineCoordinates;
  }

  Uint8List? pickupIcon;
  Uint8List? destinationIcon;

  Set<Marker> getMarkers({
    required LatLng pickup,
    required LatLng destination,
  }) {
    return {
      Marker(
        markerId: MarkerId('markerId${pickup.latitude}'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: pickupIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                pickupIcon!,
                height: 40,
                width: 40,
                bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pickup.latitude, pickup.longitude),
                zoom: 20,
              ),
            ),
          );
        },
      ),
      Marker(
        markerId: MarkerId('markerId${destination.latitude}'),
        position: LatLng(destination.latitude, destination.longitude),
        icon: destinationIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                destinationIcon!,
                height: 45,
                width: 45,
                bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(destination.latitude, destination.longitude),
                zoom: 20,
              ),
            ),
          );
        },
      ),
    };
  }

  Future<void> setCustomMarkerIcon({bool? isRunning}) async {
    pickupIcon = await Helper.getBytesFromAsset(
      MyIcons.mapMarkerPickUpIcon,
      150,
    );
    destinationIcon = await Helper.getBytesFromAsset(
      MyIcons.mapMarkerIcon,
      150,
    );
    update();
  }

  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    setMapFitToTour(Set<Polyline>.of(polylines.values));
  }

  void setMapFitToTour(Set<Polyline> p) {
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
        LatLngBounds(
          southwest: LatLng(minLat, minLong),
          northeast: LatLng(maxLat, maxLong),
        ),
        30,
      ),
    );
    // mapController?.moveCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong)), 30));
  }
}
