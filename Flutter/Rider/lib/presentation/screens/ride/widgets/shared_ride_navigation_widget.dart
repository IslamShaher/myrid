import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovorideuser/core/utils/dimensions.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:ovorideuser/data/controller/location/app_location_controller.dart';
import 'package:ovorideuser/presentation/components/divider/custom_spacer.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/flutter_polyline_points.dart';
import 'package:ovorideuser/presentation/packages/flutter_polyline_points/src/polyline_decoder.dart';

/// Navigation widget with turn-by-turn directions for shared rides
class SharedRideNavigationWidget extends StatefulWidget {
  final Map<String, dynamic> directionsData;
  final List<String> sequence;
  final LatLng? currentLocation;
  final double pickupLat1;
  final double pickupLng1;
  final double destLat1;
  final double destLng1;
  final double pickupLat2;
  final double pickupLng2;
  final double destLat2;
  final double destLng2;

  const SharedRideNavigationWidget({
    super.key,
    required this.directionsData,
    required this.sequence,
    this.currentLocation,
    required this.pickupLat1,
    required this.pickupLng1,
    required this.destLat1,
    required this.destLng1,
    required this.pickupLat2,
    required this.pickupLng2,
    required this.destLat2,
    required this.destLng2,
  });

  @override
  State<SharedRideNavigationWidget> createState() => _SharedRideNavigationWidgetState();
}

class _SharedRideNavigationWidgetState extends State<SharedRideNavigationWidget> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  String? _currentInstruction;
  double? _distanceToNext;
  int _currentStepIndex = 0;
  List<Map<String, dynamic>>? _steps;
  List<LatLng>? _routePoints;

  @override
  void initState() {
    super.initState();
    _parseDirections();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _parseDirections() {
    try {
      // Parse directions data to extract steps
      if (widget.directionsData['routes'] != null && 
          widget.directionsData['routes'].isNotEmpty) {
        final route = widget.directionsData['routes'][0];
        if (route['legs'] != null && route['legs'].isNotEmpty) {
          _steps = [];
          for (var leg in route['legs']) {
            if (leg['steps'] != null) {
              for (var step in leg['steps']) {
                _steps!.add({
                  'instruction': step['html_instructions']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? '',
                  'distance': step['distance']?['text'] ?? '',
                  'duration': step['duration']?['text'] ?? '',
                  'start_location': {
                    'lat': step['start_location']?['lat'],
                    'lng': step['start_location']?['lng'],
                  },
                  'end_location': {
                    'lat': step['end_location']?['lat'],
                    'lng': step['end_location']?['lng'],
                  },
                });
              }
            }
          }
        }
      }
      
      // Parse polyline for route display
      if (widget.directionsData['polyline'] != null) {
        String encodedPolyline = widget.directionsData['polyline'] as String;
        List<PointLatLng> decodedPoints = PolylineDecoder.run(encodedPolyline);
        _routePoints = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
      
      if (_steps != null && _steps!.isNotEmpty) {
        _currentInstruction = _steps![0]['instruction'];
        _updateCurrentStep();
      }
    } catch (e) {
      print('Error parsing directions: $e');
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final appLocationController = Get.find<AppLocationController>();
        final position = await appLocationController.getCurrentPosition();
        if (position != null) {
          setState(() {
            _currentPosition = position;
          });
          _updateCurrentStep();
          _updateMapCamera();
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  void _updateCurrentStep() {
    if (_currentPosition == null || _steps == null || _steps!.isEmpty) return;
    
    final currentLat = _currentPosition!.latitude;
    final currentLng = _currentPosition!.longitude;
    
    // Find the closest step to current location
    double minDistance = double.infinity;
    int closestStepIndex = 0;
    
    for (int i = 0; i < _steps!.length; i++) {
      final step = _steps![i];
      final stepLat = step['start_location']?['lat'] as double?;
      final stepLng = step['start_location']?['lng'] as double?;
      
      if (stepLat != null && stepLng != null) {
        final distance = Geolocator.distanceBetween(
          currentLat, currentLng,
          stepLat, stepLng,
        );
        
        if (distance < minDistance) {
          minDistance = distance;
          closestStepIndex = i;
        }
      }
    }
    
    // Update to next step if we're close to current step (within 50 meters)
    // Always show the NEXT step ahead, not the current one
    int nextStepIndex = closestStepIndex;
    if (minDistance < 50 && closestStepIndex < _steps!.length - 1) {
      nextStepIndex = closestStepIndex + 1; // Show next step
    }
    
    if (nextStepIndex != _currentStepIndex) {
      setState(() {
        _currentStepIndex = nextStepIndex;
        if (nextStepIndex < _steps!.length) {
          _currentInstruction = _steps![nextStepIndex]['instruction'];
          // Calculate distance to next step's start location
          final nextStep = _steps![nextStepIndex];
          final nextStepLat = nextStep['start_location']?['lat'] as double?;
          final nextStepLng = nextStep['start_location']?['lng'] as double?;
          if (nextStepLat != null && nextStepLng != null) {
            _distanceToNext = Geolocator.distanceBetween(
              currentLat, currentLng,
              nextStepLat, nextStepLng,
            );
          }
        }
      });
    } else if (_distanceToNext == null) {
      // Calculate distance if not set
      final nextStep = _steps![nextStepIndex];
      final nextStepLat = nextStep['start_location']?['lat'] as double?;
      final nextStepLng = nextStep['start_location']?['lng'] as double?;
      if (nextStepLat != null && nextStepLng != null) {
        setState(() {
          _distanceToNext = Geolocator.distanceBetween(
            currentLat, currentLng,
            nextStepLat, nextStepLng,
          );
        });
      }
    }
  }

  void _updateMapCamera() {
    if (_mapController == null || _currentPosition == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.getCardBgColor(),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        boxShadow: MyColor.getCardShadow(),
      ),
      child: Column(
        children: [
          // Navigation Header
          Container(
            padding: EdgeInsets.all(Dimensions.space15),
            decoration: BoxDecoration(
              color: MyColor.getPrimaryColor(),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.mediumRadius),
                topRight: Radius.circular(Dimensions.mediumRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.navigation, color: Colors.white, size: 24),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Navigation Mode",
                        style: boldDefault.copyWith(color: Colors.white),
                      ),
                      if (_distanceToNext != null)
                        Text(
                          "${(_distanceToNext! / 1000).toStringAsFixed(1)} km to next turn",
                          style: regularSmall.copyWith(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Current Instruction
          Container(
            padding: EdgeInsets.all(Dimensions.space15),
            child: Column(
              children: [
                if (_currentInstruction != null)
                  Container(
                    padding: EdgeInsets.all(Dimensions.space15),
                    decoration: BoxDecoration(
                      color: MyColor.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.turn_right, 
                          color: MyColor.getPrimaryColor(), 
                          size: 32,
                        ),
                        spaceSide(Dimensions.space15),
                        Expanded(
                          child: Text(
                            _currentInstruction!,
                            style: boldLarge.copyWith(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                spaceDown(Dimensions.space10),
                
                // Mini Map
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: MyColor.neutral300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : LatLng(widget.pickupLat1, widget.pickupLng1),
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      polylines: _routePoints != null
                          ? Set<Polyline>.from([
                              Polyline(
                                polylineId: PolylineId('route'),
                                points: _routePoints!,
                                color: MyColor.getPrimaryColor(),
                                width: 5,
                              ),
                            ])
                          : <Polyline>{},
                      markers: {
                        if (_currentPosition != null)
                          Marker(
                            markerId: const MarkerId('current'),
                            position: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          ),
                      },
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

