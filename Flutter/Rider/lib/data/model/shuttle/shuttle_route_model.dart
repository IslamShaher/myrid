class ShuttleRouteModel {
  bool? success;
  Stop? startStop;
  Stop? endStop;
  List<MatchedRoute>? matchedRoutes;

  ShuttleRouteModel({this.success, this.startStop, this.endStop, this.matchedRoutes});

  ShuttleRouteModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    startStop = json['start_stop'] != null ? Stop.fromJson(json['start_stop']) : null;
    endStop = json['end_stop'] != null ? Stop.fromJson(json['end_stop']) : null;
    if (json['matched_routes'] != null) {
      matchedRoutes = <MatchedRoute>[];
      json['matched_routes'].forEach((v) {
        matchedRoutes!.add(MatchedRoute.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (startStop != null) {
      data['start_stop'] = startStop!.toJson();
    }
    if (endStop != null) {
      data['end_stop'] = endStop!.toJson();
    }
    if (matchedRoutes != null) {
      data['matched_routes'] = matchedRoutes!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Stop {
  int? id;
  String? name;
  String? latitude;
  String? longitude;
  double? distance;

  Stop({this.id, this.name, this.latitude, this.longitude, this.distance});

  Stop.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    distance = json['distance'] != null ? double.parse(json['distance'].toString()) : 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['distance'] = distance;
    return data;
  }
}

class MatchedRoute {
  int? id;
  String? name;
  String? code;
  List<RouteStop>? stops;

  MatchedRoute({this.id, this.name, this.code, this.stops});

  MatchedRoute.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    code = json['code'];
    if (json['stops'] != null) {
      stops = <RouteStop>[];
      json['stops'].forEach((v) {
        stops!.add(RouteStop.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['code'] = code;
    if (stops != null) {
      data['stops'] = stops!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class RouteStop {
  int? id;
  String? name;
  String? latitude;
  String? longitude;
  Pivot? pivot;

  RouteStop({this.id, this.name, this.latitude, this.longitude, this.pivot});

  RouteStop.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    if (pivot != null) {
      data['pivot'] = pivot!.toJson();
    }
    return data;
  }
}

class Pivot {
  int? routeId;
  int? stopId;
  int? order;

  Pivot({this.routeId, this.stopId, this.order});

  Pivot.fromJson(Map<String, dynamic> json) {
    routeId = json['route_id'];
    stopId = json['stop_id'];
    order = json['order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['route_id'] = routeId;
    data['stop_id'] = stopId;
    data['order'] = order;
    return data;
  }
}
