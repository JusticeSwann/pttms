// lib/data/models/route_model.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final String name;
  final String vehicleType;
  final List<LatLng> polyline;
  final LatLng routeStart;
  final LatLng routeEnd;
  final List<LatLng> pickupPoints;

  RouteModel({
    required this.name,
    required this.vehicleType,
    required this.polyline,
    required this.routeStart,
    required this.routeEnd,
    required this.pickupPoints,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      name: json['name'] as String,
      // Normalize the vehicle type (trim whitespace and lowercase)
      vehicleType: (json['vehicle_type'] as String).trim().toLowerCase(),
      polyline: (json['polyline'] as List)
          .map((coord) => LatLng(
                (coord[0] as num).toDouble(),
                (coord[1] as num).toDouble(),
              ))
          .toList(),
      routeStart: LatLng(
        (json['route_start'][0] as num).toDouble(),
        (json['route_start'][1] as num).toDouble(),
      ),
      routeEnd: LatLng(
        (json['route_end'][0] as num).toDouble(),
        (json['route_end'][1] as num).toDouble(),
      ),
      pickupPoints: (json['pickup_points'] as List)
          .map((coord) => LatLng(
                (coord[0] as num).toDouble(),
                (coord[1] as num).toDouble(),
              ))
          .toList(),
    );
  }
}
