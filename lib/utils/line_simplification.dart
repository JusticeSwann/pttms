// lib/utils/line_simplification.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

/// Simplifies a polyline using the Douglas-Peucker algorithm.
/// [points] is the original list of LatLng points.
/// [epsilon] is the tolerance in meters. Higher values yield more simplification.
List<LatLng> simplifyPolyline(List<LatLng> points, double epsilon) {
  if (points.length < 3) return points;

  int index = -1;
  double maxDistance = 0.0;
  // Find the point with the maximum distance from the line between the first and last points.
  for (int i = 1; i < points.length - 1; i++) {
    double distance = _perpendicularDistance(points[i], points.first, points.last);
    if (distance > maxDistance) {
      index = i;
      maxDistance = distance;
    }
  }

  // If max distance is greater than epsilon, recursively simplify.
  if (maxDistance > epsilon) {
    // Recursively simplify the segments.
    List<LatLng> firstSegment = simplifyPolyline(points.sublist(0, index + 1), epsilon);
    List<LatLng> lastSegment = simplifyPolyline(points.sublist(index, points.length), epsilon);

    // Concatenate results, removing duplicate at the junction.
    return firstSegment.sublist(0, firstSegment.length - 1) + lastSegment;
  } else {
    // If max distance is less than epsilon, return the endpoints.
    return [points.first, points.last];
  }
}

/// Calculate the perpendicular distance from point p to the line formed by points p1 and p2.
double _perpendicularDistance(LatLng p, LatLng p1, LatLng p2) {
  double x0 = p.latitude;
  double y0 = p.longitude;
  double x1 = p1.latitude;
  double y1 = p1.longitude;
  double x2 = p2.latitude;
  double y2 = p2.longitude;

  // If p1 and p2 are the same, return distance between p and p1.
  if (x1 == x2 && y1 == y2) {
    return _euclideanDistance(x0, y0, x1, y1);
  }

  double numerator = ((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1).abs();
  double denominator = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2));
  return numerator / denominator;
}

/// Euclidean distance between two points (in degrees, not meters).
double _euclideanDistance(double x1, double y1, double x2, double y2) {
  return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
}
