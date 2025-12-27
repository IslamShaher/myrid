import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ovorideuser/environment.dart';

class SharedRideMapWidget extends StatefulWidget {
  final double startLat1; // Rider 1
  final double startLng1;
  final double endLat1;
  final double endLng1;
  final double startLat2; // You (Rider 2)
  final double startLng2;
  final double endLat2;
  final double endLng2;
  final List<String>? sequence; // e.g., ['S1', 'S2', 'E1', 'E2']

  const SharedRideMapWidget({
    super.key,
    required this.startLat1,
    required this.startLng1,
    required this.endLat1,
    required this.endLng1,
    required this.startLat2,
    required this.startLng2,
    required this.endLat2,
    required this.endLng2,
    this.sequence,
  });

  @override
  State<SharedRideMapWidget> createState() => _SharedRideMapWidgetState();
}

class _SharedRideMapWidgetState extends State<SharedRideMapWidget> {
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
      // Rider 1 pickup - violet
      Marker(
        markerId: const MarkerId('S1'),
        position: LatLng(widget.startLat1, widget.startLng1),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(title: "Rider 1 Pickup"),
      ),
      // Rider 1 dropoff - violet
      Marker(
        markerId: const MarkerId('E1'),
        position: LatLng(widget.endLat1, widget.endLng1),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: const InfoWindow(title: "Rider 1 Dropoff"),
      ),
      // Rider 2 (You) pickup - orange (different color to highlight)
      Marker(
        markerId: const MarkerId('S2'),
        position: LatLng(widget.startLat2, widget.startLng2),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: "Your Pickup"),
      ),
      // Rider 2 (You) dropoff - orange (different color to highlight)
      Marker(
        markerId: const MarkerId('E2'),
        position: LatLng(widget.endLat2, widget.endLng2),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: "Your Dropoff"),
      ),
    };
  }

  Future<void> _loadRoute() async {
    if (widget.sequence == null || widget.sequence!.length != 4) {
      // Fallback: draw direct lines if no sequence
      setState(() => _isLoading = false);
      return;
    }

    // Map sequence codes to coordinates
    final Map<String, LatLng> pointMap = {
      'S1': LatLng(widget.startLat1, widget.startLng1),
      'E1': LatLng(widget.endLat1, widget.endLng1),
      'S2': LatLng(widget.startLat2, widget.startLng2),
      'E2': LatLng(widget.endLat2, widget.endLng2),
    };

    // Get ordered list of points based on sequence
    List<LatLng> orderedPoints = widget.sequence!.map((code) => pointMap[code]!).toList();

    try {
      // Build route with waypoints
      final PolylinePoints polylinePoints = PolylinePoints();
      
      // Origin is first point, destination is last point
      final origin = PointLatLng(orderedPoints[0].latitude, orderedPoints[0].longitude);
      final destination = PointLatLng(orderedPoints[3].latitude, orderedPoints[3].longitude);
      
      // Waypoints are the middle points
      List<PolylineWayPoint> waypoints = [];
      for (int i = 1; i < 3; i++) {
        waypoints.add(PolylineWayPoint(
          location: "${orderedPoints[i].latitude},${orderedPoints[i].longitude}",
        ));
      }

      final PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: origin,
          destination: destination,
          wayPoints: waypoints,
          mode: TravelMode.driving,
        ),
        googleApiKey: Environment.mapKey,
      );

      if (result.points.isNotEmpty) {
        // Convert to LatLng list
        List<LatLng> allPoints = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Find indices in sequence for user's points (S2 and E2)
        int s2Index = widget.sequence!.indexOf('S2');
        int e2Index = widget.sequence!.indexOf('E2');
        
        // Draw complete route
        // Since we can't easily split the polyline to color segments differently,
        // we'll draw the full route in primary color (shows complete path through 4 points)
        // User's points (S2, E2) are highlighted with orange markers
        _polylines[const PolylineId('full_route')] = Polyline(
          polylineId: const PolylineId('full_route'),
          color: MyColor.getPrimaryColor(),
          points: allPoints,
          width: 5,
        );
        
        // Note: To color specific route segments differently (e.g., segments involving S2/E2),
        // we would need to make separate API calls for each segment or use route waypoint indices.
        // For now, the full route with highlighted markers clearly shows the path.
      }
    } catch (e) {
      print('Error loading route: $e');
    }

    setState(() {
      _isLoading = false;
    });

    // Fit bounds after loading
    Future.delayed(const Duration(milliseconds: 500), () {
      _fitBounds();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Increased height for better visibility
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.startLat1, widget.startLng1),
                zoom: 12,
              ),
              markers: _markers,
              polylines: Set<Polyline>.of(_polylines.values),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
                // Fit bounds after a delay to ensure map is ready
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
        ),
      ),
    );
  }

  void _fitBounds() {
    if (_controller == null) return;

    double minLat = widget.startLat1;
    double maxLat = widget.startLat1;
    double minLng = widget.startLng1;
    double maxLng = widget.startLng1;

    List<double> lats = [widget.startLat1, widget.endLat1, widget.startLat2, widget.endLat2];
    List<double> lngs = [widget.startLng1, widget.endLng1, widget.startLng2, widget.endLng2];

    for (var lat in lats) {
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
    }
    for (var lng in lngs) {
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    _controller!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50, // padding
    ));
  }
}
