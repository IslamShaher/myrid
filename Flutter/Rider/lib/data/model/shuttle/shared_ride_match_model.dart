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
  List<String>? sequence;

  SharedMatch(
      {this.ride,
      this.r1Overhead,
      this.r2Overhead,
      this.totalOverhead,
      this.r1Solo,
      this.r2Solo,
      this.r1Fare,
      this.r2Fare,
      this.sequence});

  SharedMatch.fromJson(Map<String, dynamic> json) {
    ride = json['ride'] != null ? RideInfo.fromJson(json['ride']) : null;
    r1Overhead = double.tryParse(json['r1_overhead'].toString());
    r2Overhead = double.tryParse(json['r2_overhead'].toString());
    totalOverhead = double.tryParse(json['total_overhead'].toString());
    r1Solo = double.tryParse(json['r1_solo'].toString());
    r2Solo = double.tryParse(json['r2_solo'].toString());
    r1Fare = double.tryParse(json['r1_fare'].toString());
    r2Fare = double.tryParse(json['r2_fare'].toString());
    sequence = json['sequence'].cast<String>();
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
      this.destLng});

  RideInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    pickupLocation = json['pickup_location'];
    destination = json['destination'];
    distance = json['distance'].toString();
    duration = json['duration'].toString();
    amount = json['amount'].toString();
    pickupLat = double.tryParse(json['pickup_latitude'].toString());
    pickupLng = double.tryParse(json['pickup_longitude'].toString());
    destLat = double.tryParse(json['destination_latitude'].toString());
    destLng = double.tryParse(json['destination_longitude'].toString());
  }
}
