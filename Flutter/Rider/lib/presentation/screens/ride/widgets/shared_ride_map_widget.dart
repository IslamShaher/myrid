import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/utils/helper.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/src/polyline_decoder.dart';
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
  final Map<String, dynamic>? directionsData; // Saved directions data from backend
  final LatLng? currentUserLocation; // Current user's live location
  final LatLng? otherUserLocation; // Other user's live location
  final bool showLiveLocations; // Whether to show live location markers

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
    this.directionsData,
    this.currentUserLocation,
    this.otherUserLocation,
    this.showLiveLocations = false,
  });

  @override
  State<SharedRideMapWidget> createState() => _SharedRideMapWidgetState();
}

class _SharedRideMapWidgetState extends State<SharedRideMapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Map<PolylineId, Polyline> _polylines = {};
  bool _isLoading = true;
  BitmapDescriptor? _rider1PickupIcon;
  BitmapDescriptor? _rider1DropoffIcon;
  BitmapDescriptor? _rider2PickupIcon;
  BitmapDescriptor? _rider2DropoffIcon;
  BitmapDescriptor? _currentUserLiveIcon;
  BitmapDescriptor? _otherUserLiveIcon;

  @override
  void initState() {
    super.initState();
    _createCustomIcons();
  }

  Future<void> _createCustomIcons() async {
    // Rider 1 - Purple/Blue theme
    final rider1PickupBytes = await Helper.createCustomCircleMarker(
      color: const Color(0xFF7B2CBF), // Purple
      iconColor: Colors.white,
      iconType: 'pickup',
      size: 32,
    );
    final rider1DropoffBytes = await Helper.createCustomCircleMarker(
      color: const Color(0xFF5A189A), // Darker purple
      iconColor: Colors.white,
      iconType: 'dropoff',
      size: 32,
    );
    
    // Rider 2 - Orange/Amber theme
    final rider2PickupBytes = await Helper.createCustomCircleMarker(
      color: const Color(0xFFFF6B35), // Orange
      iconColor: Colors.white,
      iconType: 'pickup',
      size: 32,
    );
    final rider2DropoffBytes = await Helper.createCustomCircleMarker(
      color: const Color(0xFFE63946), // Red-orange
      iconColor: Colors.white,
      iconType: 'dropoff',
      size: 32,
    );
    
    // Live location markers - smaller and more subtle
    final currentUserLiveBytes = await Helper.createCustomCircleMarker(
      color: const Color(0xFF06D6A0), // Green
      iconColor: Colors.white,
      iconType: 'live',
      size: 24,
    );
    final otherUserLiveBytes = await Helper.createCustomCircleMarker(
      color: const Color(0xFF118AB2), // Blue
      iconColor: Colors.white,
      iconType: 'live',
      size: 24,
    );
    
    setState(() {
      _rider1PickupIcon = BitmapDescriptor.fromBytes(rider1PickupBytes);
      _rider1DropoffIcon = BitmapDescriptor.fromBytes(rider1DropoffBytes);
      _rider2PickupIcon = BitmapDescriptor.fromBytes(rider2PickupBytes);
      _rider2DropoffIcon = BitmapDescriptor.fromBytes(rider2DropoffBytes);
      _currentUserLiveIcon = BitmapDescriptor.fromBytes(currentUserLiveBytes);
      _otherUserLiveIcon = BitmapDescriptor.fromBytes(otherUserLiveBytes);
      _initializeMarkers();
      _loadRoute();
    });
  }

  void _initializeMarkers() {
    if (_rider1PickupIcon == null || _rider1DropoffIcon == null || 
        _rider2PickupIcon == null || _rider2DropoffIcon == null) {
      return; // Wait for icons to be created
    }
    
    _markers = {
      // Rider 1 pickup - purple with navigation icon
      Marker(
        markerId: const MarkerId('S1'),
        position: LatLng(widget.startLat1, widget.startLng1),
        icon: _rider1PickupIcon!,
        infoWindow: const InfoWindow(title: "Rider 1 Pickup"),
        anchor: const Offset(0.5, 0.5),
      ),
      // Rider 1 dropoff - darker purple with flag icon
      Marker(
        markerId: const MarkerId('E1'),
        position: LatLng(widget.endLat1, widget.endLng1),
        icon: _rider1DropoffIcon!,
        infoWindow: const InfoWindow(title: "Rider 1 Dropoff"),
        anchor: const Offset(0.5, 0.5),
      ),
      // Rider 2 (You) pickup - orange with navigation icon
      Marker(
        markerId: const MarkerId('S2'),
        position: LatLng(widget.startLat2, widget.startLng2),
        icon: _rider2PickupIcon!,
        infoWindow: const InfoWindow(title: "Your Pickup"),
        anchor: const Offset(0.5, 0.5),
      ),
      // Rider 2 (You) dropoff - red-orange with flag icon
      Marker(
        markerId: const MarkerId('E2'),
        position: LatLng(widget.endLat2, widget.endLng2),
        icon: _rider2DropoffIcon!,
        infoWindow: const InfoWindow(title: "Your Dropoff"),
        anchor: const Offset(0.5, 0.5),
      ),
    };
    
    // Add live location markers if enabled
    if (widget.showLiveLocations) {
      if (widget.currentUserLocation != null && _currentUserLiveIcon != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current_user_live'),
            position: widget.currentUserLocation!,
            icon: _currentUserLiveIcon!,
            infoWindow: const InfoWindow(title: "Your Location"),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
      if (widget.otherUserLocation != null && _otherUserLiveIcon != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('other_user_live'),
            position: widget.otherUserLocation!,
            icon: _otherUserLiveIcon!,
            infoWindow: const InfoWindow(title: "Other Rider Location"),
            anchor: const Offset(0.5, 0.5),
          ),
        );
      }
    }
  }
  
  @override
  void didUpdateWidget(SharedRideMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update markers when live locations change
    if (widget.showLiveLocations && 
        (widget.currentUserLocation != oldWidget.currentUserLocation ||
         widget.otherUserLocation != oldWidget.otherUserLocation)) {
      _initializeMarkers();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadRoute() async {
    if (widget.sequence == null || widget.sequence!.length != 4) {
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
      List<LatLng>? fullRoutePoints;
      
      // Check if we have saved directions data (from confirmed rides)
      if (widget.directionsData != null && widget.directionsData!['polyline'] != null) {
        // Use saved directions data to avoid API calls for full route
        String encodedPolyline = widget.directionsData!['polyline'] as String;
        List<PointLatLng> decodedPoints = PolylineDecoder.run(encodedPolyline);
        fullRoutePoints = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      } else {
        // Fetch directions from API (for possible matches or when directions not saved)
        final PolylinePoints polylinePoints = PolylinePoints();
        
        // Build route with waypoints for complete path passing through all 4 points
        final origin = PointLatLng(orderedPoints[0].latitude, orderedPoints[0].longitude);
        final destination = PointLatLng(orderedPoints[3].latitude, orderedPoints[3].longitude);
        
        List<PolylineWayPoint> waypoints = [];
        for (int i = 1; i < 3; i++) {
          waypoints.add(PolylineWayPoint(
            location: "${orderedPoints[i].latitude},${orderedPoints[i].longitude}",
          ));
        }

        // Get the complete route passing through all 4 points
        final PolylineResult fullResult = await polylinePoints.getRouteBetweenCoordinates(
          request: PolylineRequest(
            origin: origin,
            destination: destination,
            wayPoints: waypoints,
            mode: TravelMode.driving,
          ),
          googleApiKey: Environment.mapKey,
        );

        if (fullResult.points.isNotEmpty) {
          fullRoutePoints = fullResult.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        }
      }
      
      // Draw route segments with different colors
      await _drawColoredSegments(orderedPoints, fullRoutePoints);
    } catch (e) {
      print('Error loading route: $e');
      // Fallback: draw direct lines if API fails
    }

    setState(() {
      _isLoading = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _fitBounds();
    });
  }

  Future<void> _drawColoredSegments(List<LatLng> orderedPoints, List<LatLng>? fullRoutePoints) async {
    // Draw route segments between consecutive waypoints with different colors
    // based on which passenger's pickup/dropoff points they connect
    final PolylinePoints polylinePoints = PolylinePoints();
    
    for (int i = 0; i < 3; i++) {
      final startCode = widget.sequence![i];
      final endCode = widget.sequence![i + 1];
      
      // Determine color based on which passenger's points this segment connects
      // S1-E1 = Rider 1's route (purple/violet)
      // S2-E2 = Rider 2's route (orange)
      // Mixed segments = primary color
      Color segmentColor;
      
      if ((startCode == 'S1' && endCode == 'E1') || (startCode == 'E1' && endCode == 'S1')) {
        // Rider 1's direct route segment
        segmentColor = Colors.purple;
      } else if ((startCode == 'S2' && endCode == 'E2') || (startCode == 'E2' && endCode == 'S2')) {
        // Rider 2's direct route segment
        segmentColor = Colors.orange;
      } else if (startCode == 'S1' || startCode == 'E1' || endCode == 'S1' || endCode == 'E1') {
        // Segment involving Rider 1's points
        segmentColor = Colors.purple.withOpacity(0.7);
      } else if (startCode == 'S2' || startCode == 'E2' || endCode == 'S2' || endCode == 'E2') {
        // Segment involving Rider 2's points
        segmentColor = Colors.orange.withOpacity(0.7);
      } else {
        // Mixed or shared segment
        segmentColor = MyColor.getPrimaryColor();
      }
      
      // Get route for this segment
      try {
        final segmentResult = await polylinePoints.getRouteBetweenCoordinates(
          request: PolylineRequest(
            origin: PointLatLng(orderedPoints[i].latitude, orderedPoints[i].longitude),
            destination: PointLatLng(orderedPoints[i + 1].latitude, orderedPoints[i + 1].longitude),
            mode: TravelMode.driving,
          ),
          googleApiKey: Environment.mapKey,
        );
        
        if (segmentResult.points.isNotEmpty) {
          List<LatLng> segmentPoints = segmentResult.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          
          final isSharedSegment = segmentColor == MyColor.getPrimaryColor();
          _polylines[PolylineId('segment_$i')] = Polyline(
            polylineId: PolylineId('segment_$i'),
            color: segmentColor,
            points: segmentPoints,
            width: 6,
            patterns: isSharedSegment ? [PatternItem.dash(20), PatternItem.gap(10)] : [],
          );
        }
      } catch (e) {
        print('Error loading segment $i: $e');
      }
    }
    
    // Also draw full route as background if available
    if (fullRoutePoints != null && fullRoutePoints.isNotEmpty) {
      _polylines[const PolylineId('full_route')] = Polyline(
        polylineId: const PolylineId('full_route'),
        color: MyColor.getPrimaryColor().withOpacity(0.2),
        points: fullRoutePoints,
        width: 4,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
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
              zoomControlsEnabled: true, // Enable zoom controls
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomGesturesEnabled: true, // Enable pinch to zoom
              scrollGesturesEnabled: true, // Enable scroll/pan
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
        ),
      ),
    );
  }

  void _fitBounds() {
    if (_controller == null) return;

    List<LatLng> points = [
      LatLng(widget.startLat1, widget.startLng1),
      LatLng(widget.endLat1, widget.endLng1),
      LatLng(widget.startLat2, widget.startLng2),
      LatLng(widget.endLat2, widget.endLng2),
    ];

    // Add live locations to bounds if available
    if (widget.showLiveLocations) {
      if (widget.currentUserLocation != null) points.add(widget.currentUserLocation!);
      if (widget.otherUserLocation != null) points.add(widget.otherUserLocation!);
    }

    // Filter out invalid coordinates (e.g. 0,0)
    List<LatLng> validPoints = points.where((p) => p.latitude != 0 && p.longitude != 0).toList();
    
    if (validPoints.isEmpty) return;

    double minLat = validPoints.first.latitude;
    double maxLat = validPoints.first.latitude;
    double minLng = validPoints.first.longitude;
    double maxLng = validPoints.first.longitude;

    for (var point in validPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _controller!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50,
    ));
  }
}
