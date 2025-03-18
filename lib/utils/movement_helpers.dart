import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calculates the distance in meters between two coordinates using the Haversine formula.
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // in meters
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadius * c;
}

/// Helper to convert degrees to radians.
double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

/// Updates the movement route trace by adding a new location if the distance
/// from the last point exceeds the given threshold (in meters).
List<Map<String, double>> updateMovementRouteTrace(
  List<Map<String, double>> routeTrace,
  LatLng newLocation,
  double threshold,
) {
  if (routeTrace.isEmpty) {
    routeTrace.add({'lat': newLocation.latitude, 'lng': newLocation.longitude});
  } else {
    final lastPoint = routeTrace.last;
    final distance = calculateDistance(
      lastPoint['lat']!,
      lastPoint['lng']!,
      newLocation.latitude,
      newLocation.longitude,
    );
    if (distance > threshold) {
      routeTrace.add({'lat': newLocation.latitude, 'lng': newLocation.longitude});
    }
  }
  return routeTrace;
}

/// Computes the average traffic level based on a list of traffic level strings.
/// 'low' counts as 1, 'medium' as 2, and 'high' as 3.
String computeAverageTrafficLevel(List<String> trafficLevels) {
  if (trafficLevels.isEmpty) return 'low';
  int total = 0;
  for (var level in trafficLevels) {
    if (level == 'low') {
      total += 1;
    } else if (level == 'medium') {
      total += 2;
    } else if (level == 'high') {
      total += 3;
    }
  }
  double avg = total / trafficLevels.length;
  if (avg < 1.5) {
    return 'low';
  } else if (avg < 2.5) {
    return 'medium';
  } else {
    return 'high';
  }
}
