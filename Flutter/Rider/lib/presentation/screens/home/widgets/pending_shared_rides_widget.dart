import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/shuttle/shared_ride_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ovorideuser/environment.dart';
import 'package:intl/intl.dart';

class PendingSharedRidesWidget extends StatelessWidget {
  const PendingSharedRidesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SharedRideController>(
      builder: (controller) {
        if (controller.isLoadingPendingRides) {
          return Container(
            padding: EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: MyColor.getCardBgColor(),
              borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              boxShadow: MyColor.getCardShadow(),
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (controller.pendingRides.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pending Shared Rides",
              style: boldLarge.copyWith(color: MyColor.getHeadingTextColor()),
            ),
            spaceDown(Dimensions.space10),
            ...controller.pendingRides.map((ride) {
              return Container(
                margin: EdgeInsets.only(bottom: Dimensions.space10),
                padding: EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.getCardBgColor(),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  boxShadow: MyColor.getCardShadow(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: MyColor.getPrimaryColor()),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Ride #${ride['uid'] ?? ride['id']}",
                            style: boldDefault,
                          ),
                        ),
                      ],
                    ),
                    spaceDown(Dimensions.space10),
                    Text(
                      "${ride['pickup_location'] ?? ''} → ${ride['destination'] ?? ''}",
                      style: regularDefault,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Map for pending ride (only shows Rider 1's route)
                    if (ride['pickup_latitude'] != null && ride['pickup_longitude'] != null &&
                        ride['destination_latitude'] != null && ride['destination_longitude'] != null) ...[
                      spaceDown(Dimensions.space10),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                          border: Border.all(color: MyColor.neutral300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                          child: _PendingRideMapWidget(
                            pickupLat: ride['pickup_latitude'] is num 
                                ? (ride['pickup_latitude'] as num).toDouble()
                                : (double.tryParse(ride['pickup_latitude']?.toString() ?? '') ?? 0.0),
                            pickupLng: ride['pickup_longitude'] is num 
                                ? (ride['pickup_longitude'] as num).toDouble()
                                : (double.tryParse(ride['pickup_longitude']?.toString() ?? '') ?? 0.0),
                            destLat: ride['destination_latitude'] is num 
                                ? (ride['destination_latitude'] as num).toDouble()
                                : (double.tryParse(ride['destination_latitude']?.toString() ?? '') ?? 0.0),
                            destLng: ride['destination_longitude'] is num 
                                ? (ride['destination_longitude'] as num).toDouble()
                                : (double.tryParse(ride['destination_longitude']?.toString() ?? '') ?? 0.0),
                          ),
                        ),
                      ),
                    ],
                    
                    if (ride['is_scheduled'] == true && ride['scheduled_time'] != null) ...[
                      spaceDown(Dimensions.space8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: MyColor.neutral700),
                          SizedBox(width: 4),
                          Text(
                            "Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(ride['scheduled_time']))}",
                            style: regularSmall.copyWith(color: MyColor.neutral700),
                          ),
                        ],
                      ),
                    ],
                    spaceDown(Dimensions.space8),
                    Text(
                      "Waiting for a match...",
                      style: regularSmall.copyWith(
                        color: MyColor.getPrimaryColor(),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

// Simple map widget for pending rides (single route)
class _PendingRideMapWidget extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;

  const _PendingRideMapWidget({
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<_PendingRideMapWidget> createState() => _PendingRideMapWidgetState();
}

class _PendingRideMapWidgetState extends State<_PendingRideMapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    _loadRoute();
  }

  void _initializeMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: "Pickup"),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.destLat, widget.destLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Destination"),
      ),
    };
  }

  Future<void> _loadRoute() async {
    try {
      final PolylinePoints polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(widget.pickupLat, widget.pickupLng),
          destination: PointLatLng(widget.destLat, widget.destLng),
          mode: TravelMode.driving,
        ),
        googleApiKey: Environment.mapKey,
      );

      if (result.points.isNotEmpty) {
        List<LatLng> points = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        _polylines[const PolylineId('route')] = Polyline(
          polylineId: const PolylineId('route'),
          color: MyColor.getPrimaryColor(),
          points: points,
          width: 5,
        );
      }
    } catch (e) {
      print('Error loading route: $e');
    }

    setState(() {
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _fitBounds();
    });
  }

  void _fitBounds() {
    if (_controller == null) return;

    double minLat = widget.pickupLat < widget.destLat ? widget.pickupLat : widget.destLat;
    double maxLat = widget.pickupLat > widget.destLat ? widget.pickupLat : widget.destLat;
    double minLng = widget.pickupLng < widget.destLng ? widget.pickupLng : widget.destLng;
    double maxLng = widget.pickupLng > widget.destLng ? widget.pickupLng : widget.destLng;

    _controller!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.pickupLat, widget.pickupLng),
            zoom: 12,
          ),
          markers: _markers,
          polylines: Set<Polyline>.of(_polylines.values),
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            Future.delayed(const Duration(milliseconds: 800), () {
              _fitBounds();
            });
          },
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

