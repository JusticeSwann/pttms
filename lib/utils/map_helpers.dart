// lib/utils/map_helpers.dart
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

double calculateDistance(LatLng p1, LatLng p2) {
  const double earthRadius = 6371000; // meters
  final dLat = degreesToRadians(p2.latitude - p1.latitude);
  final dLon = degreesToRadians(p2.longitude - p1.longitude);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(degreesToRadians(p1.latitude)) *
          cos(degreesToRadians(p2.latitude)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

double degreesToRadians(double degrees) => degrees * pi / 180;

double computeSpeedKmh(LatLng lastLocation, LatLng currentLocation, double intervalSeconds) {
  final movement = calculateDistance(lastLocation, currentLocation);
  return (movement / intervalSeconds) * 3.6;
}

void updateRouteData({
  required LatLng currentPosition,
  required List<LatLng> routeTrace,
  required List<LatLng> stopsMade,
  required double threshold,
}) {
  if (routeTrace.isEmpty) {
    routeTrace.add(currentPosition);
  } else {
    final lastPoint = routeTrace.last;
    final distance = calculateDistance(lastPoint, currentPosition);
    if (distance >= threshold) {
      routeTrace.add(currentPosition);
      stopsMade.clear();
    } else {
      if (stopsMade.isEmpty ||
          calculateDistance(stopsMade.last, currentPosition) >= threshold) {
        stopsMade.add(currentPosition);
      }
    }
  }
}
