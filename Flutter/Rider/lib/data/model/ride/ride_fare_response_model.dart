// To parse this JSON data, do
//
//     final rideFareResponseModel = rideFareResponseModelFromJson(jsonString);

import 'dart:convert';

import '../global/app/app_service_model.dart';

RideFareResponseModel rideFareResponseModelFromJson(String str) => RideFareResponseModel.fromJson(json.decode(str));

String rideFareResponseModelToJson(RideFareResponseModel data) => json.encode(data.toJson());

class RideFareResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  RideFareModel? data;

  RideFareResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory RideFareResponseModel.fromJson(Map<String, dynamic> json) => RideFareResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null ? [] : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : RideFareModel.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "remark": remark,
        "status": status,
        "message": message == null ? [] : List<dynamic>.from(message!.map((x) => x)),
        "data": data?.toJson(),
      };
}

class RideFareModel {
  String? distance;
  String? rideType;
  List<AppService>? services;

  RideFareModel({
    this.distance,
    this.rideType,
    this.services,
  });

  factory RideFareModel.fromJson(Map<String, dynamic> json) => RideFareModel(
        distance: json["distance"]?.toString(),
        rideType: json["ride_type"]?.toString(),
        services: json["services"] == null ? [] : List<AppService>.from(json["services"]!.map((x) => AppService.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "distance": distance,
        "ride_type": rideType,
        "services": services == null ? [] : List<dynamic>.from(services!.map((x) => x.toJson())),
      };
}
