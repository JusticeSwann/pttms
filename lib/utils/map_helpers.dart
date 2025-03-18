// lib/utils/map_helpers.dart
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calculates the distance in meters between two LatLng points.
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

/// Converts degrees to radians.
double degreesToRadians(double degrees) => degrees * pi / 180;

/// Computes the instantaneous speed (in km/h) between two locations over a given time interval in seconds.
double computeSpeedKmh(LatLng lastLocation, LatLng currentLocation, double intervalSeconds) {
  final movement = calculateDistance(lastLocation, currentLocation);
  return (movement / intervalSeconds) * 3.6;
}

/// Updates the route trace and stops list based on the current position and a distance threshold.
/// If the distance from the last trace point exceeds the threshold, the point is added to the trace and stops are cleared.
/// Otherwise, if the distance from the last stop point exceeds the threshold, the point is added as a stop.
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
