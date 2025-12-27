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

  SharedMatch(
      {this.ride,
      this.r1Overhead,
      this.r2Overhead,
      this.totalOverhead,
      this.r1Solo,
      this.r2Solo,
      this.r1Fare,
      this.r2Fare,
      this.r1SoloFare,
      this.r2SoloFare,
      this.sequence,
      this.estimatedPickupTime,
      this.estimatedPickupTimeReadable,
      this.rideScheduledTime,
      this.rideScheduledTimeReadable});

  SharedMatch.fromJson(Map<String, dynamic> json) {
    ride = json['ride'] != null ? RideInfo.fromJson(json['ride']) : null;
    r1Overhead = double.tryParse(json['r1_overhead'].toString());
    r2Overhead = double.tryParse(json['r2_overhead'].toString());
    totalOverhead = double.tryParse(json['total_overhead'].toString());
    r1Solo = double.tryParse(json['r1_solo'].toString());
    r2Solo = double.tryParse(json['r2_solo'].toString());
    r1Fare = double.tryParse(json['r1_fare'].toString());
    r2Fare = double.tryParse(json['r2_fare'].toString());
    r1SoloFare = json['r1_solo_fare'] != null ? double.tryParse(json['r1_solo_fare'].toString()) : null;
    r2SoloFare = json['r2_solo_fare'] != null ? double.tryParse(json['r2_solo_fare'].toString()) : null;
    sequence = json['sequence'] != null ? (json['sequence'] as List).cast<String>() : null;
    estimatedPickupTime = json['estimated_pickup_time']?.toString();
    estimatedPickupTimeReadable = json['estimated_pickup_time_readable']?.toString();
    rideScheduledTime = json['ride_scheduled_time']?.toString();
    rideScheduledTimeReadable = json['ride_scheduled_time_readable']?.toString();
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
  int? userId;
  int? secondUserId;
  List<String>? sharedRideSequence;

  RideInfo(
      {this.id,
      this.pickupLocation,
      this.destination,
      this.distance,
      this.duration,
      this.amount,
      this.pickupLat,
      this.pickupLng,
      this.destLat,
      this.destLng,
      this.userId,
      this.secondUserId,
      this.sharedRideSequence});

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
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    secondUserId = json['second_user_id'] != null ? int.tryParse(json['second_user_id'].toString()) : null;
    if (json['shared_ride_sequence'] != null) {
      sharedRideSequence = (json['shared_ride_sequence'] as List).cast<String>();
    }
  }
}
