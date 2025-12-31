class SharedRideMatchModel {
  bool? success;
  List<SharedMatch>? matches;

  SharedRideMatchModel({this.success, this.matches});

  SharedRideMatchModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['matches'] != null) {
      matches = <SharedMatch>[];
      json['matches'].forEach((v) {
        matches!.add(SharedMatch.fromJson(v));
      });
    }
  }
}

class SharedMatch {
  RideInfo? ride;
  double? r1Overhead;
  double? r2Overhead;
  double? totalOverhead;
  double? r1Solo;
  double? r2Solo;
  double? r1Fare;
  double? r2Fare;
  double? r1SoloFare;
  double? r2SoloFare;
  List<String>? sequence;
  String? estimatedPickupTime;
  String? estimatedPickupTimeReadable;
  String? rideScheduledTime;
  String? rideScheduledTimeReadable;
  Map<String, dynamic>? directions;

  SharedMatch({this.ride, this.r1Overhead, this.r2Overhead, this.totalOverhead, this.r1Solo, this.r2Solo, this.r1Fare, this.r2Fare, this.r1SoloFare, this.r2SoloFare, this.sequence, this.estimatedPickupTime, this.estimatedPickupTimeReadable, this.rideScheduledTime, this.rideScheduledTimeReadable, this.directions});

  SharedMatch.fromJson(Map<String, dynamic> json) {
    ride = json['ride'] != null ? RideInfo.fromJson(json['ride']) : null;
    r1Overhead = json['r1_overhead'] != null ? double.tryParse(json['r1_overhead'].toString()) : null;
    r2Overhead = json['r2_overhead'] != null ? double.tryParse(json['r2_overhead'].toString()) : null;
    totalOverhead = json['total_overhead'] != null ? double.tryParse(json['total_overhead'].toString()) : null;
    r1Solo = json['r1_solo'] != null ? double.tryParse(json['r1_solo'].toString()) : null;
    r2Solo = json['r2_solo'] != null ? double.tryParse(json['r2_solo'].toString()) : null;
    r1Fare = json['r1_fare'] != null ? double.tryParse(json['r1_fare'].toString()) : null;
    r2Fare = json['r2_fare'] != null ? double.tryParse(json['r2_fare'].toString()) : null;
    r1SoloFare = json['r1_solo_fare'] != null ? double.tryParse(json['r1_solo_fare'].toString()) : null;
    r2SoloFare = json['r2_solo_fare'] != null ? double.tryParse(json['r2_solo_fare'].toString()) : null;
    sequence = json['sequence'] != null && json['sequence'] is List ? (json['sequence'] as List).map((e) => e.toString()).toList() : null;
    estimatedPickupTime = json['estimated_pickup_time']?.toString();
    estimatedPickupTimeReadable = json['estimated_pickup_time_readable']?.toString();
    rideScheduledTime = json['ride_scheduled_time']?.toString();
    rideScheduledTimeReadable = json['ride_scheduled_time_readable']?.toString();
    directions = json['directions'] != null ? Map<String, dynamic>.from(json['directions']) : null;
  }
}

class RideInfo {
  int? id;
  String? pickupLocation;
  String? destination;
  String? distance; // API returns km/m string or value?
  String? duration;
  String? amount;
  double? pickupLat;
  double? pickupLng;
  double? destLat;
  double? destLng;
  double? secondPickupLat;
  double? secondPickupLng;
  double? secondDestLat;
  double? secondDestLng;
  int? userId;
  int? secondUserId;
  List<String>? sharedRideSequence;
  Map<String, dynamic>? directionsData; // Saved directions data from backend

  RideInfo({this.id, this.pickupLocation, this.destination, this.distance, this.duration, this.amount, this.pickupLat, this.pickupLng, this.destLat, this.destLng, this.secondPickupLat, this.secondPickupLng, this.secondDestLat, this.secondDestLng, this.userId, this.secondUserId, this.sharedRideSequence, this.directionsData});

  RideInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    pickupLocation = json['pickup_location']?.toString();
    destination = json['destination']?.toString();
    distance = json['distance']?.toString();
    duration = json['duration']?.toString();
    amount = json['amount']?.toString();
    pickupLat = double.tryParse(json['pickup_latitude']?.toString() ?? '');
    pickupLng = double.tryParse(json['pickup_longitude']?.toString() ?? '');
    destLat = double.tryParse(json['destination_latitude']?.toString() ?? '');
    destLng = double.tryParse(json['destination_longitude']?.toString() ?? '');
    secondPickupLat = json['second_pickup_latitude'] != null ? double.tryParse(json['second_pickup_latitude'].toString()) : null;
    secondPickupLng = json['second_pickup_longitude'] != null ? double.tryParse(json['second_pickup_longitude'].toString()) : null;
    secondDestLat = json['second_destination_latitude'] != null ? double.tryParse(json['second_destination_latitude'].toString()) : null;
    secondDestLng = json['second_destination_longitude'] != null ? double.tryParse(json['second_destination_longitude'].toString()) : null;
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    secondUserId = json['second_user_id'] != null ? int.tryParse(json['second_user_id'].toString()) : null;
    if (json['shared_ride_sequence'] != null && json['shared_ride_sequence'] is List) {
      sharedRideSequence = (json['shared_ride_sequence'] as List).map((e) => e.toString()).toList();
    }
    if (json['directions_data'] != null && json['directions_data'] is Map) {
      directionsData = Map<String, dynamic>.from(json['directions_data']);
    }
  }
}
