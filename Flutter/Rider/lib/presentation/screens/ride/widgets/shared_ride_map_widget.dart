import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';

class SharedRideMapWidget extends StatefulWidget {
  final double startLat1; // Rider 1
  final double startLng1;
  final double endLat1;
  final double endLng1;
  final double startLat2; // You
  final double startLng2;
  final double endLat2;
  final double endLng2;

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
  });

  @override
  State<SharedRideMapWidget> createState() => _SharedRideMapWidgetState();
}

class _SharedRideMapWidgetState extends State<SharedRideMapWidget> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers = {
      Marker(
        markerId: const MarkerId('S1'),
        position: LatLng(widget.startLat1, widget.startLng1),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet), // R1 Pick
        infoWindow: const InfoWindow(title: "Rider 1 Pickup"),
      ),
      Marker(
        markerId: const MarkerId('E1'),
        position: LatLng(widget.endLat1, widget.endLng1),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet), // R1 Drop
         infoWindow: const InfoWindow(title: "Rider 1 Drop"),
      ),
      Marker(
        markerId: const MarkerId('S2'),
        position: LatLng(widget.startLat2, widget.startLng2),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // You Pick
         infoWindow: const InfoWindow(title: "You Pickup"),
      ),
      Marker(
        markerId: const MarkerId('E2'),
        position: LatLng(widget.endLat2, widget.endLng2),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // You Pick
         infoWindow: const InfoWindow(title: "You Drop"),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150, // Mini map height
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.startLat1, widget.startLng1),
            zoom: 12,
          ),
          markers: _markers,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            // Fit bounds
            Future.delayed(const Duration(milliseconds: 500), () {
               _fitBounds();
            });
          },
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
      40, // padding
    ));
  }
}
